<template>
    <div>
        <NuxtLayout>
            <NuxtPage />
        </NuxtLayout>
        <ToastWrapper />
        <FloatingChat />
        <NearAlertOverlay />
    </div>
</template>

<script setup>
import ToastWrapper from '~/components/ToastWrapper.vue';
import FloatingChat from '~/components/FloatingChat.vue';
import NearAlertOverlay from '~/components/NearAlertOverlay.vue';
</script>