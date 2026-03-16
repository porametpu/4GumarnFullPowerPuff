import { ref, computed } from 'vue'
import dayjs from 'dayjs'
import { useNuxtApp } from '#app'
import { useToast } from '~/composables/useToast'

const activeRoutes = ref([])
const isRefreshing = ref(false)
const lastRefreshTime = ref(null)

export const useDriverConsole = () => {
    const { $api } = useNuxtApp()
    const { toast } = useToast()

    const fetchActiveRoutes = async () => {
        try {
            isRefreshing.value = true
            const res = await $api('/routes/me', {
                query: {
                    status: 'AVAILABLE,FULL,IN_TRANSIT',
                    limit: 5
                }
            })
            
            const raw = Array.isArray(res) ? res : []
            
            // Format and Filter for "Today" routes primarily, but show all active
            activeRoutes.value = raw.map(r => {
                const start = r.startLocation || {}
                const end = r.endLocation || {}
                const confirmedBookings = (r.booking || []).filter(b => b.status === 'CONFIRMED')
                
                return {
                    id: r.id,
                    origin: start.name || 'Unknown',
                    destination: end.name || 'Unknown',
                    departureTime: r.departureTime,
                    timeText: dayjs(r.departureTime).format('HH:mm'),
                    dateText: dayjs(r.departureTime).format('D MMM'),
                    status: r.status,
                    passengers: confirmedBookings.map(b => ({
                        id: b.id,
                        bookingId: b.id,
                        name: `${b.passenger?.firstName || ''} ${b.passenger?.lastName?.charAt(0) || ''}.`.trim(),
                        image: b.passenger?.profilePicture,
                        pickupLocation: b.pickupLocation,
                        distance: null,
                        loading: false
                    })),
                    isExpanded: true
                }
            }).sort((a, b) => new Date(a.departureTime) - new Date(b.departureTime))
            
            lastRefreshTime.value = new Date()
        } catch (error) {
            console.error('Failed to fetch active routes for console:', error)
        } finally {
            isRefreshing.value = false
        }
    }

    const haversineDistance = (lat1, lon1, lat2, lon2) => {
        const R = 6371; // Earth radius in km
        const dLat = (lat2 - lat1) * Math.PI / 180;
        const dLon = (lon2 - lon1) * Math.PI / 180;
        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    };

    const updateDistances = async (routeId) => {
        if (!navigator.geolocation) return
        
        const route = activeRoutes.value.find(r => r.id === routeId)
        if (!route) return

        return new Promise((resolve) => {
            navigator.geolocation.getCurrentPosition(async (position) => {
                const { latitude, longitude } = position.coords;
                
                route.passengers.forEach(p => {
                    if (p.pickupLocation?.lat && p.pickupLocation?.lng) {
                        p.distance = haversineDistance(
                            latitude, longitude,
                            p.pickupLocation.lat, p.pickupLocation.lng
                        );
                    }
                });

                // Sort by distance
                route.passengers.sort((a, b) => (a.distance || 999) - (b.distance || 999));
                resolve(true)
            }, (err) => {
                console.error('Geolocation error:', err);
                resolve(false)
            });
        })
    }

    const notifyPassenger = async (routeId, passenger) => {
        try {
            passenger.loading = true
            
            // Try to get current position for accuracy
            let lat = 0, lng = 0
            try {
                const pos = await new Promise((resolve, reject) => {
                    navigator.geolocation.getCurrentPosition(resolve, reject, { timeout: 3000 })
                })
                lat = pos.coords.latitude
                lng = pos.coords.longitude
            } catch (e) {
                console.warn('Could not get precise location for notification, using 0,0')
            }

            await $api(`/routes/${routeId}/nearby-alert`, {
                method: 'POST',
                body: { 
                    bookingId: passenger.bookingId,
                    driverLat: lat,
                    driverLng: lng
                }
            })
            toast.success(`แจ้งเตือนคุณ ${passenger.name} เรียบร้อยแล้ว`)
        } catch (error) {
            toast.error(error?.data?.message || 'แจ้งเตือนไม่สำเร็จ')
        } finally {
            passenger.loading = false
        }
    }

    return {
        activeRoutes,
        isRefreshing,
        lastRefreshTime,
        fetchActiveRoutes,
        updateDistances,
        notifyPassenger
    }
}
