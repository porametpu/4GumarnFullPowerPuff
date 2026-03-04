<template>
    <div>
        <div class="px-4 py-8 mx-auto max-w-7xl sm:px-6 lg:px-8">
            <div class="mb-8">
                <h2 class="text-2xl font-bold text-gray-900">การเดินทางของฉัน</h2>
                <p class="mt-2 text-gray-600">จัดการและติดตามการเดินทางทั้งหมดของคุณ</p>
            </div>

            <div class="p-6 mb-8 bg-white border border-gray-300 rounded-lg shadow-md">
                <div class="flex flex-wrap gap-2">
                    <button v-for="tab in tabs" :key="tab.status" @click="activeTab = tab.status"
                        :class="['tab-button px-4 py-2 rounded-md font-medium', { 'active': activeTab === tab.status }]">
                        {{ tab.label }} ({{ getTripCount(tab.status) }})
                    </button>
                </div>
            </div>

            <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
                <div class="lg:col-span-2">
                    <div class="bg-white border border-gray-300 rounded-lg shadow-md">
                        <div class="p-6 border-b border-gray-300">
                            <h3 class="text-lg font-semibold text-gray-900">รายการการเดินทาง</h3>
                        </div>

                        <div v-if="isLoading" class="p-12 text-center text-gray-500">
                            <p>กำลังโหลดข้อมูลการเดินทาง...</p>
                        </div>

                        <div v-else class="divide-y divide-gray-200">
                            <div v-if="filteredTrips.length === 0" class="p-12 text-center text-gray-500">
                                <p>ไม่พบรายการเดินทางในหมวดหมู่นี้</p>
                            </div>

                            <div v-for="trip in filteredTrips" :key="trip.id"
                                class="p-6 transition-colors duration-200 cursor-pointer trip-card hover:bg-gray-50"
                                @click="toggleTripDetails(trip.id)">
                                <div class="flex items-start justify-between mb-4">
                                    <div class="flex-1">
                                        <div class="flex items-center justify-between">
                                            <h4 class="text-lg font-semibold text-gray-900">
                                                {{ trip.origin }} → {{ trip.destination }}
                                            </h4>
                                            <span v-if="trip.status === 'pending'"
                                                class="status-badge status-pending">รอดำเนินการ</span>
                                            <span v-else-if="trip.status === 'confirmed'"
                                                class="status-badge status-confirmed">ยืนยันแล้ว</span>
                                            <span v-else-if="trip.status === 'rejected'"
                                                class="status-badge status-rejected">ปฏิเสธ</span>
                                            <span v-else-if="trip.status === 'cancelled'"
                                                class="status-badge status-cancelled">ยกเลิก</span>
                                        </div>
                                        <p class="mt-1 text-sm text-gray-600">จุดนัดพบ: {{ trip.pickupPoint }}</p>
                                        <p class="text-sm text-gray-600">
                                            วันที่: {{ trip.date }}
                                            <span class="mx-2 text-gray-300">|</span>
                                            เวลา: {{ trip.time }}
                                            <span class="mx-2 text-gray-300">|</span>
                                            ระยะเวลา: {{ trip.durationText }}
                                            <span class="mx-2 text-gray-300">|</span>
                                            ระยะทาง: {{ trip.distanceText }}
                                        </p>
                                    </div>
                                </div>

                                <div class="flex items-center mb-4 space-x-4">
                                    <img :src="trip.driver.image" :alt="trip.driver.name"
                                        class="object-cover w-12 h-12 rounded-full" />
                                    <div class="flex-1">
                                        <h5 class="font-medium text-gray-900">{{ trip.driver.name }}</h5>
                                        <div class="flex items-center">
                                            <div class="flex text-sm text-yellow-400">
                                                <span>
                                                    {{ '★'.repeat(Math.round(trip.driver.rating)) }}{{ '☆'.repeat(5 -
                                                        Math.round(trip.driver.rating)) }}
                                                </span>
                                            </div>
                                            <span class="ml-2 text-sm text-gray-600">{{ trip.driver.rating }} ({{
                                                trip.driver.reviews }} รีวิว)</span>
                                        </div>
                                    </div>
                                    <div class="text-right">
                                        <div class="text-lg font-bold text-blue-600">{{ trip.price }} บาท</div>
                                        <div class="text-sm text-gray-600">จำนวน {{ trip.seats }} ที่นั่ง</div>
                                    </div>
                                </div>

                                <div v-if="selectedTripId === trip.id"
                                    class="pt-4 mt-4 mb-5 duration-300 border-t border-gray-300 animate-in slide-in-from-top">
                                    <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                                        <div>
                                            <h5 class="mb-2 font-medium text-gray-900">รายละเอียดเส้นทาง</h5>
                                            <ul class="space-y-1 text-sm text-gray-600">
                                                <li>
                                                    • จุดเริ่มต้น:
                                                    <span class="font-medium text-gray-900">{{ trip.origin }}</span>
                                                    <span v-if="trip.originAddress"> — {{ trip.originAddress }}</span>
                                                </li>

                                                <template v-if="trip.stops && trip.stops.length">
                                                    <li class="mt-2 text-gray-700">• จุดแวะระหว่างทาง ({{
                                                        trip.stops.length }} จุด):</li>
                                                    <li v-for="(stop, idx) in trip.stops" :key="idx">  - จุดแวะ {{ idx +
                                                        1 }}: {{ stop }}</li>
                                                </template>

                                                <li class="mt-1">
                                                    • จุดปลายทาง:
                                                    <span class="font-medium text-gray-900">{{ trip.destination
                                                        }}</span>
                                                    <span v-if="trip.destinationAddress"> — {{ trip.destinationAddress
                                                        }}</span>
                                                </li>
                                            </ul>
                                        </div>
                                        <div>
                                            <h5 class="mb-2 font-medium text-gray-900">รายละเอียดรถ</h5>
                                            <ul class="space-y-1 text-sm text-gray-600">
                                                <li v-for="detail in trip.carDetails" :key="detail">• {{ detail }}</li>
                                            </ul>
                                        </div>

                                        <div>
                                            <div class="mt-4">
                                                <h5 class="mb-2 font-medium text-gray-900">ข้อมูลสัมภาระเพิ่มเติม</h5>
                                                <p v-if="trip.extraLuggageSelected"
                                                    class="p-3 text-sm text-gray-700 border border-gray-300 rounded-md bg-gray-50">
                                                    ประเภท: {{ luggageTypeLabel(trip.extraLuggageType) }}<br>
                                                    ค่าบริการเพิ่ม: {{ trip.extraLuggageFee }} บาท
                                                </p>
                                                <p v-else
                                                    class="p-3 text-sm text-gray-600 border border-gray-300 rounded-md bg-gray-50">
                                                    ไม่มีการขอสัมภาระเพิ่มเติม
                                                </p>
                                            </div>

                                        </div>

                                    </div>

                                    <div class="mt-4 space-y-4">
                                        <div v-if="trip.conditions">
                                            <h5 class="mb-2 font-medium text-gray-900">เงื่อนไขการเดินทาง</h5>
                                            <p
                                                class="p-3 text-sm text-gray-700 border border-gray-300 rounded-md bg-gray-50">
                                                {{ trip.conditions }}
                                            </p>
                                        </div>

                                        <div v-if="trip.photos && trip.photos.length > 0">
                                            <h5 class="mb-2 font-medium text-gray-900">รูปภาพรถยนต์</h5>
                                            <div class="grid grid-cols-3 gap-2 mt-2">
                                                <div v-for="(photo, index) in trip.photos.slice(0, 3)" :key="index">
                                                    <img :src="photo" alt="Vehicle photo"
                                                        class="object-cover w-full transition-opacity rounded-lg shadow-sm cursor-pointer aspect-video hover:opacity-90" />
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="flex justify-end space-x-3" :class="{ 'mt-4': selectedTripId !== trip.id }">
                                    <!-- PENDING: ยกเลิกได้ -->
                                    <button v-if="trip.status === 'pending'" @click.stop="openCancelModal(trip)"
                                        class="px-4 py-2 text-sm text-red-600 transition duration-200 border border-red-300 rounded-md hover:bg-red-50">
                                        ยกเลิกการจอง
                                    </button>

                                    <!-- CONFIRMED: เพิ่มปุ่มยกเลิก + คงปุ่มแชท -->
                                    <template v-else-if="trip.status === 'confirmed'">
                                        <button @click.stop="openCancelModal(trip)"
                                            class="px-4 py-2 text-sm text-red-600 transition duration-200 border border-red-300 rounded-md hover:bg-red-50">
                                            ยกเลิกการจอง
                                        </button>
                                        <button @click.stop="openChatPage(trip.id)"
                                            class="px-4 py-2 text-sm text-white transition duration-200 bg-blue-600 rounded-md hover:bg-blue-700">
                                            แชทกับผู้ขับ
                                        </button>
                                    </template>

                                    <!-- REJECTED / CANCELLED: ลบได้ -->
                                    <button v-else-if="['rejected', 'cancelled'].includes(trip.status)"
                                        @click.stop="openConfirmModal(trip, 'delete')"
                                        class="px-4 py-2 text-sm text-gray-600 transition duration-200 border border-gray-300 rounded-md hover:bg-gray-50">
                                        ลบรายการ
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="lg:col-span-1">
                    <div class="sticky overflow-hidden bg-white border border-gray-300 rounded-lg shadow-md top-8">
                        <div class="p-6 border-b border-gray-300">
                            <h3 class="text-lg font-semibold text-gray-900">แผนที่เส้นทาง</h3>
                        </div>
                        <div ref="mapContainer" id="map" class="h-96"></div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Modal: เลือกเหตุผลการยกเลิก -->
        <div v-if="isCancelModalVisible" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40"
            @click.self="closeCancelModal">
            <div class="w-full max-w-md p-6 bg-white rounded-lg shadow-xl">
                <h3 class="text-lg font-semibold text-gray-900">เลือกเหตุผลการยกเลิก</h3>
                <p class="mt-1 text-sm text-gray-600">โปรดเลือกเหตุผลตามตัวเลือกที่กำหนด</p>

                <div class="mt-4">
                    <label class="block mb-1 text-sm text-gray-700">เหตุผล</label>
                    <select v-model="selectedCancelReason" class="w-full px-3 py-2 border border-gray-300 rounded-md">
                        <option value="" disabled>-- เลือกเหตุผล --</option>
                        <option v-for="r in cancelReasonOptions" :key="r.value" :value="r.value">
                            {{ r.label }}
                        </option>
                    </select>
                    <p v-if="cancelReasonError" class="mt-2 text-sm text-red-600">
                        {{ cancelReasonError }}
                    </p>
                </div>

                <div class="flex justify-end gap-2 mt-6">
                    <button @click="closeCancelModal"
                        class="px-4 py-2 text-sm text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200">
                        ปิด
                    </button>
                    <button @click="submitCancel" :disabled="!selectedCancelReason || isSubmittingCancel"
                        class="px-4 py-2 text-sm text-white bg-red-600 rounded-md hover:bg-red-700 disabled:opacity-50">
                        {{ isSubmittingCancel ? 'กำลังส่ง...' : 'ยืนยันการยกเลิก' }}
                    </button>
                </div>
            </div>
        </div>

        <ConfirmModal :show="isModalVisible" :title="modalContent.title" :message="modalContent.message"
            :confirmText="modalContent.confirmText" :variant="modalContent.variant" @confirm="handleConfirmAction"
            @cancel="closeConfirmModal" />
    </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import dayjs from 'dayjs'
import 'dayjs/locale/th'
import buddhistEra from 'dayjs/plugin/buddhistEra'
import ConfirmModal from '~/components/ConfirmModal.vue'
import { useToast } from '~/composables/useToast'
import { useLongdoMap } from '~/composables/useLongdoMap'

// Setup dayjs for Thai locale
dayjs.locale('th')
dayjs.extend(buddhistEra)

const { $api } = useNuxtApp()
const { toast } = useToast()
const { loadLongdoMap } = useLongdoMap()

// --- State Management ---
const activeTab = ref('pending')
const selectedTripId = ref(null)
const isLoading = ref(false)
const mapContainer = ref(null)
const allTrips = ref([])

let gmap = null // Longdo Map instance
let activePolyline = null
let startMarker = null
let endMarker = null
const mapReady = ref(false)
let stopMarkers = []
let mapOverlays = []

const tabs = [
    { status: 'pending', label: 'รอดำเนินการ' },
    { status: 'confirmed', label: 'ยืนยันแล้ว' },
    { status: 'rejected', label: 'ปฏิเสธ' },
    { status: 'cancelled', label: 'ยกเลิก' },
    { status: 'all', label: 'ทั้งหมด' }
]

definePageMeta({ middleware: 'auth' })

const cancelReasonOptions = [
    { value: 'CHANGE_OF_PLAN', label: 'เปลี่ยนแผน/มีธุระกะทันหัน' },
    { value: 'FOUND_ALTERNATIVE', label: 'พบวิธีเดินทางอื่นแล้ว' },
    { value: 'DRIVER_DELAY', label: 'คนขับล่าช้าหรือเลื่อนเวลา' },
    { value: 'PRICE_ISSUE', label: 'ราคาหรือค่าใช้จ่ายไม่เหมาะสม' },
    { value: 'WRONG_LOCATION', label: 'เลือกจุดรับ–ส่งผิด' },
    { value: 'DUPLICATE_OR_WRONG_DATE', label: 'จองซ้ำหรือจองผิดวัน' },
    { value: 'SAFETY_CONCERN', label: 'กังวลด้านความปลอดภัย' },
    { value: 'WEATHER_OR_FORCE_MAJEURE', label: 'สภาพอากาศ/เหตุสุดวิสัย' },
    { value: 'COMMUNICATION_ISSUE', label: 'สื่อสารไม่สะดวก/ติดต่อไม่ได้' }
]

const isCancelModalVisible = ref(false)
const isSubmittingCancel = ref(false)
const selectedCancelReason = ref('')
const cancelReasonError = ref('')
const tripToCancel = ref(null)

// --- Computed Properties ---
const filteredTrips = computed(() => {
    if (activeTab.value === 'all') return allTrips.value
    return allTrips.value.filter((trip) => trip.status === activeTab.value)
})

const selectedTrip = computed(() => {
    return allTrips.value.find((trip) => trip.id === selectedTripId.value) || null
})

function cleanAddr(a) {
    return (a || '')
        .replace(/,?\s*(Thailand|ไทย|ประเทศ)\s*$/i, '')
        .replace(/\s{2,}/g, ' ')
        .trim()
}

function luggageTypeLabel(type) {
    const map = {
        MEDIUM: 'ขนาดกลาง ( <= 24 นิ้ว)',
        LARGE: 'ขนาดใหญ่ ( <= 28 นิ้ว)',
        EXTRA_LARGE: 'ขนาดใหญ่พิเศษ (> 28 นิ้ว)'
    }
    return map[type] || type || '-'

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

// --- Methods ---
async function fetchMyTrips() {
    isLoading.value = true
    try {
        const bookings = await $api('/bookings/me')

        // map ข้อมูลพื้นฐานก่อน (ตั้งชื่อชั่วคราวเป็นพิกัด แล้วไป reverse geocode ภายหลัง)
        const formatted = bookings.map((b) => {
            const driverData = {
                name: `${b.route.driver.firstName} ${b.route.driver.lastName}`.trim(),
                image:
                    b.route.driver.profilePicture ||
                    `https://ui-avatars.com/api/?name=${encodeURIComponent(b.route.driver.firstName || 'U')}&background=random&size=64`,
                rating: 4.5,
                reviews: Math.floor(Math.random() * 50) + 5
            }

            const carDetails = []
            if (b.route.vehicle) {
                carDetails.push(`${b.route.vehicle.vehicleModel} (${b.route.vehicle.vehicleType})`)
                if (Array.isArray(b.route.vehicle.amenities) && b.route.vehicle.amenities.length) {
                    carDetails.push(...b.route.vehicle.amenities)
                }
            } else {
                carDetails.push('ไม่มีข้อมูลรถ')
            }

            const start = b.route.startLocation
            const end = b.route.endLocation

            const wp = b.route.waypoints || {}
            const baseList =
                (Array.isArray(wp.used) && wp.used.length ? wp.used : Array.isArray(wp.requested) ? wp.requested : []) || []
            const orderedList =
                Array.isArray(wp.optimizedOrder) && wp.optimizedOrder.length === baseList.length
                    ? wp.optimizedOrder.map((i) => baseList[i])
                    : baseList

            const stops = orderedList
                .map((p) => {
                    const name = p?.name || ''
                    const address = cleanAddr(p?.address || '')
                    const fallback =
                        p?.lat != null && p?.lng != null ? `(${Number(p.lat).toFixed(6)}, ${Number(p.lng).toFixed(6)})` : ''
                    const title = name || fallback
                    return address ? `${title} — ${address}` : title
                })
                .filter(Boolean)

            const stopsCoords = orderedList
                .map((p) =>
                    p && typeof p.lat === 'number' && typeof p.lng === 'number'
                        ? { lat: Number(p.lat), lng: Number(p.lng), name: p.name || '', address: p.address || '' }
                        : null
                )
                .filter(Boolean)

            return {
                id: b.id,
                status: String(b.status || '').toLowerCase(),
                origin: start?.name || `(${Number(start.lat).toFixed(2)}, ${Number(start.lng).toFixed(2)})`,
                destination: end?.name || `(${Number(end.lat).toFixed(2)}, ${Number(end.lng).toFixed(2)})`,
                originAddress: start?.address ? cleanAddr(start.address) : null,
                destinationAddress: end?.address ? cleanAddr(end.address) : null,
                originHasName: !!start?.name,
                destinationHasName: !!end?.name,
                pickupPoint: b.pickupLocation?.name || '-',
                date: dayjs(b.route.departureTime).format('D MMMM BBBB'),
                time: dayjs(b.route.departureTime).format('HH:mm น.'),
                price: (b.route.pricePerSeat || 0) * (b.numberOfSeats || 1) + Number(b.extraLuggageFee || 0),
                seats: b.numberOfSeats || 1,
                extraLuggageSelected: !!b.extraLuggageSelected,
                extraLuggageType: b.extraLuggageType || null,
                extraLuggageFee: Number(b.extraLuggageFee || 0),
                driver: driverData,
                coords: [
                    [start.lat, start.lng],
                    [end.lat, end.lng]
                ],
                polyline: b.route.routePolyline || null, // ใช้เมื่อมี
                routePath: b.route.landmarks?.routePath || b.route.routePath || null,
                stops,
                stopsCoords,
                carDetails,
                conditions: b.route.conditions,
                photos: b.route.vehicle?.photos || [],
                durationText:
                    (typeof b.route.duration === 'string' ? formatDuration(b.route.duration) : b.route.duration) ||
                    (typeof b.route.durationSeconds === 'number' ? `${Math.round(b.route.durationSeconds / 60)} นาที` : '-'),
                distanceText:
                    (typeof b.route.distance === 'string' ? formatDistance(b.route.distance) : b.route.distance) ||
                    (typeof b.route.distanceMeters === 'number' ? `${(b.route.distanceMeters / 1000).toFixed(1)} กม.` : '-')
            }
        })

        allTrips.value = formatted

        // รอให้แผนที่พร้อมก่อน แล้วค่อย reverse geocode เพื่อได้ "ชื่อสถานที่" สวยๆ
        await waitMapReady()

        const jobs = allTrips.value.map(async (t, idx) => {
            const [o, d] = await Promise.all([reverseGeocode(t.coords[0][0], t.coords[0][1]), reverseGeocode(t.coords[1][0], t.coords[1][1])])
            if (!allTrips.value[idx].originHasName && o?.name) {
                allTrips.value[idx].origin = o.name
            }
            if (!allTrips.value[idx].destinationHasName && d?.name) {
                allTrips.value[idx].destination = d.name
            }
            if (!allTrips.value[idx].originAddress && o?.address) {
                allTrips.value[idx].originAddress = cleanAddr(o.address)
            }
            if (!allTrips.value[idx].destinationAddress && d?.address) {
                allTrips.value[idx].destinationAddress = cleanAddr(d.address)
            }
        })

        await Promise.allSettled(jobs)
    } catch (error) {
        console.error('Failed to fetch my trips:', error)
        allTrips.value = []
    } finally {
        isLoading.value = false
    }
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

const formatReverseAddress = (data) => {
    if (!data) return null
    if (typeof data === 'string') return data
    if (data.address) return data.address
    if (data.display_name) return data.display_name
    const parts = [data.road, data.subdistrict, data.district, data.province, data.postcode].filter(Boolean)
    return parts.length ? parts.join(' ') : null
}

const reverseGeocode = async (lat, lng) => {
    try {
        const res = await $api('/maps/reverse-geocode', { query: { lat, lng } })
        const addr = formatReverseAddress(res?.data ?? res)
        return addr ? { name: addr, address: addr } : null
    } catch (e) {
        console.error('Reverse geocode failed:', e)
        return null
    }
}

const getTripCount = (status) => {
    if (status === 'all') return allTrips.value.length
    return allTrips.value.filter((trip) => trip.status === status).length
}

const toggleTripDetails = (tripId) => {
    const tripForMap = allTrips.value.find((trip) => trip.id === tripId)
    if (tripForMap) {
        updateMap(tripForMap)
    }

    if (selectedTripId.value === tripId) {
        selectedTripId.value = null
    } else {
        selectedTripId.value = tripId
    }
}

const addOverlay = (overlay) => {
    if (!gmap || !overlay) return
    gmap.Overlays.add(overlay)
    mapOverlays.push(overlay)
}

const clearMapDrawing = () => {
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

async function updateMap(trip) {
    if (!trip) return
    await waitMapReady()
    if (!gmap || !window.longdo) return

    clearMapDrawing()

    const points = []
    const start = { lat: Number(trip.coords[0][0]), lng: Number(trip.coords[0][1]) }
    const end = { lat: Number(trip.coords[1][0]), lng: Number(trip.coords[1][1]) }

    startMarker = new longdo.Marker({ lon: start.lng, lat: start.lat }, { title: 'จุดเริ่มต้น' })
    endMarker = new longdo.Marker({ lon: end.lng, lat: end.lat }, { title: 'จุดปลายทาง' })
    addOverlay(startMarker)
    addOverlay(endMarker)
    points.push(start, end)

    if (Array.isArray(trip.stopsCoords) && trip.stopsCoords.length) {
        stopMarkers = trip.stopsCoords.map((s, idx) => {
            const marker = new longdo.Marker(
                { lon: s.lng, lat: s.lat },
                { title: s.name || s.address || `จุดแวะ ${idx + 1}` }
            )
            addOverlay(marker)
            points.push({ lat: s.lat, lng: s.lng })
            return marker
        })
    }

    let path = []
    if (Array.isArray(trip.routePath) && trip.routePath.length) {
        path = trip.routePath.map(coerceLatLng).filter(Boolean)
    } else if (trip.polyline) {
        path = decodePolyline(trip.polyline)
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

    fitMapToPoints(points)
}

// --- Chat Widget Navigation ---
import { useChatWidget } from '~/composables/useChatWidget'
const { openChat } = useChatWidget()

const openChatPage = (bookingId) => {
    openChat(bookingId)
}

// --- Modal Logic ---
const isModalVisible = ref(false)
const tripToAction = ref(null)
const modalContent = ref({
    title: '',
    message: '',
    confirmText: '',
    action: null,
    variant: 'danger'
})

const openConfirmModal = (trip, action) => {
    tripToAction.value = trip
    if (action === 'cancel') {
        // ตอนนี้ไม่ใช้ทางยืนยันตรง ๆ แล้ว แต่คงโครงไว้เผื่ออนาคต
        modalContent.value = {
            title: 'ยืนยันการยกเลิกการจอง',
            message: `คุณต้องการยกเลิกการเดินทางไปที่ "${trip.destination}" ใช่หรือไม่?`,
            confirmText: 'ใช่, ยกเลิกการจอง',
            action: 'cancel',
            variant: 'danger'
        }
    } else if (action === 'delete') {
        modalContent.value = {
            title: 'ยืนยันการลบรายการ',
            message: `คุณต้องการลบรายการเดินทางไปที่ "${trip.destination}" ออกจากประวัติใช่หรือไม่?`,
            confirmText: 'ใช่, ลบรายการ',
            action: 'delete',
            variant: 'danger'
        }
    }
    isModalVisible.value = true
}

const closeConfirmModal = () => {
    isModalVisible.value = false
    tripToAction.value = null
}

const handleConfirmAction = async () => {
    if (!tripToAction.value) return
    const action = modalContent.value.action
    const tripId = tripToAction.value.id
    try {
        if (action === 'cancel') {
            // ไม่ยิง PATCH ตรง ๆ — ต้องให้ผู้ใช้เลือกเหตุผลก่อน
            openCancelModal(tripToAction.value)
            closeConfirmModal()
            return
        } else if (action === 'delete') {
            await $api(`/bookings/${tripId}`, { method: 'DELETE' })
            toast.success('ลบรายการสำเร็จ', 'รายการได้ถูกลบออกจากประวัติแล้ว')
        }
        closeConfirmModal()
        await fetchMyTrips()
    } catch (error) {
        console.error(`Failed to ${action} booking:`, error)
        toast.error('เกิดข้อผิดพลาด', error.data?.message || 'ไม่สามารถดำเนินการได้')
        closeConfirmModal()
    }
}

function openCancelModal(trip) {
    tripToCancel.value = trip
    selectedCancelReason.value = ''
    cancelReasonError.value = ''
    isCancelModalVisible.value = true
}

function closeCancelModal() {
    isCancelModalVisible.value = false
    tripToCancel.value = null
}

async function submitCancel() {
    if (!selectedCancelReason.value) {
        cancelReasonError.value = 'กรุณาเลือกเหตุผล'
        return
    }
    if (!tripToCancel.value) return

    isSubmittingCancel.value = true
    try {
        await $api(`/bookings/${tripToCancel.value.id}/cancel`, {
            method: 'PATCH',
            body: { reason: selectedCancelReason.value } // ✅ ตรงกับ schema ฝั่ง backend
        })
        toast.success('ยกเลิกการจองสำเร็จ', 'ระบบบันทึกเหตุผลแล้ว')
        closeCancelModal()
        await fetchMyTrips()
    } catch (err) {
        console.error('Cancel booking failed:', err)
        toast.error('เกิดข้อผิดพลาด', err?.data?.message || 'ไม่สามารถยกเลิกได้')
    } finally {
        isSubmittingCancel.value = false
    }
}

function formatDistance(input) {
    if (typeof input !== 'string') return input
    const parts = input.split('+')
    if (parts.length <= 1) return input

    let meters = 0
    for (const seg of parts) {
        const n = parseFloat(seg.replace(/[^\d.]/g, ''))
        if (Number.isNaN(n)) continue
        if (/กม/.test(seg)) meters += n * 1000
        else if (/เมตร|ม\./.test(seg)) meters += n
        else meters += n // สมมติเป็นเมตรถ้าไม่พบหน่วย
    }

    if (meters >= 1000) {
        const km = Math.round((meters / 1000) * 10) / 10 // ปัดทศนิยม 1 ตำแหน่ง
        return `${(km % 1 === 0 ? km.toFixed(0) : km)} กม.`
    }
    return `${Math.round(meters)} ม.`
}

function formatDuration(input) {
    if (typeof input !== 'string') return input
    const parts = input.split('+')
    if (parts.length <= 1) return input

    let minutes = 0
    for (const seg of parts) {
        const n = parseFloat(seg.replace(/[^\d.]/g, ''))
        if (Number.isNaN(n)) continue
        if (/ชม/.test(seg)) minutes += n * 60
        else minutes += n // นาที
    }

    const h = Math.floor(minutes / 60)
    const m = Math.round(minutes % 60)
    return h ? (m ? `${h} ชม. ${m} นาที` : `${h} ชม.`) : `${m} นาที`
}

// --- Lifecycle and Watchers ---
useHead({
    title: 'การเดินทางของฉัน - ไปนำแหน่',
    link: [{ rel: 'stylesheet', href: 'https://fonts.googleapis.com/css2?family=Kanit:wght@300;400;500;600;700&display=swap' }]
})

onMounted(async () => {
    try {
        await loadLongdoMap()
    } catch (e) {
        console.error(e)
        toast.error('ไม่สามารถโหลดแผนที่ได้', 'กรุณาตรวจสอบคีย์ Longdo Map')
        return
    }

    initializeMap()
    fetchMyTrips().then(() => {
        if (filteredTrips.value.length) updateMap(filteredTrips.value[0])
    })
})

function initializeMap() {
    if (!mapContainer.value || gmap) return
    if (!window.longdo) return
    gmap = new longdo.Map({ placeholder: mapContainer.value })
    gmap.location({ lon: 100.5018, lat: 13.7563 })
    gmap.zoom(6)
    mapReady.value = true
}
</script>

<style scoped>
.trip-card {
    transition: all 0.3s ease;
    cursor: pointer;
}

.trip-card:hover {
    /* transform: translateY(-2px); */
    box-shadow: 0 10px 25px rgba(59, 130, 246, 0.1);
}

.tab-button {
    transition: all 0.3s ease;
}

.tab-button.active {
    background-color: #3b82f6;
    color: white;
    box-shadow: 0 4px 14px rgba(59, 130, 246, 0.3);
}

.tab-button:not(.active) {
    background-color: white;
    color: #6b7280;
    border: 1px solid #d1d5db;
}

.tab-button:not(.active):hover {
    background-color: #f9fafb;
    color: #374151;
}

#map {
    height: 100%;
    min-height: 600px;
    border-radius: 0 0 0.5rem 0.5rem;
}

.status-badge {
    display: inline-flex;
    align-items: center;
    padding: 0.25rem 0.75rem;
    border-radius: 9999px;
    font-size: 0.875rem;
    font-weight: 500;
}

.status-pending {
    background-color: #fef3c7;
    color: #d97706;
}

.status-confirmed {
    background-color: #d1fae5;
    color: #065f46;
}

.status-rejected {
    background-color: #fee2e2;
    color: #dc2626;
}

.status-cancelled {
    background-color: #f3f4f6;
    color: #6b7280;
}

@keyframes slide-in-from-top {
    from {
        opacity: 0;
        transform: translateY(-10px);
    }

    to {
        opacity: 1;
        transform: translateY(0);
    }
}

.animate-in {
    animation-fill-mode: both;
}

.slide-in-from-top {
    animation-name: slide-in-from-top;
}

.duration-300 {
    animation-duration: 300ms;
}
</style>
