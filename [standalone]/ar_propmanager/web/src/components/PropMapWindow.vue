<script setup lang="ts">
import { ref, computed, watch, onUnmounted, nextTick } from 'vue'
import { storeToRefs } from 'pinia'
import { useLocaleStore } from '../stores/locale.store'
import L from 'leaflet'
import type { Map as LeafletMap } from 'leaflet'
import 'leaflet/dist/leaflet.css'
import 'leaflet.markercluster'
import 'leaflet.markercluster/dist/MarkerCluster.css'
import 'leaflet.markercluster/dist/MarkerCluster.Default.css'
import 'leaflet.heat'
import { usePropManagerStore, type PropEntry } from '../stores/propmanager.store'

const store = usePropManagerStore()
const { locales: l } = storeToRefs(useLocaleStore())

// --- Mode ---------------------------------------------------------------------

type Mode = 'clusters' | 'heatmap'
const mode = ref<Mode>('clusters')

// --- Selection ----------------------------------------------------------------

const selected        = ref<PropEntry | null>(null)
const selectedCluster = ref<PropEntry[]>([])

function clearSelection() {
  selected.value = null
  selectedCluster.value = []
}

// --- Outline all -------------------------------------------------------------

const allOutlined = computed(() => store.props.length > 0 && store.props.every((p) => p.outlined))

// --- GTA V <-> Leaflet coordinate conversion -----------------------------------

const MAP_CENTER: [number, number] = [-119.43, 58.84]
const LAT_PER_100 = 1.421

function gameToMap(x: number, y: number): [number, number] {
  return [
    MAP_CENTER[0] + (LAT_PER_100 / 100) * y,
    MAP_CENTER[1] + (LAT_PER_100 / 100) * x,
  ]
}

// --- Map setup ----------------------------------------------------------------

const mapContainer = ref<HTMLElement | null>(null)

let map: LeafletMap | null = null
let clusterGroup: any = null
let heatLayer: any = null

const TILE_URL = 'https://s.rsg.sc/sc/images/games/GTAV/map/game/{z}/{x}/{y}.jpg'

async function initMap() {
  if (!mapContainer.value) return

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

  // Deselect when clicking empty map
  map.on('click', clearSelection)

  // Clear cluster list after zoom - the cluster composition changes so the list is stale
  map.on('zoomend', () => { selectedCluster.value = [] })

  buildLayers()
}

// --- Layer builders -----------------------------------------------------------

function clearLayers() {
  if (clusterGroup) { map?.removeLayer(clusterGroup); clusterGroup = null }
  if (heatLayer)    { map?.removeLayer(heatLayer);    heatLayer    = null }
}

function buildClusterLayer() {
  if (!map) return

  clusterGroup = (L as any).markerClusterGroup({
    maxClusterRadius: 50,
    showCoverageOnHover: false,
    spiderfyOnMaxZoom: false,
    zoomToBoundsOnClick: false,   // we handle click manually
    iconCreateFunction: (cluster: any) => {
      const n = cluster.getChildCount()
      const size = n >= 100 ? 40 : n >= 10 ? 34 : 28
      const childIds = new Set(
        cluster.getAllChildMarkers().map((m: any) => m._prop?.id).filter(Boolean)
      )
      const isSelected = selectedCluster.value.length > 0 &&
        selectedCluster.value.some((p) => childIds.has(p.id))
      return L.divIcon({
        html: `<div class="pm-cluster${isSelected ? ' pm-cluster-selected' : ''}" style="width:${size}px;height:${size}px">${n}</div>`,
        className: '',
        iconSize: L.point(size, size),
        iconAnchor: L.point(size / 2, size / 2),
      })
    },
  })

  // Cluster click: zoom in below max zoom, show prop list at max zoom
  clusterGroup.on('clusterclick', (e: any) => {
    L.DomEvent.stopPropagation(e)
    if (!map) return
    if (map.getZoom() < map.getMaxZoom()) {
      map.fitBounds(e.layer.getBounds(), { padding: [30, 30], maxZoom: map.getMaxZoom() })
      clearSelection()
    } else {
      const props: PropEntry[] = e.layer.getAllChildMarkers()
        .map((m: any) => m._prop as PropEntry)
        .filter(Boolean)
      selected.value = null
      selectedCluster.value = props
    }
  })

  for (const prop of store.props) {
    const [lat, lng] = gameToMap(prop.position.x, prop.position.y)
    const isSelected = selected.value?.id === prop.id

    const marker = L.circleMarker([lat, lng], {
      radius: isSelected ? 10 : 5,
      color: prop.outlined ? '#f59e0b' : isSelected ? '#e879f9' : '#3b82f6',
      fillColor: prop.outlined ? '#fcd34d' : isSelected ? '#d946ef' : '#60a5fa',
      fillOpacity: 1,
      weight: isSelected ? 3 : 1.5,
      className: isSelected ? 'pm-selected-marker' : '',
    })

    ;(marker as any)._prop = prop

    marker.bindTooltip(
      `<span style="font-size:0.75rem">${prop.model}</span><br><span style="font-size:0.7rem;color:#94a3b8">${prop.group}</span>`,
      { direction: 'top', offset: L.point(0, -8) }
    )

    marker.on('click', (e: any) => {
      L.DomEvent.stopPropagation(e)
      selectedCluster.value = []
      selected.value = selected.value?.id === prop.id ? null : prop
    })

    clusterGroup.addLayer(marker)
  }

  map.addLayer(clusterGroup)
}

function buildHeatLayer() {
  if (!map) return

  const points = store.props.map((p) => {
    const [lat, lng] = gameToMap(p.position.x, p.position.y)
    return [lat, lng, 1] as [number, number, number]
  })

  heatLayer = (L as any).heatLayer(points, {
    radius: 25,
    blur: 20,
    maxZoom: map.getMaxZoom(),
    gradient: { 0.3: '#3b82f6', 0.6: '#a855f7', 1.0: '#ef4444' },
    minOpacity: 0.4,
  }).addTo(map)
}

function buildLayers() {
  clearLayers()
  if (mode.value === 'clusters') {
    buildClusterLayer()
  } else {
    clearSelection()
    buildHeatLayer()
  }
}

// --- Reactivity ---------------------------------------------------------------

watch(() => store.props, () => { if (map) buildLayers() }, { deep: true })
watch(mode, () => { if (map) buildLayers() })
watch([selected, selectedCluster], () => { if (map && mode.value === 'clusters') buildLayers() })

watch(
  () => mapContainer.value,
  (el) => { if (el) nextTick(initMap) },
  { immediate: true }
)

onUnmounted(() => {
  map?.remove()
  map = null
})

// --- Actions ------------------------------------------------------------------

const deleteSelected = () => {
  if (!selected.value) return
  store.deleteProp(selected.value.id)
  selected.value = null
}

const deleteFromCluster = (prop: PropEntry) => {
  store.deleteProp(prop.id)
  selectedCluster.value = selectedCluster.value.filter((p) => p.id !== prop.id)
}
</script>

<template>
  <div class="flex h-[50vh] flex-col">
    <!-- Toolbar -->
    <div class="flex items-center justify-between border-b border-white/10 px-4 py-2">
      <!-- Mode toggle -->
      <div class="flex gap-1">
        <button
          class="flex items-center gap-1.5 rounded px-2.5 py-1 text-xs transition"
          :class="mode === 'clusters'
            ? 'bg-blue-600/50 text-blue-200'
            : 'bg-white/5 text-slate-400 hover:bg-white/10 hover:text-slate-200'"
          @click="mode = 'clusters'"
        >
          <i class="pi pi-circle-fill text-[0.7rem]" />
          {{ l.ui_map_clusters }}
        </button>
        <button
          class="flex items-center gap-1.5 rounded px-2.5 py-1 text-xs transition"
          :class="mode === 'heatmap'
            ? 'bg-red-600/50 text-red-200'
            : 'bg-white/5 text-slate-400 hover:bg-white/10 hover:text-slate-200'"
          @click="mode = 'heatmap'"
        >
          <i class="pi pi-stop-circle text-[0.7rem]" />
          {{ l.ui_map_heatmap }}
        </button>
      </div>

      <!-- Stats + outline toggle -->
      <div class="flex items-center gap-2">
        <span class="text-xs text-slate-500">{{ store.props.length }} {{ store.props.length !== 1 ? l.ui_props : l.ui_prop }}</span>
        <button
          class="flex items-center gap-1.5 rounded px-2.5 py-1 text-xs transition"
          :class="allOutlined
            ? 'bg-amber-500/30 text-amber-300 hover:bg-amber-500/20'
            : 'bg-white/5 text-slate-400 hover:bg-white/10 hover:text-slate-200'"
          :disabled="store.props.length === 0"
          @click="store.outlineAll()"
        >
          <i class="pi pi-eye text-[0.7rem]" />
          {{ allOutlined ? l.ui_map_clear_outlines : l.ui_map_outline_all }}
        </button>
      </div>
    </div>

    <!-- Map -->
    <div ref="mapContainer" class="flex-1 w-full" />

    <!-- Selection panel -->
    <div v-if="(selected || selectedCluster.length > 0) && mode === 'clusters'" class="border-t border-white/10">

      <!-- Cluster header -->
      <div
        v-if="selectedCluster.length > 0"
        class="flex items-center justify-between border-b border-white/5 px-4 py-1.5"
      >
        <span class="text-xs text-slate-400">{{ selectedCluster.length }} {{ selectedCluster.length !== 1 ? l.ui_props : l.ui_prop }} {{ l.ui_map_at_location }}</span>
        <button class="text-xs text-slate-600 transition hover:text-slate-400" @click="clearSelection">✕</button>
      </div>

      <!-- Prop rows -->
      <div class="max-h-[10vh] overflow-y-auto">
        <div
          v-for="prop in selected ? [selected] : selectedCluster"
          :key="prop.id"
          class="flex items-center gap-2 border-b border-white/5 px-4 py-2 text-xs last:border-0"
        >
          <div class="flex min-w-0 flex-1 flex-col gap-0.5">
            <span class="truncate font-mono text-slate-200">{{ prop.model }}</span>
            <span class="font-mono text-[0.7rem] text-slate-500">
              {{ prop.position.x.toFixed(1) }}, {{ prop.position.y.toFixed(1) }}, {{ prop.position.z.toFixed(1) }}
            </span>
          </div>
          <span class="shrink-0 rounded bg-white/10 px-2 py-0.5 text-[0.7rem] text-slate-400">{{ prop.group }}</span>
          <button
            class="flex shrink-0 items-center gap-1 rounded bg-red-600/20 px-2.5 py-1 text-xs text-red-400 transition hover:bg-red-600/40 hover:text-red-300"
            @click="selected ? deleteSelected() : deleteFromCluster(prop)"
          >
            <i class="pi pi-trash text-[0.7rem]" /> {{ l.ui_map_delete }}
          </button>
        </div>
      </div>
    </div>

    <!-- Footer: hint -->
    <div class="flex h-[3vh] shrink-0 items-center border-t border-white/10 px-4">
      <span class="text-xs text-slate-600">
        {{ mode === 'clusters' ? l.ui_map_hint_clusters : l.ui_map_hint_heatmap }}
      </span>
    </div>
  </div>
</template>

<style>
/* -- Cluster marker icons ---------------------------------------------------- */

.pm-cluster {
  background: rgba(59, 130, 246, 0.85);
  border: 2px solid rgba(147, 197, 253, 0.7);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.72rem;
  font-weight: 700;
  color: #fff;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.2);
}

.pm-cluster-selected {
  background: rgba(217, 70, 239, 0.9);
  border-color: rgba(240, 171, 252, 0.85);
  box-shadow: 0 0 0 3px rgba(217, 70, 239, 0.3), 0 0 0 6px rgba(217, 70, 239, 0.12);
}

/* -- Selected single marker glow -------------------------------------------- */

.pm-selected-marker {
  filter: drop-shadow(0 0 5px rgba(217, 70, 239, 0.9));
}

/* -- Leaflet tooltip - dark theme ------------------------------------------- */

.leaflet-tooltip {
  background: rgba(10, 16, 28, 0.95) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  border-radius: 6px !important;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.5) !important;
  padding: 5px 10px !important;
  text-align: center;
  color: #cbd5e1 !important;
}

.leaflet-tooltip::before {
  border-top-color: rgba(10, 16, 28, 0.95) !important;
}

/* -- Markercluster animation ------------------------------------------------ */

.leaflet-cluster-anim .leaflet-marker-icon,
.leaflet-cluster-anim .leaflet-marker-shadow {
  transition: transform 0.3s ease-out, opacity 0.3s ease-in;
}
</style>
