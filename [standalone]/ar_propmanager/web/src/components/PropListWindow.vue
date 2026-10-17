<script setup lang="ts">
import { ref } from 'vue'
import { storeToRefs } from 'pinia'
import { usePropManagerStore } from '../stores/propmanager.store'
import { useLocaleStore } from '../stores/locale.store'

const props = defineProps<{ canManage: boolean; canEdit: boolean; canTeleport: boolean; canDelete: boolean }>()

const pmStore = usePropManagerStore()
const { locales: l } = storeToRefs(useLocaleStore())

// --- Helpers ------------------------------------------------------------------

type PropPosition = { x: number; y: number; z: number }

const fmtPos = (p: PropPosition) =>
  `${p.x.toFixed(1)},  ${p.y.toFixed(1)},  ${p.z.toFixed(1)}`

const fmtExpiry = (epoch: number) => {
  const d = new Date(epoch * 1000)
  const dd   = String(d.getDate()).padStart(2, '0')
  const mm   = String(d.getMonth() + 1).padStart(2, '0')
  const yyyy = d.getFullYear()
  const hh   = String(d.getHours()).padStart(2, '0')
  const min  = String(d.getMinutes()).padStart(2, '0')
  return `${dd}/${mm}/${yyyy} ${hh}:${min}`
}

const pendingDelete = ref<number | null>(null)

const requestDelete = (id: number) => {
  if (pendingDelete.value === id) {
    pmStore.deleteProp(id)
    pendingDelete.value = null
  } else {
    pendingDelete.value = id
  }
}

const cancelDelete = () => {
  pendingDelete.value = null
}

const isGroupEnabled = (name: string) => pmStore.groupStates[name] !== false
</script>

<template>
  <div class="flex h-[50vh] flex-col" @mousedown="cancelDelete">
    <!-- Prop list -->
    <div class="min-h-0 flex-1 overflow-y-auto">
      <div v-if="pmStore.groups.size === 0" class="py-8 text-center text-xs text-slate-500">
        {{ l.ui_no_props_found }}
      </div>

      <div v-for="[groupName, groupProps] in pmStore.groups" :key="groupName">
        <!-- Group header -->
        <div
          class="flex w-full items-center border-b border-white/5 bg-white/5 px-3 py-2 text-xs"
          :class="{ 'opacity-50': !isGroupEnabled(groupName) }"
        >
          <!-- Collapse toggle -->
          <button
            class="flex flex-1 items-center gap-2 text-left font-semibold uppercase tracking-wider text-slate-400 transition hover:text-slate-200"
            @click.stop="pmStore.toggleCollapsed(groupName)"
          >
            <i
              :class="pmStore.collapsedGroups.has(groupName) ? 'pi-chevron-right' : 'pi-chevron-down'"
              class="pi text-[0.7rem] text-slate-500"
            />
            {{ groupName }}
            <span class="rounded-full bg-white/10 px-1.5 py-0.5 text-[0.7rem] font-normal text-slate-400">
              {{ groupProps.length }}
            </span>
          </button>

          <!-- Group state badge + toggle -->
          <div class="flex shrink-0 items-center gap-1.5">
            <span
              class="rounded px-1.5 py-0.5 text-[0.7rem] font-medium"
              :class="isGroupEnabled(groupName)
                ? 'bg-green-500/15 text-green-400'
                : 'bg-white/5 text-slate-500'"
            >
              {{ isGroupEnabled(groupName) ? l.ui_group_active : l.ui_group_inactive }}
            </span>
            <button
              class="rounded p-1 transition hover:bg-white/10"
              :class="isGroupEnabled(groupName) ? 'text-green-400 hover:text-green-300' : 'text-slate-500 hover:text-slate-300'"
              @click.stop="pmStore.toggleGroup(groupName, !isGroupEnabled(groupName))"
            >
              <i class="pi pi-power-off text-xs" />
            </button>
          </div>
        </div>

        <!-- Prop rows -->
        <template v-if="!pmStore.collapsedGroups.has(groupName)">
          <div
            v-for="prop in groupProps"
            :key="prop.id"
            class="flex items-center gap-2 border-b border-white/5 px-4 py-2 text-xs transition"
            :class="[
              isGroupEnabled(groupName) ? 'hover:bg-white/5' : 'opacity-40',
              prop.outlined ? 'bg-yellow-500/5 ring-1 ring-inset ring-yellow-500/20' : '',
            ]"
          >

            <!-- Model + position stacked -->
            <div class="flex min-w-0 flex-1 flex-col gap-0.5">
              <span class="truncate font-mono text-xs text-slate-200">{{ prop.model }}</span>
              <span class="truncate font-mono text-[0.7rem] text-slate-500">{{ fmtPos(prop.position) }}</span>
            </div>

            <!-- Badges + actions -->
            <div class="flex shrink-0 items-center gap-2">
              <!-- Render distance -->
              <span
                v-if="prop.renderDistance"
                class="rounded bg-white/5 px-1.5 py-0.5 text-[0.7rem] text-slate-500"
              >{{ prop.renderDistance }}m</span>

              <!-- Expiry -->
              <span
                v-if="prop.expiresAt"
                class="rounded px-1.5 py-0.5 text-[0.7rem]"
                :class="prop.expiresAt * 1000 < Date.now()
                  ? 'bg-red-500/20 text-red-400'
                  : 'bg-amber-500/15 text-amber-400'"
              >
                <i class="pi pi-clock mr-0.5 text-[0.6rem]" />{{ fmtExpiry(prop.expiresAt) }}
              </span>

              <div class="flex items-center gap-1">
                <!-- Teleport -->
                <button
                  v-if="props.canTeleport"
                  class="rounded px-2 py-1 text-slate-400 transition hover:bg-white/10 hover:text-slate-100"
                  :disabled="!isGroupEnabled(groupName)"
                  @click.stop="pmStore.teleport(prop.id)"
                >
                  <i class="pi pi-map-marker text-xs" />
                </button>

                <!-- Edit / move -->
                <button
                  v-if="props.canEdit"
                  class="rounded px-2 py-1 text-slate-400 transition hover:bg-white/10 hover:text-slate-100"
                  :disabled="!isGroupEnabled(groupName)"
                  @click.stop="pmStore.editProp(prop.id)"
                >
                  <i class="pi pi-arrows-alt text-xs" />
                </button>

                <!-- Outline -->
                <button
                  class="rounded px-2 py-1 transition hover:bg-white/10"
                  :disabled="!isGroupEnabled(groupName)"
                  :class="prop.outlined ? 'text-yellow-400 hover:text-yellow-300' : 'text-slate-400 hover:text-slate-100'"
                  @click.stop="pmStore.outline(prop.id)"
                >
                  <i class="pi pi-eye text-xs" />
                </button>

                <!-- Delete -->
                <button
                  v-if="props.canDelete"
                  class="rounded px-2 py-1 transition hover:bg-white/10"
                  :class="pendingDelete === prop.id ? 'text-red-400 hover:text-red-300' : 'text-slate-400 hover:text-slate-100'"
                  @mousedown.stop
                  @click.stop="requestDelete(prop.id)"
                >
                  <i class="pi text-xs" :class="pendingDelete === prop.id ? 'pi-exclamation-triangle' : 'pi-trash'" />
                </button>
              </div>
            </div>
          </div>
        </template>
      </div>
    </div>

    <!-- Footer: total count -->
    <div class="flex h-[3vh] shrink-0 items-center border-t border-white/5 px-4 text-[0.7rem] text-slate-600">
      {{ pmStore.props.length }} {{ pmStore.props.length !== 1 ? l.ui_props : l.ui_prop }} {{ l.ui_across }} {{ pmStore.groups.size }} {{ pmStore.groups.size !== 1 ? l.ui_groups : l.ui_group }}
    </div>
  </div>
</template>
