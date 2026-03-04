<template>
  <div>
    <AdminHeader />
    <AdminSidebar />

    <main id="main-content" class="main-content mt-16 ml-0 lg:ml-[280px] p-6">
      <div class="mx-auto max-w-8xl">
        <div class="flex flex-col gap-3 mb-6 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 class="text-2xl font-semibold text-gray-800">Driver Verification Management</h1>
            <p class="text-sm text-gray-500">รายการคำขอยืนยันตัวตนคนขับ</p>
          </div>
          <button
            type="button"
            class="px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50"
            @click="fetchVerifications"
          >
            รีเฟรช
          </button>
        </div>

        <div class="bg-white border border-gray-300 rounded-lg shadow-sm">
          <div v-if="isLoading" class="p-8 text-center text-gray-500">กำลังโหลดข้อมูล...</div>
          <div v-else-if="loadError" class="p-8 text-center text-red-600">{{ loadError }}</div>
          <div v-else-if="rows.length === 0" class="p-8 text-center text-gray-500">ไม่พบคำขอการยืนยันตัวตน</div>

          <div v-else class="overflow-x-auto">
            <table class="min-w-full text-sm">
              <thead class="text-gray-700 bg-gray-50">
                <tr>
                  <th class="px-4 py-3 text-left">ผู้ใช้</th>
                  <th class="px-4 py-3 text-left">เลขใบขับขี่</th>
                  <th class="px-4 py-3 text-left">ประเภทใบขับขี่</th>
                  <th class="px-4 py-3 text-left">สถานะ</th>
                  <th class="px-4 py-3 text-left">วันออกบัตร</th>
                  <th class="px-4 py-3 text-left">วันหมดอายุ</th>
                  <th class="px-4 py-3 text-right">อนุมัติ</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="v in rows" :key="v.id" class="border-t border-gray-100">
                  <td class="px-4 py-3">
                    <div class="font-medium text-gray-900">{{ fullName(v.user) }}</div>
                    <div class="text-xs text-gray-500">{{ v.user?.email || '-' }}</div>
                    <div class="font-mono text-[10px] text-gray-400">{{ v.id }}</div>
                  </td>
                  <td class="px-4 py-3">{{ v.licenseNumber || '-' }}</td>
                  <td class="px-4 py-3">{{ v.typeOnLicense || '-' }}</td>
                  <td class="px-4 py-3">
                    <span class="inline-flex px-2 py-1 text-xs font-medium rounded-full" :class="statusClass(v.status)">
                      {{ v.status || '-' }}
                    </span>
                  </td>
                  <td class="px-4 py-3">{{ formatDate(v.licenseIssueDate) }}</td>
                  <td class="px-4 py-3">{{ formatDate(v.licenseExpiryDate) }}</td>
                  <td class="px-4 py-3 text-right">
                    <div v-if="canReview(v)" class="inline-flex gap-2">
                      <button
                        class="px-3 py-1.5 text-xs font-medium text-white bg-emerald-600 rounded-md hover:bg-emerald-700 disabled:opacity-60"
                        :disabled="isRowBusy(v)"
                        @click="reviewVerification(v, 'APPROVED')"
                      >
                        {{ isBusy(v, 'APPROVED') ? 'กำลังบันทึก...' : 'Approve' }}
                      </button>
                      <button
                        class="px-3 py-1.5 text-xs font-medium text-white bg-rose-600 rounded-md hover:bg-rose-700 disabled:opacity-60"
                        :disabled="isRowBusy(v)"
                        @click="reviewVerification(v, 'REJECTED')"
                      >
                        {{ isBusy(v, 'REJECTED') ? 'กำลังบันทึก...' : 'Reject' }}
                      </button>
                    </div>
                    <span v-else class="text-xs text-gray-400">—</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <p v-if="actionError" class="mt-3 text-sm text-red-600">{{ actionError }}</p>
      </div>
    </main>

    <div id="overlay" class="fixed inset-0 z-40 hidden bg-black bg-opacity-50 lg:hidden" @click="closeMobileSidebar" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRuntimeConfig, useCookie } from '#app'
import dayjs from 'dayjs'
import 'dayjs/locale/th'
import buddhistEra from 'dayjs/plugin/buddhistEra'
import AdminHeader from '~/components/admin/AdminHeader.vue'
import AdminSidebar from '~/components/admin/AdminSidebar.vue'

dayjs.locale('th')
dayjs.extend(buddhistEra)

definePageMeta({ middleware: ['admin-auth'] })
useHead({
  title: 'Driver Verification Management • Admin',
  link: [{ rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }]
})

const rows = ref([])
const isLoading = ref(true)
const loadError = ref('')
const actionLoadingId = ref('')
const actionError = ref('')

function getToken() {
  return useCookie('token')?.value || (process.client ? localStorage.getItem('token') : '')
}

function fullName(u) {
  if (!u) return '-'
  const name = `${u.firstName || ''} ${u.lastName || ''}`.trim()
  return name || u.username || '-'
}

function formatDate(v) {
  if (!v) return '-'
  return dayjs(v).format('D MMM BBBB')
}

function statusClass(status) {
  switch (String(status || '').toUpperCase()) {
    case 'APPROVED': return 'bg-emerald-100 text-emerald-700'
    case 'REJECTED': return 'bg-rose-100 text-rose-700'
    case 'PENDING': return 'bg-amber-100 text-amber-700'
    default: return 'bg-gray-100 text-gray-700'
  }
}

function canReview(item) {
  return String(item?.status || '').toUpperCase() === 'PENDING'
}

function isBusy(item, status) {
  return actionLoadingId.value === `${item.id}:${status}`
}

function isRowBusy(item) {
  return actionLoadingId.value.startsWith(`${item.id}:`)
}

async function fetchVerifications() {
  isLoading.value = true
  loadError.value = ''
  try {
    const apiBase = useRuntimeConfig().public.apiBase
    const token = getToken()

    const res = await fetch(`${apiBase}driver-verifications/admin?page=1&limit=100`, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      credentials: 'include',
    })

    const body = await res.json()
    if (!res.ok) throw new Error(body?.message || `Request failed (${res.status})`)
    rows.value = Array.isArray(body?.data) ? body.data : []
  } catch (err) {
    console.error(err)
    loadError.value = err?.message || 'ไม่สามารถโหลดรายการยืนยันตัวตนคนขับได้'
    rows.value = []
  } finally {
    isLoading.value = false
  }
}

async function reviewVerification(item, status) {
  if (!canReview(item)) return

  const ok = window.confirm(
    status === 'APPROVED'
      ? `ยืนยันอนุมัติคำขอของ ${fullName(item.user)} ?`
      : `ยืนยันปฏิเสธคำขอของ ${fullName(item.user)} ?`
  )
  if (!ok) return

  actionLoadingId.value = `${item.id}:${status}`
  actionError.value = ''

  try {
    const apiBase = useRuntimeConfig().public.apiBase
    const token = getToken()

    const res = await fetch(`${apiBase}driver-verifications/${item.id}/status`, {
      method: 'PATCH',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: JSON.stringify({ status }),
      credentials: 'include',
    })

    const body = await res.json()
    if (!res.ok) throw new Error(body?.message || `Request failed (${res.status})`)

    item.status = status
  } catch (err) {
    console.error(err)
    actionError.value = err?.message || 'ไม่สามารถอัปเดตสถานะได้'
  } finally {
    actionLoadingId.value = ''
  }
}

function closeMobileSidebar() {
  const sidebar = document.getElementById('sidebar')
  const overlay = document.getElementById('overlay')
  if (!sidebar || !overlay) return
  sidebar.classList.remove('mobile-open')
  overlay.classList.add('hidden')
}

onMounted(fetchVerifications)
</script>
