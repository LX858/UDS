import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useApi } from '../composables/useApi'

export interface PropEntry {
  id: number
  model: string
  position: { x: number; y: number; z: number }
  quaternion?: { x: number; y: number; z: number; w: number }
  group: string
  outlined: boolean
  renderDistance?: number
  expiresAt?: number | null
}

export const usePropManagerStore = defineStore('propManager', () => {
  const isVisible = ref(false)
  const props = ref<PropEntry[]>([])
  const groupStates = ref<Record<string, boolean>>({})
  const collapsedGroups = ref(new Set<string>())
  const seenGroups = ref(new Set<string>())

  const applyGroupDefaults = (newStates: Record<string, boolean>) => {
    for (const [name, enabled] of Object.entries(newStates)) {
      if (!seenGroups.value.has(name)) {
        if (!enabled) collapsedGroups.value = new Set([...collapsedGroups.value, name])
        seenGroups.value = new Set([...seenGroups.value, name])
      }
    }
  }

  const toggleCollapsed = (name: string) => {
    const next = new Set(collapsedGroups.value)
    if (next.has(name)) next.delete(name)
    else next.add(name)
    collapsedGroups.value = next
  }

  const groups = computed(() => {
    const map = new Map<string, PropEntry[]>()
    for (const prop of props.value) {
      if (!map.has(prop.group)) map.set(prop.group, [])
      map.get(prop.group)!.push(prop)
    }
    return new Map([...map.entries()].sort(([a], [b]) => a.localeCompare(b)))
  })

  const teleport = (id: number) => {
    useApi('TeleportToProp', { method: 'POST', body: JSON.stringify({ id }) }, undefined, {})
  }

  const editProp = (id: number) => {
    useApi('EditProp', { method: 'POST', body: JSON.stringify({ id }) }, undefined, {})
  }

  const outline = (id: number) => {
    useApi<string>('OutlineProp', { method: 'POST', body: JSON.stringify({ id }) }, undefined, 'ok')
      .then(() => {
        const prop = props.value.find((p) => p.id === id)
        if (prop) prop.outlined = !prop.outlined
      })
  }

  const deleteProp = (id: number) => {
    useApi<string>('DeleteProp', { method: 'POST', body: JSON.stringify({ id }) }, undefined, 'ok')
      .then(() => {
        props.value = props.value.filter((p) => p.id !== id)
      })
  }

  const outlineAll = () => {
    const target = !props.value.every((p) => p.outlined)
    useApi<string>('OutlineAllProps', { method: 'POST', body: JSON.stringify({ outlined: target }) }, undefined, 'ok')
      .then(() => {
        for (const prop of props.value) prop.outlined = target
      })
  }

  const toggleGroup = (group: string, enabled: boolean) => {
    useApi<string>('ToggleGroup', { method: 'POST', body: JSON.stringify({ group, enabled }) }, undefined, 'ok')
      .then(() => {
        groupStates.value = { ...groupStates.value, [group]: enabled }
      })
  }

  return { 
    isVisible, 
    props, 
    groupStates, 
    groups, 
    collapsedGroups, 
    applyGroupDefaults, 
    toggleCollapsed, 
    teleport, 
    editProp, 
    outline, 
    outlineAll, 
    deleteProp, 
    toggleGroup 
  }
})
