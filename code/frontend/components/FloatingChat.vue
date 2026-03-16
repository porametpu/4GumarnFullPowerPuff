<template>
  <div v-if="isWidgetOpen" class="fixed bottom-4 right-4 z-50 flex flex-col shadow-2xl rounded-2xl overflow-hidden border border-gray-200 bg-white transition-all duration-300"
       :class="isWidgetMinimized ? 'w-auto h-auto' : 'w-[400px] h-[600px] max-w-[calc(100vw-2rem)] max-h-[calc(100vh-2rem)]'">
    
    <!-- Minimized State -->
    <div v-if="isWidgetMinimized" @click="maximizeChat" class="px-4 py-3 bg-blue-600 text-white cursor-pointer flex items-center justify-between space-x-6 hover:bg-blue-700 transition-colors shadow-lg">
      <div class="flex items-center space-x-2">
        <div class="relative">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path></svg>
          <div v-if="totalUnreadCount > 0" class="absolute -top-1.5 -right-1.5 bg-red-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full border-2 border-blue-600 animate-bounce">
            {{ totalUnreadCount > 99 ? '99+' : totalUnreadCount }}
          </div>
        </div>
        <div class="flex flex-col">
          <span class="font-medium text-sm">แชทกับ {{ otherParticipantName !== 'กำลังโหลด...' ? otherParticipantName : 'ผู้เดินทาง' }}</span>
        </div>
      </div>
      <button @click.stop="closeChat" class="p-1 hover:bg-white/20 rounded-full transition-colors flex-shrink-0">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
      </button>
    </div>

    <!-- Maximized State -->
    <template v-else>
      <!-- Header -->
      <header @click="minimizeChat" class="bg-blue-600 px-4 py-3 flex items-center justify-between text-white shadow-sm shrink-0 z-10 cursor-pointer hover:bg-blue-700 transition-colors">
        <div class="flex items-center space-x-3">
          <div>
            <h1 class="text-base font-semibold line-clamp-1">แชทกับ {{ otherParticipantName }}</h1>
            <p class="text-[11px] text-blue-100 line-clamp-1 truncate" v-if="bookingDetails">
              {{ bookingDetails.route?.startLocation?.name || 'จุดเริ่มต้น' }} → {{ bookingDetails.route?.endLocation?.name || 'ปลายทาง' }}
            </p>
          </div>
        </div>
        <div class="flex items-center space-x-1 shrink-0">
          <button class="p-1.5 text-blue-100 hover:text-white hover:bg-white/20 rounded-lg transition-colors" title="ย่อหน้าต่าง">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          </button>
          <button @click.stop="closeChat" class="p-1.5 text-blue-100 hover:text-white hover:bg-white/20 rounded-lg transition-colors" title="ปิดหน้าต่าง">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>
        </div>
      </header>

      <!-- Message Area -->
      <main class="flex-1 overflow-y-auto p-4 space-y-4 bg-gray-50 relative" ref="messagesContainer">
        <div v-if="isLoading" class="flex justify-center py-8">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        </div>
        <div v-else-if="messages.length === 0" class="text-center text-gray-500 py-8">
          <div class="bg-blue-50 text-blue-800 p-3 rounded-lg inline-block text-[13px]">
            ยังไม่มีข้อความ เริ่มต้นทักทายเลย! 👋
          </div>
        </div>

        <template v-else>
          <!-- Messages List -->
          <div v-for="msg in messages" :key="msg.id" class="flex items-end space-x-2 group" :class="msg.isMine ? 'justify-end' : 'justify-start'">
            
            <!-- Avatar -->
            <img v-if="!msg.isMine" :src="msg.senderAvatar || `https://ui-avatars.com/api/?name=${encodeURIComponent(msg.senderDisplayName)}&background=random`" alt="Avatar" class="w-7 h-7 rounded-full object-cover shadow-sm flex-shrink-0" />

            <div class="max-w-[75%] sm:max-w-[80%] flex flex-col space-y-1 relative">
              <!-- Name & Time -->
              <div class="flex items-center space-x-2 text-[10px] text-gray-500" :class="msg.isMine ? 'justify-end' : 'justify-start'">
                <span v-if="!msg.isMine" class="font-medium text-gray-700">{{ msg.senderDisplayName }}</span>
                <span>{{ formatTime(msg.createdAt) }}</span>
                <!-- Read Status Indicator -->
                <div v-if="msg.isMine" class="flex items-center ml-1">
                   <svg v-if="msg.isRead" class="w-3 h-3 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7M5 13l4 4L19 7" />
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" class="translate-x-0.5" />
                   </svg>
                   <svg v-else class="w-3 h-3 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                   </svg>
                </div>
              </div>
              <div class="px-3 py-2 shadow-sm" :class="getBubbleClass(msg)">
                <!-- Deleted Message Placeholder -->
                <div v-if="msg.isDeleted" class="flex items-center space-x-2 py-0.5">
                  <svg class="w-3.5 h-3.5 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                  <p class="text-[13px]">{{ msg.content || 'ข้อความนี้ถูกลบแล้ว' }}</p>
                </div>

                <template v-else>
                  <!-- TEXT -->
                  <p v-if="msg.type === 'TEXT'" class="text-[14px] whitespace-pre-wrap break-words leading-relaxed">{{ msg.content }}</p>

                  <!-- IMAGE  -->
                  <div v-else-if="msg.type === 'IMAGE'" class="relative group cursor-pointer" @click="openImage(msg.content)">
                    <img :src="msg.content" alt="Image" class="rounded-md max-h-48 object-cover w-full bg-white" loading="lazy" />
                    <div class="absolute inset-0 bg-black/opacity-0 group-hover:bg-black/10 transition-colors rounded-md"></div>
                  </div>

                  <!-- LOCATION -->
                  <div v-else-if="msg.type === 'LOCATION'" class="flex flex-col space-y-2">
                    <div class="flex items-center space-x-2 pb-2 border-b" :class="msg.isMine ? 'border-blue-500/30' : 'border-gray-200'">
                      <svg class="w-4 h-4 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                      </svg>
                      <span class="font-medium text-[13px]">ส่งตำแหน่งที่ตั้ง</span>
                    </div>
                    <p class="text-[13px] truncate max-w-full">{{ parseLocationName(msg.content) || 'ตำแหน่งถูกแชร์' }}</p>
                    <a :href="getLocationUrl(msg.content)" target="_blank" rel="noopener noreferrer" 
                       class="mt-1 inline-block text-[12px] font-medium hover:underline flex items-center gap-1"
                       :class="msg.isMine ? 'text-blue-100 hover:text-white' : 'text-blue-600'">
                       ดูบนแผนที่ 
                       <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path></svg>
                    </a>
                  </div>
                  
                  <!-- SYSTEM Type -->
                   <div v-else-if="msg.type === 'SYSTEM'" class="text-center italic text-[12px] opacity-90">
                    {{ msg.content }}
                   </div>
                </template>
              </div>
                <!-- Delete Button (Hover) -->
                 <button 
                    v-if="msg.isMine && !msg.isDeleted" 
                    @click.stop="deleteMessageLocal(msg.id)"
                    class="absolute -left-7 top-1/2 -translate-y-1/2 p-1 text-gray-300 hover:text-red-500 opacity-0 group-hover:opacity-100 transition-all focus:outline-none hover:bg-white rounded-full shadow-sm border border-gray-100"
                    title="ลบข้อความ"
                  >
                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                    </svg>
                 </button>
            </div>
            <!-- Avatar (Me) -->
            <img v-if="msg.isMine" :src="msg.senderAvatar || `https://ui-avatars.com/api/?name=${encodeURIComponent(msg.senderDisplayName)}&background=random`" alt="Avatar" class="w-7 h-7 rounded-full object-cover shadow-sm flex-shrink-0" />
          </div>
        </template>
        
        <!-- Sensitive Info Warning -->
        <div v-if="showSecurityWarning" class="p-3 bg-amber-50 border border-amber-200 rounded-xl flex items-start space-x-3 shadow-sm animate-in fade-in slide-in-from-bottom-2 duration-300 mt-4">
          <div class="bg-amber-100 p-1.5 rounded-full text-amber-600 flex-shrink-0">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
            </svg>
          </div>
          <div class="flex-1">
            <p class="text-[12px] text-amber-800 font-bold leading-tight">⚠️ โปรดระวังการส่งข้อมูลส่วนตัว</p>
            <p class="text-[11px] text-amber-700 mt-1 leading-relaxed">
              การแชร์ชื่อ-นามสกุล, ที่อยู่, เบอร์โทรศัพท์ ซึ่งขัดต่อแนวทางและนโยบายของเว็บไซต์ มีความเสี่ยงต่อความปลอดภัย โปรดตรวจสอบให้มั่นใจก่อนส่งข้อมูล
            </p>
          </div>
        </div>
      </main>

      <!-- Attachment Menu (Overlay) -->
      <transition name="slide-up">
        <div v-if="showAttachmentMenu" class="absolute bottom-[calc(60px+1rem)] left-4 bg-white p-2 rounded-xl shadow-xl border z-20 flex space-x-2 w-[220px]">
          <button @click="triggerImageUpload" class="flex-1 flex flex-col items-center justify-center p-2 hover:bg-gray-50 rounded-lg transition-colors group">
            <div class="w-10 h-10 bg-purple-100 text-purple-600 rounded-full flex items-center justify-center mb-1 group-hover:bg-purple-200 transition-colors">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
            </div>
            <span class="text-[11px] font-medium text-gray-700">รูปภาพ</span>
          </button>
          <button @click="confirmSendLocation" class="flex-1 flex flex-col items-center justify-center p-2 hover:bg-gray-50 rounded-lg transition-colors group" :disabled="isSendingLocation">
            <div class="w-10 h-10 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mb-1 group-hover:bg-emerald-200 transition-colors">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
            </div>
            <span class="text-[11px] font-medium text-gray-700">ตำแหน่งที่ตั้ง</span>
          </button>
        </div>
      </transition>
      
      <!-- Hidden File Input -->
      <input type="file" ref="fileInput" class="hidden" accept="image/*" @change="handleImageSelected" />

      <!-- Backdrop -->
      <div v-if="showAttachmentMenu" class="absolute inset-0 z-10 bg-black/5" @click="showAttachmentMenu = false"></div>

      <!-- Quick Replies -->
      <div v-if="quickReplies.length > 0" class="bg-slate-50 border-t px-3 py-2 w-full overflow-x-auto whitespace-nowrap hide-scroll z-20 shrink-0">
        <div class="flex space-x-2">
          <button 
            v-for="(reply, idx) in quickReplies" 
            :key="idx"
            @click="sendQuickReply(reply)"
            class="px-3 py-1 bg-white border border-gray-200 text-gray-700 text-[12px] rounded-full shadow-sm hover:bg-blue-50 hover:border-blue-200 hover:text-blue-700 transition-colors flex-shrink-0 focus:outline-none"
          >
            {{ reply }}
          </button>
        </div>
      </div>

      <footer class="bg-white px-3 py-3 border-t z-20 shrink-0">
        <div v-if="isUploadingImage || isSendingLocation" class="text-[11px] text-blue-600 mb-1 pl-2 animate-pulse">
          กำลังส่ง{{ isUploadingImage ? 'รูปภาพ' : 'ตำแหน่งที่ตั้ง' }}...
        </div>
        <div class="flex items-end gap-2 w-full">
          <button @click="showAttachmentMenu = !showAttachmentMenu" class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded-full transition-colors focus:outline-none flex-shrink-0">
            <svg class="w-5 h-5" :class="{'rotate-45': showAttachmentMenu}" style="transition: transform 0.2s;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
            </svg>
          </button>
          <div class="flex-1 bg-gray-100 rounded-2xl flex items-center border border-transparent focus-within:border-blue-300 focus-within:bg-white transition-colors overflow-hidden">
            <textarea 
              v-model="newMessage" 
              @keydown="handleKeydown"
              rows="1"
              placeholder="พิมพ์ข้อความ..." 
              class="w-full bg-transparent px-3 py-2 focus:outline-none resize-none max-h-24 text-[14px] leading-relaxed"
              :disabled="isSending"
              ref="messageInput"
              @input="adjustTextareaHeight"
            ></textarea>
          </div>
          <button 
            @click="sendMessage" 
            :disabled="!newMessage.trim() || isSending"
            class="p-2.5 bg-blue-600 text-white rounded-full hover:bg-blue-700 disabled:bg-gray-300 disabled:text-gray-500 transition-colors flex items-center justify-center flex-shrink-0 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
          >
            <svg class="w-4 h-4 translate-x-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path>
            </svg>
          </button>
        </div>
      </footer>
    </template>
    
    <!-- Image View Modal (Full Screen) -->
    <div v-if="viewingImage" class="fixed inset-0 z-[60] bg-black flex items-center justify-center p-4">
      <button @click="viewingImage = null" class="absolute top-4 right-4 p-2 text-white bg-black/50 hover:bg-black/80 rounded-full transition-colors z-50">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
      </button>
      <img :src="viewingImage" class="max-w-full max-h-full object-contain" />
    </div>

    <!-- Location Warning Modal -->
    <ConfirmModal 
      :show="showLocationWarning" 
      title="ยืนยันการแชร์ตำแหน่งที่ตั้ง" 
      message="การแชร์ตำแหน่งปัจจุบันของคุณอาจเป็นการเปิดเผยข้อมูลส่วนตัว คุณแน่ใจหรือไม่ว่าต้องการแชร์ตำแหน่งนี้ให้คู่สนทนาทราบ?" 
      confirmText="ยืนยันแชร์ตำแหน่ง" 
      cancelText="ยกเลิก"
      variant="primary" 
      @confirm="executeSendLocation" 
      @cancel="showLocationWarning = false" 
    />
  </div>
</template>

<script setup>
import { ref, watch, nextTick, onMounted, onUnmounted, computed } from 'vue'
import dayjs from 'dayjs'
import { useToast } from '~/composables/useToast'
import { useSocket } from '~/composables/useSocket'
import ConfirmModal from '~/components/ConfirmModal.vue'
import { useChatWidget } from '~/composables/useChatWidget'

const { $api } = useNuxtApp()
const { toast } = useToast()
const { isWidgetOpen, isWidgetMinimized, activeBookingId, totalUnreadCount, minimizeChat, maximizeChat, closeChat, refreshUnreadCount, markRoomAsRead } = useChatWidget()

const isLoading = ref(true)
const isSending = ref(false)
const showAttachmentMenu = ref(false)
const isUploadingImage = ref(false)
const isSendingLocation = ref(false)
const showLocationWarning = ref(false)

const messages = ref([])
const newMessage = ref('')
const messagesContainer = ref(null)
const messageInput = ref(null)
const fileInput = ref(null)

const chatRoomId = ref(null)
const bookingDetails = ref(null)
const otherParticipantName = ref('กำลังโหลด...')
const viewingImage = ref(null)
const resetState = () => {
    messages.value = []
    chatRoomId.value = null
    bookingDetails.value = null
    otherParticipantName.value = 'กำลังโหลด...'
    isLoading.value = true
    showAttachmentMenu.value = false
    isSending.value = false
}

const currentUser = ref(null)
const { socket, joinRoom } = useSocket()

const quickReplies = computed(() => {
  if (!bookingDetails.value || !currentUser.value) return []
  
  const isDriver = bookingDetails.value.route?.driverId === currentUser.value.id
  
  if (isDriver) {
    return [
      "ใกล้ถึงแล้ว",
      "ถึงจุดรับแล้ว",
      "รอสักครู่นะ",
      "กำลังหาที่จอด",
      "รถติดนิดหน่อย"
    ]
  } else {
    return [
      "รออยู่ที่จุดนัดพบ",
      "ใกล้ถึงหรือยัง?",
      "กำลังเดินไป",
      "ถึงแล้วบอกด้วยนะ",
      "ขอบคุณนะ🙏"
    ]
  }
})

const sensitiveKeywords = [
  'เบอร์', 'โทร', '08', '06', '09', 'ที่อยู่', 'บ้านเลขที่', 'เลขบัตร', 'บัตรประชาชน',
  'ชื่อจริง', 'นามสกุล', 'ชื่อ-นามสกุล', 'ไลน์', 'line', 'add' , 'ซอย' , 'หมู่' , 'ตำบล' , 'อำเภอ' , 'จังหวัด' , 'รหัสไปรษณีย์' , 'เลขที่','ถนน','ชื่อ','นามสกุล','ตำแหน่ง','ที่ตั้ง'
]

const showSecurityWarning = computed(() => {
  if (messages.value.length === 0) return false
  const lastMsg = messages.value[messages.value.length - 1]
  
  // Always show warning for locations
  if (lastMsg.type === 'LOCATION') return true
  
  if (lastMsg.type !== 'TEXT') return false
  
  const content = lastMsg.content.toLowerCase()
  return sensitiveKeywords.some(keyword => content.includes(keyword))
})

watch(showSecurityWarning, (newVal) => {
  if (newVal) {
    scrollToBottom()
  }
})

watch(activeBookingId, (newId) => {
    if (newId) {
        resetState()
        fetchRoomDetails()
    }
}, { immediate: true })

watch(isWidgetOpen, (isOpen) => {
    if (isOpen && activeBookingId.value) {
        fetchRoomDetails()
    }
})

watch(isWidgetMinimized, (isMinimized) => {
    if (!isMinimized && chatRoomId.value) {
        markRoomAsRead(chatRoomId.value)
        scrollToBottom(true)
    }
})

watch(chatRoomId, (newRoomId) => {
    if (newRoomId) {
        joinRoom(newRoomId)
    }
})

// Socket Listeners
watch(socket, (newSocket) => {
    if (newSocket) {
        newSocket.on('new-message', (message) => {
            if (message.chatRoomId === chatRoomId.value) {
                const exists = messages.value.some(m => m.id === message.id)
                if (!exists) {
                    const meId = currentUser.value?.id
                    const enrichedMsg = {
                        ...message,
                        isMine: message.senderId === meId
                    }
                    messages.value.push(enrichedMsg)
                    scrollToBottom()
                    
                    if (!enrichedMsg.isMine) {
                        const audio = new Audio('https://assets.mixkit.co/active_storage/sfx/2358/2358-preview.mp3')
                        audio.volume = 0.3
                        audio.play().catch(() => {})
                    }

                    if (!isWidgetMinimized.value) {
                         markRoomAsRead(chatRoomId.value)
                    }
                }
            }
        })

        newSocket.on('message-deleted', ({ messageId, roomId }) => {
            if (roomId === chatRoomId.value) {
                const msg = messages.value.find(m => m.id === messageId);
                if (msg) {
                    msg.isDeleted = true;
                    msg.content = 'ข้อความนี้ถูกลบแล้ว';
                }
            }
        })

        newSocket.on('messages-read', ({ roomId, userId }) => {
            if (roomId === chatRoomId.value && userId !== currentUser.value?.id) {
                // Someone else read my messages
                messages.value = messages.value.map(msg => {
                    if (msg.senderId === currentUser.value?.id) {
                        return { ...msg, isRead: true }
                    }
                    return msg
                })
            }
        })
    }
}, { immediate: true })

const deleteMessageLocal = async (messageId) => {
  if (!confirm('ยืนยันลบข้อความนี้ใช่หรือไม่? บุคคลร่วมสนทนาของคุณจะไม่เห็นข้อความนี้อีกต่อไป')) return
  
  try {
    await $api(`/chats/messages/${messageId}`, { method: 'DELETE' })
    const msg = messages.value.find(m => m.id === messageId)
    if (msg) {
        msg.isDeleted = true
        msg.content = 'ข้อความนี้ถูกลบแล้ว'
    }
    toast.success('ลบข้อความแล้ว')
  } catch (error) {
    console.error('Failed to delete message:', error)
    toast.error('ไม่สามารถลบข้อความได้')
  }
}

const adjustTextareaHeight = () => {
    if (!messageInput.value) return;
    messageInput.value.style.height = 'auto';
    messageInput.value.style.height = `${Math.min(messageInput.value.scrollHeight, 96)}px`;
}

const handleKeydown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
    }
}

const getBubbleClass = (msg) => {
  if (msg.isDeleted) return 'bg-gray-100 text-gray-400 italic border border-gray-200 rounded-xl'
  if (msg.type === 'SYSTEM') return 'bg-transparent border border-dashed border-gray-300 text-gray-500 rounded-xl'
  if (msg.isMine) return 'bg-blue-600 text-white rounded-[1.2rem] rounded-br-[4px]'
  return 'bg-white text-gray-800 border rounded-[1.2rem] rounded-bl-[4px]'
}

const openImage = (url) => {
  viewingImage.value = url
}

const parseLocationName = (contentStr) => {
  try {
    const loc = JSON.parse(contentStr)
    return loc.name || 'ตำแหน่งบนแผนที่'
  } catch(e) {
    return 'ตำแหน่งถูกแชร์'
  }
}

const getLocationUrl = (contentStr) => {
  try {
    const loc = JSON.parse(contentStr)
    return `https://www.google.com/maps/search/?api=1&query=${loc.lat},${loc.lng}`
  } catch(e) {
    return '#'
  }
}

const formatTime = (date) => {
  return dayjs(date).format('HH:mm')
}

const scrollToBottom = async (instant = false) => {
  await nextTick()
  if (messagesContainer.value) {
    if (instant) {
      messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
    } else {
      messagesContainer.value.scrollTo({
        top: messagesContainer.value.scrollHeight,
        behavior: 'smooth'
      })
    }
  }
}

const fetchRoomDetails = async () => {
  if (!activeBookingId.value) return
  
  try {
    // Fetch Chat Room
    const room = await $api(`/chats/booking/${activeBookingId.value}`)
    chatRoomId.value = room?.id

    const meRes = await $api('/users/me')
    currentUser.value = meRes
    const other = room?.participants?.find(p => p.userId !== meRes.id)
    if (other) {
        otherParticipantName.value = other.displayName
    }
    const book = await $api(`/bookings/${activeBookingId.value}`)
    bookingDetails.value = book
    
    // Fetch Messages
    if (chatRoomId.value) {
      await fetchMessages()
    }
  } catch (error) {
    console.error('Failed to fetch chat room:', error)
    if (error.response?.status === 404) {
       toast.error('ไม่พบห้องแชท', 'อาจจะยังไม่ได้รับการยืนยันการจอง')
       closeChat()
    }
  } finally {
    isLoading.value = false
  }
}

const fetchMessages = async () => {
  if (!chatRoomId.value) return 
  try {
    const messagesArray = await $api(`/chats/${chatRoomId.value}/messages`)
    const isNew = messages.value.length !== (messagesArray || []).length
    messages.value = messagesArray || []
    
    if (isNew) {
      scrollToBottom(messages.value.length < 10)
    }
    refreshUnreadCount()
  } catch (error) {
    console.error('Failed to fetch messages:', error)
  }
}

const sendMessage = async () => {
  const content = newMessage.value.trim()
  if (!content || isSending.value || !chatRoomId.value) return
  
  try {
    isSending.value = true
    const res = await $api(`/chats/${chatRoomId.value}/messages`, {
      method: 'POST',
      body: { content, type: 'TEXT' }
    })
    const msg = res.data || res
    newMessage.value = ''
    adjustTextareaHeight()
    scrollToBottom()
  } catch (error) {
    console.error('Failed to send message:', error)
    toast.error('ส่งข้อความไม่สำเร็จ')
  } finally {
    isSending.value = false
  }
}

const sendQuickReply = async (text) => {
  if (isSending.value || !chatRoomId.value) return
  
  try {
    isSending.value = true
    const res = await $api(`/chats/${chatRoomId.value}/messages`, {
      method: 'POST',
      body: { content: text, type: 'TEXT' }
    })
    const msg = res.data || res
    scrollToBottom()
  } catch (error) {
    console.error('Failed to send quick reply:', error)
    toast.error('ส่งข้อความไม่สำเร็จ')
  } finally {
    isSending.value = false
  }
}

const triggerImageUpload = () => {
    showAttachmentMenu.value = false
    if (fileInput.value) {
        fileInput.value.click()
    }
}

const handleImageSelected = async (event) => {
    const file = event.target.files[0]
    if (!file || !chatRoomId.value) return
    if (!file.mimetype?.startsWith('image/') && !file.type.startsWith('image/')) {
        toast.error('รองรับเฉพาะไฟล์รูปภาพเท่านั้น')
        return
    }

    try {
        isUploadingImage.value = true
        showAttachmentMenu.value = false
        
        const formData = new FormData()
        formData.append('image', file)

        await $api(`/chats/${chatRoomId.value}/messages/image`, {
            method: 'POST',
            body: formData,
        })
        
        scrollToBottom()
    } catch (error) {
        console.error('Failed to send image:', error)
        toast.error('อัปโหลดรูปภาพไม่สำเร็จ')
    } finally {
        isUploadingImage.value = false
        if (fileInput.value) fileInput.value.value = '' // clear input
    }
}

const confirmSendLocation = () => {
    showAttachmentMenu.value = false
    showLocationWarning.value = true
}

const executeSendLocation = async () => {
    showLocationWarning.value = false

    if (!navigator.geolocation) {
        toast.error('เบราว์เซอร์ของคุณไม่รองรับการแชร์ตำแหน่ง')
        return
    }

    try {
        isSendingLocation.value = true
        
        navigator.geolocation.getCurrentPosition(async (position) => {
            const { latitude, longitude } = position.coords;
            const content = JSON.stringify({
                lat: latitude,
                lng: longitude,
                name: 'ตำแหน่งของฉัน'
            })

            await $api(`/chats/${chatRoomId.value}/messages`, {
                method: 'POST',
                body: { content, type: 'LOCATION' }
            })
            
            scrollToBottom()
            isSendingLocation.value = false
            toast.success('แชร์ตำแหน่งเรียบร้อยแล้ว')
        }, (err) => {
            console.error('Geolocation error:', err)
            toast.error('ไม่สามารถดึงตำแหน่งปัจจุบันได้ กรุณาเปิดการเข้าถึงตำแหน่ง')
            isSendingLocation.value = false
        })
    } catch (e) {
        console.error('Failed to send location:', e)
        isSendingLocation.value = false
        toast.error('ส่งตำแหน่งไม่สำเร็จ')
    }
}

onMounted(() => {
    refreshUnreadCount()
    const unreadPoller = setInterval(refreshUnreadCount, 30000)
    
    onUnmounted(() => {
        clearInterval(unreadPoller)
    })
})
</script>

<style scoped>
.slide-up-enter-active,
.slide-up-leave-active {
  transition: all 0.3s ease;
}
.slide-up-enter-from,
.slide-up-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

.hide-scroll::-webkit-scrollbar {
  display: none;
}
.hide-scroll {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
</style>
