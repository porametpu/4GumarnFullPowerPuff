<template>
  <div class="px-4 py-8 mx-auto max-w-4xl sm:px-6 lg:px-8">
    <div class="mb-8">
      <h2 class="text-2xl font-bold text-gray-900">ประวัติการแชท</h2>
      <p class="mt-2 text-gray-600">คุยกับผู้ร่วมเดินทางของคุณได้จากรายการรวมนี้</p>
    </div>

    <div v-if="isLoading" class="p-12 text-center bg-white border border-gray-200 rounded-xl shadow-sm">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
      <p class="text-gray-500 font-medium">กำลังโหลดการสนทนา...</p>
    </div>

    <div v-else-if="rooms.length === 0" class="p-16 text-center bg-white border border-gray-200 rounded-xl shadow-sm">
      <div class="bg-gray-50 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6">
        <svg class="w-10 h-10 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path>
        </svg>
      </div>
      <h3 class="text-lg font-bold text-gray-900 mb-2">ยังไม่มีประวัติการแชท</h3>
      <p class="text-gray-500 max-w-sm mx-auto">เมื่อคุณมีการจองที่ได้รับการยืนยันแล้ว คุณจะสามารถกดแชทคุยกับเพื่อนร่วมเดินทางได้ที่นี่</p>
    </div>

    <div v-else class="space-y-2">
      <div 
        v-for="room in rooms" 
        :key="room.id"
        @click="openChatWindow(room.bookingId)"
        class="bg-white border border-gray-200 p-4 rounded-xl shadow-sm hover:shadow-md hover:border-blue-300 transition-all cursor-pointer flex items-center group relative overflow-hidden"
      >
        <div class="absolute left-0 top-0 bottom-0 w-1 bg-blue-600 opacity-0 group-hover:opacity-100 transition-opacity"></div>
        <div class="relative flex-shrink-0">
          <img 
            :src="`https://ui-avatars.com/api/?name=${encodeURIComponent(room.otherParticipantName)}&background=random`" 
            class="w-14 h-14 rounded-full object-cover border-2 border-white shadow-sm"
          />
          <div v-if="room.unreadCount > 0" class="absolute -top-1 -right-1 bg-red-500 text-white text-[10px] font-extrabold flex items-center justify-center min-w-[20px] h-5 px-1 rounded-full border-2 border-white shadow-sm ring-2 ring-red-500/10">
            {{ room.unreadCount > 9 ? '9+' : room.unreadCount }}
          </div>
        </div>

        <!-- รายละเอียด -->
        <div class="ml-5 flex-1 min-w-0">
          <div class="mb-2">
            <h3 class="font-bold text-gray-900 truncate pr-2">{{ room.otherParticipantName }}</h3>
          </div>
          
          <div class="flex items-center text-xs text-blue-600 font-medium mb-1 truncate bg-blue-50/50 w-fit px-2 py-0.5 rounded-md">
            <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
            </svg>
            {{ room.booking.route.startLocation?.name || 'ต้นทาง' }} → {{ room.booking.route.endLocation?.name || 'ปลายทาง' }}
          </div>
          <!-- ข้อความล่าสุด -->
          <p class="text-sm truncate" :class="room.unreadCount > 0 ? 'text-gray-900 font-semibold' : 'text-gray-500'">
            {{ getMessagePreview(room.lastMessage) }}
          </p>
        </div>
        <!-- เวลากับiconข้อความ -->
        <div class="ml-4 flex-shrink-0 flex flex-col items-end self-start pt-1">
           <span class="text-[12px] text-gray-500 font-medium whitespace-nowrap mb-2">
             {{ formatRelativeTime(room.lastMessage?.createdAt) }}
           </span>
           <div class="opacity-0 group-hover:opacity-100 transition-opacity">
              <div class="p-1 bg-blue-50 text-blue-600 rounded-full hover:bg-blue-100">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path>
                </svg>
              </div>
           </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import dayjs from 'dayjs'
import relativeTime from 'dayjs/plugin/relativeTime'
import 'dayjs/locale/th'
import { useChatWidget } from '~/composables/useChatWidget'
import { useSocket } from '~/composables/useSocket'

dayjs.extend(relativeTime)
dayjs.locale('th')

definePageMeta({ middleware: 'auth' })

const { $api } = useNuxtApp()
const { openChat, markRoomAsRead, refreshUnreadCount } = useChatWidget()
const rooms = ref([])
const isLoading = ref(true)
const { socket } = useSocket()
watch(socket, (newSocket) => {
    if (newSocket) {
        newSocket.on('message-notification', () => {
            fetchHistory()
            refreshUnreadCount()
        })
    }
}, { immediate: true })

const fetchHistory = async () => {
    try {
        isLoading.value = true
        const res = await $api('/chats/history')
        let fetchedRooms = res || []

        fetchedRooms.sort((a, b) => {
            const timeA = a.lastMessage?.createdAt ? new Date(a.lastMessage.createdAt).getTime() : 0;
            const timeB = b.lastMessage?.createdAt ? new Date(b.lastMessage.createdAt).getTime() : 0;
            return timeB - timeA;
        })
        
        rooms.value = fetchedRooms
    } catch (error) {
        console.error('Failed to fetch chat history:', error)
    } finally {
        isLoading.value = false
    }
}

const openChatWindow = (bookingId) => {
    openChat(bookingId)
    const room = rooms.value.find(r => r.bookingId === bookingId)
    if (room) {
        room.unreadCount = 0
        markRoomAsRead(room.id)
    }
}

const getMessagePreview = (message) => {
    if (!message) return 'ยังไม่มีข้อความ...'
    if (message.type === 'IMAGE') return '📸 ส่งรูปภาพ'
    if (message.type === 'LOCATION') return '📍 ส่งตำแหน่งที่ตั้ง'
    return message.content
}

const formatRelativeTime = (date) => {
    if (!date) return ''
    const d = dayjs(date)
    if (dayjs().diff(d, 'day') < 1) {
        return d.format('HH:mm')
    }
    if (dayjs().diff(d, 'day') < 7) {
        return d.fromNow(true)
    }
    return d.format('D MMM')
}

onMounted(() => {
    fetchHistory()
})
</script>

<style scoped>
.animate-in {
  animation: slideIn 0.3s ease-out;
}
@keyframes slideIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
