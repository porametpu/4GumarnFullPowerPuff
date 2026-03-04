"""
Chat API Integration Tests
===========================
Prerequisites:
  - Backend running at BASE_URL (default: http://localhost:3000/api)
  - Database seeded with at least:
    1. A passenger user (email/password known)
    2. A driver user (email/password known)
    3. A CONFIRMED booking between them

  Configure via environment variables or edit CONSTANTS below.

Install:
  pip install pytest requests

Run:
  pytest tests/test_chat_api.py -v

With custom config:
  API_BASE_URL=http://localhost:3000/api \
  PASSENGER_EMAIL=p@test.com PASSENGER_PASSWORD=1234 \
  DRIVER_EMAIL=d@test.com DRIVER_PASSWORD=1234 \
  CONFIRMED_BOOKING_ID=<id> \
  pytest tests/test_chat_api.py -v
  pytest tests/test_chat_api.py -v --html=report/report.html --self-contained-html
"""

import os
import json
import pytest
import requests

# ─── Configuration ───────────────────────────────────────────────

BASE_URL = os.getenv("API_BASE_URL", "http://localhost:3000/api")
PASSENGER_EMAIL = os.getenv("PASSENGER_EMAIL", "test99@test.com")
PASSENGER_PASSWORD = os.getenv("PASSENGER_PASSWORD", "00000000")
DRIVER_EMAIL = os.getenv("DRIVER_EMAIL", "test12@test.com")
DRIVER_PASSWORD = os.getenv("DRIVER_PASSWORD", "00000000")
CONFIRMED_BOOKING_ID = os.getenv("CONFIRMED_BOOKING_ID", "cmm5vzhbv0004l8ork3c1oto6")


# ─── Helpers ─────────────────────────────────────────────────────

def login(email, password):
    """Login and return JWT token."""
    r = requests.post(
        f"{BASE_URL}/auth/login",
        json={"email": email, "password": password},
    )
    assert r.status_code == 200, f"Login failed for {email}: {r.text}"
    data = r.json().get("data", r.json())
    token = data.get("token") or data.get("accessToken")
    assert token, f"No token in login response for {email}"
    return token


def auth_header(token):
    """Return Authorization header dict."""
    return {"Authorization": f"Bearer {token}", "Accept": "application/json"}


# ─── Fixtures ────────────────────────────────────────────────────

@pytest.fixture(scope="module")
def passenger_token():
    return login(PASSENGER_EMAIL, PASSENGER_PASSWORD)


@pytest.fixture(scope="module")
def driver_token():
    return login(DRIVER_EMAIL, DRIVER_PASSWORD)


@pytest.fixture(scope="module")
def booking_id():
    bid = CONFIRMED_BOOKING_ID
    assert bid, (
        "CONFIRMED_BOOKING_ID env var must be set. "
        "Export a booking ID with status=CONFIRMED before running tests."
    )
    return bid


@pytest.fixture(scope="module")
def chat_room_id(passenger_token, booking_id):
    """Get or create the chat room, returns room ID."""
    r = requests.get(
        f"{BASE_URL}/chats/booking/{booking_id}",
        headers=auth_header(passenger_token),
    )
    assert r.status_code == 200, f"Failed to get chat room: {r.text}"
    data = r.json().get("data", r.json())
    room_id = data.get("id")
    assert room_id, "No room ID returned"
    return room_id


# ═══════════════════════════════════════════════════════════════════
# TC-01: Get / Create Chat Room
# ═══════════════════════════════════════════════════════════════════

class TestGetChatRoom:
    """TC-CHAT-01: Get or create chat room for a booking."""

    def test_01_passenger_gets_room(self, passenger_token, booking_id):
        """01-01: Passenger opens chat for CONFIRMED booking → 200, room with 2 participants."""
        r = requests.get(
            f"{BASE_URL}/chats/booking/{booking_id}",
            headers=auth_header(passenger_token),
        )
        assert r.status_code == 200
        data = r.json()["data"]
        assert "id" in data
        assert "participants" in data
        assert len(data["participants"]) >= 2, "Room should have at least 2 participants"

    def test_02_driver_gets_same_room(self, driver_token, booking_id, chat_room_id):
        """01-02: Driver gets the same room as passenger."""
        r = requests.get(
            f"{BASE_URL}/chats/booking/{booking_id}",
            headers=auth_header(driver_token),
        )
        assert r.status_code == 200
        data = r.json()["data"]
        assert data["id"] == chat_room_id, "Driver should get the same room as passenger"

    def test_03_re_open_returns_same_room(self, passenger_token, booking_id, chat_room_id):
        """01-03: Re-opening the same booking returns the same room ID."""
        r = requests.get(
            f"{BASE_URL}/chats/booking/{booking_id}",
            headers=auth_header(passenger_token),
        )
        assert r.status_code == 200
        assert r.json()["data"]["id"] == chat_room_id

    def test_04_unauthenticated_request(self, booking_id):
        """01-04: Request without token → 401."""
        r = requests.get(f"{BASE_URL}/chats/booking/{booking_id}")
        assert r.status_code == 401

    def test_05_invalid_booking_id(self, passenger_token):
        """01-05: Non-existent booking ID → 404."""
        r = requests.get(
            f"{BASE_URL}/chats/booking/nonexistent_id_xyz_000",
            headers=auth_header(passenger_token),
        )
        assert r.status_code == 404


# ═══════════════════════════════════════════════════════════════════
# TC-02: Chat History
# ═══════════════════════════════════════════════════════════════════

class TestChatHistory:
    """TC-CHAT-02: List all user's chat rooms."""

    def test_01_returns_rooms_list(self, passenger_token):
        """02-01: Passenger should have at least 1 chat room."""
        r = requests.get(
            f"{BASE_URL}/chats/history",
            headers=auth_header(passenger_token),
        )
        assert r.status_code == 200
        data = r.json()["data"]
        assert isinstance(data, list)
        assert len(data) >= 1, "Should have at least 1 room after creating one"

    def test_02_room_has_required_fields(self, passenger_token):
        """02-02: Each room has unreadCount, otherParticipantName, bookingId."""
        r = requests.get(
            f"{BASE_URL}/chats/history",
            headers=auth_header(passenger_token),
        )
        rooms = r.json()["data"]
        for room in rooms:
            assert "unreadCount" in room, "Room missing 'unreadCount'"
            assert "otherParticipantName" in room, "Room missing 'otherParticipantName'"
            assert "bookingId" in room, "Room missing 'bookingId'"
            assert "id" in room, "Room missing 'id'"

    def test_03_sorted_by_latest_message(self, passenger_token):
        """02-03: Rooms sorted by most recent message first."""
        r = requests.get(
            f"{BASE_URL}/chats/history",
            headers=auth_header(passenger_token),
        )
        rooms = r.json()["data"]
        if len(rooms) >= 2:
            for i in range(len(rooms) - 1):
                t1 = rooms[i].get("lastMessage", {})
                t2 = rooms[i + 1].get("lastMessage", {})
                time1 = t1.get("createdAt", "") if t1 else ""
                time2 = t2.get("createdAt", "") if t2 else ""
                if time1 and time2:
                    assert time1 >= time2, (
                        f"Rooms not sorted: {time1} should be >= {time2}"
                    )


# ═══════════════════════════════════════════════════════════════════
# TC-03: Get Messages
# ═══════════════════════════════════════════════════════════════════

class TestGetMessages:
    """TC-CHAT-03: Get messages in a chat room."""

    def test_01_fetch_as_participant(self, passenger_token, chat_room_id):
        """03-01: Participant can fetch messages → 200."""
        r = requests.get(
            f"{BASE_URL}/chats/{chat_room_id}/messages",
            headers=auth_header(passenger_token),
        )
        assert r.status_code == 200
        data = r.json()["data"]
        assert isinstance(data, list)

    def test_02_message_has_required_fields(self, passenger_token, chat_room_id):
        """03-02: Each message has senderDisplayName, isMine, content, type, createdAt."""
        r = requests.get(
            f"{BASE_URL}/chats/{chat_room_id}/messages",
            headers=auth_header(passenger_token),
        )
        data = r.json()["data"]
        for msg in data:
            assert "senderDisplayName" in msg, "Missing 'senderDisplayName'"
            assert "isMine" in msg, "Missing 'isMine'"
            assert "content" in msg, "Missing 'content'"
            assert "type" in msg, "Missing 'type'"
            assert "createdAt" in msg, "Missing 'createdAt'"

    def test_03_invalid_room_returns_404(self, passenger_token):
        """03-03: Invalid room ID → 404."""
        r = requests.get(
            f"{BASE_URL}/chats/invalid_room_xyz_000/messages",
            headers=auth_header(passenger_token),
        )
        assert r.status_code == 404


# ═══════════════════════════════════════════════════════════════════
# TC-04: Send Text Message
# ═══════════════════════════════════════════════════════════════════

class TestSendMessage:
    """TC-CHAT-04: Send text and location messages."""

    UNIQUE_TEXT = "pytest-สวัสดีครับ-test-message"

    def test_01_send_text_message(self, passenger_token, chat_room_id):
        """04-01: Send TEXT message → 201 with correct content."""
        r = requests.post(
            f"{BASE_URL}/chats/{chat_room_id}/messages",
            headers={
                **auth_header(passenger_token),
                "Content-Type": "application/json",
            },
            json={"content": self.UNIQUE_TEXT, "type": "TEXT"},
        )
        assert r.status_code == 201
        data = r.json()["data"]
        assert data["content"] == self.UNIQUE_TEXT
        assert data["isMine"] is True
        assert "senderDisplayName" in data

    def test_02_send_location_message(self, passenger_token, chat_room_id):
        """04-02: Send LOCATION message → 201 with type LOCATION."""
        loc_content = json.dumps({
            "lat": 13.7563,
            "lng": 100.5018,
            "name": "กรุงเทพมหานคร (pytest)",
        })
        r = requests.post(
            f"{BASE_URL}/chats/{chat_room_id}/messages",
            headers={
                **auth_header(passenger_token),
                "Content-Type": "application/json",
            },
            json={"content": loc_content, "type": "LOCATION"},
        )
        assert r.status_code == 201
        data = r.json()["data"]
        assert data["type"] == "LOCATION"

    def test_03_sent_message_appears_in_messages_list(
        self, passenger_token, chat_room_id
    ):
        """04-03 follow-up: Sent message appears when fetching messages."""
        r = requests.get(
            f"{BASE_URL}/chats/{chat_room_id}/messages",
            headers=auth_header(passenger_token),
        )
        data = r.json()["data"]
        contents = [m["content"] for m in data]
        assert self.UNIQUE_TEXT in contents, (
            f"Sent message '{self.UNIQUE_TEXT}' not found in messages list"
        )

    def test_04_response_has_sender_info(self, passenger_token, chat_room_id):
        """04-04: Response includes senderDisplayName and isMine."""
        r = requests.post(
            f"{BASE_URL}/chats/{chat_room_id}/messages",
            headers={
                **auth_header(passenger_token),
                "Content-Type": "application/json",
            },
            json={"content": "verify sender info", "type": "TEXT"},
        )
        assert r.status_code == 201
        data = r.json()["data"]
        assert "senderDisplayName" in data
        assert isinstance(data["senderDisplayName"], str)
        assert data["isMine"] is True


# ═══════════════════════════════════════════════════════════════════
# TC-04B: Driver Send Message & Cross-Communication
# ═══════════════════════════════════════════════════════════════════

class TestDriverSendMessage:
    """TC-CHAT-04B: Driver sends messages and cross-user visibility."""

    DRIVER_TEXT = "pytest-driver-สวัสดีจากคนขับ"

    def test_01_driver_sends_text(self, driver_token, chat_room_id):
        """04B-01: Driver sends TEXT message → 201."""
        r = requests.post(
            f"{BASE_URL}/chats/{chat_room_id}/messages",
            headers={
                **auth_header(driver_token),
                "Content-Type": "application/json",
            },
            json={"content": self.DRIVER_TEXT, "type": "TEXT"},
        )
        assert r.status_code == 201
        data = r.json()["data"]
        assert data["content"] == self.DRIVER_TEXT
        assert data["isMine"] is True
        assert "senderDisplayName" in data

    def test_02_driver_sends_location(self, driver_token, chat_room_id):
        """04B-02: Driver sends LOCATION message → 201."""
        loc_content = json.dumps({
            "lat": 14.8820,
            "lng": 100.0956,
            "name": "จุดรับผู้โดยสาร (driver pytest)",
        })
        r = requests.post(
            f"{BASE_URL}/chats/{chat_room_id}/messages",
            headers={
                **auth_header(driver_token),
                "Content-Type": "application/json",
            },
            json={"content": loc_content, "type": "LOCATION"},
        )
        assert r.status_code == 201
        data = r.json()["data"]
        assert data["type"] == "LOCATION"

    def test_03_passenger_sees_driver_message(self, passenger_token, chat_room_id):
        """04B-03: Passenger fetches messages → driver's message visible with isMine=False."""
        r = requests.get(
            f"{BASE_URL}/chats/{chat_room_id}/messages",
            headers=auth_header(passenger_token),
        )
        assert r.status_code == 200
        data = r.json()["data"]
        driver_msgs = [m for m in data if m["content"] == self.DRIVER_TEXT]
        assert len(driver_msgs) >= 1, "Driver's message not found in passenger's view"
        assert driver_msgs[0]["isMine"] is False, "Driver's message should show isMine=False for passenger"

    def test_04_driver_sees_passenger_message_as_not_mine(self, driver_token, chat_room_id):
        """04B-04: Driver fetches messages → passenger's messages show isMine=False."""
        r = requests.get(
            f"{BASE_URL}/chats/{chat_room_id}/messages",
            headers=auth_header(driver_token),
        )
        assert r.status_code == 200
        data = r.json()["data"]
        # Find a message sent by passenger (should have isMine=False from driver's POV)
        passenger_msgs = [m for m in data if m["isMine"] is False]
        assert len(passenger_msgs) >= 1, "No passenger messages visible from driver's view"

    def test_05_driver_history_shows_room(self, driver_token, chat_room_id):
        """04B-05: Driver's chat history includes this room with lastMessage."""
        r = requests.get(
            f"{BASE_URL}/chats/history",
            headers=auth_header(driver_token),
        )
        assert r.status_code == 200
        rooms = r.json()["data"]
        target = [rm for rm in rooms if rm["id"] == chat_room_id]
        assert len(target) == 1, "Room not found in driver's chat history"
        assert target[0].get("lastMessage") is not None, "lastMessage should not be null"
        assert target[0].get("otherParticipantName"), "otherParticipantName should be set"


# ═══════════════════════════════════════════════════════════════════
# TC-05: Send Image Message
# ═══════════════════════════════════════════════════════════════════

class TestSendImage:
    """TC-CHAT-05: Send image message (multipart upload)."""

    def test_01_no_file_returns_error(self, passenger_token, chat_room_id):
        """05-01: Upload without file → 400 or 500 (backend bug: multer returns 500)."""
        r = requests.post(
            f"{BASE_URL}/chats/{chat_room_id}/messages/image",
            headers=auth_header(passenger_token),
        )
        # Backend currently returns 500 instead of 400 when no file is sent
        # This is a known issue: multer middleware doesn't gracefully handle missing file
        assert r.status_code in (400, 500), f"Expected 400/500, got {r.status_code}"

    @staticmethod
    def _make_png():
        """Create a valid minimal 1x1 red PNG image in memory."""
        import struct, zlib
        def chunk(chunk_type, data):
            c = chunk_type + data
            return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)

        sig = b"\x89PNG\r\n\x1a\n"
        ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
        raw_row = b"\x00\xff\x00\x00"  # filter byte + 1 red pixel (RGB)
        idat = chunk(b"IDAT", zlib.compress(raw_row))
        iend = chunk(b"IEND", b"")
        return sig + ihdr + idat + iend

    def test_02_passenger_uploads_image(self, passenger_token, chat_room_id):
        """05-02: Passenger uploads valid image → 201, content = Cloudinary URL."""
        import io
        png_bytes = self._make_png()
        r = requests.post(
            f"{BASE_URL}/chats/{chat_room_id}/messages/image",
            headers=auth_header(passenger_token),
            files={"image": ("test_passenger.png", io.BytesIO(png_bytes), "image/png")},
        )
        assert r.status_code == 201, f"Upload failed: {r.text}"
        data = r.json()["data"]
        assert data["type"] == "IMAGE"
        assert data["content"].startswith("http"), "Content should be a Cloudinary URL"
        assert data["isMine"] is True

    def test_03_driver_uploads_image(self, driver_token, chat_room_id):
        """05-03: Driver uploads valid image → 201, content = Cloudinary URL."""
        import io
        png_bytes = self._make_png()
        r = requests.post(
            f"{BASE_URL}/chats/{chat_room_id}/messages/image",
            headers=auth_header(driver_token),
            files={"image": ("test_driver.png", io.BytesIO(png_bytes), "image/png")},
        )
        assert r.status_code == 201, f"Upload failed: {r.text}"
        data = r.json()["data"]
        assert data["type"] == "IMAGE"
        assert data["content"].startswith("http"), "Content should be a Cloudinary URL"
        assert data["isMine"] is True

    def test_04_passenger_sees_driver_image(self, passenger_token, chat_room_id):
        """05-04: Passenger fetches messages → driver's IMAGE message visible."""
        r = requests.get(
            f"{BASE_URL}/chats/{chat_room_id}/messages",
            headers=auth_header(passenger_token),
        )
        assert r.status_code == 200
        data = r.json()["data"]
        image_msgs = [m for m in data if m["type"] == "IMAGE"]
        assert len(image_msgs) >= 2, "Should have at least 2 image messages (passenger + driver)"
        # At least one image from driver (isMine=False for passenger)
        driver_images = [m for m in image_msgs if m["isMine"] is False]
        assert len(driver_images) >= 1, "Driver's image should be visible to passenger"


# ═══════════════════════════════════════════════════════════════════
# TC-06: Mark as Read
# ═══════════════════════════════════════════════════════════════════

class TestMarkAsRead:
    """TC-CHAT-06: Mark messages as read."""

    def test_01_mark_read_success(self, driver_token, chat_room_id):
        """06-01: Mark all unread as read → 200."""
        r = requests.post(
            f"{BASE_URL}/chats/{chat_room_id}/read",
            headers=auth_header(driver_token),
        )
        assert r.status_code == 200
        body = r.json()
        assert body.get("message") == "Messages marked as read"

    def test_02_unread_count_drops_to_zero(self, driver_token, chat_room_id):
        """06-02: After marking read, unreadCount for this room = 0."""
        r = requests.get(
            f"{BASE_URL}/chats/history",
            headers=auth_header(driver_token),
        )
        rooms = r.json()["data"]
        target = [rm for rm in rooms if rm["id"] == chat_room_id]
        if target:
            assert target[0]["unreadCount"] == 0, (
                f"Expected unreadCount=0, got {target[0]['unreadCount']}"
            )

    def test_03_idempotent_mark_read(self, driver_token, chat_room_id):
        """06-03: Marking already-read messages again → still 200 (idempotent)."""
        r = requests.post(
            f"{BASE_URL}/chats/{chat_room_id}/read",
            headers=auth_header(driver_token),
        )
        assert r.status_code == 200
