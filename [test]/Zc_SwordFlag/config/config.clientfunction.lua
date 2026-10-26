Notify = function(msg, typemsg) -- Thông báo
    lib.notify({ description = msg, type = typemsg, duration = 3000 })
end

DrawText2D = function(x, y, scale, width, height, text)
    -- Dùng font mặc định của GTA để tránh lỗi Unicode/ô vuông
    SetTextFont(0)
    SetTextProportional(0)
    SetTextScale(0.4, 0.4)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width / 2.3, y - height / 1 + 0.005)
end

DrawText2D2 = function(x, y, scale, width, height, text)
    SetTextFont(0)
    SetTextProportional(0)
    SetTextScale(0.4, 0.4)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width / 2.3, y - height / 1 + 0.005)
end

ShowToolTip = function(msg, x, y, z)
    AddTextEntry("Test", msg)
    SetFloatingHelpTextWorldPosition(1, x, y, z)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    BeginTextCommandDisplayHelp("Test")
    EndTextCommandDisplayHelp(2, false, false, -1)
end

DrawText3D = function(x, y, z, text)
    if SanitizeNativeText then
        text = SanitizeNativeText(text)
    end
    SetDrawOrigin(x, y, z, 0)
    SetTextFont(0)
    SetTextProportional(0)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 215)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextOutline()
    SetTextCentre(1)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentString(text or '')
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function TryReviveNow()
    local reviveCfg = (Config and Config.Revive) or {}
    local tries = reviveCfg.tries or 1
    local retryDelayMs = reviveCfg.retryDelayMs or 500

    TriggerServerEvent('zcSword_RequestRevive')
    for _ = 1, tries do
        Wait(retryDelayMs)
        if not SwordPlayerIsDown() then
            return true
        end
    end
    return not SwordPlayerIsDown()
end

function SwordPlayerIsDown()
    local ped = PlayerPedId()
    return IsPedDeadOrDying(ped, true) or GetEntityHealth(ped) <= 0
        or exports.qbx_medical:IsDead() or exports.qbx_medical:IsLaststand()
end

function ReviveBuff()
    TryReviveNow()
end

function ReviveOnStartOrEnd()
    TryReviveNow()
end

function Revive()
    if not TryReviveNow() then return end
    Wait(300)
    SetEntityCoords(PlayerPedId(),
        Config.StartPoint.x + math.random(-5, 5),
        Config.StartPoint.y + math.random(-5, 5),
        Config.StartPoint.z + 1)
    Wait(300)
    SetEntityHealth(PlayerPedId(), 200)
end

function playanimation()
    local animdict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
    local animname = "machinic_loop_mechandplayer"
    RequestAnimDict(animdict)
    while not HasAnimDictLoaded(animdict) do Citizen.Wait(1) end
    TaskPlayAnim(PlayerPedId(), animdict, animname, 8.0, -8.0, -1, 48, 0, false,
        40, false)
    FreezeEntityPosition(PlayerPedId(), true)
end

Keys = {
    ["ESC"] = 322,
    ["F1"] = 288,
    ["F2"] = 289,
    ["F3"] = 170,
    ["F5"] = 166,
    ["F6"] = 167,
    ["F7"] = 168,
    ["F8"] = 169,
    ["F9"] = 56,
    ["F10"] = 57,
    ["~"] = 243,
    ["1"] = 157,
    ["2"] = 158,
    ["3"] = 160,
    ["4"] = 164,
    ["5"] = 165,
    ["6"] = 159,
    ["7"] = 161,
    ["8"] = 162,
    ["9"] = 163,
    ["-"] = 84,
    ["="] = 83,
    ["BACKSPACE"] = 177,
    ["TAB"] = 37,
    ["Q"] = 44,
    ["W"] = 32,
    ["E"] = 38,
    ["R"] = 45,
    ["T"] = 245,
    ["Y"] = 246,
    ["U"] = 303,
    ["P"] = 199,
    ["["] = 39,
    ["]"] = 40,
    ["ENTER"] = 18,
    ["CAPS"] = 137,
    ["A"] = 34,
    ["S"] = 8,
    ["D"] = 9,
    ["F"] = 23,
    ["G"] = 47,
    ["H"] = 74,
    ["K"] = 311,
    ["L"] = 182,
    ["LEFTSHIFT"] = 21,
    ["Z"] = 20,
    ["X"] = 73,
    ["C"] = 26,
    ["V"] = 0,
    ["B"] = 29,
    ["N"] = 249,
    ["M"] = 244,
    [","] = 82,
    ["."] = 81,
    ["LEFTCTRL"] = 36,
    ["ALT"] = 19,
    ["SPACE"] = 22,
    ["RIGHTCTRL"] = 70,
    ["HOME"] = 213,
    ["PAGEUP"] = 10,
    ["PAGEDOWN"] = 11,
    ["DELETE"] = 178,
    ["LEFT"] = 174,
    ["RIGHT"] = 175,
    ["TOP"] = 27,
    ["DOWN"] = 173,
    ["NENTER"] = 201,
    ["N4"] = 108,
    ["N5"] = 60,
    ["N6"] = 107,
    ["N+"] = 96,
    ["N-"] = 97,
    ["N7"] = 117,
    ["N8"] = 61,
    ["N9"] = 118,
    ["Enter"] = 191
}
