import { useState } from '#app'

export const useNearAlert = () => {
    const activeAlert = useState('nearAlertActive', () => null)

    const requestPermission = async () => {
        if (process.client && 'Notification' in window) {
            if (Notification.permission !== 'granted' && Notification.permission !== 'denied') {
                await Notification.requestPermission();
            }
        }
    }

    const showAlert = (data) => {
        activeAlert.value = data
        
        // Play Alert Sound
        if (process.client) {
            // Use a more reliable sound URL or ensure it's loaded
            const audio = new Audio('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3')
            audio.volume = 0.7
            audio.play().catch(e => {
                console.log('Sound play blocked by browser policy. Interaction needed.', e)
            })
        }

        // Browser Native Notification (Outside the web page)
        if (process.client && 'Notification' in window) {
            if (Notification.permission === 'granted') {
                try {
                    const notification = new Notification(data.title || 'แจ้งเตือนจาก ไปนำแหน่', {
                        body: data.message,
                        icon: '/favicon.ico',
                        badge: '/favicon.ico',
                        vibrate: [200, 100, 200],
                        silent: false
                    });
                    
                    notification.onclick = () => {
                        window.focus();
                        closeAlert();
                    };
                } catch (err) {
                    console.error('Browser Notification Error:', err);
                }
            } else if (Notification.permission !== 'denied') {
                Notification.requestPermission().then(permission => {
                    if (permission === 'granted') {
                        new Notification(data.title, { body: data.message });
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
        closeAlert,
        requestPermission
    }
}
