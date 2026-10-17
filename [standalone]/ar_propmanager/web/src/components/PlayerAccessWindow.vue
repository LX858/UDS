<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { storeToRefs } from 'pinia'
import { usePlayerAccessStore, type PlayerAccessEntry, type Zone, type OnlinePlayer } from '../stores/playeraccess.store'
import { useLocaleStore } from '../stores/locale.store'
import MapZonePicker from './MapZonePicker.vue'
import MapAreaViewer from './MapAreaViewer.vue'

const props = defineProps<{ level: number }>()

const store = usePlayerAccessStore()
const localeStore = useLocaleStore()
const { locales: l } = storeToRefs(localeStore)
const { t } = localeStore

// --- Restricted view (level 0) ------------------------------------------------

const myEntry = computed(() => store.entries[0] ?? null)

// --- Form state ---------------------------------------------------------------

const showForm = ref(false)
const editingId = ref<number | null>(null)

const EXPIRY_PRESETS: { label: string; value: number | null }[] = [
  { label: 'None',  value: null },
  { label: '1h',    value: 3600 },
  { label: '6h',    value: 21600 },
  { label: '12h',   value: 43200 },
  { label: '1d',    value: 86400 },
  { label: '3d',    value: 259200 },
  { label: '7d',    value: 604800 },
  { label: '30d',   value: 2592000 },
]

function formatExpiry(seconds: number | null): string {
  if (!seconds) return 'None'
  if (seconds < 3600)  return `${Math.round(seconds / 60)}m`
  if (seconds < 86400) return `${Math.round(seconds / 3600)}h`
  return `${Math.round(seconds / 86400)}d`
}

const emptyForm = () => ({
  name: '',
  identifier: '',
  groups: [] as string[],
  zones: [] as Zone[],
  draftZone: [] as Array<{ x: number; y: number }>,
  maxExpiry: null as number | null,
})

const form = reactive(emptyForm())

const openAdd = () => {
  Object.assign(form, emptyForm())
  editingId.value = null
  playerSearch.value = ''
  showForm.value = true
  store.loadOnlinePlayers()
}

const openEdit = (entry: PlayerAccessEntry) => {
  form.name       = entry.name
  form.identifier = entry.identifier
  form.groups     = [...(entry.groups ?? [])]
  form.zones      = entry.zones.map((z) => [...z])
  form.draftZone  = []
  form.maxExpiry  = entry.maxExpiry ?? null
  editingId.value = entry.id
  showForm.value  = true
}

const cancelForm = () => {
  showForm.value  = false
  editingId.value = null
}

const addDraftZone = () => {
  if (form.draftZone.length < 3) return
  form.zones.push([...form.draftZone])
  form.draftZone = []
}

// --- Online player picker -----------------------------------------------------

const playerSearch = ref('')

const filteredPlayers = computed(() => {
  const q = playerSearch.value.trim().toLowerCase()
  if (!q) return store.onlinePlayers
  return store.onlinePlayers.filter(
    (p) => p.name.toLowerCase().includes(q) || p.identifier.toLowerCase().includes(q)
  )
})

const selectPlayer = (p: OnlinePlayer) => {
  form.name          = p.name
  form.identifier    = p.identifier
  playerSearch.value = ''
}

// -----------------------------------------------------------------------------

const toggleGroup = (g: string) => {
  const idx = form.groups.indexOf(g)
  if (idx === -1) form.groups.push(g)
  else form.groups.splice(idx, 1)
}

const isDuplicate = computed(() =>
  !editingId.value &&
  !!form.identifier.trim() &&
  store.entries.some((e) => e.identifier === form.identifier.trim())
)

const submitForm = () => {
  if (!form.name.trim() || !form.identifier.trim() || form.groups.length === 0 || isDuplicate.value) return

  const payload = {
    name:       form.name.trim(),
    identifier: form.identifier.trim(),
    groups:     [...form.groups],
    zones:      form.zones,
    maxExpiry:  form.maxExpiry,
  }

  if (editingId.value) {
    store.updateEntry({ id: editingId.value, ...payload })
    const idx = store.entries.findIndex((e) => e.id === editingId.value)
    if (idx !== -1) store.entries[idx] = { id: editingId.value, ...payload }
  } else {
    store.addEntry(payload)
  }

  cancelForm()
}

// --- Confirm delete -----------------------------------------------------------

const pendingDelete = ref<number | null>(null)

const requestDelete = (id: number) => {
  if (pendingDelete.value === id) {
    store.deleteEntry(id)
    pendingDelete.value = null
  } else {
    pendingDelete.value = id
  }
}
</script>

<template>
  <!-- --- Restricted access view (level 0) ------------------------------------ -->
  <div v-if="props.level === 0" class="flex min-h-[50vh] flex-col">
    <div class="flex items-center gap-2 border-b border-white/10 px-4 py-2.5">
      <i class="pi pi-lock text-amber-400 text-xs" />
      <span class="text-xs font-semibold text-amber-300">{{ l.ui_restricted_access }}</span>
    </div>

    <div v-if="myEntry" class="flex flex-1 flex-col gap-3 p-4">
      <p class="text-xs text-slate-400">
        {{ l.ui_restricted_desc }}
      </p>

      <!-- Groups -->
      <div class="flex flex-col gap-1">
        <span class="text-xs text-slate-500">{{ l.ui_accessible_groups }}</span>
        <div class="flex flex-wrap gap-1">
          <span
            v-for="g in myEntry.groups"
            :key="g"
            class="rounded bg-blue-600/30 px-2 py-0.5 text-xs text-blue-300 ring-1 ring-blue-500/30"
          >
            {{ g }}
          </span>
        </div>
      </div>

      <!-- Forced expiry -->
      <div v-if="myEntry.maxExpiry" class="flex flex-col gap-1">
        <span class="text-xs text-slate-500">{{ l.ui_forced_expiry }}</span>
        <span class="text-xs text-amber-300">{{ t('ui_forced_expiry_player_desc', formatExpiry(myEntry.maxExpiry)) }}</span>
      </div>

      <!-- Zones — grows to fill whatever space remains -->
      <div class="flex min-h-0 flex-1 flex-col gap-1">
        <span class="text-xs text-slate-500">{{ l.ui_zone_restrictions }}</span>
        <div v-if="!myEntry.zones.length" class="text-xs text-slate-400">{{ l.ui_no_zone_restriction }}</div>
        <MapAreaViewer v-else :zones="myEntry.zones" />
      </div>
    </div>

    <div v-else class="py-8 text-center text-xs text-slate-500">
      {{ l.ui_no_access_entry }}
    </div>
  </div>

  <!-- --- Full management view (level >= 3) ----------------------------------- -->
  <div v-else class="flex min-h-[50vh] flex-col" @mousedown="pendingDelete = null">
    <!-- Toolbar -->
    <div class="flex items-center justify-between border-b border-white/10 px-4 py-2">
      <span class="text-xs text-slate-500">{{ store.entries.length }} {{ store.entries.length !== 1 ? l.ui_players : l.ui_player }} {{ l.ui_with_access }}</span>
      <button
        class="flex items-center gap-1.5 rounded bg-white/10 px-2.5 py-1 text-xs text-slate-300 transition hover:bg-white/20"
        @click.stop="openAdd"
      >
        <i class="pi pi-plus text-[0.7rem]" />
        {{ l.ui_grant_access }}
      </button>
    </div>

    <!-- Add / Edit form -->
    <Transition name="form-slide">
      <div v-if="showForm" class="border-b border-white/10 bg-white/5 p-4">
        <div class="mb-3 text-xs font-semibold text-slate-300">{{ editingId ? l.ui_edit_access_entry : l.ui_grant_player_access }}</div>

        <div class="mb-2 flex flex-col gap-2">
          <!-- Player selector (new entry) -->
          <div v-if="!editingId" class="flex flex-col gap-1">
            <label class="text-xs text-slate-400">{{ l.ui_player_label }}</label>
            <!-- Selected player chip -->
            <div
              v-if="form.name && form.identifier"
              class="flex items-center gap-2 rounded border border-white/10 bg-white/5 px-2.5 py-1.5"
            >
              <div class="flex min-w-0 flex-1 flex-col">
                <span class="text-xs font-medium text-slate-100">{{ form.name }}</span>
                <span class="truncate font-mono text-[0.65rem] text-slate-500">{{ form.identifier }}</span>
              </div>
              <button
                type="button"
                class="shrink-0 text-slate-500 transition hover:text-slate-300"
                @click.stop="form.name = ''; form.identifier = ''"
              >
                <i class="pi pi-times text-[0.7rem]" />
              </button>
            </div>
            <!-- Search + dropdown -->
            <template v-else>
              <input
                v-model="playerSearch"
                type="text"
                :placeholder="l.ui_search_players_placeholder"
                class="rounded border border-white/10 bg-white/5 px-2 py-1 text-xs text-slate-100 outline-none transition placeholder:text-slate-600 focus:border-white/25 focus:bg-white/10"
              />
              <div class="flex max-h-32 flex-col overflow-y-auto rounded border border-white/10 bg-black/40">
                <div v-if="store.loadingPlayers" class="py-3 text-center text-xs text-slate-500">{{ l.ui_loading }}</div>
                <div v-else-if="filteredPlayers.length === 0" class="py-3 text-center text-xs text-slate-500">
                  {{ playerSearch ? l.ui_no_players_found : l.ui_no_players_online }}
                </div>
                <button
                  v-for="p in filteredPlayers"
                  :key="p.identifier"
                  type="button"
                  class="flex flex-col px-2.5 py-1.5 text-left transition hover:bg-white/10"
                  @click.stop="selectPlayer(p)"
                >
                  <span class="text-xs text-slate-200">{{ p.name }}</span>
                  <span class="truncate font-mono text-[0.65rem] text-slate-500">{{ p.identifier }}</span>
                </button>
              </div>
            </template>
          </div>

          <!-- Readonly player info (edit entry) -->
          <div v-else class="flex flex-col gap-1">
            <label class="text-xs text-slate-400">{{ l.ui_player_label }}</label>
            <div class="rounded border border-white/10 bg-white/5 px-2.5 py-1.5">
              <span class="text-xs font-medium text-slate-100">{{ form.name }}</span>
              <div class="mt-0.5 truncate select-all font-mono text-[0.65rem] text-slate-500">{{ form.identifier }}</div>
            </div>
          </div>

          <!-- Groups -->
          <div class="flex flex-col gap-1">
            <label class="text-xs text-slate-400">
              {{ l.ui_default_groups }}
              <span v-if="form.groups.length" class="ml-1 text-slate-500">({{ form.groups.length }} selected)</span>
            </label>
            <div class="flex flex-wrap gap-1">
              <button
                v-for="g in store.availableGroups"
                :key="g"
                type="button"
                class="rounded px-2 py-0.5 text-xs transition"
                :class="form.groups.includes(g)
                  ? 'bg-blue-600/60 text-blue-200 ring-1 ring-blue-500/40'
                  : 'bg-white/5 text-slate-400 hover:bg-white/10 hover:text-slate-200'"
                @click.stop="toggleGroup(g)"
              >
                {{ g }}
              </button>
            </div>
          </div>
        </div>

        <!-- Zone restrictions -->
        <div class="mb-1 flex items-center justify-between">
          <label class="text-xs text-slate-400">{{ l.ui_zone_restrictions }}</label>
          <span v-if="form.zones.length" class="text-[0.7rem] text-slate-500">
            {{ form.zones.length }} {{ form.zones.length !== 1 ? l.ui_zones : l.ui_zone }} {{ l.ui_saved }}
          </span>
        </div>
        <div class="rounded border border-white/10 bg-white/5 p-3">
          <MapZonePicker
            v-model="form.draftZone"
            :zones="form.zones"
            @delete-zone="form.zones.splice($event, 1)"
          />
          <button
            type="button"
            class="mt-2 w-full rounded bg-blue-600/40 py-1 text-xs text-blue-300 transition hover:bg-blue-600/60 disabled:opacity-40"
            :disabled="form.draftZone.length < 3"
            @click.stop="addDraftZone"
          >
            <i class="pi pi-plus mr-1 text-[0.7rem]" />
            {{ l.ui_add_zone }}
          </button>
          <p class="mt-1.5 text-[0.7rem] text-slate-500">
            {{ form.zones.length ? t('ui_player_restricted_zones', form.zones.length + ' ' + (form.zones.length !== 1 ? l.ui_zones : l.ui_zone)) : l.ui_no_zones_added }}
          </p>
        </div>

        <!-- Forced expiry -->
        <div class="mt-3">
          <label class="mb-1 block text-xs text-slate-400">{{ l.ui_force_expiry }}</label>
          <div class="flex flex-wrap gap-1">
            <button
              v-for="preset in EXPIRY_PRESETS"
              :key="String(preset.value)"
              type="button"
              class="rounded px-2.5 py-1 text-xs transition"
              :class="form.maxExpiry === preset.value
                ? 'bg-amber-600/50 text-amber-200 ring-1 ring-amber-500/40'
                : 'bg-white/5 text-slate-400 hover:bg-white/10 hover:text-slate-200'"
              @click.stop="form.maxExpiry = preset.value"
            >{{ preset.label }}</button>
          </div>
          <p v-if="form.maxExpiry" class="mt-1 text-[0.7rem] text-slate-500">
            {{ t('ui_player_expiry_desc', formatExpiry(form.maxExpiry)) }}
          </p>
        </div>

        <!-- Form actions -->
        <div class="mt-3 flex flex-col gap-2">
          <p v-if="isDuplicate" class="text-[0.7rem] text-red-400">
            <i class="pi pi-exclamation-circle mr-1 text-[0.65rem]" />
            {{ l.ui_duplicate_entry }}
          </p>
          <div class="flex justify-end gap-2">
            <button
              class="rounded bg-white/10 px-3 py-1.5 text-xs text-slate-300 transition hover:bg-white/20"
              @click="cancelForm"
            >
              {{ l.ui_cancel }}
            </button>
            <button
              class="rounded bg-blue-600/80 px-3 py-1.5 text-xs font-medium text-white transition hover:bg-blue-500/80 disabled:opacity-40"
              :disabled="!form.name.trim() || !form.identifier.trim() || form.groups.length === 0 || isDuplicate"
              @click="submitForm"
            >
              {{ editingId ? l.ui_save_changes : l.ui_grant_access }}
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Access list -->
    <div v-if="!showForm" class="max-h-[40vh] overflow-y-auto">
      <div v-if="store.entries.length === 0" class="py-8 text-center text-xs text-slate-500">
        {{ l.ui_no_players_access }}
      </div>

      <div
        v-for="entry in store.entries"
        :key="entry.id"
        class="flex items-center gap-2 border-b border-white/5 px-4 py-2.5 text-xs transition hover:bg-white/5"
      >
        <!-- Name + identifier -->
        <div class="flex min-w-0 flex-1 flex-col gap-0.5">
          <span class="truncate font-medium text-slate-100">{{ entry.name }}</span>
          <span class="truncate font-mono text-xs text-slate-500">{{ entry.identifier }}</span>
        </div>

        <!-- Group count -->
        <span
          class="shrink-0 rounded bg-white/10 px-2 py-0.5 text-xs text-slate-300"
        >
          {{ entry.groups.length }} {{ entry.groups.length !== 1 ? l.ui_groups : l.ui_group }}
        </span>

        <!-- Zone count badge -->
        <span
          class="shrink-0 rounded px-2 py-0.5 text-xs"
          :class="entry.zones.length ? 'bg-blue-500/15 text-blue-400' : 'bg-white/5 text-slate-500'"
        >
          {{ entry.zones.length ? `${entry.zones.length} ${entry.zones.length !== 1 ? l.ui_zones : l.ui_zone}` : l.ui_full_map }}
        </span>

        <!-- Expiry badge -->
        <span
          v-if="entry.maxExpiry"
          class="shrink-0 rounded bg-amber-500/15 px-2 py-0.5 text-xs text-amber-400"
        >
          <i class="pi pi-clock mr-0.5 text-[0.6rem]" />{{ formatExpiry(entry.maxExpiry) }}
        </span>

        <!-- Actions -->
        <div class="flex shrink-0 gap-1">
          <button
            class="rounded px-2 py-1 text-slate-400 transition hover:bg-white/10 hover:text-slate-100"
            @click.stop="openEdit(entry)"
          >
            <i class="pi pi-pencil text-xs" />
          </button>
          <button
            class="rounded px-2 py-1 transition hover:bg-white/10"
            :class="pendingDelete === entry.id ? 'text-red-400' : 'text-slate-400 hover:text-slate-100'"
            @click.stop="requestDelete(entry.id)"
          >
            <i class="pi text-xs" :class="pendingDelete === entry.id ? 'pi-exclamation-triangle' : 'pi-trash'" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.form-slide-enter-active,
.form-slide-leave-active {
  transition: opacity 0.15s ease, max-height 0.2s ease;
  overflow: hidden;
  max-height: 500px;
}
.form-slide-enter-from,
.form-slide-leave-to {
  opacity: 0;
  max-height: 0;
}
</style>
