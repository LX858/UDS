cameraOpen = false
isSelfieMode = false
isVideoMode = false
isHudHidden = false
recordingPeerId = nil
baseUrl = nil
photoTypes = {}
photoTypes.selfies = "selfie"
photoTypes.screenshots = "screenshot"
photoTypes.imports = "import"

function OpenCellCamera()
  CreateMobilePhone(0)
  CellCamActivate(true, true)
  Citizen.InvokeNative(2635073306796480568, isSelfieMode)
  SetTimeout(500, function()
    local objects = GetGamePool("CObject")
    local playerCoords = GetEntityCoords(PlayerPedId())
    for i = 1, #objects, 1 do
      local object = objects[i]
      local objectCoords = GetEntityCoords(object)
      local distance = #(playerCoords - objectCoords)
      if distance < 4.0 then
        local model = GetEntityModel(object)
        if 413312110 == model then
          SetEntityAsMissionEntity(object, true, true)
          DeleteObject(object)
        end
      end
    end
  end)
  while true do
    if not phoneOpen then
      break
    end
    if not cameraOpen then
      break
    end
    if IsWalkingCamEnabled() then
      break
    end
    Wait(250)
    InvalidateIdleCam()
    InvalidateVehicleIdleCam()
  end
  DestroyMobilePhone()
  if cameraOpen then
    if not IsWalkingCamEnabled() then
      while true do
        if phoneOpen then
          break
        end
        Wait(500)
      end
      OpenCellCamera()
    end
  end
end

function ShowCameraInstructions()
  if isHudHidden then
    return
  end
  local showTip = Config.Camera
  if showTip then
    showTip = showTip.ShowTip
  end
  if false == showTip then
    return
  end
  local instructions = {}
  local takePhotoConfig = Config.KeyBinds.TakePhoto
  if takePhotoConfig then
    takePhotoConfig = takePhotoConfig.Command
  end
  if takePhotoConfig then
    local index = #instructions + 1
    local text = L("BACKEND.CAMERA.TAKE_PHOTO", {key = Config.KeyBinds.TakePhoto.bindData.instructional})
    instructions[index] = text
  end
  local flipCameraConfig = Config.KeyBinds.FlipCamera
  if flipCameraConfig then
    flipCameraConfig = flipCameraConfig.Command
  end
  if flipCameraConfig then
    local index = #instructions + 1
    local text = L("BACKEND.CAMERA.FLIP_CAMERA", {key = Config.KeyBinds.FlipCamera.bindData.instructional})
    instructions[index] = text
  end
  local toggleFlashConfig = Config.KeyBinds.ToggleFlash
  if toggleFlashConfig then
    toggleFlashConfig = toggleFlashConfig.Command
  end
  if toggleFlashConfig then
    local index = #instructions + 1
    local text = L("BACKEND.CAMERA.TOGGLE_FLASH", {key = Config.KeyBinds.ToggleFlash.bindData.instructional})
    instructions[index] = text
  end
  local leftModeConfig = Config.KeyBinds.LeftMode
  if leftModeConfig then
    leftModeConfig = leftModeConfig.Command
  end
  if leftModeConfig then
    local rightModeConfig = Config.KeyBinds.RightMode
    if rightModeConfig then
      rightModeConfig = rightModeConfig.Command
    end
    if rightModeConfig then
      local index = #instructions + 1
      local text = L("BACKEND.CAMERA.CHANGE_MODE", {
        key = Config.KeyBinds.LeftMode.bindData.instructional,
        key2 = Config.KeyBinds.RightMode.bindData.instructional
      })
      instructions[index] = text
    end
  end
  local rollLeftConfig = Config.KeyBinds.RollLeft
  if rollLeftConfig then
    rollLeftConfig = rollLeftConfig.Command
  end
  if rollLeftConfig then
    local rollRightConfig = Config.KeyBinds.RollRight
    if rollRightConfig then
      rollRightConfig = rollRightConfig.Command
    end
    if rollRightConfig then
      local index = #instructions + 1
      local text = L("BACKEND.CAMERA.ROLL", {
        key = Config.KeyBinds.RollLeft.bindData.instructional,
        key2 = Config.KeyBinds.RollRight.bindData.instructional
      })
      instructions[index] = text
    end
  end
  local freezeEnabled = Config.Camera
  if freezeEnabled then
    freezeEnabled = freezeEnabled.Freeze
    if freezeEnabled then
      freezeEnabled = freezeEnabled.Enabled
    end
  end
  if freezeEnabled then
    local freezeCameraConfig = Config.KeyBinds.FreezeCamera
    if freezeCameraConfig then
      freezeCameraConfig = freezeCameraConfig.Command
    end
    if freezeCameraConfig then
      local index = #instructions + 1
      local text = L("BACKEND.CAMERA.FREEZE", {key = Config.KeyBinds.FreezeCamera.bindData.instructional})
      instructions[index] = text
    end
  end
  local focusConfig = Config.KeyBinds.Focus
  if focusConfig then
    focusConfig = focusConfig.Command
  end
  if focusConfig then
    local index = #instructions + 1
    local text = L("BACKEND.CAMERA.TOGGLE_CURSOR", {key = Config.KeyBinds.Focus.bindData.instructional})
    instructions[index] = text
  end
  local instructionCount = #instructions
  if instructionCount > 0 then
    local instructionText = table.concat(instructions, "\n")
    AddTextEntry("CAMERA_TIP2", instructionText)
    BeginTextCommandDisplayHelp("CAMERA_TIP2")
    EndTextCommandDisplayHelp(0, true, true, 0)
  end
end

function ParseFilterData(filterData)
  local album = filterData.album
  if "recents" == album then
    filterData.album = nil
  else
    local album = filterData.album
    if "favourites" == album then
      filterData.album = nil
      filterData.favourites = true
    end
  end
  local filterType = filterData.type
  if "videos" == filterType then
    local videoFilter = {}
    videoFilter.showPhotos = false
    videoFilter.showVideos = true
    filterData = videoFilter
  end
  local filterType = filterData.type
  if filterType then
    filterData.album = nil
    local mappedType = photoTypes[filterType]
    if mappedType then
      local mappedType = photoTypes[filterType]
      filterData.type = mappedType
    else
      filterData.type = nil
      filterData.duplicates = true
    end
  end
  local showPhotos = filterData.showPhotos
  if not showPhotos then
    local showVideos = filterData.showVideos
    if not showVideos then
      filterData.showPhotos = true
      filterData.showVideos = true
    end
  end
  return filterData
end

function GetUploadMethod(uploadType)
  local uploadMethod = nil
  local customMethod = CustomGetUploadMethod
  if customMethod then
    local method = CustomGetUploadMethod(uploadType)
    uploadMethod = method
  else
    local methods = UploadMethods[Config.UploadMethod[uploadType]]
    if not methods then
      infoprint("error", "Upload methods not found for ", uploadType)
      return
    end
    local typeMethod = methods[uploadType] or uploadMethod
    uploadMethod = typeMethod
    if not typeMethod then
      uploadMethod = methods.Default
    end
    if not uploadMethod then
      infoprint("error", "Upload method not found for ", uploadType)
      return
    end
  end
  local method = uploadMethod.method
  if not method then
    local configMethod = Config.UploadMethod[uploadType]
    uploadMethod.method = configMethod
  end
  local sendPlayer = uploadMethod.sendPlayer
  if sendPlayer then
    local player = uploadMethod.player
    if not player then
      local playerData = {}
      local identifier = GetIdentifier()
      playerData.identifier = identifier
      local playerName = GetPlayerName(PlayerId())
      playerData.name = playerName
      uploadMethod.player = playerData
    end
  end
  local url = uploadMethod.url
  local hasBaseUrl = url:find("BASE_URL")
  if hasBaseUrl then
    local currentBaseUrl = baseUrl
    if not currentBaseUrl then
      local fetchedBaseUrl = AwaitCallback("camera:getBaseUrl")
      baseUrl = fetchedBaseUrl
    end
    local newUrl = uploadMethod.url:gsub("BASE_URL", baseUrl)
    uploadMethod.url = newUrl
  end
  local hasApiKey = false
  local url = uploadMethod.url
  local urlHasApiKey = url:find("API_KEY")
  if urlHasApiKey then
    hasApiKey = true
  else
    local headers = uploadMethod.headers
    if headers then
      for headerKey, headerValue in pairs(uploadMethod.headers) do
        local hasKeyInHeader = headerValue:find("API_KEY")
        if hasKeyInHeader then
          hasApiKey = true
          break
        end
      end
    end
  end
  if hasApiKey then
    local apiKey = AwaitCallback("camera:getUploadApiKey", uploadType)
    local newUrl = uploadMethod.url:gsub("API_KEY", apiKey)
    uploadMethod.url = newUrl
    local headers = uploadMethod.headers
    if headers then
      for headerKey, headerValue in pairs(uploadMethod.headers) do
        local newHeaderValue = headerValue:gsub("API_KEY", apiKey)
        uploadMethod.headers[headerKey] = newHeaderValue
      end
    end
  end
  local url = uploadMethod.url
  local hasPresignedUrl = url:find("PRESIGNED_URL")
  if hasPresignedUrl then
    local presignedUrl = AwaitCallback("camera:getPresignedUrl", uploadType)
    if not presignedUrl then
      infoprint("error", "Failed to get presigned url for " .. uploadType)
      return
    end
    local newUrl = uploadMethod.url:gsub("PRESIGNED_URL", presignedUrl)
    uploadMethod.presignedUrl = newUrl
  end
  return uploadMethod
end

RegisterNUICallback("Camera", function(data, callback)
  local phone = currentPhone
  if not phone then
    return
  end
  if not data then
    debugprint("Camera data is nil")
    return
  end
  local action = data.action
  debugprint("Camera:" .. (action or ""))
  if "open" == action then
    callback("ok")
    cameraOpen = true
    ShowCameraInstructions()
    local cameraEnabled = Config.Camera
    if cameraEnabled then
      cameraEnabled = cameraEnabled.Enabled
    end
    if cameraEnabled then
      EnableWalkableCam()
    else
      OpenCellCamera()
    end
  elseif "saveToGallery" == action then
    TriggerCallback("camera:saveToGallery", callback, data.link, data.size, data.isVideo and true or false, data.type, data.shouldLog)
  elseif "deleteFromGallery" == action then
    local idsType = type(data.ids)
    if "table" ~= idsType then
      local idsList = {}
      local id = data.ids
      idsList[1] = id
      data.ids = idsList
    end
    TriggerCallback("camera:deleteFromGallery", callback, data.ids)
  elseif "getLastImage" == action then
    TriggerCallback("camera:getLastImage", callback)
  elseif "getImages" == action then
    local filter = ParseFilterData(data.filter or {})
    local images = AwaitCallback("camera:getImages", filter, data.page or 0)
    local formattedImages = {}
    for i = 1, #images, 1 do
      local image = images[i]
      local formatted = {}
      local id = image.id
      formatted.id = id
      local link = image.link
      formatted.src = link
      local isVideo = image.is_video
      formatted.isVideo = isVideo
      local metadata = image.metadata
      formatted.type = metadata
      local isFavourite = image.is_favourite
      formatted.favourite = isFavourite
      local timestamp = image.timestamp
      formatted.timestamp = timestamp
      local size = image.size or 0
      formatted.size = size
      formattedImages[i] = formatted
    end
    callback(formattedImages)
  elseif "getAlbums" == action then
    TriggerCallback("camera:getHomePageData", callback)
  elseif "createAlbum" == action then
    TriggerCallback("camera:createAlbum", callback, data.title)
  elseif "renameAlbum" == action then
    TriggerCallback("camera:renameAlbum", callback, data.id, data.title)
  elseif "addToAlbum" == action then
    TriggerCallback("camera:addToAlbum", callback, data.album, data.ids)
  elseif "removeFromAlbum" == action then
    TriggerCallback("camera:removeFromAlbum", callback, data.album, data.ids)
  elseif "deleteAlbum" == action then
    TriggerCallback("camera:deleteAlbum", callback, data.id)
  elseif "removeMemberFromAlbum" == action then
    TriggerCallback("camera:removeMemberFromAlbum", callback, data.number, data.album)
  elseif "leaveSharedAlbum" == action then
    TriggerCallback("camera:leaveSharedAlbum", callback, data.id)
  elseif "getAlbumMembers" == action then
    TriggerCallback("camera:getAlbumMembers", callback, data.id)
  elseif "toggleFavourites" == action then
    TriggerCallback("camera:toggleFavourites", callback, data.favourite, data.ids)
  elseif "toggleVideo" == action then
    local currentVideoMode = isVideoMode
    local newVideoMode = data.toggled
    if currentVideoMode == newVideoMode then
      callback("ok")
      return
    end
    local toggled = data.toggled
    isVideoMode = toggled
    cameraOpen = true
    callback("ok")
    SendReactMessage("camera:toggleMicrophone", IsTalking())
    local videoMode = isVideoMode
    if not videoMode then
      local cameraEnabled = Config.Camera
      if cameraEnabled then
        cameraEnabled = cameraEnabled.Enabled
      end
      if not cameraEnabled then
        goto continueExecution
      end
    end
    EnableWalkableCam(isSelfieMode)
    goto endExecution
    ::continueExecution::
    DisableWalkableCam()
    OpenCellCamera()
    ::endExecution::
  elseif "toggleHud" == action then
    local toggled = data.toggled
    toggled = not toggled
    isHudHidden = toggled
    TriggerEvent("lb-phone:toggleHud", isHudHidden)
    SetTimeout(100, function()
      callback(true)
    end)
    while true do
      local hudHidden = isHudHidden
      if not hudHidden then
        break
      end
      Wait(0)
      HideHudComponents()
    end
  elseif "getUploadApi" == action then
    callback(GetUploadMethod(data.uploadType) or false)
  elseif "toggleLandscape" == action then
    local phoneObject = GetPhoneObject()
    local playerPed = PlayerPedId()
    local entityExists = DoesEntityExist(phoneObject)
    if not entityExists then
      return
    end
    local toggled = data.toggled
    if toggled then
      AttachEntityToEntity(phoneObject, playerPed, GetPedBoneIndex(playerPed, 28422), -0.03, -0.005, -0.02, 0.0, 90.0, 180.0, false, false, false, false, 2, true)
    else
      AttachEntityToEntity(phoneObject, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, -0.005, 0.0, 0.0, 0.0, 180.0, false, false, false, false, 2, true)
    end
    callback("ok")
  elseif "flipCamera" == action then
    local value = data.value
    value = true == value
    data.value = value
    local currentSelfieMode = isSelfieMode
    local newSelfieMode = data.value
    if currentSelfieMode == newSelfieMode then
      callback("ok")
      return
    end
    local value = data.value
    isSelfieMode = value
    local walkingCamEnabled = IsWalkingCamEnabled()
    if walkingCamEnabled then
      ToggleSelfieCam(isSelfieMode)
    else
      Citizen.InvokeNative(2635073306796480568, isSelfieMode)
    end
    callback("ok")
  elseif "setQuickZoom" == action then
    local value = data.value
    local walkingCamEnabled = IsWalkingCamEnabled()
    if walkingCamEnabled then
      SetCameraZoom(value)
    end
    callback(true)
  elseif "setRecordingPeerId" == action then
    TriggerServerEvent("phone:camera:setPeer", data.peerId)
    local peerId = data.peerId
    recordingPeerId = peerId
    callback("ok")
  elseif "endedRecording" == action then
    local peerId = recordingPeerId
    if peerId then
      TriggerServerEvent("phone:camera:endedRecording", recordingPeerId)
      local nilValue = nil
      recordingPeerId = nilValue
      callback("ok")
    end
  elseif "close" == action then
    cameraOpen = false
    local falseValue = false
    isVideoMode = falseValue
    local falseValue = false
    isSelfieMode = falseValue
    ClearAllHelpMessages()
    ClearHelp(true)
    DisableWalkableCam()
    callback("ok")
  end
end)

exports("SaveToGallery", function(link)
  assert(type(link) == "string", "Expected string for link, got " .. type(link))
  SendReactMessage("saveMedia", link)
end)

RegisterNetEvent("phone:photos:addMemberToAlbum", function(albumId, phoneNumber)
  SendReactMessage("photos:addMemberToAlbum", {albumId = albumId, phoneNumber = phoneNumber})
end)

RegisterNetEvent("phone:photos:removeMemberFromAlbum", function(albumId, phoneNumber)
  SendReactMessage("photos:removeMemberFromAlbum", {albumId = albumId, phoneNumber = phoneNumber})
end)

RegisterNetEvent("phone:photos:addSharedAlbum", function(album)
  SendReactMessage("photos:addSharedAlbum", album)
end)

RegisterNetEvent("phone:photos:updateAlbum", function(album)
  debugprint("phone:photos:updateAlbum", album)
  SendReactMessage("photos:updateAlbum", album)
end)
