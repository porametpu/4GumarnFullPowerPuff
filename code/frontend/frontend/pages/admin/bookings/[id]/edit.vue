<template>
    <div>
        <AdminHeader />
        <AdminSidebar />

        <main id="main-content" class="main-content mt-16 ml-0 lg:ml-[280px] p-6 min-h-screen">
            <div class="mx-auto max-w-7xl">
                <!-- Back -->
                <div class="mb-8">
                    <NuxtLink to="/admin/bookings"
                        class="inline-flex items-center gap-2 px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50">
                        <i class="fa-solid fa-arrow-left"></i>
                        <span>ย้อนกลับ</span>
                    </NuxtLink>
                </div>

                <!-- Title -->
                <div class="flex flex-col gap-3 mb-6 sm:flex-row sm:items-center sm:justify-between">
                    <div class="flex items-center gap-3">
                        <h1 class="text-2xl font-semibold text-gray-800">แก้ไขการจอง (แอดมิน)</h1>
                        <span class="text-sm text-gray-500">ปรับเส้นทาง ผู้โดยสาร จำนวนที่นั่ง และจุดรับ-ส่ง</span>
                    </div>
                </div>

                <!-- Card -->
                <div class="flex w-full overflow-hidden bg-white border border-gray-300 rounded-lg shadow-lg">
                    <main class="flex-1 p-8 space-y-8">
                        <!-- SECTION: เส้นทาง + ผู้โดยสาร -->
                        <section>
                            <h3 class="mb-3 text-sm font-semibold text-gray-700">เส้นทางและผู้โดยสาร</h3>
                            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                                <!-- Route search -->
                                <div class="relative">
                                    <label class="block mb-2 text-sm font-medium text-gray-700">
                                        เลือกเส้นทาง (ค้นหา: ต้นทาง/ปลายทาง/ผู้ขับ/เวลา) <span
                                            class="text-red-500">*</span>
                                    </label>
                                    <input v-model.trim="routeQuery" @input="onSearchRoutes" type="text"
                                        placeholder="เช่น มข. → เซ็นทรัล / ชื่อคนขับ / เวลา"
                                        class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                    <div v-if="showRouteList"
                                        class="absolute z-20 w-full mt-1 overflow-auto bg-white border rounded-md shadow max-h-60">
                                        <button v-for="r in routeResults" :key="r.id" type="button"
                                            @click="selectRoute(r)" class="w-full px-3 py-2 text-left hover:bg-blue-50">
                                            <div class="text-sm font-medium text-gray-800">
                                                {{ summarizeRoute(r) }}
                                            </div>
                                            <div class="text-xs text-gray-500">
                                                {{ formatDateTime(r.departureTime) }} • ที่นั่งคงเหลือ {{
                                                r.availableSeats }} • ฿{{ r.pricePerSeat }}/ที่นั่ง
                                            </div>
                                        </button>
                                        <div v-if="!isSearchingRoutes && routeResults.length === 0"
                                            class="px-3 py-2 text-sm text-gray-500">
                                            ไม่พบเส้นทางที่ตรงกับคำค้น
                                        </div>
                                    </div>
                                    <p v-if="!selectedRouteId" class="mt-2 text-xs text-amber-600">*
                                        ต้องเลือกเส้นทางจากรายการ</p>
                                    <p v-else class="mt-2 text-xs text-gray-600 truncate">เลือกแล้ว: {{
                                        selectedRouteLabel }}</p>
                                </div>

                                <!-- Passenger search -->
                                <div class="relative">
                                    <label class="block mb-2 text-sm font-medium text-gray-700">
                                        เลือกผู้โดยสาร (ค้นหา: อีเมล / ชื่อ / Username) <span
                                            class="text-red-500">*</span>
                                    </label>
                                    <input v-model.trim="userQuery" @input="onSearchUsers" type="text"
                                        placeholder="เช่น user1@gmail.com / User1"
                                        class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                    <div v-if="showUserList"
                                        class="absolute z-20 w-full mt-1 overflow-auto bg-white border rounded-md shadow max-h-60">
                                        <button v-for="u in userResults" :key="u.id" type="button"
                                            @click="selectUser(u)" class="w-full px-3 py-2 text-left hover:bg-blue-50">
                                            <div class="text-sm font-medium text-gray-800">
                                                {{ u.firstName }} {{ u.lastName }}
                                                <span v-if="u.username" class="text-xs text-gray-500">(@{{ u.username
                                                    }})</span>
                                            </div>
                                            <div class="text-xs text-gray-500">{{ u.email }}</div>
                                        </button>
                                        <div v-if="!isSearchingUsers && userResults.length === 0"
                                            class="px-3 py-2 text-sm text-gray-500">
                                            ไม่พบผู้ใช้ที่ตรงกับคำค้น
                                        </div>
                                    </div>
                                    <p v-if="!selectedPassengerId" class="mt-2 text-xs text-amber-600">*
                                        ต้องเลือกผู้โดยสารจากรายการ</p>
                                    <p v-else class="mt-2 text-xs text-gray-600 truncate">เลือกแล้ว: {{
                                        selectedPassengerLabel }}</p>
                                </div>
                            </div>
                        </section>

                        <!-- SECTION: รายละเอียดการจอง -->
                        <section>
                            <h3 class="mb-3 text-sm font-semibold text-gray-700">รายละเอียดการจอง</h3>
                            <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
                                <div>
                                    <label class="block mb-1 text-xs font-medium text-gray-600">
                                        จำนวนที่นั่ง <span class="text-red-500">*</span>
                                    </label>
                                    <input v-model.number="form.numberOfSeats" type="number" min="1"
                                        :max="maxSeats || undefined"
                                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                    <p class="mt-1 text-xs text-gray-500">
                                        {{
                                            selectedRoute?.availableSeats != null
                                                ? `เลือกได้สูงสุด ${selectedRoute.availableSeats} ที่นั่ง`
                                                : 'กรุณาเลือกเส้นทางก่อน'
                                        }}
                                    </p>
                                </div>
                                <div>
                                    <label class="block mb-1 text-xs font-medium text-gray-600">ราคาต่อที่นั่ง
                                        (อ้างอิงจากเส้นทาง)</label>
                                    <input :value="selectedRoute ? selectedRoute.pricePerSeat : ''" disabled
                                        class="w-full px-3 py-2 border border-gray-300 rounded-md disabled:bg-gray-100" />
                                </div>
                                <div>
                                    <label class="block mb-1 text-xs font-medium text-gray-600">เวลาออกเดินทาง</label>
                                    <input :value="selectedRoute ? formatDateTime(selectedRoute.departureTime) : ''"
                                        disabled
                                        class="w-full px-3 py-2 border border-gray-300 rounded-md disabled:bg-gray-100" />
                                </div>
                            </div>

                            <!-- จุดขึ้น/ลง -->
                            <div class="grid grid-cols-1 gap-4 mt-4 sm:grid-cols-2">
                                <div>
                                    <label class="block mb-2 text-sm font-medium text-gray-700">เลือกจุดขึ้นรถ</label>
                                    <div class="relative">
                                        <input ref="pickupInputEl" v-model="pickupPoint" type="text"
                                            placeholder="พิมพ์ชื่อสถานที่..." @input="onPickupInput"
                                            @focus="onPickupFocus" @blur="onPickupBlur"
                                            @change="onPickupManual"
                                            class="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                        <button type="button" @click="startBookingPicker('pickup')"
                                            class="absolute inset-y-0 my-auto text-gray-500 right-2 hover:text-blue-600"
                                            title="เลือกจากแผนที่">
                                            <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                                                <path
                                                    d="M12 2a7 7 0 00-7 7c0 5.25 7 13 7 13s7-7.75 7-13a7 7 0 00-7-7zm0 9.5a2.5 2.5 0 110-5 2.5 2.5 0 010 5z" />
                                            </svg>
                                        </button>
                                        <ul v-if="pickupFocused && pickupSuggestions.length" class="suggest-list">
                                            <li v-for="(s, i) in pickupSuggestions" :key="i" class="suggest-item"
                                                @mousedown.prevent="applyPickupSuggestion(s)">
                                                {{ s.label }}
                                            </li>
                                        </ul>
                                    </div>
                                </div>
                                <div>
                                    <label class="block mb-2 text-sm font-medium text-gray-700">เลือกจุดลงรถ</label>
                                    <div class="relative">
                                        <input ref="dropoffInputEl" v-model="dropoffPoint" type="text"
                                            placeholder="พิมพ์ชื่อสถานที่..." @input="onDropoffInput"
                                            @focus="onDropoffFocus" @blur="onDropoffBlur"
                                            @change="onDropoffManual"
                                            class="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                        <button type="button" @click="startBookingPicker('dropoff')"
                                            class="absolute inset-y-0 my-auto text-gray-500 right-2 hover:text-blue-600"
                                            title="เลือกจากแผนที่">
                                            <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                                                <path
                                                    d="M12 2a7 7 0 00-7 7c0 5.25 7 13 7 13s7-7.75 7-13a7 7 0 00-7-7zm0 9.5a2.5 2.5 0 110-5 2.5 2.5 0 010 5z" />
                                            </svg>
                                        </button>
                                        <ul v-if="dropoffFocused && dropoffSuggestions.length" class="suggest-list">
                                            <li v-for="(s, i) in dropoffSuggestions" :key="i" class="suggest-item"
                                                @mousedown.prevent="applyDropoffSuggestion(s)">
                                                {{ s.label }}
                                            </li>
                                        </ul>
                                    </div>
                                </div>
                            </div>
                        </section>

                        <!-- Actions -->
                        <div class="flex justify-end gap-4 pt-2">
                            <button type="button" @click="handleCancel" :disabled="isSubmitting"
                                class="px-6 py-3 text-gray-700 border border-gray-300 rounded-md hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-400 disabled:opacity-50">
                                ยกเลิก
                            </button>
                            <button type="button" @click="handleUpdate" :disabled="!canSubmit || isSubmitting"
                                class="flex items-center px-6 py-3 font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-blue-400 disabled:cursor-not-allowed">
                                <svg v-if="isSubmitting" class="w-5 h-5 mr-3 -ml-1 text-white animate-spin"
                                    xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor"
                                        stroke-width="4" />
                                    <path class="opacity-75" fill="currentColor"
                                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                                </svg>
                                {{ isSubmitting ? 'กำลังบันทึก...' : 'บันทึกการเปลี่ยนแปลง' }}
                            </button>
                        </div>
                    </main>
                </div>
            </div>
        </main>

        <!-- Overlay (มือถือ) -->
        <div id="overlay" class="fixed inset-0 z-40 hidden bg-black bg-opacity-50 lg:hidden"
            @click="closeMobileSidebar"></div>

        <!-- Modal: Map Picker -->
        <transition name="modal-fade">
            <div v-if="bookingPickingTarget" class="fixed inset-0 z-50 flex items-center justify-center bg-black/60"
                @click.self="stopBookingPicker">
                <div class="bg-white rounded-lg w-[95%] max-w-3xl overflow-hidden">
                    <div class="flex items-center justify-between p-4 border-b border-gray-300">
                        <h3 class="text-lg font-semibold text-gray-900">เลือก{{ bookingPickingTarget === 'pickup' ?
                            'จุดขึ้นรถ' : 'จุดลงรถ' }}</h3>
                        <button @click="stopBookingPicker" class="text-gray-400 hover:text-gray-600"><i
                                class="fa-solid fa-xmark"></i></button>
                    </div>
                    <div class="p-0">
                        <div ref="bookingPickerMapEl" class="w-full" style="height: 65vh;"></div>
                        <div class="flex items-center justify-between p-4 border-t border-gray-200">
                            <div class="text-sm text-gray-700 truncate">
                                <span class="font-medium">ตำแหน่ง:</span>
                                <span class="truncate">{{ bookingPicked.name || '— ยังไม่เลือก —' }}</span>
                            </div>
                            <button
                                class="px-4 py-2 text-white bg-blue-600 rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
                                :disabled="!bookingPicked.name" @click="applyBookingPicked">
                                ใช้ตำแหน่งนี้
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </transition>
    </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute, useRuntimeConfig, useCookie } from '#app'
import AdminHeader from '~/components/admin/AdminHeader.vue'
import AdminSidebar from '~/components/admin/AdminSidebar.vue'
import { useToast } from '~/composables/useToast'
import { useLongdoMap } from '~/composables/useLongdoMap'
import dayjs from 'dayjs'
import 'dayjs/locale/th'
dayjs.locale('th')

definePageMeta({ middleware: ['admin-auth'] })
useHead({
    title: 'Edit Booking • Admin',
    link: [{ rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }]
})

const route = useRoute()
const bookingId = route.params.id
const { toast } = useToast()
const config = useRuntimeConfig()
const token = useCookie('token')?.value || (process.client ? localStorage.getItem('token') : '')
const { loadLongdoMap } = useLongdoMap()

const isSubmitting = ref(false)

/* ===== form ===== */
const form = reactive({
    numberOfSeats: 1,
    status: '' // เก็บไว้ส่งกลับ (ไม่มี input UI ตาม create)
})

/* ===== points ===== */
const pickupPoint = ref('')
const dropoffPoint = ref('')
const pickupData = ref({ lat: null, lng: null, placeId: null, address: null, name: null })
const dropoffData = ref({ lat: null, lng: null, placeId: null, address: null, name: null })

/* ===== route & passenger search (เหมือนหน้า create) ===== */
const routeQuery = ref('')
const selectedRouteId = ref('')
const selectedRoute = ref(null)
const selectedRouteLabel = ref('')
const routeResults = ref([])
const isSearchingRoutes = ref(false)
const lastRouteLabel = ref('')

const userQuery = ref('')
const selectedPassengerId = ref('')
const selectedPassengerLabel = ref('')
const userResults = ref([])
const isSearchingUsers = ref(false)
const lastUserLabel = ref('')

const showRouteList = computed(() => routeQuery.value && (isSearchingRoutes.value || routeResults.value.length > 0))
const showUserList = computed(() => userQuery.value && (isSearchingUsers.value || userResults.value.length > 0))

function summarizeRoute(r) {
    const s = r.startLocation?.name || 'ต้นทาง'
    const e = r.endLocation?.name || 'ปลายทาง'
    const driver = r.driver ? `${r.driver.firstName || ''} ${r.driver.lastName || ''}`.trim() : ''
    return `${s} → ${e}${driver ? ' • ' + driver : ''}`
}
function formatDateTime(iso) { return iso ? dayjs(iso).format('D MMM YYYY HH:mm') : '-' }

/* --- search funcs (เหมือน create) --- */
let routeTimer = null
async function onSearchRoutes() {
    if (routeQuery.value !== lastRouteLabel.value) {
        selectedRouteId.value = ''
        selectedRoute.value = null
        selectedRouteLabel.value = ''
    }
    clearTimeout(routeTimer)
    const q = routeQuery.value.trim()
    if (!q) { routeResults.value = []; return }
    routeTimer = setTimeout(async () => {
        try {
            isSearchingRoutes.value = true
            const res = await $fetch('/routes/admin', {
                baseURL: config.public.apiBase,
                headers: { Accept: 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
                query: { q, page: 1, limit: 10 }
            })
            routeResults.value = res?.data || []
        } catch { routeResults.value = [] }
        finally { isSearchingRoutes.value = false }
    }, 300)
}
function selectRoute(r) {
    selectedRouteId.value = r.id
    selectedRoute.value = r
    const label = `${summarizeRoute(r)} • ${formatDateTime(r.departureTime)}`
    routeQuery.value = label; lastRouteLabel.value = label; selectedRouteLabel.value = label
    routeResults.value = []
}

let userTimer = null
async function onSearchUsers() {
    if (userQuery.value !== lastUserLabel.value) selectedPassengerId.value = ''
    clearTimeout(userTimer)
    const q = userQuery.value.trim()
    if (!q) { userResults.value = []; return }
    userTimer = setTimeout(async () => {
        try {
            isSearchingUsers.value = true
            const res = await $fetch('/users/admin', {
                baseURL: config.public.apiBase,
                headers: { Accept: 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
                query: { q, page: 1, limit: 10 }
            })
            userResults.value = res?.data || []
        } catch { userResults.value = [] }
        finally { isSearchingUsers.value = false }
    }, 300)
}
function selectUser(u) {
    selectedPassengerId.value = u.id
    const label = `${u.firstName || ''} ${u.lastName || ''} (${u.username ? '@' + u.username : u.email})`
    userQuery.value = label; lastUserLabel.value = label; selectedPassengerLabel.value = label
    userResults.value = []
}

/* ====================== Pickup/Dropoff: Suggest + Picker (Longdo) ====================== */
const pickupInputEl = ref(null)
const dropoffInputEl = ref(null)
const bookingPickingTarget = ref(/** @type {'pickup'|'dropoff'|null} */(null))
const bookingPickerMapEl = ref(null)
let bookingPickerMap = null
let bookingPickerMarker = null
const bookingPicked = ref({ name: '', lat: null, lng: null, address: null })

const pickupSuggestions = ref([])
const dropoffSuggestions = ref([])
const pickupFocused = ref(false)
const dropoffFocused = ref(false)
let pickupBlurTimer = null
let dropoffBlurTimer = null
let pickupInputTimer = null
let dropoffInputTimer = null

const stripHtml = (html) => {
    if (!html) return null
    return String(html).replace(/<[^>]+>/g, '')
}
const toSuggestLabel = (item) => {
    if (!item) return null
    if (typeof item === 'string') return item
    return (
        item.w ||
        stripHtml(item.d) ||
        item.name ||
        item.title ||
        item.display_name ||
        item.address ||
        item.addr ||
        item.text ||
        null
    )
}
const normalizeResultList = (data) => {
    if (!data) return []
    if (Array.isArray(data)) return data
    if (Array.isArray(data.suggest)) return data.suggest
    if (Array.isArray(data.suggestions)) return data.suggestions
    if (Array.isArray(data.data)) return data.data
    if (Array.isArray(data.results)) return data.results
    if (Array.isArray(data.result)) return data.result
    if (Array.isArray(data.geocode)) return data.geocode
    if (Array.isArray(data.items)) return data.items
    if (Array.isArray(data.data?.suggest)) return data.data.suggest
    if (Array.isArray(data.data?.suggestions)) return data.data.suggestions
    if (Array.isArray(data.data?.results)) return data.data.results
    if (Array.isArray(data.data?.result)) return data.data.result
    if (data.data && Array.isArray(data.data.data)) return data.data.data
    return []
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
const pickFirstLocation = (data) => {
    const list = normalizeResultList(data)
    const item = list[0]
    if (!item) return null
    const ll = coerceLatLng(item)
    if (!ll) return null
    const name = item.name || item.title || item.display_name || item.address || item.addr || null
    const address = item.address || item.addr || item.display_name || name || null
    return { ...ll, name, address }
}
const formatReverseAddress = (data) => {
    if (!data) return null
    if (typeof data === 'string') return data
    if (data.address) return data.address
    if (data.display_name) return data.display_name
    const parts = [data.road, data.subdistrict, data.district, data.province, data.postcode].filter(Boolean)
    return parts.length ? parts.join(' ') : null
}
const geocodeAddress = async (text) => {
    if (!text) return null
    try {
        const res = await $fetch('/maps/geocode', {
            baseURL: config.public.apiBase,
            headers: { Accept: 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
            query: { address: text }
        })
        return pickFirstLocation(res?.data ?? res)
    } catch (e) {
        console.error('Geocode failed:', e)
        return null
    }
}
const searchKeyword = async (text) => {
    if (!text) return null
    try {
        const res = await $fetch('/maps/search', {
            baseURL: config.public.apiBase,
            headers: { Accept: 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
            query: { keyword: text }
        })
        return pickFirstLocation(res?.data ?? res)
    } catch (e) {
        console.error('Search failed:', e)
        return null
    }
}
const reverseGeocode = async (lat, lng) => {
    try {
        const res = await $fetch('/maps/reverse-geocode', {
            baseURL: config.public.apiBase,
            headers: { Accept: 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
            query: { lat, lng }
        })
        const addr = formatReverseAddress(res?.data ?? res)
        return addr ? { name: addr, address: addr } : null
    } catch (e) {
        console.error('Reverse geocode failed:', e)
        return null
    }
}
const fetchSuggestions = async (text) => {
    const q = (text || '').trim()
    if (q.length < 2) return []
    try {
        const res = await $fetch('/maps/suggest', {
            baseURL: config.public.apiBase,
            headers: { Accept: 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
            query: { keyword: q }
        })
        const list = normalizeResultList(res?.data ?? res)
        return list
            .map((it) => {
                const label = toSuggestLabel(it)
                return label ? { label, raw: it } : null
            })
            .filter(Boolean)
            .slice(0, 8)
    } catch (e) {
        console.error('Suggest failed:', e)
        return []
    }
}
const setMetaFromSuggestion = async (label, raw) => {
    let ll = coerceLatLng(raw)
    let name = toSuggestLabel(raw) || label
    let address = raw?.address || raw?.addr || raw?.display_name || name || label
    if (!ll) {
        const s = await searchKeyword(label)
        if (s && s.lat != null && s.lng != null) {
            ll = { lat: s.lat, lng: s.lng }
            name = s.name || label
            address = s.address || label
        } else {
            const g = await geocodeAddress(label)
            if (g && g.lat != null && g.lng != null) {
                ll = { lat: g.lat, lng: g.lng }
                name = g.name || label
                address = g.address || label
            }
        }
    }
    if (!ll) return null
    return { lat: ll.lat, lng: ll.lng, name, address }
}
const resolveTextToLocation = async (text) => {
    const s = await searchKeyword(text)
    if (s && s.lat != null && s.lng != null) return s
    const g = await geocodeAddress(text)
    if (g && g.lat != null && g.lng != null) return g
    return null
}

const onPickupInput = () => {
    pickupFocused.value = true
    if (pickupBlurTimer) clearTimeout(pickupBlurTimer)
    if (pickupInputTimer) clearTimeout(pickupInputTimer)
    if (pickupData.value.lat != null || pickupData.value.lng != null) {
        pickupData.value = { ...pickupData.value, lat: null, lng: null }
    }
    const text = pickupPoint.value || ''
    pickupInputTimer = setTimeout(async () => {
        const list = await fetchSuggestions(text)
        if ((pickupPoint.value || '') === text) pickupSuggestions.value = list
    }, 250)
}
const onDropoffInput = () => {
    dropoffFocused.value = true
    if (dropoffBlurTimer) clearTimeout(dropoffBlurTimer)
    if (dropoffInputTimer) clearTimeout(dropoffInputTimer)
    if (dropoffData.value.lat != null || dropoffData.value.lng != null) {
        dropoffData.value = { ...dropoffData.value, lat: null, lng: null }
    }
    const text = dropoffPoint.value || ''
    dropoffInputTimer = setTimeout(async () => {
        const list = await fetchSuggestions(text)
        if ((dropoffPoint.value || '') === text) dropoffSuggestions.value = list
    }, 250)
}
const onPickupFocus = () => { pickupFocused.value = true }
const onDropoffFocus = () => { dropoffFocused.value = true }
const onPickupBlur = () => {
    pickupBlurTimer = setTimeout(() => {
        pickupFocused.value = false
        pickupSuggestions.value = []
    }, 150)
}
const onDropoffBlur = () => {
    dropoffBlurTimer = setTimeout(() => {
        dropoffFocused.value = false
        dropoffSuggestions.value = []
    }, 150)
}
const applyPickupSuggestion = async (s) => {
    pickupPoint.value = s.label
    pickupSuggestions.value = []
    const meta = await setMetaFromSuggestion(s.label, s.raw)
    if (meta) {
        pickupData.value = { lat: meta.lat, lng: meta.lng, name: meta.name, address: meta.address, placeId: null }
    }
}
const applyDropoffSuggestion = async (s) => {
    dropoffPoint.value = s.label
    dropoffSuggestions.value = []
    const meta = await setMetaFromSuggestion(s.label, s.raw)
    if (meta) {
        dropoffData.value = { lat: meta.lat, lng: meta.lng, name: meta.name, address: meta.address, placeId: null }
    }
}
const onPickupManual = async () => {
    const text = pickupPoint.value
    if (!text) return
    const r = await resolveTextToLocation(text)
    if (!r) return
    pickupData.value = { lat: r.lat, lng: r.lng, name: r.name || text, address: r.address || text, placeId: null }
}
const onDropoffManual = async () => {
    const text = dropoffPoint.value
    if (!text) return
    const r = await resolveTextToLocation(text)
    if (!r) return
    dropoffData.value = { lat: r.lat, lng: r.lng, name: r.name || text, address: r.address || text, placeId: null }
}

async function startBookingPicker(target) {
    bookingPickingTarget.value = target
    bookingPicked.value = { name: '', lat: null, lng: null, address: null }
    try {
        await loadLongdoMap()
    } catch (e) {
        console.error(e)
        toast.error('ไม่สามารถโหลดแผนที่ได้', 'กรุณาตรวจสอบคีย์ Longdo Map')
        bookingPickingTarget.value = null
        return
    }
    nextTick(() => {
        const fallbackCenter = { lat: 13.7563, lng: 100.5018 }
        const base = target === 'pickup' ? pickupData.value : dropoffData.value
        const center = (base.lat && base.lng) ? { lat: base.lat, lng: base.lng } : fallbackCenter
        bookingPickerMap = new longdo.Map({ placeholder: bookingPickerMapEl.value })
        bookingPickerMap.location({ lon: center.lng, lat: center.lat })
        bookingPickerMap.zoom(base.lat ? 14 : 6)
        if (base.lat && base.lng) {
            setBookingPickerMarker(base.lat, base.lng)
            bookingPicked.value = { name: base.name || '', lat: base.lat, lng: base.lng, address: base.address || '' }
        }
        bookingPickerMap.Event.bind('click', () => {
            const loc = bookingPickerMap.location(longdo.LocationMode.Pointer)
            if (!loc || loc.lat == null || loc.lon == null) return
            setBookingPickerMarker(loc.lat, loc.lon)
            resolveBookingPicked(loc.lat, loc.lon)
        })
    })
}
function stopBookingPicker() {
    bookingPickingTarget.value = null
    if (bookingPickerMap && bookingPickerMarker) {
        bookingPickerMap.Overlays.remove(bookingPickerMarker)
    }
    bookingPickerMap = null
    bookingPickerMarker = null
}
function setBookingPickerMarker(lat, lng) {
    if (!bookingPickerMap || !window.longdo) return
    if (bookingPickerMarker) {
        bookingPickerMap.Overlays.remove(bookingPickerMarker)
        bookingPickerMarker = null
    }
    bookingPickerMarker = new longdo.Marker({ lon: lng, lat }, { title: 'ตำแหน่งที่เลือก' })
    bookingPickerMap.Overlays.add(bookingPickerMarker)
}
async function resolveBookingPicked(lat, lng) {
    const info = await reverseGeocode(lat, lng)
    const name = cleanAddr(info?.name || `${lat.toFixed(5)}, ${lng.toFixed(5)}`)
    const address = cleanAddr(info?.address || name)
    bookingPicked.value = { name, lat, lng, address }
}
function applyBookingPicked() {
    if (!bookingPickingTarget.value || !bookingPicked.value.name) return
    const data = { lat: bookingPicked.value.lat, lng: bookingPicked.value.lng, placeId: null, address: bookingPicked.value.address, name: bookingPicked.value.name }
    if (bookingPickingTarget.value === 'pickup') { pickupPoint.value = data.name || data.address || ''; pickupData.value = data }
    else { dropoffPoint.value = data.name || data.address || ''; dropoffData.value = data }
    stopBookingPicker()
}

/* ===== Submit (PUT) ===== */
const maxSeats = computed(() => selectedRoute.value?.availableSeats ?? null)
const canSubmit = computed(() =>
    !!selectedRouteId.value &&
    !!selectedPassengerId.value &&
    form.numberOfSeats >= 1 &&
    (!maxSeats.value || form.numberOfSeats <= maxSeats.value) &&
    (!!pickupData.value.lat || !!pickupPoint.value) &&
    (!!dropoffData.value.lat || !!dropoffPoint.value)
)

async function geocodeText(text) {
    if (!text) return null
    const r = await resolveTextToLocation(text)
    if (!r) return null
    return {
        lat: r.lat,
        lng: r.lng,
        placeId: null,
        address: r.address || null,
        name: r.name || null
    }
}

function normalizeBookingError(err) {
    const status = err?.statusCode || err?.status || err?.response?.status || err?.data?.statusCode
    const rawMsg = err?.data?.message || err?.message || ''
    const msg = String(rawMsg || '').trim()
    const lower = msg.toLowerCase()
    let title = 'เกิดข้อผิดพลาด', body = msg || 'ไม่สามารถบันทึกการจองได้'
    if (/driver cannot book their own route/i.test(msg)) { title = 'ไม่สามารถดำเนินการ'; body = 'ผู้ขับไม่สามารถจองเส้นทางของตนเองได้ (Driver cannot book their own route.)' }
    else if (/booking already exists|duplicate booking/i.test(lower) || status === 409) { title = 'ข้อมูลซ้ำ'; body = msg || 'มีคำขอจองนี้อยู่ในระบบแล้ว' }
    else if (/no available seats|route .* full|insufficient seats|exceeds available seats/i.test(lower)) { title = 'ที่นั่งไม่เพียงพอ'; body = 'จำนวนที่นั่งไม่พอหรือเส้นทางเต็มแล้ว' }
    else if (/route not found/i.test(lower)) { title = 'ไม่พบเส้นทาง'; body = 'กรุณาเลือกเส้นทางใหม่อีกครั้ง' }
    else if (/passenger not found|user not found/i.test(lower)) { title = 'ไม่พบผู้โดยสาร'; body = 'ตรวจสอบผู้โดยสารที่เลือกอีกครั้ง' }
    else if (status === 400) { title = 'ข้อมูลไม่ถูกต้อง'; body = msg || 'รูปแบบข้อมูลไม่ถูกต้อง' }
    else if (status === 401 || status === 403) { title = 'ไม่ได้รับอนุญาต'; body = 'สิทธิ์ไม่เพียงพอสำหรับการกระทำนี้' }
    return { title, body, status, raw: msg }
}

function cleanAddr(a) {
    return (a || '').replace(/,?\s*(Thailand|ไทย|ประเทศ)\s*$/i, '').replace(/\s{2,}/g, ' ').trim()
}

async function handleUpdate() {
    if (!canSubmit.value) {
        toast.warning('ข้อมูลไม่ครบถ้วน', 'กรุณาเลือกเส้นทาง/ผู้โดยสาร ระบุจำนวนที่นั่ง และกำหนดจุดรับ-ส่งให้ถูกต้อง')
        return
    }
    // geocode ถ้าผู้ใช้พิมพ์เอง
    if (pickupPoint.value && !pickupData.value.lat) {
        const g1 = await geocodeText(pickupPoint.value); if (g1) pickupData.value = g1
    }
    if (dropoffPoint.value && !dropoffData.value.lat) {
        const g2 = await geocodeText(dropoffPoint.value); if (g2) dropoffData.value = g2
    }
    if (!pickupData.value.lat || !dropoffData.value.lat) {
        toast.warning('ข้อมูลไม่ครบถ้วน', 'กรุณาเลือกจุดขึ้นรถและจุดลงรถจากรายการหรือปักหมุดบนแผนที่')
        return
    }

    isSubmitting.value = true
    try {
        const payload = {
            routeId: selectedRouteId.value,
            passengerId: selectedPassengerId.value,
            numberOfSeats: Number(form.numberOfSeats),
            pickupLocation: pickupData.value,
            dropoffLocation: dropoffData.value,
            ...(form.status ? { status: form.status } : {})
        }
        await $fetch(`/bookings/admin/${bookingId}`, {
            baseURL: config.public.apiBase,
            method: 'PUT',
            headers: {
                Accept: 'application/json',
                'Content-Type': 'application/json',
                ...(token ? { Authorization: `Bearer ${token}` } : {})
            },
            body: payload
        })
        toast.success('บันทึกสำเร็จ', 'อัปเดตการจองเรียบร้อย')
        navigateTo(`/admin/bookings/${bookingId}`).catch(() => { })
    } catch (error) {
        const mapped = normalizeBookingError(error)
        console.error('Update booking error:', { status: mapped.status, message: mapped.raw })
        toast.error(mapped.title, mapped.body)
    } finally {
        isSubmitting.value = false
    }
}
function handleCancel() { navigateTo('/admin/bookings') }

/* ===== Prefill: โหลดข้อมูลการจองเดิม ===== */
async function preloadBooking() {
    try {
        const res = await $fetch(`/bookings/admin/${bookingId}`, {
            baseURL: config.public.apiBase,
            headers: { Accept: 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }
        })
        const b = res?.data || res
        // จำนวนที่นั่ง + สถานะ
        form.numberOfSeats = Number(b?.numberOfSeats || 1)
        form.status = b?.status || ''

        // ผู้โดยสาร
        const p = b?.passenger || b?.user
        if (p?.id) {
            selectedPassengerId.value = p.id
            const label = `${p.firstName || ''} ${p.lastName || ''} (${p.username ? '@' + p.username : p.email || ''})`.trim()
            userQuery.value = label; lastUserLabel.value = label; selectedPassengerLabel.value = label
        } else if (b?.passengerId) {
            selectedPassengerId.value = b.passengerId
            userQuery.value = `ผู้โดยสาร: ${b.passengerId}`; lastUserLabel.value = userQuery.value; selectedPassengerLabel.value = userQuery.value
        }

        // เส้นทาง
        const r = b?.route
        if (r?.id) {
            selectRoute(r) // จะตั้ง selectedRouteId + labels ให้ครบ
        } else if (b?.routeId) {
            selectedRouteId.value = b.routeId
            routeQuery.value = `เส้นทาง: ${b.routeId}`; lastRouteLabel.value = routeQuery.value; selectedRouteLabel.value = routeQuery.value
        }

        // จุดรับ/ส่ง
        const pick = b?.pickupLocation || {}
        const drop = b?.dropoffLocation || {}
        pickupData.value = { lat: pick.lat ?? null, lng: pick.lng ?? null, placeId: pick.placeId ?? null, address: pick.address ?? null, name: pick.name ?? null }
        dropoffData.value = { lat: drop.lat ?? null, lng: drop.lng ?? null, placeId: drop.placeId ?? null, address: drop.address ?? null, name: drop.name ?? null }
        pickupPoint.value = pick.name || pick.address || ''
        dropoffPoint.value = drop.name || drop.address || ''
    } catch (e) {
        console.error('Load booking failed', e)
        toast.error('ไม่สามารถโหลดข้อมูล', 'ไม่พบข้อมูลการจองหรือคุณไม่มีสิทธิ์เข้าถึง')
    }
}

/* ===== Layout helper (เหมือน create) ===== */
function closeMobileSidebar() {
    const sidebar = document.getElementById('sidebar')
    const overlay = document.getElementById('overlay')
    if (!sidebar || !overlay) return
    sidebar.classList.remove('mobile-open'); overlay.classList.add('hidden')
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
    }
    window.addEventListener('resize', window.__adminResizeHandler__)
}
function cleanupGlobalScripts() {
    window.removeEventListener('resize', window.__adminResizeHandler__ || (() => { }))
    delete window.__adminResizeHandler__
}

onMounted(async () => {
    defineGlobalScripts()
    if (typeof window.__adminResizeHandler__ === 'function') window.__adminResizeHandler__()
    try {
        await loadLongdoMap()
    } catch (e) {
        console.error(e)
    }
    preloadBooking()
})
onUnmounted(() => { cleanupGlobalScripts() })
</script>

<style scoped>
.main-content {
    transition: margin-left 0.3s ease;
}

.modal-fade-enter-active,
.modal-fade-leave-active {
    transition: opacity .2s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
    opacity: 0;
}

.suggest-list {
    position: absolute;
    z-index: 30;
    width: 100%;
    margin-top: 0.25rem;
    background: #fff;
    border: 1px solid #e5e7eb;
    border-radius: 0.5rem;
    max-height: 220px;
    overflow: auto;
    box-shadow: 0 10px 20px rgba(0, 0, 0, 0.08);
}

.suggest-item {
    padding: 0.5rem 0.75rem;
    cursor: pointer;
    font-size: 0.875rem;
}

.suggest-item:hover {
    background: #eff6ff;
}

</style>
