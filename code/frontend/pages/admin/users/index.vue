<template>
  <div>
    <AdminHeader />
    <AdminSidebar />

    <main id="main-content" class="main-content mt-16 ml-0 lg:ml-[280px] p-6">
      <div class="mx-auto max-w-8xl">
        <div class="flex flex-col gap-3 mb-6 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 class="text-2xl font-semibold text-gray-800">User Management</h1>
            <p class="text-sm text-gray-500">รายการผู้ใช้ในระบบ</p>
          </div>
          <button
            type="button"
            class="px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50"
            @click="fetchUsers"
          >
            รีเฟรช
          </button>
        </div>

        <div class="bg-white border border-gray-300 rounded-lg shadow-sm">
          <div v-if="isLoading" class="p-8 text-center text-gray-500">กำลังโหลดข้อมูล...</div>
          <div v-else-if="loadError" class="p-8 text-center text-red-600">{{ loadError }}</div>
          <div v-else-if="rows.length === 0" class="p-8 text-center text-gray-500">ไม่พบข้อมูลผู้ใช้</div>

          <div v-else class="overflow-x-auto">
            <table class="min-w-full text-sm">
              <thead class="text-gray-700 bg-gray-50">
                <tr>
                  <th class="px-4 py-3 text-left">ชื่อผู้ใช้</th>
                  <th class="px-4 py-3 text-left">อีเมล</th>
                  <th class="px-4 py-3 text-left">ชื่อ-สกุล</th>
                  <th class="px-4 py-3 text-left">Role</th>
                  <th class="px-4 py-3 text-left">ยืนยันตัวตน</th>
                  <th class="px-4 py-3 text-left">สถานะใช้งาน</th>
                  <th class="px-4 py-3 text-left">สร้างเมื่อ</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="u in rows" :key="u.id" class="border-t border-gray-100">
                  <td class="px-4 py-3">{{ u.username || '-' }}</td>
                  <td class="px-4 py-3">{{ u.email || '-' }}</td>
                  <td class="px-4 py-3">{{ fullName(u) }}</td>
                  <td class="px-4 py-3">{{ u.role || '-' }}</td>
                  <td class="px-4 py-3">
                    <span class="inline-flex px-2 py-1 text-xs font-medium rounded-full" :class="u.isVerified ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-700'">
                      {{ u.isVerified ? 'Verified' : 'Not Verified' }}
                    </span>
                  </td>
                  <td class="px-4 py-3">
                    <span class="inline-flex px-2 py-1 text-xs font-medium rounded-full" :class="u.isActive ? 'bg-blue-100 text-blue-700' : 'bg-rose-100 text-rose-700'">
                      {{ u.isActive ? 'Active' : 'Inactive' }}
                    </span>
                  </td>
                  <td class="px-4 py-3">{{ formatDateTime(u.createdAt) }}</td>
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
  title: 'User Management • Admin',
  link: [{ rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }]
})

const rows = ref([])
const isLoading = ref(true)
const loadError = ref('')

function getToken() {
  return useCookie('token')?.value || (process.client ? localStorage.getItem('token') : '')
}

function fullName(u) {
  if (!u) return '-'
  return `${u.firstName || ''} ${u.lastName || ''}`.trim() || '-'
}

function formatDateTime(v) {
  if (!v) return '-'
  return dayjs(v).format('D MMM BBBB HH:mm')
}

async function fetchUsers() {
  isLoading.value = true
  loadError.value = ''
  try {
    const apiBase = useRuntimeConfig().public.apiBase
    const token = getToken()

    const res = await fetch(`${apiBase}users/admin?page=1&limit=100`, {
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
    loadError.value = err?.message || 'ไม่สามารถโหลดรายการผู้ใช้ได้'
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

onMounted(fetchUsers)
</script>

