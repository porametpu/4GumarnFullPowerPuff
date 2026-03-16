<template>
  <Transition
    enter-active-class="transition duration-300 ease-out"
    enter-from-class="opacity-0 scale-95"
    enter-to-class="opacity-100 scale-100"
    leave-active-class="transition duration-200 ease-in"
    leave-from-class="opacity-100 scale-100"
    leave-to-class="opacity-0 scale-95"
  >
    <div v-if="activeAlert" class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
      <div class="bg-white rounded-2xl shadow-2xl max-w-sm w-full overflow-hidden transform transition-all border border-blue-100">
        <div class="bg-blue-600 p-6 flex flex-col items-center text-white relative">
            <!-- Animated Icon -->
            <div class="w-20 h-20 bg-white/20 rounded-full flex items-center justify-center mb-4 animate-pulse">
                <div class="w-14 h-14 bg-white rounded-full flex items-center justify-center shadow-inner">
                    <svg class="w-8 h-8 text-blue-600 animate-bounce" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                    </svg>
                </div>
            </div>
          <h3 class="text-xl font-bold">{{ activeAlert.title }}</h3>
          <p class="text-blue-100 text-sm mt-1">ข้อความสำคัญจากการเดินทาง</p>
        </div>
        <div class="p-6 text-center">
          <p class="text-gray-700 text-lg leading-relaxed font-medium">
            {{ activeAlert.message }}
          </p>
          
          <div class="mt-8 flex flex-col space-y-3">
            <button 
              @click="closeAlert"
              class="w-full py-3 px-4 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl shadow-lg shadow-blue-200 transition-all active:scale-95"
            >
              รับทราบ
            </button>
            <p class="text-[11px] text-gray-400">แจ้งเตือนนี้จะปรากฏขึ้นเมื่อคนขับอยู่ใกล้คุณ</p>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
import { useNearAlert } from '~/composables/useNearAlert'

const { activeAlert, closeAlert } = useNearAlert()
</script>

<style scoped>
.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.8; transform: scale(1.05); }
}
</style>
