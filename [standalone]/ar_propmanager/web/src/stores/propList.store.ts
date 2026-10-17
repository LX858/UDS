import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useApi } from '../composables/useApi'

export interface PropEntry {
  id: string
  handle: number
  model: string
  position: { x: number; y: number; z: number }
  group: string
  outlined: boolean
}

export const usePropListStore = defineStore('propList', () => {
  const isVisible = ref(false)
  const props = ref<PropEntry[]>([])

  const groups = computed(() => {
    const map = new Map<string, PropEntry[]>()
    for (const prop of props.value) {
      if (!map.has(prop.group)) map.set(prop.group, [])
      map.get(prop.group)!.push(prop)
    }
    return map
  })

  return { isVisible, props, groups}
})
