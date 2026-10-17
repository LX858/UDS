<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import PropManagerWindow from './PropManagerWindow.vue'
import { useNuiEvent } from '../composables/useNuiEvent'
import { useApi } from '../composables/useApi'
import { usePropManagerStore, type PropEntry } from '../stores/propmanager.store'
import { usePlayerAccessStore, type PlayerAccessEntry } from '../stores/playeraccess.store'
import { useAddPropStore } from '../stores/addprop.store'
import { useLocaleStore, type UILocales } from '../stores/locale.store'

const propStore = usePropManagerStore()
const accessStore = usePlayerAccessStore()
const addPropStore = useAddPropStore()
const localeStore = useLocaleStore()

const windowVisible = ref(false)
const activeTab = ref<'props' | 'add-prop' | 'map' | 'permissions'>('props')
const level = ref(0)

interface OpenPropManagerPayload {
  level: number
  props: PropEntry[]
  groupStates: Record<string, boolean>
  playerAccess?: PlayerAccessEntry[]
  groups?: string[]
  locales?: UILocales
}

function applyPayload(data: OpenPropManagerPayload) {
  level.value = data.level ?? 0
  propStore.props = (data.props ?? []).map((p) => ({ ...p, outlined: p.outlined ?? false }))
  propStore.groupStates = data.groupStates ?? {}
  propStore.applyGroupDefaults(propStore.groupStates)
  if (data.playerAccess) accessStore.entries = data.playerAccess
  if (data.groups) accessStore.availableGroups = data.groups
  addPropStore.allowedGroups = data.level === 0 ? (data.playerAccess?.[0]?.groups ?? []) : []
  addPropStore.maxExpiry     = data.level === 0 ? (data.playerAccess?.[0]?.maxExpiry ?? null) : null
  if (data.locales) localeStore.setLocales(data.locales)
}

useNuiEvent<OpenPropManagerPayload>('openPropManager', (data) => {
  applyPayload(data)
  activeTab.value = 'props'
  windowVisible.value = true
})

useNuiEvent<PropEntry>('addProp', (prop) => {
  if (!propStore.props.find((p) => p.id === prop.id)) {
    propStore.props.push({ ...prop, outlined: false })
  }
})

useNuiEvent<PropEntry>('updateProp', (prop) => {
  const idx = propStore.props.findIndex((p) => p.id === prop.id)
  if (idx !== -1) {
    propStore.props[idx] = { ...prop, outlined: propStore.props[idx].outlined }
  }
})

useNuiEvent<{ ids: number[] }>('removeProps', ({ ids }) => {
  const set = new Set(ids)
  propStore.props = propStore.props.filter((p) => !set.has(p.id))
})

useNuiEvent<Record<string, boolean>>('updateGroupStates', (groupStates) => {
  propStore.groupStates = groupStates
  propStore.applyGroupDefaults(groupStates)
})

useNuiEvent<PlayerAccessEntry>('playerAccessSaved', (entry) => {
  accessStore.entries.push(entry)
})

useNuiEvent('closePropManager', () => {
  windowVisible.value = false
})

function closeWindow() {
  useApi('ClosePropManager', { method: 'POST', body: '{}' }, undefined, {}).then(() => {
    windowVisible.value = false
  })
}

function onKeydown(e: KeyboardEvent) {
  if (!windowVisible.value) return
  if (e.key === 'Escape' || e.key === 'Backspace') {
    const tag = (document.activeElement as HTMLElement)?.tagName
    if (tag !== 'INPUT' && tag !== 'TEXTAREA') closeWindow()
  }
}

onMounted(() => window.addEventListener('keydown', onKeydown))
onUnmounted(() => window.removeEventListener('keydown', onKeydown))
</script>

<template>
  <Transition name="window-fade">
    <PropManagerWindow
      v-show="windowVisible"
      v-model:activeTab="activeTab"
      :level="level"
      @close="closeWindow"
    />
  </Transition>
</template>

<style>
.window-fade-enter-active,
.window-fade-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}
.window-fade-enter-from,
.window-fade-leave-to {
  opacity: 0;
  transform: scale(0.97);
}
</style>
