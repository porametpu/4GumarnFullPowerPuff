<template>
  <div>
    <AdminHeader />
    <AdminSidebar />

    <main id="main-content" class="main-content mt-16 ml-0 lg:ml-[280px] p-6">
      <div class="mx-auto max-w-8xl">
        <div class="flex flex-col gap-3 mb-6 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 class="text-2xl font-semibold text-gray-800">Booking Management</h1>
            <p class="text-sm text-gray-500">รายการการจองทั้งหมดของระบบ</p>
          </div>
          <div class="flex items-center gap-2">
            <button
              type="button"
              class="px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50"
              @click="fetchBookings"
            >
              รีเฟรช
            </button>
            <NuxtLink
              to="/admin/bookings/create"
              class="px-3 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700"
            >
              สร้างการจอง
            </NuxtLink>
          </div>
        </div>

        <div class="bg-white border border-gray-300 rounded-lg shadow-sm">
          <div v-if="isLoading" class="p-8 text-center text-gray-500">กำลังโหลดข้อมูล...</div>
          <div v-else-if="loadError" class="p-8 text-center text-red-600">{{ loadError }}</div>
          <div v-else-if="rows.length === 0" class="p-8 text-center text-gray-500">ไม่พบข้อมูลการจอง</div>

          <div v-else class="overflow-x-auto">
            <table class="min-w-full text-sm">
              <thead class="text-gray-700 bg-gray-50">
                <tr>
                  <th class="px-4 py-3 text-left">Booking ID</th>
                  <th class="px-4 py-3 text-left">ผู้โดยสาร</th>
                  <th class="px-4 py-3 text-left">เส้นทาง</th>
                  <th class="px-4 py-3 text-left">ที่นั่ง</th>
                  <th class="px-4 py-3 text-left">สถานะ</th>
                  <th class="px-4 py-3 text-left">สร้างเมื่อ</th>
                  <th class="px-4 py-3 text-right">จัดการ</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="b in rows" :key="b.id" class="border-t border-gray-100">
                  <td class="px-4 py-3 font-mono text-xs">{{ shortId(b.id) }}</td>
                  <td class="px-4 py-3">{{ fullName(b.passenger) }}</td>
                  <td class="px-4 py-3">
                    <div class="font-medium text-gray-900">{{ b.route?.routeSummary || '-' }}</div>
                    <div class="text-xs text-gray-500">{{ fullName(b.route?.driver) }}</div>
                  </td>
                  <td class="px-4 py-3">{{ b.numberOfSeats ?? '-' }}</td>
                  <td class="px-4 py-3">
                    <span class="inline-flex px-2 py-1 text-xs font-medium rounded-full" :class="statusClass(b.status)">
                      {{ b.status || '-' }}
                    </span>
                  </td>
                  <td class="px-4 py-3">{{ formatDateTime(b.createdAt) }}</td>
                  <td class="px-4 py-3 text-right">
                    <div class="inline-flex items-center gap-2">
                      <NuxtLink :to="`/admin/bookings/${b.id}`" class="text-blue-600 hover:underline">รายละเอียด</NuxtLink>
                      <NuxtLink :to="`/admin/bookings/${b.id}/edit`" class="text-indigo-600 hover:underline">แก้ไข</NuxtLink>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
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
  title: 'Booking Management • Admin',
  link: [{ rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }]
})

const rows = ref([])
const isLoading = ref(true)
const loadError = ref('')

function getToken() {
  return useCookie('token')?.value || (process.client ? localStorage.getItem('token') : '')
}

function shortId(id) {
  if (!id) return '-'
  return String(id).slice(0, 10)
}

function fullName(u) {
  if (!u) return '-'
  const name = `${u.firstName || ''} ${u.lastName || ''}`.trim()
  return name || u.email || u.username || '-'
}

function formatDateTime(v) {
  if (!v) return '-'
  return dayjs(v).format('D MMM BBBB HH:mm')
}

function statusClass(status) {
  switch (String(status || '').toUpperCase()) {
    case 'PENDING': return 'bg-amber-100 text-amber-700'
    case 'CONFIRMED': return 'bg-emerald-100 text-emerald-700'
    case 'REJECTED': return 'bg-rose-100 text-rose-700'
    case 'CANCELLED': return 'bg-gray-200 text-gray-700'
    default: return 'bg-gray-100 text-gray-700'
  }
}

async function fetchBookings() {
  isLoading.value = true
  loadError.value = ''
  try {
    const apiBase = useRuntimeConfig().public.apiBase
    const token = getToken()

    const res = await fetch(`${apiBase}bookings/admin?page=1&limit=100`, {
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
    loadError.value = err?.message || 'ไม่สามารถโหลดรายการการจองได้'
    rows.value = []
  } finally {
    isLoading.value = false
  }
}

function closeMobileSidebar() {
  const sidebar = document.getElementById('sidebar')
  const overlay = document.getElementById('overlay')
  if (!sidebar || !overlay) return
  sidebar.classList.remove('mobile-open')
  overlay.classList.add('hidden')
}

onMounted(fetchBookings)
</script>

