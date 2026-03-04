<template>
  <div>
    <AdminHeader />
    <AdminSidebar />

    <main id="main-content" class="main-content mt-16 ml-0 lg:ml-[280px] p-6">
      <div class="mx-auto max-w-5xl">
        <div class="flex flex-col gap-3 mb-6 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 class="text-2xl font-semibold text-gray-800">Admin Notifications</h1>
            <p class="text-sm text-gray-500">รายการการแจ้งเตือนในฝั่งแอดมิน</p>
          </div>
          <button
            type="button"
            class="px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50"
            @click="fetchNotifications"
          >
            รีเฟรช
          </button>
        </div>

        <div class="bg-white border border-gray-300 rounded-lg shadow-sm">
          <div v-if="isLoading" class="p-8 text-center text-gray-500">กำลังโหลดข้อมูล...</div>
          <div v-else-if="loadError" class="p-8 text-center text-red-600">{{ loadError }}</div>
          <div v-else-if="rows.length === 0" class="p-8 text-center text-gray-500">ไม่มีการแจ้งเตือน</div>

          <ul v-else class="divide-y divide-gray-100">
            <li v-for="n in rows" :key="n.id" class="p-4">
              <div class="flex items-start justify-between gap-3">
                <div>
                  <p class="font-medium text-gray-900">{{ n.title || '-' }}</p>
                  <p class="text-sm text-gray-600">{{ n.body || '-' }}</p>
                  <p class="mt-1 text-xs text-gray-400">{{ formatDateTime(n.createdAt) }}</p>
                </div>
                <span class="inline-flex px-2 py-1 text-xs font-medium rounded-full" :class="n.adminReviewedAt ? 'bg-gray-100 text-gray-700' : 'bg-emerald-100 text-emerald-700'">
                  {{ n.adminReviewedAt ? 'Read' : 'Unread' }}
                </span>
              </div>
            </li>
          </ul>
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
  title: 'Admin Notifications',
  link: [{ rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }]
})

const rows = ref([])
const isLoading = ref(true)
const loadError = ref('')

function getToken() {
  return useCookie('token')?.value || (process.client ? localStorage.getItem('token') : '')
}

function formatDateTime(v) {
  if (!v) return '-'
  return dayjs(v).format('D MMM BBBB HH:mm')
}

async function fetchNotifications() {
  isLoading.value = true
  loadError.value = ''
  try {
    const apiBase = useRuntimeConfig().public.apiBase
    const token = getToken()

    const res = await fetch(`${apiBase}notifications/admin?page=1&limit=50`, {
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
    loadError.value = err?.message || 'ไม่สามารถโหลดรายการแจ้งเตือนได้'
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

onMounted(fetchNotifications)
</script>

