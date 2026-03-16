<template>
  <div v-if="user && user.role === 'DRIVER'" class="fixed bottom-20 right-4 sm:bottom-24 sm:right-6 z-[45] flex flex-col items-end pointer-events-none">
    
    <!-- Expanded Panel -->
    <transition
      enter-active-class="transition duration-300 ease-out transform"
      enter-from-class="translate-y-4 scale-95 opacity-0"
      enter-to-class="translate-y-0 scale-100 opacity-100"
      leave-active-class="transition duration-200 ease-in transform"
      leave-from-class="translate-y-0 scale-100 opacity-100"
      leave-to-class="translate-y-4 scale-95 opacity-0"
    >
      <div v-if="isOpen" class="mb-4 w-screen max-w-[calc(100vw-2rem)] sm:w-[360px] bg-white rounded-2xl shadow-2xl border border-gray-100 overflow-hidden pointer-events-auto flex flex-col max-h-[60vh] sm:max-h-[500px]">
        
        <!-- Header -->
        <div class="bg-gradient-to-r from-blue-600 to-blue-700 px-4 py-3 flex items-center justify-between shadow-sm shrink-0">
          <div class="flex items-center space-x-2 text-white">
            <div class="bg-white/20 p-1.5 rounded-lg">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path>
                </svg>
            </div>
            <div>
                <h3 class="font-bold text-[15px] leading-tight">Driver Hub</h3>
                <p class="text-[10px] text-blue-100 opacity-80">จัดการผู้โดยสาร</p>
            </div>
          </div>
          <button @click="isOpen = false" class="text-white/80 hover:text-white transition-colors">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>
        </div>

        <!-- Content -->
        <div class="flex-1 overflow-y-auto p-3 space-y-4 bg-gray-50/50 custom-scroll">
          
          <!-- Loading State -->
          <div v-if="isLoading" class="py-12 flex flex-col items-center justify-center space-y-3">
             <div class="w-8 h-8 border-3 border-blue-600/20 border-t-blue-600 rounded-full animate-spin"></div>
             <p class="text-xs text-gray-400">กำลังโหลดเส้นทาง...</p>
          </div>

          <!-- Empty State -->
          <div v-else-if="activeRoutes.length === 0" class="py-10 text-center px-6">
            <div class="bg-blue-50 w-12 h-12 rounded-full flex items-center justify-center mx-auto mb-3 text-blue-400">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path></svg>
            </div>
            <p class="text-sm font-medium text-gray-600">ยังไม่มีเส้นทางที่กำลังจะเริ่ม</p>
            <p class="text-[11px] text-gray-400 mt-1">เส้นทางที่สร้างไว้จะปรากฏที่นี่</p>
          </div>

          <!-- Routes List -->
          <template v-else>
            <div v-for="route in activeRoutes" :key="route.id" class="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
                <!-- Route Summary -->
                <div class="px-3 py-2.5 bg-gray-50/50 flex items-center justify-between border-b border-gray-100">
                    <div class="flex items-center space-x-2 min-w-0">
                        <span class="text-[11px] font-bold text-blue-600 bg-blue-50 px-1.5 py-0.5 rounded">{{ route.timeText }}</span>
                        <div class="truncate">
                            <p class="text-[12px] font-bold text-gray-900 truncate">{{ route.origin }} → {{ route.destination }}</p>
                        </div>
                    </div>
                    <div class="flex items-center space-x-1">
                        <button @click.stop="toggleRefresh(route)" :disabled="isRefreshingGlobal" class="p-1.5 text-blue-600 hover:bg-blue-100 rounded-lg transition-colors" title="รีเฟรช">
                            <svg class="w-4 h-4" :class="{'animate-spin': isRefreshingId === route.id}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
                            </svg>
                        </button>
                        <button @click.stop="route.isExpanded = !route.isExpanded" class="p-1.5 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-all" title="ย่อ/ขยาย">
                            <svg class="w-4 h-4 transition-transform duration-300" :class="{'rotate-180': !route.isExpanded}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                            </svg>
                        </button>
                    </div>
                </div>

                <!-- Passenger List -->
                <div v-show="route.isExpanded" class="p-2 space-y-2 animate-in fade-in slide-in-from-top-2 duration-300">
                    <div v-if="!route.passengers.length" class="py-4 text-center">
                        <p class="text-[11px] text-gray-400 italic">ยังไม่มีผู้โดยสารจองเข้ามา</p>
                    </div>
                    <div v-for="p in route.passengers" :key="p.id" class="flex items-center p-2 rounded-lg bg-gray-50/50 border border-transparent hover:border-blue-100 transition-all group">
                        <!-- Avatar & Basic Info -->
                        <div class="relative shrink-0 mr-3">
                            <img :src="p.image || `https://ui-avatars.com/api/?name=${encodeURIComponent(p.name)}&background=random`" class="w-8 h-8 rounded-full object-cover border border-white shadow-sm" />
                            <div v-if="p.distance !== null" class="absolute -top-1.5 -right-1.5 px-1 bg-emerald-500 text-white text-[8px] font-bold rounded-full shadow-sm">
                                {{ p.distance.toFixed(1) }} กม.
                            </div>
                        </div>
                        <div class="flex-1 min-w-0 mr-2">
                            <p class="text-[12px] font-bold text-gray-900 truncate">{{ p.name }}</p>
                            <p class="text-[10px] text-gray-500 truncate">{{ p.pickupLocation?.name || 'จุดรับ' }}</p>
                        </div>
                        <!-- Actions -->
                        <div class="flex items-center space-x-1 shrink-0 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button @click="openChatDirectly(p.bookingId)" class="p-1.5 text-blue-600 bg-white border border-blue-50 hover:bg-blue-50 rounded-lg shadow-sm transition-colors">
                                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path></svg>
                            </button>
                            <button 
                                @click="handleNotify(route.id, p)" 
                                :disabled="p.loading || p.distance === null || p.distance > 5"
                                class="p-1.5 bg-amber-500 text-white rounded-lg shadow-sm hover:bg-amber-600 disabled:opacity-40 disabled:grayscale transition-all"
                            >
                                <svg v-if="!p.loading" class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"></path></svg>
                                <svg v-else class="w-3.5 h-3.5 animate-spin" viewBox="0 0 24 24" fill="none"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
          </template>
        </div>

        <!-- Footer Info -->
        <div class="px-4 py-2.5 bg-white border-t border-gray-100 flex items-center justify-between shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.05)] shrink-0">
            <p v-if="lastRefreshTime" class="text-[9px] text-gray-400">อัปเดตล่าสุด: {{ formatLastRef(lastRefreshTime) }}</p>
            <p v-else class="text-[9px] text-gray-400 font-medium">กดปุ่มรีเฟรชเพื่ออัปเดตระยะทาง</p>
            <NuxtLink to="/myRoute" @click="isOpen = false" class="text-[10px] font-bold text-blue-600 hover:underline flex items-center">
                ไปหน้าเส้นทาง 
                <svg class="w-2.5 h-2.5 ml-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
            </NuxtLink>
        </div>
      </div>
    </transition>

    <!-- Floating Bubble -->
    <button 
      @click="togglePanel"
      class="group relative w-14 h-14 bg-gradient-to-br from-blue-600 to-indigo-700 text-white rounded-full shadow-lg hover:shadow-2xl hover:scale-105 active:scale-95 transition-all duration-300 pointer-events-auto flex items-center justify-center focus:outline-none focus:ring-4 focus:ring-blue-100 overflow-hidden"
      aria-label="Toggle Driver Hub"
    >
      <!-- Ripple Effect Background -->
      <div class="absolute inset-0 bg-white/20 scale-0 group-hover:scale-150 rounded-full transition-transform duration-700"></div>
      
      <div class="relative">
        <svg v-if="!isOpen" class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path>
        </svg>
        <svg v-else class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
        </svg>
      </div>
    </button>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useAuth } from '~/composables/useAuth'
import { useDriverConsole } from '~/composables/useDriverConsole'
import { useChatWidget } from '~/composables/useChatWidget'
import dayjs from 'dayjs'

const { user } = useAuth()
const { activeRoutes, fetchActiveRoutes, updateDistances, notifyPassenger, lastRefreshTime } = useDriverConsole()
const { openChat } = useChatWidget()

const isOpen = ref(false)
const isLoading = ref(false)
const isRefreshingId = ref(null)
const isRefreshingGlobal = ref(false)

const confirmedPassengerCount = computed(() => {
    return activeRoutes.value.reduce((acc, r) => acc + (r.passengers?.length || 0), 0)
})

const togglePanel = async () => {
  isOpen.value = !isOpen.value
  if (isOpen.value && activeRoutes.value.length === 0) {
    isLoading.value = true
    await fetchActiveRoutes()
    isLoading.value = false
  }
}

const toggleRefresh = async (route) => {
    isRefreshingId.value = route.id
    isRefreshingGlobal.value = true
    await updateDistances(route.id)
    isRefreshingId.value = null
    isRefreshingGlobal.value = false
}

const handleNotify = async (routeId, passenger) => {
    await notifyPassenger(routeId, passenger)
}

const openChatDirectly = (bookingId) => {
    if (bookingId) {
        openChat(bookingId)
    }
}

const formatLastRef = (date) => {
    return dayjs(date).format('HH:mm:ss')
}

onMounted(() => {
    if (user.value?.role === 'DRIVER') {
        fetchActiveRoutes()
    }
})
</script>

<style scoped>
.custom-scroll::-webkit-scrollbar {
  width: 4px;
}
.custom-scroll::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scroll::-webkit-scrollbar-thumb {
  background: #e2e8f0;
  border-radius: 10px;
}
.custom-scroll::-webkit-scrollbar-thumb:hover {
  background: #cbd5e1;
}

@keyframes bounce {
  0%, 100% { transform: translateY(-25%); animation-timing-function: cubic-bezier(0.8,0,1,1); }
  50% { transform: translateY(0); animation-timing-function: cubic-bezier(0,0,0.2,1); }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: .5; }
}
</style>
