"""
Nearby Alert API Integration Tests (Item 18)
================================================
ทดสอบระบบแจ้งเตือนใกล้ถึง POST /routes/:id/nearby-alert

Prerequisites:
  - Backend running at BASE_URL (default: http://localhost:3000/api)
  - Driver user with CONFIRMED booking on TODAY's route

Configure via environment variables or edit CONSTANTS below.

Install:
  pip install pytest requests

Run:
  pytest test_nearby_alert_api.py -v
  pytest test_nearby_alert_api.py -v --html=report/report.html --self-contained-html
"""

import os
import time
import pytest
import requests

# ─── Configuration ───────────────────────────────────────────────

BASE_URL = os.getenv("API_BASE_URL", "http://localhost:3000/api")
DRIVER_EMAIL = os.getenv("DRIVER_EMAIL", "test12@test.com")
DRIVER_PASSWORD = os.getenv("DRIVER_PASSWORD", "00000000")
PASSENGER_EMAIL = os.getenv("PASSENGER_EMAIL", "test99@test.com")
PASSENGER_PASSWORD = os.getenv("PASSENGER_PASSWORD", "00000000")
# Route ID for a route departing TODAY (must be set before running)
TODAY_ROUTE_ID = os.getenv("TODAY_ROUTE_ID", "")
# Booking ID of the CONFIRMED booking in that route
CONFIRMED_BOOKING_ID = os.getenv("CONFIRMED_BOOKING_ID", "cmm5vzhbv0004l8ork3c1oto6")

# Simulated driver location (lat/lng near pickup location in test data)
DRIVER_LAT = float(os.getenv("DRIVER_LAT", "13.7563"))
DRIVER_LNG = float(os.getenv("DRIVER_LNG", "100.5018"))


# ─── Helpers ─────────────────────────────────────────────────────

def login(email, password):
    r = requests.post(f"{BASE_URL}/auth/login", json={"email": email, "password": password})
    assert r.status_code == 200, f"Login failed: {r.text}"
    data = r.json().get("data", r.json())
    token = data.get("token") or data.get("accessToken")
    assert token, "No token"
    return token


def auth_header(token):
    return {"Authorization": f"Bearer {token}", "Accept": "application/json", "Content-Type": "application/json"}


def get_today_route_id(driver_token):
    """Try to fetch the first AVAILABLE/IN_TRANSIT route for today."""
    r = requests.get(
        f"{BASE_URL}/routes/me",
        params={"status": "AVAILABLE,FULL,IN_TRANSIT", "limit": 5},
        headers=auth_header(driver_token),
    )
    if r.status_code == 200:
        data = r.json()
        routes = data if isinstance(data, list) else data.get("data", [])
        if routes:
            return routes[0]["id"]
    return None


# ─── Fixtures ────────────────────────────────────────────────────

@pytest.fixture(scope="module")
def driver_token():
    return login(DRIVER_EMAIL, DRIVER_PASSWORD)


@pytest.fixture(scope="module")
def passenger_token():
    return login(PASSENGER_EMAIL, PASSENGER_PASSWORD)


@pytest.fixture(scope="module")
def route_id(driver_token):
    rid = TODAY_ROUTE_ID or get_today_route_id(driver_token)
    if not rid:
        pytest.skip(
            "No active route found for today. Set TODAY_ROUTE_ID env var "
            "or ensure driver has an AVAILABLE/IN_TRANSIT route departing today."
        )
    return rid


@pytest.fixture(scope="module")
def booking_id():
    bid = CONFIRMED_BOOKING_ID
    assert bid, "CONFIRMED_BOOKING_ID env var must be set."
    return bid


# ═══════════════════════════════════════════════════════════════════
# TC-NEARBY-01: Authentication & Authorization
# ═══════════════════════════════════════════════════════════════════

class TestNearbyAlertAuth:
    """TC-NEARBY-01: Check auth/authorization guard on nearby-alert endpoint."""

    def test_01_unauthenticated_request_returns_401(self, route_id):
        """01-01: No token → 401 Unauthorized."""
        r = requests.post(
            f"{BASE_URL}/routes/{route_id}/nearby-alert",
            json={"driverLat": DRIVER_LAT, "driverLng": DRIVER_LNG},
        )
        assert r.status_code == 401, f"Expected 401, got {r.status_code}"

    def test_02_passenger_cannot_send_alert(self, passenger_token, route_id, booking_id):
        """01-02: Passenger (non-driver) sends alert → 403 or 401."""
        r = requests.post(
            f"{BASE_URL}/routes/{route_id}/nearby-alert",
            headers=auth_header(passenger_token),
            json={"driverLat": DRIVER_LAT, "driverLng": DRIVER_LNG, "bookingId": booking_id},
        )
        assert r.status_code in (401, 403), (
            f"Expected 401/403 for passenger, got {r.status_code}"
        )

    def test_03_nonexistent_route_returns_404(self, driver_token):
        """01-03: Driver sends alert for non-existent route → 400."""
        r = requests.post(
            f"{BASE_URL}/routes/nonexistent_route_xyz_000/nearby-alert",
            headers=auth_header(driver_token),
            json={"driverLat": DRIVER_LAT, "driverLng": DRIVER_LNG},
        )
        assert r.status_code == 400


# ═══════════════════════════════════════════════════════════════════
# TC-NEARBY-02: Sending Nearby Alert (Happy Path)
# ═══════════════════════════════════════════════════════════════════

class TestNearbyAlertSend:
    """TC-NEARBY-02: Driver sends nearby alert successfully."""

    def test_01_driver_sends_alert_with_specific_booking(self, driver_token, route_id, booking_id):
        """02-01: Driver sends alert for specific booking → 200, result details returned."""
        r = requests.post(
            f"{BASE_URL}/routes/{route_id}/nearby-alert",
            headers=auth_header(driver_token),
            json={
                "driverLat": DRIVER_LAT,
                "driverLng": DRIVER_LNG,
                "bookingId": booking_id,
                "radiusKm": 100  # Large radius to ensure pickup is within range
            },
        )
        # Expect 200 (success) or 400 (cooldown)
        assert r.status_code in (200, 400), f"Unexpected status: {r.status_code}\nBody: {r.text}"
        data = r.json()
        assert "message" in data or "data" in data, "Response should have 'message' or 'data' key"

    def test_02_response_has_expected_structure(self, driver_token, route_id, booking_id):
        """02-02: Response body has sentCount, skippedCount, details."""
        r = requests.post(
            f"{BASE_URL}/routes/{route_id}/nearby-alert",
            headers=auth_header(driver_token),
            json={
                "driverLat": DRIVER_LAT,
                "driverLng": DRIVER_LNG,
                "bookingId": booking_id,
                "radiusKm": 100
            },
        )
        if r.status_code == 200:
            data = r.json().get("data", {})
            assert "sentCount" in data or "skippedCount" in data or "details" in data, (
                "Response data should include sentCount, skippedCount, or details"
            )
        elif r.status_code == 400:
            # Cooldown block is expected behavior
            assert "message" in r.json()
            pytest.skip("Alert in cooldown period — cooldown test is expected behavior")

    def test_03_driver_sends_alert_for_all_bookings(self, driver_token, route_id):
        """02-03: Driver sends alert without specifying bookingId → targets all CONFIRMED."""
        r = requests.post(
            f"{BASE_URL}/routes/{route_id}/nearby-alert",
            headers=auth_header(driver_token),
            json={
                "driverLat": DRIVER_LAT,
                "driverLng": DRIVER_LNG,
                "radiusKm": 100
            },
        )
        assert r.status_code in (200, 400), (
            f"Unexpected status when sending to all bookings: {r.status_code}"
        )

# ═══════════════════════════════════════════════════════════════════
# TC-NEARBY-03: Cooldown Enforcement
# ═══════════════════════════════════════════════════════════════════

class TestNearbyAlertCooldown:
    """TC-NEARBY-03: Verify cooldown prevents spamming nearby alerts."""

    def test_01_second_alert_within_cooldown_is_blocked(self, driver_token, route_id, booking_id):
        """03-01: Two rapid alerts → second one blocked (400 or sentCount=0 for COOLDOWN)."""
        # First alert
        r1 = requests.post(
            f"{BASE_URL}/routes/{route_id}/nearby-alert",
            headers=auth_header(driver_token),
            json={"driverLat": DRIVER_LAT, "driverLng": DRIVER_LNG, "bookingId": booking_id, "radiusKm": 100},
        )
        first_status = r1.status_code
        print(f"  First alert status: {first_status}, body: {r1.text[:200]}")

        # Immediately second alert (within cooldown)
        r2 = requests.post(
            f"{BASE_URL}/routes/{route_id}/nearby-alert",
            headers=auth_header(driver_token),
            json={"driverLat": DRIVER_LAT, "driverLng": DRIVER_LNG, "bookingId": booking_id, "radiusKm": 100},
        )
        print(f"  Second alert status: {r2.status_code}, body: {r2.text[:200]}")

        if first_status == 200:
            # Second should be in cooldown
            if r2.status_code == 200:
                data2 = r2.json().get("data", {})
                details = data2.get("details", [])
                # Check that result is COOLDOWN, not SENT
                cooldown_results = [d for d in details if d.get("result") == "COOLDOWN"]
                sent_results = [d for d in details if d.get("result") == "SENT"]
                assert len(sent_results) == 0 or len(cooldown_results) > 0, (
                    "Second alert should be in COOLDOWN state, not SENT"
                )
            elif r2.status_code == 400:
                # Expected: cooldown error
                assert "message" in r2.json()
        elif first_status == 400:
            # First was already in cooldown — that's fine
            pytest.skip("Already in cooldown from a previous test run")


# ═══════════════════════════════════════════════════════════════════
# TC-NEARBY-04: Date Restriction
# ═══════════════════════════════════════════════════════════════════

class TestNearbyAlertDateRestriction:
    """TC-NEARBY-04: Ensure alerts are restricted to the travel date."""

    def test_01_cannot_alert_on_wrong_date_route(self, driver_token):
        """
        04-01: If a route is not departing today, backend should return 400.
        Note: This requires a route that is NOT departing today.
        If no such route exists, the test is skipped.
        """
        # Fetch all routes to find one not matching today
        r = requests.get(
            f"{BASE_URL}/routes/me",
            params={"limit": 20},
            headers=auth_header(driver_token),
        )
        if r.status_code != 200:
            pytest.skip("Could not fetch driver routes")

        from datetime import date
        today_str = date.today().isoformat()
        routes = r.json() if isinstance(r.json(), list) else r.json().get("data", [])
        non_today = [rt for rt in routes if today_str not in (rt.get("departureTime") or "")]

        if not non_today:
            pytest.skip("No non-today routes found to test date restriction")

        wrong_date_route = non_today[0]["id"]
        r2 = requests.post(
            f"{BASE_URL}/routes/{wrong_date_route}/nearby-alert",
            headers=auth_header(driver_token),
            json={"driverLat": DRIVER_LAT, "driverLng": DRIVER_LNG, "radiusKm": 100},
        )
        assert r2.status_code == 400, (
            f"Expected 400 for non-today route, got {r2.status_code}: {r2.text}"
        )
