<script setup lang="ts">
import { shallowRef, watch } from 'vue'
import * as THREE from 'three'
import { TresCanvas } from '@tresjs/core'
import { TransformControls } from '@tresjs/cientos'
import { useNuiEvent } from '../composables/useNuiEvent'
import { useGizmoStore } from '../stores/gizmo.store'
import { useLocaleStore, type UILocales } from '../stores/locale.store'
import type { Zone } from '../stores/playeraccess.store'

const gizmoStore = useGizmoStore()
const localeStore = useLocaleStore()

const cameraRef = shallowRef<THREE.PerspectiveCamera | null>(null)
const meshRef = shallowRef<THREE.Mesh | null>(null)

// --- Coordinate helpers -------------------------------------------------------
// FiveM uses Z-up; Three.js uses Y-up.
// FiveM -> Three.js:  (x, y, z) -> (x, z, -y)
// Three.js -> FiveM:  (x, y, z) -> (x, -z, y)
// Quaternion -> FiveM: (x, y, z, w) -> (x, -z, y, w)

function syncDisplay() {
  const mesh = meshRef.value
  if (!mesh) return
  const pos = mesh.position
  const euler = new THREE.Euler().setFromQuaternion(mesh.quaternion, 'YZX')
  const toDeg = THREE.MathUtils.radToDeg
  gizmoStore.updateDisplay(
    { x: pos.x, y: -pos.z, z: pos.y },
    { x: toDeg(euler.x), y: toDeg(-euler.z), z: toDeg(euler.y) }
  )
}

function handleObjectChange() {
  const mesh = meshRef.value
  if (!gizmoStore.isVisible || !mesh) return
  const pos = mesh.position
  const quat = mesh.quaternion
  gizmoStore.transformEntity(
    { x: pos.x, y: -pos.z, z: pos.y },
    { x: quat.x, y: -quat.z, z: quat.y, w: quat.w }
  )
  syncDisplay()
}

// --- NUI Events ---------------------------------------------------------------

useNuiEvent<{
  position: { x: number; y: number; z: number }
  quaternion: { x: number; y: number; z: number; w: number }
  keybinds?: { mode: { key: string; description: string }; focus: { key: string; description: string }; finish: { key: string; description: string }; cancel: { key: string; description: string } }
  restrictRotationAxes?: boolean
  zones?: Zone[]
  locales?: UILocales
}>('initGizmo', (entity) => {
  const mesh = meshRef.value
  if (!mesh) return

  if (entity.keybinds) gizmoStore.keys = entity.keybinds
  if (entity.locales)  localeStore.setLocales(entity.locales)
  gizmoStore.restrictRotationAxes = entity.restrictRotationAxes ?? false
  gizmoStore.setZones(entity.zones ?? [])

  mesh.position.set(entity.position.x, entity.position.z, -entity.position.y)
  mesh.quaternion.set(entity.quaternion.x, entity.quaternion.z, -entity.quaternion.y, entity.quaternion.w)
  syncDisplay()

  gizmoStore.isVisible = true
})

useNuiEvent<{
  position: { x: number; y: number; z: number }
  quaternion: { x: number; y: number; z: number; w: number }
}>('updateGizmoTransform', (data) => {
  const mesh = meshRef.value
  if (!mesh || !gizmoStore.isVisible) return

  mesh.position.set(data.position.x, data.position.z, -data.position.y)
  mesh.quaternion.set(data.quaternion.x, data.quaternion.z, -data.quaternion.y, data.quaternion.w)
  syncDisplay()
})

useNuiEvent('closeGizmo', () => {
  gizmoStore.isVisible = false
  gizmoStore.setZones([])
})

useNuiEvent<{
  position: { x: number; y: number; z: number }
  rotation: { x: number; y: number; z: number }
}>('setCameraPosition', ({ position, rotation }) => {
  const camera = cameraRef.value
  if (!camera) return

  camera.position.set(position.x, position.z, -position.y)
  camera.rotation.order = 'YZX'

  // GTA can flip the camera when rotation.x crosses certain thresholds;
  // the Z component needs to be sign-flipped to compensate.
  const zSign = (t: number, e: number) =>
    t > 0 && t < 90 ? e : (t > -180 && t < -90) || t > 0 ? -e : e

  camera.rotation.set(
    THREE.MathUtils.degToRad(rotation.x),
    THREE.MathUtils.degToRad(zSign(rotation.x, rotation.z)),
    THREE.MathUtils.degToRad(rotation.y)
  )

  camera.updateProjectionMatrix()
})

useNuiEvent('toggleMode', () => {
  gizmoStore.toggleEditorMode()
})

// --- Manual transform input ---------------------------------------------------

// Reverse of syncDisplay: FiveM (rx,ry,rz) degrees -> Three.js Euler 'YZX'
// From syncDisplay: fivem.x=deg(e.x), fivem.y=deg(-e.z), fivem.z=deg(e.y)
// So:               e.x=rad(fivem.x),  e.z=-rad(fivem.y), e.y=rad(fivem.z)
watch(
  () => gizmoStore.manualTransform,
  (transform) => {
    const mesh = meshRef.value
    if (!transform || !mesh || !gizmoStore.isVisible) return

    const { position: pos, rotation: rot } = transform
    mesh.position.set(pos.x, pos.z, -pos.y)

    const euler = new THREE.Euler(
      THREE.MathUtils.degToRad(rot.x),
      THREE.MathUtils.degToRad(rot.z),
      -THREE.MathUtils.degToRad(rot.y),
      'YZX'
    )
    const quat = new THREE.Quaternion().setFromEuler(euler)
    mesh.quaternion.copy(quat)

    gizmoStore.transformEntity(
      { x: pos.x, y: pos.y, z: pos.z },
      { x: quat.x, y: -quat.z, z: quat.y, w: quat.w }
    )
    syncDisplay()
    gizmoStore.manualTransform = null
  }
)
</script>

<template>
  <TresCanvas
    alpha
    :clear-alpha="0"
    window-size
    render-mode="always"
    class="absolute inset-0"
    style="z-index: 1; pointer-events: auto;"
  >
    <TresPerspectiveCamera
      ref="cameraRef"
      :near="0.01"
      :far="10000"
      :position="[0, 0, 10]"
      make-default
    />
    <TresMesh ref="meshRef">
      <TresBoxGeometry :args="[0.001, 0.001, 0.001]" />
      <TresMeshBasicMaterial :visible="false" />
    </TresMesh>
    <TransformControls
      v-if="gizmoStore.isVisible && meshRef"
      :object="meshRef"
      :mode="gizmoStore.editorMode"
      :space="gizmoStore.spaceMode"
      :size="0.5"
      :show-x="!(gizmoStore.restrictRotationAxes && gizmoStore.editorMode === 'rotate')"
      :show-z="!(gizmoStore.restrictRotationAxes && gizmoStore.editorMode === 'rotate')"
      @change="handleObjectChange"
    />
  </TresCanvas>
</template>
