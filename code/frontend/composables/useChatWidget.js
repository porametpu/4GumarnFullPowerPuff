import { useState } from '#app'

export const useChatWidget = () => {
    const isWidgetOpen = useState('chatWidgetOpen', () => false)
    const isWidgetMinimized = useState('chatWidgetMinimized', () => false)
    const activeBookingId = useState('chatWidgetBookingId', () => null)
    const totalUnreadCount = useState('chatTotalUnreadCount', () => 0)

    const { $api } = useNuxtApp()

    const refreshUnreadCount = async () => {
        try {
            const token = useCookie('token').value
            if (!token) return

            const res = await $api('/chats/history')
            const rooms = res || []

            let count = 0
            let lastRoomWithUnread = null

            rooms.forEach(room => {
                count += room.unreadCount || 0
                if (room.unreadCount > 0) {
                    lastRoomWithUnread = room
                }
            });

            totalUnreadCount.value = count

            if (count > 0 && !isWidgetOpen.value && !activeBookingId.value && lastRoomWithUnread) {
                activeBookingId.value = lastRoomWithUnread.bookingId
                isWidgetOpen.value = true
                isWidgetMinimized.value = true
            }
        } catch (error) {
            console.error('Failed to refresh unread count:', error)
        }
    }

    const openChat = (bookingId) => {
        activeBookingId.value = bookingId
        isWidgetOpen.value = true
        isWidgetMinimized.value = false
    }

    const minimizeChat = () => {
        isWidgetMinimized.value = true
    }

    const maximizeChat = () => {
        isWidgetMinimized.value = false
    }

    const closeChat = () => {
        isWidgetOpen.value = false
        activeBookingId.value = null
        isWidgetMinimized.value = false
    }

    const markRoomAsRead = async (roomId) => {
        if (!roomId) return
        try {
            await $api(`/chats/${roomId}/read`, { method: 'POST' })
            await refreshUnreadCount()
        } catch (error) {
            console.error('Failed to mark room as read:', error)
        }
    }

    return {
        isWidgetOpen,
        isWidgetMinimized,
        activeBookingId,
        totalUnreadCount,
        openChat,
        minimizeChat,
        maximizeChat,
        closeChat,
        refreshUnreadCount,
        markRoomAsRead
    }
}
