<template>
  <div class="flex items-center justify-center py-8">
    <div class="flex bg-white rounded-lg shadow-lg overflow-hidden max-w-6xl w-full mx-4 border border-gray-300">
        <ProfileSidebar />
      <main class="flex-1 p-8">
        <div class="text-center mb-8">
          <div class="inline-flex items-center justify-center w-16 h-16 bg-blue-600 rounded-full mb-4">
            <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
          </div>
          <h1 class="text-3xl font-bold text-gray-800 mb-2">ลบบัญชีผู้ใช้</h1>
          <p class="text-gray-600 max-w-md mx-auto">
            ลบบัญชีผู้ใช้ของคุณอย่างถาวร รวมถึงข้อมูลส่วนตัวและข้อมูลรถยนต์ที่บันทึกไว้ทั้งหมด
          </p>
        </div>

        <div class="bg-white rounded-xl shadow-xl p-8 border border-gray-300">
          <div v-if="errorMessage" class="mb-6 p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg">
            {{ errorMessage }}
          </div>

          <div v-if="successMessage" class="mb-6 p-4 bg-green-50 border border-green-200 text-green-700 rounded-lg whitespace-pre-line">
            {{ successMessage }}
          </div>

          <div class="space-y-4">
            <div v-if="isLoadingData" class="flex justify-center items-center py-4 text-gray-500">
              <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-gray-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              <span>กำลังตรวจสอบข้อมูล...</span>
            </div>
            <template v-else>
              <input
                v-model="emailConfirm"
                type="email"
                placeholder="กรอกอีเมลของคุณเพื่อยืนยัน"
                :disabled="hasActiveBookings"
                class="w-full border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
              />

              <button
                @click="handleDelete"
                :disabled="loading || hasActiveBookings || !emailConfirm.trim()"
                class="w-full bg-red-600 hover:bg-red-700 text-white py-2 rounded-lg transition disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {{ loading ? 'กำลังลบบัญชี...' : 'ลบบัญชีถาวร' }}
              </button>
            </template>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import ProfileSidebar from '~/components/ProfileSidebar.vue';
import { useAuth } from '~/composables/useAuth'

const { $api } = useNuxtApp()
const { user } = useAuth()

const emailConfirm = ref('')
const loading = ref(false)
const isLoadingData = ref(true)
const errorMessage = ref('')
const successMessage = ref('')
const hasActiveBookings = ref(false)
const activeBookingMessage = ref('')

definePageMeta({
    middleware: 'auth'
});

onMounted(async () => {
  await checkActiveBookings()
})

const checkActiveBookings = async () => {
  isLoadingData.value = true
  try {
    const tokenCookie = useCookie('token')
    const token = tokenCookie.value
    if (!token) return

    let activeCount = 0

    // ตรวจสอบจาก bookings (ฝั่งคนนั่ง)
    try {
      const bookings = await $api('/bookings/me', {
        headers: { Authorization: `Bearer ${token}` }
      })
      const activeBookings = bookings.filter(b => b.status === 'PENDING' || b.status === 'CONFIRMED')
      activeCount += activeBookings.length
    } catch (e) {
      console.error('Cannot fetch bookings:', e)
    }

    // ตรวจสอบจาก routes (ฝั่งคนขับ)
    if (user.value?.role === 'DRIVER') {
      try {
        const routes = await $api('/routes/me', {
          headers: { Authorization: `Bearer ${token}` }
        })
        const activeRoutes = routes.filter(r => r.status === 'AVAILABLE' || r.status === 'FULL' || r.status === 'IN_TRANSIT')
        activeCount += activeRoutes.length
      } catch (e) {
        console.error('Cannot fetch routes:', e)
      }
    }

    if (activeCount > 0) {
      hasActiveBookings.value = true
      activeBookingMessage.value = 'คุณมีรายการจองหรือการเดินทางที่กำลังดำเนินการอยู่ กรุณายกเลิกหรือทำรายการให้เสร็จสิ้นก่อนลบบัญชี'
      errorMessage.value = activeBookingMessage.value
    }
  } catch (err) {
    console.error('Error checking active bookings:', err)
  } finally {
    isLoadingData.value = false
  }
}

const handleDelete = async () => {
  if (hasActiveBookings.value) {
    errorMessage.value = activeBookingMessage.value
    return
  }

  if (!emailConfirm.value.trim()) {
    errorMessage.value = 'กรุณากรอกอีเมลเพื่อยืนยัน'
    return
  }

  if (!confirm('คุณแน่ใจหรือไม่ว่าต้องการลบบัญชี? การกระทำนี้ไม่สามารถย้อนกลับได้หลัง 90 วัน')) {
    return
  }

  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const tokenCookie = useCookie('token')
    const token = tokenCookie.value
    if (!token) {
      errorMessage.value = 'ไม่พบ token กรุณา login ใหม่'
      return
    }
    const res = await $api('/users/delete-account', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({ email: emailConfirm.value.trim() }),
      credentials: 'include'
    })
    successMessage.value = res.message || 'คำขอการลบบัญชีสำเร็จแล้ว'
    if (res.detail) successMessage.value += `\n${res.detail}`
    if (res.scheduledDate) {
      const date = new Date(res.scheduledDate)
      successMessage.value += `\nจะลบถาวรประมาณ ${date.toLocaleDateString('th-TH', { year: 'numeric', month: 'long', day: 'numeric' })}`
    }

    tokenCookie.value = null
    useCookie('user').value = null
    setTimeout(() => navigateTo('/'), 3000)

  } catch (err) {
    errorMessage.value = err.data?.message || 'เกิดข้อผิดพลาดในการลบบัญชี กรุณาตรวจสอบข้อมูลและลองใหม่อีกครั้ง'
    if (err.status === 401) {
      errorMessage.value = 'ไม่ได้รับอนุญาต – Token อาจหมดอายุหรือไม่ถูกต้อง'
    }
  } finally {
    loading.value = false
  }
}
</script>