<template>
    <div>
        <div class="max-w-4xl px-4 py-8 mx-auto sm:px-6 lg:px-8">
            <div class="mb-8">
                <h2 class="mb-2 text-3xl font-bold text-gray-900">
                    สร้างการเดินทางของคุณ
                </h2>
                <p class="text-gray-600">
                    กำหนดจุดเริ่มต้น ปลายทาง และรายละเอียดต่างๆ เพื่อให้ผู้โดยสารมาร่วมทาง
                </p>
            </div>

            <div class="p-8 bg-white border border-gray-300 rounded-lg shadow-md">
                <form @submit.prevent="handleSubmit" id="postRouteForm" novalidate class="space-y-8">
                    <div>
                        <h3 class="pb-2 mb-6 text-xl font-semibold text-gray-900 border-b border-gray-300">
                            ข้อมูลเส้นทาง
                        </h3>
                        <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                            <div>
                                <label for="startPoint" class="block mb-2 text-sm font-medium text-gray-700">
                                    จุดเริ่มต้น <span class="text-red-500">*</span>
                                </label>
                                <div class="relative">
                                    <input ref="startInputEl" v-model="form.startPoint" id="startPoint"
                                        name="startPoint" type="text" placeholder="เช่น กรุงเทพมหานคร, ถนนสุขุมวิท"
                                        required
                                        @input="onStartInput"
                                        @focus="onStartFocus"
                                        @blur="onStartBlur"
                                        class="w-full px-4 py-3 pr-10 border border-gray-300 rounded-md focus:ring-blue-500" />
                                    <button type="button" @click="openPlacePicker('start')"
                                        class="absolute inset-y-0 my-auto text-gray-500 right-2 hover:text-blue-600"
                                        title="เลือกจากแผนที่">
                                        <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                                            <path
                                                d="M12 2a7 7 0 00-7 7c0 5.25 7 13 7 13s7-7.75 7-13a7 7 0 00-7-7zm0 9.5a2.5 2.5 0 110-5 2.5 2.5 0 010 5z" />
                                        </svg>
                                    </button>
                                    <ul v-if="startFocused && startSuggestions.length" class="suggest-list">
                                        <li v-for="(s, i) in startSuggestions" :key="i"
                                            class="suggest-item"
                                            @mousedown.prevent="applyStartSuggestion(s)">
                                            {{ s.label }}
                                        </li>
                                    </ul>
                                </div>
                            </div>
                            <div>
                                <label for="endPoint" class="block mb-2 text-sm font-medium text-gray-700">
                                    จุดปลายทาง <span class="text-red-500">*</span>
                                </label>
                                <div class="relative">
                                    <input ref="endInputEl" v-model="form.endPoint" id="endPoint" name="endPoint"
                                        type="text" placeholder="เช่น เชียงใหม่, ถนนนิมมานเหมินท์" required
                                        @input="onEndInput"
                                        @focus="onEndFocus"
                                        @blur="onEndBlur"
                                        class="w-full px-4 py-3 pr-10 border border-gray-300 rounded-md focus:ring-blue-500" />
                                    <button type="button" @click="openPlacePicker('end')"
                                        class="absolute inset-y-0 my-auto text-gray-500 right-2 hover:text-blue-600"
                                        title="เลือกจากแผนที่">
                                        <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                                            <path
                                                d="M12 2a7 7 0 00-7 7c0 5.25 7 13 7 13s7-7.75 7-13a7 7 0 00-7-7zm0 9.5a2.5 2.5 0 110-5 2.5 2.5 0 010 5z" />
                                        </svg>
                                    </button>
                                    <ul v-if="endFocused && endSuggestions.length" class="suggest-list">
                                        <li v-for="(s, i) in endSuggestions" :key="i"
                                            class="suggest-item"
                                            @mousedown.prevent="applyEndSuggestion(s)">
                                            {{ s.label }}
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>

                        <div class="mt-6">
                            <label class="block mb-2 text-sm font-medium text-gray-700">
                                จุดแวะ (เพิ่มได้หลายจุด)
                            </label>

                            <div class="space-y-4">
                                <div v-for="(wp, idx) in waypoints" :key="idx" class="relative">
                                    <input :ref="el => waypointInputs[idx] = el" v-model="wp.text" type="text"
                                        :placeholder="`เช่น จุดรับ-ส่ง ระหว่างทาง (#${idx + 1})`"
                                        @input="onWaypointInput(idx)"
                                        @focus="onWaypointFocus(idx)"
                                        @blur="onWaypointBlur(idx)"
                                        class="w-full px-4 py-3 pr-20 border border-gray-300 rounded-md focus:ring-blue-500" />
                                    <div class="absolute inset-y-0 flex items-center gap-2 my-auto right-2">
                                        <button type="button" class="text-gray-500 hover:text-blue-600"
                                            @click="openPlacePicker(`wp-${idx}`)" title="เลือกจากแผนที่">
                                            <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                                                <path
                                                    d="M12 2a7 7 0 00-7 7c0 5.25 7 13 7 13s7-7.75 7-13a7 7 0 00-7-7zm0 9.5a2.5 2.5 0 110-5 2.5 2.5 0 010 5z" />
                                            </svg>
                                        </button>
                                        <button type="button" class="text-gray-500 hover:text-red-600"
                                            @click="removeWaypoint(idx)" title="ลบจุดแวะนี้">
                                            <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                                                <path d="M6 18L18 6M6 6l12 12" />
                                            </svg>
                                        </button>
                                    </div>
                                    <ul v-if="waypointFocused[idx] && (waypointSuggestions[idx] || []).length" class="suggest-list">
                                        <li v-for="(s, i) in (waypointSuggestions[idx] || [])" :key="i"
                                            class="suggest-item"
                                            @mousedown.prevent="applyWaypointSuggestion(idx, s)">
                                            {{ s.label }}
                                        </li>
                                    </ul>
                                </div>

                                <button type="button" @click="addWaypoint"
                                    class="inline-flex items-center gap-2 px-3 py-2 text-sm text-white bg-blue-600 rounded-md cursor-pointer hover:bg-blue-700">
                                    <i class="fa-solid fa-plus"></i>
                                    เพิ่มจุดแวะ
                                </button>
                            </div>
                        </div>
                    </div>

                    <div>
                        <h3 class="pb-2 mb-6 text-xl font-semibold text-gray-900 border-b border-gray-300 ">
                            รายละเอียดการเดินทาง
                        </h3>
                        <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                            <div>
                                <label for="travelDate" class="block mb-2 text-sm font-medium text-gray-700">
                                    วันที่เดินทาง <span class="text-red-500">*</span>
                                </label>
                                <input v-model="form.date" id="travelDate" name="travelDate" type="date" required
                                    class="w-full px-4 py-3 border border-gray-300 rounded-md focus:ring-blue-500" />
                            </div>
                            <div>
                                <label for="travelTime" class="block mb-2 text-sm font-medium text-gray-700">
                                    เวลาออกเดินทาง <span class="text-red-500">*</span>
                                </label>
                                <input v-model="form.time" id="travelTime" name="travelTime" type="time" required
                                    class="w-full px-4 py-3 border border-gray-300 rounded-md focus:ring-blue-500" />
                            </div>
                            <div>
                                <label for="seatCount" class="block mb-2 text-sm font-medium text-gray-700">
                                    จำนวนที่นั่งที่รับได้ <span class="text-red-500">*</span>
                                </label>
                                <input v-model.number="form.availableSeats" id="seatCount" name="seatCount"
                                    type="number" min="1" placeholder="กรอกจำนวนที่นั่ง (เช่น 4)" required
                                    class="w-full px-4 py-3 border border-gray-300 rounded-md focus:ring-blue-500" />
                                <p class="mt-1 text-xs text-gray-500">
                                    รถยนต์ส่วนบุคคลทั่วไปมี 4–5 ที่นั่ง หากใช้รถตู้/รถบัส
                                    ให้ระบุจำนวนได้ตามจริง
                                </p>
                            </div>
                            <div>
                                <label for="pricePerSeat" class="block mb-2 text-sm font-medium text-gray-700">
                                    ราคาต่อที่นั่ง (บาท) <span class="text-red-500">*</span>
                                </label>
                                <input v-model.number="form.pricePerSeat" id="pricePerSeat" name="pricePerSeat"
                                    type="number" min="0" placeholder="เช่น 250" required
                                    class="w-full px-4 py-3 border border-gray-300 rounded-md focus:ring-blue-500" />
                            </div>
                        </div>
                    </div>

                    <div>
                        <h3 class="pb-2 mb-6 text-xl font-semibold text-gray-900 border-b border-gray-300">
                            ข้อมูลรถยนต์
                        </h3>
                        <div v-if="vehicles.length > 0" class="grid items-center grid-cols-1 gap-6 md:grid-cols-2">
                            <div>
                                <label for="vehicle" class="block mb-2 text-sm font-medium text-gray-700">
                                    เลือกรถยนต์ที่จะใช้ <span class="text-red-500">*</span>
                                </label>
                                <select v-model="form.vehicleId" id="vehicle" name="vehicle"
                                    class="w-full px-4 py-3 border border-gray-300 rounded-md focus:ring-blue-500">
                                    <option disabled value="">กรุณาเลือกรถยนต์</option>
                                    <option v-for="v in vehicles" :key="v.id" :value="v.id">
                                        {{ v.vehicleModel }} ({{ v.licensePlate }})
                                    </option>
                                </select>
                            </div>
                            <div class="self-end">
                                <button type="button" @click="isModalOpen = true"
                                    class="w-full px-4 py-3 text-sm text-gray-800 transition-colors bg-gray-100 rounded-md cursor-pointer md:w-auto hover:bg-gray-200">
                                    เพิ่ม / จัดการข้อมูลรถยนต์
                                </button>
                            </div>
                        </div>
                        <div v-else class="p-8 bg-white border border-gray-300 shadow-xl rounded-xl">
                            <div
                                class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4 bg-[#F2F2F2] p-4 md:px-6 md:py-6 rounded-[8px]">
                                <p class="text-gray-800 text-base md:text-[18px] text-center sm:text-left">
                                    คุณยังไม่มีข้อมูลรถยนต์
                                </p>
                                <button type="button" @click="isModalOpen = true"
                                    class="bg-[#2563EB] hover:bg-blue-600 text-white text-sm md:text-[16px] px-4 py-2 rounded-lg transition-colors whitespace-nowrap">
                                    เพิ่ม / จัดการข้อมูล
                                </button>
                            </div>
                        </div>
                    </div>
                    <VehicleModal :show="isModalOpen" @close="closeAndRefresh" />

                    <div>
                        <h3 class="pb-2 mb-6 text-xl font-semibold text-gray-900 border-b border-gray-300">
                            เงื่อนไขและข้อตกลง
                        </h3>
                        <textarea v-model="form.conditions" id="terms" name="terms" rows="4"
                            placeholder="ระบุเงื่อนไข เช่น ไม่สูบบุหรี่, ไม่นำสัตว์เลี้ยง, ชำระเงินล่วงหน้า 50%"
                            class="w-full px-4 py-3 border border-gray-300 rounded-md resize-none focus:ring-blue-500"></textarea>
                    </div>

                    <div>
                        <h3 class="pb-2 mb-6 text-xl font-semibold text-gray-900 border-b border-gray-300">
                            ค่าใช้จ่ายเพิ่มเติม
                        </h3>
                        <div class="space-y-4">
                            <label class="flex items-center justify-between p-3 border border-gray-300 rounded-md">
                            <span class="text-sm font-medium text-gray-800">เปิดรับสัมภาระเกินปกติ</span>
                            <input v-model="form.allowExtraLuggage" type="checkbox" class="w-4 h-4">
                        </label>

                        <div v-if="form.allowExtraLuggage" class="p-4 border border-blue-200 rounded-md bg-blue-50">
                            <p class="mb-3 text-sm text-gray-700">เลือกระดับสูงสุดของสัมภาระที่รับได้</p>
                            <label
                            v-for="opt in EXTRA_LUGGAGE_OPTIONS"
                            :key="opt.value"
                            class="flex items-start justify-between p-3 mb-2 bg-white border border-gray-200 rounded-md cursor-pointer"
                            >
                            <div>
                                <div class="font-medium text-gray-900">{{ opt.label }}</div>
                                <div class="text-xs text-gray-600">คิดเพิ่ม {{ opt.fee }} บาท / การจอง</div>
                            </div>
                            <input v-model="form.maxExtraLuggageType" type="radio" :value="opt.value" class="mt-1">
                            </label>
                        </div>
                        </div>

                    </div>

                    <div class="flex justify-end gap-4 pt-6">
                        <button type="button"
                            class="px-6 py-3 text-gray-700 border border-gray-300 rounded-md cursor-pointer hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500">
                            ยกเลิก
                        </button>
                        <button type="submit" :disabled="isLoading"
                            class="px-6 py-3 font-medium text-white bg-blue-600 rounded-md cursor-pointer hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-400 disabled:cursor-not-allowed">
                            {{ isLoading ? 'กำลังสร้าง...' : 'สร้างการเดินทาง' }}
                        </button>
                    </div>
                </form>
            </div>
            <transition name="modal-fade">
                <div v-if="showPlacePicker" class="modal-overlay" @click.self="closePlacePicker">
                    <div class="modal-content">
                        <div class="flex items-center justify-between p-4 border-b border-gray-300">
                            <h3 class="text-lg font-semibold text-gray-900">
                                เลือก
                                {{ pickingField === 'start'
                                    ? 'จุดเริ่มต้น'
                                    : pickingField === 'end'
                                        ? 'จุดปลายทาง'
                                        : 'จุดแวะ' }}
                            </h3>
                            <button @click="closePlacePicker" class="text-gray-400 hover:text-gray-600">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                        d="M6 18L18 6M6 6l12 12" />
                                </svg>
                            </button>
                        </div>
                        <div class="p-4 space-y-3">
                            <div ref="placePickerMapEl" class="w-full border border-gray-200 rounded-md h-80"></div>
                            <div class="text-sm text-gray-700">
                                <div class="font-medium">ตำแหน่งที่เลือก:</div>
                                <div class="truncate">{{ pickedPlace.name || '— ยังไม่เลือก —' }}</div>
                                <div v-if="pickedPlace.lat && pickedPlace.lng" class="text-gray-500">
                                    lat: {{ pickedPlace.lat.toFixed(6) }}, lng: {{ pickedPlace.lng.toFixed(6) }}
                                </div>
                            </div>
                            <div class="flex gap-3 pt-2">
                                <button @click="closePlacePicker"
                                    class="flex-1 px-4 py-2 font-semibold text-gray-800 bg-gray-200 rounded-md hover:bg-gray-300">
                                    ยกเลิก
                                </button>
                                <button :disabled="!pickedPlace.name" @click="applyPickedPlace"
                                    class="flex-1 px-4 py-2 font-semibold text-white bg-blue-600 rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed">
                                    ใช้ตำแหน่งนี้
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </transition>
        </div>

    </div>

</template>

<script setup>
import { ref, reactive, onMounted, nextTick } from 'vue';
import { useRuntimeConfig } from '#app'
import { useToast } from '~/composables/useToast';
import { navigateTo } from '#app';
import VehicleModal from '~/components/VehicleModal.vue';
import { useLongdoMap } from '~/composables/useLongdoMap'

definePageMeta({ middleware: 'auth' })

const { $api } = useNuxtApp();
const { toast } = useToast();

const isModalOpen = ref(false);
const isLoading = ref(false);
const vehicles = ref([]);

const waypoints = ref([])
const waypointMetas = ref([])
const waypointInputs = ref([])
const waypointSuggestions = ref([])
const waypointFocused = ref([])

const form = reactive({
    vehicleId: '',
    startPoint: '', // ค่าเริ่มต้นสำหรับแสดงผล, จะถูกแทนที่ด้วย lat/lng ตอนส่ง
    endPoint: '', // ค่าเริ่มต้นสำหรับแสดงผล
    date: '',
    time: '',
    availableSeats: null,
    pricePerSeat: null,
    conditions: '',
    allowExtraLuggage: false,
    maxExtraLuggageType: 'MEDIUM',
});

const EXTRA_LUGGAGE_OPTIONS = [
    { value: 'MEDIUM', label: 'ไม่เกิน 24 นิ้ว / ไม่เกิน 20 กก.', fee: 50 },
  { value: 'LARGE', label: 'ไม่เกิน 28 นิ้ว / ไม่เกิน 30 กก.', fee: 100 },
  { value: 'EXTRA_LARGE', label: 'เกิน 28 นิ้ว หรือสัมภาระพิเศษ', fee: 120 },
]

const startInputEl = ref(null)
const endInputEl = ref(null)

const startSuggestions = ref([])
const endSuggestions = ref([])
const startFocused = ref(false)
const endFocused = ref(false)

let startBlurTimer = null
let endBlurTimer = null
const waypointBlurTimers = {}
let startInputTimer = null
let endInputTimer = null
const waypointInputTimers = {}

// meta สำหรับส่งไป backend
const startMeta = ref({ lat: null, lng: null, name: null, address: null, placeId: null })
const endMeta = ref({ lat: null, lng: null, name: null, address: null, placeId: null })

// modal ปักหมุด
const showPlacePicker = ref(false)
const pickingField = ref(null) // 'start' | 'end'
const placePickerMapEl = ref(null)
let placePickerMap = null
let placePickerMarker = null
const pickedPlace = ref({ name: '', lat: null, lng: null })

const config = useRuntimeConfig()
const { loadLongdoMap } = useLongdoMap()

const fetchVehicles = async () => {
    try {
        const userVehicles = await $api('/vehicles');
        vehicles.value = userVehicles;
        // [เพิ่ม] ตั้งค่ารถคันแรก (หรือคันที่เป็น default) เป็นค่าเริ่มต้นในฟอร์ม
        if (userVehicles.length > 0) {
            const defaultVehicle = userVehicles.find(v => v.isDefault) || userVehicles[0];
            form.vehicleId = defaultVehicle.id;
        }
    } catch (error) {
        console.error("Failed to fetch vehicles:", error);
        if (showErrorToast) {
            toast.error('เกิดข้อผิดพลาด', 'ไม่สามารถโหลดข้อมูลรถยนต์ได้');
        }
    }
};

const closeAndRefresh = async () => {
    isModalOpen.value = false;
    await fetchVehicles(false); // Refresh list but suppress error toast
};

const stripHtml = (html) => {
    if (!html) return null;
    return String(html).replace(/<[^>]+>/g, '');
};

const toSuggestLabel = (item) => {
    if (!item) return null;
    if (typeof item === 'string') return item;
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
    );
};

const fetchSuggestions = async (text) => {
    const q = (text || '').trim();
    if (q.length < 2) return [];
    try {
        const res = await $api('/maps/suggest', { query: { keyword: q } });
        const list = normalizeResultList(res?.data ?? res);
        const mapped = list
            .map((it) => {
                const label = toSuggestLabel(it);
                return label ? { label, raw: it } : null;
            })
            .filter(Boolean);
        return mapped.slice(0, 8);
    } catch (e) {
        console.error('Suggest failed:', e);
        return [];
    }
};

const setMetaFromSuggestion = async (label, raw, metaRef) => {
    let ll = coerceLatLng(raw);
    let name = toSuggestLabel(raw) || label;
    let address = raw?.address || raw?.addr || raw?.display_name || name || label;
    if (!ll) {
        const s = await searchKeyword(label);
        if (s && s.lat != null && s.lng != null) {
            ll = { lat: s.lat, lng: s.lng };
            name = s.name || label;
            address = s.address || label;
        } else {
            const g = await geocodeAddress(label);
            if (g && g.lat != null && g.lng != null) {
                ll = { lat: g.lat, lng: g.lng };
                name = g.name || label;
                address = g.address || label;
            }
        }
    }
    if (ll) {
        metaRef.value = {
            lat: ll.lat,
            lng: ll.lng,
            name,
            address,
            placeId: null
        };
    }
};

const onStartInput = () => {
    startFocused.value = true;
    if (startBlurTimer) clearTimeout(startBlurTimer);
    if (startInputTimer) clearTimeout(startInputTimer);
    const text = form.startPoint || '';
    startInputTimer = setTimeout(async () => {
        const list = await fetchSuggestions(text);
        if ((form.startPoint || '') === text) startSuggestions.value = list;
    }, 250);
};

const onEndInput = () => {
    endFocused.value = true;
    if (endBlurTimer) clearTimeout(endBlurTimer);
    if (endInputTimer) clearTimeout(endInputTimer);
    const text = form.endPoint || '';
    endInputTimer = setTimeout(async () => {
        const list = await fetchSuggestions(text);
        if ((form.endPoint || '') === text) endSuggestions.value = list;
    }, 250);
};

const onWaypointInput = (idx) => {
    waypointFocused.value[idx] = true;
    if (waypointBlurTimers[idx]) clearTimeout(waypointBlurTimers[idx]);
    if (waypointInputTimers[idx]) clearTimeout(waypointInputTimers[idx]);
    const text = waypoints.value[idx]?.text || '';
    waypointInputTimers[idx] = setTimeout(async () => {
        const list = await fetchSuggestions(text);
        if ((waypoints.value[idx]?.text || '') === text) {
            waypointSuggestions.value[idx] = list;
        }
    }, 250);
};

const onStartFocus = () => { startFocused.value = true; };
const onEndFocus = () => { endFocused.value = true; };
const onWaypointFocus = (idx) => { waypointFocused.value[idx] = true; };

const onStartBlur = () => {
    startBlurTimer = setTimeout(() => {
        startFocused.value = false;
        startSuggestions.value = [];
    }, 150);
};

const onEndBlur = () => {
    endBlurTimer = setTimeout(() => {
        endFocused.value = false;
        endSuggestions.value = [];
    }, 150);
};

const onWaypointBlur = (idx) => {
    waypointBlurTimers[idx] = setTimeout(() => {
        waypointFocused.value[idx] = false;
        waypointSuggestions.value[idx] = [];
    }, 150);
};

const applyStartSuggestion = async (s) => {
    form.startPoint = s.label;
    startSuggestions.value = [];
    await setMetaFromSuggestion(s.label, s.raw, startMeta);
};

const applyEndSuggestion = async (s) => {
    form.endPoint = s.label;
    endSuggestions.value = [];
    await setMetaFromSuggestion(s.label, s.raw, endMeta);
};

const applyWaypointSuggestion = async (idx, s) => {
    if (!waypoints.value[idx]) return;
    waypoints.value[idx].text = s.label;
    waypointSuggestions.value[idx] = [];
    const metaRef = { value: waypointMetas.value[idx] || {} };
    await setMetaFromSuggestion(s.label, s.raw, metaRef);
    waypointMetas.value[idx] = metaRef.value;
};

const normalizeResultList = (data) => {
    if (!data) return [];
    if (Array.isArray(data)) return data;
    if (Array.isArray(data.suggest)) return data.suggest;
    if (Array.isArray(data.suggestions)) return data.suggestions;
    if (Array.isArray(data.data)) return data.data;
    if (Array.isArray(data.results)) return data.results;
    if (Array.isArray(data.result)) return data.result;
    if (Array.isArray(data.geocode)) return data.geocode;
    if (Array.isArray(data.items)) return data.items;
    if (Array.isArray(data.data?.suggest)) return data.data.suggest;
    if (Array.isArray(data.data?.suggestions)) return data.data.suggestions;
    if (Array.isArray(data.data?.results)) return data.data.results;
    if (Array.isArray(data.data?.result)) return data.data.result;
    if (data.data && Array.isArray(data.data.data)) return data.data.data;
    return [];
};

const coerceLatLng = (item) => {
    if (!item) return null;
    if (typeof item.lat === 'number' && typeof item.lon === 'number') return { lat: item.lat, lng: item.lon };
    if (typeof item.lat === 'number' && typeof item.lng === 'number') return { lat: item.lat, lng: item.lng };
    if (typeof item.latitude === 'number' && typeof item.longitude === 'number') return { lat: item.latitude, lng: item.longitude };
    if (typeof item.x === 'number' && typeof item.y === 'number') return { lat: item.y, lng: item.x };
    if (item.location && typeof item.location.lat === 'number' && typeof item.location.lon === 'number') {
        return { lat: item.location.lat, lng: item.location.lon };
    }
    if (item.location && typeof item.location.lat === 'number' && typeof item.location.lng === 'number') {
        return { lat: item.location.lat, lng: item.location.lng };
    }
    if (Array.isArray(item) && item.length >= 2) {
        const a = Number(item[0]);
        const b = Number(item[1]);
        if (Number.isFinite(a) && Number.isFinite(b)) {
            return Math.abs(a) > 90 ? { lat: b, lng: a } : { lat: a, lng: b };
        }
    }
    return null;
};

const pickFirstLocation = (data) => {
    const list = normalizeResultList(data);
    const item = list[0];
    if (!item) return null;
    const ll = coerceLatLng(item);
    if (!ll) return null;
    const name =
        item.name ||
        item.title ||
        item.display_name ||
        item.address ||
        item.addr ||
        null;
    const address = item.address || item.addr || item.display_name || name || null;
    return { ...ll, name, address };
};

const formatReverseAddress = (data) => {
    if (!data) return null;
    if (typeof data === 'string') return data;
    if (data.address) return data.address;
    if (data.display_name) return data.display_name;
    const parts = [
        data.road,
        data.subdistrict,
        data.district,
        data.province,
        data.postcode
    ].filter(Boolean);
    return parts.length ? parts.join(' ') : null;
};

const geocodeAddress = async (text) => {
    if (!text) return null;
    try {
        const res = await $api('/maps/geocode', { query: { address: text } });
        return pickFirstLocation(res?.data ?? res);
    } catch (e) {
        console.error('Geocode failed:', e);
        return null;
    }
};

const searchKeyword = async (text) => {
    if (!text) return null;
    try {
        const res = await $api('/maps/search', { query: { keyword: text } });
        return pickFirstLocation(res?.data ?? res);
    } catch (e) {
        console.error('Search failed:', e);
        return null;
    }
};

const reverseGeocode = async (lat, lng) => {
    try {
        const res = await $api('/maps/reverse-geocode', { query: { lat, lng } });
        const addr = formatReverseAddress(res?.data ?? res);
        return addr ? { name: addr, address: addr } : null;
    } catch (e) {
        console.error('Reverse geocode failed:', e);
        return null;
    }
};

const ensureMetaFromText = async (metaRef, text) => {
    if (metaRef.value.lat != null && metaRef.value.lng != null) return metaRef.value;
    const g = await geocodeAddress(text);
    if (g && g.lat != null && g.lng != null) {
        metaRef.value = {
            ...metaRef.value,
            lat: g.lat,
            lng: g.lng,
            name: g.name || text,
            address: g.address || text,
            placeId: null
        };
    }
    return metaRef.value;
};

const handleSubmit = async () => {
    if (isLoading.value) return

    // Basic validation (ตามเดิม)
    if (!form.vehicleId || !form.date || !form.time || !form.availableSeats || !form.pricePerSeat) {
        toast.error('ข้อมูลไม่ครบถ้วน', 'กรุณากรอกข้อมูลที่มีเครื่องหมาย * ให้ครบถ้วน')
        return
    }

    isLoading.value = true

    // รวมวันที่+เวลาเป็น ISO (ตามเดิม)
    const departureTime = new Date(`${form.date}T${form.time}`).toISOString()

    // เติมพิกัดจากข้อความ (ถ้ายังไม่มี)
    await ensureMetaFromText(startMeta, form.startPoint)
    await ensureMetaFromText(endMeta, form.endPoint)

    if (startMeta.value.lat == null || startMeta.value.lng == null) {
        toast.error('ไม่พบพิกัดจุดเริ่มต้น', 'กรุณาใส่ที่อยู่/ชื่อสถานที่ที่ชัดเจน')
        isLoading.value = false
        return
    }
    if (endMeta.value.lat == null || endMeta.value.lng == null) {
        toast.error('ไม่พบพิกัดจุดปลายทาง', 'กรุณาใส่ที่อยู่/ชื่อสถานที่ที่ชัดเจน')
        isLoading.value = false
        return
    }

    for (let i = 0; i < waypoints.value.length; i++) {
        const text = waypoints.value[i]?.text
        const meta = waypointMetas.value[i] || {}
        if ((meta.lat == null || meta.lng == null) && text) {
            const g = await geocodeAddress(text)
            if (g && g.lat != null && g.lng != null) {
                waypointMetas.value[i] = {
                    ...meta,
                    lat: g.lat,
                    lng: g.lng,
                    name: g.name || text,
                    address: g.address || text,
                    placeId: null
                }
            }
        }
    }

    const waypointsPayload = waypointMetas.value
        .map((m, i) => {
            const name = (m && m.name) || (waypoints.value[i] && waypoints.value[i].text) || null
            const address = (m && m.address) || (waypoints.value[i] && waypoints.value[i].text) || null
            const lat = m && m.lat != null ? Number(m.lat) : null
            const lng = m && m.lng != null ? Number(m.lng) : null
            if (!name && lat == null && lng == null) return null
            return { lat, lng, name, address }
        })
        .filter(Boolean)

        if(form.allowExtraLuggage && !form.maxExtraLuggageType){
            toast.error('ข้อมูลสัมภาระไม่ครบถ้วน','กรุณาเลือกระดับสัมภาระเพิ่มเติม')
            isLoading.value = false
            return
        }

    const payload = {
        allowExtraLuggage: Boolean(form.allowExtraLuggage),
        ...(form.allowExtraLuggage ? {maxExtraLuggageType: form.maxExtraLuggageType} : {}),
        vehicleId: form.vehicleId,
        startLocation: {
            lat: Number(startMeta.value.lat),
            lng: Number(startMeta.value.lng),
            name: startMeta.value.name || form.startPoint || null,
            address: startMeta.value.address || form.startPoint || null
        },
        endLocation: {
            lat: Number(endMeta.value.lat),
            lng: Number(endMeta.value.lng),
            name: endMeta.value.name || form.endPoint || null,
            address: endMeta.value.address || form.endPoint || null
        },
        waypoints: waypointsPayload,    // << เพิ่ม
        optimizeWaypoints: true,
        departureTime,
        availableSeats: Number(form.availableSeats),
        pricePerSeat: Number(form.pricePerSeat),
        conditions: form.conditions
    }

    // ===== รูปแบบ POST แบบเดียวกับหน้า create user (จัดการ error แบบเจาะจง) =====
    try {
        const apiBase = useRuntimeConfig().public.apiBase || 'http://localhost:3000/api'

        // ดึง token แบบไม่พึ่ง useCookie (เพื่อไม่ต้องแก้ import อื่น)
        let token = ''
        try {
            const m = document.cookie.match(/(?:^|;\s*)token=([^;]+)/)
            if (m) token = decodeURIComponent(m[1])
        } catch { }
        if (process.client && !token) {
            try { token = localStorage.getItem('token') || '' } catch { }
        }

        const res = await fetch(`${apiBase}/routes`, {
            method: 'POST',
            headers: {
                Accept: 'application/json',
                'Content-Type': 'application/json',
                ...(token ? { Authorization: `Bearer ${token}` } : {})
            },
            body: JSON.stringify(payload),
            credentials: 'include'
        })

        let body
        try {
            body = await res.json() // คาดหวัง { success, message, data } หรือ error payload
        } catch {
            const text = await res.text()
            const err = new Error(text || 'Unexpected response from server')
            err.status = res.status
            throw err
        }

        if (!res.ok) {
            const err = new Error(body?.message || `Request failed with status ${res.status}`)
            err.status = res.status
            err.payload = body
            throw err
        }

        // success
        toast.success('สำเร็จ', body?.message || 'สร้างเส้นทางการเดินทางเรียบร้อยแล้ว!')
        setTimeout(() => { navigateTo('/findTrip') }, 1500)

    } catch (err) {
        console.error('Failed to create route:', err)

        const msg = String(err?.message || '')
        const is403 = err?.status === 403
        const needDriverVerify =
            is403 ||
            /ยืนยันตัวตนผู้ขับ/.test(msg) ||                         // จับข้อความไทยจาก API
            /ApiError:.*ยืนยันตัวตนผู้ขับ/.test(msg)                // ครอบกรณีสแต็กเท็กซ์ที่ให้มา

        if (needDriverVerify) {
            toast.error('จำเป็นต้องยืนยันตัวตน', 'คุณต้องยืนยันตัวตนผู้ขับก่อนจึงจะสร้างเส้นทางได้')
            // window.location.href = 'http://localhost:3001/profile/driver-verification'
            setTimeout(() => { navigateTo('/profile/driver-verification') }, 1500)
        } else {
            const fallback = msg || 'ไม่สามารถสร้างเส้นทางได้'
            toast.error('เกิดข้อผิดพลาด', fallback)
        }
    } finally {
        isLoading.value = false
    }
}

function addWaypoint() {
    waypoints.value.push({ text: '' })
    waypointMetas.value.push({ lat: null, lng: null, name: null, address: null, placeId: null })
    waypointSuggestions.value.push([])
    waypointFocused.value.push(false)
}

function removeWaypoint(idx) {
    waypoints.value.splice(idx, 1)
    waypointMetas.value.splice(idx, 1)
    waypointInputs.value.splice(idx, 1)
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
}

async function openPlacePicker(field) {
    pickingField.value = field // 'start' | 'end' | 'wp-<index>'
    pickedPlace.value = { name: '', lat: null, lng: null }
    showPlacePicker.value = true
    try {
        await loadLongdoMap()
    } catch (e) {
        console.error(e)
        toast.error('ไม่สามารถโหลดแผนที่ได้', 'กรุณาตรวจสอบคีย์ Longdo Map')
        showPlacePicker.value = false
        return
    }
    nextTick(() => {
        let base
        if (field === 'start') base = startMeta.value
        else if (field === 'end') base = endMeta.value
        else if (String(field).startsWith('wp-')) {
            const idx = Number(String(field).split('-')[1] || -1)
            base = waypointMetas.value[idx] || {}
        }

        const hasMeta = base && base.lat != null && base.lng != null
        const center = hasMeta ? { lat: base.lat, lng: base.lng } : { lat: 13.7563, lng: 100.5018 }

        placePickerMap = new longdo.Map({ placeholder: placePickerMapEl.value })
        placePickerMap.location({ lon: center.lng, lat: center.lat })
        placePickerMap.zoom(hasMeta ? 14 : 6)

        placePickerMap.Event.bind('click', () => {
            const loc = placePickerMap.location(longdo.LocationMode.Pointer)
            if (!loc || loc.lat == null || loc.lon == null) return
            setPickerMarker(loc.lat, loc.lon)
            resolvePicked(loc.lat, loc.lon)
        })
    })
}

function setPickerMarker(lat, lng) {
    if (!placePickerMap || !window.longdo) return
    if (placePickerMarker) {
        placePickerMap.Overlays.remove(placePickerMarker)
        placePickerMarker = null
    }
    placePickerMarker = new longdo.Marker({ lon: lng, lat }, { title: 'ตำแหน่งที่เลือก' })
    placePickerMap.Overlays.add(placePickerMarker)
}

async function resolvePicked(lat, lng) {
    const info = await reverseGeocode(lat, lng)
    const display = info?.name || `${lat.toFixed(5)}, ${lng.toFixed(5)}`
    pickedPlace.value = { name: display, address: info?.address || display, lat, lng }
}

function applyPickedPlace() {
    if (!pickingField.value || !pickedPlace.value.name) return
    const meta = {
        lat: pickedPlace.value.lat,
        lng: pickedPlace.value.lng,
        name: pickedPlace.value.name,
        address: pickedPlace.value.address || pickedPlace.value.name,
        placeId: null
    }

    if (pickingField.value === 'start') {
        form.startPoint = pickedPlace.value.name
        startMeta.value = meta
    } else if (pickingField.value === 'end') {
        form.endPoint = pickedPlace.value.name
        endMeta.value = meta
    } else if (String(pickingField.value).startsWith('wp-')) {
        const idx = Number(String(pickingField.value).split('-')[1] || -1)
        if (idx > -1) {
            waypoints.value[idx].text = pickedPlace.value.name
            waypointMetas.value[idx] = meta
        }
    }
    closePlacePicker()
}

function closePlacePicker() {
    showPlacePicker.value = false
    pickingField.value = null
    if (placePickerMap && placePickerMarker) {
        placePickerMap.Overlays.remove(placePickerMarker)
    }
    placePickerMarker = null
    placePickerMap = null
}

onMounted(() => {
    fetchVehicles()
})
</script>

<style scoped>
.license-card {
    background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
    border: 3px solid #1e40af;
    border-radius: 12px;
    position: relative;
    overflow: hidden;
    box-shadow: 0 4px 12px rgba(30, 64, 175, 0.2);
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
    font-size: 14px;
    color: #111827;
}

.suggest-item:hover {
    background: #f3f4f6;
}

.selfie-frame {
    background: linear-gradient(135deg, #fef3c7 0%, #fbbf24 100%);
    border: 3px solid #f59e0b;
    border-radius: 20px;
    position: relative;
    overflow: hidden;
    box-shadow: 0 4px 12px rgba(245, 158, 11, 0.2);
}

.person-silhouette {
    background: linear-gradient(135deg, #6b7280 0%, #4b5563 100%);
    border-radius: 50%;
    position: relative;
}

.upload-zone {
    transition: all 0.3s ease;
    cursor: pointer;
}

.upload-zone:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
}

.step-indicator {
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    color: white;
    width: 28px;
    height: 28px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 14px;
    font-weight: bold;
    flex-shrink: 0;
    box-shadow: 0 2px 8px rgba(16, 185, 129, 0.3);
}

.modal-overlay {
    position: fixed;
    z-index: 1000;
    /* ดันให้อยู่บนสุด */
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.6);
    display: flex;
    align-items: center;
    justify-content: center;
}

.modal-content {
    background: #fff;
    border-radius: 0.75rem;
    max-width: 600px;
    width: 95%;
    max-height: 90vh;
    overflow-y: auto;
    box-shadow: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);
}

.modal-fade-enter-active,
.modal-fade-leave-active {
    transition: opacity .3s cubic-bezier(.52, .02, .19, 1.02);
}

.modal-fade-enter-active .modal-content,
.modal-fade-leave-active .modal-content {
    transition: all .3s cubic-bezier(.52, .02, .19, 1.02);
}

.modal-fade-enter-from,
.modal-fade-leave-to {
    opacity: 0;
}

.modal-fade-enter-from .modal-content,
.modal-fade-leave-to .modal-content {
    transform: scale(.9) translateY(1rem);
}
</style>
