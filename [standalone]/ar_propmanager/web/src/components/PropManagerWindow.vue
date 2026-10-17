<script setup lang="ts">
import { computed, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { useDraggable } from '@vueuse/core'
import PropListWindow from './PropListWindow.vue'
import AddPropWindow from './AddPropWindow.vue'
import PlayerAccessWindow from './PlayerAccessWindow.vue'
import PropMapWindow from './PropMapWindow.vue'
import { useLocaleStore } from '../stores/locale.store'

type Tab = 'props' | 'add-prop' | 'map' | 'permissions'

const props = defineProps<{
  activeTab: Tab
  level: number
}>()

const emit = defineEmits<{
  'update:activeTab': [tab: Tab]
  close: []
}>()

// --- Draggable window ---------------------------------------------------------

const titleBar = ref<HTMLElement | null>(null)
const windowEl = ref<HTMLElement | null>(null)

const { style } = useDraggable(windowEl, {
  handle: titleBar,
  initialValue: {
    x: Math.max(0, (window.innerWidth - Math.min(620, Math.max(440, window.innerWidth * 0.35))) / 2),
    y: Math.round(window.innerHeight * 0.1),
  },
})

const canAdd = computed(() => props.level >= 2 || props.level === 0)

const { locales: l } = storeToRefs(useLocaleStore())

const ALL_TABS = computed(() => [
  { key: 'props'       as Tab, label: l.value.ui_tab_props,         icon: 'pi-list'  },
  { key: 'add-prop'    as Tab, label: l.value.ui_tab_add_prop,      icon: 'pi-plus'  },
  { key: 'map'         as Tab, label: l.value.ui_tab_map,           icon: 'pi-map'   },
  { key: 'permissions' as Tab, label: l.value.ui_tab_player_access, icon: 'pi-users' },
])

const visibleTabs = computed(() =>
  ALL_TABS.value.filter((tab) => {
    if (tab.key === 'props')       return props.level >= 1 || props.level === 0
    if (tab.key === 'add-prop')    return canAdd.value
    if (tab.key === 'map')         return props.level >= 2
    if (tab.key === 'permissions') return props.level >= 3 || props.level === 0
    return false
  })
)
</script>

<template>
  <div
    ref="windowEl"
    :style="style"
    class="fixed z-20 flex max-h-[85vh] w-[clamp(440px,35vw,620px)] flex-col overflow-hidden rounded-xl border border-white/10 bg-black/85 text-white shadow-2xl"
  >
      <!-- Title bar -->
      <div
        ref="titleBar"
        class="flex cursor-grab select-none items-center justify-between border-b border-white/10 px-4 py-2.5 active:cursor-grabbing"
      >
        <div class="flex items-center gap-2 text-sm font-semibold text-slate-200">
          <i class="pi pi-objects-column text-slate-400" />
          {{ l.ui_window_title }}
        </div>
        <button
          class="rounded p-1 text-slate-500 transition hover:text-slate-200"
          @click.stop="emit('close')"
        >
          <i class="pi pi-times text-xs" />
        </button>
      </div>

      <!-- Tab strip -->
      <div v-if="visibleTabs.length > 1" class="flex border-b border-white/10 bg-white/3">
        <button
          v-for="tab in visibleTabs"
          :key="tab.key"
          class="flex items-center gap-1.5 px-4 py-2 text-xs font-medium transition"
          :class="activeTab === tab.key
            ? 'border-b-2 border-blue-400 text-blue-400'
            : 'text-slate-400 hover:text-slate-200'"
          @click="emit('update:activeTab', tab.key)"
        >
          <i :class="`pi ${tab.icon} text-xs`" />
          {{ tab.label }}
        </button>
      </div>

      <!-- Tab content -->
      <div class="flex min-h-0 flex-1 flex-col overflow-hidden">
        <PropListWindow
          v-if="activeTab === 'props'"
          :can-manage="level >= 2"
          :can-delete="level >= 2 || level === 0"
          :can-edit="level >= 2 || level === 0"
          :can-teleport="level >= 1"
        />
        <AddPropWindow
          v-else-if="activeTab === 'add-prop'"
          @done="emit('update:activeTab', 'props')"
        />
        <PropMapWindow      v-else-if="activeTab === 'map'" />
        <PlayerAccessWindow v-else :level="level" />
      </div>
    </div>
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
