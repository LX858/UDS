local QBCore = exports['qb-core']:GetCoreObject()



local isJudge = false

local isPolice = false

local isTow = false

local isTaxi = false

local isMedic = false

local isDead = false

local myJob = "Unemployed"

local isHandcuffed = false

local hasOxygenTankOn = false

local bennyscivpoly = false

local onDuty = false

local inGarage = false

local inDepots = false



rootMenuConfig =  {



    -- {

    --     id = "ooc",

    --     displayName = "OOC GIFT",

    --     icon = "#police-check-bank",

    --     enableMenu = function()

    --     return (not isDead)

    --     end,

    --     functionName = "Donation:Openshop"

    -- },



    -- {

    --     id = "gacha",

    --     displayName = "MỞ GACHA",

    --     icon = "#expressions-oneeye",

    --     enableMenu = function()

    --     return (not isDead)

    --     end,

    --     functionName = "es-case:client:openCase"

    -- },



    {

    id = "citizen",

    displayName = "Công dân",

    icon = "#prisoner-group",

    enableMenu = function()

        return (not isDead and not IsPedInAnyVehicle(PlayerPedId(), false))

    end,

    functionName = "diemuytin:checkMyReputation",

    --subMenus = { 'taxijob', "general:givenum"}

    },

    -- {

    --     id = "moloto",

    --     displayName = "LOTO",

    --     icon = "#animation-money",

    --     enableMenu = function()

    --         return (not isDead)

    --     end,

    --     functionName = "loto:client:open",

    --  --subMenus = { 'taxijob', "general:givenum"}

    -- },

    -- {

    --     id = "chotot",

    --     displayName = "Chợ Tốt",

    --     icon = "#police-check-bank",

    --     enableMenu = function()

    --         return (not isDead and not IsPedInAnyVehicle(PlayerPedId(), false))

    --     end,

    --     functionName = "chotot:client:Open",

    -- },

    {

        id = "chuphinhh",

        displayName = "Chụp Hình",

        icon = "#news-job-news-camera",

        enableMenu = function()

            return (not isDead)

        end,

        functionName = "JINGJOKCAM:client:OpenCameraMode",

     --subMenus = { 'taxijob', "general:givenum"}

    },

    {

        id = "nhanquaa",

        displayName = "FPS Boots",

        icon = "#general",

        enableMenu = function()

            return (not isDead)

        end,

        functionName = "oxlyn_fps:togglePanel",

    },

    {

        id = "loadquanao",

        displayName = "Reload Q.A",

        icon = "#oxygen-mask",

        enableMenu = function()

            return (not isDead and not IsPedInAnyVehicle(PlayerPedId(), false))

        end,

        functionName = "reload:skin",

     --subMenus = { 'taxijob', "general:givenum"}

    },

    -- {

    --     id = "nhanquaa",

    --     displayName = "Sự kiện",

    --     icon = "#obj-box",

    --     enableMenu = function()

    --         return (not isDead and not IsPedInAnyVehicle(PlayerPedId(), false))

    --     end,

    --     functionName = "xn_eventtichdiem:client:openUI",

    --  --subMenus = { 'taxijob', "general:givenum"}

    -- },



    {

    id = "keysvhc",

    displayName = "Đánh chìa khóa",

    icon = "#general-keys-give",

    enableMenu = function()

        return (not isDead)

    end,

    functionName = "vehiclekey:client:openMenu"

    },

    {

        id = "vehicle",

        displayName = "Phương tiện",

        icon = "#vehicle-options-vehicle",

        functionName = "vehcontrol:openmenu",

        enableMenu = function()

        --   isDead = exports["ir-ambulancejob"]:GetDeath()

            return (not isDead and IsPedInAnyVehicle(PlayerPedId(), false))

        end

    },

    {

      id = "medic-hotong",

      displayName = "Bỏ vác Xác",

      icon = "#judge-actions-escort",

      enableMenu = function()

        --   isDead = exports["ir-ambulancejob"]:GetDeath()

          local playerData = QBCore.Functions.GetPlayerData()

          return (not isDead and playerData.job.name == "ambulance" and playerData.job.onduty)

      end,

      functionName = "ambulance:client:EscortPlayer"

    },



    -- {

    --   id = "prop-menu",

    --   displayName = "Prop Menu",

    --   icon = "#oxygen-mask",

    --   enableMenu = function()

    --     return not isDead

    --   end,

    --   functionName = "xn_chibicore:cl:openpropped"

    -- },

    -- {

    --   id = "medic",

    --   displayName = "kéo xác",

    --   icon = "#medic",

    --   enableMenu = function()

    --     --   isDead = exports["ir-ambulancejob"]:GetDeath()

    --       local playerData = QBCore.Functions.GetPlayerData()

    --       return (not isDead and playerData.job.name == "ambulance" and playerData.job.onduty)

    --   end,

    --   functionName = "hospital:client:initDragDownedPlayers"

    -- },

--   {

--       id = "medic",

--       displayName = "EMS Tools",

--       icon = "#medic",

--       enableMenu = function()

--         --   isDead = exports["ir-ambulancejob"]:GetDeath()

--           local playerData = QBCore.Functions.GetPlayerData()

--           return (not isDead and playerData.job.name == "ambulance" and playerData.job.onduty)

--       end,

--       subMenus = {"ambulance:hotong", 'ems:revivehelp', 'ems:checkhelp'}

--     },



    {

      id = "taxi-job",

      displayName = "Taxi Tools",

      icon = "#vehicle-options-vehicle",

      enableMenu = function()

          local playerData = QBCore.Functions.GetPlayerData()

          return (not isDead and playerData.job.name == "taxi")

      end,

      subMenus = {'taxi:job1', 'taxi:job2', 'taxi:job3'}

    },



    {

      id = "realestate",

      displayName = "Bất Động Sản",

      icon = "#general-apart-givekey",

      enableMenu = function()

          local playerData = QBCore.Functions.GetPlayerData()

          return (not isDead and playerData.job.name == "realestate")

      end,

      subMenus = {'realestate:job1'}

    },





  {

    id = "mdtcardealer",

    displayName = "CDL Tools",

    icon = "#car",

    enableMenu = function()

      --   isDead = exports["ir-ambulancejob"]:GetDeath()

      local playerData = QBCore.Functions.GetPlayerData()

        return (not isDead and (playerData.job.name == "cardealer" or playerData.job.name == "luxurycar") and playerData.job.onduty)

    end,

    subMenus = {"sellVehicle", 'TestVehicle'}

  },



  {

    id = "police-objects",
    displayName = "Vật Thể CS",
    icon = "#police-action",
    enableMenu = function()
        local playerData = QBCore.Functions.GetPlayerData()
        if not playerData or not playerData.job then return false end
        local isLeo = playerData.job.name == "police" or playerData.job.type == "leo"
        return (not isDead and isLeo and playerData.job.onduty and not IsPedInAnyVehicle(PlayerPedId(), false))
    end,

    subMenus = {

        'police:object:cone',

        'police:object:barrier',

        'police:object:roadsign',

        'police:object:tent',

        'police:object:light',

        'police:object:chair',

        'police:object:chairs',

        'police:object:tabe',

        'police:object:monitor',

        'police:object:spikestrip',

    }

  },



}





newSubMenus = {

    ['police:object:cone'] = {

        title = "Cọc tiêu",

        icon = "#police-action",

        functionName = "police:client:spawnPObj",

        parameters = "cone",

        functionParameters = "cone",

        eventType = "client",

    },

    ['police:object:barrier'] = {

        title = "Rào chắn",

        icon = "#police-action",

        functionName = "police:client:spawnPObj",

        parameters = "barrier",

        functionParameters = "barrier",

        eventType = "client",

    },

    ['police:object:roadsign'] = {

        title = "Biển báo",

        icon = "#police-action",

        functionName = "police:client:spawnPObj",

        parameters = "roadsign",

        functionParameters = "roadsign",

        eventType = "client",

    },

    ['police:object:tent'] = {

        title = "Lều dã chiến",

        icon = "#police-action",

        functionName = "police:client:spawnPObj",

        parameters = "tent",

        functionParameters = "tent",

        eventType = "client",

    },

    ['police:object:light'] = {

        title = "Đèn chiếu sáng",

        icon = "#police-action",

        functionName = "police:client:spawnPObj",

        parameters = "light",

        functionParameters = "light",

        eventType = "client",

    },

    ['police:object:chair'] = {

        title = "Ghế đơn",

        icon = "#police-action",

        functionName = "police:client:spawnPObj",

        parameters = "chair",

        functionParameters = "chair",

        eventType = "client",

    },

    ['police:object:chairs'] = {

        title = "Chồng ghế",

        icon = "#police-action",

        functionName = "police:client:spawnPObj",

        parameters = "chairs",

        functionParameters = "chairs",

        eventType = "client",

    },

    ['police:object:tabe'] = {

        title = "Bàn làm việc",

        icon = "#police-action",

        functionName = "police:client:spawnPObj",

        parameters = "tabe",

        functionParameters = "tabe",

        eventType = "client",

    },

    ['police:object:monitor'] = {

        title = "Màn hình",

        icon = "#police-action",

        functionName = "police:client:spawnPObj",

        parameters = "monitor",

        functionParameters = "monitor",

        eventType = "client",

    },

    ['police:object:spikestrip'] = {

        title = "Rải Đinh",

        icon = "#police-action",

        functionName = "police:client:SpawnSpikeStrip",

        eventType = "client",

    },

    ['general:givenum'] = {

        title = "Chia sẻ liên hệ",

        icon = "#obj-phone",

        functionName = "qb-phone:client:GiveContactDetails"

    },

    -- ['general:cornerselling'] = {

    --     title = "Bán Xà Cân",

    --     icon = "#weed-cultivation",

    --     functionName = "xx_selldrugs:client:StartSelling"

    -- },

    ['general:checkexiting'] = {

        title = "KT Thoát game",

        icon = "#general-emotes",

        functionName = "pixel_anticl"

    },

    ['taxijob'] = {

        title = "Điểm uy tín",

        icon = "#general-emote",

        functionName = "diemuytin:checkMyReputation"

    },

    ['general:emotes'] = {

        title = "Animacije",

        icon = "#general-emotes",

        functionName = "emotes:OpenMenu"

    },    

  ['general:keysgive'] = {

      title = "Đưa chìa khóa xe",

      icon = "#general-keys-give",

      functionName = "qb-vehiclekeys:server:give:keys"

  },

  ['general:carry1'] = {

      title = "Cõng",

      icon = "#judge-actions-escort",

      functionName = "xx_carry:play",

  },

  ['general:carry2'] = {

    title = "Vác xác",

    icon = "#judge-actions-escort",

    functionName = "esx_ambulancejob:drag:target",

  },

  ['general:dualenxe2'] = {

    title = "Đưa lên xe",

    icon = "#car",

    functionName = "police:client:PutPlayerInVehicle",

  },

  ['general:rakhoixe2'] = {

    title = "Kéo ra khỏi xe",

    icon = "#car",

    functionName = "ambulance:client:SetPlayerOutVehicle",

  },

  ['general:escort'] = {

    title = "Tiếng nói",

    icon = "#general-escort",

    functionName = "escortPlayer",

    },



  ['general:settingntf'] = {

    title = "Thông báo",

    icon = "#expressions-oneeye",

    functionName = "saka-notification:client:OpenSettings",

    },

    

  ['general:donate'] = {

      title = "OOC GIFT",

      icon = "#blips-trainstations",

      functionName = "Donation:Openshop"

  },

['general:gacha'] = {

      title = "QUAY GACHA",

      icon = "#blips-trainstations",

      functionName = "es-case:client:openCase"

  },

  ['general:givekey'] = {

      title = "Daj Kljuc(Kuca)",

      icon = "#general-apart-givekey",

      functionName = "esx-housing:client:giveHouseKey"

  },

  ['general:takekey'] = {

      title = "Uzmi Kljuc(Kuca)",

      icon = "#general-apart-givekey",

      functionName = "esx-housing:client:removeHouseKey"

  },

  ['general:putinvehicle'] = {

      title = "Stavi u Vozilo",

      icon = "#general-put-in-veh",

      functionName = "police:forceEnter"

  },

  ['general:unseatnearest'] = {

      title = "Izvadi iz Vozila",

      icon = "#general-unseat-nearest",

      functionName = "unseatPlayer"

  }, 

  ['general:shoessteal'] = {

      title = "Skini patike",

      icon = "#general-unseat-nearest",

      functionName = "shoes:steal"

  },       

  ['general:stanjeracuna'] = {

      title = "Gotovina/Banka Stanje",

      icon = "#police-check-bank",

      functionName = "stanjeracuna"

  },  

  ['general:flipvehicle'] = {

      title = "Okreni Vozilo",

      icon = "#general-flip-vehicle",

      functionName = "FlipVehicle"

  },

  ['general:checkvehicle'] = {

      title = "Provjeri Vozilo",

      icon = "#general-check-vehicle",

      functionName = "veh:requestUpdate"

  },

  ['general:zovivoz'] = {

      title = "Pozovi Voz",

      icon = "#blips-trainstations",

      functionName = "AskForTrainConfirmed"

  },



    ['sellVehicle'] = {

        title = "bán xe",

        icon = "#blips-trainstations",

        functionName = "1307_Cardealer:client:SellVehicle"

    },



    ['TestVehicle'] = {

        title = "Lái thử",

        icon = "#blips-trainstations",

        functionName = "1307_Cardealer:client:TestDrive"

    },



  ['gepek:kidnap'] = {

      title = "Kidnapuj Osobu",

      icon = "#police-vehicle",

      functionName = "ped:forceTrunk"

  },

  ['gepek:izadi'] = {

      title = "Izadi Iz Gepeka",

      icon = "#police-vehicle",

      functionName = "ped:releaseTrunkCheckSelf"

  },

  ['gepek:izvadiosobu'] = {

      title = "Izvadi Osobu",

      icon = "#police-vehicle",

      functionName = "ped:releaseTrunkCheck"

  },

  ['gepek:ugepek'] = {

      title = "Udji u Gepek",

      icon = "#police-vehicle",

      functionName = "ped:forceTrunkSelf"

  },

  ['duznost:prijavi'] = {

      title = "On Duty",

      icon = "#police-action",

      functionName = "duznost:prijavi"

  },

  ['duznost:odjavi'] = {

      title = "Off Duty",

      icon = "#police-action",

      functionName = "duznost:odjavi"      -- medic

  },

  ['duznost:prijaviEMS'] = {

      title = "On Duty",

      icon = "#medic",

      functionName = "duznost:prijavi"

  },

  ['duznost:odjaviEMS'] = {

      title = "Off Duty",

      icon = "#medic",

      functionName = "duznost:odjavi"

  },

  ['animations:joy'] = {

      title = "Joy",

      icon = "#animation-joy",

      functionName = "AnimSet:Joy"

  },

  ['animations:sexy'] = {

      title = "Sexy",

      icon = "#animation-sexy",

      functionName = "AnimSet:Sexy"

  },

  ['animations:moon'] = {

      title = "Moon",

      icon = "#animation-moon",

      functionName = "AnimSet:Moon"

  },

  ['animations:tired'] = {

      title = "Tired",

      icon = "#animation-tired",

      functionName = "AnimSet:Tired"

  },

  ['animations:arrogant'] = {

      title = "Arrogant",

      icon = "#animation-arrogant",

      functionName = "AnimSet:Arrogant"

  },

  

  ['animations:casual'] = {

      title = "Casual",

      icon = "#animation-casual",

      functionName = "AnimSet:Casual"

  },

  ['animations:casual2'] = {

      title = "Casual 2",

      icon = "#animation-casual",

      functionName = "AnimSet:Casual2"

  },

  ['animations:casual3'] = {

      title = "Casual 3",

      icon = "#animation-casual",

      functionName = "AnimSet:Casual3"

  },

  ['animations:casual4'] = {

      title = "Casual 4",

      icon = "#animation-casual",

      functionName = "AnimSet:Casual4"

  },

  ['animations:casual5'] = {

      title = "Casual 5",

      icon = "#animation-casual",

      functionName = "AnimSet:Casual5"

  },

  ['animations:casual6'] = {

      title = "Casual 6",

      icon = "#animation-casual",

      functionName = "AnimSet:Casual6"

  },

  ['animations:confident'] = {

      title = "Confident",

      icon = "#animation-confident",

      functionName = "AnimSet:Confident"

  },

  

  ['animations:business2'] = {

      title = "Business 2",

      icon = "#animation-business",

      functionName = "AnimSet:Business2"

  },

  ['animations:business3'] = {

      title = "Business 3",

      icon = "#animation-business",

      functionName = "AnimSet:Business3"

  },

  

  ['animations:femme'] = {

      title = "Femme",

      icon = "#animation-female",

      functionName = "AnimSet:Femme"

  },

  ['animations:flee'] = {

      title = "Flee",

      icon = "#animation-flee",

      functionName = "AnimSet:Flee"

  },

  ['animations:gangster'] = {

      title = "Gangster",

      icon = "#animation-gangster",

      functionName = "AnimSet:Gangster"

  },

  ['animations:gangster2'] = {

      title = "Gangster 2",

      icon = "#animation-gangster",

      functionName = "AnimSet:Gangster2"

  },

  ['animations:gangster3'] = {

      title = "Gangster 3",

      icon = "#animation-gangster",

      functionName = "AnimSet:Gangster3"

  },

  ['animations:gangster4'] = {

      title = "Gangster 4",

      icon = "#animation-gangster",

      functionName = "AnimSet:Gangster4"

  },

  ['animations:gangster5'] = {

      title = "Gangster 5",

      icon = "#animation-gangster",

      functionName = "AnimSet:Gangster5"

  },

  

  ['animations:heels'] = {

      title = "Heels",

      icon = "#animation-female",

      functionName = "AnimSet:Heels"

  },

  ['animations:heels2'] = {

      title = "Heels 2",

      icon = "#animation-female",

      functionName = "AnimSet:Heels2"

  },

  

  ['animations:hipster'] = {

      title = "Hipster",

      icon = "#animation-hipster",

      functionName = "AnimSet:Hipster"

  },

  ['animations:hiking'] = {

      title = "Hiking",

      icon = "#animation-hiking",

      functionName = "AnimSet:Hiking"

  },

  

  ['animations:jog'] = {

      title = "Jog",

      icon = "#animation-jog",

      functionName = "AnimSet:Jog"

  },

  

  ['animations:muscle'] = {

      title = "Muscle",

      icon = "#animation-tough",

      functionName = "AnimSet:Muscle"

  },

  

  ['animations:quick'] = {

      title = "Quick",

      icon = "#animation-quick",

      functionName = "AnimSet:Quick"

  },

  ['animations:wide'] = {

      title = "Wide",

      icon = "#animation-wide",

      functionName = "AnimSet:Wide"

  },

  ['animations:scared'] = {

      title = "Scared",

      icon = "#animation-scared",

      functionName = "AnimSet:Scared"

  },

  ['animations:guard'] = {

      title = "Guard",

      icon = "#animation-guard",

      functionName = "AnimSet:Guard"

  },

  ['animations:brave'] = {

      title = "Brave",

      icon = "#animation-brave",

      functionName = "AnimSet:Brave"

  },

  ['animations:hurry'] = {

      title = "Hurry",

      icon = "#animation-hurry",

      functionName = "AnimSet:Hurry"

  },

  ['animations:business'] = {

      title = "Business",

      icon = "#animation-business",

      functionName = "AnimSet:Business"

  },

  ['animations:tipsy'] = {

      title = "Tipsy",

      icon = "#animation-tipsy",

      functionName = "AnimSet:Tipsy"

  },

  ['animations:injured'] = {

      title = "Injured",

      icon = "#animation-injured",

      functionName = "AnimSet:Injured"

  },

  ['animations:tough'] = {

      title = "Tough",

      icon = "#animation-tough",

      functionName = "AnimSet:ToughGuy"

  },

  ['animations:sassy'] = {

      title = "Sassy",

      icon = "#animation-sassy",

      functionName = "AnimSet:Sassy"

  },

  ['animations:sad'] = {

      title = "Sad",

      icon = "#animation-sad",

      functionName = "AnimSet:Sad"

  },

  ['animations:posh'] = {

      title = "Posh",

      icon = "#animation-posh",

      functionName = "AnimSet:Posh"

  },

  ['animations:alien'] = {

      title = "Alien",

      icon = "#animation-alien",

      functionName = "AnimSet:Alien"

  },

  ['animations:nonchalant'] =

  {

      title = "Nonchalant",

      icon = "#animation-nonchalant",

      functionName = "AnimSet:NonChalant"

  },

  ['animations:hobo'] = {

      title = "Hobo",

      icon = "#animation-hobo",

      functionName = "AnimSet:Hobo"

  },

  ['animations:money'] = {

      title = "Money",

      icon = "#animation-money",

      functionName = "AnimSet:Money"

  },

  ['animations:swagger'] = {

      title = "Swagger",

      icon = "#animation-swagger",

      functionName = "AnimSet:Swagger"

  },

  ['animations:shady'] = {

      title = "Shady",

      icon = "#animation-shady",

      functionName = "AnimSet:Shady"

  },

  ['animations:maneater'] = {

      title = "Man Eater",

      icon = "#animation-maneater",

      functionName = "AnimSet:ManEater"

  },

  ['animations:chichi'] = {

      title = "ChiChi",

      icon = "#animation-chichi",

      functionName = "AnimSet:ChiChi"

  },

  ['animations:default'] = {

      title = "Default",

      icon = "#animation-default",

      functionName = "AnimSet:default"

  },

  ['blips:gasstations'] = {

      title = "Gas Stations",

      icon = "#blips-gasstations",

      functionName = "CarPlayerHud:ToggleGas"

  },    

  ['blips:trainstations'] = {

      title = "Train Stations",

      icon = "#blips-trainstations",

      functionName = "Trains:ToggleTainsBlip"

  },

  ['blips:garages'] = {

      title = "Garages",

      icon = "#blips-garages",

      functionName = "Garages:ToggleGarageBlip"

  },

  ['blips:barbershop'] = {

      title = "Barber Shop",

      icon = "#blips-barbershop",

      functionName = "ld:togglebarber"

  },    

  ['blips:tattooshop'] = {

      title = "Tattoo Shop",

      icon = "#blips-tattooshop",

      functionName = "ld:toggletattoblip"

  },

  ['cuffs:cuff'] = {

      title = "Zavezi",

      icon = "#cuffs-cuff",

      functionName = "civ:cuffFromMenu"

  },

  ['cuffs:uncuff'] = {

      title = "Odvezi",                                    

      icon = "#cuffs-uncuff",

      functionName = "police:uncuffMenu"

  },

  ['cuffs:zavezi'] = {

      title = "Zavezi",                                    

      icon = "#cuffs-cuff",

      functionName = "civ:cuffFromMenu"

  },

  ['cuffs:remmask'] = {

      title = "Skini Masku(Osobi)",

      icon = "#cuffs-check-inventory",

      functionName = "police:remmask"

  },

  ['cuffs:checkinventory'] = {

      title = "Pretresi Osobu",

      icon = "#cuffs-check-inventory",

      functionName = "police:checkInventory"

  },

  ['police:searchplayer'] = {

    title = "Kiểm tra người",

    icon = "#cuffs-check-inventory",

    functionName = "police:client:SearchPlayer"

  },

  ['police:seizecash'] = {

    title = "Phá khóa xe",

    icon = "#cuffs-check-inventory",

    functionName = "police:client:Unlock"

    },

    ['police:hotong'] = {

        title = "Hộ tống",

        icon = "#judge-actions-escort",

        functionName = "police:client:EscortPlayer"

    },



    ['ambulance:hotong'] = {

        title = "Bỏ vác Xác",

        icon = "#judge-actions-escort",

        functionName = "ambulance:client:EscortPlayer"

    },



    ['police:openmdt'] = {

        title = "MDT",

        icon = "#mdt",

        functionName = "qs-dispatch:client:OpenMdt"

    },



    -- ['police:plattuoffline'] = {

    --     title = "Phạt Logout",

    --     icon = "#judge-actions-escort",

    --     functionName = "nl_hotcut:phatlogout2",

    --     isEnabled = function(pEntity, pContext)

    --         local playerData = QBCore.Functions.GetPlayerData()

    --         return playerData.job.name == "police" and playerData.job.grade.level >= 12

    --     end

    -- },



    -- ['police:huyplattuoffline'] = {

    --     title = "Hủy phạt Logout",

    --     icon = "#judge-actions-escort",

    --     functionName = "nl_hotcut:huyphatoffline2",

    --     isEnabled = function(pEntity, pContext)

    --         local playerData = QBCore.Functions.GetPlayerData()

    --         return playerData.job.name == "police" and playerData.job.grade.level >= 14

    --     end

    -- },



    -- ['police:phatlaodong'] = {

    --     title = "Phạt Tù",

    --     icon = "#judge-actions-escort",

    --     functionName = "nl_hotcut:phatlaodong"

    -- },



    ['police:ganmoc'] = {

        title = "Gắn móc",

        icon = "#vehicle-anchor",

        functionName = "Client:installGrappler"

    },



    ['police:mocthao'] = {

        title = "Móc tháo",

        icon = "#vehicle-anchor",

        functionName = "Client:removeGrappler"

    },



    -- ['police:huyphatlaodong'] = {

    --     title = "Hủy Phạt Tù",

    --     icon = "#judge-actions-escort",

    --     functionName = "nl_hotcut:huyphatlaodong",

    --     isEnabled = function(pEntity, pContext)

    --         local playerData = QBCore.Functions.GetPlayerData()

    --         return playerData.job.name == "police" and playerData.job.grade.level >= 14

    --     end

    -- },



    ['police:capgiaytoxe'] = {

        title = "Cấp giấy tờ xe",

        icon = "#police-vehicle-plate",

        functionName = "LuaNest_BamBienSo:client:capGiayToXe",

        isEnabled = function(pEntity, pContext)

            local playerData = QBCore.Functions.GetPlayerData()

            return playerData.job.name == "police" and playerData.job.grade.level >= 4

        end

    },



    ['police:dualenxe'] = {

        title = "Đưa vào xe",

        icon = "#vehicle-options-vehicle",

        functionName = "police:client:PutPlayerInVehicle"

    },

    ['police:duarakhoixe'] = {

        title = "Đưa ra khỏi xe",

        icon = "#vehicle-options-vehicle",

        functionName = "police:client:SetPlayerOutVehicle"

    },

    ['police:nangcao'] = {

        title = "Nâng cao",

        icon = "#vehicle-options-vehicle",

        functionName = "police:client:ImpoundVehicle"

    },

    ['ems:reviveplayer'] = {

        title = "Cứu người",

        icon = "#medic-revive",

        functionName = "hospital:client:RevivePlayer"

    },

    ['ems:revivehelp'] = {

        title = "Hồi phục",

        icon = "#medic-heal",

        functionName = "hospital:client:TreatWounds"

    },

    ['ems:checkhelp'] = {

        title = "kiểm tra tình trạng",

        icon = "#medic-revive",

        functionName = "hospital:client:CheckStatus"

    },

  ['cuffs:unseat'] = {

      title = "Izvadi iz Vozila",

      icon = "#cuffs-unseat-player",

      functionName = "unseatPlayerCiv"

  },

  ['medic:revive'] = {

      title = "Ozivi",

      icon = "#medic-revive",

      functionName = "tp:emsrevive"

  },

  ['medic:heal'] = {

      title = "Nahilaj",

      icon = "#medic-heal",

      functionName = "revive"

  },

  ['medic:pingbs'] = {

    title = "MDT EMS",

    icon = "#medic-heal",

    functionName = "esx_pingJobs:openList"

},

  ['medic:stomachpump'] = {

      title = "Isprazni Zeludac",

      icon = "#medic-stomachpump",

      functionName = "ems:stomachpump"

  },

  ['police:cuff'] = {

      title = "Zavezi",

      icon = "#cuffs-cuff",

      functionName = "police:cuffFromMenu"

  },

  ['police:uncuff'] = {

      title = "Tháo Còng",

      icon = "#cuffs-cuff",

      functionName = "police:client:UncuffFromMenu"

  },

  ['police:checkbank'] = {

      title = "Provjeri Novac",

      icon = "#police-check-bank",

      functionName = "check-bank"

  },

  ['police:checklicenses'] = {

      title = "Provjeri License",

      icon = "#police-check-licenses",

      functionName = "police:checkLicenses"

  },

  ['police:removeweapons'] = {

      title = "Oduzmi Licensu(oruzije)",

      icon = "#police-action-remove-weapons",

      functionName = "police:removeWeapon"

  },

  ['police:znacka'] = {

      title = "Pokazi Znacku",

      icon = "#police-action",

      functionName = "badge:openPD"

  },

  ['police:tablet'] = {

      title = "Otvori Tablet",

      icon = "#police-action",

      functionName = "otvori:mdt"

  },

  ['ems:panic'] = {

      title = "Upomoc!",

      icon = "#medic-stomachpump",

      functionName = "ems:panic"

  },

  ['police:gsr'] = {

      title = "GSR Testiranje",

      icon = "#police-action-gsr",

      functionName = "police:gsr"

  },

  ['police:dna'] = {

      title = "DNA Testiranje",

      icon = "#police-action-gsr",

      functionName = "police:dna"

  },

  ['police:dnaswab'] = {

      title = "DNA Swab",

      icon = "#police-action-dna-swab",

      functionName = "evidence:dnaSwab"

  },

  ['police:toggleradar'] = {

      title = "Radar bật/tắt",

      icon = "#police-vehicle-radar",

      functionName = ""

  },

  ['police:runplate'] = {

      title = "Bằng lái",

      icon = "#police-vehicle-plate",

      functionName = "clientcheckLicensePlate"

  },

  ['judge:spawnvehicle'] = {

      title = "Vozilo (posao)",

      icon = "#police-vehicle",

      functionName = "judge:spawnvehicle"



  },

  -- ['mechanic:hijack'] = {

  --     title = "Hijack",

  --     icon = "#police-vehicle",

  --     functionName = "tp:hijack"

  -- },

  ['mechanic:repair'] = {

      title = "Popravi",

      icon = "#police-vehicle",

      functionName = "tp:mechrepair"

  },

  ['mechanic:clean'] = {

      title = "Ocisti",

      icon = "#police-vehicle",

      functionName = "tp:mechclean" 

  },

  ['zaplena:lspd'] = {

      title = "Zapleni",

      icon = "#police-vehicle",

      functionName = "ir-vozila:impoundmeni"

  },

  ['izdaj:racun'] = {

      title = "Daj Racun",

      icon = "#police-vehicle",

      functionName = "dajracun"

  },

  ['mechanic:impound'] = {

      title = "Impoundaj",

      icon = "#police-vehicle",

      functionName = "impoundVehicle"

  },

  ['judge:grantDriver'] = {

      title = "Grant Drivers",

      icon = "#judge-licenses-grant-drivers",

      functionName = "police:grantDriver"

  }, 

  ['judge:grantBusiness'] = {

      title = "Grant Business",

      icon = "#judge-licenses-grant-business",

      functionName = "police:grantBusiness"

  },  

  ['judge:grantWeapon'] = {

      title = "Grant Weapon",

      icon = "#judge-licenses-grant-weapon",

      functionName = "police:grantWeapon"

  },

  ['judge:grantHouse'] = {

      title = "Grant House",

      icon = "#judge-licenses-grant-house",

      functionName = "police:grantHouse"

  },

  ['judge:grantBar'] = {

      title = "Grant BAR",

      icon = "#judge-licenses-grant-bar",

      functionName = "police:grantBar"

  },

  ['judge:grantDA'] = {

      title = "Grant DA",

      icon = "#judge-licenses-grant-da",

      functionName = "police:grantDA"

  },

  ['judge:removeDriver'] = {

      title = "Remove Drivers",

      icon = "#judge-licenses-remove-drivers",

      functionName = "police:removeDriver"

  },

  ['judge:removeBusiness'] = {

      title = "Remove Business",

      icon = "#judge-licenses-remove-business",

      functionName = "police:removeBusiness"

  },

  ['judge:removeWeapon'] = {

      title = "Remove Weapon",

      icon = "#judge-licenses-remove-weapon",

      functionName = "police:removeWeapon"

  },

  ['judge:removeHouse'] = {

      title = "Remove House",

      icon = "#judge-licenses-remove-house",

      functionName = "police:removeHouse"

  },

  ['judge:removeBar'] = {

      title = "Remove BAR",

      icon = "#judge-licenses-remove-bar",

      functionName = "police:removeBar"

  },

  ['judge:removeDA'] = {

      title = "Remove DA",

      icon = "#judge-licenses-remove-da",

      functionName = "police:removeDA"

  },

  ['judge:denyWeapon'] = {

      title = "Deny Weapon",

      icon = "#judge-licenses-deny-weapon",

      functionName = "police:denyWeapon"

  },

  ['judge:denyDriver'] = {

      title = "Deny Drivers",

      icon = "#judge-licenses-deny-drivers",

      functionName = "police:denyDriver"

  },

  ['judge:denyBusiness'] = {

      title = "Deny Business",

      icon = "#judge-licenses-deny-business",

      functionName = "police:denyBusiness"

  },

  ['judge:denyHouse'] = {

      title = "Deny House",

      icon = "#judge-licenses-deny-house",

      functionName = "police:denyHouse"

  },

  ['news:setCamera'] = {

      title = "Camera",

      icon = "#news-job-news-camera",

      functionName = "Cam:ToggleCam"

  },

  ['news:setMicrophone'] = {

      title = "Microphone",

      icon = "#news-job-news-microphone",

      functionName = "Mic:ToggleMic"

  },

  ['news:setBoom'] = {

      title = "Microphone Boom",

      icon = "#news-job-news-boom",

      functionName = "Mic:ToggleBMic"

  },

  ['weed:currentStatusServer'] = {

      title = "Request Status",

      icon = "#weed-cultivation-request-status",

      functionName = "weed:currentStatusServer"

  },   

  ['weed:weedCrate'] = {

      title = "Remove A Crate",

      icon = "#weed-cultivation-remove-a-crate",

      functionName = "weed:weedCrate"

  },

  ['cocaine:currentStatusServer'] = {

      title = "Request Status",

      icon = "#meth-manufacturing-request-status",

      functionName = "cocaine:currentStatusServer"

  },

  ['cocaine:methCrate'] = {

      title = "Remove A Crate",

      icon = "#meth-manufacturing-remove-a-crate",

      functionName = "cocaine:methCrate"

  },

  ["expressions:angry"] = {

      title="Angry",

      icon="#expressions-angry",

      functionName = "expressions",

      functionParameters =  { "mood_angry_1" }

  },



    ['taxi:job1'] = {

        title = "Bắt đầu",

        icon = "#vehicle-options-vehicle",

        functionName = "qb-taxi:client:toggleMeter"

    },



    ['taxi:job2'] = {

        title = "Bật/tắt đồng hồ",

        icon = "#vehicle-options-vehicle",

        functionName = "qb-taxi:client:enableMeter"

    },



    ['taxi:job3'] = {

        title = "Vào ca / Tan ca",

        icon = "#police-action",

        functionName = "qb-taxi:client:toggleDuty"

    },



    ['realestate:job1'] = {

        title = "Vào ca / Tan ca",

        icon = "#police-action",

        functionName = "qb-realestate:client:ToggleDuty"

    },

    

  ["expressions:drunk"] = {

      title="Drunk",

      icon="#expressions-drunk",

      functionName = "expressions",

      functionParameters =  { "mood_drunk_1" }

  },

  ["expressions:dumb"] = {

      title="Dumb",

      icon="#expressions-dumb",

      functionName = "expressions",

      functionParameters =  { "pose_injured_1" }

  },

  ["expressions:electrocuted"] = {

      title="Electrocuted",

      icon="#expressions-electrocuted",

      functionName = "expressions",

      functionParameters =  { "electrocuted_1" }

  },

  ['police:proveriNovac'] = {

      title = "Proveri Novac",

      icon = "#police-proveri",

      functionName = "police:proveriNovac"

  },

  ['police:konfiskujNovac'] = {

      title = "Konfiskuj Novac",

      icon = "#police-konfiskuj",

      functionName = "police:konfiskujNovac"

  },

  ['police:ZaplenaItema'] = {

      title = "Oduzmi Stvari",

      icon = "#police-itemZaplena",

      functionName = "police:ZaplenaItema"

  },

  ["expressions:grumpy"] = {

      title="Grumpy",

      icon="#expressions-grumpy",

      functionName = "expressions", 

      functionParameters =  { "mood_drivefast_1" }

  },

  ["expressions:happy"] = {

      title="Happy",

      icon="#expressions-happy",

      functionName = "expressions",

      functionParameters =  { "mood_happy_1" }

  },

  ["expressions:injured"] = {

      title="Injured",

      icon="#expressions-injured",

      functionName = "expressions",

      functionParameters =  { "mood_injured_1" }

  },

  ["expressions:joyful"] = {

      title="Joyful",

      icon="#expressions-joyful",

      functionName = "expressions",

      functionParameters =  { "mood_dancing_low_1" }

  },

  ["expressions:mouthbreather"] = {

      title="Mouthbreather",

      icon="#expressions-mouthbreather",

      functionName = "expressions",

      functionParameters = { "smoking_hold_1" }

  },

  ["expressions:normal"]  = {

      title="Normal",

      icon="#expressions-normal",

      functionName = "expressions:clear"

  },

  ["expressions:oneeye"]  = {

      title="One Eye",

      icon="#expressions-oneeye",

      functionName = "expressions",

      functionParameters = { "pose_aiming_1" }

  },

  ["expressions:shocked"]  = {

      title="Shocked",

      icon="#expressions-shocked",

      functionName = "expressions",

      functionParameters = { "shocked_1" }

  },

  ["expressions:sleeping"]  = {

      title="Sleeping",

      icon="#expressions-sleeping",

      functionName = "expressions",

      functionParameters = { "dead_1" }

  },

  ["expressions:smug"]  = {

      title="Smug",

      icon="#expressions-smug",

      functionName = "expressions",

      functionParameters = { "mood_smug_1" }

  },

  ["expressions:speculative"]  = {

      title="Speculative",

      icon="#expressions-speculative",

      functionName = "expressions",

      functionParameters = { "mood_aiming_1" }

  },

  ["expressions:stressed"]  = {

      title="Stressed",

      icon="#expressions-stressed",

      functionName = "expressions",

      functionParameters = { "mood_stressed_1" }

  },

  ["expressions:sulking"]  = {

      title="Sulking",

      icon="#expressions-sulking",

      functionName = "expressions",

      functionParameters = { "mood_sulk_1" },

  },

  ["expressions:weird"]  = {

      title="Weird",

      icon="#expressions-weird",

      functionName = "expressions",

      functionParameters = { "effort_2" }

  },

  ["expressions:weird2"]  = {

      title="Weird 2",

      icon="#expressions-weird2",

      functionName = "expressions",

      functionParameters = { "effort_3" }

  },

  

  -- Thú cưng submenu

  ['thucung:danhsach'] = {

      title = "Danh sách thú cưng",

      icon = "#general-escort",

      functionName = "dt-thucung:openpetmenu"

  },

  

  ['thucung:hanhdong'] = {

      title = "Danh sách hành động",

      icon = "#general-escort",

      functionName = "dt-thucung:openpetemote"

  },



  -- Taxi submenu

  ['taxi:go'] = {

      title = "Gọi Taxi",

      icon = "#general-escort",

      functionName = "vie_radialmenu:runCommand",

      functionParameters = { "minitaxi" }

  },



  ['taxi:cancel'] = {

      title = "Huỷ Taxi",

      icon = "#general-escort",

      functionName = "vie_radialmenu:runCommand",

      functionParameters = { "cancelminitaxi" }

  },

}

    



RegisterNetEvent("isJudge") -- these are all up to you and your job system, if person become Judge, script will see him as Judge too.

AddEventHandler("isJudge", function()

    isJudge = true

end)



RegisterNetEvent("isJudgeOff") -- opposite of the above

AddEventHandler("isJudgeOff", function()

    isJudge = false

end)



RegisterNetEvent("isTow") -- these are all up to you and your job system, if person become Judge, script will see him as Judge too.

AddEventHandler("isTow", function()

    isTow = true

end)



RegisterNetEvent("isTowOff") -- these are all up to you and your job system, if person become Judge, script will see him as Judge too.

AddEventHandler("isTowOff", function()

    isTow = false

end)



RegisterNetEvent("isTaxi") -- these are all up to you and your job system, if person become Judge, script will see him as Judge too.

AddEventHandler("isTaxi", function()

    isTaxi = true

end)



RegisterNetEvent("isTaxiOff") -- opposite of the above

AddEventHandler("isTaxiOff", function()

    isTaxi = false

end)



RegisterNetEvent("QBCore:Client:OnJobUpdate") -- dont edit this unless you don't use qb-core

AddEventHandler("QBCore:Client:OnJobUpdate", function(jobInfo)

    myJob = jobInfo.name

    if isMedic and myJob ~= "ambulance" then isMedic = false end

    if isPolice and myJob ~= "police" then isPolice = false end

    if isTow and myJob ~= "tow" then isTow = false end

    if isTaxi and myJob ~= "taxi" then isTaxi = false end

    if myJob == "police" then isPolice = true end

    if myJob == "tow" then isTow = true end

    if myJob == "taxi" then isTaxi = true end

    if myJob == "ambulance" then isMedic = true end

end)



RegisterNetEvent('QBCore:Client:SetDuty') -- dont edit this unless you don't use qb-core

AddEventHandler('QBCore:Client:SetDuty', function(duty)

    myJob = QBCore.Functions.GetPlayerData().job.name

    if isMedic and myJob ~= "ambulance" then isMedic = false end

    if isPolice and myJob ~= "police" then isPolice = false end

    if myJob == "police" then isPolice = true onDuty = duty end

    if myJob == "ambulance" then isMedic = true onDuty = duty end

end)



RegisterNetEvent('deathcheck') -- YOU SHOULD ADD THIS IN YOUR ambulancejob system, basically let the function trigger here when the ped playing anim and add this to

-- your revived function so everytime if person dies, this will be triggered to isDead = true, if he get revived this will be triggered to isDead = false

AddEventHandler('deathcheck', function()

    if not isDead then

        isDead = true

    else

        isDead = false

    end

end)





RegisterNetEvent("police:currentHandCuffedState") -- add this your police:client:GetCuffed @qb-policejob\client\interactions.lua

AddEventHandler("police:currentHandCuffedState", function(pIsHandcuffed)

    isHandcuffed = pIsHandcuffed

end)



RegisterNetEvent("menu:hasOxygenTank") -- add this to your oxygentank wear place, idk where is this for qb-inventory so find out please

AddEventHandler("menu:hasOxygenTank", function(pHasOxygenTank)

    hasOxygenTankOn = pHasOxygenTank

end)





RegisterNetEvent('police:client:PutInVehicle')

AddEventHandler('police:client:PutInVehicle', function()

    if isEscorted then

    end

end)

