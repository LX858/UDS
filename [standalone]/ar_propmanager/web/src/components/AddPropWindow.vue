<script setup lang="ts">
import { ref, computed, reactive, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useAddPropStore } from '../stores/addprop.store'
import { usePropManagerStore } from '../stores/propmanager.store'
import { useApi } from '../composables/useApi'
import { useLocaleStore } from '../stores/locale.store'
import { parentResourceName } from '../utils/parentResource.utils'

const emit = defineEmits<{ done: [] }>()

const addPropStore = useAddPropStore()
const propStore    = usePropManagerStore()
const localeStore  = useLocaleStore()
const { locales: l } = storeToRefs(localeStore)
const { t } = localeStore

// --- Prop list ----------------------------------------------------------------

// Module-level cache - survives tab switches, fetched at most once per session
let _cachedPropList: string[] | null = null

const DEV_FALLBACK: string[] = [
  'prop_bench_01a', 'prop_bench_01b', 'prop_tree_pine_01a',
  'prop_streetlight_01', 'prop_bin_01a', 'prop_bollard_01a',
  'prop_barrier_01a', 'prop_cone_01', 'prop_box_wood01a',
]

async function loadPropList(): Promise<string[]> {
  if (_cachedPropList) return _cachedPropList

  if (!parentResourceName) {
    _cachedPropList = DEV_FALLBACK
    return _cachedPropList
  }

  try {
    const res = await fetch(`https://${parentResourceName}/GetPropList`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    })
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    _cachedPropList = await res.json() as string[]
    return _cachedPropList
  } catch {
    _cachedPropList = DEV_FALLBACK
    return _cachedPropList
  }
}

const propList    = ref<string[]>([])
const listLoading = ref(true)

onMounted(async () => {
  propList.value = await loadPropList()
  listLoading.value = false
})

// --- Fuzzy search -------------------------------------------------------------

const searchQuery = ref('')
const showResults = ref(false)

function scoreMatch(query: string, target: string): number {
  const q = query.toLowerCase()
  const t = target.toLowerCase()

  if (t === q) return 100
  if (t.startsWith(q)) return 80
  if (t.includes(q)) return 60

  const qSegs = q.split(/[_\s-]+/).filter(Boolean)
  const tSegs = t.split(/[_\s-]+/)
  let segScore = 0
  for (const qs of qSegs) {
    if (tSegs.some((ts) => ts.startsWith(qs))) segScore += 20
    else if (t.includes(qs)) segScore += 10
  }
  if (segScore > 0) return segScore

  let qi = 0
  for (const c of t) {
    if (qi < q.length && c === q[qi]) qi++
  }
  return qi === q.length ? Math.max(1, Math.floor((qi / t.length) * 8)) : 0
}

const filteredProps = computed(() => {
  const q = searchQuery.value.trim()
  if (!q) return propList.value.slice(0, 20)
  return propList.value
    .map((p) => ({ p, s: scoreMatch(q, p) }))
    .filter((x) => x.s > 0)
    .sort((a, b) => b.s - a.s)
    .slice(0, 60)
    .map((x) => x.p)
})

const selectProp = (name: string) => {
  searchQuery.value = name
  showResults.value = false
}

const onBlur = () => {
  setTimeout(() => { showResults.value = false }, 150)
}

// --- Form state ---------------------------------------------------------------

const existingGroups = computed(() =>
  addPropStore.allowedGroups.length > 0
    ? addPropStore.allowedGroups
    : [...propStore.groups.keys()]
)

const form = reactive({
  group:          '',
  renderDistance: 200,
  hasExpiry:      false,
  expiresAt:      '',
})

// --- Group dropdown -----------------------------------------------------------

const showGroupResults = ref(false)

const filteredGroups = computed(() => {
  const q = form.group.trim().toLowerCase()
  if (!q) return existingGroups.value
  return existingGroups.value.filter((g) => g.toLowerCase().includes(q))
})

const selectGroup = (name: string) => {
  form.group = name
  showGroupResults.value = false
}

const onGroupBlur = () => {
  setTimeout(() => { showGroupResults.value = false }, 150)
}

const canPlace = computed(() =>
  searchQuery.value.trim().length > 0 && form.group.trim().length > 0
)

function formatExpiry(seconds: number): string {
  if (seconds < 3600)  return `${Math.round(seconds / 60)} minutes`
  if (seconds < 86400) return `${Math.round(seconds / 3600)} hour${Math.round(seconds / 3600) !== 1 ? 's' : ''}`
  return `${Math.round(seconds / 86400)} day${Math.round(seconds / 86400) !== 1 ? 's' : ''}`
}

// --- Submit -------------------------------------------------------------------

const placing = ref(false)
const error   = ref('')

const place = async () => {
  if (!canPlace.value) return
  placing.value = true
  error.value   = ''

  const result = await useApi<string | { error?: string }>(
    'PlaceProp',
    {
      method: 'POST',
      body: JSON.stringify({
        model:          searchQuery.value.trim(),
        group:          form.group.trim(),
        renderDistance: form.renderDistance,
        expiresAt:      addPropStore.maxExpiry
          ? Math.floor(Date.now() / 1000) + addPropStore.maxExpiry
          : form.hasExpiry && form.expiresAt
            ? Math.floor(new Date(form.expiresAt).getTime() / 1000)
            : null,
      }),
    },
    undefined,
    'ok'
  )

  placing.value = false

  const data = result.data.value
  if (data !== 'ok') {
    if (typeof data === 'object' && data?.error === 'invalid_model') {
      error.value = l.value.ui_error_invalid_model
    } else if (typeof data === 'object' && data?.error === 'group_exists_no_access') {
      error.value = l.value.ui_error_group_no_access
    } else {
      error.value = l.value.ui_error_place_failed
    }
    return
  }

  emit('done')
}
</script>

<template>
  <div class="flex h-[50vh] flex-col">
  <div class="flex flex-1 flex-col gap-4 p-4">

    <!-- Model search -->
    <div class="flex flex-col gap-1.5">
      <label class="text-xs font-medium text-slate-400">{{ l.ui_prop_model_label }}</label>
      <div class="relative">
        <div class="pointer-events-none absolute inset-y-0 left-2.5 flex items-center">
          <i class="pi pi-search text-xs text-slate-500" />
        </div>
        <input
          v-model="searchQuery"
          type="text"
          :placeholder="l.ui_prop_model_placeholder"
          class="w-full rounded border border-white/10 bg-white/5 py-1.5 pl-7 pr-3 text-xs text-slate-100 outline-none transition placeholder:text-slate-600 focus:border-white/25 focus:bg-white/10"
          @focus="showResults = true"
          @blur="onBlur"
        />

        <!-- Results dropdown -->
        <div
          v-if="showResults && filteredProps.length > 0"
          class="absolute top-full z-10 mt-1 max-h-[20vh] w-full overflow-y-auto rounded border border-white/10 bg-black/95 shadow-xl"
        >
          <div v-if="listLoading" class="px-3 py-2 text-xs text-slate-500">{{ l.ui_prop_list_loading }}</div>
          <button
            v-for="name in filteredProps"
            :key="name"
            class="flex w-full items-center px-3 py-1.5 text-left text-xs text-slate-300 transition hover:bg-white/10 hover:text-slate-100"
            @mousedown.prevent="selectProp(name)"
          >
            <span class="font-mono">{{ name }}</span>
          </button>
        </div>
      </div>
      <p v-if="searchQuery && !propList.includes(searchQuery)" class="text-[0.7rem] text-amber-400/80">
        <i class="pi pi-exclamation-triangle mr-1 text-[0.6rem]" />
        {{ l.ui_prop_not_in_list }}
      </p>
    </div>

    <!-- Group + Render distance -->
    <div class="grid grid-cols-2 gap-3">
      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-medium text-slate-400">{{ l.ui_group_label }}</label>
        <!-- Group dropdown (existingGroups is scoped to allowedGroups for restricted players) -->
        <div class="relative">
          <div class="pointer-events-none absolute inset-y-0 left-2.5 flex items-center">
            <i class="pi pi-tag text-xs text-slate-500" />
          </div>
          <input
            v-model="form.group"
            type="text"
            :placeholder="l.ui_group_placeholder"
            class="w-full rounded border border-white/10 bg-white/5 py-1.5 pl-7 pr-3 text-xs text-slate-100 outline-none transition placeholder:text-slate-600 focus:border-white/25 focus:bg-white/10"
            @focus="showGroupResults = true"
            @blur="onGroupBlur"
          />
          <div
            v-if="showGroupResults && filteredGroups.length > 0"
            class="absolute top-full z-10 mt-1 max-h-[16vh] w-full overflow-y-auto rounded border border-white/10 bg-black/95 shadow-xl"
          >
            <button
              v-for="g in filteredGroups"
              :key="g"
              class="flex w-full items-center px-3 py-1.5 text-left text-xs text-slate-300 transition hover:bg-white/10 hover:text-slate-100"
              @mousedown.prevent="selectGroup(g)"
            >{{ g }}</button>
          </div>
        </div>
      </div>

      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-medium text-slate-400">{{ l.ui_render_distance_label }}</label>
        <input
          v-model.number="form.renderDistance"
          type="number"
          min="1"
          max="1000"
          step="1"
          @change="form.renderDistance = Math.min(1000, Math.max(1, form.renderDistance))"
          class="rounded border border-white/10 bg-white/5 px-2.5 py-1.5 text-xs text-slate-100 outline-none transition focus:border-white/25 focus:bg-white/10"
        />
      </div>
    </div>

    <!-- Expiry -->
    <div class="flex flex-col gap-1.5">
      <template v-if="addPropStore.maxExpiry">
        <div class="flex items-center gap-2 rounded border border-amber-500/20 bg-amber-500/10 px-3 py-2 text-xs text-amber-300">
          <i class="pi pi-clock text-[0.7rem]" />
          {{ t('ui_expiry_notice', formatExpiry(addPropStore.maxExpiry)) }}
        </div>
      </template>
      <template v-else>
        <div class="flex items-center justify-between">
          <label class="text-xs font-medium text-slate-400">{{ l.ui_expiry_label }}</label>
          <button
            type="button"
            class="rounded px-2 py-1 text-xs transition"
            :class="form.hasExpiry
              ? 'bg-blue-600/60 text-blue-200 ring-1 ring-blue-500/40'
              : 'bg-white/5 text-slate-400 hover:bg-white/10 hover:text-slate-200'"
            @click.stop="form.hasExpiry = !form.hasExpiry"
          >
            {{ form.hasExpiry ? l.ui_expiry_enabled : l.ui_expiry_disabled }}
          </button>
        </div>
        <Transition name="form-slide">
          <input
            v-if="form.hasExpiry"
            v-model="form.expiresAt"
            type="datetime-local"
            class="rounded border border-white/10 bg-white/5 px-2.5 py-1.5 text-xs text-slate-100 outline-none transition focus:border-white/25 focus:bg-white/10 [color-scheme:dark]"
          />
        </Transition>
      </template>
    </div>

    <!-- Error -->
    <p v-if="error" class="text-xs text-red-400">{{ error }}</p>
  </div>

  <!-- Footer: actions -->
  <div class="flex h-[5vh] shrink-0 items-center justify-end gap-2 border-t border-white/5 px-4">
    <button
      class="rounded bg-white/10 px-3 py-1.5 text-xs text-slate-300 transition hover:bg-white/20"
      @click="emit('done')"
    >
      {{ l.ui_cancel }}
    </button>
    <button
      class="flex items-center gap-1.5 rounded bg-blue-600/80 px-3 py-1.5 text-xs font-medium text-white transition hover:bg-blue-500/80 disabled:opacity-40"
      :disabled="!canPlace || placing"
      @click="place"
    >
      <i class="pi pi-map-marker text-[0.7rem]" />
      {{ placing ? l.ui_placing : l.ui_place_prop }}
    </button>
  </div>
  </div>
</template>

<style scoped>
.form-slide-enter-active,
.form-slide-leave-active {
  transition: opacity 0.15s ease, max-height 0.2s ease;
  overflow: hidden;
  max-height: 60px;
}
.form-slide-enter-from,
.form-slide-leave-to {
  opacity: 0;
  max-height: 0;
}
</style>
