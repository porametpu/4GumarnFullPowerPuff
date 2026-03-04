<template>
  <div>
    <AdminHeader />
    <AdminSidebar />

    <main id="main-content" class="main-content mt-16 ml-0 lg:ml-[280px] p-6">
      <div class="mx-auto max-w-8xl">

        <!-- Header -->
        <div class="flex flex-col gap-3 mb-6 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 class="text-2xl font-semibold text-gray-800">
              Investigation Management
            </h1>
            <p class="text-sm text-gray-500">
              รายการคำร้องขอข้อมูลเพื่อการ Export Chat Log
            </p>
          </div>

          <button
            class="px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50"
            @click="navigateTo('/admin/investigations/create')"
          >
            + Chat Log Export
          </button>
        </div>

        <!-- TABLE -->
        <div class="bg-white border border-gray-300 rounded-lg shadow-sm">

          <div v-if="loading" class="p-8 text-center text-gray-500">
            กำลังโหลดข้อมูล...
          </div>

          <div v-else-if="error" class="p-8 text-center text-red-600">
            {{ error }}
          </div>

          <div v-else-if="investigations.length === 0" class="p-8 text-center text-gray-500">
            ไม่พบคำร้อง
          </div>

          <div v-else class="overflow-x-auto">
            <table class="min-w-full text-sm">

              <thead class="text-gray-700 bg-gray-50">
                <tr>
                  <th class="px-4 py-3 text-left">Request No</th>
                  <th class="px-4 py-3 text-left">Authority</th>
                  <th class="px-4 py-3 text-left">Booking ID</th>
                  <th class="px-4 py-3 text-left">Period</th>
                  <th class="px-4 py-3 text-left">Created</th>
                  <th class="px-4 py-3 text-right">Actions</th>
                </tr>
              </thead>

              <tbody>
                <tr
                  v-for="item in investigations"
                  :key="item.id"
                  class="border-t border-gray-100"
                >

                  <!-- Request No -->
                  <td class="px-4 py-3 font-medium">
                    {{ item.requestNumber }}
                  </td>

                  <!-- Authority -->
                  <td class="px-4 py-3">
                    <div class="font-medium">
                      {{ item.authorityName || '-' }}
                    </div>
                    <div class="text-xs text-gray-500">
                      {{ item.officerName || '' }}
                    </div>
                  </td>

                  <!-- Booking -->
                  <td class="px-4 py-3">
                    {{ item.bookingId }}
                  </td>

                  <!-- Period -->
                  <td class="px-4 py-3 text-xs text-gray-600">
                    <div>{{ formatDate(item.fromDate) }}</div>
                    <div>ถึง</div>
                    <div>{{ formatDate(item.toDate) }}</div>
                  </td>

                  <!-- Created -->
                  <td class="px-4 py-3">
                    {{ formatDateTime(item.createdAt) }}
                  </td>

                  <!-- ACTION -->
                  <td class="px-4 py-3 text-right">
                    <div class="inline-flex gap-2 flex-wrap">

                      <!-- View -->
                      <button
                        class="px-3 py-1.5 text-xs font-medium text-white bg-gray-600 rounded-md hover:bg-gray-700"
                        @click="navigateTo(`/admin/investigations/${item.id}`)"
                      >
                        View
                      </button>

                      <!-- Export -->
                      <button
                        v-if="!item.exportedFileUrl"
                        class="px-3 py-1.5 text-xs font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 disabled:opacity-60"
                        :disabled="exportingId === item.id"
                        @click="exportData(item.id)"
                      >
                        {{ exportingId === item.id ? 'Exporting...' : 'Export' }}
                      </button>

                      <!-- Download -->
                      <button
                        v-if="item.exportedFileUrl"
                        class="px-3 py-1.5 text-xs font-medium text-white bg-purple-600 rounded-md hover:bg-purple-700"
                        @click="download(item.exportedFileUrl)"
                      >
                        Download
                      </button>

                    </div>
                  </td>

                </tr>
              </tbody>

            </table>
          </div>
        </div>

      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRuntimeConfig, useCookie, navigateTo } from '#app'
import dayjs from 'dayjs'
import AdminHeader from '~/components/admin/AdminHeader.vue'
import AdminSidebar from '~/components/admin/AdminSidebar.vue'
useHead({
  title: 'Investigation Management • Admin',
  link: [
    { rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }
  ]
})
definePageMeta({ middleware: ['admin-auth'] })

const investigations = ref([])
const loading = ref(true)
const error = ref('')
const exportingId = ref(null)

const apiBase = useRuntimeConfig().public.apiBase

function getToken() {
  return useCookie('token')?.value ||
    (process.client ? localStorage.getItem('token') : '')
}

function formatDateTime(v) {
  if (!v) return '-'
  return dayjs(v).format('D MMM YYYY HH:mm')
}

function formatDate(v) {
  if (!v) return '-'
  return dayjs(v).format('D MMM YYYY')
}

async function fetchInvestigations() {
  loading.value = true
  error.value = ''

  try {
    const res = await fetch(`${apiBase}admin/investigations`, {
      headers: {
        Accept: 'application/json',
        Authorization: `Bearer ${getToken()}`
      }
    })

    const body = await res.json()

    if (!res.ok) {
      throw new Error(body?.message || 'โหลดข้อมูลล้มเหลว')
    }

    investigations.value = body.data || []
  } catch (err) {
    error.value = err.message
  } finally {
    loading.value = false
  }
}

async function exportData(id) {

  if (!confirm('Export ข้อมูลตามคำร้องนี้?')) return

  exportingId.value = id

  try {

    const res = await fetch(
      `${apiBase}admin/investigations/${id}/export`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${getToken()}`
        }
      }
    )

    if (!res.ok) {
      const text = await res.text()
      throw new Error(text || "Export failed")
    }

    const blob = await res.blob()

    const url = window.URL.createObjectURL(blob)

    const a = document.createElement("a")
    a.href = url
    a.download = `chatlog-${id}.pdf`
    document.body.appendChild(a)
    a.click()

    a.remove()

  } catch (err) {

    alert(err.message)

  } finally {

    exportingId.value = null

  }
}

function download(url) {
  if (!url) return
  window.open(`${apiBase}${url}`, '_blank')
}

onMounted(fetchInvestigations)
</script>