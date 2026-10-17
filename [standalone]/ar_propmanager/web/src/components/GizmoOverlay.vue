<script setup lang="ts">
import { reactive, computed, watch } from 'vue'
import { storeToRefs } from 'pinia'
import { useGizmoStore } from '../stores/gizmo.store'
import { useLocaleStore } from '../stores/locale.store'

const gizmoStore = useGizmoStore()
const { locales: l } = storeToRefs(useLocaleStore())

const keybindDisplay = computed(() => [
  { key: l.value.ui_keybind_mode_key,   desc: l.value.ui_keybind_mode   },
  { key: l.value.ui_keybind_focus_key,  desc: l.value.ui_keybind_focus  },
  { key: l.value.ui_keybind_finish_key, desc: l.value.ui_keybind_finish },
  { key: l.value.ui_keybind_cancel_key, desc: l.value.ui_keybind_cancel },
])

// --- Local editable state -----------------------------------------------------

type Vec3Fields = { x: string; y: string; z: string }

const localPos = reactive<Vec3Fields>({ x: '0.0', y: '0.0', z: '0.0' })
const localRot = reactive<Vec3Fields>({ x: '0', y: '0', z: '0' })
const editingPos = reactive({ x: false, y: false, z: false })
const editingRot = reactive({ x: false, y: false, z: false })

watch(
  () => gizmoStore.displayPosition,
  (p) => {
    if (!editingPos.x) localPos.x = p.x.toFixed(1)
    if (!editingPos.y) localPos.y = p.y.toFixed(1)
    if (!editingPos.z) localPos.z = p.z.toFixed(1)
  },
  { deep: true }
)

watch(
  () => gizmoStore.displayRotation,
  (r) => {
    if (!editingRot.x) localRot.x = Math.round(r.x).toString()
    if (!editingRot.y) localRot.y = Math.round(r.y).toString()
    if (!editingRot.z) localRot.z = Math.round(r.z).toString()
  },
  { deep: true }
)

// --- Commit helpers -----------------------------------------------------------

function commit() {
  const px = parseFloat(localPos.x)
  const py = parseFloat(localPos.y)
  const pz = parseFloat(localPos.z)
  const rx = parseFloat(localRot.x)
  const ry = parseFloat(localRot.y)
  const rz = parseFloat(localRot.z)
  if ([px, py, pz, rx, ry, rz].some(isNaN)) return
  gizmoStore.applyManualTransform({ x: px, y: py, z: pz }, { x: rx, y: ry, z: rz })
}

function onFocus(group: typeof editingPos, axis: keyof Vec3Fields) {
  group[axis] = true
}

function onBlur(group: typeof editingPos, axis: keyof Vec3Fields) {
  group[axis] = false
  commit()
}

function onEnter(el: EventTarget | null) {
  ;(el as HTMLInputElement | null)?.blur()
}

function onEscape(
  el: EventTarget | null,
  group: typeof editingPos,
  axis: keyof Vec3Fields,
  local: Vec3Fields,
  storeVal: number,
  fmt: (n: number) => string
) {
  local[axis] = fmt(storeVal)
  group[axis] = false
  ;(el as HTMLInputElement | null)?.blur()
}

// --- Copy / Paste -------------------------------------------------------------

let posBuffer: Vec3Fields | null = null
let rotBuffer: Vec3Fields | null = null

function copyVec(v: Vec3Fields, type: 'pos' | 'rot') {
  const buf = { x: v.x, y: v.y, z: v.z }
  if (type === 'pos') posBuffer = buf
  else rotBuffer = buf
}

function pasteVec(target: Vec3Fields, fmt: (n: number) => string, type: 'pos' | 'rot') {
  const buf = type === 'pos' ? posBuffer : rotBuffer
  if (!buf) return
  const parts = [buf.x, buf.y, buf.z].map((s) => parseFloat(s))
  if (parts.some(isNaN)) return
  target.x = fmt(parts[0])
  target.y = fmt(parts[1])
  target.z = fmt(parts[2])
  commit()
}
</script>

<template>
  <Transition name="fade">
    <div v-if="gizmoStore.isVisible" class="pointer-events-none absolute inset-0 z-10 flex justify-center">
      <div class="relative w-full max-w-[200vh]">

      <!-- -- Left middle: Transform + Controls --------------------------- -->
      <div class="pointer-events-auto absolute left-8 top-1/2 flex w-52 -translate-y-1/2 flex-col gap-3 rounded-lg border border-white/10 bg-black/75 p-3 text-white">

        <!-- Position -->
        <div>
          <div class="mb-1 flex items-center justify-between">
            <span class="text-xs font-semibold uppercase tracking-wider text-slate-400">{{ l.ui_gizmo_position }}</span>
            <div class="flex gap-1">
              <button class="rounded p-0.5 text-slate-500 transition hover:text-slate-200" tabindex="-1" @click="copyVec(localPos, 'pos')"><i class="pi pi-copy text-xs" /></button>
              <button class="rounded p-0.5 transition hover:text-slate-200" :class="posBuffer ? 'text-slate-400' : 'text-slate-600'" tabindex="-1" @click="pasteVec(localPos, (n) => n.toFixed(1), 'pos')"><i class="pi pi-file-import text-xs" /></button>
            </div>
          </div>
          <div class="flex flex-col gap-1">
            <div v-for="axis in (['x', 'y', 'z'] as const)" :key="'p' + axis" class="flex items-center gap-1.5">
              <span :class="{ 'text-red-400': axis === 'x', 'text-green-400': axis === 'y', 'text-blue-400': axis === 'z' }" class="w-3 text-center text-xs font-bold uppercase">{{ axis }}</span>
              <input
                v-model="localPos[axis]"
                type="text"
                class="min-w-0 flex-1 rounded border border-white/10 bg-white/5 px-1.5 py-0.5 font-mono text-xs text-slate-100 outline-none transition focus:border-white/30 focus:bg-white/10"
                @focus="onFocus(editingPos, axis)"
                @blur="onBlur(editingPos, axis)"
                @keydown.enter="onEnter($event.target)"
                @keydown.escape="onEscape($event.target, editingPos, axis, localPos, gizmoStore.displayPosition[axis], (n) => n.toFixed(1))"
              />
            </div>
          </div>
        </div>

        <!-- Rotation -->
        <div>
          <div class="mb-1 flex items-center justify-between">
            <span class="text-xs font-semibold uppercase tracking-wider text-slate-400">{{ l.ui_gizmo_rotation }}</span>
            <div class="flex gap-1">
              <button class="rounded p-0.5 text-slate-500 transition hover:text-slate-200" tabindex="-1" @click="copyVec(localRot, 'rot')"><i class="pi pi-copy text-xs" /></button>
              <button class="rounded p-0.5 transition hover:text-slate-200" :class="rotBuffer ? 'text-slate-400' : 'text-slate-600'" tabindex="-1" @click="pasteVec(localRot, (n) => Math.round(n).toString(), 'rot')"><i class="pi pi-file-import text-xs" /></button>
            </div>
          </div>
          <div class="flex flex-col gap-1">
            <div v-for="axis in (['x', 'y', 'z'] as const)" :key="'r' + axis" class="flex items-center gap-1.5">
              <span :class="{ 'text-red-400': axis === 'x', 'text-green-400': axis === 'y', 'text-blue-400': axis === 'z' }" class="w-3 text-center text-xs font-bold uppercase">{{ axis }}</span>
              <input
                v-model="localRot[axis]"
                type="text"
                class="min-w-0 flex-1 rounded border border-white/10 bg-white/5 px-1.5 py-0.5 font-mono text-xs text-slate-100 outline-none transition focus:border-white/30 focus:bg-white/10"
                @focus="onFocus(editingRot, axis)"
                @blur="onBlur(editingRot, axis)"
                @keydown.enter="onEnter($event.target)"
                @keydown.escape="onEscape($event.target, editingRot, axis, localRot, gizmoStore.displayRotation[axis], (n) => Math.round(n).toString())"
              />
            </div>
          </div>
        </div>

        <div class="h-px bg-white/10" />

        <!-- Mode + Space indicators -->
        <div class="flex gap-2">
          <div class="flex flex-1 flex-col items-center rounded bg-white/5 px-2 py-1.5">
            <span class="text-[0.6rem] uppercase tracking-wider text-slate-500">{{ l.ui_gizmo_mode }}</span>
            <span class="text-xs font-medium capitalize text-slate-200">{{ gizmoStore.editorMode }}</span>
          </div>
          <div class="flex flex-1 flex-col items-center rounded bg-white/5 px-2 py-1.5">
            <span class="text-[0.6rem] uppercase tracking-wider text-slate-500">{{ l.ui_gizmo_space }}</span>
            <span class="text-xs font-medium capitalize text-slate-200">{{ gizmoStore.spaceMode }}</span>
          </div>
        </div>

        <!-- Action buttons -->
        <div class="flex flex-col gap-1">
          <button class="rounded bg-white/10 px-3 py-1.5 text-xs text-white transition-colors hover:bg-white/20" @click="gizmoStore.toggleSpaceMode()">{{ l.ui_gizmo_toggle_space }}</button>
          <button class="rounded bg-white/10 px-3 py-1.5 text-xs text-white transition-colors hover:bg-white/20" @click="gizmoStore.snapToGround()">{{ l.ui_gizmo_snap_ground }}</button>
          <button class="rounded bg-white/10 px-3 py-1.5 text-xs text-white transition-colors hover:bg-white/20" @click="gizmoStore.resetRotation()">{{ l.ui_gizmo_reset_rotation }}</button>
        </div>

        <!-- Zone validity  -->
        <template v-if="gizmoStore.zones.length > 0">
          <div class="h-px bg-white/10" />
          <div
            class="flex items-center gap-2 rounded px-2.5 py-2 transition-colors"
            :class="gizmoStore.isPositionValid ? 'bg-green-500/15' : 'bg-red-500/20'"
          >
            <i
              class="pi text-[0.75rem]"
              :class="gizmoStore.isPositionValid ? 'pi-check-circle text-green-400' : 'pi-times-circle text-red-400'"
            />
            <span class="text-xs font-medium" :class="gizmoStore.isPositionValid ? 'text-green-300' : 'text-red-300'">
              {{ gizmoStore.isPositionValid ? l.ui_gizmo_zone_valid : l.ui_gizmo_zone_invalid }}
            </span>
          </div>
          <button
            class="rounded px-3 py-1.5 text-xs text-white transition-colors"
            :class="gizmoStore.zonesDrawn ? 'bg-cyan-600/50 hover:bg-cyan-600/70' : 'bg-white/10 hover:bg-white/20'"
            @click="gizmoStore.toggleZoneDraw()"
          >{{ l.ui_gizmo_toggle_zones }}</button>
        </template>

        <div class="h-px bg-white/10" />

        <!-- Keybinds -->
        <div class="grid grid-cols-[auto_1fr] gap-x-2 gap-y-1 px-2">
          <template
            v-for="bind in keybindDisplay"
            :key="bind.key"
          >
            <kbd class="self-center justify-self-center rounded bg-white/15 px-1.5 py-0.5 font-mono text-xs text-slate-100">{{ bind.key }}</kbd>
            <span class="justify-self-center text-center text-xs text-slate-400">{{ bind.desc }}</span>
          </template>
        </div>

      </div>

      </div>
    </div>
  </Transition>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.15s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
