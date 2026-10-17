local MAX_FOV = 100.0
local MIN_FOV = 2.0
local ZOOM_SPEED = 10.0
local LR_SPEED = 8.0
local UD_SPEED = 8.0
local binoculars = false
local fov = (MAX_FOV + MIN_FOV) * 0.5
local cam = nil

-- Khởi tạo QBX
local QBX = exports.qbx_core:GetPlayerData()

local function closeBinoculars()
    ClearTimecycleModifier()
    fov = (MAX_FOV + MIN_FOV) * 0.5
    ClearPedTasks(cache.ped)
    RenderScriptCams(false, false, 500, true, false)
    DestroyCam(cam, false)
    cam = nil
    binoculars = false
end

-- Đăng ký Keybind để thoát
lib.addKeybind({
    name = 'closeBinoculars',
    description = 'Close Binoculars',
    defaultKey = 'BACK',
    onPressed = function()
        if binoculars then closeBinoculars() end
    end,
})

-- Hàm Toggle chính
local function toggleBinoculars()
    if cache.vehicle or IsPedSwimming(cache.ped) then return end
    
    binoculars = not binoculars

    if binoculars then
        TaskStartScenarioInPlace(cache.ped, 'WORLD_HUMAN_BINOCULARS', 0, true)
        cam = CreateCam('DEFAULT_SCRIPTED_FLY_CAMERA', true)
        AttachCamToEntity(cam, cache.ped, 0.0, 0.2, 0.7, true)
        SetCamRot(cam, 0.0, 0.0, GetEntityHeading(cache.ped), 2)
        RenderScriptCams(true, false, 500, true, false)
        
        CreateThread(function()
            local scaleform = lib.requestScaleformMovie('BINOCULARS')
            while binoculars do
                BeginScaleformMovieMethod(scaleform, 'SET_CAM_LOGO')
                ScaleformMovieMethodAddParamInt(0)
                EndScaleformMovieMethod()

                -- Xử lý Zoom & Xoay
                local zoomValue = (1.0 / (MAX_FOV - MIN_FOV)) * (fov - MIN_FOV)
                
                -- Check Rotation trực tiếp
                local rightAxisX = GetControlNormal(0, 220)
                local rightAxisY = GetControlNormal(0, 221)
                local rot = GetCamRot(cam, 2)
                if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
                    local newZ = rot.z + rightAxisX * -1.0 * (UD_SPEED) * (zoomValue + 0.1)
                    local newX = math.max(math.min(20.0, rot.x + rightAxisY * -1.0 * (LR_SPEED) * (zoomValue + 0.1)), -89.5)
                    SetCamRot(cam, newX, 0.0, newZ, 2)
                    SetEntityHeading(cache.ped, newZ)
                end

                -- Check Zoom
                if IsControlJustPressed(0, 241) then fov = math.max(fov - ZOOM_SPEED, MIN_FOV) end
                if IsControlJustPressed(0, 242) then fov = math.min(fov + ZOOM_SPEED, MAX_FOV) end
                
                local currentFov = GetCamFov(cam)
                if math.abs(fov - currentFov) > 0.01 then
                    SetCamFov(cam, currentFov + (fov - currentFov) * 0.05)
                end

                -- Hide HUD & Draw
                HideHudAndRadarThisFrame()
                DrawScaleformMovie(scaleform, 0.5, 0.5, 1.0, 1.0, 255, 255, 255, 255)
                Wait(0)
            end
        end)
    else
        closeBinoculars()
    end
end

-- Export và Event
RegisterNetEvent('qbx_binoculars:client:toggle', toggleBinoculars)
exports('useBinoculars', toggleBinoculars)

-- Lệnh Test (Gõ /testbinoc trong game)
RegisterCommand('testbinoc', function()
    toggleBinoculars()
end)