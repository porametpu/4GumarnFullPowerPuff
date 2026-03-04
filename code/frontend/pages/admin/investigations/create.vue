<template>
  <div>
    <AdminHeader />
    <AdminSidebar />

    <main class="main-content mt-16 ml-0 lg:ml-[280px] p-6">
      <div class="mx-auto max-w-4xl">

        <!-- Header -->
        <div class="mb-6">
          <h1 class="text-2xl font-semibold text-gray-800">
            Create Investigation Request
          </h1>
          <p class="text-sm text-gray-500">
            สร้างคำร้องขอข้อมูลเพื่อการสอบสวนตามคำร้องจากหน่วยงานที่มีอำนาจ
          </p>
        </div>

        <div class="bg-white border border-gray-300 rounded-lg shadow-sm p-6 space-y-6">

          <!-- Case Information -->
          <div>
            <h2 class="text-lg font-semibold mb-4">Case Information</h2>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">

              <!-- Authority Name -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Authority Name *
                </label>
                <input v-model="form.authorityName"
                  class="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
              </div>

              <!-- Officer Name -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Officer Name *
                </label>
                <input v-model="form.officerName"
                  class="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
              </div>

              <!-- Officer Position -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Officer Position
                </label>
                <input v-model="form.officerPosition"
                  class="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
              </div>

              <!-- Contact Email -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Contact Email *
                </label>
                <input type="email" v-model="form.contactEmail"
                  class="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
              </div>

              <!-- Contact Phone -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Contact Phone *
                </label>
                <input v-model="form.contactPhone"
                  class="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
              </div>
              <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">
        Official Document (PDF/Image) *
      </label>
      <input
        type="file"
        accept=".pdf,.jpg,.jpeg,.png"
        @change="handleFile"
        class="w-full border border-gray-300 rounded px-3 py-2 text-sm"
      />
    </div>

              <!-- Official Request Date -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Official Request Date *
                </label>
                <input type="date" v-model="form.requestDate"
                  class="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
              </div>

            </div>
          </div>

          <!-- Target Booking -->
          <div>
            <h2 class="text-lg font-semibold mb-4">Target Booking</h2>

            <label class="block text-sm font-medium text-gray-700 mb-1">
              Booking ID *
            </label>
            <input v-model="form.bookingId"
              class="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
          </div>

          <!-- Requested Data Period -->
          <div>
            <h2 class="text-lg font-semibold mb-2">Requested Data Period</h2>
            <p class="text-sm text-gray-500 mb-4">
              กำหนดช่วงเวลาของข้อมูลแชทที่ต้องการ Export
            </p>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Start Date *
                </label>
                <input type="date" v-model="form.startDate"
                  class="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  End Date *
                </label>
                <input type="date" v-model="form.endDate"
                  class="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
              </div>
            </div>
          </div>

          <!-- Reason -->
          <div>
            <h2 class="text-lg font-semibold mb-4">Reason</h2>
            <textarea v-model="form.reason" rows="4"
              placeholder="ระบุเหตุผลการขอข้อมูล"
              class="w-full border border-gray-300 rounded px-3 py-2 text-sm"></textarea>
          </div>

          <!-- Confirmation -->
          <div class="flex items-start gap-3">
            <input type="checkbox" v-model="form.confirmed" class="mt-1" />
            <p class="text-sm text-gray-600">
              ข้าพเจ้ายืนยันว่าได้รับคำร้องอย่างเป็นทางการจากหน่วยงานที่มีอำนาจ
              และข้อมูลที่ร้องขออยู่ภายในขอบเขตที่ระบุเท่านั้น
            </p>
          </div>

          <!-- Buttons -->
          <div class="flex justify-end gap-3">
            <button
              class="px-4 py-2 bg-gray-300 rounded hover:bg-gray-400"
              @click="navigateTo('/admin/investigations')">
              Cancel
            </button>

            <button
              class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
              :disabled="submitting"
              @click="submit">
              {{ submitting ? 'Submitting...' : 'Submit Request' }}
            </button>
          </div>

        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRuntimeConfig, useCookie, navigateTo } from '#app'
import AdminHeader from '~/components/admin/AdminHeader.vue'
import AdminSidebar from '~/components/admin/AdminSidebar.vue'
useHead({
  title: 'Investigation Management • Admin',
  link: [
    { rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }
  ]
})
definePageMeta({ middleware: ['admin-auth'] })

const apiBase = useRuntimeConfig().public.apiBase
const submitting = ref(false)

const form = ref({
  authorityName: '',
  officerName: '',
  officerPosition: '',
  contactEmail: '',
  contactPhone: '',
  requestDate: '',
  bookingId: '',
  startDate: '',
  endDate: '',
  reason: '',
  confirmed: false
})

function getToken() {
  return useCookie('token')?.value ||
    (process.client ? localStorage.getItem('token') : '')
}

function validate() {
  if (!form.value.authorityName) return 'Authority required'
  if (!form.value.officerName) return 'Officer Name required'
  if (!form.value.contactEmail) return 'Email required'
  if (!form.value.contactPhone) return 'Phone required'
  if (!form.value.requestDate) return 'Request Date required'
  if (!form.value.bookingId) return 'Booking ID required'
  if (!form.value.startDate) return 'Start Date required'
  if (!form.value.endDate) return 'End Date required'
  if (!form.value.confirmed) return 'กรุณายืนยันคำร้องอย่างเป็นทางการ'
  return null
}

async function submit() {

  const errorMsg = validate()
  if (errorMsg) {
    alert(errorMsg)
    return
  }

  if (!confirm('ยืนยันการสร้างคำร้องนี้?')) return

  submitting.value = true

  try {

    const res = await fetch(`${apiBase}admin/investigations`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${getToken()}`
      },
      body: JSON.stringify(form.value)
    })

    const body = await res.json()

    console.log("API RESPONSE:", body)

    if (!res.ok) {
      throw new Error(body?.message || 'Create failed')
    }

    const id = body?.data?.id || body?.id

    if (!id) {
      throw new Error("Investigation ID not returned from API")
    }

    alert('สร้างคำร้องสำเร็จ')

    navigateTo(`/admin/investigations/${id}`)

  } catch (err) {
    alert(err.message)
  } finally {
    submitting.value = false
  }
}
</script>