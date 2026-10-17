<script setup lang="ts">
import { ref, watch, onUnmounted, nextTick } from 'vue'
import { storeToRefs } from 'pinia'
import { useLocaleStore } from '../stores/locale.store'
import type { Map as LeafletMap, CircleMarker, Polygon } from 'leaflet'
import type { Zone } from '../stores/playeraccess.store'

// --- Props / emits ------------------------------------------------------------

const props = defineProps<{
  modelValue: Array<{ x: number; y: number }>
  zones?: Zone[]
}>()

const emit = defineEmits<{
  'update:modelValue': [points: Array<{ x: number; y: number }>]
  'delete-zone': [index: number]
}>()

// --- GTA V <-> Leaflet coordinate conversion -----------------------------------

const MAP_CENTER: [number, number] = [-119.43, 58.84]
const LAT_PER_100 = 1.421

function gameToMap(x: number, y: number): [number, number] {
  return [
    MAP_CENTER[0] + (LAT_PER_100 / 100) * y,
    MAP_CENTER[1] + (LAT_PER_100 / 100) * x,
  ]
}

function mapToGame(lat: number, lng: number): { x: number; y: number } {
  const scale = LAT_PER_100 / 100
  return {
    x: (lng - MAP_CENTER[1]) / scale,
    y: (lat - MAP_CENTER[0]) / scale,
  }
}

// --- State --------------------------------------------------------------------

const mapContainer = ref<HTMLElement | null>(null)
const hoverCoords  = ref<{ x: number; y: number } | null>(null)

let L: typeof import('leaflet') | null = null
let map: LeafletMap | null = null
let markers: CircleMarker[] = []
let draftPolygon: Polygon | null = null
let savedPolygons: Polygon[] = []

const localeStore = useLocaleStore()
const { locales: l } = storeToRefs(localeStore)
const { t } = localeStore

// Internal copy - synced to modelValue on mount, then emitted on every change
const points = ref<Array<{ x: number; y: number }>>([...props.modelValue])

function commitPoints() {
  emit('update:modelValue', [...points.value])
}

// --- Leaflet bootstrap --------------------------------------------------------

const TILE_URL = 'https://s.rsg.sc/sc/images/games/GTAV/map/game/{z}/{x}/{y}.jpg'

async function initMap() {
  if (!mapContainer.value) return

  L = await import('leaflet')
  await import('leaflet/dist/leaflet.css')

  map = L.map(mapContainer.value, {
    crs: L.CRS.Simple,
    maxBoundsViscosity: 1.0,
    preferCanvas: true,
    zoomControl: false,
    attributionControl: false,
    maxZoom: 7,
    minZoom: 2,
  })

  const bounds = L.latLngBounds(L.latLng(0, 128), L.latLng(-192, 0))
  map.setMaxBounds(bounds)
  map.fitBounds(bounds)

  const container = map.getContainer()
  if (container) container.style.backgroundColor = '#384950'

  L.tileLayer(TILE_URL, {
    maxZoom: 7,
    minZoom: 2,
    bounds,
    noWrap: true,
  }).addTo(map)

  L.control.zoom({ position: 'bottomright' }).addTo(map)

  map.on('click', onMapClick)
  map.on('mousemove', onMapMouseMove)
  map.on('mouseout', () => { hoverCoords.value = null })

  redrawSaved()
  redrawDraft()

  if (draftPolygon && points.value.length >= 2) {
    map.fitBounds(draftPolygon.getBounds(), { padding: [24, 24] })
  }
}

function onMapClick(e: import('leaflet').LeafletMouseEvent) {
  if (!L) return
  points.value.push(mapToGame(e.latlng.lat, e.latlng.lng))
  redrawDraft()
  commitPoints()
}

function onMapMouseMove(e: import('leaflet').LeafletMouseEvent) {
  hoverCoords.value = mapToGame(e.latlng.lat, e.latlng.lng)
}

// --- Drawing ------------------------------------------------------------------

function redrawDraft() {
  if (!L || !map) return

  markers.forEach((m) => m.remove())
  markers = []
  if (draftPolygon) { draftPolygon.remove(); draftPolygon = null }

  const latlngs = points.value.map((p) => gameToMap(p.x, p.y))

  if (latlngs.length >= 2) {
    draftPolygon = L.polygon(latlngs as [number, number][], {
      color: '#3b82f6',
      fillColor: '#3b82f6',
      fillOpacity: latlngs.length >= 3 ? 0.15 : 0,
      weight: 2,
    }).addTo(map)
  }

  latlngs.forEach(([lat, lng], i) => {
    const isFirst = i === 0
    const marker = L!.circleMarker([lat, lng], {
      radius: isFirst ? 7 : 5,
      color: isFirst ? '#60a5fa' : '#3b82f6',
      fillColor: isFirst ? '#93c5fd' : '#60a5fa',
      fillOpacity: 1,
      weight: 2,
    }).addTo(map!)

    marker.on('click', (e: import('leaflet').LeafletMouseEvent) => {
      L!.DomEvent.stopPropagation(e)
      if (isFirst && points.value.length >= 3) return
      points.value.splice(i, 1)
      redrawDraft()
      commitPoints()
    })

    markers.push(marker)
  })
}

function redrawSaved() {
  savedPolygons.forEach((p) => p.remove())
  savedPolygons = []

  if (!L || !map || !props.zones?.length) return

  props.zones.forEach((zone, i) => {
    if (zone.length < 2) return
    const latlngs = zone.map((p) => gameToMap(p.x, p.y))
    const poly = L!.polygon(latlngs as [number, number][], {
      color: '#10b981',
      fillColor: '#10b981',
      fillOpacity: zone.length >= 3 ? 0.15 : 0,
      weight: 2,
    }).addTo(map!)

    poly.on('mouseover', () => poly.setStyle({ color: '#ef4444', fillColor: '#ef4444' }))
    poly.on('mouseout',  () => poly.setStyle({ color: '#10b981', fillColor: '#10b981' }))
    poly.on('click', (e: import('leaflet').LeafletMouseEvent) => {
      L!.DomEvent.stopPropagation(e)
      emit('delete-zone', i)
    })

    savedPolygons.push(poly)
  })
}

// --- Actions ------------------------------------------------------------------

const undoLast = () => {
  if (points.value.length === 0) return
  points.value.pop()
  redrawDraft()
  commitPoints()
}

const clearAll = () => {
  points.value = []
  redrawDraft()
  commitPoints()
}

// --- Lifecycle ----------------------------------------------------------------

watch(
  () => mapContainer.value,
  (el) => { if (el) nextTick(initMap) },
  { immediate: true }
)

// Sync internal points when parent clears the draft (e.g. after "Add Zone")
watch(
  () => props.modelValue,
  (val) => {
    if (val.length === 0 && points.value.length > 0) {
      points.value = []
      redrawDraft()
    }
  }
)

watch(() => props.zones, redrawSaved, { deep: true })

onUnmounted(() => {
  map?.remove()
  map = null
})
</script>

<template>
  <div class="overflow-hidden rounded border border-white/10 bg-black/30">
    <!-- Hover coords bar -->
    <div class="flex h-7 items-center border-b border-white/10 bg-black/40 px-3">
      <span class="font-mono text-[0.7rem] text-slate-500">
        <template v-if="hoverCoords">
          X {{ hoverCoords.x.toFixed(0) }}&nbsp;&nbsp;Y {{ hoverCoords.y.toFixed(0) }}
        </template>
        <template v-else>
          {{ l.ui_zone_map_hint }}
        </template>
      </span>
    </div>

    <!-- Map -->
    <div ref="mapContainer" class="h-[26vh] w-full" />

    <!-- Bottom bar: point count + undo / clear -->
    <div class="flex items-center justify-between border-t border-white/10 bg-black/40 px-3 py-1.5">
      <span class="text-xs text-slate-400">
        {{ points.length }} {{ points.length !== 1 ? l.ui_points : l.ui_point }}
        <span v-if="points.length < 3" class="text-slate-600"> - {{ t('ui_zone_need_more', 3 - points.length) }}</span>
      </span>
      <div class="flex items-center gap-1.5">
        <button
          class="rounded px-2 py-0.5 text-xs text-slate-400 transition hover:bg-white/10 hover:text-slate-200 disabled:opacity-30"
          :disabled="points.length === 0"
          @click.stop="undoLast"
        >
          <i class="pi pi-undo text-[0.7rem]" /> {{ l.ui_zone_undo }}
        </button>
        <button
          class="rounded px-2 py-0.5 text-xs text-slate-400 transition hover:bg-white/10 hover:text-red-400 disabled:opacity-30"
          :disabled="points.length === 0"
          @click.stop="clearAll"
        >
          <i class="pi pi-trash text-[0.7rem]" /> {{ l.ui_zone_clear }}
        </button>
      </div>
    </div>
  </div>
</template>
