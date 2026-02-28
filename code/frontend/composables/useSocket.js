import { io } from 'socket.io-client'
import { ref } from 'vue'

const socketRef = ref(null)

export const useSocket = () => {
    const config = useRuntimeConfig()

    const connect = () => {
        // client-side
        if (process.server) return null

        if (socketRef.value?.connected) {
            return socketRef.value
        }

        let socketUrl = config.public.apiBase.replace('/api', '')
        if (socketUrl.endsWith('//')) socketUrl = socketUrl.slice(0, -1)

        if (!socketRef.value) {
            console.log('[Socket.io] Initializing connection to:', socketUrl)
            socketRef.value = io(socketUrl, {
                transports: ['polling', 'websocket'],
                withCredentials: true,
                reconnection: true,
                reconnectionAttempts: 10,
                reconnectionDelay: 1000,
                autoConnect: true
            })

            socketRef.value.on('connect', () => {
                console.log('%c[Socket.io] Connected! ID:', 'color: #00c853; font-weight: bold;', socketRef.value.id)

                // Re-join user room on reconnect
                const userCookie = useCookie('user').value
                if (userCookie?.id) {
                    socketRef.value.emit('join-user', userCookie.id)
                }
            })

            socketRef.value.on('connect_error', (error) => {
                console.error('[Socket.io] Connection error:', error.message)
            })
        } else if (!socketRef.value.connected) {
            socketRef.value.connect()
        }

        return socketRef.value
    }

    const joinRoom = (roomId) => {
        if (process.server) return
        const s = socketRef.value || connect()
        if (s) {
            console.log('[Socket.io] Joining room:', roomId)
            s.emit('join-room', roomId)
        }
    }

    const joinUser = (userId) => {
        if (process.server) return
        const s = socketRef.value || connect()
        if (s) {
            console.log('[Socket.io] Joining personal room:', userId)
            s.emit('join-user', userId)
        }
    }

    const disconnect = () => {
        if (process.server) return
        if (socketRef.value) {
            socketRef.value.disconnect()
            socketRef.value = null
        }
    }

    return {
        socket: socketRef,
        connect,
        joinRoom,
        joinUser,
        disconnect
    }
}
