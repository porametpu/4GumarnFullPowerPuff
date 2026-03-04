<template>
    <div>
        <AdminHeader />
        <AdminSidebar />

        <main id="main-content" class="main-content mt-16 ml-0 lg:ml-[280px] p-6">
            <!-- Back -->
            <div class="mb-8">
                <NuxtLink to="/admin/routes"
                    class="inline-flex items-center gap-2 px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50">
                    <i class="fa-solid fa-arrow-left"></i>
                    <span>ย้อนกลับ</span>
                </NuxtLink>
            </div>

            <div class="mx-auto max-w-8xl">
                <!-- Title (เหมือนหน้า users) -->
                <div class="flex flex-col gap-3 mb-6 sm:flex-row sm:items-center sm:justify-between">
                    <div class="flex items-center gap-3">
                        <h1 class="text-2xl font-semibold text-gray-800">รายละเอียดเส้นทาง</h1>
                        <span class="text-sm text-gray-500">ดูข้อมูลทั้งหมดของ Route</span>
                    </div>
                    <!-- ที่วางปุ่ม/สวิตช์ในอนาคต (รอ API) -->
                </div>

                <!-- Card หลัก (โครงเดียวกับหน้า users/[id]) -->
                <div class="bg-white border border-gray-300 rounded-lg shadow-sm">
                    <div class="px-4 py-4 border-b border-gray-200 sm:px-6">
                        <h2 class="font-medium text-gray-800">ข้อมูลเส้นทาง</h2>
                    </div>

                    <!-- Loading / Error -->
                    <div v-if="isLoading" class="p-8 text-center text-gray-500">กำลังโหลดข้อมูล...</div>
                    <div v-else-if="loadError" class="p-8 text-center text-red-600">{{ loadError }}</div>

                    <!-- Content -->
                    <div v-else class="grid grid-cols-1 gap-6 p-4 sm:p-6 text-[15px]">
                        <div class="w-full max-w-[80rem] mx-auto space-y-6">

                            <!-- แผนที่เส้นทาง -->
                            <section>
                                <h3 class="mb-3 text-sm font-semibold text-gray-700">แผนที่เส้นทาง</h3>
                                <div class="overflow-hidden border border-gray-300 rounded-lg">
                                    <div ref="mapEl" class="w-full" style="height: 400px;"></div>
                                </div>
                            </section>

                            <!-- เส้นทาง (ต้นทาง/ปลายทาง) -->
                            <section>
                                <h3 class="mb-3 text-sm font-semibold text-gray-700">เส้นทาง</h3>
                                <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                                    <div>
                                        <label class="block mb-1 text-xs font-medium text-gray-600">จุดเริ่มต้น</label>
                                        <div
                                            class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50 text-gray-900">
                                            {{ routeData?.originName || '-' }}
                                            <div v-if="routeData?.originAddress" class="mt-1 text-xs text-gray-500">
                                                {{ routeData.originAddress }}
                                            </div>
                                        </div>
                                    </div>
                                    <div>
                                        <label class="block mb-1 text-xs font-medium text-gray-600">จุดปลายทาง</label>
                                        <div
                                            class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50 text-gray-900">
                                            {{ routeData?.destinationName || '-' }}
                                            <div v-if="routeData?.destinationAddress"
                                                class="mt-1 text-xs text-gray-500">
                                                {{ routeData.destinationAddress }}
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="grid grid-cols-1 gap-4 mt-4 sm:grid-cols-2">
                                    <div>
                                        <label
                                            class="block mb-1 text-xs font-medium text-gray-600">ระยะเวลาโดยประมาณ</label>
                                        <div
                                            class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50 text-gray-900">
                                            {{ routeData?.durationText || '-' }}
                                        </div>
                                    </div>
                                    <div>
                                        <label
                                            class="block mb-1 text-xs font-medium text-gray-600">ระยะทางโดยประมาณ</label>
                                        <div
                                            class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50 text-gray-900">
                                            {{ routeData?.distanceText || '-' }}
                                        </div>
                                    </div>
                                </div>
                            </section>

                            <!-- จุดแวะระหว่างทาง -->
                            <section>
                                <h3 class="mb-3 text-sm font-semibold text-gray-700">จุดแวะระหว่างทาง</h3>
                                <div class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50">
                                    <template v-if="routeData?.stops?.length">
                                        <ul class="space-y-1 text-gray-700">
                                            <li v-for="(s, idx) in routeData.stops" :key="idx">• {{ s }}</li>
                                        </ul>
                                    </template>
                                    <template v-else>
                                        <div class="text-gray-500">— ไม่มีจุดแวะ —</div>
                                    </template>
                                </div>
                            </section>

                            <!-- รายละเอียดเวลา/ราคา/ที่นั่ง/ระยะทาง -->
                            <section>
                                <h3 class="mb-3 text-sm font-semibold text-gray-700">เวลา ราคา และความพร้อมที่นั่ง</h3>
                                <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
                                    <div>
                                        <label
                                            class="block mb-1 text-xs font-medium text-gray-600">วัน-เวลาออกเดินทาง</label>
                                        <div class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50">
                                            <div class="text-gray-900">{{ routeData?.date || '-' }} {{
                                                routeData?.departureTime || '' }}</div>

                                        </div>
                                    </div>
                                    <div>
                                        <label class="block mb-1 text-xs font-medium text-gray-600">ราคา/ที่นั่ง</label>
                                        <div
                                            class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50 text-gray-900">
                                            {{ routeData?.price != null ? `${routeData.price} บาท` : '-' }}
                                        </div>
                                    </div>
                                    <div>
                                        <label
                                            class="block mb-1 text-xs font-medium text-gray-600">ที่นั่งคงเหลือ</label>
                                        <div
                                            class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50 text-gray-900">
                                            {{ routeData?.availableSeats != null ? routeData.availableSeats : '-' }}
                                        </div>
                                    </div>
                                </div>

                                <!-- <div class="grid grid-cols-1 gap-4 mt-4 sm:grid-cols-2">
                                    <div>
                                        <label
                                            class="block mb-1 text-xs font-medium text-gray-600">ระยะเวลาโดยประมาณ</label>
                                        <div
                                            class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50 text-gray-900">
                                            {{ routeData?.durationText || '-' }}
                                        </div>
                                    </div>
                                    <div>
                                        <label
                                            class="block mb-1 text-xs font-medium text-gray-600">ระยะทางโดยประมาณ</label>
                                        <div
                                            class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50 text-gray-900">
                                            {{ routeData?.distanceText || '-' }}
                                        </div>
                                    </div>
                                </div> -->
                            </section>



                            <!-- ผู้ขับขี่ -->
                            <section>
                                <h3 class="mb-3 text-sm font-semibold text-gray-700">ผู้ขับขี่</h3>
                                <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                                    <div>
                                        <label class="block mb-1 text-xs font-medium text-gray-600">ชื่อผู้ขับ</label>
                                        <div
                                            class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50 text-gray-900">
                                            {{ routeData?.driver?.name || '-' }}
                                        </div>
                                    </div>
                                    <div>
                                        <label
                                            class="block mb-1 text-xs font-medium text-gray-600">การยืนยันตัวตน</label>
                                        <div
                                            class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50 text-gray-900">
                                            {{ routeData?.driver?.isVerified ? 'ยืนยันแล้ว' : 'ยังไม่ยืนยัน' }}
                                        </div>
                                    </div>
                                </div>
                            </section>

                            <!-- รายละเอียดรถ -->
                            <section>
                                <h3 class="mb-3 text-sm font-semibold text-gray-700">รายละเอียดรถ</h3>
                                <div class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50">
                                    <template v-if="routeData?.carDetails?.length">
                                        <ul class="space-y-1 text-gray-700">
                                            <li v-for="(d, idx) in routeData.carDetails" :key="idx">• {{ d }}</li>
                                        </ul>
                                    </template>
                                    <template v-else>
                                        <div class="text-gray-500">— ไม่มีข้อมูลรถ —</div>
                                    </template>
                                </div>
                            </section>

                            <!-- เงื่อนไข -->
                            <section v-if="routeData?.conditions">
                                <h3 class="mb-3 text-sm font-semibold text-gray-700">เงื่อนไขการเดินทาง</h3>
                                <div
                                    class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50 text-gray-900">
                                    {{ routeData.conditions }}
                                </div>
                            </section>

                            <!-- รูปภาพรถ -->
                            <section>
                                <h3 class="mb-3 text-sm font-semibold text-gray-700">รูปภาพรถยนต์</h3>
                                <div class="grid grid-cols-3 gap-2">
                                    <template v-if="routeData?.photos?.length">
                                        <div v-for="(photo, idx) in routeData.photos.slice(0, 3)" :key="idx">
                                            <img :src="photo" alt="Vehicle"
                                                class="object-cover w-full transition-opacity border border-gray-300 rounded-lg shadow-sm aspect-video hover:opacity-90">
                                        </div>
                                    </template>
                                    <div v-else
                                        class="col-span-3 p-4 text-center text-gray-500 border border-gray-300 rounded-md bg-gray-50">
                                        <i class="text-3xl fa-regular fa-image"></i>
                                        <p class="mt-1 text-sm">ไม่มีรูป</p>
                                    </div>
                                </div>
                            </section>



                            <!-- ระบบ -->
                            <section>
                                <h3 class="mb-3 text-sm font-semibold text-gray-700">ระบบ</h3>
                                <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
                                    <div>
                                        <label class="block mb-1 text-xs font-medium text-gray-600">สร้างเมื่อ</label>
                                        <div
                                            class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50 text-gray-900">
                                            {{ formatDate(routeData?.createdAt, true) }}
                                        </div>
                                    </div>
                                    <div>
                                        <label
                                            class="block mb-1 text-xs font-medium text-gray-600">ปรับปรุงล่าสุด</label>
                                        <div
                                            class="w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50 text-gray-900">
                                            {{ formatDate(routeData?.updatedAt, true) }}
                                        </div>
                                    </div>
                                </div>
                            </section>

                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- Mobile Overlay -->
        <div id="overlay" class="fixed inset-0 z-40 hidden bg-black bg-opacity-50 lg:hidden"
            @click="closeMobileSidebar"></div>
    </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { useRoute, useRuntimeConfig, useCookie } from '#app'
import AdminHeader from '~/components/admin/AdminHeader.vue'
import AdminSidebar from '~/components/admin/AdminSidebar.vue'
import dayjs from 'dayjs'
import 'dayjs/locale/th'
import buddhistEra from 'dayjs/plugin/buddhistEra'
import { useLongdoMap } from '~/composables/useLongdoMap'

dayjs.locale('th')
dayjs.extend(buddhistEra)

definePageMeta({ middleware: ['admin-auth'] })
useHead({
    title: 'ดูรายละเอียดเส้นทาง • Admin',
    link: [{ rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }]
})

const route = useRoute()
const isLoading = ref(true)
const loadError = ref('')
const routeData = ref(null) // โครงข้อมูลที่ map UI ใช้ (ยังไม่ผูก API)
const { loadLongdoMap } = useLongdoMap()

const mapEl = ref(null)
let gmap = null
let activePolyline = null
let startMarker = null
let endMarker = null
let stopMarkers = []
let mapOverlays = []
const mapReady = ref(false)

/* ---------------- helpers (ใช้รูปแบบเดียวกับ findTrip) ---------------- */
function cleanAddr(a) {
    return (a || '').replace(/,?\s*(Thailand|ไทย|ประเทศ)\s*$/i, '').replace(/\s{2,}/g, ' ').trim()
}
function formatDate(iso, withTime = false) {
    if (!iso) return '-'
    return withTime ? dayjs(iso).format('D MMM BBBB HH:mm') : dayjs(iso).format('D MMM BBBB')
}

function waitMapReady() {
    return new Promise((resolve) => {
        if (mapReady.value) return resolve(true)
        const t = setInterval(() => {
            if (mapReady.value) {
                clearInterval(t)
                resolve(true)
            }
        }, 50)
    })
}

/* ---------------- Map (Longdo) ---------------- */
function addOverlay(overlay) {
    if (!gmap || !overlay) return
    gmap.Overlays.add(overlay)
    mapOverlays.push(overlay)
}
function clearMap() {
    if (!gmap) return
    if (mapOverlays.length) {
        mapOverlays.forEach((o) => {
            try { gmap.Overlays.remove(o) } catch { }
        })
    }
    mapOverlays = []
    activePolyline = null
    startMarker = null
    endMarker = null
    stopMarkers = []
}
const decodePolyline = (str, precision = 5) => {
    if (!str) return []
    let index = 0
    let lat = 0
    let lng = 0
    const coordinates = []
    const factor = Math.pow(10, precision)
    while (index < str.length) {
        let b
        let shift = 0
        let result = 0
        do {
            b = str.charCodeAt(index++) - 63
            result |= (b & 0x1f) << shift
            shift += 5
        } while (b >= 0x20)
        const deltaLat = result & 1 ? ~(result >> 1) : result >> 1
        lat += deltaLat

        shift = 0
        result = 0
        do {
            b = str.charCodeAt(index++) - 63
            result |= (b & 0x1f) << shift
            shift += 5
        } while (b >= 0x20)
        const deltaLng = result & 1 ? ~(result >> 1) : result >> 1
        lng += deltaLng

        coordinates.push({ lat: lat / factor, lng: lng / factor })
    }
    return coordinates
}
const coerceLatLng = (item) => {
    if (!item) return null
    const num = (v) => (typeof v === 'string' ? Number(v) : v)
    const lat = num(item.lat)
    const lon = num(item.lon)
    const lng = num(item.lng)
    const latitude = num(item.latitude)
    const longitude = num(item.longitude)
    const x = num(item.x)
    const y = num(item.y)
    if (Number.isFinite(lat) && Number.isFinite(lon)) return { lat, lng: lon }
    if (Number.isFinite(lat) && Number.isFinite(lng)) return { lat, lng }
    if (Number.isFinite(latitude) && Number.isFinite(longitude)) return { lat: latitude, lng: longitude }
    if (Number.isFinite(x) && Number.isFinite(y)) return { lat: y, lng: x }
    if (item.location) {
        const locLat = num(item.location.lat)
        const locLon = num(item.location.lon)
        const locLng = num(item.location.lng)
        if (Number.isFinite(locLat) && Number.isFinite(locLon)) return { lat: locLat, lng: locLon }
        if (Number.isFinite(locLat) && Number.isFinite(locLng)) return { lat: locLat, lng: locLng }
    }
    if (Array.isArray(item) && item.length >= 2) {
        const a = Number(item[0])
        const b = Number(item[1])
        if (Number.isFinite(a) && Number.isFinite(b)) {
            return Math.abs(a) > 90 ? { lat: b, lng: a } : { lat: a, lng: b }
        }
    }
    return null
}
const fitMapToPoints = (points) => {
    if (!gmap || !points?.length) return
    const lats = points.map((p) => p.lat).filter((v) => typeof v === 'number')
    const lngs = points.map((p) => p.lng).filter((v) => typeof v === 'number')
    if (!lats.length || !lngs.length) return
    const minLat = Math.min(...lats)
    const maxLat = Math.max(...lats)
    const minLon = Math.min(...lngs)
    const maxLon = Math.max(...lngs)
    const center = { lat: (minLat + maxLat) / 2, lon: (minLon + maxLon) / 2 }
    gmap.location(center)

    if (typeof gmap.bound === 'function') {
        try {
            gmap.bound({ minLat, minLon, maxLat, maxLon })
            return
        } catch { }
    }

    const span = Math.max(Math.abs(maxLat - minLat), Math.abs(maxLon - minLon))
    let zoom = 12
    if (span > 20) zoom = 5
    else if (span > 10) zoom = 6
    else if (span > 5) zoom = 7
    else if (span > 2) zoom = 8
    else if (span > 1) zoom = 9
    else if (span > 0.5) zoom = 10
    else if (span > 0.2) zoom = 11
    gmap.zoom(zoom)
}
function initializeMap() {
    if (!mapEl.value || gmap) return
    if (!window.longdo) return
    gmap = new longdo.Map({ placeholder: mapEl.value })
    gmap.location({ lat: 13.7563, lon: 100.5018 })
    gmap.zoom(6)
    mapReady.value = true
}
async function drawRouteOnMap(data) {
    if (!data) return
    await waitMapReady()
    if (!gmap || !window.longdo) return

    clearMap()

    const points = []
    if (data.start?.lat != null && data.start?.lng != null) {
        startMarker = new longdo.Marker({ lon: data.start.lng, lat: data.start.lat }, { title: 'จุดเริ่มต้น' })
        addOverlay(startMarker)
        points.push({ lat: data.start.lat, lng: data.start.lng })
    }
    if (data.end?.lat != null && data.end?.lng != null) {
        endMarker = new longdo.Marker({ lon: data.end.lng, lat: data.end.lat }, { title: 'จุดปลายทาง' })
        addOverlay(endMarker)
        points.push({ lat: data.end.lat, lng: data.end.lng })
    }

    if (Array.isArray(data.stopsCoords) && data.stopsCoords.length) {
        stopMarkers = data.stopsCoords.map((s, i) => {
            const marker = new longdo.Marker(
                { lon: s.lng, lat: s.lat },
                { title: s.name || s.address || `จุดแวะ ${i + 1}` }
            )
            addOverlay(marker)
            points.push({ lat: s.lat, lng: s.lng })
            return marker
        })
    }

    let path = []
    if (Array.isArray(data.routePath) && data.routePath.length) {
        path = data.routePath.map(coerceLatLng).filter(Boolean)
    } else if (data.polyline) {
        path = decodePolyline(data.polyline)
    }

    if (path.length > 1) {
        const line = new longdo.Polyline(
            path.map((p) => ({ lon: p.lng, lat: p.lat })),
            { lineWidth: 5, lineColor: '#2563eb', lineOpacity: 0.9 }
        )
        activePolyline = line
        addOverlay(line)
        points.push(...path)
    }

    if (points.length) fitMapToPoints(points)
}
/* ----------------------------------------------------------------------- */

async function fetchRoute() {
    isLoading.value = true
    loadError.value = ''
    try {
        const id = route.params.id
        const apiBase = useRuntimeConfig().public.apiBase
        const token = useCookie('token')?.value || (process.client ? localStorage.getItem('token') : '')

        const res = await fetch(`${apiBase}/routes/admin/${id}`, {
            method: 'GET',
            headers: {
                Accept: 'application/json',
                ...(token ? { Authorization: `Bearer ${token}` } : {})
            },
            credentials: 'include'
        })

        let body
        try { body = await res.json() } catch {
            const txt = await res.text()
            const e = new Error(txt || 'Unexpected response from server'); e.status = res.status; throw e
        }
        if (!res.ok) {
            const e = new Error(body?.message || `Request failed with status ${res.status}`); e.status = res.status; e.payload = body; throw e
        }

        const r = body?.data
        if (!r) throw new Error('Invalid response: missing data')

        // map → โครงเดียวกับหน้า findTrip
        const { stops, stopsCoords } = buildStops(r.waypoints)

        const start = r.startLocation || {}
        const end = r.endLocation || {}

        const driverName = `${r.driver?.firstName || ''} ${r.driver?.lastName || ''}`.trim() || 'ไม่ระบุชื่อ'
        const driverImage = r.driver?.profilePicture
            || `https://ui-avatars.com/api/?name=${encodeURIComponent(r.driver?.firstName || 'U')}&background=random&size=64`

        routeData.value = {
            id: r.id,
            start,
            end,
            originName: start?.name || (start?.lat != null && start?.lng != null ? `(${start.lat.toFixed(2)}, ${start.lng.toFixed(2)})` : '-'),
            destinationName: end?.name || (end?.lat != null && end?.lng != null ? `(${end.lat.toFixed(2)}, ${end.lng.toFixed(2)})` : '-'),
            originAddress: start?.address ? cleanAddr(start.address) : null,
            destinationAddress: end?.address ? cleanAddr(end.address) : null,

            availableSeats: r.availableSeats,
            price: r.pricePerSeat,
            departureTime: dayjs(r.departureTime).format('HH:mm น.'),
            date: dayjs(r.departureTime).format('D MMMM BBBB'),

            durationText: formatDurationText(r.duration, r.durationSeconds),
            distanceText: formatDistance(r.distance, r.distanceMeters),

            polyline: r.routePolyline || r.landmarks?.overview_polyline || null,
            routePath: r.routePath || r.landmarks?.routePath || null,

            stops,
            stopsCoords,

            conditions: r.conditions,
            photos: r.vehicle?.photos || [],
            carDetails: r.vehicle
                ? [`${r.vehicle.vehicleModel} (${r.vehicle.vehicleType})`, ...(r.vehicle.amenities || [])]
                : ['ไม่มีข้อมูลรถ'],

            driver: {
                name: driverName,
                image: driverImage,
                isVerified: !!r.driver?.isVerified
            },

            createdAt: r.createdAt,
            updatedAt: r.updatedAt
        }

        // วาดแผนที่เมื่อมีข้อมูลและ Longdo Map พร้อม
        if (window.longdo) {
            drawRouteOnMap(routeData.value)
        }
    } catch (err) {
        console.error(err)
        loadError.value = err?.message || 'ไม่สามารถโหลดข้อมูลเส้นทางได้'
        routeData.value = null
    } finally {
        isLoading.value = false
    }
}


function defineGlobalScripts() {
    window.__adminResizeHandler__ = function () {
        const sidebar = document.getElementById('sidebar')
        const mainContent = document.getElementById('main-content')
        const overlay = document.getElementById('overlay')
        if (!sidebar || !mainContent || !overlay) return
        if (window.innerWidth >= 1024) {
            sidebar.classList.remove('mobile-open'); overlay.classList.add('hidden')
            mainContent.style.marginLeft = sidebar.classList.contains('collapsed') ? '80px' : '280px'
        } else { mainContent.style.marginLeft = '0' }

        // --- เพิ่ม: บังคับให้แผนที่ปรับขนาด + fitBounds ใหม่เมื่อเลย์เอาต์เปลี่ยน ---
        if (gmap && mapReady.value) {
            try { gmap.resize && gmap.resize() } catch { }
            if (routeData.value) drawRouteOnMap(routeData.value)
        }
    }
    window.addEventListener('resize', window.__adminResizeHandler__)
}
function cleanupGlobalScripts() {
    window.removeEventListener('resize', window.__adminResizeHandler__ || (() => { }))
    delete window.__adminResizeHandler__
}
function closeMobileSidebar() {
    const sidebar = document.getElementById('sidebar')
    const overlay = document.getElementById('overlay')
    if (!sidebar || !overlay) return
    sidebar.classList.remove('mobile-open'); overlay.classList.add('hidden')
}

function formatDistance(input, distanceMeters) {
    if (typeof input === 'string' && input.includes('+')) {
        // โครงเดียวกับหน้า findTrip: รวม segment แล้วแสดงแบบย่อ
        const parts = input.split('+')
        let meters = 0
        for (const seg of parts) {
            const n = parseFloat(seg.replace(/[^\d.]/g, ''))
            if (Number.isNaN(n)) continue
            if (/กม/.test(seg)) meters += n * 1000
            else if (/เมตร|ม\./.test(seg)) meters += n
            else meters += n
        }
        if (meters >= 1000) {
            const km = Math.round((meters / 1000) * 10) / 10
            return `${(km % 1 === 0 ? km.toFixed(0) : km)} กม.`
        }
        return `${Math.round(meters)} ม.`
    }
    // fallback จาก distanceMeters
    if (typeof distanceMeters === 'number') {
        if (distanceMeters >= 1000) {
            const km = Math.round((distanceMeters / 1000) * 10) / 10
            return `${(km % 1 === 0 ? km.toFixed(0) : km)} กม.`
        }
        return `${Math.round(distanceMeters)} ม.`
    }
    return input || '-'
}

function formatDurationText(input, seconds) {
    if (typeof input === 'string' && input.includes('+')) {
        // โครงเดียวกับหน้า findTrip
        const parts = input.split('+')
        let minutes = 0
        for (const seg of parts) {
            const n = parseFloat(seg.replace(/[^\d.]/g, ''))
            if (Number.isNaN(n)) continue
            if (/ชม/.test(seg)) minutes += n * 60
            else minutes += n
        }
        const h = Math.floor(minutes / 60)
        const m = Math.round(minutes % 60)
        return h ? (m ? `${h} ชม. ${m} นาที` : `${h} ชม.`) : `${m} นาที`
    }
    if (typeof seconds === 'number') {
        const minutes = Math.round(seconds / 60)
        const h = Math.floor(minutes / 60)
        const m = minutes % 60
        return h ? (m ? `${h} ชม. ${m} นาที` : `${h} ชม.`) : `${m} นาที`
    }
    return input || '-'
}

function buildStops(waypoints) {
    const wp = waypoints || {}
    const baseList = (Array.isArray(wp.used) && wp.used.length
        ? wp.used
        : Array.isArray(wp.requested) ? wp.requested : [])
    const orderedList = (Array.isArray(wp.optimizedOrder) && wp.optimizedOrder.length === baseList.length)
        ? wp.optimizedOrder.map(i => baseList[i])
        : baseList

    const stops = orderedList.map(p => {
        const name = p?.name || ''
        const address = cleanAddr(p?.address || '')
        const fallback = (p?.lat != null && p?.lng != null) ? `(${p.lat.toFixed(6)}, ${p.lng.toFixed(6)})` : ''
        const title = name || fallback
        return address ? `${title} — ${address}` : title
    }).filter(Boolean)

    const stopsCoords = orderedList
        .map(p => (p && typeof p.lat === 'number' && typeof p.lng === 'number')
            ? { lat: p.lat, lng: p.lng, name: p.name || '', address: p.address || '' }
            : null)
        .filter(Boolean)

    return { stops, stopsCoords }
}
watch(isLoading, async (loading) => {
    if (loading === false) {
        // รอ DOM ของส่วนแผนที่ถูกเรนเดอร์ (mapEl มีจริงและมีขนาดแล้ว)
        await nextTick()
        if (!gmap && window.longdo) {
            initializeMap()
        }
        if (routeData.value && window.longdo) {
            drawRouteOnMap(routeData.value)
        }
    }
})

onMounted(async () => {
    defineGlobalScripts()
    if (typeof window.__adminResizeHandler__ === 'function') window.__adminResizeHandler__()
    try {
        await loadLongdoMap()
    } catch (e) {
        console.error(e)
    }
    initializeMap()
    await fetchRoute()
    if (routeData.value) drawRouteOnMap(routeData.value)
})

onUnmounted(() => {
    cleanupGlobalScripts()
    clearMap()
})
</script>

<style>
.main-content {
    transition: margin-left 0.3s ease;
}
</style>
