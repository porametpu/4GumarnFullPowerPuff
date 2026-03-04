<template>
    <div>
        <NuxtLayout>
            <NuxtPage />
        </NuxtLayout>
        <FloatingChat />
        <ToastWrapper />
    </div>
</template>

<script setup>
import ToastWrapper from '~/components/ToastWrapper.vue';
import FloatingChat from '~/components/FloatingChat.vue';
</script>