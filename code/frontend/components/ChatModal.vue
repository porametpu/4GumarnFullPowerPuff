<template>
  <transition name="modal-fade">
    <div v-if="show" class="modal-overlay" @click.self="close">
      <div class="modal-content flex flex-col">
        <!-- Header -->
        <div class="flex justify-between items-center p-4 border-b">
          <h3 class="text-lg font-semibold text-gray-900">แชทกับผู้โดยสาร</h3>
          <button @click="close" class="text-gray-400 hover:text-gray-600">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>

        <!-- Body: Chat Messages -->
        <div class="flex-1 p-4 overflow-y-auto bg-gray-50 flex flex-col space-y-3" style="max-height: 400px; min-height: 300px;" ref="messagesContainer">
          <div v-if="isLoading" class="text-center text-gray-500 py-4">กำลังโหลดข้อความ...</div>
          <div v-else-if="messages.length === 0" class="text-center text-gray-500 py-4">ยังไม่มีข้อความ เริ่มต้นทักทายเลย!</div>
          
          <div v-for="msg in messages" :key="msg.id" class="flex" :class="msg.isMine ? 'justify-end' : 'justify-start'">
            <div class="max-w-[75%]">
              <div class="text-xs text-gray-500 mb-1" :class="msg.isMine ? 'text-right' : 'text-left'">
                {{ msg.senderDisplayName }} • {{ formatTime(msg.createdAt) }}
              </div>
              <div class="px-4 py-2 rounded-lg" :class="msg.isMine ? 'bg-blue-600 text-white rounded-br-none' : 'bg-white text-gray-800 border rounded-bl-none'">
                {{ msg.content }}
              </div>
            </div>
          </div>
        </div>

        <!-- Footer: Input Area -->
        <div class="p-4 border-t flex gap-2 bg-white rounded-b-xl">
          <input 
            v-model="newMessage" 
            @keyup.enter="sendMessage"
            type="text" 
            placeholder="พิมพ์ข้อความ..." 
            class="flex-1 px-4 py-2 border border-gray-300 rounded-full focus:outline-none focus:ring-2 focus:ring-blue-500"
            :disabled="isSending"
          />
          <button 
            @click="sendMessage" 
            :disabled="!newMessage.trim() || isSending"
            class="px-4 py-2 bg-blue-600 text-white rounded-full hover:bg-blue-700 disabled:opacity-50 transition-colors flex items-center justify-center"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path>
            </svg>
          </button>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, watch, nextTick, onUnmounted } from 'vue'
import dayjs from 'dayjs'
import { useChatWidget } from '~/composables/useChatWidget'

const props = defineProps({
  show: Boolean,
  bookingId: String
})

const emit = defineEmits(['close'])

const { $api } = useNuxtApp()
const { socket, joinRoom } = useSocket()
const { refreshUnreadCount, markRoomAsRead } = useChatWidget()
const isLoading = ref(false)
const isSending = ref(false)
const messages = ref([])
const newMessage = ref('')
const messagesContainer = ref(null)
const chatRoomId = ref(null)

const close = () => {
  emit('close')
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

const fetchChatRoomAndMessages = async () => {
  if (!props.bookingId) return
  
  try {
    const roomRes = await $api(`/chats/booking/${props.bookingId}`)
    chatRoomId.value = roomRes?.id
    
    if (chatRoomId.value) {
      joinRoom(chatRoomId.value)
      await fetchMessages()
    }
  } catch (error) {
    console.error('Failed to fetch chat room:', error)
  } finally {
    isLoading.value = false
  }
}

const fetchMessages = async () => {
  if (!chatRoomId.value) return
  try {
    const res = await $api(`/chats/${chatRoomId.value}/messages`)
    messages.value = res || []
    scrollToBottom(true)
    markRoomAsRead(chatRoomId.value)
  } catch (error) {
    console.error('Failed to fetch messages:', error)
  }
}

const sendMessage = async () => {
  if (!newMessage.value.trim() || isSending.value || !chatRoomId.value) return
  
  try {
    isSending.value = true
    const res = await $api(`/chats/${chatRoomId.value}/messages`, {
      method: 'POST',
      body: { content: newMessage.value.trim(), type: 'TEXT' }
    })
    
    const msg = res.data || res
    if (!messages.value.some(m => m.id === msg.id)) {
        messages.value.push(msg)
        scrollToBottom()
    }
    newMessage.value = ''
  } catch (error) {
    console.error('Failed to send message:', error)
  } finally {
    isSending.value = false
  }
}

watch(() => props.show, (newVal) => {
  if (newVal) {
    isLoading.value = true
    fetchChatRoomAndMessages()
  } else {
    messages.value = []
    chatRoomId.value = null
  }
})

watch(socket, (newSocket) => {
    if (newSocket) {
        newSocket.on('new-message', (message) => {
            if (message.chatRoomId === chatRoomId.value) {
                const exists = messages.value.some(m => m.id === message.id)
                if (!exists) {
                    messages.value.push(message)
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
.modal-overlay {
  position: fixed;
  z-index: 1000;
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-content {
  background-color: white;
  border-radius: 0.75rem;
  width: 95%;
  max-width: 448px;
  box-shadow: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);
}

.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.3s ease;
}

.modal-fade-enter-active .modal-content,
.modal-fade-leave-active .modal-content {
  transition: all 0.3s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.modal-fade-enter-from .modal-content,
.modal-fade-leave-to .modal-content {
  transform: scale(0.95) translateY(1rem);
}

::-webkit-scrollbar {
  width: 6px;
}
::-webkit-scrollbar-track {
  background: transparent;
}
::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 3px;
}
::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}
</style>
