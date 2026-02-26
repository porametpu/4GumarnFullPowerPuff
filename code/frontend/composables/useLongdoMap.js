import { useRuntimeConfig } from '#app'

let loadPromise = null

export const useLongdoMap = () => {
  const config = useRuntimeConfig()

  const loadLongdoMap = () => {
    if (!process.client) return Promise.resolve(null)
    if (window.longdo) return Promise.resolve(window.longdo)
    if (loadPromise) return loadPromise

    const key = config.public.longdoMapApiKey
    loadPromise = new Promise((resolve, reject) => {
      if (!key) {
        reject(new Error('NUXT_PUBLIC_LONGDO_MAP_API_KEY is missing'))
        return
      }
      const script = document.createElement('script')
      script.src = `https://api.longdo.com/map/?key=${key}`
      script.async = true
      script.defer = true
      script.onload = () => resolve(window.longdo)
      script.onerror = () => reject(new Error('Failed to load Longdo Map script'))
      document.head.appendChild(script)
    })

    return loadPromise
  }

  return { loadLongdoMap }
}
