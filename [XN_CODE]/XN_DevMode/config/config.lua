Config = {}

Config.Blips = {
}

Config.RemoveDurabilityQuanlity = {
    ["dohotrac"] = 5,
    ["caixeng"] = 2,
    ["keo"] = 5,
    ["maydomin"] = 5,
    ["lockpick"] = 25,
    ["fishingrod"] = 10,
    ["fishingrod1"] = 0,
    ["fishingrod2"] = 0,
    ["fishingrod3"] = 0,
    ["fishingrod4"] = 0,
    ["fishingrod5"] = 0,
    ["advancedlockpick"] = 5,
    ["bao_thuoc_lion"] = 10,
    ["lighter"] = 2,
    ["cuoc_dao_da"] = 2,
    ["cai_phay"] = 2,
    ["cay_keo"] = 2,
    ["may_xay"] = 2,
    ["may_cua"] = 10,
    ["scissors"] = 5,
    ["WEAPON_MACHETE"] = 20,
    ["xa_beng"] = 25

}

Config.GiveVehicleRewards = true
Config.Weaponlist = {
    -- Melee
    WEAPON_UNARMED = 0.5,
    WEAPON_CONCA = 0,
    WEAPON_DENONGSAO = 0,
    WEAPON_FLASHLIGHT = 0,
    WEAPON_NIGHTSTICK = 0.9,
}

-- Duty toggle locations
Config.DutyLocations = {
    {
        coords = vec3(-348.6151, -127.7593, 39.1990),
        heading = 0.0,
        jobs = { "mechanic" }, -- Job(s) được thấy và tương tác với zone này (ví dụ: "police" hoặc {"police", "toathichinh"})
        label = "On/Off Duty"
    },
}

Config.Weapon = {
    {WeaponName = "WEAPON_UNARMED", WeaponDamage = 0.05},
    {WeaponName = "WEAPON_MACHETE", WeaponDamage = 0.0},
    {WeaponName = "WEAPON_FLASHLIGHT", WeaponDamage = 0.0},
    {WeaponName = "WEAPON_NIGHTSTICK", WeaponDamage = 0.9},

}

Config.GenderNumbers = {['male'] = 4, ['female'] = 5}

Config.PedList = {
    -- { ---  BÁN XE
    --     model = 's_m_y_devi',
    --     coords = vector4(-3022.9519, 81.8312, 10.6081, 320.000),
    --     gender = 'male',
    --     scenario = 'WORLD_HUMAN_CLIPBOARD_FACILITY'
    -- }
    -- { ---  BÁN đồ sạch
    --     model = 'a_m_m_mlcrisis_01',
    --     coords = vec4(452.19, -759.57, 27.36, 272.54),
    --     gender = 'male',
    --     scenario = 'WORLD_HUMAN_CLIPBOARD_FACILITY'
    -- },
    -- { ---  BÁN đồ sạch
    --     model = 'a_m_m_mlcrisis_01',
    --     coords = vec4(452.16, -752.9, 27.36, 265.4),
    --     gender = 'male',
    --     scenario = 'WORLD_HUMAN_CLIPBOARD_FACILITY'
    -- }
}

Config.Target = {
    [1] = { --- MỞ MENU XEM XE VÀ BÁN XE
        name = 'cardealer',
        coords = vec3(-788.3723, -226.7200, 38.0505),
        type = 'client',
        event = "1307_Cardealer:cl:OpenXemXe",
        label = 'Xem List Xe',
        distance = 3.0,

    },

    [10] = { --- MỞ MENU XEM XE VÀ BÁN XE
        name = 'cardealer',
        coords = vec3(-788.3723, -226.7200, 38.0505),
        type = 'client',
        event = "1307_Cardealer:cl:OpenNUI",
        label = 'Quản lý Cardealer',
        distance = 3.0,
        Job = 'cardealer'
    },
}

Config.DrawingTime = 20 * 1000
Config.TextColor = {r = 255, g = 255, b = 255}

Config.waitTimeInSeconds = 5
Config.waitTime = Config.waitTimeInSeconds * 1000

Config.whitelistedJobs = {"police", "toathichinh", "ambulance", 'hocvien', 'mechanic'}

Config.whitelistedJobs2 = {"toathichinh", "ambulance", "police"}

Config.whitelistedJobs3 = {"police", "ambulance", "toathichinh", 'mechanic'}

Config.whitelistedJobsAmbulance = {"ambulance", "mechanic"}

Config.CitizenID_List = {
    "XN Coding" -- 
}
-- Vị trí cho command /bring citizenid [location]
Config.BringLocations = {
    ['garage'] = vec4(-340.89, -874.54, 31.08, 170.0),
    ['police'] = vec4(441.89, -982.05, 30.69, 180.0),
    ['hospital'] = vec4(304.27, -600.33, 43.28, 340.0),
    ['mechanic'] = vec4(-211.08, -1324.28, 30.89, 180.0),
    ['bank'] = vec4(149.46, -1040.54, 29.37, 340.0),
    ['pillbox'] = vec4(296.33, -584.45, 43.26, 160.0),
    ['sandy'] = vec4(1839.71, 3672.93, 34.28, 210.0),
    ['paleto'] = vec4(-244.83, 6324.49, 32.43, 315.0),
    ['airport'] = vec4(-1037.12, -2738.21, 13.76, 330.0),
    ['legion'] = vec4(195.17, -933.77, 30.69, 140.0)
}

Config.Blacklist = {
    [GetHashKey("gt4pol")] = true,
    [GetHashKey("policesultanrs")] = true,
    [GetHashKey("dodgeEMS")] = true,
    [GetHashKey("hp_bmwm5")] = true,
    [GetHashKey("polp1")] = true,
    [GetHashKey("dinghy4")] = true,
}

Config.BlacklistPolice = {
    [GetHashKey("polvstr")] = true,
    [GetHashKey("lapdr1200")] = true,
    [GetHashKey("nkscout")] = true,
    [GetHashKey("polbuffalo4")] = true,
    [GetHashKey("poldom")] = true,
    [GetHashKey("polvigero2")] = true,
    [GetHashKey("polcoq4")] = true,
    [GetHashKey("predator")] = true,
}

Config.BlacklistTaxi = {
    [GetHashKey("taxi")] = true,
}

Config.BlacklistAmbulance = {
    [GetHashKey("ambulance")] = true,
    [GetHashKey("dc_mdoracle")] = true,
    [GetHashKey("ShuttleBus")] = true,
    [GetHashKey("dc_mdbuffalo")] = true,
    [GetHashKey("dc_mdg4m82")] = true,
    [GetHashKey("dinghy4")] = true,
}


-- Keybind settings
Config.UseKeyMapping = false
Config.KeyBind = 'G'
Config.KeyDescription = 'Anchor/Raise Boat'

-- Anchor settings
Config.MaxSpeedToDeploy = 10 -- km/h - Maximum speed to deploy anchor
Config.CheckInterval = 500 -- ms - How often to check for anchored boat when entering

-- Messages
Config.Messages = {
    anchorRaised = 'Neo nâng lên',
    anchorLowered = 'Neo hạ thấp',
    notInWater = 'Bạn không thể neo ở đây',
    tooFast = 'Giảm tốc độ để sử dụng neo',
    boatAnchored = 'Chiếc thuyền này đang được neo',
    notInBoat = 'Bạn phải ở trong thuyền hoặc máy bay đậu trên nước để sử dụng neo',
    notDriver = 'Bạn phải là người lái để sử dụng neo'
}

-- Notification settings
Config.NotificationType = 'ox_lib' -- 'ox_lib' or 'qbcore'
Config.NotificationPosition = 'top' -- ox_lib notification position

return Config

