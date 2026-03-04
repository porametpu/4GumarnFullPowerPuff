<template>
    <div>
        <AdminHeader />
        <AdminSidebar />

        <main id="main-content" class="main-content mt-16 ml-0 lg:ml-[280px] p-6 min-h-screen">
            <div class="mx-auto max-w-7xl">
                <!-- Back -->
                <div class="mb-8">
                    <NuxtLink to="/admin/routes"
                        class="inline-flex items-center gap-2 px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50">
                        <i class="fa-solid fa-arrow-left"></i>
                        <span>ย้อนกลับ</span>
                    </NuxtLink>
                </div>

                <!-- Title -->
                <div class="flex flex-col gap-3 mb-6 sm:flex-row sm:items-center sm:justify-between">
                    <div class="flex items-center gap-3">
                        <h1 class="text-2xl font-semibold text-gray-800">สร้างเส้นทาง (แอดมิน)</h1>
                        <span class="text-sm text-gray-500">กรอกข้อมูลเส้นทาง เลือกผู้ขับ และรถที่ใช้</span>
                    </div>
                </div>

                <!-- Card -->
                <div class="flex w-full overflow-hidden bg-white border border-gray-300 rounded-lg shadow-lg">
                    <main class="flex-1 p-8 space-y-8">
                        <!-- SECTION: ผู้ขับขี่ / รถ (ตำแหน่งอ้างอิงจากหน้า detail > ผู้ขับขี่/รถ) -->
                        <section>
                            <h3 class="mb-3 text-sm font-semibold text-gray-700">ผู้ขับขี่และรถ</h3>

                            <!-- Driver search (เหมือน DV) -->
                            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                                <div class="relative">
                                    <label class="block mb-2 text-sm font-medium text-gray-700">
                                        เลือกผู้ขับขี่ (ค้นหา: อีเมล / ชื่อ / Username) <span
                                            class="text-red-500">*</span>
                                    </label>
                                    <input v-model.trim="driverQuery" @input="onSearchDrivers" type="text"
                                        placeholder="เช่น user@example.com หรือ User"
                                        class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                    <div v-if="showDriverList"
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
                                    <p v-if="!form.driverId" class="mt-2 text-xs text-amber-600">*
                                        ต้องเลือกผู้ขับจากรายการ</p>
                                </div>

                                <!-- Vehicle (โหลดตาม driverId) -->
                                <div class="relative">
                                    <label class="block mb-2 text-sm font-medium text-gray-700">
                                        เลือกรถของผู้ขับ <span class="text-red-500">*</span>
                                    </label>
                                    <input v-model.trim="vehicleQuery" @focus="openVehicleList = true"
                                        @input="filterVehicleLocal" type="text" :disabled="!form.driverId"
                                        placeholder="ค้นหาด้วย รุ่น/ป้ายทะเบียน"
                                        class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100" />
                                    <div v-if="openVehicleList && form.driverId"
                                        class="absolute z-20 w-full mt-1 overflow-auto bg-white border rounded-md shadow max-h-60">
                                        <button v-for="v in vehicleFiltered" :key="v.id" type="button"
                                            @click="selectVehicle(v)"
                                            class="w-full px-3 py-2 text-left hover:bg-blue-50">
                                            <div class="text-sm font-medium text-gray-800">
                                                {{ v.vehicleModel }} <span class="text-xs text-gray-500">({{
                                                    v.vehicleType }})</span>
                                            </div>
                                            <div class="text-xs text-gray-500">
                                                {{ v.licensePlate || '— ไม่มีป้าย —' }}
                                            </div>
                                        </button>
                                        <div v-if="!isLoadingVehicles && vehicleFiltered.length === 0"
                                            class="px-3 py-2 text-sm text-gray-500">
                                            ไม่มีรถในรายการ
                                        </div>
                                    </div>
                                    <p v-if="!form.vehicleId" class="mt-2 text-xs text-amber-600">* ต้องเลือกรถจากรายการ
                                    </p>
                                </div>
                            </div>
                        </section>

                        <!-- SECTION: แผนที่เส้นทาง (อ้างอิงตำแหน่งจาก detail: แสดงบนสุดก่อนฟิลด์เส้นทาง) -->
                        <section>
                            <h3 class="mb-3 text-sm font-semibold text-gray-700">แผนที่เส้นทาง</h3>
                            <div class="overflow-hidden border border-gray-300 rounded-lg">
                                <div ref="mapEl" class="w-full" style="height: 360px;"></div>
                            </div>
                        </section>

                        <!-- SECTION: เส้นทาง (ต้นทาง/ปลายทาง) -->
                        <section>
                            <h3 class="mb-3 text-sm font-semibold text-gray-700">เส้นทาง</h3>
                            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                                <!-- Start -->
                                <div>
                                    <label class="block mb-1 text-xs font-medium text-gray-600">จุดเริ่มต้น <span
                                            class="text-red-500">*</span></label>
                                    <div class="relative">
                                        <input ref="startInputEl" v-model="startName" type="text"
                                            placeholder="พิมพ์ชื่อสถานที่ หรือใช้ปุ่มปักหมุด"
                                            @input="onStartInput"
                                            @focus="onStartFocus"
                                            @blur="onStartBlur"
                                            class="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                        <button type="button" @click="openPicker('start')"
                                            class="absolute inset-y-0 my-auto text-gray-500 right-2 hover:text-blue-600"
                                            title="เลือกจากแผนที่">
                                            <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                                                <path
                                                    d="M12 2a7 7 0 00-7 7c0 5.25 7 13 7 13s7-7.75 7-13a7 7 0 00-7-7zm0 9.5a2.5 2.5 0 110-5 2.5 2.5 0 010 5z" />
                                            </svg>
                                        </button>
                                        <ul v-if="startFocused && startSuggestions.length" class="suggest-list">
                                            <li v-for="(s, i) in startSuggestions" :key="i" class="suggest-item"
                                                @mousedown.prevent="applyStartSuggestion(s)">
                                                {{ s.label }}
                                            </li>
                                        </ul>
                                    </div>
                                    <p class="mt-1 text-xs text-gray-500 truncate" v-if="form.startLocation.address">
                                        {{ form.startLocation.address }} ({{ form.startLocation.lat }}, {{
                                        form.startLocation.lng }})
                                    </p>
                                </div>
                                <!-- End -->
                                <div>
                                    <label class="block mb-1 text-xs font-medium text-gray-600">จุดปลายทาง <span
                                            class="text-red-500">*</span></label>
                                    <div class="relative">
                                        <input ref="endInputEl" v-model="endName" type="text"
                                            placeholder="พิมพ์ชื่อสถานที่ หรือใช้ปุ่มปักหมุด"
                                            @input="onEndInput"
                                            @focus="onEndFocus"
                                            @blur="onEndBlur"
                                            class="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                        <button type="button" @click="openPicker('end')"
                                            class="absolute inset-y-0 my-auto text-gray-500 right-2 hover:text-blue-600"
                                            title="เลือกจากแผนที่">
                                            <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                                                <path
                                                    d="M12 2a7 7 0 00-7 7c0 5.25 7 13 7 13s7-7.75 7-13a7 7 0 00-7-7zm0 9.5a2.5 2.5 0 110-5 2.5 2.5 0 010 5z" />
                                            </svg>
                                        </button>
                                        <ul v-if="endFocused && endSuggestions.length" class="suggest-list">
                                            <li v-for="(s, i) in endSuggestions" :key="i" class="suggest-item"
                                                @mousedown.prevent="applyEndSuggestion(s)">
                                                {{ s.label }}
                                            </li>
                                        </ul>
                                    </div>
                                    <p class="mt-1 text-xs text-gray-500 truncate" v-if="form.endLocation.address">
                                        {{ form.endLocation.address }} ({{ form.endLocation.lat }}, {{
                                        form.endLocation.lng }})
                                    </p>
                                </div>
                            </div>
                        </section>

                        <!-- SECTION: จุดแวะระหว่างทาง -->
                        <section>
                            <h3 class="mb-3 text-sm font-semibold text-gray-700">จุดแวะระหว่างทาง</h3>
                            <div class="space-y-3">
                                <div v-for="(w, idx) in form.waypoints" :key="idx"
                                    class="grid grid-cols-1 gap-3 sm:grid-cols-[1fr_auto]">
                                    <div class="relative">
                                        <input :ref="el => (waypointInputs[idx] = el)" v-model="waypointNames[idx]"
                                            type="text" placeholder="ชื่อสถานที่ / ที่อยู่"
                                            @input="onWaypointInput(idx)"
                                            @focus="onWaypointFocus(idx)"
                                            @blur="onWaypointBlur(idx)"
                                            class="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                        <button type="button" @click="openPicker('waypoint', idx)"
                                            class="absolute inset-y-0 my-auto text-gray-500 right-2 hover:text-blue-600"
                                            title="เลือกจากแผนที่">
                                            <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                                                <path
                                                    d="M12 2a7 7 0 00-7 7c0 5.25 7 13 7 13s7-7.75 7-13a7 7 0 00-7-7zm0 9.5a2.5 2.5 0 110-5 2.5 2.5 0 010 5z" />
                                            </svg>
                                        </button>
                                        <ul v-if="waypointFocused[idx] && (waypointSuggestions[idx] || []).length" class="suggest-list">
                                            <li v-for="(s, i) in (waypointSuggestions[idx] || [])" :key="i"
                                                class="suggest-item"
                                                @mousedown.prevent="applyWaypointSuggestion(idx, s)">
                                                {{ s.label }}
                                            </li>
                                        </ul>
                                        <p class="mt-1 text-xs text-gray-500 truncate" v-if="w.address">
                                            {{ w.address }} ({{ w.lat }}, {{ w.lng }})
                                        </p>
                                    </div>
                                    <div class="flex items-center gap-2">
                                        <button type="button" @click="removeWaypoint(idx)"
                                            class="px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50">
                                            ลบ
                                        </button>
                                    </div>
                                </div>

                                <button type="button" @click="addWaypoint"
                                    class="px-4 py-2 text-blue-700 border border-blue-600 rounded-md hover:bg-blue-50">
                                    + เพิ่มจุดแวะ
                                </button>
                            </div>
                        </section>

                        <!-- SECTION: เวลา / ราคา / ที่นั่ง -->
                        <section>
                            <h3 class="mb-3 text-sm font-semibold text-gray-700">เวลา ราคา และความพร้อมที่นั่ง</h3>
                            <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
                                <div>
                                    <label class="block mb-1 text-xs font-medium text-gray-600">วัน-เวลาออกเดินทาง <span
                                            class="text-red-500">*</span></label>
                                    <input v-model="departureLocal" type="datetime-local"
                                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                </div>
                                <div>
                                    <label class="block mb-1 text-xs font-medium text-gray-600">ราคา / ที่นั่ง (บาท)
                                        <span class="text-red-500">*</span></label>
                                    <input v-model.number="form.pricePerSeat" type="number" min="0"
                                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                </div>
                                <div>
                                    <label class="block mb-1 text-xs font-medium text-gray-600">ที่นั่งคงเหลือ <span
                                            class="text-red-500">*</span></label>
                                    <input v-model.number="form.availableSeats" type="number" min="1"
                                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                                </div>
                            </div>
                        </section>

                        <!-- SECTION: เงื่อนไข -->
                        <section>
                            <h3 class="mb-3 text-sm font-semibold text-gray-700">เงื่อนไขการเดินทาง</h3>
                            <textarea v-model="form.conditions" rows="4"
                                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                placeholder="พิมพ์เงื่อนไข เช่น งดเปิดเพลงเสียงดัง, ไม่สูบบุหรี่ในรถ ฯลฯ"></textarea>
                        </section>

                        <!-- Actions (อ้างอิงปุ่มจาก DV) -->
                        <div class="flex justify-end gap-4 pt-2">
                            <button type="button" @click="handleCancel" :disabled="isSubmitting"
                                class="px-6 py-3 text-gray-700 border border-gray-300 rounded-md hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-400 disabled:opacity-50">
                                ยกเลิก
                            </button>
                            <button type="button" @click="handleCreate" :disabled="!canSubmit || isSubmitting"
                                class="flex items-center px-6 py-3 font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-blue-400 disabled:cursor-not-allowed">
                                <svg v-if="isSubmitting" class="w-5 h-5 mr-3 -ml-1 text-white animate-spin"
                                    xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor"
                                        stroke-width="4" />
                                    <path class="opacity-75" fill="currentColor"
                                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                                </svg>
                                {{ isSubmitting ? 'กำลังสร้าง...' : 'สร้างเส้นทาง' }}
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
            <div v-if="showPicker" class="fixed inset-0 z-50 flex items-center justify-center bg-black/60"
                @click.self="closePicker">
                <div class="bg-white rounded-lg w-[95%] max-w-3xl overflow-hidden">
                    <div class="flex items-center justify-between p-4 border-b border-gray-200">
                        <h3 class="text-lg font-semibold text-gray-900">
                            เลือก{{ pickerTarget === 'start' ? 'จุดเริ่มต้น' : pickerTarget === 'end' ? 'จุดปลายทาง' :
                            'จุดแวะ' }}
                        </h3>
                        <button @click="closePicker" class="text-gray-400 hover:text-gray-600">
                            <i class="fa-solid fa-xmark"></i>
                        </button>
                    </div>
                    <div class="p-0">
                        <div ref="pickerMapEl" class="w-full" style="height: 65vh;"></div>
                        <div class="flex items-center justify-between p-4 border-t border-gray-200">
                            <div class="text-sm text-gray-700 truncate">
                                <span class="font-medium">ตำแหน่ง:</span>
                                <span class="truncate">{{ picked.name || '— ยังไม่เลือก —' }}</span>
                            </div>
                            <button
                                class="px-4 py-2 text-white bg-blue-600 rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
                                :disabled="!picked.name" @click="applyPicked">
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
import { ref, reactive, computed, nextTick, onMounted, onUnmounted } from 'vue'
import { useRuntimeConfig, useCookie } from '#app'
import AdminHeader from '~/components/admin/AdminHeader.vue'
import AdminSidebar from '~/components/admin/AdminSidebar.vue'
import { useToast } from '~/composables/useToast'
import { useLongdoMap } from '~/composables/useLongdoMap'

definePageMeta({ middleware: ['admin-auth'] })
useHead({
    title: 'Create Route • Admin',
    link: [{ rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }]
})

const { toast } = useToast()
const config = useRuntimeConfig()
const token = useCookie('token')?.value || (process.client ? localStorage.getItem('token') : '')
const { loadLongdoMap } = useLongdoMap()

/* ====================== Driver & Vehicle (แบบ DV) ====================== */
const driverQuery = ref('')
const driverResults = ref([])
const isSearchingDrivers = ref(false)
const lastDriverLabel = ref('')
const form = reactive({
    driverId: '',
    vehicleId: '',
    startLocation: { lat: null, lng: null, name: '', address: '' },
    endLocation: { lat: null, lng: null, name: '', address: '' },
    waypoints: [],
    departureTime: '', // ISO
    availableSeats: 1,
    pricePerSeat: 0,
    conditions: ''
})
const showDriverList = computed(() => driverQuery.value && (isSearchingDrivers.value || driverResults.value.length > 0))

let userSearchTimer = null
async function onSearchDrivers() {
    if (driverQuery.value !== lastDriverLabel.value) form.driverId = ''
    clearTimeout(userSearchTimer)
    const q = driverQuery.value.trim()
    if (!q) { driverResults.value = []; return }
    userSearchTimer = setTimeout(async () => {
        try {
            isSearchingDrivers.value = true
            const res = await $fetch('/users/admin', {
                baseURL: config.public.apiBase,
                headers: { Accept: 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
                query: { q, page: 1, limit: 10 }
            })
            driverResults.value = res?.data || []
        } catch (e) {
            driverResults.value = []
        } finally {
            isSearchingDrivers.value = false
        }
    }, 300)
}
function selectDriver(u) {
    form.driverId = u.id
    const label = `${u.firstName || ''} ${u.lastName || ''} (@${u.username || ''})`.trim()
    driverQuery.value = label
    lastDriverLabel.value = label
    driverResults.value = []
    // load vehicles for this driver
    loadVehiclesForDriver(u.id)
}

/* Vehicles */
const vehicleQuery = ref('')
const openVehicleList = ref(false)
const isLoadingVehicles = ref(false)
const vehicles = ref([])
const vehicleFiltered = ref([])
async function loadVehiclesForDriver(driverId) {
    if (!driverId) return
    try {
        isLoadingVehicles.value = true
        const res = await $fetch(`/vehicles/admin/user/${driverId}`, {
            baseURL: config.public.apiBase,
            headers: { Accept: 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }
        })
        vehicles.value = res?.data || res || []
        vehicleFiltered.value = vehicles.value
        vehicleQuery.value = ''
        form.vehicleId = ''
    } catch (e) {
        vehicles.value = []
        vehicleFiltered.value = []
        form.vehicleId = ''
    } finally {
        isLoadingVehicles.value = false
    }
}
function filterVehicleLocal() {
    const q = vehicleQuery.value.trim().toLowerCase()
    vehicleFiltered.value = vehicles.value.filter(v =>
        (v.vehicleModel || '').toLowerCase().includes(q) ||
        (v.licensePlate || '').toLowerCase().includes(q) ||
        (v.vehicleType || '').toLowerCase().includes(q)
    )
}
function selectVehicle(v) {
    form.vehicleId = v.id
    vehicleQuery.value = `${v.vehicleModel} (${v.licensePlate || '—'})`
    openVehicleList.value = false
}

/* ====================== Map & Place Picker (Longdo) ====================== */
const mapEl = ref(null)
let gmap = null
let startMarker = null, endMarker = null, waypointMarkers = []
let activePolyline = null
const mapReady = ref(false)
let mapOverlays = []

const startInputEl = ref(null)
const endInputEl = ref(null)
const waypointInputs = reactive([])
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

// modal picker
const showPicker = ref(false)
const pickerMapEl = ref(null)
let pickerMap = null, pickerMarker = null
const pickerTarget = ref(/** @type {'start'|'end'|'waypoint'|null} */(null))
const pickerIndex = ref(-1)
const picked = ref({ name: '', lat: null, lng: null, address: '' })

const startName = ref('')
const endName = ref('')
const waypointNames = reactive([])

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
        redrawMap()
    }
}

const applyEndSuggestion = async (s) => {
    endName.value = s.label
    endSuggestions.value = []
    const meta = await setMetaFromSuggestion(s.label, s.raw)
    if (meta) {
        form.endLocation = { lat: meta.lat, lng: meta.lng, name: meta.name, address: meta.address }
        redrawMap()
    }
}

const applyWaypointSuggestion = async (idx, s) => {
    waypointNames[idx] = s.label
    waypointSuggestions.value[idx] = []
    const meta = await setMetaFromSuggestion(s.label, s.raw)
    if (meta) {
        form.waypoints[idx] = { lat: meta.lat, lng: meta.lng, name: meta.name, address: meta.address }
        redrawMap()
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
    activePolyline = null
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
    redrawMap()
}

function redrawMap() {
    if (!gmap) return
    clearMapOverlays()
    const points = []
    if (form.startLocation.lat && form.startLocation.lng) {
        startMarker = new longdo.Marker({ lon: form.startLocation.lng, lat: form.startLocation.lat }, { title: 'จุดเริ่มต้น' })
        addOverlay(startMarker)
        points.push({ lat: form.startLocation.lat, lng: form.startLocation.lng })
    }
    if (form.endLocation.lat && form.endLocation.lng) {
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

/* Picker */
async function openPicker(target, idx = -1) {
    pickerTarget.value = target
    pickerIndex.value = idx
    picked.value = { name: '', lat: null, lng: null, address: '' }
    showPicker.value = true
    try {
        await loadLongdoMap()
    } catch (e) {
        console.error(e)
        toast.error('ไม่สามารถโหลดแผนที่ได้', 'กรุณาตรวจสอบคีย์ Longdo Map')
        showPicker.value = false
        return
    }
    nextTick(() => {
        const center =
            target === 'start' && form.startLocation.lat ? { lat: form.startLocation.lat, lng: form.startLocation.lng } :
                target === 'end' && form.endLocation.lat ? { lat: form.endLocation.lat, lng: form.endLocation.lng } :
                    (idx > -1 && form.waypoints[idx]?.lat) ? { lat: form.waypoints[idx].lat, lng: form.waypoints[idx].lng } :
                        { lat: 13.7563, lng: 100.5018 }
        pickerMap = new longdo.Map({ placeholder: pickerMapEl.value })
        pickerMap.location({ lon: center.lng, lat: center.lat })
        pickerMap.zoom(center.lat ? 14 : 6)
        pickerMap.Event.bind('click', () => {
            const loc = pickerMap.location(longdo.LocationMode.Pointer)
            if (!loc || loc.lat == null || loc.lon == null) return
            setPicker(loc.lat, loc.lon)
            resolvePicked(loc.lat, loc.lon)
        })
    })
}
function setPicker(lat, lng) {
    if (!pickerMap || !window.longdo) return
    if (pickerMarker) {
        pickerMap.Overlays.remove(pickerMarker)
        pickerMarker = null
    }
    pickerMarker = new longdo.Marker({ lon: lng, lat }, { title: 'ตำแหน่งที่เลือก' })
    pickerMap.Overlays.add(pickerMarker)
}
async function resolvePicked(lat, lng) {
    const info = await reverseGeocode(lat, lng)
    const name = cleanAddr(info?.name || `${lat.toFixed(5)}, ${lng.toFixed(5)}`)
    const address = cleanAddr(info?.address || name)
    picked.value = { name, lat, lng, address }
}
function applyPicked() {
    if (!picked.value?.lat) return
    if (pickerTarget.value === 'start') {
        startName.value = picked.value.name
        form.startLocation = { ...picked.value }
    } else if (pickerTarget.value === 'end') {
        endName.value = picked.value.name
        form.endLocation = { ...picked.value }
    } else if (pickerTarget.value === 'waypoint' && pickerIndex.value > -1) {
        waypointNames[pickerIndex.value] = picked.value.name
        form.waypoints[pickerIndex.value] = { ...picked.value }
    }
    closePicker()
    redrawMap()
}
function closePicker() {
    showPicker.value = false
    if (pickerMap && pickerMarker) {
        pickerMap.Overlays.remove(pickerMarker)
    }
    pickerMap = null; pickerMarker = null
}

/* ====================== Waypoints helpers ====================== */
function addWaypoint() {
    form.waypoints.push({ lat: null, lng: null, name: '', address: '' })
    waypointNames.push('')
    waypointSuggestions.value.push([])
    waypointFocused.value.push(false)
}
function removeWaypoint(idx) {
    form.waypoints.splice(idx, 1)
    waypointNames.splice(idx, 1)
    waypointInputs.splice(idx, 1)
    waypointSuggestions.value.splice(idx, 1)
    waypointFocused.value.splice(idx, 1)
    if (waypointBlurTimers[idx]) {
        clearTimeout(waypointBlurTimers[idx])
        delete waypointBlurTimers[idx]
    }
    if (waypointInputTimers[idx]) {
        clearTimeout(waypointInputTimers[idx])
        delete waypointInputTimers[idx]
    }
    redrawMap()
}

/* ====================== Submit ====================== */
const isSubmitting = ref(false)
const departureLocal = ref('')

const canSubmit = computed(() =>
    !!form.driverId &&
    !!form.vehicleId &&
    !!form.startLocation.lat &&
    !!form.endLocation.lat &&
    !!departureLocal.value &&
    form.availableSeats > 0 &&
    form.pricePerSeat >= 0
)

function toISOLocal(datetimeLocal) {
    // datetime-local เป็น local time → แปลงเป็น ISO (UTC)
    const d = new Date(datetimeLocal)
    return d.toISOString()
}

async function handleCreate() {
    // เติมพิกัดจากข้อความ ถ้ายังไม่มี
    if ((form.startLocation.lat == null || form.startLocation.lng == null) && startName.value) {
        const g = await geocodeAddress(startName.value)
        if (g && g.lat != null && g.lng != null) {
            form.startLocation = { lat: g.lat, lng: g.lng, name: g.name || startName.value, address: g.address || startName.value }
        }
    }
    if ((form.endLocation.lat == null || form.endLocation.lng == null) && endName.value) {
        const g = await geocodeAddress(endName.value)
        if (g && g.lat != null && g.lng != null) {
            form.endLocation = { lat: g.lat, lng: g.lng, name: g.name || endName.value, address: g.address || endName.value }
        }
    }
    for (let i = 0; i < form.waypoints.length; i++) {
        const w = form.waypoints[i]
        const text = waypointNames[i]
        if ((w?.lat == null || w?.lng == null) && text) {
            const g = await geocodeAddress(text)
            if (g && g.lat != null && g.lng != null) {
                form.waypoints[i] = { lat: g.lat, lng: g.lng, name: g.name || text, address: g.address || text }
            }
        }
    }
    if (!canSubmit.value) {
        toast.warning('ข้อมูลไม่ครบถ้วน', 'กรุณากรอก/เลือกข้อมูลที่จำเป็นให้ครบ')
        return
    }
    isSubmitting.value = true
    try {
        const payload = {
            driverId: form.driverId,
            vehicleId: form.vehicleId,
            startLocation: form.startLocation,
            endLocation: form.endLocation,
            waypoints: form.waypoints.filter(w => w && w.lat != null && w.lng != null),
            departureTime: toISOLocal(departureLocal.value),
            availableSeats: Number(form.availableSeats),
            pricePerSeat: Number(form.pricePerSeat),
            conditions: form.conditions || ''
        }

        await $fetch('/routes/admin', {
            baseURL: config.public.apiBase,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                ...(token ? { Authorization: `Bearer ${token}` } : {})
            },
            body: payload
        })

        toast.success('สร้างเส้นทางสำเร็จ', 'บันทึกเส้นทางเรียบร้อย')
        navigateTo('/admin/routes')
    } catch (error) {
        console.error('Create route error:', error)
        toast.error('เกิดข้อผิดพลาด', error?.data?.message || 'ไม่สามารถสร้างเส้นทางได้')
    } finally {
        isSubmitting.value = false
    }
}
function handleCancel() {
    navigateTo('/admin/routes')
}

/* ====================== Utils / Layout ====================== */
function cleanAddr(a) {
    return (a || '').replace(/,?\s*(Thailand|ไทย|ประเทศ)\s*$/i, '').replace(/\s{2,}/g, ' ').trim()
}
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

        if (gmap && mapReady.value) {
            try { gmap.resize && gmap.resize() } catch { }
            redrawMap()
        }
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
        toast.error('ไม่สามารถโหลดแผนที่ได้', 'กรุณาตรวจสอบคีย์ Longdo Map')
        return
    }
    initMap()
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
    transition: opacity .2s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
    opacity: 0;
}

.suggest-list {
    position: absolute;
    z-index: 50;
    width: 100%;
    margin-top: 4px;
    background: #fff;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    box-shadow: 0 6px 16px rgba(0, 0, 0, 0.08);
    max-height: 240px;
    overflow-y: auto;
}

.suggest-item {
    padding: 8px 12px;
    cursor: pointer;
    font-size: 0.9rem;
    color: #111827;
}

.suggest-item:hover {
    background: #f3f4f6;
}
</style>
