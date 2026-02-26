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
            <input
              v-model="emailConfirm"
              type="email"
              placeholder="กรอกอีเมลของคุณเพื่อยืนยัน"
              class="w-full border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />

            <button
              @click="handleDelete"
              :disabled="loading || !emailConfirm.trim()"
              class="w-full bg-red-600 hover:bg-red-700 text-white py-2 rounded-lg transition disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {{ loading ? 'กำลังลบบัญชี...' : 'ลบบัญชีถาวร' }}
            </button>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import ProfileSidebar from '~/components/ProfileSidebar.vue';
const { $api } = useNuxtApp()

const emailConfirm = ref('')
const loading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

definePageMeta({
    middleware: 'auth'
});


const handleDelete = async () => {
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