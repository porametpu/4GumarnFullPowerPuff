<template>
  <div class="bg-gray-200 min-h-[calc(100vh-64px)] flex justify-center w-full">
    <div class="w-full max-w-2xl bg-white flex flex-col h-[calc(100vh-64px)] shadow-2xl relative border-x border-gray-300">
      <!-- Header -->
    <header class="bg-white border-b px-4 py-3 flex items-center justify-between sticky top-0 z-10 shadow-sm">
      <div class="flex items-center space-x-3">
        <button @click="goBack" class="p-2 -ml-2 text-gray-600 hover:bg-gray-100 rounded-full transition-colors">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path>
          </svg>
        </button>
        <div>
          <h1 class="text-xl font-semibold text-gray-900 line-clamp-1">แชทกับ {{ otherParticipantName }}</h1>
          <p class="text-xs text-gray-500 line-clamp-1 truncate" v-if="bookingDetails">
            {{ bookingDetails.route?.startLocation?.name || 'จุดเริ่มต้น' }} → {{ bookingDetails.route?.endLocation?.name || 'ปลายทาง' }}
          </p>
        </div>
      </div>
    </header>

    <!-- Message Area -->
    <main class="flex-1 overflow-y-auto p-4 space-y-4" ref="messagesContainer">
      <div v-if="isLoading" class="flex justify-center py-8">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
      <div v-else-if="messages.length === 0" class="text-center text-gray-500 py-8">
        <div class="bg-blue-50 text-blue-800 p-4 rounded-lg inline-block text-sm">
          ยังไม่มีข้อความ เริ่มต้นทักทายเลย! 👋
        </div>
      </div>

      <template v-else>
        <!-- Messages List -->
        <div v-for="msg in messages" :key="msg.id" class="flex items-end space-x-2" :class="msg.isMine ? 'justify-end' : 'justify-start'">
          
          <!-- Avatar -->
          <img v-if="!msg.isMine" :src="msg.senderAvatar || `https://ui-avatars.com/api/?name=${encodeURIComponent(msg.senderDisplayName)}&background=random`" alt="Avatar" class="w-8 h-8 rounded-full object-cover shadow-sm flex-shrink-0" />

          <div class="max-w-[75%] sm:max-w-[65%] flex flex-col space-y-1">

            <div class="flex items-center space-x-2 text-[11px] text-gray-500" :class="msg.isMine ? 'justify-end' : 'justify-start'">
              <span v-if="!msg.isMine" class="font-medium text-gray-700">{{ msg.senderDisplayName }}</span>
              <span>{{ formatTime(msg.createdAt) }}</span>
            </div>
            <div class="px-4 py-2.5 shadow-sm" :class="getBubbleClass(msg)">
              
              <!-- TEXT -->
              <p v-if="msg.type === 'TEXT'" class="text-[15px] whitespace-pre-wrap break-words leading-relaxed">{{ msg.content }}</p>

              <!-- IMAGE -->
              <div v-else-if="msg.type === 'IMAGE'" class="relative group cursor-pointer" @click="openImage(msg.content)">
                <img :src="msg.content" alt="Image" class="rounded-md max-h-60 sm:max-h-80 object-cover w-full bg-white" loading="lazy" />
                <div class="absolute inset-0 bg-black/opacity-0 group-hover:bg-black/10 transition-colors rounded-md"></div>
              </div>

              <!-- LOCATION -->
              <div v-else-if="msg.type === 'LOCATION'" class="flex flex-col space-y-2">
                <div class="flex items-center space-x-2 pb-2 border-b" :class="msg.isMine ? 'border-blue-500/30' : 'border-gray-200'">
                  <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                  </svg>
                  <span class="font-medium text-[15px]">ส่งตำแหน่งที่ตั้ง</span>
                </div>
                <p class="text-[15px] truncate max-w-full">{{ parseLocationName(msg.content) || 'ตำแหน่งถูกแชร์' }}</p>
                <a :href="getLocationUrl(msg.content)" target="_blank" rel="noopener noreferrer" 
                   class="mt-1 inline-block text-sm font-medium hover:underline flex items-center gap-1"
                   :class="msg.isMine ? 'text-blue-100 hover:text-white' : 'text-blue-600'">
                   ดูบนแผนที่ 
                   <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path></svg>
                </a>
              </div>
              
              <!-- SYSTEM Type -->
               <div v-else-if="msg.type === 'SYSTEM'" class="text-center italic text-[13px] opacity-90">
                {{ msg.content }}
               </div>

            </div>
          </div>
          
          <!-- Avatar (Me) -->
          <img v-if="msg.isMine" :src="msg.senderAvatar || `https://ui-avatars.com/api/?name=${encodeURIComponent(msg.senderDisplayName)}&background=random`" alt="Avatar" class="w-8 h-8 rounded-full object-cover shadow-sm flex-shrink-0" />
        
        </div>
      </template>
    </main>

    <!-- Attachment Menu (Overlay) -->
    <transition name="slide-up">
      <div v-if="showAttachmentMenu" class="absolute bottom-[calc(64px+1rem)] left-4 bg-white p-3 rounded-xl shadow-xl border z-20 flex space-x-3 w-[240px]">
        <button @click="triggerImageUpload" class="flex-1 flex flex-col items-center justify-center p-3 hover:bg-gray-50 rounded-lg transition-colors group">
          <div class="w-12 h-12 bg-purple-100 text-purple-600 rounded-full flex items-center justify-center mb-2 group-hover:bg-purple-200 transition-colors">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
          </div>
          <span class="text-xs font-medium text-gray-700">รูปภาพ</span>
        </button>
        <button @click="confirmSendLocation" class="flex-1 flex flex-col items-center justify-center p-3 hover:bg-gray-50 rounded-lg transition-colors group" :disabled="isSendingLocation">
          <div class="w-12 h-12 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mb-2 group-hover:bg-emerald-200 transition-colors">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
          </div>
          <span class="text-xs font-medium text-gray-700">ตำแหน่งที่ตั้ง</span>
        </button>
      </div>
    </transition>

    <input type="file" ref="fileInput" class="hidden" accept="image/*" @change="handleImageSelected" />

    <!-- Backdrop -->
    <div v-if="showAttachmentMenu" class="absolute inset-0 z-10 bg-black/5" @click="showAttachmentMenu = false"></div>

    <!-- Quick Replies -->
    <div v-if="quickReplies.length > 0" class="bg-slate-50 border-t px-4 py-2 w-full overflow-x-auto whitespace-nowrap hide-scroll z-20">
      <div class="flex space-x-2">
        <button 
          v-for="(reply, idx) in quickReplies" 
          :key="idx"
          @click="sendQuickReply(reply)"
          class="px-3 py-1.5 bg-white border border-gray-200 text-gray-700 text-[13px] rounded-full shadow-sm hover:bg-blue-50 hover:border-blue-200 hover:text-blue-700 transition-colors flex-shrink-0 focus:outline-none"
        >
          {{ reply }}
        </button>
      </div>
    </div>

    <footer class="bg-white px-4 py-3 border-t z-20">
      <div v-if="isUploadingImage || isSendingLocation" class="text-xs text-blue-600 mb-2 pl-4 animate-pulse">
        กำลังส่ง{{ isUploadingImage ? 'รูปภาพ' : 'ตำแหน่งที่ตั้ง' }}...
      </div>
      <div class="flex items-end gap-2 max-w-4xl mx-auto">
        <button @click="showAttachmentMenu = !showAttachmentMenu" class="p-2.5 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded-full transition-colors focus:outline-none flex-shrink-0">
          <svg class="w-6 h-6" :class="{'rotate-45': showAttachmentMenu}" style="transition: transform 0.2s;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
          </svg>
        </button>

        <div class="flex-1 bg-gray-100 rounded-2xl flex items-center border border-transparent focus-within:border-blue-300 focus-within:bg-white transition-colors overflow-hidden">
          <textarea 
            v-model="newMessage" 
            @keydown="handleKeydown"
            rows="1"
            placeholder="พิมพ์ข้อความ..." 
            class="w-full bg-transparent px-4 py-3 focus:outline-none resize-none max-h-32 text-[15px] leading-relaxed"
            :disabled="isSending"
            ref="messageInput"
            @input="adjustTextareaHeight"
          ></textarea>
        </div>
        
        <button 
          @click="sendMessage" 
          :disabled="!newMessage.trim() || isSending"
          class="p-3 bg-blue-600 text-white rounded-full hover:bg-blue-700 disabled:bg-gray-300 disabled:text-gray-500 transition-colors flex items-center justify-center flex-shrink-0 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
          <svg class="w-5 h-5 translate-x-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path>
          </svg>
        </button>
      </div>
    </footer>
    
    <!-- Image View Modal (Full Screen) -->
    <div v-if="viewingImage" class="fixed inset-0 z-50 bg-black flex items-center justify-center p-4">
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
  </div>
</template>

<script setup>
import { ref, watch, nextTick, onMounted, onUnmounted, computed } from 'vue'
import dayjs from 'dayjs'
import { useRoute, useRouter } from 'vue-router'
import ConfirmModal from '~/components/ConfirmModal.vue'
import { useSocket } from '~/composables/useSocket'
import { useChatWidget } from '~/composables/useChatWidget'

definePageMeta({ middleware: 'auth' })

const { $api } = useNuxtApp()
const route = useRoute()
const router = useRouter()
const { toast } = useToast()

const bookingId = computed(() => route.params.bookingId)

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
const currentUser = ref(null)
const { socket, joinRoom } = useSocket()
const { refreshUnreadCount, markRoomAsRead } = useChatWidget()

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

const goBack = () => {
  router.back()
}

const adjustTextareaHeight = () => {
    if (!messageInput.value) return;
    messageInput.value.style.height = 'auto';
    messageInput.value.style.height = `${Math.min(messageInput.value.scrollHeight, 128)}px`;
}

const handleKeydown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
    }
}

const getBubbleClass = (msg) => {
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
  if (!bookingId.value) return
  
  try {
    const room = await $api(`/chats/booking/${bookingId.value}`)
    chatRoomId.value = room?.id
    
    const meRes = await $api('/users/me')
    currentUser.value = meRes
    const other = room?.participants?.find(p => p.userId !== meRes.id)
    if (other) {
        otherParticipantName.value = other.displayName
    }

    const book = await $api(`/bookings/${bookingId.value}`)
    bookingDetails.value = book
    
    if (chatRoomId.value) {
      joinRoom(chatRoomId.value)
      await fetchMessages()
    }
  } catch (error) {
    console.error('Failed to fetch chat room:', error)
    if (error.response?.status === 404) {
       toast.error('ไม่พบห้องแชท', 'อาจจะยังไม่ได้รับการยืนยันการจอง')
       setTimeout(() => router.push('/myRoute'), 2000)
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
      scrollToBottom(messages.value.length < 20)
    }
    markRoomAsRead(chatRoomId.value)
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
    if (!messages.value.some(m => m.id === msg.id)) {
        messages.value.push({ ...msg, isMine: true })
        scrollToBottom()
    }
    newMessage.value = ''
    if (messageInput.value) {
        messageInput.value.focus()
    }
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
    if (!messages.value.some(m => m.id === msg.id)) {
        messages.value.push({ ...msg, isMine: true })
        scrollToBottom()
    }
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
    if (!file.type?.startsWith('image/')) {
        toast.error('รองรับเฉพาะไฟล์รูปภาพเท่านั้น')
        return
    }

    try {
        isUploadingImage.value = true
        showAttachmentMenu.value = false
        
        const formData = new FormData()
        formData.append('image', file)

        const res = await $api(`/chats/${chatRoomId.value}/messages/image`, {
            method: 'POST',
            body: formData,
        })
        
        const msg = res.data || res
        if (msg && !messages.value.some(m => m.id === msg.id)) {
            messages.value.push({ ...msg, isMine: true })
            scrollToBottom()
        }
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

            const res = await $api(`/chats/${chatRoomId.value}/messages`, {
                method: 'POST',
                body: { content, type: 'LOCATION' }
            })
            
            const msg = res.data || res
            if (!messages.value.some(m => m.id === msg.id)) {
                messages.value.push({ ...msg, isMine: true })
                scrollToBottom()
            }
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
  fetchRoomDetails()
})

watch(socket, (newSocket) => {
    if (newSocket) {
        newSocket.on('new-message', (message) => {
            if (message.chatRoomId === chatRoomId.value) {
                const exists = messages.value.some(m => m.id === message.id)
                if (!exists) {
                    const enrichedMsg = {
                        ...message,
                        isMine: message.senderId === currentUser.value?.id
                    }
                    messages.value.push(enrichedMsg)
                    scrollToBottom()
                    markRoomAsRead(chatRoomId.value)
                }
            }
        })
    }
}, { immediate: true })

onUnmounted(() => {
})
</script>

<style scoped>
.slide-up-enter-active,
.slide-up-leave-active {
  transition: all 0.3sease;
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
