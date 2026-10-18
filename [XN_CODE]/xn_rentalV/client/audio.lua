local config = ScootConfig
local ScootAudioApi = {}
local activeSounds = {}
local nextSoundId = 0
local loopRunning = false

function getCamRelativeCoords(coords)
  local camCoord = GetGameplayCamCoord()
  local camRot = GetGameplayCamRot(2)
  local pitch = math.rad(camRot.x)
  local yaw = math.rad(camRot.z)

  local cosPitch = math.cos(pitch)
  local forwardX = -math.sin(yaw) * cosPitch
  local forwardY = math.cos(yaw) * cosPitch
  local forwardZ = math.sin(pitch)
  local rightX = math.cos(yaw)
  local rightY = math.sin(yaw)
  local upX = rightY * forwardZ
  local upY = -rightX * forwardZ
  local upZ = rightX * forwardY - rightY * forwardX

  local dx = coords.x - camCoord.x
  local dy = coords.y - camCoord.y
  local dz = coords.z - camCoord.z

  local x = dx * rightX + dy * rightY
  local y = dx * upX + dy * upY + dz * upZ
  local z = -(dx * forwardX + dy * forwardY + dz * forwardZ)
  local distance = #(coords - camCoord)

  return x, y, z, distance
end

function sendSpatialSound(action, id, entry)
  local x, y, z, distance = getCamRelativeCoords(entry.coords)
  if distance > config.soundDistance then
    SendNUIMessage({
      action = "update",
      id = id,
      volume = 0.0,
      x = x,
      y = y,
      z = z,
    })
    return
  end

  SendNUIMessage({
    action = action,
    id = id,
    file = entry.file,
    loop = true,
    volume = entry.base * config.soundVolume,
    x = x,
    y = y,
    z = z,
    ref = config.soundRefDistance,
    max = config.soundDistance,
    rolloff = config.soundRolloff,
  })
end

function ensureAudioLoop()
  if loopRunning then
    return
  end

  loopRunning = true
  CreateThread(function()
    while true do
      if not next(activeSounds) then
        break
      end

      local now = GetGameTimer()
      for id, entry in pairs(activeSounds) do
        if now >= entry.expires then
          activeSounds[id] = nil
          SendNUIMessage({
            action = "stop",
            id = id,
          })
        else
          sendSpatialSound("update", id, entry)
        end
      end

      Wait(50)
    end

    loopRunning = false
  end)
end

function ScootAudioApi.play(file, coords, baseVolume, durationSeconds)
  if not config.playSounds then
    return
  end

  local _, _, _, distance = getCamRelativeCoords(coords)
  if distance > config.soundDistance then
    return
  end

  nextSoundId = nextSoundId + 1
  local id = nextSoundId
  activeSounds[id] = {
    coords = coords,
    base = baseVolume,
    file = file,
    expires = GetGameTimer() + math.floor(durationSeconds * 1000) + 200,
  }

  sendSpatialSound("play", id, activeSounds[id])
  ensureAudioLoop()
  return id
end

function ScootAudioApi.stopAll()
  for id in pairs(activeSounds) do
    activeSounds[id] = nil
    SendNUIMessage({
      action = "stop",
      id = id,
    })
  end
end

function ScootAudioApi.stop(id)
  if id then
    activeSounds[id] = nil
    SendNUIMessage({
      action = "stop",
      id = id,
    })
  end
end

CreateThread(function()
  if not config.playSounds then
    return
  end

  local files = {}
  for i = 1, #config.sounds do
    files[#files + 1] = config.sounds[i].file
  end

  Wait(1000)
  SendNUIMessage({
    action = "preload",
    files = files,
  })
end)

ScootAudio = ScootAudioApi
