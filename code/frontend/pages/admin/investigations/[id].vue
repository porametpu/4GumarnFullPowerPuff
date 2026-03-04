<template>
  <div>
    <AdminHeader />
    <AdminSidebar />

    <main class="main-content mt-16 ml-0 lg:ml-[280px] p-6">
      <div class="max-w-5xl mx-auto">

        <h1 class="text-2xl font-semibold mb-6">
          Investigation Detail
        </h1>

        <!-- Loading -->
        <div v-if="loading" class="text-gray-500">
          Loading...
        </div>

        <!-- Error -->
        <div v-else-if="error" class="text-red-600">
          {{ error }}
        </div>

        <!-- Case Info -->
        <div v-else class="bg-white p-6 border rounded">

          <h2 class="font-semibold text-lg mb-4">
            Case Info
          </h2>

          <p><b>Request Number:</b> {{ investigation?.requestNumber || '-' }}</p>
          <p><b>Authority:</b> {{ investigation?.authorityName || '-' }}</p>
          <p><b>Officer:</b> {{ investigation?.officerName || '-' }}</p>
          <p><b>Officer Position:</b> {{ investigation?.officerPosition || '-' }}</p>
          <p><b>Booking ID:</b> {{ investigation?.bookingId || '-' }}</p>

          <p>
            <b>Request Date:</b>
            {{ formatDate(investigation?.requestDate) }}
          </p>

          <p>
            <b>Data Period:</b>
            {{ formatDate(investigation?.fromDate) }}
            -
            {{ formatDate(investigation?.toDate) }}
          </p>

          <p>
            <b>Reason:</b>
            {{ investigation?.reason || '-' }}
          </p>

        </div>

        <!-- Export -->
        <div class="mt-6">
          <button
            class="bg-red-600 text-white px-4 py-2 rounded hover:bg-red-700"
            @click="exportPDF"
          >
            Export PDF
          </button>
        </div>

      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue"
import { useRoute, useRuntimeConfig, useCookie } from "#app"

import AdminHeader from "~/components/admin/AdminHeader.vue"
import AdminSidebar from "~/components/admin/AdminSidebar.vue"

const route = useRoute()
const apiBase = useRuntimeConfig().public.apiBase

const investigation = ref(null)
const loading = ref(true)
const error = ref(null)

function getToken() {
  return useCookie('token')?.value ||
    (process.client ? localStorage.getItem('token') : '')
}

function formatDate(v){
  if(!v) return "-"
  return new Date(v).toLocaleDateString("th-TH")
}

async function loadData(){

  try{

    const res = await fetch(
      `${apiBase}admin/investigations/${route.params.id}`,
      {
        headers:{
          Accept:"application/json",
          Authorization:`Bearer ${getToken()}`
        }
      }
    )

    const body = await res.json()

    if(!res.ok){
      throw new Error(body?.message)
    }

    investigation.value = body.data || {}

  }
  catch(err){

    console.error(err)
    error.value = err.message

  }
  finally{

    loading.value = false

  }

}

async function exportPDF(){

  try{

    const res = await fetch(
      `${apiBase}admin/investigations/${route.params.id}/export`,
      {
        headers:{
          Authorization:`Bearer ${getToken()}`
        }
      }
    )

    if(!res.ok){
      throw new Error("Export failed")
    }

    const blob = await res.blob()

    const url = window.URL.createObjectURL(blob)

    const a = document.createElement("a")
    a.href = url
    a.download = `chatlog-${route.params.id}.pdf`

    document.body.appendChild(a)
    a.click()
    a.remove()

  }
  catch(err){

    alert(err.message)

  }

}

onMounted(loadData)
</script>