<template>
    <div>
        <div class="px-4 py-8 mx-auto max-w-7xl sm:px-6 lg:px-8">
            <div class="p-6 mb-8 bg-white border border-gray-300 rounded-lg shadow-md">
                <h2 class="mb-6 text-xl font-semibold text-gray-900">ค้นหาการเดินทาง</h2>
                <form @submit.prevent="handleSearch" class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-5">
                    <!-- จุดเริ่มต้น -->
                    <div>
                        <label class="block mb-2 text-sm font-medium text-gray-700">จุดเริ่มต้น</label>
                        <div class="relative">
                            <input ref="originInputEl" v-model="searchForm.origin" type="text"
                                placeholder="เช่น กรุงเทพฯ" @input="onOriginInput" @focus="onOriginFocus"
                                @blur="onOriginBlur"
                                class="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                            <!-- ไอคอนปักหมุด -->
                            <button type="button" @click="openPlacePicker('origin')"
                                class="absolute inset-y-0 my-auto text-gray-500 right-2 hover:text-blue-600"
                                title="เลือกจากแผนที่">
                                <!-- pin icon -->
                                <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                                    <path
                                        d="M12 2a7 7 0 00-7 7c0 5.25 7 13 7 13s7-7.75 7-13a7 7 0 00-7-7zm0 9.5a2.5 2.5 0 110-5 2.5 2.5 0 010 5z" />
                                </svg>
                            </button>
                            <ul v-if="originFocused && originSuggestions.length" class="suggest-list">
                                <li v-for="(s, i) in originSuggestions" :key="i" class="suggest-item"
                                    @mousedown.prevent="applyOriginSuggestion(s)">
                                    {{ s.label }}
                                </li>
                            </ul>
                        </div>
                    </div>
                    <!-- จุดปลายทาง -->
                    <div>
                        <label class="block mb-2 text-sm font-medium text-gray-700">จุดปลายทาง</label>
                        <div class="relative">
                            <input ref="destinationInputEl" v-model="searchForm.destination" type="text"
                                placeholder="เช่น เชียงใหม่" @input="onDestinationInput" @focus="onDestinationFocus"
                                @blur="onDestinationBlur"
                                class="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                            <!-- ไอคอนปักหมุด -->
                            <button type="button" @click="openPlacePicker('destination')"
                                class="absolute inset-y-0 my-auto text-gray-500 right-2 hover:text-blue-600"
                                title="เลือกจากแผนที่">
                                <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                                    <path
                                        d="M12 2a7 7 0 00-7 7c0 5.25 7 13 7 13s7-7.75 7-13a7 7 0 00-7-7zm0 9.5a2.5 2.5 0 110-5 2.5 2.5 0 010 5z" />
                                </svg>
                            </button>
                            <ul v-if="destinationFocused && destinationSuggestions.length" class="suggest-list">
                                <li v-for="(s, i) in destinationSuggestions" :key="i" class="suggest-item"
                                    @mousedown.prevent="applyDestinationSuggestion(s)">
                                    {{ s.label }}
                                </li>
                            </ul>
                        </div>
                    </div>
                    <div>
                        <label class="block mb-2 text-sm font-medium text-gray-700">วันที่</label>
                        <input v-model="searchForm.date" type="date"
                            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    </div>
                    <div>
                        <label class="block mb-2 text-sm font-medium text-gray-700">จำนวนที่นั่ง</label>
                        <select v-model="searchForm.seats"
                            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                            <option value="">ค่าเริ่มต้น</option>
                            <option value="1">1 ที่นั่ง</option>
                            <option value="2">2 ที่นั่ง</option>
                            <option value="3">3 ที่นั่ง</option>
                            <option value="4">4 ที่นั่ง</option>
                            <option value="5">5 ที่นั่ง</option>
                            <!-- <option value="6">6 ที่นั่ง</option> -->
                        </select>
                    </div>
                    <div class="flex items-end">
                        <div class="flex items-end gap-2">
                            <button type="submit"
                                class="w-full px-5 py-3 text-white transition duration-200 bg-blue-600 rounded-md cursor-pointer hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                                ค้นหา
                            </button>
                            <button type="button" @click="resetSearch"
                                class="flex-1 px-5 py-3 font-medium text-gray-800 transition duration-200 bg-gray-200 rounded-md cursor-pointer hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-300 focus:ring-offset-2">
                                รีเซ็ต
                            </button>
                        </div>
                    </div>
                </form>
            </div>

            <div class="grid grid-cols-1 gap-6 lg:grid-cols-3 ">
                <div class="lg:col-span-2 ">
                    <div class="bg-white border border-gray-300 rounded-lg shadow-md">
                        <div class="p-6 border-b border-gray-300">
                            <h3 class="text-lg font-semibold text-gray-900">ผลการค้นหา ({{ routes.length }} รายการ)</h3>
                        </div>
                        <div v-if="isLoading" class="p-6 text-center text-gray-500">
                            กำลังค้นหาเส้นทาง...
                        </div>
                        <div v-else class="divide-y divide-gray-200">
                            <div v-if="routes.length === 0" class="p-6 text-center text-gray-500">
                                ไม่พบเส้นทางที่ค้นหา
                            </div>
                            <div v-for="route in routes" :key="route.id"
                                class="p-6 transition-all duration-300 cursor-pointer route-card hover:shadow-lg"
                                @click="toggleDetails(route)">
                                <h1 class="mb-6 font-semibold text-center text-gray-900">
                                    {{ route.originName }} <span class="mx-1 font-semibold text-gray-900">→</span> {{
                                        route.destinationName }}
                                </h1>
                                <div class="flex items-start space-x-4">
                                    <img :src="route.driver.image" :alt="route.driver.name"
                                        class="object-cover w-12 h-12 rounded-full">
                                    <div class="flex-1">
                                        <div class="flex items-start justify-between">
                                            <div>
                                                <div class="flex items-center">
                                                    <h4 class="font-semibold text-gray-900">{{ route.driver.name }}</h4>

                                                    <div v-if="route.driver.isVerified"
                                                        class="relative group ml-1.5 flex items-center">
                                                        <svg class="w-5 h-5 text-blue-600" viewBox="0 0 24 24"
                                                            fill="currentColor">
                                                            <path fill-rule="evenodd"
                                                                d="M8.603 3.799A4.49 4.49 0 0112 2.25c1.357 0 2.573.6 3.397 1.549a4.49 4.49 0 013.498 1.307 4.491 4.491 0 011.307 3.497A4.49 4.49 0 0121.75 12c0 1.357-.6 2.573-1.549 3.397a4.49 4.49 0 01-1.307 3.498 4.491 4.491 0 01-3.497 1.307A4.49 4.49 0 0112 21.75a4.49 4.49 0 01-3.397-1.549 4.49 4.49 0 01-3.498-1.306 4.491 4.491 0 01-1.307-3.498A4.49 4.49 0 012.25 12c0-1.357.6-2.573 1.549-3.397a4.49 4.49 0 011.307-3.497 4.49 4.49 0 013.497-1.307zm7.007 6.387a.75.75 0 10-1.22-.872l-3.236 4.53L9.53 12.22a.75.75 0 00-1.06 1.06l2.25 2.25a.75.75 0 001.07-.01l3.5-4.875z"
                                                                clip-rule="evenodd" />
                                                        </svg>
                                                        <span
                                                            class="absolute px-2 py-1 mb-2 text-xs text-white transition-opacity -translate-x-1/2 bg-gray-800 rounded-md opacity-0 pointer-events-none bottom-full left-1/2 w-max group-hover:opacity-100">
                                                            ผู้ขับขี่ยืนยันตัวตนแล้ว
                                                        </span>
                                                    </div>
                                                </div>
                                                <div class="flex items-center mt-1">
                                                    <div class="flex text-yellow-400">
                                                        <span v-for="star in 5" :key="star">{{ star <=
                                                            route.driver.rating ? '★' : '☆' }}</span>
                                                    </div>
                                                    <span class="ml-2 text-sm text-gray-600">
                                                        {{ route.driver.rating }} ({{ route.driver.reviews }} รีวิว)
                                                    </span>
                                                </div>
                                            </div>
                                            <div class="text-right">
                                                <div class="text-lg font-bold text-blue-600">{{ route.price }} บาท</div>
                                                <div class="text-sm text-gray-600">ต่อที่นั่ง</div>
                                            </div>
                                        </div>
                                        <div class="mt-3">
                                            <div class="flex flex-wrap items-center text-sm text-gray-600">
                                                <span class="font-medium">{{ route.date }}</span>
                                                <span class="mx-2 text-gray-300">|</span>
                                                <span class="font-medium">เวลาออก:</span>
                                                <span class="ml-1">{{ route.departureTime }}</span>
                                                <span class="mx-2 text-gray-300">|</span>
                                                <span class="font-medium">ระยะเวลา:</span>
                                                <span class="ml-1">{{ route.durationText }}</span>
                                                <span class="mx-2 text-gray-300">|</span>
                                                <span class="font-medium">ระยะทาง:</span>
                                                <span class="ml-1">{{ route.distanceText }}</span>
                                            </div>

                                            <div class="flex items-center mt-2 text-sm text-gray-600">
                                                <span :class="[
                                                    'px-2 py-1 rounded-full text-xs font-medium',
                                                    route.availableSeats > 2 ? 'bg-green-100 text-green-800' : route.availableSeats > 0 ? 'bg-yellow-100 text-yellow-800' : 'bg-red-100 text-red-800'
                                                ]">
                                                    {{ route.availableSeats > 0 ? `เหลือ ${route.availableSeats}
                                                    ที่นั่ง` : 'เต็มแล้ว' }}
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div v-if="selectedRoute && selectedRoute.id === route.id"
                                    class="pt-4 mt-4 duration-300 border-t border-gray-300 animate-in slide-in-from-top">
                                    <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                                        <div>
                                            <h5 class="mb-2 font-medium text-gray-900">รายละเอียดเส้นทาง</h5>
                                            <ul class="space-y-1 text-sm text-gray-600">
                                                <li>
                                                    • จุดเริ่มต้น:
                                                    <span class="font-medium text-gray-900">{{ route.originName
                                                    }}</span>
                                                    <span v-if="route.originAddress"> — {{ route.originAddress }}</span>
                                                </li>

                                                <template v-if="route.stops && route.stops.length">
                                                    <li class="mt-2 text-gray-700">• จุดแวะระหว่างทาง ({{
                                                        route.stops.length }} จุด):</li>
                                                    <li v-for="(stop, idx) in route.stops" :key="idx">  - จุดแวะ {{ idx
                                                        + 1 }}: {{ stop }}</li>
                                                </template>

                                                <li class="mt-1">
                                                    • จุดปลายทาง:
                                                    <span class="font-medium text-gray-900">{{ route.destinationName
                                                    }}</span>
                                                    <span v-if="route.destinationAddress"> — {{ route.destinationAddress
                                                    }}</span>
                                                </li>
                                            </ul>
                                            <!-- <ul class="space-y-1 text-sm text-gray-600">
                                                <li v-for="stop in route.stops" :key="stop">• {{ stop }}</li>
                                            </ul> -->
                                        </div>
                                        <div>
                                            <h5 class="mb-2 font-medium text-gray-900">รายละเอียดรถ</h5>
                                            <ul class="space-y-1 text-sm text-gray-600">
                                                <li v-for="detail in route.carDetails" :key="detail">• {{ detail }}</li>
                                            </ul>
                                        </div>
                                    </div>
                                    <div class="mt-4 space-y-4">
                                        <div v-if="route.conditions">
                                            <h5 class="mb-2 font-medium text-gray-900">เงื่อนไขการเดินทาง</h5>
                                            <p
                                                class="p-3 text-sm text-gray-700 border border-gray-300 rounded-md bg-gray-50">
                                                {{ route.conditions }}
                                            </p>
                                        </div>
                                        <div v-if="route.photos && route.photos.length > 0">
                                            <h5 class="mb-2 font-medium text-gray-900">รูปภาพรถยนต์</h5>
                                            <div class="grid grid-cols-3 gap-2 mt-2 ">
                                                <div v-for="(photo, index) in route.photos.slice(0, 3)" :key="index"
                                                    class="">
                                                    <img :src="photo" alt="Vehicle photo"
                                                        class="object-cover w-full transition-opacity border border-gray-300 rounded-lg shadow-sm cursor-pointer aspect-video hover:opacity-90">
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="flex justify-end mt-4">
                                        <button @click.stop="openModal(route)" :disabled="route.availableSeats === 0"
                                            class="px-6 py-2 text-white transition duration-200 bg-blue-600 rounded-md cursor-pointer hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed">
                                            จองที่นั่ง
                                        </button>
                                    </div>
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
                        <div ref="mapContainer" class="h-96"></div>
                    </div>
                </div>
            </div>
        </div>

        <transition name="modal-fade">
            <div v-if="showModal && bookingRoute" class="modal-overlay" @click.self="closeModal">
                <div class="modal-content">
                    <template v-if="!bookingPickingTarget">
                        <div class="flex items-center justify-between p-6 border-b border-gray-300">
                            <h3 class="text-xl font-semibold text-gray-900">ยืนยันการจอง</h3>
                            <button @click="closeModal" class="text-gray-400 hover:text-gray-600">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                        d="M6 18L18 6M6 6l12 12"></path>
                                </svg>
                            </button>
                        </div>
                    </template>
                    <template v-else>
                        <div class="flex items-center justify-between p-4 border-b border-gray-300">
                            <h3 class="text-lg font-semibold text-gray-900">
                                เลือก{{ bookingPickingTarget === 'pickup' ? 'จุดขึ้นรถ' : 'จุดลงรถ' }}
                            </h3>
                            <button @click="stopBookingPicker" class="text-gray-400 hover:text-gray-600">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                        d="M6 18L18 6M6 6l12 12" />
                                </svg>
                            </button>
                        </div>
                        <div class="p-0">
                            <div ref="bookingPickerMapEl" class="w-full" style="height: 72vh;"></div>
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
                    </template>
                    <div class="p-6">
                        <div class="mb-6">
                            <h4 class="mb-3 font-semibold text-gray-900">เดินทางกับ</h4>
                            <div class="flex items-center p-3 space-x-3 rounded-lg bg-gray-50">
                                <img :src="bookingRoute.driver.image" :alt="bookingRoute.driver.name"
                                    class="object-cover w-12 h-12 rounded-full">
                                <div>
                                    <!-- <div class="font-medium text-gray-900">{{ bookingRoute.driver.name }}</div> -->
                                    <div class="flex items-center">
                                        <div class="font-medium text-gray-900">{{ bookingRoute.driver.name }}</div>

                                        <div v-if="bookingRoute.driver.isVerified"
                                            class="relative group ml-1.5 flex items-center">
                                            <svg class="w-5 h-5 text-blue-600" viewBox="0 0 24 24" fill="currentColor">
                                                <path fill-rule="evenodd"
                                                    d="M8.603 3.799A4.49 4.49 0 0112 2.25c1.357 0 2.573.6 3.397 1.549a4.49 4.49 0 013.498 1.307 4.491 4.491 0 011.307 3.497A4.49 4.49 0 0121.75 12c0 1.357-.6 2.573-1.549 3.397a4.49 4.49 0 01-1.307 3.498 4.491 4.491 0 01-3.497 1.307A4.49 4.49 0 0112 21.75a4.49 4.49 0 01-3.397-1.549 4.49 4.49 0 01-3.498-1.306 4.491 4.491 0 01-1.307-3.498A4.49 4.49 0 012.25 12c0-1.357.6-2.573 1.549-3.397a4.49 4.49 0 011.307-3.497 4.49 4.49 0 013.497-1.307zm7.007 6.387a.75.75 0 10-1.22-.872l-3.236 4.53L9.53 12.22a.75.75 0 00-1.06 1.06l2.25 2.25a.75.75 0 001.07-.01l3.5-4.875z"
                                                    clip-rule="evenodd" />
                                            </svg>
                                            <span
                                                class="absolute px-2 py-1 mb-2 text-xs text-white transition-opacity -translate-x-1/2 bg-gray-800 rounded-md opacity-0 pointer-events-none bottom-full left-1/2 w-max group-hover:opacity-100">
                                                ผู้ขับขี่ยืนยันตัวตนแล้ว
                                            </span>
                                        </div>
                                    </div>
                                    <div class="flex items-center">
                                        <div class="flex text-sm text-yellow-400">
                                            <span v-for="star in 5" :key="star">{{ star <= bookingRoute.driver.rating
                                                ? '★' : '☆' }}</span>
                                        </div>
                                        <span class="ml-2 text-sm text-gray-600">{{ bookingRoute.driver.rating }} ({{
                                            bookingRoute.driver.reviews }} รีวิว)</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="grid grid-cols-1 gap-6 mb-6 md:grid-cols-2">
                            <div>
                                <label class="block mb-2 text-sm font-medium text-gray-700">วันที่เดินทาง</label>
                                <div class="p-3 text-gray-900 rounded-lg bg-gray-50">
                                    {{ bookingRoute.date }}
                                </div>
                            </div>
                            <div>
                                <label class="block mb-2 text-sm font-medium text-gray-700">เวลาออก</label>
                                <div class="p-3 text-gray-900 rounded-lg bg-gray-50">
                                    {{ bookingRoute.departureTime }}
                                </div>
                            </div>
                        </div>
                        <div class="mb-6">
                            <h4 class="mb-3 font-semibold text-gray-900">เส้นทางการเดินทาง</h4>
                            <div class="flex items-center p-3 space-x-4 rounded-lg bg-gray-50">
                                <div class="flex-1">
                                    <div class="font-medium text-gray-900">{{ bookingRoute.originName }}</div>
                                    <div class="text-sm text-gray-600">จุดเริ่มต้น</div>
                                </div>
                                <div class="text-blue-600">
                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                            d="M9 5l7 7-7 7">
                                        </path>
                                    </svg>
                                </div>
                                <div class="flex-1 text-right">
                                    <div class="font-medium text-gray-900">{{ bookingRoute.destinationName }}</div>
                                    <div class="text-sm text-gray-600">จุดปลายทาง</div>
                                </div>
                            </div>
                        </div>
                        <div class="mb-6 space-y-4">
                            <div>
                                <label
                                    class="block mb-2 text-sm font-medium text-gray-700">จำนวนที่นั่งที่ต้องการจอง</label>
                                <select v-model="bookingSeats"
                                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                                    <option v-for="seat in bookingRoute.availableSeats" :key="seat" :value="seat">
                                        {{ seat }} ที่นั่ง
                                    </option>
                                </select>
                            </div>
                            <div>
                                <label class="block mb-2 text-sm font-medium text-gray-700">เลือกจุดขึ้นรถ</label>
                                <div class="relative">
                                    <input ref="pickupInputEl" v-model="pickupPoint" type="text"
                                        placeholder="พิมพ์ชื่อสถานที่..." @input="onPickupInput" @focus="onPickupFocus"
                                        @blur="onPickupBlur"
                                        class="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
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
                                        class="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
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

                            <div>
                                <div v-if="bookingRoute.allowExtraLuggage"
                                    class="p-3 border border-blue-200 rounded-md bg-blue-50">
                                    <label class="flex items-center justify-between">
                                        <span class="text-sm font-medium text-gray-800">มีสัมภาระเกินปกติ</span>
                                        <input v-model="extraLuggageSelected" type="checkbox" class="w-4 h-4">
                                    </label>

                                    <div v-if="extraLuggageSelected" class="mt-3 space-y-2">
                                        <label v-for="opt in allowedExtraLuggageOptions" :key="opt.value"
                                            class="flex items-center justify-between p-2 bg-white border border-gray-200 rounded-md">
                                            <span class="text-sm text-gray-800">{{ opt.label }}</span>
                                            <div class="flex items-center gap-3">
                                                <span class="text-xs text-blue-700">+{{ opt.fee }} บาท</span>
                                                <input v-model="extraLuggageType" type="radio" :value="opt.value">
                                            </div>
                                        </label>
                                    </div>
                                </div>

                            </div>




                        </div>
                        <div class="p-4 mb-6 rounded-lg bg-blue-50">
                            <div class="flex items-center justify-between mb-2">
                                <span class="text-gray-700">ราคาต่อที่นั่ง</span>
                                <span class="font-medium text-gray-900">{{ bookingRoute.price }} บาท</span>
                            </div>
                            <div class="flex items-center justify-between mb-2">
                                <span class="text-gray-700">จำนวนที่นั่ง</span>
                                <span class="font-medium text-gray-900">{{ bookingSeats }} ที่นั่ง</span>
                            </div>
                            <div class="pt-2 mt-2 border-t border-gray-300">
                                <div class="flex items-center justify-between">
                                    <span class="font-semibold text-gray-900">ยอดรวม</span>
                                    <span class="text-lg font-bold text-blue-600">{{ bookingTotalPrice }} บาท</span>
                                </div>
                                <div v-if="extraLuggageSelected" class="flex items-center justify-between mb-2">
                                    <span class="text-gray-700">ค่าสัมภาระเพิ่มเติม</span>
                                    <span class="font-medium text-gray-900">{{ extraLuggageFee }} บาท</span>
                                </div>

                            </div>
                        </div>
                        <div class="flex space-x-4">
                            <button @click="closeModal"
                                class="flex-1 px-4 py-3 font-semibold text-gray-800 transition duration-200 bg-gray-200 rounded-md hover:bg-gray-300">
                                ยกเลิก
                            </button>
                            <button @click="confirmBooking"
                                class="flex-1 px-4 py-3 font-semibold text-white transition duration-200 bg-blue-600 rounded-md hover:bg-blue-700">
                                ยืนยันการจอง
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </transition>
        <!-- Map Picker Modal -->
        <transition name="modal-fade">
            <div v-if="showPlacePicker" class="modal-overlay" @click.self="closePlacePicker">
                <div class="modal-content">
                    <div class="flex items-center justify-between p-4 border-b border-gray-300">
                        <h3 class="text-lg font-semibold text-gray-900">เลือก{{ pickingField === 'origin' ?
                            'จุดเริ่มต้น' : 'จุดปลายทาง' }}</h3>
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
</template>


<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import dayjs from 'dayjs'
import 'dayjs/locale/th'
import buddhistEra from 'dayjs/plugin/buddhistEra'
import { useToast } from '~/composables/useToast';
import { useAuth } from '~/composables/useAuth';
import { useLongdoMap } from '~/composables/useLongdoMap'
import { navigateTo } from '#app';

dayjs.locale('th')
dayjs.extend(buddhistEra)

const { $api } = useNuxtApp()
const { toast } = useToast();
const { token } = useAuth();
const { loadLongdoMap } = useLongdoMap()

// --- Booking modal: Suggest + Picker ---
const pickupInputEl = ref(null)
const dropoffInputEl = ref(null)

// โครงสร้างเต็มที่จะส่งให้ API
const pickupData = ref({ lat: null, lng: null, placeId: null, address: null, name: null })
const dropoffData = ref({ lat: null, lng: null, placeId: null, address: null, name: null })

// โหมดปักหมุดใน modal เดิม
const bookingPickingTarget = ref(/** @type {'pickup'|'dropoff'|null} */(null))
const bookingPickerMapEl = ref(null)
let bookingPickerMap = null
let bookingPickerMarker = null
const bookingPicked = ref({ name: '', lat: null, lng: null, placeId: null, address: null })

// ---- NEW: refs & state สำหรับ Suggest ----
const originInputEl = ref(null)
const destinationInputEl = ref(null)

// --- สำหรับ Map Picker ---
const showPlacePicker = ref(false)
const pickingField = ref(/** @type {'origin'|'destination'|null} */(null))
const placePickerMapEl = ref(null)
let placePickerMap = null
let placePickerMarker = null
const pickedPlace = ref({ name: '', lat: null, lng: null })

// ---- Suggest state (origin/destination + booking pickup/dropoff) ----
const originSuggestions = ref([])
const destinationSuggestions = ref([])
const pickupSuggestions = ref([])
const dropoffSuggestions = ref([])
const originFocused = ref(false)
const destinationFocused = ref(false)
const pickupFocused = ref(false)
const dropoffFocused = ref(false)
let originBlurTimer = null
let destinationBlurTimer = null
let pickupBlurTimer = null
let dropoffBlurTimer = null
let originInputTimer = null
let destinationInputTimer = null
let pickupInputTimer = null
let dropoffInputTimer = null

useHead({
    title: 'ค้นหาเส้นทาง - Car Pool',
    link: [
        { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css2?family=Kanit:wght@300;400;500;600;700&display=swap' },
        // { rel: 'stylesheet', href: 'https://unpkg.com/leaflet@1.7.1/dist/leaflet.css' }
    ],
})

const searchForm = ref({
    origin: '',
    destination: '',
    date: '',
    seats: ''
})
const RADIUS_METERS = 500

const routes = ref([])
const selectedRoute = ref(null)
const isLoading = ref(false)

const mapContainer = ref(null)
let gmap = null               // แผนที่ของ Longdo
let activePolyline = null     // เส้นทางที่กำลังแสดงอยู่
let startMarker = null
let endMarker = null
const mapReady = ref(false)
let stopMarkers = []
let mapOverlays = []

const showModal = ref(false)
const bookingRoute = ref(null)
const bookingSeats = ref(1)
const pickupPoint = ref('')
const dropoffPoint = ref('')
const extraLuggageSelected = ref(false)
const extraLuggageType = ref('MEDIUM')

const EXTRA_LUGGAGE_OPTIONS = [
    { value: 'MEDIUM', label: 'ไม่เกิน 24 นิ้ว / ไม่เกิน 20 กก.', fee: 50 },
    { value: 'LARGE', label: 'ไม่เกิน 28 นิ้ว / ไม่เกิน 30 กก.', fee: 100 },
    { value: 'EXTRA_LARGE', label: 'เกิน 28 นิ้ว หรือสัมภาระพิเศษ', fee: 120 },
]

const LUGGAGE_ORDER = { MEDIUM: 1, LARGE: 2, EXTRA_LARGE: 3 }

const allowedExtraLuggageOptions = computed(() => {
    if (!bookingRoute.value?.allowExtraLuggage) return []
    const maxType = bookingRoute.value?.maxExtraLuggageType || 'MEDIUM'
    return EXTRA_LUGGAGE_OPTIONS.filter((opt) => LUGGAGE_ORDER[opt.value] <= LUGGAGE_ORDER[maxType])
})

const extraLuggageFee = computed(() => {
    if (!extraLuggageSelected.value) return 0
    const found = EXTRA_LUGGAGE_OPTIONS.find((o) => o.value === extraLuggageType.value)
    return found ? found.fee : 0
})

const bookingTotalPrice = computed(() => {
    if (!bookingRoute.value) return 0
    const base = bookingSeats.value * bookingRoute.value.price
    return base + extraLuggageFee.value
})

function cleanAddr(a) {
    return (a || '')
        .replace(/,?\s*(Thailand|ไทย|ประเทศ)\s*$/i, '') // ตัดทั้ง Thailand/ไทย/ประเทศ ที่อยู่ท้ายสตริง
        .replace(/\s{2,}/g, ' ')                         // เก็บช่องว่างซ้ำ
        .trim();
}

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
    const num = (v) => (typeof v === 'string' ? Number(v) : v);
    const lat = num(item.lat);
    const lon = num(item.lon);
    const lng = num(item.lng);
    const latitude = num(item.latitude);
    const longitude = num(item.longitude);
    const x = num(item.x);
    const y = num(item.y);
    if (Number.isFinite(lat) && Number.isFinite(lon)) return { lat, lng: lon };
    if (Number.isFinite(lat) && Number.isFinite(lng)) return { lat, lng };
    if (Number.isFinite(latitude) && Number.isFinite(longitude)) return { lat: latitude, lng: longitude };
    if (Number.isFinite(x) && Number.isFinite(y)) return { lat: y, lng: x };
    if (item.location) {
        const locLat = num(item.location.lat);
        const locLon = num(item.location.lon);
        const locLng = num(item.location.lng);
        if (Number.isFinite(locLat) && Number.isFinite(locLon)) return { lat: locLat, lng: locLon };
        if (Number.isFinite(locLat) && Number.isFinite(locLng)) return { lat: locLat, lng: locLng };
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

const resolveSuggestionMeta = async (label, raw) => {
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
    if (!ll) return null;
    return { lat: ll.lat, lng: ll.lng, name, address };
};

const onOriginInput = () => {
    originFocused.value = true;
    if (originBlurTimer) clearTimeout(originBlurTimer);
    if (originInputTimer) clearTimeout(originInputTimer);
    const text = searchForm.value.origin || '';
    originInputTimer = setTimeout(async () => {
        const list = await fetchSuggestions(text);
        if ((searchForm.value.origin || '') === text) originSuggestions.value = list;
    }, 250);
};

const onDestinationInput = () => {
    destinationFocused.value = true;
    if (destinationBlurTimer) clearTimeout(destinationBlurTimer);
    if (destinationInputTimer) clearTimeout(destinationInputTimer);
    const text = searchForm.value.destination || '';
    destinationInputTimer = setTimeout(async () => {
        const list = await fetchSuggestions(text);
        if ((searchForm.value.destination || '') === text) destinationSuggestions.value = list;
    }, 250);
};

const onPickupInput = () => {
    pickupFocused.value = true;
    if (pickupBlurTimer) clearTimeout(pickupBlurTimer);
    if (pickupInputTimer) clearTimeout(pickupInputTimer);
    const text = pickupPoint.value || '';
    pickupInputTimer = setTimeout(async () => {
        const list = await fetchSuggestions(text);
        if ((pickupPoint.value || '') === text) pickupSuggestions.value = list;
    }, 250);
};

const onDropoffInput = () => {
    dropoffFocused.value = true;
    if (dropoffBlurTimer) clearTimeout(dropoffBlurTimer);
    if (dropoffInputTimer) clearTimeout(dropoffInputTimer);
    const text = dropoffPoint.value || '';
    dropoffInputTimer = setTimeout(async () => {
        const list = await fetchSuggestions(text);
        if ((dropoffPoint.value || '') === text) dropoffSuggestions.value = list;
    }, 250);
};

const onOriginFocus = () => { originFocused.value = true; };
const onDestinationFocus = () => { destinationFocused.value = true; };
const onPickupFocus = () => { pickupFocused.value = true; };
const onDropoffFocus = () => { dropoffFocused.value = true; };

const onOriginBlur = () => {
    originBlurTimer = setTimeout(() => {
        originFocused.value = false;
        originSuggestions.value = [];
    }, 150);
};

const onDestinationBlur = () => {
    destinationBlurTimer = setTimeout(() => {
        destinationFocused.value = false;
        destinationSuggestions.value = [];
    }, 150);
};

const onPickupBlur = () => {
    pickupBlurTimer = setTimeout(() => {
        pickupFocused.value = false;
        pickupSuggestions.value = [];
    }, 150);
};

const onDropoffBlur = () => {
    dropoffBlurTimer = setTimeout(() => {
        dropoffFocused.value = false;
        dropoffSuggestions.value = [];
    }, 150);
};

const applyOriginSuggestion = async (s) => {
    searchForm.value.origin = s.label;
    originSuggestions.value = [];
    const meta = await resolveSuggestionMeta(s.label, s.raw);
    if (meta) {
        searchForm.value._originMeta = {
            ...meta,
            placeId: null,
            fullAddress: meta.address || null
        };
    }
};

const applyDestinationSuggestion = async (s) => {
    searchForm.value.destination = s.label;
    destinationSuggestions.value = [];
    const meta = await resolveSuggestionMeta(s.label, s.raw);
    if (meta) {
        searchForm.value._destinationMeta = {
            ...meta,
            placeId: null,
            fullAddress: meta.address || null
        };
    }
};

const applyPickupSuggestion = async (s) => {
    pickupPoint.value = s.label;
    pickupSuggestions.value = [];
    const meta = await resolveSuggestionMeta(s.label, s.raw);
    if (meta) {
        pickupData.value = {
            lat: meta.lat,
            lng: meta.lng,
            placeId: null,
            address: meta.address || null,
            name: meta.name || null
        };
    }
};

const applyDropoffSuggestion = async (s) => {
    dropoffPoint.value = s.label;
    dropoffSuggestions.value = [];
    const meta = await resolveSuggestionMeta(s.label, s.raw);
    if (meta) {
        dropoffData.value = {
            lat: meta.lat,
            lng: meta.lng,
            placeId: null,
            address: meta.address || null,
            name: meta.name || null
        };
    }
};

async function ensureLatLng(field /* 'origin' | 'destination' */) {
    const metaKey = field === 'origin' ? '_originMeta' : '_destinationMeta'
    const meta = searchForm.value[metaKey]
    if (meta?.lat && meta?.lng) return { lat: meta.lat, lng: meta.lng }

    const text = searchForm.value[field]
    if (!text) return { lat: null, lng: null }

    const g = await geocodeText(text) // มีอยู่แล้วในไฟล์
    if (g?.lat && g?.lng) {
        searchForm.value[metaKey] = {
            ...(meta || {}),
            lat: g.lat,
            lng: g.lng,
            placeId: g.placeId || null,
            fullAddress: g.address || null
        }
        return { lat: g.lat, lng: g.lng }
    }
    return { lat: null, lng: null }
}

async function handleSearch() {
    isLoading.value = true
    selectedRoute.value = null

    try {
        const q = { page: 1, limit: 20 }

        // --- วันที่ (optional) ---
        if (searchForm.value.date) {
            const d = dayjs(searchForm.value.date)
            q.dateFrom = d.startOf('day').toISOString()
            q.dateTo = d.endOf('day').toISOString()
        }
        if (searchForm.value.seats) {
            q.seatsRequired = Number(searchForm.value.seats)
        }
        // --- จุดเริ่มต้น / ปลายทาง (ใส่ทีละอันได้) ---
        let usedRadius = false

        // origin (ถ้าพิมพ์หรือปักหมุดไว้)
        if (searchForm.value.origin || searchForm.value._originMeta?.lat) {
            const { lat: startLat, lng: startLng } = await ensureLatLng('origin')
            if (startLat != null && startLng != null) {
                q.startNearLat = startLat
                q.startNearLng = startLng
                usedRadius = true
            }
        }

        // destination (ถ้าพิมพ์หรือปักหมุดไว้)
        if (searchForm.value.destination || searchForm.value._destinationMeta?.lat) {
            const { lat: endLat, lng: endLng } = await ensureLatLng('destination')
            if (endLat != null && endLng != null) {
                q.endNearLat = endLat
                q.endNearLng = endLng
                usedRadius = true
            }
        }

        // ใช้ radiusMeters ก็ต่อเมื่อมีตัวกรองพิกัดอย่างน้อยหนึ่งฝั่ง
        if (usedRadius) q.radiusMeters = RADIUS_METERS

        // 🔎 ถ้าไม่ใส่ตัวกรองอะไรเลย จะเรียก /routes ปกติ (q มีแค่ page/limit)
        const apiRes = await $api('/routes', { query: q })

        const raw = (apiRes?.data || apiRes || []).filter(r => r.status === 'AVAILABLE')

        // ----- ด้านล่างเหมือนเดิม (map ข้อมูล) -----
        routes.value = raw.map(route => {
            const wp = route.waypoints || {}
            const baseList = (Array.isArray(wp.used) && wp.used.length ? wp.used
                : Array.isArray(wp.requested) ? wp.requested : [])
            const orderedList = (Array.isArray(wp.optimizedOrder) && wp.optimizedOrder.length === baseList.length)
                ? wp.optimizedOrder.map(i => baseList[i]) : baseList

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
                    : null
                ).filter(Boolean)

            return {
                id: route.id,
                availableSeats: route.availableSeats,
                price: route.pricePerSeat,
                departureTime: dayjs(route.departureTime).format('HH:mm น.'),
                date: dayjs(route.departureTime).format('D MMMM BBBB'),
                start: route.startLocation,
                end: route.endLocation,
                originName: route.startLocation?.name || `(${route.startLocation.lat.toFixed(2)}, ${route.startLocation.lng.toFixed(2)})`,
                destinationName: route.endLocation?.name || `(${route.endLocation.lat.toFixed(2)}, ${route.endLocation.lng.toFixed(2)})`,
                originAddress: route.startLocation?.address ? cleanAddr(route.startLocation.address) : null,
                destinationAddress: route.endLocation?.address ? cleanAddr(route.endLocation.address) : null,
                allowExtraLuggage: !!route.allowExtraLuggage,
                maxExtraLuggageType: route.maxExtraLuggageType || null,
                driver: {
                    name: `${route.driver?.firstName || ''} ${route.driver?.lastName || ''}`.trim() || 'ไม่ระบุชื่อ',
                    image: route.driver?.profilePicture || `https://ui-avatars.com/api/?name=${encodeURIComponent(route.driver?.firstName || 'U')}&background=random&size=64`,
                    rating: 4.5,
                    reviews: Math.floor(Math.random() * 50) + 5,
                    isVerified: !!route.driver?.isVerified
                },
                carDetails: route.vehicle
                    ? [`${route.vehicle.vehicleModel} (${route.vehicle.vehicleType})`, ...(route.vehicle.amenities || [])]
                    : ['ไม่มีข้อมูลรถ'],
                conditions: route.conditions,
                photos: route.vehicle?.photos || [],
                durationText: formatDuration(route.duration) || route.duration || '-',
                distanceText: formatDistance(route.distance) || route.distance || '-',
                polyline: route.routePolyline || null,
                routePath: route.landmarks?.routePath || route.routePath || null,
                stops,
                stopsCoords,
            }
        })

        await waitMapReady()
        const jobs = routes.value.map(async (r, i) => {
            const [o, d] = await Promise.all([
                reverseGeocode(r.start.lat, r.start.lng),
                reverseGeocode(r.end.lat, r.end.lng)
            ])
            if (!r.start?.name && o?.name) routes.value[i].originName = o.name
            if (!r.end?.name && d?.name) routes.value[i].destinationName = d.name
            if (!r.start?.address && o?.address) routes.value[i].originAddress = cleanAddr(o.address)
            if (!r.end?.address && d?.address) routes.value[i].destinationAddress = cleanAddr(d.address)
        })
        await Promise.allSettled(jobs)

    } catch (e) {
        console.error('Failed to fetch routes:', e)
        routes.value = []
    } finally {
        isLoading.value = false
    }
}


const toggleDetails = (route) => {
    if (selectedRoute.value && selectedRoute.value.id === route.id) {
        selectedRoute.value = null
        clearMapDrawing()
    } else {
        selectedRoute.value = route
        updateMapForRoute(route)
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

const addOverlay = (overlay) => {
    if (!gmap || !overlay) return;
    gmap.Overlays.add(overlay);
    mapOverlays.push(overlay);
};

function clearMapDrawing() {
    if (!gmap) return;
    if (mapOverlays.length) {
        mapOverlays.forEach((o) => {
            try { gmap.Overlays.remove(o); } catch { }
        });
    }
    mapOverlays = [];
    activePolyline = null;
    startMarker = null;
    endMarker = null;
    stopMarkers = [];
}

function decodePolyline(str, precision = 5) {
    if (!str) return [];
    let index = 0;
    let lat = 0;
    let lng = 0;
    const coordinates = [];
    const factor = Math.pow(10, precision);
    while (index < str.length) {
        let b;
        let shift = 0;
        let result = 0;
        do {
            b = str.charCodeAt(index++) - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        const deltaLat = (result & 1) ? ~(result >> 1) : (result >> 1);
        lat += deltaLat;

        shift = 0;
        result = 0;
        do {
            b = str.charCodeAt(index++) - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        const deltaLng = (result & 1) ? ~(result >> 1) : (result >> 1);
        lng += deltaLng;

        coordinates.push({ lat: lat / factor, lng: lng / factor });
    }
    return coordinates;
}

const fitMapToPoints = (points) => {
    if (!gmap || !points?.length) return;
    const lats = points.map(p => p.lat).filter((v) => typeof v === 'number');
    const lngs = points.map(p => p.lng).filter((v) => typeof v === 'number');
    if (!lats.length || !lngs.length) return;
    const minLat = Math.min(...lats);
    const maxLat = Math.max(...lats);
    const minLon = Math.min(...lngs);
    const maxLon = Math.max(...lngs);
    const center = { lat: (minLat + maxLat) / 2, lon: (minLon + maxLon) / 2 };
    gmap.location(center);

    if (typeof gmap.bound === 'function') {
        try {
            gmap.bound({ minLat, minLon, maxLat, maxLon });
            return;
        } catch { }
    }

    const span = Math.max(Math.abs(maxLat - minLat), Math.abs(maxLon - minLon));
    let zoom = 12;
    if (span > 20) zoom = 5;
    else if (span > 10) zoom = 6;
    else if (span > 5) zoom = 7;
    else if (span > 2) zoom = 8;
    else if (span > 1) zoom = 9;
    else if (span > 0.5) zoom = 10;
    else if (span > 0.2) zoom = 11;
    gmap.zoom(zoom);
};

async function updateMapForRoute(route) {
    if (!route) return;
    await waitMapReady();
    if (!gmap || !window.longdo) return;

    clearMapDrawing();

    const points = [];

    if (route.start?.lat != null && route.start?.lng != null) {
        startMarker = new longdo.Marker(
            { lon: route.start.lng, lat: route.start.lat },
            { title: 'จุดเริ่มต้น' }
        );
        addOverlay(startMarker);
        points.push({ lat: route.start.lat, lng: route.start.lng });
    }

    if (route.end?.lat != null && route.end?.lng != null) {
        endMarker = new longdo.Marker(
            { lon: route.end.lng, lat: route.end.lat },
            { title: 'จุดปลายทาง' }
        );
        addOverlay(endMarker);
        points.push({ lat: route.end.lat, lng: route.end.lng });
    }

    if (Array.isArray(route.stopsCoords) && route.stopsCoords.length) {
        stopMarkers = route.stopsCoords.map((s, idx) => {
            const marker = new longdo.Marker(
                { lon: s.lng, lat: s.lat },
                { title: s.name || s.address || `จุดแวะ ${idx + 1}` }
            );
            addOverlay(marker);
            points.push({ lat: s.lat, lng: s.lng });
            return marker;
        });
    }

    let path = [];
    if (Array.isArray(route.routePath) && route.routePath.length) {
        path = route.routePath.map(coerceLatLng).filter(Boolean);
    } else if (route.polyline) {
        path = decodePolyline(route.polyline);
    }

    if (path.length > 1) {
        const line = new longdo.Polyline(
            path.map(p => ({ lon: p.lng, lat: p.lat })),
            { lineWidth: 5, lineColor: '#2563eb', lineOpacity: 0.9 }
        );
        activePolyline = line;
        addOverlay(line);
        points.push(...path);
    }

    fitMapToPoints(points);
}

function openModal(route) {
    if (!token.value) {
        return navigateTo('/login');
    }
    if (route && route.availableSeats > 0) {
        bookingRoute.value = route
        bookingSeats.value = 1
        pickupPoint.value = ''
        dropoffPoint.value = ''
        pickupData.value = { lat: null, lng: null, placeId: null, address: null, name: null }
        dropoffData.value = { lat: null, lng: null, placeId: null, address: null, name: null }
        bookingPickingTarget.value = null
        showModal.value = true
    }

    extraLuggageSelected.value = false
    const firstAllowed = EXTRA_LUGGAGE_OPTIONS.find((opt) => {
        if (!route.maxExtraLuggageType) return opt.value === 'MEDIUM'
        return LUGGAGE_ORDER[opt.value] <= LUGGAGE_ORDER[route.maxExtraLuggageType]
    })
    extraLuggageType.value = firstAllowed?.value || 'MEDIUM'
}

function closeModal() {
    showModal.value = false
    setTimeout(() => {
        bookingRoute.value = null
    }, 300);
}

async function confirmBooking() {
    if (!bookingRoute.value) return;

    // ถ้าผู้ใช้พิมพ์เองแต่ยังไม่มีพิกัด ให้ geocode จากข้อความ
    if (pickupPoint.value && !pickupData.value.lat) {
        const g1 = await geocodeText(pickupPoint.value)
        if (g1) pickupData.value = g1
    }
    if (dropoffPoint.value && !dropoffData.value.lat) {
        const g2 = await geocodeText(dropoffPoint.value)
        if (g2) dropoffData.value = g2
    }

    if (!pickupData.value.lat || !dropoffData.value.lat) {
        toast.warning('ข้อมูลไม่ครบถ้วน', 'กรุณาเลือกจุดขึ้นรถและจุดลงรถจากรายการหรือปักหมุดบนแผนที่');
        return;
    }

    const payload = {
        routeId: bookingRoute.value.id,
        numberOfSeats: bookingSeats.value,
        pickupLocation: pickupData.value,
        dropoffLocation: dropoffData.value,
        extraLuggageSelected: Boolean(extraLuggageSelected.value && bookingRoute.value.allowExtraLuggage),
        extraLuggageType:
            extraLuggageSelected.value && bookingRoute.value.allowExtraLuggage
                ? extraLuggageType.value
                : null,

    };

    try {
        await $api('/bookings', { method: 'POST', body: payload });
        closeModal();
        toast.success('ส่งคำขอจองสำเร็จ!', 'คำขอของคุณถูกส่งไปให้ผู้ขับแล้ว โปรดรอการยืนยัน');
        setTimeout(() => navigateTo('/myTrip'), 1500);
    } catch (error) {
        console.error("Failed to create booking:", error);
        toast.error('เกิดข้อผิดพลาดในการจอง', error.data?.message || 'โปรดลองใหม่อีกครั้งในภายหลัง');
    }
}

const initializeMap = () => {
    if (!mapContainer.value || gmap) return;
    if (!window.longdo) return;
    gmap = new longdo.Map({ placeholder: mapContainer.value });
    gmap.location({ lon: 100.5018, lat: 13.7563 });
    gmap.zoom(6);
    mapReady.value = true;
};

async function openPlacePicker(field) {
    pickingField.value = field // 'origin' | 'destination'
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
        const fallbackCenter = { lat: 13.7563, lng: 100.5018 } // กรุงเทพฯ
        const meta = field === 'origin' ? searchForm.value._originMeta : searchForm.value._destinationMeta
        const center = (meta?.lat && meta?.lng) ? { lat: meta.lat, lng: meta.lng } : fallbackCenter

        placePickerMap = new longdo.Map({ placeholder: placePickerMapEl.value })
        placePickerMap.location({ lon: center.lng, lat: center.lat })
        placePickerMap.zoom(meta?.lat ? 14 : 6)

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
    pickedPlace.value = { name: display, lat, lng }
}

function applyPickedPlace() {
    if (!pickingField.value || !pickedPlace.value.name) return
    if (pickingField.value === 'origin') {
        searchForm.value.origin = pickedPlace.value.name
        searchForm.value._originMeta = {
            placeId: null, fullAddress: null,
            lat: pickedPlace.value.lat, lng: pickedPlace.value.lng
        }
    } else if (pickingField.value === 'destination') {
        searchForm.value.destination = pickedPlace.value.name
        searchForm.value._destinationMeta = {
            placeId: null, fullAddress: null,
            lat: pickedPlace.value.lat, lng: pickedPlace.value.lng
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

async function startBookingPicker(target) {
    bookingPickingTarget.value = target // 'pickup' | 'dropoff'
    bookingPicked.value = { name: '', lat: null, lng: null, placeId: null, address: null }

    try {
        await loadLongdoMap()
    } catch (e) {
        console.error(e)
        toast.error('ไม่สามารถโหลดแผนที่ได้', 'กรุณาตรวจสอบคีย์ Longdo Map')
        return
    }

    nextTick(() => {
        const fallbackCenter = { lat: 13.7563, lng: 100.5018 }
        const base = target === 'pickup' ? pickupData.value : dropoffData.value
        const center = (base.lat && base.lng) ? { lat: base.lat, lng: base.lng } : fallbackCenter

        bookingPickerMap = new longdo.Map({ placeholder: bookingPickerMapEl.value })
        bookingPickerMap.location({ lon: center.lng, lat: center.lat })
        bookingPickerMap.zoom(base.lat ? 15 : 6)

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
    const name = info?.name || `${lat.toFixed(5)}, ${lng.toFixed(5)}`
    const address = info?.address || name
    bookingPicked.value = { name, lat, lng, placeId: null, address }
}
function applyBookingPicked() {
    if (!bookingPickingTarget.value || !bookingPicked.value.name) return
    const data = {
        lat: bookingPicked.value.lat,
        lng: bookingPicked.value.lng,
        placeId: bookingPicked.value.placeId,
        address: bookingPicked.value.address,
        name: bookingPicked.value.name
    }
    if (bookingPickingTarget.value === 'pickup') {
        pickupPoint.value = data.name || data.address || ''
        pickupData.value = data
    } else {
        dropoffPoint.value = data.name || data.address || ''
        dropoffData.value = data
    }
    stopBookingPicker()
}

async function geocodeText(text) {
    if (!text) return null
    const s = await searchKeyword(text)
    if (s && s.lat != null && s.lng != null) {
        return { ...s, placeId: null }
    }
    const g = await geocodeAddress(text)
    if (g && g.lat != null && g.lng != null) {
        return { ...g, placeId: null }
    }
    return null
}

function resetSearch() {
    // ล้างค่าฟิลเตอร์ทั้งหมด
    searchForm.value.origin = ''
    searchForm.value.destination = ''
    searchForm.value.date = ''
    searchForm.value.seats = ''
    originSuggestions.value = []
    destinationSuggestions.value = []
    originFocused.value = false
    destinationFocused.value = false
    // ล้างเมตาพิกัดที่เก็บไว้จาก autocomplete / picker
    delete searchForm.value._originMeta
    delete searchForm.value._destinationMeta

    selectedRoute.value = null
    // ดึงรายการทั้งหมด (API ปกติ)
    handleSearch()
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

onMounted(async () => {
    try {
        await loadLongdoMap()
    } catch (e) {
        console.error(e)
        toast.error('ไม่สามารถโหลดแผนที่ได้', 'กรุณาตรวจสอบคีย์ Longdo Map')
        return
    }
    initializeMap()
    handleSearch()
})
</script>

<style scoped>
body,
* {
    font-family: 'Kanit', sans-serif;
}

.route-card:hover {
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
    transform: translateY(-2px);
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

.modal-overlay {
    position: fixed;
    z-index: 1000;
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
    background-color: white;
    border-radius: 0.75rem;
    max-width: 600px;
    width: 95%;
    max-height: 90vh;
    overflow-y: auto;
    box-shadow: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);
}

.modal-fade-enter-active,
.modal-fade-leave-active {
    transition: opacity 0.3s cubic-bezier(0.52, 0.02, 0.19, 1.02);
}

.modal-fade-enter-active .modal-content,
.modal-fade-leave-active .modal-content {
    transition: all 0.3s cubic-bezier(0.52, 0.02, 0.19, 1.02);
}

.modal-fade-enter-from,
.modal-fade-leave-to {
    opacity: 0;
}

.modal-fade-enter-from .modal-content,
.modal-fade-leave-to .modal-content {
    transform: scale(0.9) translateY(1rem);
}

.suggest-list {
    position: absolute;
    z-index: 60;
    width: 100%;
    margin-top: 4px;
    background: #fff;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    box-shadow: 0 6px 16px rgba(0, 0, 0, 0.08);
    max-height: 220px;
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
