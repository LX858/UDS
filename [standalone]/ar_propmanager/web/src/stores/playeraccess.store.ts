import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useApi } from '../composables/useApi'

export type Zone = Array<{ x: number; y: number }>

export interface PlayerAccessEntry {
  id: number
  identifier: string
  name: string
  groups: string[]
  zones: Zone[]
  maxExpiry: number | null  // forced expiry duration in seconds, null = no limit
}

export interface OnlinePlayer {
  name: string
  identifier: string
}

const mockOnlinePlayers: OnlinePlayer[] = [
  { name: 'John Doe',      identifier: 'license:a1b2c3d4e5f6a1b2c3d4' },
  { name: 'Jane Smith',    identifier: 'license:f6e5d4c3b2a1f6e5d4c3' },
  { name: 'Bob Jones',     identifier: 'license:c3b2a1f6e5d4c3b2a1f6' },
  { name: 'Alice Walker',  identifier: 'license:1234567890abcdef1234' },
  { name: 'Charlie Brown', identifier: 'license:abcdef1234567890abcd' },
]

export const usePlayerAccessStore = defineStore('playerAccess', () => {
  const isVisible = ref(false)
  const entries = ref<PlayerAccessEntry[]>([])
  const availableGroups = ref<string[]>([])
  const onlinePlayers = ref<OnlinePlayer[]>([])
  const loadingPlayers = ref(false)

  const loadOnlinePlayers = () => {
    loadingPlayers.value = true
    useApi<OnlinePlayer[]>(
      'GetOnlinePlayers',
      { method: 'POST', body: JSON.stringify({}) },
      undefined,
      mockOnlinePlayers,
    ).then((result) => {
      onlinePlayers.value = result.data?.value ?? []
      loadingPlayers.value = false
    })
  }

  const addEntry = (data: Omit<PlayerAccessEntry, 'id'>) => {
    useApi<PlayerAccessEntry>(
      'AddPlayerAccess',
      { method: 'POST', body: JSON.stringify(data) },
      undefined,
      { id: Date.now(), ...data },
    ).then((result) => {
      const entry = result.data?.value
      if (entry && typeof entry === 'object' && 'id' in entry) {
        entries.value.push(entry as PlayerAccessEntry)
      }
    })
  }

  const updateEntry = (entry: PlayerAccessEntry) => {
    useApi<string>('UpdatePlayerAccess', { method: 'POST', body: JSON.stringify(entry) }, undefined, 'ok')
      .then(() => {
        const idx = entries.value.findIndex((e) => e.id === entry.id)
        if (idx !== -1) entries.value[idx] = entry
      })
  }

  const deleteEntry = (id: number) => {
    useApi<string>('DeletePlayerAccess', { method: 'POST', body: JSON.stringify({ id }) }, undefined, 'ok')
      .then(() => {
        entries.value = entries.value.filter((e) => e.id !== id)
      })
  }

  return { 
    isVisible, 
    entries, 
    availableGroups, 
    onlinePlayers, 
    loadingPlayers, 
    loadOnlinePlayers, 
    addEntry, 
    updateEntry, 
    deleteEntry 
  }
})
