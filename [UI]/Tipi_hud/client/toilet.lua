local isSick = false
local notifyTimer = 0
local NOTIFY_COOLDOWN = 30000   
local CHECK_INTERVAL = 5000     
local EFFECT_DURATION = 15000   

local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

local function LoadAnimSet(animSet)
    RequestAnimSet(animSet)
    while not HasAnimSetLoaded(animSet) do
        Wait(10)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────

function StopStomachPain()
    if not isSick then return end
    isSick = false

    local ped = PlayerPedId()

    ClearPedTasks(ped)
    ResetPedMovementClipset(ped, 0.5)
    SetPedMotionBlur(ped, false)

    StopScreenEffect("DrugsTrevorClownsFight")
    StopGameplayCamShaking(true)
end

local function StartStomachPain(duration)
    if isSick then return end
    isSick = true

    local ped = PlayerPedId()
    local animDict = "amb@world_human_bum_standing@depressed@idle_a"
    local animName = "idle_a"

    LoadAnimDict(animDict)
    LoadAnimSet("move_m@drunk@verydrunk")

    SetPedMovementClipset(ped, "move_m@drunk@verydrunk", 1.0)
    StartScreenEffect("DrugsTrevorClownsFight", 0, true)
    ShakeGameplayCam("DRUNK_SHAKE", 1.2)
    SetPedMotionBlur(ped, true)

    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)

    CreateThread(function()
        local endTime = GetGameTimer() + duration

        while isSick and GetGameTimer() < endTime do
            local playerPed = PlayerPedId()

            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 22, true) -- Jump
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 44, true) -- Cover
            if math.random(1, 100) <= 3 then
                ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.15)
            end

            if not IsEntityPlayingAnim(playerPed, animDict, animName, 3) then
                TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
            end

            Wait(500)
        end

        StopStomachPain()
    end)
end

CreateThread(function()
    while true do
        Wait(CHECK_INTERVAL)

        if not loaded then goto continue end

        local poopVal = getPoop()
        local peeVal  = getPee()

        if poopVal >= 80 or peeVal >= 80 then
            local now = GetGameTimer()
            if now - notifyTimer >= NOTIFY_COOLDOWN then
                notifyTimer = now
                lib.notify({
                    title = "Cảnh báo sức khoẻ",
                    description = "Bạn đang buồn vệ sinh! Hãy tìm nơi để giải quyết nỗi buồn.",
                    type = "warning",
                    duration = 6000,
                    position = "top-right",
                })
            end

            StartStomachPain(EFFECT_DURATION)
        else
            if isSick then
                StopStomachPain()
            end
        end

        ::continue::
    end
end)
