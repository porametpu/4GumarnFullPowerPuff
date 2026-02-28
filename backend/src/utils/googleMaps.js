const axios = require('axios');

const LONGDO_MAP_API_KEY = process.env.LONGDO_MAP_API_KEY;

const ensureKey = () => {
    if (!LONGDO_MAP_API_KEY) {
        throw new Error('LONGDO_MAP_API_KEY is missing');
    }
};

// origin/destination รับได้ทั้ง {lat,lng} หรือ [lat,lng]
const normalizeLocation = (loc) => {
    if (!loc) return null;
    if (typeof loc.lat === 'number' && typeof loc.lng === 'number') {
        return { lat: loc.lat, lng: loc.lng };
    }
    if (typeof loc.lat === 'number' && typeof loc.lon === 'number') {
        return { lat: loc.lat, lng: loc.lon };
    }
    if (Array.isArray(loc) && loc.length >= 2) {
        return { lat: Number(loc[0]), lng: Number(loc[1]) };
    }
    return null;
};

const toLonLatParam = (loc) => {
    const p = normalizeLocation(loc);
    if (!p) return null;
    return { lon: p.lng, lat: p.lat };
};

const formatDistance = (meters) => {
    if (meters == null || Number.isNaN(meters)) return null;
    if (meters >= 1000) return `${(meters / 1000).toFixed(1)} กม.`;
    return `${Math.round(meters)} ม.`;
};

const formatDuration = (seconds) => {
    if (seconds == null || Number.isNaN(seconds)) return null;
    const mins = Math.round(seconds / 60);
    const h = Math.floor(mins / 60);
    const m = mins % 60;
    if (h > 0) return `${h} ชม. ${m} นาที`;
    return `${m} นาที`;
};

const estimateDurationSeconds = (meters, speedKmh = 50) => {
    if (meters == null || Number.isNaN(meters)) return null;
    const speedMs = (speedKmh * 1000) / 3600;
    return Math.round(meters / speedMs);
};

const encodeSignedNumber = (num) => {
    let s = num < 0 ? ~(num << 1) : num << 1;
    let out = '';
    while (s >= 0x20) {
        out += String.fromCharCode((0x20 | (s & 0x1f)) + 63);
        s >>= 5;
    }
    out += String.fromCharCode(s + 63);
    return out;
};

const encodePolyline = (points = []) => {
    let lastLat = 0;
    let lastLng = 0;
    let result = '';
    for (const p of points) {
        const lat = Math.round(p.lat * 1e5);
        const lng = Math.round(p.lng * 1e5);
        const dLat = lat - lastLat;
        const dLng = lng - lastLng;
        result += encodeSignedNumber(dLat) + encodeSignedNumber(dLng);
        lastLat = lat;
        lastLng = lng;
    }
    return result || null;
};

const normalizePoint = (p) => {
    if (!p) return null;
    if (Array.isArray(p) && p.length >= 2) {
        const a = Number(p[0]);
        const b = Number(p[1]);
        if (Math.abs(a) > 90 && Math.abs(b) <= 90) return { lat: b, lng: a }; // [lon, lat]
        if (Math.abs(b) > 90 && Math.abs(a) <= 90) return { lat: a, lng: b }; // [lat, lon]
        return { lat: b, lng: a };
    }
    if (typeof p.lat === 'number' && typeof p.lon === 'number') return { lat: p.lat, lng: p.lon };
    if (typeof p.lat === 'number' && typeof p.lng === 'number') return { lat: p.lat, lng: p.lng };
    return null;
};

const extractPathPoints = (raw) => {
    const root = raw?.data ?? raw?.path ?? raw?.route ?? raw;
    if (!root) return [];
    if (Array.isArray(root)) {
        return root.map(normalizePoint).filter(Boolean);
    }
    if (Array.isArray(root?.path)) {
        return root.path.map(normalizePoint).filter(Boolean);
    }
    if (Array.isArray(root?.routes?.[0]?.path)) {
        return root.routes[0].path.map(normalizePoint).filter(Boolean);
    }
    return [];
};

const buildStops = (origin, waypoints = [], destination) => {
    const stops = [origin, ...(Array.isArray(waypoints) ? waypoints : []), destination]
        .map(normalizeLocation)
        .filter(Boolean)
        .map(p => ({ lat: p.lat, lng: p.lng }));
    return stops;
};

const fetchGuide = async ({ from, to, departureTime }) => {
    const params = {
        flon: from.lng,
        flat: from.lat,
        tlon: to.lng,
        tlat: to.lat,
        mode: 't', // fastest + avoid traffic
        type: 25,  // road + ferry + tollway
        locale: 'th',
        key: LONGDO_MAP_API_KEY,
    };
    if (departureTime) {
        const t = Math.floor(new Date(departureTime).getTime() / 1000);
        if (!Number.isNaN(t)) params.time = t;
    }

    const url = 'https://api.longdo.com/RouteService/json/route/guide';

    const tryRequest = async (p) => {
        const { data } = await axios.get(url, { params: p });
        return data;
    };

    try {
        return await tryRequest(params);
    } catch (err) {
        const status = err?.response?.status;
        const hasTime = Object.prototype.hasOwnProperty.call(params, 'time');

        // Some Longdo responses return 500 when time-based routing is unsupported.
        // Retry once without "time", then fallback to standard driving mode.
        if (status >= 500 && hasTime) {
            const retryParams = { ...params };
            delete retryParams.time;

            try {
                return await tryRequest(retryParams);
            } catch (retryErr) {
                if ((retryErr?.response?.status || 0) >= 500) {
                    const fallbackParams = { ...retryParams, mode: 'd' };
                    return await tryRequest(fallbackParams);
                }
                throw retryErr;
            }
        }

        throw err;
    }
};

const fetchPath = async (id) => {
    if (!id) return null;
    const { data } = await axios.get('https://api.longdo.com/RouteService/json/route/path', {
        params: { id, key: LONGDO_MAP_API_KEY }
    });
    return data;
};

const getDirections = async ({ origin, destination, waypoints = [], departureTime }) => {
    ensureKey();
    const stops = buildStops(origin, waypoints, destination);
    if (stops.length < 2) {
        throw new Error('Invalid origin/destination');
    }
    const segmentResults = [];
    for (let i = 0; i < stops.length - 1; i++) {
        const from = stops[i];
        const to = stops[i + 1];
        const guideRes = await fetchGuide({ from, to, departureTime });
        const guide = guideRes?.data?.[0] || null;
        const pathRes = guide?.id ? await fetchPath(guide.id) : null;
        const pathPoints = extractPathPoints(pathRes);
        segmentResults.push({ from, to, guide, pathPoints });
    }

    const distanceMeters = segmentResults.reduce((sum, s) => sum + (s.guide?.distance || 0), 0);
    const durationSeconds = segmentResults.reduce((sum, s) => sum + (s.guide?.interval || 0), 0);
    const steps = segmentResults.flatMap((s) => {
        const g = s.guide?.guide || [];
        return g.map((step) => ({
            html_instructions: step.name || '',
            distance: typeof step.distance === 'number'
                ? { value: Math.round(step.distance), text: formatDistance(step.distance) }
                : null,
            duration: typeof step.interval === 'number'
                ? { value: Math.round(step.interval), text: formatDuration(step.interval) }
                : null,
            start_location: null,
            end_location: null,
            travel_mode: 'DRIVING',
            maneuver: null,
        }));
    });

    const pathPoints = [];
    segmentResults.forEach((s, idx) => {
        if (!s.pathPoints?.length) return;
        if (idx > 0 && pathPoints.length) {
            // avoid duplicate joint point
            const last = pathPoints[pathPoints.length - 1];
            const first = s.pathPoints[0];
            if (last.lat === first.lat && last.lng === first.lng) {
                pathPoints.push(...s.pathPoints.slice(1));
                return;
            }
        }
        pathPoints.push(...s.pathPoints);
    });

    const polyline = pathPoints.length ? encodePolyline(pathPoints) : null;

    return {
        routes: [
            {
                summary: segmentResults[0]?.guide?.guide?.[0]?.name || null,
                legs: [
                    {
                        distance: distanceMeters != null ? { value: distanceMeters, text: formatDistance(distanceMeters) } : null,
                        duration: durationSeconds != null ? { value: durationSeconds, text: formatDuration(durationSeconds) } : null,
                        start_location: { lat: stops[0].lat, lng: stops[0].lng },
                        end_location: { lat: stops[stops.length - 1].lat, lng: stops[stops.length - 1].lng },
                        steps
                    }
                ],
                overview_polyline: polyline ? { points: polyline } : null,
                waypoint_order: []
            }
        ],
        routePath: pathPoints
    };
};

const geocode = async (address) => {
    ensureKey();
    const url = 'https://search.longdo.com/addresslookup/api/addr/geocoding';
    const { data } = await axios.get(url, { params: { text: address, key: LONGDO_MAP_API_KEY } });
    return data;
};

const reverseGeocode = async (lat, lng) => {
    ensureKey();
    const url = 'https://api.longdo.com/map/services/address';
    const { data } = await axios.get(url, { params: { lat, lon: lng, locale: 'th', key: LONGDO_MAP_API_KEY } });
    return data;
};

const suggest = async (keyword) => {
    ensureKey();
    const url = 'https://search.longdo.com/mapsearch/json/suggest';
    const { data } = await axios.get(url, { params: { keyword, key: LONGDO_MAP_API_KEY } });
    return data;
};

const search = async (keyword) => {
    ensureKey();
    const url = 'https://search.longdo.com/mapsearch/json/search';
    const { data } = await axios.get(url, { params: { keyword, key: LONGDO_MAP_API_KEY, locale: 'th' } });
    return data;
};

module.exports = { getDirections, geocode, reverseGeocode, suggest, search };
