import { useCookie } from '#app'
import { useRouter } from 'vue-router'
import { useChatWidget } from './useChatWidget'

export function useAuth() {
  const { $api } = useNuxtApp()

  const cookieOpts = {
    maxAge: 60 * 60 * 24 * 7,
    path: '/',
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production'
  }
  const token = useCookie('token', cookieOpts)
  const user = useCookie('user', cookieOpts)
  // const token = useCookie('token', { maxAge: 60 * 60 * 24 * 7, secure: true })
  // const user = useCookie('user', { maxAge: 60 * 60 * 24 * 7, secure: true })
  const router = useRouter()

  const login = async (identifier, password) => {
    const payload = { password }
    if (identifier.includes('@')) {
      payload.email = identifier
    } else {
      payload.username = identifier
    }

    const res = await $api('/auth/login', {
      method: 'POST',
      body: payload
    })
    token.value = res.token
    user.value = res.user
    return res
  }

  // const register = async (email, password, firstName, lastName) => {
  //   const res = await $api('/users', {
  //     method: 'POST',
  //     body: { email, password, firstName, lastName }
  //   })
  //   return res
  // }

  const register = async (formData) => {
    const res = await $api('/users', {
      method: 'POST',
      body: formData // ส่ง FormData ไปทั้งก้อน ไม่ต้องแปลงเป็น JSON
    })
    return res
  }

  const logout = () => {
    token.value = null
    user.value = null

    // Force close chat widget by clearing the global state
    try {
      const activeBookingId = useChatWidget().activeBookingId
      if (activeBookingId) activeBookingId.value = null

      const isWidgetOpen = useChatWidget().isWidgetOpen
      if (isWidgetOpen) isWidgetOpen.value = false
    } catch (e) { }

    return router.push('/')
  }

  return { token, user, login, logout, register }
}
