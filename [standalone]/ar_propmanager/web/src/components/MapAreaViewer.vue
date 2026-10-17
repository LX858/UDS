<script setup lang="ts">
import { ref, watch, onUnmounted, nextTick } from 'vue'
import type { Zone } from '../stores/playeraccess.store'
import type { Map as LeafletMap, Polygon } from 'leaflet'

const props = defineProps<{
  zones: Zone[]
  height?: string
}>()

const MAP_CENTER: [number, number] = [-119.43, 58.84]
const LAT_PER_100 = 1.421

function gameToMap(x: number, y: number): [number, number] {
  return [
    MAP_CENTER[0] + (LAT_PER_100 / 100) * y,
    MAP_CENTER[1] + (LAT_PER_100 / 100) * x,
  ]
}

// --- State --------------------------------------------------------------------

const mapContainer = ref<HTMLElement | null>(null)
let L: typeof import('leaflet') | null = null
let map: LeafletMap | null = null
let shapes: Polygon[] = []

const TILE_URL = 'https://s.rsg.sc/sc/images/games/GTAV/map/game/{z}/{x}/{y}.jpg'

// --- Leaflet bootstrap --------------------------------------------------------

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

  redraw()

  await nextTick()
  map.invalidateSize()
}

// --- Drawing ------------------------------------------------------------------

function redraw() {
  if (!L || !map) return

  shapes.forEach((s) => s.remove())
  shapes = []

  if (!props.zones.length) return

  let combinedBounds: ReturnType<typeof L.latLngBounds> | null = null

  for (const zone of props.zones) {
    if (zone.length < 2) continue
    const latlngs = zone.map((p) => gameToMap(p.x, p.y))
    const poly = L.polygon(latlngs as [number, number][], {
      color: '#3b82f6',
      fillColor: '#3b82f6',
      fillOpacity: zone.length >= 3 ? 0.18 : 0,
      weight: 2,
    }).addTo(map)
    shapes.push(poly)
    combinedBounds = combinedBounds
      ? combinedBounds.extend(poly.getBounds())
      : poly.getBounds()
  }

  if (combinedBounds) map.fitBounds(combinedBounds, { padding: [24, 24] })
}

// --- Lifecycle ----------------------------------------------------------------

watch(
  () => mapContainer.value,
  (el) => { if (el) nextTick(initMap) },
  { immediate: true },
)

watch(() => props.zones, redraw, { deep: true })

onUnmounted(() => {
  map?.remove()
  map = null
})
</script>

<template>
  <div
    class="overflow-hidden rounded border border-white/10 bg-black/30"
    :class="height ? '' : 'flex flex-1 flex-col min-h-0'"
  >
    <div
      ref="mapContainer"
      class="w-full"
      :class="height ? '' : 'flex-1'"
      :style="height ? { height } : {}"
    />
  </div>
</template>
