// ==========================================
// CẤU HÌNH VỊ TRÍ MÁY CHIẾU & BẢNG PLANNING BOARD
// ==========================================
const projectorPos = [2495.0998242188, -312.91387329102, 95.1282] // MRPD board (vị trí màn hình chiếu scaleform)

// Cấu hình nghề nghiệp (job/group) được phép dùng:
// - Để 'police' nếu chỉ cảnh sát mới dùng được
// - Để false nếu muốn TẤT CẢ mọi người (kể cả admin / dân thường) đều dùng được
const TargetJob = 'police'

// Danh sách các model bảng được hỗ trợ target
const TargetModels = [
  'v_ilev_mm_scre_off',
]

// Cấu hình hiển thị màn chiếu trên bảng prop
const ProjectorConfig = {
  // Tự động căn chỉnh vị trí và góc xoay màn chiếu theo bảng prop
  // (Màn chiếu sẽ tự bám theo mặt bảng, không sợ bị xoay lệch hay cắt ngang bảng)
  attachToBoard: false,

  // Độ lệch tương đối [X, Y, Z] so với tâm bảng:
  // - X: 0.0 (chính giữa chiều ngang bảng)
  // - Y: 0.03 (nhô ra trước mặt bảng 3cm để tránh bị chìm/chớp hình)
  // - Z: 0.40 (độ cao đưa màn chiếu lên đúng giữa mặt bảng trắng)
  offset: [0.0, 0.00, 0.0],

  // Góc xoay bù:
  // - 0.0: Mặc định cùng hướng với mặt bảng
  // - Đổi thành 180.0 nếu màn chiếu bị quay úp mặt vào tường (ngược mặt)
  rotationOffset: 180.0,

  // Kích thước tỉ lệ màn chiếu (mặc định 0.1)
  scale: 0.1,
}

// Cấu hình các vị trí spawn prop model p_planning_board_01
const BoardConfigs = [
  {
    model: 'v_ilev_mm_scre_off',
    coords: [2496.5698242188, -312.81387329102, 95.2282], // [X, Y, Z] - Vị trí đặt chân bảng (MRPD briefing room)
    heading: -180.0, // Hướng quay của bảng (-90.0 hoặc 90.0 tuỳ theo hướng mặt bảng)
    freeze: true,   // Cố định bảng chống va chạm
  },
]

let spawnedBoards = []

async function loadModel(model) {
  const modelHash = typeof model === 'string' ? GetHashKey(model) : model
  if (!IsModelInCdimage(modelHash)) {
    console.warn(`^3[l2s-projector]^7 Model ${model} is not valid!`)
    return false
  }

  RequestModel(modelHash)
  let attempts = 0
  while (!HasModelLoaded(modelHash) && attempts < 100) {
    await new Promise((resolve) => setTimeout(resolve, 50))
    attempts++
  }
  return HasModelLoaded(modelHash)
}

function attachEntityTarget(entity) {
  try {
    if (GetResourceState('ox_target') === 'started') {
      exports.ox_target.addLocalEntity(entity, [
        {
          name: 'projector_use',
          icon: 'fas fa-display',
          label: 'Use Projector',
          event: 'l2s-projector:client:project',
          groups: TargetJob || undefined,
          distance: 5.0,
        },
        {
          name: 'projector_clear',
          icon: 'fas fa-power-off',
          label: 'Power off',
          event: 'l2s-projector:client:project-clear',
          groups: TargetJob || undefined,
          distance: 5.0,
        },
        {
          name: 'projector_next',
          icon: 'fas fa-caret-right',
          label: 'Next',
          event: 'l2s-projector:client:next',
          groups: TargetJob || undefined,
          distance: 5.0,
        },
        {
          name: 'projector_prev',
          icon: 'fas fa-caret-left',
          label: 'Previous',
          event: 'l2s-projector:client:previous',
          groups: TargetJob || undefined,
          distance: 5.0,
        },
      ])
    } else if (GetResourceState('qb-target') === 'started') {
      exports['qb-target'].AddTargetEntity(entity, {
        options: [
          {
            type: 'client',
            event: 'l2s-projector:client:project',
            icon: 'fas fa-display',
            label: 'Use Projector',
            job: TargetJob || false,
          },
          {
            type: 'client',
            event: 'l2s-projector:client:project-clear',
            icon: 'fas fa-power-off',
            label: 'Power off',
            job: TargetJob || false,
          },
          {
            type: 'client',
            event: 'l2s-projector:client:next',
            icon: 'fas fa-caret-right',
            label: 'Next',
            job: TargetJob || false,
          },
          {
            type: 'client',
            event: 'l2s-projector:client:previous',
            icon: 'fas fa-caret-left',
            label: 'Previous',
            job: TargetJob || false,
          },
        ],
        distance: 5.0,
      })
    }
  } catch (err) {
    console.error('^1[l2s-projector] Error attaching entity target:^7', err.message || err)
  }
}

async function spawnBoards() {
  cleanupBoards()

  for (const config of BoardConfigs) {
    const modelHash = GetHashKey(config.model)
    const loaded = await loadModel(modelHash)
    if (!loaded) continue

    const [x, y, z] = config.coords
    const obj = CreateObjectNoOffset(modelHash, x, y, z, false, false, false)

    if (DoesEntityExist(obj)) {
      SetEntityHeading(obj, config.heading || 0.0)
      if (config.freeze) {
        FreezeEntityPosition(obj, true)
      }
      SetEntityInvincible(obj, true)
      SetEntityCollision(obj, true, true)
      spawnedBoards.push(obj)

      // Gắn target trực tiếp vào entity vừa tạo
      attachEntityTarget(obj)
    }
    SetModelAsNoLongerNeeded(modelHash)
  }

  if (spawnedBoards.length > 0) {
    console.log(`^2[l2s-projector]^7 Successfully spawned ${spawnedBoards.length} board(s) (model: ${BoardConfigs[0].model})`)
  }
}

function cleanupBoards() {
  for (const obj of spawnedBoards) {
    if (DoesEntityExist(obj)) {
      try {
        if (GetResourceState('ox_target') === 'started') {
          exports.ox_target.removeLocalEntity(obj, [
            'projector_use',
            'projector_clear',
            'projector_next',
            'projector_prev',
          ])
        } else if (GetResourceState('qb-target') === 'started') {
          exports['qb-target'].RemoveTargetEntity(obj, [
            'Use Projector',
            'Power off',
            'Next',
            'Previous',
          ])
        }
      } catch (e) { }
      DeleteObject(obj)
    }
  }
  spawnedBoards = []
}

async function loadScaleform(scaleform) {
  let scaleformHandle = RequestScaleformMovie(scaleform)

  return new Promise((resolve) => {
    const interval = setInterval(() => {
      if (HasScaleformMovieLoaded(scaleformHandle)) {
        clearInterval(interval)
        resolve(scaleformHandle)
      } else {
        scaleformHandle = RequestScaleformMovie(scaleform)
      }
    }, 0)
  })
}

const url = 'https://i.imgur.com/Jhh0Apl.png' // Lighthouse eft map :)
const scale = 0.1
const sfName = 'generic_texture_renderer'

const width = 1550
const height = 900

let sfHandle = null
let txdHasBeenSet = false
let duiObj = null
let currentUrl = null
let isPlaying = false
let ourlink = null
let slidesnumber = 1

setTick(async () => {
  if (sfHandle !== null && !txdHasBeenSet) {
    PushScaleformMovieFunction(sfHandle, 'SET_TEXTURE')

    PushScaleformMovieMethodParameterString('meows') // txd
    PushScaleformMovieMethodParameterString('woof') // txn

    PushScaleformMovieFunctionParameterInt(0) // x
    PushScaleformMovieFunctionParameterInt(0) // y
    PushScaleformMovieFunctionParameterInt(width)
    PushScaleformMovieFunctionParameterInt(height)

    PopScaleformMovieFunctionVoid()

    txdHasBeenSet = true
  }

  if (currentUrl) {
    const playerCoords = GetEntityCoords(PlayerPedId())
    if (
      GetDistanceBetweenCoords(
        playerCoords[0],
        playerCoords[1],
        playerCoords[2],
        projectorPos[0],
        projectorPos[1],
        projectorPos[2],
      ) <= 12.0
    ) {
      if (!isPlaying) {
        await taskPlayUrl(currentUrl)
      }
    } else {
      CleanupDUI()
    }
  }
  if (sfHandle !== null && HasScaleformMovieLoaded(sfHandle)) {
    let renderPos = [projectorPos[0], projectorPos[1], projectorPos[2] + ProjectorConfig.offset[2]]
    let renderRot = [0.0, 0.0, (BoardConfigs[0]?.heading || 74.0922) + (ProjectorConfig.rotationOffset || 0.0)]

    if (ProjectorConfig.attachToBoard) {
      let boardEntity = null
      for (const b of spawnedBoards) {
        if (DoesEntityExist(b)) {
          boardEntity = b
          break
        }
      }

      if (!boardEntity) {
        for (const model of TargetModels) {
          const closest = GetClosestObjectOfType(
            projectorPos[0],
            projectorPos[1],
            projectorPos[2],
            5.0,
            GetHashKey(model),
            false,
            false,
            false
          )
          if (closest && DoesEntityExist(closest)) {
            boardEntity = closest
            break
          }
        }
      }

      if (boardEntity && DoesEntityExist(boardEntity)) {
        const rot = GetEntityRotation(boardEntity, 2)
        renderPos = GetOffsetFromEntityInWorldCoords(
          boardEntity,
          ProjectorConfig.offset[0],
          ProjectorConfig.offset[1],
          ProjectorConfig.offset[2]
        )
        renderRot = [
          rot[0],
          rot[1],
          rot[2] + (ProjectorConfig.rotationOffset || 0.0)
        ]
      }
    }

    DrawScaleformMovie_3dNonAdditive(
      sfHandle,
      renderPos[0],
      renderPos[1],
      renderPos[2],
      renderRot[0],
      renderRot[1],
      renderRot[2],
      2,
      2,
      2,
      ProjectorConfig.scale * 1,
      ProjectorConfig.scale * (9 / 16),
      1,
      2,
    )
  }
})




on('l2s-projector:client:project', async () => {
  let link = null
  let linktype = null

  if (GetResourceState('ox_lib') === 'started') {
    const input = await exports.ox_lib.inputDialog('Projector', [
      {
        type: 'input',
        label: 'Load URL',
        placeholder: 'https://...',
        required: true,
      },
      {
        type: 'select',
        label: 'Choose Type',
        options: [
          { value: 'door', label: 'YouTube Video' },
          { value: 'slides', label: 'Google Presentation' },
          { value: 'double', label: 'Public Link' },
        ],
        default: 'door',
        required: true,
      },
    ])
    if (!input) return
    link = input[0]
    linktype = input[1]
  } else if (GetResourceState('qb-input') === 'started') {
    const keyboard = await exports['qb-input'].ShowInput({
      header: 'Projector',
      inputs: [
        {
          text: 'Load URL',
          name: 'link',
          type: 'text',
          isRequired: true,
          default: '',
        },
        {
          text: 'Choose ',
          name: 'linktype',
          type: 'select',
          isRequired: true,
          default: 'door',
          options: [
            { value: 'door', text: 'Youtube Video' },
            { value: 'slides', text: 'Google Presentation' },
            { value: 'double', text: 'Public Link' },
          ],
        },
      ],
    })
    if (!keyboard) return
    link = keyboard.link
    linktype = keyboard.linktype
  } else {
    console.warn('^3[l2s-projector]^7 Neither ox_lib nor qb-input is started!')
    return
  }

  if (link) {
    const googleSlidesMatch = link.match(/\/presentation\/d\/([a-zA-Z0-9_-]+)/)
    if (googleSlidesMatch) {
      const presId = googleSlidesMatch[1]
      slidesnumber = 1
      const embedUrl = `https://docs.google.com/presentation/d/${presId}/embed?slide=id.p1`
      emitNet('l2s-projector:server:project-start', {
        url: embedUrl,
        type: 'slides',
        presentationId: presId,
        currentSlide: 1,
      })
    } else if (linktype === 'door' || link.includes('youtube.com') || link.includes('youtu.be')) {
      const regExp = /^.*(youtu\.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/
      const match = link.match(regExp)
      if (match && match[2]) {
        emitNet('l2s-projector:server:project-start', 'https://www.youtube.com/embed/' + match[2] + '?autoplay=1')
      } else {
        emitNet('l2s-projector:server:project-start', link)
      }
    } else {
      emitNet('l2s-projector:server:project-start', link)
    }
  }
})

on('l2s-projector:client:next', () => {
  emitNet('l2s-projector:server:change-slide', 1)
})

on('l2s-projector:client:previous', () => {
  emitNet('l2s-projector:server:change-slide', -1)
})

on('l2s-projector:client:project-clear', () => {
  emitNet('l2s-projector:server:project-stop')
})

RegisterNetEvent('l2s-projector:client:project-start')
RegisterNetEvent('l2s-projector:client:project-stop')
RegisterNetEvent('l2s-projector:client:slide-updated')

on('l2s-projector:client:project-start', async (link, data) => {
  if (currentUrl) CleanupDUI()
  currentUrl = link
  if (data && data.currentSlide) {
    slidesnumber = data.currentSlide
  } else {
    slidesnumber = 1
  }

  await taskPlayUrl(link)
})

on('l2s-projector:client:slide-updated', async (newUrl, slideNumber) => {
  currentUrl = newUrl
  slidesnumber = slideNumber

  if (duiObj) {
    SetDuiUrl(duiObj, newUrl)
  } else {
    await taskPlayUrl(newUrl)
  }
})

on('l2s-projector:client:project-stop', () => {
  currentUrl = null
  ourlink = null
  slidesnumber = 1
  CleanupDUI()
})

const taskPlayUrl = async (link) => {
  isPlaying = true
  sfHandle = await loadScaleform(sfName)

  const txd = CreateRuntimeTxd('meows')
  duiObj = CreateDui(link, width, height)
  const dui = GetDuiHandle(duiObj)
  CreateRuntimeTextureFromDuiHandle(txd, 'woof', dui)
}

let targetRegistered = false
let targetZones = []

function cleanupZones() {
  for (const z of targetZones) {
    try {
      if (z.type === 'ox' && GetResourceState('ox_target') === 'started') {
        exports.ox_target.removeZone(z.id)
      } else if (z.type === 'qb' && GetResourceState('qb-target') === 'started') {
        exports['qb-target'].RemoveZone(z.name)
      }
    } catch (e) { }
  }
  targetZones = []
}

const SetupTarget = () => {
  cleanupZones()

  // Tự động gộp tất cả model từ BoardConfigs vào danh sách TargetModels
  const allModels = [...new Set([...TargetModels, ...BoardConfigs.map((b) => b.model).filter(Boolean)])]

  try {
    if (GetResourceState('ox_target') === 'started') {
      const options = [
        {
          name: 'projector_use',
          icon: 'fas fa-display',
          label: 'Use Projector',
          event: 'l2s-projector:client:project',
          groups: TargetJob || undefined,
          distance: 5.0,
        },
        {
          name: 'projector_clear',
          icon: 'fas fa-power-off',
          label: 'Power off',
          event: 'l2s-projector:client:project-clear',
          groups: TargetJob || undefined,
          distance: 5.0,
        },
        {
          name: 'projector_next',
          icon: 'fas fa-caret-right',
          label: 'Next',
          event: 'l2s-projector:client:next',
          groups: TargetJob || undefined,
          distance: 5.0,
        },
        {
          name: 'projector_prev',
          icon: 'fas fa-caret-left',
          label: 'Previous',
          event: 'l2s-projector:client:previous',
          groups: TargetJob || undefined,
          distance: 5.0,
        },
      ]

      // 1. Target theo Model
      exports.ox_target.addModel(allModels, options)

      // 2. Target theo Zone (đảm bảo 100% bắt được kể cả prop không có camera collision như màn chiếu v_ilev_mm_scre_off)
      for (let i = 0; i < BoardConfigs.length; i++) {
        const cfg = BoardConfigs[i]
        const zoneCoords = [cfg.coords[0], cfg.coords[1], cfg.coords[2] + 1.0]
        const zoneId = exports.ox_target.addSphereZone({
          name: 'projector_board_zone_' + i,
          coords: zoneCoords,
          radius: 3.5,
          debug: false,
          options: options,
        })
        targetZones.push({ type: 'ox', id: zoneId })
      }

      targetRegistered = true
      console.log('^2[l2s-projector]^7 Successfully registered target with ox_target (models & zones)')
    } else if (GetResourceState('qb-target') === 'started') {
      const qbOptions = [
        {
          type: 'client',
          event: 'l2s-projector:client:project',
          icon: 'fas fa-display',
          label: 'Use Projector',
          job: TargetJob || false,
        },
        {
          type: 'client',
          event: 'l2s-projector:client:project-clear',
          icon: 'fas fa-power-off',
          label: 'Power off',
          job: TargetJob || false,
        },
        {
          type: 'client',
          event: 'l2s-projector:client:next',
          icon: 'fas fa-caret-right',
          label: 'Next',
          job: TargetJob || false,
        },
        {
          type: 'client',
          event: 'l2s-projector:client:previous',
          icon: 'fas fa-caret-left',
          label: 'Previous',
          job: TargetJob || false,
        },
      ]

      // 1. Target theo Model
      exports['qb-target'].AddTargetModel(allModels, {
        options: qbOptions,
        distance: 5.0,
      })

      // 2. Target theo Zone
      for (let i = 0; i < BoardConfigs.length; i++) {
        const cfg = BoardConfigs[i]
        const zoneCoords = [cfg.coords[0], cfg.coords[1], cfg.coords[2] + 1.0]
        const zoneName = 'projector_board_zone_' + i
        exports['qb-target'].AddCircleZone(
          zoneName,
          zoneCoords,
          3.5,
          {
            name: zoneName,
            debugPoly: false,
          },
          {
            options: qbOptions,
            distance: 5.0,
          }
        )
        targetZones.push({ type: 'qb', name: zoneName })
      }

      targetRegistered = true
      console.log('^2[l2s-projector]^7 Successfully registered target with qb-target (models & zones)')
    }
  } catch (err) {
    console.error('^1[l2s-projector] Error registering target:^7', err.message || err)
  }
}

on('QBCore:Client:OnPlayerLoaded', () => {
  SetupTarget()
  spawnBoards()
})

on('qbx_core:client:playerLoaded', () => {
  SetupTarget()
  spawnBoards()
})

on('esx:playerLoaded', () => {
  SetupTarget()
  spawnBoards()
})

on('onClientResourceStart', (resName) => {
  if (
    resName === GetCurrentResourceName() ||
    resName === 'ox_target' ||
    resName === 'qb-target'
  ) {
    SetupTarget()
    spawnBoards()
  }
})

// Tự động spawn khi client session đã sẵn sàng
setImmediate(async () => {
  while (!NetworkIsSessionStarted()) {
    await new Promise((resolve) => setTimeout(resolve, 500))
  }
  SetupTarget()
  spawnBoards()
  emitNet('l2s-projector:server:request-sync')
})

// Lệnh reload lại bảng cho admin / dev test
RegisterCommand('reloadprojectorboard', () => {
  targetRegistered = false
  SetupTarget()
  spawnBoards()
  console.log('^2[l2s-projector]^7 Reloaded projector board(s) and targets.')
}, false)

on('onResourceStop', (resName) => {
  if (resName === GetCurrentResourceName()) {
    CleanupDUI()
    cleanupBoards()
    cleanupZones()
    if (targetRegistered) {
      try {
        const allModels = [...new Set([...TargetModels, ...BoardConfigs.map((b) => b.model).filter(Boolean)])]
        if (GetResourceState('ox_target') === 'started') {
          for (const m of allModels) {
            exports.ox_target.removeModel(m, [
              'projector_use',
              'projector_clear',
              'projector_next',
              'projector_prev',
            ])
          }
        } else if (GetResourceState('qb-target') === 'started') {
          for (const m of allModels) {
            exports['qb-target'].RemoveTargetModel(m, [
              'Use Projector',
              'Power off',
              'Next',
              'Previous',
            ])
          }
        }
      } catch (e) {
        // Ignore removal error on stop
      }
    }
  }
})

const CleanupDUI = () => {
  if (duiObj) {
    DestroyDui(duiObj)
    SetScaleformMovieAsNoLongerNeeded(0)
    duiObj = null
    txdHasBeenSet = false
    sfHandle = null
    isPlaying = false
  }
}