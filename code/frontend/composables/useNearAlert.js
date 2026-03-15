import { useState } from '#app'

export const useNearAlert = () => {
    const activeAlert = useState('nearAlertActive', () => null)

    const showAlert = (data) => {
        activeAlert.value = data
        
        // Play Alert Sound
        if (process.client) {
            const audio = new Audio('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3')
            audio.volume = 0.5
            audio.play().catch(e => console.log('Sound play blocked by browser policy:', e))
        }

        // Browser Native Notification
        if (process.client && 'Notification' in window) {
            if (Notification.permission === 'granted') {
                new Notification(data.title, {
                    body: data.message,
                    icon: '/favicon.ico' // adjust if needed
                });
            } else if (Notification.permission !== 'denied') {
                Notification.requestPermission().then(permission => {
                    if (permission === 'granted') {
                        new Notification(data.title, {
                            body: data.message,
                        });
                    }
                });
            }
        }
    }

    const closeAlert = () => {
        activeAlert.value = null
    }

    return {
        activeAlert,
        showAlert,
        closeAlert
    }
}
