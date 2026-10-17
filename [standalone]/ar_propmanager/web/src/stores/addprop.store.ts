import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAddPropStore = defineStore('addProp', () => {
  const allowedGroups = ref<string[]>([])   // non-empty = restricted to these groups only
  const maxExpiry     = ref<number | null>(null)  // forced expiry in seconds, null = no limit

  return { allowedGroups, maxExpiry }
})
