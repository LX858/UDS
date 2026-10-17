Config = {
    -- ═══════════════════════════════════════════════════════════════
    -- CÀI ĐẶT CHUNG
    -- ═══════════════════════════════════════════════════════════════
    Language = "vi",              
    Framework = "auto",          
    ServerLogo = "https://raw.githubusercontent.com/ghtipi/cdn_bacsigaming/main/assets_UDS/logo.webp",
    FirstTextColor = "#ffffff", 
    LinkTextColor = "#b8b8b8",   
    SecondTextColor = "#00e5ff", 

    UseCruiseControl = true,      
    CruiseKey = "N",              
    UseVehicleControl = true,     
    VehicleControlKey = "Y",      
    VehicleControlCommand = "vehcontrol", 
    UseSeatBelt = true,           
    BeltKey = "B",                
    UseStress = true,     
    
    SettingsKeyBind = false,       
    SettingsMenu = "F4",          
    SettingsCommand = "hud",    

    UseNitro = false,            
    NitroItem = 'nitrous',        
    NitroKey = "X",               
    NitroForce = 50.0,            
    RemoveNitroOnMilliseconds = 0.2, 
    UseWeatherSync = true,     
    WeatherSyncResource = "qb-weathersync", 
    WeatherSyncRealTime = false,
    UseRealWorldTime = true,
    RealWorldTimezoneOffset = 7,    
    FuelScript = "cdn-fuel",     
 
    MaxSpeed = 240,             
    MinimapNativeScale = 1.06,
    MinimapNativeWidthExtra = 0.013,
    MinimapNativeHeightExtra = 0.018,
    MinimapNativeOffsetX = 0.0,
    MinimapNativeOffsetY = 0.0,
    MinimapOnlyInVehicle = false,
    StressNotify = true,          
    StressChance = 0.1,           
    MinimumStress = 50,           

    StressIntensity = {
        ['blur'] = {
            [1] = { min = 50,  max = 60,  intensity = 1500 },
            [2] = { min = 60,  max = 70,  intensity = 2000 },
            [3] = { min = 70,  max = 80,  intensity = 2500 },
            [4] = { min = 80,  max = 90,  intensity = 2700 },
            [5] = { min = 90,  max = 100, intensity = 3000 },
        }
    },

    StressEffectInterval = {
        [1] = { min = 50,  max = 60,  timeout = 60000 },
        [2] = { min = 60,  max = 70,  timeout = 50000 },
        [3] = { min = 70,  max = 80,  timeout = 35000 },
        [4] = { min = 80,  max = 90,  timeout = 25000 },
        [5] = { min = 90,  max = 100, timeout = 17000 },
    },

    --
    WhitelistedWeaponStress = {
        [joaat('weapon_petrolcan')]      = true,
        [joaat('weapon_hazardcan')]      = true,
        [joaat('weapon_fireextinguisher')] = true,
        [joaat('weapon_candycane')]      = true,
        [joaat('weapon_flashlight')]     = true,
        [joaat('weapon_ball')]           = true,
        [joaat('weapon_acidpackage')]    = true,
        [joaat('weapon_snowball')]       = true,
        [joaat('weapon_fertilizercan')]  = true,
        [joaat('gadget_parachute')]      = true,
        [joaat('weapon_flare')]          = true,
    },


    WhitelistedVehicles = {},

    WhitelistedJobs = {
        ['leo']       = true,
        ['police']    = true,
        ['ambulance'] = true,
    },

    -- Cấu hình giảm stress khi lái xe cho ban ngành (Police, Ambulance) khi OnDuty
    DrivingStressJobReduction = {
        enabled = true,
        multiplier = 0.3, -- Stress mỗi lần tăng chỉ bằng 30% so với player thông thường
        jobs = {
            ['police']    = true,
            ['ambulance'] = true,
            ['sheriff']   = true,
            ['bcso']      = true,
            ['sasp']      = true,
            ['doctor']    = true,
            ['ems']       = true,
        },
        jobTypes = {
            ['leo']       = true,
            ['ambulance'] = true,
            ['ems']       = true,
        }
    },

    AddStress = {
        ["on_shoot"] = {
            min = 1,        
            max = 2,        
            enable = true,  
        },
        ["on_fastdrive"] = {
            min = 1,       
            max = 3,        
            enable = true,  
            minSpeed = 110, 
            chance = 50,   
        },
    },

    RemoveStress = {
        ["on_eat"] = {
            min = 5,
            max = 10,
            enable = false,  
        },
        ["on_drink"] = {
            min = 5,
            max = 10,
            enable = false,  
        },
        ["on_swim"] = {
            min = 5,
            max = 10,
            enable = false,  
        },
        ["on_run"] = {
            min = 5,
            max = 10,
            enable = false,  
        },
    },

    defaultSettings = {
        hideAll = false,         
        hudType = 2,              
        speedometer = 2,          
        hideInfo = false,        
        percentText = false,       
        bars = {
            health = {
                visible = true,       
                color = "#FF3838",    
                hideOpacity = 100,    
            },
            armor = {
                visible = true,
                color = "#FFFFFF",
                hideOpacity = 100,
            },
            hunger = {
                visible = true,       
                color = "#FFDA57",
                hideOpacity = 100,
            },
            thrist = {
                visible = true,      
                color = "#46D3FF",
                hideOpacity = 100,
            },
            stamia = {
                visible = true,       
                color = "#53FFC0",
                hideOpacity = 100,
                hideAtFull = true,   
            },
            stress = {
                visible = true,       
                color = "#7B0059",
                hideOpacity = 100,
                hideAtZero = true,    
            },
            sleep = {
                visible = true,       
                color = "#FF0000",
                hideOpacity = 100,
            },
            poop = {
                visible = true,       
                color = "#6B3A2A",
                hideOpacity = 100,
                hideAtZero = true,
            },
            pee = {
                visible = true,       
                color = "#FFD700",
                hideOpacity = 100,
                hideAtZero = true,
            },
        }
    },

    locales = {
        ["vi"] = {
            stress = "Bạn đang rất căng thẳng",
            belt_true = "Bạn đã thắt dây an toàn",
            belt_false = "Bạn đã cởi dây an toàn",
            CRUISE_CANT_SET = "Không thể bật ga tự động.",
            CRUISE_SET = "Đã bật ga tự động",
            CRUISE_DISABLED = "Ga tự động đã tắt.",
            RUN_OUT_OF_NITRO = "Bạn đã hết nitro",
            NO_NITRO = "Không có nitro",
            CANT_INSTALL_IN_CAR = "Không thể lắp nitro lúc này!",
            FILLED_UP_NITRO = "Đã nạp đầy nitro!",
            NO_CAR = "Không có xe gần đó!",
        },
    }
}

function getFramework()
    if Config.Framework == "esx" then
        return exports['es_extended']:getSharedObject(), "esx"
    elseif Config.Framework == "qb" then
        return exports["qb-core"]:GetCoreObject(), "qb"
    elseif Config.Framework == "auto" then
        if GetResourceState('qb-core') == 'started' then
            return exports["qb-core"]:GetCoreObject(), "qb"
        elseif GetResourceState('es_extended') == 'started' then
            return exports['es_extended']:getSharedObject(), "esx"
        end
    end
end
