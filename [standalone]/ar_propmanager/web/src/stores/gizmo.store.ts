import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useApi } from '../composables/useApi'
import type { Zone } from './playeraccess.store'

export type EditorMode = 'translate' | 'rotate'
export type SpaceMode = 'world' | 'local'

export interface GizmoKey {
  key: string
  description: string
}

export interface GizmoKeys {
  mode: GizmoKey
  focus: GizmoKey
  finish: GizmoKey
  cancel: GizmoKey
}

export const useGizmoStore = defineStore('gizmo', () => {
  const isVisible = ref<boolean>(false)
  const editorMode = ref<EditorMode>('translate')
  const spaceMode = ref<SpaceMode>('world')
  const keys = ref<GizmoKeys>({
    mode:   { key: 'R',    description: 'Change Mode' },
    focus:  { key: 'F',    description: 'Toggle Focus' },
    finish: { key: 'E',    description: 'Finish' },
    cancel: { key: 'Back', description: 'Cancel' },
  })
  const restrictRotationAxes = ref<boolean>(false)
  const displayPosition = ref<{ x: number; y: number; z: number }>({ x: 0, y: 0, z: 0 })
  const displayRotation = ref<{ x: number; y: number; z: number }>({ x: 0, y: 0, z: 0 })
  const zones = ref<Zone[]>([])
  const zonesDrawn = ref(false)

  const manualTransform = ref<{
    position: { x: number; y: number; z: number }
    rotation: { x: number; y: number; z: number }
  } | null>(null)

  function pointInPolygon(px: number, py: number, polygon: Zone): boolean {
    let inside = false
    for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      const xi = polygon[i].x, yi = polygon[i].y
      const xj = polygon[j].x, yj = polygon[j].y
      if (((yi > py) !== (yj > py)) && (px < ((xj - xi) * (py - yi)) / (yj - yi) + xi)) {
        inside = !inside
      }
    }
    return inside
  }

  const isPositionValid = computed(() => {
    if (zones.value.length === 0) return true
    const { x, y } = displayPosition.value
    return zones.value.some((zone) => pointInPolygon(x, y, zone))
  })

  const setZones = (newZones: Zone[]) => {
    zones.value = newZones
    zonesDrawn.value = false
  }

  const toggleZoneDraw = () => {
    useApi('ToggleZoneDraw', { method: 'POST', body: JSON.stringify({}) }, undefined, {})
    zonesDrawn.value = !zonesDrawn.value
  }

  const applyManualTransform = (
    position: { x: number; y: number; z: number },
    rotation: { x: number; y: number; z: number }
  ) => {
    manualTransform.value = { position, rotation }
  }

  const updateDisplay = (
    position: { x: number; y: number; z: number },
    rotation: { x: number; y: number; z: number }
  ) => {
    displayPosition.value = position
    displayRotation.value = rotation
  }

  const toggleEditorMode = () => {
    editorMode.value = editorMode.value === 'translate' ? 'rotate' : 'translate'
  }

  const toggleSpaceMode = () => {
    spaceMode.value = spaceMode.value === 'world' ? 'local' : 'world'
  }

  const transformEntity = (position: object, quaternion: object) => {
    useApi(
      'TransformEntity',
      { method: 'POST', body: JSON.stringify({ position, quaternion }) },
      undefined,
      {}
    )
  }

  const snapToGround = () => {
    useApi('SnapToGround', { method: 'POST', body: JSON.stringify({}) }, undefined, {})
  }

  const resetRotation = () => {
    useApi('ResetRotation', { method: 'POST', body: JSON.stringify({}) }, undefined, {})
  }

  return {
    isVisible,
    editorMode,
    spaceMode,
    keys,
    restrictRotationAxes,
    displayPosition,
    displayRotation,
    updateDisplay,
    manualTransform,
    applyManualTransform,
    toggleEditorMode,
    toggleSpaceMode,
    transformEntity,
    snapToGround,
    resetRotation,
    zones,
    zonesDrawn,
    isPositionValid,
    setZones,
    toggleZoneDraw,
  }
})
