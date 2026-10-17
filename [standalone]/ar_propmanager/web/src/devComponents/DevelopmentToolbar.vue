<script setup lang="ts">
import { useGizmoStore } from '../stores/gizmo.store'
import SplitButton from 'primevue/splitbutton'

const pmStore = useGizmoStore()

const debugData = (data: any) => {
  window.postMessage(data, '*')
}

const testGizmo = () => {
  pmStore.isVisible = true
  setTimeout(() => {
    debugData({
      action: 'setCameraPosition',
      data: {
        position: { x: 0, y: -12, z: 3 },
        rotation: { x: -10, y: 0, z: 0 },
        fov: 60
      }
    })
    debugData({
      action: 'initGizmo',
      data: {
        handle: 1,
        position: { x: 0, y: 0, z: 0 },
        quaternion: { x: 0, y: 0, z: 0, w: 1 },
        keybinds: {
          mode:   { key: 'R',    description: 'Change Mode With Long Name' },
          focus:  { key: 'F',    description: 'Toggle Focus' },
          finish: { key: 'E',    description: 'Finish' },
          cancel: { key: 'Back', description: 'Cancel' },
        },
        restrictRotationAxes: false
      }
    })
  }, 50)
}

const mockGroups = ['Street Furniture', 'Nature', 'Vehicles']
const mockModels = [
  'prop_bench_01a', 'prop_tree_pine_01a', 'prop_streetlight_01',
  'prop_barrier_01a', 'prop_bin_01a', 'prop_bollard_01',
]
const mockGroupStates: Record<string, boolean> = {
  'Street Furniture': true,
  'Nature': false,
  'Vehicles': true,
}
const mockPlayerAccess = [
  {
    id: 1, identifier: 'license:a1b2c3d4e5f6a1b2c3d4', name: 'John Doe',
    groups: ['Street Furniture', 'Vehicles'],
    zones: [],
    maxExpiry: null,
  },
  {
    id: 2, identifier: 'license:f6e5d4c3b2a1f6e5d4c3', name: 'Jane Smith',
    groups: ['Nature'],
    zones: [
      [{ x: 150, y: -900 }, { x: 300, y: -900 }, { x: 300, y: -750 }, { x: 150, y: -750 }],
    ],
    maxExpiry: 43200,
  },
  {
    id: 3, identifier: 'license:c3b2a1f6e5d4c3b2a1f6', name: 'Bob Jones',
    groups: ['Street Furniture'],
    zones: [
      [{ x: 100, y: -900 }, { x: 250, y: -900 }, { x: 250, y: -750 }, { x: 100, y: -750 }],
      [{ x: -400, y: -200 }, { x: -200, y: -200 }, { x: -200, y: 0 }, { x: -400, y: 0 }],
    ],
    maxExpiry: 604800,
  },
]

const mockRestrictedZone = [
  {
    id: 3, identifier: 'license:c3b2a1f6e5d4c3b2a1f6', name: 'Bob Jones',
    groups: ['Street Furniture'],
    zones: [
      [{ x: 100, y: -900 }, { x: 250, y: -900 }, { x: 250, y: -750 }, { x: 100, y: -750 }],
      [{ x: -400, y: -200 }, { x: -200, y: -200 }, { x: -200, y: 0 }, { x: -400, y: 0 }],
    ],
    // maxExpiry: 604800,
  },
]

function buildMockProps() {
  const now = Math.floor(Date.now() / 1000)
  const mockExpiries = [null, now + 3600, now + 86400, now - 60]
  return Array.from({ length: 12 }, (_, i) => ({
    id: i + 1,
    model: mockModels[i % mockModels.length],
    position: { x: +(100 + i * 5).toFixed(1), y: +(200 + i * 1.2).toFixed(1), z: +(28 + (i % 4) * 0.5).toFixed(1) },
    quaternion: { x: 0, y: 0, z: 0, w: 1 },
    group: mockGroups[i % mockGroups.length],
    outlined: false,
    renderDistance: 200,
    expiresAt: mockExpiries[i % mockExpiries.length],
  }))
}

const testPropManager = (level: number, playerAccess?: any[]) => {
  const data: Record<string, any> = { level, props: buildMockProps(), groupStates: mockGroupStates }
  if (level >= 3) {
    data.playerAccess = mockPlayerAccess
    data.groups = mockGroups
  } else if (level === 0 && playerAccess) {
    data.playerAccess = playerAccess
  }
  debugData({ action: 'openPropManager', data })
}

const items = [
  { label: 'Test Gizmo', command: testGizmo },
  {
    label: 'Close Gizmo',
    command: () => {
      debugData({ action: 'closeGizmo', data: {} })
      debugData({ action: 'hide', data: {} })
      pmStore.isVisible = false
    }
  },
  { label: 'Prop Manager - Level 0 (restricted · zone)',        command: () => testPropManager(0, mockRestrictedZone) },
  { label: 'Prop Manager - Level 1 (toggle groups)',       command: () => testPropManager(1) },
  { label: 'Prop Manager - Level 2 (manage)',              command: () => testPropManager(2) },
  { label: 'Prop Manager - Level 3 (player access)',       command: () => testPropManager(3) },
  { label: 'Close Prop Manager', command: () => debugData({ action: 'closePropManager', data: {} }) },
]
</script>

<template>
  <div class="fixed left-5 top-5 flex gap-5">
    <SplitButton
      label="Toggle HUD State"
      dropdownIcon="pi pi-chevron-down"
      @click.prevent="pmStore.isVisible = !pmStore.isVisible"
      :model="items"
      size="small"
    />
  </div>
</template>
