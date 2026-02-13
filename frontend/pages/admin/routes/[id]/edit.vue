<template>
    <div>
        <AdminHeader />
        <AdminSidebar />

        <main id="main-content" class="main-content mt-16 ml-0 lg:ml-[280px] p-6 min-h-screen">
            <div class="mx-auto max-w-7xl">
                <!-- Back -->
                <div class="mb-8">
                    <NuxtLink :to="`/admin/routes/${route.params.id}`"
                        class="inline-flex items-center gap-2 px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50">
                        <i class="fa-solid fa-arrow-left"></i>
                        <span>ย้อนกลับ</span>
                    </NuxtLink>
                </div>

                <!-- Title -->
                <div class="flex flex-col gap-3 mb-6 sm:flex-row sm:items-center sm:justify-between">
                    <div class="flex items-center gap-3">
                        <h1 class="text-2xl font-semibold text-gray-800">แก้ไขเส้นทาง (แอดมิน)</h1>
                        <span class="text-sm text-gray-500">อัปเดตข้อมูลเส้นทางสำหรับผู้ขับและรถที่เลือก</span>
                    </div>
                </div>

                <!-- Card -->
                <div class="flex w-full overflow-hidden bg-white border border-gray-300 rounded-lg shadow-lg">
                    <main class="flex-1 p-6 sm:p-8">
                        <form @submit.prevent="handleSubmit" class="space-y-10">
                            <!-- ผู้ขับ/รถ -->
                            <section class="space-y-4">
                                <h2 class="text-lg font-semibold text-gray-800">ผู้ขับขี่และรถยนต์</h2>

                                <!-- ผู้ขับ (ล็อกแก้ไข) -->
                                <div class="relative">
                                    <label class="block mb-2 text-sm font-medium text-gray-700">ค้นหาผู้ขับ (อีเมล /
                                        ชื่อ / Username)</label>
                                    <input v-model.trim="driverQuery" @input="onSearchDrivers" type="text"
                                        placeholder="เลือกจากรายการ" :disabled="lockDriver" :readonly="lockDriver"
                                        class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100" />
                                    <div v-if="!lockDriver && showDriverList"
                                        class="absolute z-20 w-full mt-1 overflow-auto bg-white border rounded-md shadow max-h-60">
                                        <button v-for="u in driverResults" :key="u.id" type="button"
                                            @click="selectDriver(u)"
                                            class="w-full px-3 py-2 text-left hover:bg-blue-50">
                                            <div class="text-sm font-medium text-gray-800">
                                                {{ u.firstName }} {{ u.lastName }}
                                                <span v-if="u.username" class="text-xs text-gray-500">(@{{ u.username
                                                    }})</span>
                                            </div>
                                            <div class="text-xs text-gray-500">{{ u.email }}</div>
                                        </button>
                                        <div v-if="!isSearchingDrivers && driverResults.length === 0"
                                            class="px-3 py-2 text-sm text-gray-500">
                                            ไม่พบผู้ใช้ที่ตรงกับคำค้น
                                        </div>
                                    </div>
                                    <p class="mt-2 text-sm text-amber-600">* โหมดแก้ไข: ไม่สามารถเปลี่ยนผู้ขับได้</p>
                                </div>

                                <!-- รถ -->
                                <div>
                                    <label class="block mb-2 text-sm font-medium text-gray-700">เลือกรถของผู้ขับ</label>
                                    <select v-model="form.vehicleId"
                                        :disabled="!form.driverId || vehicleOptions.length === 0"
                                        class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100">
                                        <option disabled value="">— กรุณาเลือก —</option>
                                        <option v-for="v in vehicleOptions" :key="v.id" :value="v.id">
                                            {{ v.vehicleModel }} ({{ v.vehicleType }}) • {{ v.licensePlate || '—' }}
                                        </option>
                                    </select>
                                    <p v-if="form.driverId && vehicleOptions.length === 0"
                                        class="mt-2 text-sm text-gray-500">
                                        * ผู้ขับรายนี้ยังไม่มีรถในระบบ
                                    </p>
                                </div>
                            </section>

                            <!-- ข้อมูลเส้นทาง -->
                            <section class="space-y-6">
                                <h2 class="text-lg font-semibold text-gray-800">ข้อมูลเส้นทาง</h2>

                                <!-- แผนที่พรีวิว -->
                                <div>
                                    <h3 class="mb-2 text-sm font-semibold text-gray-700">แผนที่เส้นทาง</h3>
                                    <div class="overflow-hidden border border-gray-300 rounded-lg">
                                        <div ref="mapEl" class="w-full" style="height: 360px;"></div>
                                    </div>
                                </div>

                                <!-- Start / End -->
                                <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                                    <!-- Start -->
                                    <div>
                                        <label class="block mb-1 text-xs font-medium text-gray-600">จุดเริ่มต้น</label>
                                        <div class="space-y-2">
                                            <div class="relative">
                                                <input ref="startNameRef" v-model="startName"
                                                    @input="onStartInput" @focus="onStartFocus" @blur="onStartBlur"
                                                    @change="onNameManual('start')" type="text"
                                                    placeholder="ชื่อสถานที่"
                                                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                                <ul v-if="startFocused && startSuggestions.length" class="suggest-list">
                                                    <li v-for="(s, i) in startSuggestions" :key="i"
                                                        class="suggest-item"
                                                        @mousedown.prevent="applyStartSuggestion(s)">
                                                        {{ s.label }}
                                                    </li>
                                                </ul>
                                            </div>
                                            <input v-model="form.startLocation.address"
                                                @change="onAddressManual('start')" type="text" placeholder="ที่อยู่"
                                                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                            <div class="grid grid-cols-2 gap-2">
                                                <input v-model.number="form.startLocation.lat" type="number" step="any"
                                                    placeholder="lat"
                                                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                                <input v-model.number="form.startLocation.lng" type="number" step="any"
                                                    placeholder="lng"
                                                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                            </div>
                                            <button type="button" @click="openPicker('start')"
                                                class="px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50">
                                                เลือกจากแผนที่
                                            </button>
                                        </div>
                                    </div>

                                    <!-- End -->
                                    <div>
                                        <label class="block mb-1 text-xs font-medium text-gray-600">จุดปลายทาง</label>
                                        <div class="space-y-2">
                                            <div class="relative">
                                                <input ref="endNameRef" v-model="endName"
                                                    @input="onEndInput" @focus="onEndFocus" @blur="onEndBlur"
                                                    @change="onNameManual('end')" type="text"
                                                    placeholder="ชื่อสถานที่"
                                                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                                <ul v-if="endFocused && endSuggestions.length" class="suggest-list">
                                                    <li v-for="(s, i) in endSuggestions" :key="i" class="suggest-item"
                                                        @mousedown.prevent="applyEndSuggestion(s)">
                                                        {{ s.label }}
                                                    </li>
                                                </ul>
                                            </div>
                                            <input v-model="form.endLocation.address" @change="onAddressManual('end')"
                                                type="text" placeholder="ที่อยู่"
                                                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                            <div class="grid grid-cols-2 gap-2">
                                                <input v-model.number="form.endLocation.lat" type="number" step="any"
                                                    placeholder="lat"
                                                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                                <input v-model.number="form.endLocation.lng" type="number" step="any"
                                                    placeholder="lng"
                                                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                            </div>
                                            <button type="button" @click="openPicker('end')"
                                                class="px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50">
                                                เลือกจากแผนที่
                                            </button>
                                        </div>
                                    </div>
                                </div>

                                <!-- Waypoints -->
                                <div>
                                    <h3 class="mb-2 text-sm font-semibold text-gray-700">จุดแวะระหว่างทาง</h3>
                                    <div class="space-y-4">
                                        <div v-for="(w, idx) in form.waypoints" :key="idx"
                                            class="p-3 border border-gray-300 rounded-md">
                                            <div class="grid grid-cols-1 gap-2 sm:grid-cols-2">
                                                <div class="relative">
                                                    <input v-model="waypointNames[idx]" type="text"
                                                        placeholder="ชื่อจุดแวะ" @input="onWaypointInput(idx)"
                                                        @focus="onWaypointFocus(idx)" @blur="onWaypointBlur(idx)"
                                                        @change="onWaypointManual(idx)"
                                                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                                    <ul v-if="waypointFocused[idx] && (waypointSuggestions[idx] || []).length"
                                                        class="suggest-list">
                                                        <li v-for="(s, i) in (waypointSuggestions[idx] || [])" :key="i"
                                                            class="suggest-item"
                                                            @mousedown.prevent="applyWaypointSuggestion(idx, s)">
                                                            {{ s.label }}
                                                        </li>
                                                    </ul>
                                                </div>
                                                <input v-model="w.address" type="text" placeholder="ที่อยู่"
                                                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                                <input v-model.number="w.lat" type="number" step="any" placeholder="lat"
                                                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                                <input v-model.number="w.lng" type="number" step="any" placeholder="lng"
                                                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                            </div>
                                            <div class="flex gap-2 mt-2">
                                                <button type="button" @click="openPicker('waypoint', idx)"
                                                    class="px-3 py-1.5 text-sm border border-gray-300 rounded-md hover:bg-gray-50">
                                                    เลือกจากแผนที่
                                                </button>
                                                <button type="button" @click="removeWaypoint(idx)"
                                                    class="px-3 py-1.5 text-sm border border-red-300 text-red-700 rounded-md hover:bg-red-50">
                                                    ลบจุดแวะ
                                                </button>
                                            </div>
                                        </div>
                                        <button type="button" @click="addWaypoint"
                                            class="px-4 py-2 text-sm bg-gray-100 border rounded-md hover:bg-gray-200">
                                            + เพิ่มจุดแวะ
                                        </button>
                                    </div>
                                </div>

                                <!-- เวลา/ราคา/ที่นั่ง/เงื่อนไข -->
                                <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
                                    <div class="sm:col-span-1">
                                        <label
                                            class="block mb-1 text-xs font-medium text-gray-600">วัน-เวลาออกเดินทาง</label>
                                        <input v-model="departureLocal" type="datetime-local"
                                            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                    </div>
                                    <div>
                                        <label class="block mb-1 text-xs font-medium text-gray-600">ราคา/ที่นั่ง
                                            (บาท)</label>
                                        <input v-model.number="form.pricePerSeat" type="number" min="0"
                                            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                    </div>
                                    <div>
                                        <label
                                            class="block mb-1 text-xs font-medium text-gray-600">ที่นั่งคงเหลือ</label>
                                        <input v-model.number="form.availableSeats" type="number" min="0"
                                            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                    </div>
                                </div>

                                <div>
                                    <label
                                        class="block mb-1 text-xs font-medium text-gray-600">เงื่อนไขการเดินทาง</label>
                                    <textarea v-model="form.conditions" rows="4"
                                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                        placeholder="ระบุเงื่อนไขเพิ่มเติม เช่น ไม่เปิดเพลงเสียงดัง ฯลฯ"></textarea>
                                </div>
                            </section>

                            <!-- ปุ่ม -->
                            <div class="flex justify-end gap-4 pt-4">
                                <button type="button" :disabled="isSubmitting" @click="goBack"
                                    class="px-6 py-3 text-gray-700 border border-gray-300 rounded-md hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-400 disabled:opacity-50">
                                    ยกเลิก
                                </button>
                                <button type="submit" :disabled="!canSubmit || isSubmitting"
                                    class="flex items-center px-6 py-3 font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-blue-400 disabled:cursor-not-allowed">
                                    <svg v-if="isSubmitting" class="w-5 h-5 mr-3 -ml-1 text-white animate-spin"
                                        xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor"
                                            stroke-width="4"></circle>
                                        <path class="opacity-75" fill="currentColor"
                                            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
                                        </path>
                                    </svg>
                                    {{ isSubmitting ? 'กำลังบันทึก...' : 'บันทึกการแก้ไข' }}
                                </button>
                            </div>
                        </form>
                    </main>
                </div>
            </div>
        </main>

        <!-- overlay -->
        <div id="overlay" class="fixed inset-0 z-40 hidden bg-black bg-opacity-50 lg:hidden"
            @click="closeMobileSidebar"></div>

        <!-- Map picker -->
        <transition name="modal-fade">
            <div v-if="picker.show" class="fixed inset-0 z-[1000] bg-black/60 flex items-center justify-center"
                @click.self="closePicker">
                <div class="bg-white rounded-xl w-[95%] max-w-3xl overflow-hidden shadow-xl">
                    <div class="p-4 border-b">
                        <div class="font-semibold text-gray-800">
                            เลือกตำแหน่ง{{ picker.mode === 'start' ? 'จุดเริ่มต้น' : picker.mode === 'end' ?
                            'จุดปลายทาง' : 'จุดแวะ' }}
                        </div>
                    </div>
                    <div class="p-0">
                        <div ref="pickerMapEl" class="w-full" style="height: 70vh;"></div>
                        <div class="flex items-center justify-between p-4 border-t">
                            <div class="text-sm text-gray-700 truncate">
                                <span class="font-medium">ตำแหน่ง:</span>
                                <span class="truncate">lat: {{ picker.lat?.toFixed(6) || '-' }}, lng: {{
                                    picker.lng?.toFixed(6) || '-' }}</span>
                            </div>
                            <button
                                class="px-4 py-2 text-white bg-blue-600 rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
                                :disabled="picker.lat == null || picker.lng == null" @click="applyPicker">
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
import { ref, reactive, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useRoute, useRuntimeConfig, useCookie, navigateTo } from '#app'
import AdminHeader from '~/components/admin/AdminHeader.vue'
import AdminSidebar from '~/components/admin/AdminSidebar.vue'
import dayjs from 'dayjs'
import 'dayjs/locale/th'
import buddhistEra from 'dayjs/plugin/buddhistEra'
import { useToast } from '~/composables/useToast'
import { useLongdoMap } from '~/composables/useLongdoMap'

dayjs.locale('th'); dayjs.extend(buddhistEra)

definePageMeta({ middleware: ['admin-auth'] })
useHead({
    title: 'แก้ไขเส้นทาง • Admin',
    link: [{ rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }]
})

const { toast } = useToast()
const route = useRoute()
const config = useRuntimeConfig()
const token = useCookie('token')?.value || (process.client ? localStorage.getItem('token') : '')
const { loadLongdoMap } = useLongdoMap()

/* ----------------- ฟอร์ม ----------------- */
const form = reactive({
    driverId: '',
    vehicleId: '',
    startLocation: { lat: null, lng: null, name: '', address: '' },
    endLocation: { lat: null, lng: null, name: '', address: '' },
    waypoints: [],
    availableSeats: 0,
    pricePerSeat: 0,
    conditions: '',
    departureTimeISO: ''
})
const departureLocal = ref('')

const canSubmit = computed(() => {
    const s = form.startLocation, e = form.endLocation
    return form.driverId && form.vehicleId &&
        s.lat != null && s.lng != null && e.lat != null && e.lng != null &&
        departureLocal.value
})

/* --------- ผู้ขับ (ล็อกตอนแก้ไข) --------- */
const lockDriver = ref(true)
const driverQuery = ref('')
const lastChosenLabel = ref('')
const driverResults = ref([])
const isSearchingDrivers = ref(false)
const showDriverList = computed(() => !lockDriver.value && driverQuery.value && (isSearchingDrivers.value || driverResults.value.length > 0))
let driverTimer = null

async function onSearchDrivers() {
    if (lockDriver.value) return
    clearTimeout(driverTimer)
    const q = driverQuery.value.trim()
    if (!q) { driverResults.value = []; return }
    driverTimer = setTimeout(async () => {
        try {
            isSearchingDrivers.value = true
            const res = await $fetch('/users/admin', {
                baseURL: config.public.apiBase,
                headers: { Accept: 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
                query: { q, page: 1, limit: 10 }
            })
            driverResults.value = res?.data || []
        } catch (e) {
            console.error('search drivers error:', e)
            driverResults.value = []
        } finally {
            isSearchingDrivers.value = false
        }
    }, 300)
}

function selectDriver(u) {
    if (lockDriver.value) return
    form.driverId = u.id
    const label = `${u.firstName || ''} ${u.lastName || ''} (${u.email})`
    driverQuery.value = label
    lastChosenLabel.value = label
    driverResults.value = []
    fetchVehiclesForDriver(u.id)
}

/* ------------- รถ ------------- */
const vehicleOptions = ref([])
async function fetchVehiclesForDriver(driverId) {
    try {
        vehicleOptions.value = []
        if (!driverId) return
        const data = await $fetch(`/vehicles/admin/user/${driverId}`, {
            baseURL: config.public.apiBase,
            headers: { Accept: 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }
        })
        vehicleOptions.value = data?.data || []
    } catch (e) {
        console.error('vehicles error:', e)
        vehicleOptions.value = []
    }
}

/* ----------------- แผนที่ / จีโค้ด / ออโต้คอมพลีต (Longdo) ----------------- */
const mapEl = ref(null)
const startNameRef = ref(null)
const endNameRef = ref(null)

let gmap = null
let startMarker = null, endMarker = null, waypointMarkers = []
let mapOverlays = []
const mapReady = ref(false)

const startName = ref('')
const endName = ref('')
const waypointNames = reactive([])

const startSuggestions = ref([])
const endSuggestions = ref([])
const waypointSuggestions = ref([])
const startFocused = ref(false)
const endFocused = ref(false)
const waypointFocused = ref([])
let startBlurTimer = null
let endBlurTimer = null
const waypointBlurTimers = {}
let startInputTimer = null
let endInputTimer = null
const waypointInputTimers = {}
let programmaticUpdate = false

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
        const mapped = list
            .map((it) => {
                const label = toSuggestLabel(it)
                return label ? { label, raw: it } : null
            })
            .filter(Boolean)
        return mapped.slice(0, 8)
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

const onStartInput = () => {
    startFocused.value = true
    if (startBlurTimer) clearTimeout(startBlurTimer)
    if (startInputTimer) clearTimeout(startInputTimer)
    if (form.startLocation.lat != null || form.startLocation.lng != null) {
        form.startLocation = { ...form.startLocation, lat: null, lng: null }
    }
    const text = startName.value || ''
    startInputTimer = setTimeout(async () => {
        const list = await fetchSuggestions(text)
        if ((startName.value || '') === text) startSuggestions.value = list
    }, 250)
}

const onEndInput = () => {
    endFocused.value = true
    if (endBlurTimer) clearTimeout(endBlurTimer)
    if (endInputTimer) clearTimeout(endInputTimer)
    if (form.endLocation.lat != null || form.endLocation.lng != null) {
        form.endLocation = { ...form.endLocation, lat: null, lng: null }
    }
    const text = endName.value || ''
    endInputTimer = setTimeout(async () => {
        const list = await fetchSuggestions(text)
        if ((endName.value || '') === text) endSuggestions.value = list
    }, 250)
}

const onWaypointInput = (idx) => {
    waypointFocused.value[idx] = true
    if (waypointBlurTimers[idx]) clearTimeout(waypointBlurTimers[idx])
    if (waypointInputTimers[idx]) clearTimeout(waypointInputTimers[idx])
    if (form.waypoints[idx]?.lat != null || form.waypoints[idx]?.lng != null) {
        form.waypoints[idx] = { ...form.waypoints[idx], lat: null, lng: null }
    }
    const text = waypointNames[idx] || ''
    waypointInputTimers[idx] = setTimeout(async () => {
        const list = await fetchSuggestions(text)
        if ((waypointNames[idx] || '') === text) waypointSuggestions.value[idx] = list
    }, 250)
}

const onStartFocus = () => { startFocused.value = true }
const onEndFocus = () => { endFocused.value = true }
const onWaypointFocus = (idx) => { waypointFocused.value[idx] = true }

const onStartBlur = () => {
    startBlurTimer = setTimeout(() => {
        startFocused.value = false
        startSuggestions.value = []
    }, 150)
}

const onEndBlur = () => {
    endBlurTimer = setTimeout(() => {
        endFocused.value = false
        endSuggestions.value = []
    }, 150)
}

const onWaypointBlur = (idx) => {
    waypointBlurTimers[idx] = setTimeout(() => {
        waypointFocused.value[idx] = false
        waypointSuggestions.value[idx] = []
    }, 150)
}

const applyStartSuggestion = async (s) => {
    startName.value = s.label
    startSuggestions.value = []
    const meta = await setMetaFromSuggestion(s.label, s.raw)
    if (meta) {
        form.startLocation = { lat: meta.lat, lng: meta.lng, name: meta.name, address: meta.address }
        drawPreview()
    }
}

const applyEndSuggestion = async (s) => {
    endName.value = s.label
    endSuggestions.value = []
    const meta = await setMetaFromSuggestion(s.label, s.raw)
    if (meta) {
        form.endLocation = { lat: meta.lat, lng: meta.lng, name: meta.name, address: meta.address }
        drawPreview()
    }
}

const applyWaypointSuggestion = async (idx, s) => {
    waypointNames[idx] = s.label
    waypointSuggestions.value[idx] = []
    const meta = await setMetaFromSuggestion(s.label, s.raw)
    if (meta) {
        form.waypoints[idx] = { lat: meta.lat, lng: meta.lng, name: meta.name, address: meta.address }
        drawPreview()
    }
}

const addOverlay = (overlay) => {
    if (!gmap || !overlay) return
    gmap.Overlays.add(overlay)
    mapOverlays.push(overlay)
}

const clearMapOverlays = () => {
    if (!gmap) return
    if (mapOverlays.length) {
        mapOverlays.forEach((o) => {
            try { gmap.Overlays.remove(o) } catch { }
        })
    }
    mapOverlays = []
    startMarker = null
    endMarker = null
    waypointMarkers = []
}

const fitMapToPoints = (points) => {
    if (!gmap || !points?.length) return
    const lats = points.map(p => p.lat).filter((v) => typeof v === 'number')
    const lngs = points.map(p => p.lng).filter((v) => typeof v === 'number')
    if (!lats.length || !lngs.length) return
    const minLat = Math.min(...lats)
    const maxLat = Math.max(...lats)
    const minLon = Math.min(...lngs)
    const maxLon = Math.max(...lngs)
    gmap.location({ lat: (minLat + maxLat) / 2, lon: (minLon + maxLon) / 2 })
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

const initMap = () => {
    if (!mapEl.value || gmap) return
    if (!window.longdo) return
    gmap = new longdo.Map({ placeholder: mapEl.value })
    gmap.location({ lat: 13.7563, lon: 100.5018 })
    gmap.zoom(6)
    mapReady.value = true
    drawPreview()
}

function drawPreview() {
    if (!mapReady.value) return
    clearMapOverlays()
    const points = []
    if (isNum(form.startLocation.lat) && isNum(form.startLocation.lng)) {
        startMarker = new longdo.Marker({ lon: form.startLocation.lng, lat: form.startLocation.lat }, { title: 'จุดเริ่มต้น' })
        addOverlay(startMarker)
        points.push({ lat: form.startLocation.lat, lng: form.startLocation.lng })
    }
    if (isNum(form.endLocation.lat) && isNum(form.endLocation.lng)) {
        endMarker = new longdo.Marker({ lon: form.endLocation.lng, lat: form.endLocation.lat }, { title: 'จุดปลายทาง' })
        addOverlay(endMarker)
        points.push({ lat: form.endLocation.lat, lng: form.endLocation.lng })
    }
    if (form.waypoints.length) {
        waypointMarkers = form.waypoints.filter(Boolean).map((w, i) => {
            const marker = new longdo.Marker(
                { lon: w.lng, lat: w.lat },
                { title: w.name || w.address || `จุดแวะ ${i + 1}` }
            )
            addOverlay(marker)
            points.push({ lat: w.lat, lng: w.lng })
            return marker
        })
    }
    if (points.length) fitMapToPoints(points)
}

function isNum(v) { return typeof v === 'number' && !Number.isNaN(v) }

/* --- ซิงก์จากการพิมพ์เอง (name/address) --- */
async function onNameManual(which) {
    const text = which === 'start' ? startName.value : endName.value
    if (!text) return
    const r = await resolveTextToLocation(text)
    if (!r) return
    programmaticUpdate = true
    if (which === 'start') {
        form.startLocation.name = r.name || text
        form.startLocation.address = r.address || text
        form.startLocation.lat = r.lat
        form.startLocation.lng = r.lng
        startName.value = form.startLocation.name
    } else {
        form.endLocation.name = r.name || text
        form.endLocation.address = r.address || text
        form.endLocation.lat = r.lat
        form.endLocation.lng = r.lng
        endName.value = form.endLocation.name
    }
    programmaticUpdate = false
    drawPreview()
}
async function onAddressManual(which) {
    const text = which === 'start' ? form.startLocation.address : form.endLocation.address
    if (!text) return
    const r = await resolveTextToLocation(text)
    if (!r) return
    programmaticUpdate = true
    if (which === 'start') {
        form.startLocation.name = r.name || text
        form.startLocation.address = r.address || text
        form.startLocation.lat = r.lat
        form.startLocation.lng = r.lng
        startName.value = form.startLocation.name
    } else {
        form.endLocation.name = r.name || text
        form.endLocation.address = r.address || text
        form.endLocation.lat = r.lat
        form.endLocation.lng = r.lng
        endName.value = form.endLocation.name
    }
    programmaticUpdate = false
    drawPreview()
}
async function onWaypointManual(idx) {
    const text = waypointNames[idx]
    if (!text || !form.waypoints[idx]) return
    const r = await resolveTextToLocation(text)
    if (!r) return
    form.waypoints[idx] = { lat: r.lat, lng: r.lng, name: r.name || text, address: r.address || text }
    drawPreview()
}

/* --- ซิงก์เมื่อแก้ lat/lng เอง --- */
let syncTimerStart = null, syncTimerEnd = null
watch(() => [form.startLocation.lat, form.startLocation.lng], async ([lat, lng]) => {
    if (programmaticUpdate) return
    clearTimeout(syncTimerStart)
    syncTimerStart = setTimeout(async () => {
        if (isNum(lat) && isNum(lng)) {
            const r = await reverseGeocode(lat, lng)
            if (r?.address) {
                programmaticUpdate = true
                form.startLocation.name = r.name || form.startLocation.name
                form.startLocation.address = r.address || form.startLocation.address
                startName.value = form.startLocation.name
                programmaticUpdate = false
            }
            drawPreview()
        }
    }, 350)
})
watch(() => [form.endLocation.lat, form.endLocation.lng], async ([lat, lng]) => {
    if (programmaticUpdate) return
    clearTimeout(syncTimerEnd)
    syncTimerEnd = setTimeout(async () => {
        if (isNum(lat) && isNum(lng)) {
            const r = await reverseGeocode(lat, lng)
            if (r?.address) {
                programmaticUpdate = true
                form.endLocation.name = r.name || form.endLocation.name
                form.endLocation.address = r.address || form.endLocation.address
                endName.value = form.endLocation.name
                programmaticUpdate = false
            }
            drawPreview()
        }
    }, 350)
})

/* ---------- Waypoints / Picker ---------- */
const picker = reactive({ show: false, mode: null, index: null, lat: null, lng: null })
const pickerMapEl = ref(null); let pickerMap = null, pickerMarker = null
async function openPicker(mode, index = null) {
    picker.show = true; picker.mode = mode; picker.index = index
    picker.lat = null; picker.lng = null
    try {
        await loadLongdoMap()
    } catch (e) {
        console.error(e)
        toast.error('ไม่สามารถโหลดแผนที่ได้', 'กรุณาตรวจสอบคีย์ Longdo Map')
        picker.show = false
        return
    }
    nextTick(() => {
        const center = { lat: 13.7563, lng: 100.5018 }
        const base = mode === 'start' ? form.startLocation : mode === 'end' ? form.endLocation : form.waypoints[index] || {}
        const c = (isNum(base.lat) && isNum(base.lng)) ? { lat: +base.lat, lng: +base.lng } : center
        pickerMap = new longdo.Map({ placeholder: pickerMapEl.value })
        pickerMap.location({ lon: c.lng, lat: c.lat })
        pickerMap.zoom(isNum(base.lat) ? 14 : 6)
        if (isNum(base.lat) && isNum(base.lng)) {
            setPickerMarker(base.lat, base.lng)
            picker.lat = base.lat; picker.lng = base.lng
        }
        pickerMap.Event.bind('click', () => {
            const loc = pickerMap.location(longdo.LocationMode.Pointer)
            if (!loc || loc.lat == null || loc.lon == null) return
            setPickerMarker(loc.lat, loc.lon)
            picker.lat = loc.lat; picker.lng = loc.lon
        })
    })
}
function setPickerMarker(lat, lng) {
    if (!pickerMap || !window.longdo) return
    if (pickerMarker) {
        pickerMap.Overlays.remove(pickerMarker)
        pickerMarker = null
    }
    pickerMarker = new longdo.Marker({ lon: lng, lat }, { title: 'ตำแหน่งที่เลือก' })
    pickerMap.Overlays.add(pickerMarker)
}
function closePicker() {
    picker.show = false; picker.mode = null; picker.index = null
    if (pickerMap && pickerMarker) {
        pickerMap.Overlays.remove(pickerMarker)
    }
    pickerMarker = null; pickerMap = null
}
async function applyPicker() {
    if (picker.lat == null || picker.lng == null) return
    const info = await reverseGeocode(picker.lat, picker.lng)
    const name = cleanAddr(info?.name || `${picker.lat.toFixed(5)}, ${picker.lng.toFixed(5)}`)
    const address = cleanAddr(info?.address || name)
    programmaticUpdate = true
    if (picker.mode === 'start') {
        form.startLocation.lat = picker.lat; form.startLocation.lng = picker.lng
        form.startLocation.name = name; form.startLocation.address = address
        startName.value = form.startLocation.name
    } else if (picker.mode === 'end') {
        form.endLocation.lat = picker.lat; form.endLocation.lng = picker.lng
        form.endLocation.name = name; form.endLocation.address = address
        endName.value = form.endLocation.name
    } else if (picker.mode === 'waypoint' && picker.index != null) {
        const w = form.waypoints[picker.index]
        if (w) {
            w.lat = picker.lat; w.lng = picker.lng; w.name = name; w.address = address
            waypointNames[picker.index] = w.name
        }
    }
    programmaticUpdate = false
    closePicker(); drawPreview()
}
function addWaypoint() {
    form.waypoints.push({ lat: null, lng: null, name: '', address: '' })
    waypointNames.push('')
    waypointSuggestions.value.push([])
    waypointFocused.value.push(false)
}
function removeWaypoint(i) {
    form.waypoints.splice(i, 1)
    waypointNames.splice(i, 1)
    waypointSuggestions.value.splice(i, 1)
    waypointFocused.value.splice(i, 1)
    if (waypointBlurTimers[i]) {
        clearTimeout(waypointBlurTimers[i])
        delete waypointBlurTimers[i]
    }
    if (waypointInputTimers[i]) {
        clearTimeout(waypointInputTimers[i])
        delete waypointInputTimers[i]
    }
    drawPreview()
}

/* ---------- โหลดข้อมูลเดิม ---------- */
async function fetchRoute() {
    try {
        const res = await $fetch(`/routes/admin/${route.params.id}`, {
            baseURL: config.public.apiBase,
            headers: { Accept: 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }
        })
        const r = res?.data
        if (!r) throw new Error('Invalid response')

        // map → form
        form.driverId = r.driver?.id || ''
        form.vehicleId = r.vehicle?.id || ''
        form.startLocation = {
            lat: r.startLocation?.lat ?? null,
            lng: r.startLocation?.lng ?? null,
            name: r.startLocation?.name || '',
            address: r.startLocation?.address || ''
        }
        form.endLocation = {
            lat: r.endLocation?.lat ?? null,
            lng: r.endLocation?.lng ?? null,
            name: r.endLocation?.name || '',
            address: r.endLocation?.address || ''
        }
        form.waypoints = Array.isArray(r.waypoints?.used)
            ? r.waypoints.used.map(p => ({ lat: p.lat ?? null, lng: p.lng ?? null, name: p.name || '', address: p.address || '' }))
            : Array.isArray(r.waypoints)
                ? r.waypoints.map(p => ({ lat: p.lat ?? null, lng: p.lng ?? null, name: p.name || '', address: p.address || '' }))
                : []

        startName.value = form.startLocation.name || ''
        endName.value = form.endLocation.name || ''
        waypointNames.splice(0, waypointNames.length, ...form.waypoints.map(w => w.name || ''))
        waypointSuggestions.value = form.waypoints.map(() => [])
        waypointFocused.value = form.waypoints.map(() => false)

        form.availableSeats = r.availableSeats ?? 0
        form.pricePerSeat = r.pricePerSeat ?? 0
        form.conditions = r.conditions || ''
        form.departureTimeISO = r.departureTime || ''
        departureLocal.value = r.departureTime ? dayjs(r.departureTime).format('YYYY-MM-DDTHH:mm') : ''

        // ตั้งค่า label ให้ช่องผู้ขับ (โชว์ค่าเริ่มต้น)
        const label = `${r.driver?.firstName || ''} ${r.driver?.lastName || ''} (${r.driver?.email || ''})`.trim()
        driverQuery.value = label
        lastChosenLabel.value = label

        // โหลดรายการรถของผู้ขับเพื่อโชว์ค่าเริ่มต้นของ vehicle
        if (form.driverId) {
            await fetchVehiclesForDriver(form.driverId)
            // กรณีรถปัจจุบันไม่ได้อยู่ใน options (เช่นรถถูกลบ) ให้คงค่าเดิมไว้แต่ dropdown จะว่าง
        }

        // map preview
        if (window.longdo) {
            initMap(); nextTick(drawPreview)
        }
    } catch (e) {
        console.error('fetch route error:', e)
        toast.error('เกิดข้อผิดพลาด', e?.data?.message || 'โหลดข้อมูลเส้นทางไม่สำเร็จ')
    }
}

/* ---------- บันทึก ---------- */
const isSubmitting = ref(false)
async function handleSubmit() {
    isSubmitting.value = true
    try {
        if ((form.startLocation.lat == null || form.startLocation.lng == null) && startName.value) {
            const g = await resolveTextToLocation(startName.value)
            if (g && g.lat != null && g.lng != null) {
                form.startLocation.lat = g.lat
                form.startLocation.lng = g.lng
                form.startLocation.name = g.name || startName.value
                form.startLocation.address = g.address || startName.value
            }
        }
        if ((form.endLocation.lat == null || form.endLocation.lng == null) && endName.value) {
            const g = await resolveTextToLocation(endName.value)
            if (g && g.lat != null && g.lng != null) {
                form.endLocation.lat = g.lat
                form.endLocation.lng = g.lng
                form.endLocation.name = g.name || endName.value
                form.endLocation.address = g.address || endName.value
            }
        }
        if (!canSubmit.value) {
            toast.warning('ข้อมูลไม่ครบ', 'กรุณากรอกข้อมูลให้ครบถ้วน')
            isSubmitting.value = false
            return
        }
        const payload = {
            driverId: form.driverId,
            vehicleId: form.vehicleId,
            startLocation: { ...form.startLocation },
            endLocation: { ...form.endLocation },
            waypoints: form.waypoints.map(w => ({
                lat: +w.lat, lng: +w.lng, name: w.name || '', address: w.address || ''
            })),
            departureTime: new Date(departureLocal.value).toISOString(),
            availableSeats: +form.availableSeats,
            pricePerSeat: +form.pricePerSeat,
            conditions: form.conditions || ''
        }

        await $fetch(`/routes/admin/${route.params.id}`, {
            baseURL: config.public.apiBase,
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                ...(token ? { Authorization: `Bearer ${token}` } : {})
            },
            body: payload
        })

        toast.success('บันทึกสำเร็จ', 'อัปเดตข้อมูลเส้นทางแล้ว')
        navigateTo(`/admin/routes/${route.params.id}`).catch(() => { })
    } catch (e) {
        console.error('update route error:', e)
        toast.error('เกิดข้อผิดพลาด', e?.data?.message || 'ไม่สามารถบันทึกการแก้ไขได้')
    } finally {
        isSubmitting.value = false
    }
}

/* ---------- อื่น ๆ ---------- */
function goBack() { navigateTo(`/admin/routes/${route.params.id}`) }
function cleanAddr(a) {
    return (a || '').replace(/,?\s*(Thailand|ไทย|ประเทศ)\s*$/i, '').replace(/\s{2,}/g, ' ').trim()
}
function closeMobileSidebar() {
    const sidebar = document.getElementById('sidebar')
    const overlay = document.getElementById('overlay')
    if (!sidebar || !overlay) return
    sidebar.classList.remove('mobile-open')
    overlay.classList.add('hidden')
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

        if (gmap && mapReady.value) {
            try { gmap.resize && gmap.resize() } catch { }
            drawPreview()
        }
    }
    window.addEventListener('resize', window.__adminResizeHandler__)
}
function cleanupGlobalScripts() {
    window.removeEventListener('resize', window.__adminResizeHandler__ || (() => { }))
    delete window.__adminResizeHandler__
}

/* Mount */
onMounted(async () => {
    defineGlobalScripts()
    if (typeof window.__adminResizeHandler__ === 'function') window.__adminResizeHandler__()
    try {
        await loadLongdoMap()
    } catch (e) {
        console.error(e)
        toast.error('ไม่สามารถโหลดแผนที่ได้', 'กรุณาตรวจสอบคีย์ Longdo Map')
        return
    }
    initMap()
    await fetchRoute()
})
onUnmounted(() => {
    cleanupGlobalScripts()
})
</script>

<style scoped>
.main-content {
    transition: margin-left 0.3s ease;
}

.modal-fade-enter-active,
.modal-fade-leave-active {
    transition: opacity .25s;
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
