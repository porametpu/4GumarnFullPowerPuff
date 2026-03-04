<template>
    <div>
        <AdminHeader />
        <AdminSidebar />

        <main class="main-content mt-16 ml-0 lg:ml-[280px] p-6">
            <div class="max-w-5xl mx-auto">

                <h1 class="text-2xl font-semibold mb-6">
                    Investigation Detail
                </h1>

                <div v-if="loading">Loading...</div>

                <div v-else>

                    <!-- Case Info -->
                    <div class="bg-white p-6 border rounded mb-6">
                        <h2 class="font-semibold text-lg mb-4">Case Info</h2>

                        <p><b>Request Number:</b> {{ investigation.requestNumber }}</p>
                        <p><b>Authority:</b> {{ investigation.authorityName }}</p>
                        <p><b>Officer:</b> {{ investigation.officerName }}</p>
                        <p><b>Booking ID:</b> {{ investigation.bookingId }}</p>
                        <p><b>Reason:</b> {{ investigation.reason }}</p>
                    </div>

                    <!-- Chat Log -->
                    <div class="bg-white p-6 border rounded mb-6">
                        <h2 class="font-semibold text-lg mb-4">Chat Log</h2>

                        <div v-if="messages.length === 0">
                            No chat messages
                        </div>

                        <div v-for="msg in messages" :key="msg.id" class="border-b py-2">

                            <p class="text-sm text-gray-500">
                                {{ formatTime(msg.createdAt) }}
                            </p>

                            <div v-for="msg in messages" :key="msg.id" class="border-b py-2">

                                <div class="text-xs text-gray-400">
                                    {{ new Date(msg.createdAt).toLocaleString() }}
                                </div>

                                <div class="text-sm">
                                    <span class="font-semibold">
                                        {{ msg.sender?.username }}
                                    </span>

                                    : {{ msg.content }}
                                </div>

                            </div>
                        </div>

                    </div>

                    <!-- Export -->
                    <div class="flex gap-4">

                        <button class="bg-green-600 text-white px-4 py-2 rounded" @click="exportCSV">
                            Export CSV
                        </button>

                        <button class="bg-red-600 text-white px-4 py-2 rounded" @click="exportPDF">
                            Export PDF
                        </button>

                    </div>

                </div>

            </div>
        </main>

    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRuntimeConfig } from '#app'
useHead({
    title: 'Investigation Management • Admin',
    link: [
        { rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }
    ]
})
const route = useRoute()
const apiBase = useRuntimeConfig().public.apiBase

const investigation = ref({})
const messages = ref([])
const loading = ref(true)

function formatTime(date) {
    return new Date(date).toLocaleString()
}

async function loadData() {

    const res = await fetch(
        `${apiBase}admin/investigations/${route.params.id}`
    )

    const data = await res.json()

    investigation.value = data

    messages.value =
        data?.booking?.chatRoom?.messages || []

    loading.value = false
}

function exportCSV(){

  let csv = "time,sender,message\n"

  messages.value.forEach(m=>{
    csv += `${m.createdAt},${m.sender?.username},"${m.content}"\n`
  })

  const blob = new Blob([csv], {type:'text/csv'})
  const url = URL.createObjectURL(blob)

  const a = document.createElement('a')
  a.href = url
  a.download = `chatlog-${route.params.id}.csv`
  a.click()

}

async function exportChatLog(id) {
  await fetch(`${apiBase}admin/investigations/${id}/export`, {
    method: "POST"
  })
}

onMounted(loadData)

</script>