Config = {}
Config.Anticheat = GetConvarInt('sv:anticheat', 1) == 1

Config.Dependencies = {} 
Config.Locale = 'vi'

do
	local locale = {}
	for k, v in pairs(Locales[Config.Locale] or {}) do locale[k] = v end
	Config.Settings = { locale = locale }
end

-- Dont touch this
Config.EnableModules = {
    ["InviteCode"] = { enabled = true, client = true, priority = 1 },
    ["Main"] = {
        enabled = true,
        client = true, -- enable client side
        priority = 2   -- 1 : init on start | 2 : init on player loaded
    },
    ["GiftCode"] = {
        enabled = true,
        client = true, -- enable client side
        priority = 2   -- 1 : init on start | 2 : init on player loaded
    },
    ["Playtime"] = {
        enabled = true,
        client = false,
        priority = 1,
    },
    ["EventRules"] = {
        enabled = true,
        client = true,
        priority = 2,
    },
}
Config.Debug = false
Config.InviteCode = {
    MaxRedeemPlaytimeSeconds = 60 * 60,
    RequiredSeconds = 50 * 60 * 60,
    CheckpointMs = 30000,
    MaxRewarded = 50,
    InviteeCoin = 50,
    InviterCoin = 100,
    Milestones = { { count = 1, coin = 0 }, { count = 5, coin = 250 },
        { count = 10, coin = 600 }, { count = 20, coin = 1500 },
        { count = 30, coin = 2500 }, { count = 50, coin = 5000 } },
}
Config.Nui = false
Config.Dev = false
---@type "qbx" | "qb" | "esx" | "ProjectStarboy" | "standalone" | "old_esx"
Config.Framework = "qbx" -- "qbx" | "qb" | "esx" | "ProjectStarboy"
Config.ClientLazyLoad = false
Config.OxNotify = true

Config.QBX = {
	metadataAccounts = {
		point = 'point',
		pumpkin = 'pumpkin',
	},
	coinColumn = {
		table = 'players',
		idColumn = 'citizenid',
		column = 'coin',
	},
	dateRegistered = {
		table = 'players',
		idColumn = 'citizenid',
		dateColumn = nil, 
	},
	phone = {
		table = 'players',
		idColumn = 'citizenid',
		column = 'phone',
	},
	phoneItem = {
		name = 'phone',
		formattedKeys = { 'lbFormattedNumber', 'formattedNumber' },
		numberKeys = { 'lbPhoneNumber', 'phoneNumber', 'number' },
	},
	hudResource = 'Tipi_hud',
}

Config.Playtime = {
	table = 'players',
	idColumn = 'citizenid',
	column = 'playtime',
	newbieLabel = 'Newbie',
	autoSaveInterval = 30000,
	autoSaveChunkSize = 50,
}


Config.PlaytimeItems = {
	icon_vip = {
		export = 'icon_vip',
		seconds = math.floor(24.67 * 3600), -- 24.67 giờ
		notify = 'Đã sử dụng Thẻ VIP (+24.67 giờ playtime). Cấp hiện tại: %s',
	},
}


Config.PlaytimeAge = {
	[1] = 86400,
	[2] = 172800,
	[3] = 259200,
	[4] = 432000,
	[5] = 604800,
	[6] = 864000,
	[7] = 1209600,
	[8] = 1555200,
	[9] = 1987200,
	[10] = 2592000,
	[11] = 3024000,
	[12] = 3456000,
	[13] = 3974400,
	[14] = 4492800,
	[15] = 5184000,
	[16] = 5875200,
	[17] = 6652800,
	[18] = 7516800,
	[19] = 8467200,
	[20] = 9504000,
	[21] = 10627200,
	[22] = 11836800,
	[23] = 13132800,
	[24] = 14515200,
	[25] = 15984000,
	[26] = 17539200,
	[27] = 19180800,
	[28] = 20908800,
	[29] = 22723200,
	[30] = 24624000,
	[31] = 26784000,
	[32] = 29116800,
	[33] = 31622400,
	[34] = 34300800,
	[35] = 37152000,
	[36] = 40176000,
	[37] = 43372800,
	[38] = 46742400,
	[39] = 50284800,
	[40] = 54000000,
	[41] = 57888000,
	[42] = 61948800,
	[43] = 66182400,
	[44] = 70588800,
	[45] = 75168000,
	[46] = 79920000,
	[47] = 84844800,
	[48] = 89942400,
	[49] = 95212800,
	[50] = 100656000,
}

function Config.FormatPlaytimeAgeDisplay(level, label)
	level = tonumber(level) or 0
	if level > 0 then
		return ('%d tuổi'):format(level)
	end
	return label or (Config.Playtime and Config.Playtime.newbieLabel) or 'Newbie'
end

function L(key, ...)
    if Config.Settings.locale[key] then
        return string.format(Config.Settings.locale[key], ...)
    else
        return key
    end
end

Config.EventClient = {
    ['upgradeWeapon'] = "lr_weaponupgrade:open",
    -- ['openShopPoint'] = "mp_shoppoint:cl:openShop",
    ['openCoinMenu'] = "hm_coin:showUI",
    ['openNewbieMission'] = "hm_server:allLoaded",
    ['openDailyReward'] = "Tipi_menu:cl:openDailyRewards",
    ['openVehicleShopCoin'] = "gta5nrp_menu:client:openShop",
    ['openXnCase'] = 'es-case:client:openCase',
    ['openDailyMission'] = 'mp_dailymission:cl:openUI',
    -- ['house'] = 'mp_housedep:cl:openHouseActive', 
    ['openMap'] = 'open:map',
    ['openSetting'] = 'open:Settings',
    ['BattlePass'] = 'mp_battlepass:cl:openBattlepass'
}

Config.NewBie = {
    ["price"] = 250,
    ["item"] = {
        { name = "homnewbie",                amount = 1 }, { name = "exp100", amount = 3 },
        { name = "WEAPON_COMBATPDW",         amount = 1 },
        { name = "female_component_5_158_0", amount = 1 },
        { name = "male_component_5_156_0",   amount = 1 }

    }
}

Config.IngameRate = { [10000] = 10, [50000] = 50, [100000] = 100, [500000] = 500 }

Config.PrimePrice = 99
Config.PrimeDay = 30

Config.Events = {
    ['haloween'] = {
        items = {                 
            reward = {
                ['balonam3_0'] = 1 -- tên vật phẩm LƯU Ý : buộc phải có trong ox_inven còn 10 là số lượng
            },
            price = 599,             -- Giá
            bonus = 0                -- số point đc thưởng thêm
        },
        vehicle = {                  -- Xe
            reward = "helltacomav3", -- Mã spawn xe
            price = 1799,            -- Giá
            bonus = 0                -- số point đc thưởng thêm
        }
    }
}

Config.CurrentEvent = 'haloween'
Config.VehicleLabel = {
    ['helltacomav3'] = "HELLCAT TACOMA 6x6 (150kg) Decal phát sáng" 
}

Config.EventCards = {
    adminAces = {
        'group.admin',
        'group.god',
        'admin',
        'god',
    },
    -- Whitelist license (vd: 'license2:abc123...') — bỏ qua kiểm tra ACE nếu khớp.
    adminLicenses = {},
    fallbackBackground = 'https://raw.githubusercontent.com/ghtipi/cdn_bacsigaming/main/assets_UDS/logo.webp',
    defaults = {
        {
            key = 'racing',
            label = 'Đua xe',
            description = '',
            event_time = '',
            image_url = '',
            background_url = 'https://raw.githubusercontent.com/ghtipi/cdn_bacsigaming/main/assets_UDS/bg-duaxe-doc.webp',
            rules_content = 'Thể lệ sự kiện Đua xe sẽ được cập nhật tại đây.',
            action = 'openRacing',
            enabled = true,
            show_join_button = false,
            join_export = '',
            sort_order = 1,
        },
        {
            key = 'thinh',
            label = 'Thính',
            description = '',
            event_time = '',
            image_url = '',
            background_url = 'https://raw.githubusercontent.com/ghtipi/cdn_bacsigaming/main/assets_UDS/bg-cuopthinh-doc.webp',
            rules_content = 'Thể lệ sự kiện Thính sẽ được cập nhật tại đây.',
            action = 'openThinh',
            enabled = true,
            show_join_button = false,
            join_export = '',
            sort_order = 2,
        },
        {
            key = 'audition',
            label = 'Audition',
            description = '',
            event_time = '',
            image_url = '',
            background_url = 'https://raw.githubusercontent.com/ghtipi/cdn_bacsigaming/main/assets_UDS/bg-auditon-doc.webp',
            rules_content = 'Thể lệ sự kiện Audition sẽ được cập nhật tại đây.',
            action = 'openAudition',
            enabled = true,
            show_join_button = false,
            join_export = '',
            sort_order = 3,
        },
        {
            key = 'warrior',
            label = 'Warrior',
            description = '',
            event_time = '',
            image_url = '',
            background_url = 'https://raw.githubusercontent.com/ghtipi/cdn_bacsigaming/main/assets_UDS/bg-warrior-doc.webp',
            rules_content = 'Thể lệ sự kiện Warrior sẽ được cập nhật tại đây.',
            action = 'openWarrior',
            enabled = true,
            show_join_button = false,
            join_export = '',
            sort_order = 4,
        },
        {
            key = 'battlepass',
            label = 'Battle pass',
            description = '',
            event_time = '',
            image_url = '',
            background_url = 'https://raw.githubusercontent.com/ghtipi/cdn_bacsigaming/main/assets_UDS/logo.webp',
            rules_content = 'Thể lệ Battle pass sẽ được cập nhật tại đây.',
            action = 'BattlePass',
            enabled = true,
            show_join_button = false,
            join_export = '',
            sort_order = 5,
        },
    },
}

Config.GiftCode = {
	CooldownTime = 5000, 
	MaxCodeLength = 100, 
	MaxBundleItems = 20, 
    PlaytimeRequire = 60 * 60 * 24,
	EnableHWIDCheck = true,
	UseFakeHWIDForLocalhost = true,
	Webhooks = {
		Created = 'https://discord.com/api/webhooks/1512463343955345609/A5P3VtSQ-dXaTG2L5fisaE4R-zybAJUMqWumJHn-_XONk2bt-JQBCTMLfpm_EjtMA30r',     -- Log admin: ai tạo, phần thưởng, thời gian
		Announce = 'https://discord.com/api/webhooks/1515149649202118707/R4kmve8r-YfRt2lkgjKZVgiF4WZHLB0aH3fQRBfoBmKXGkXBRRQBE7Xn7ZjYDvZFny4R',    -- Thông báo người chơi 
		Redeemed = '',
		AbuseAlert = '',
	},
	WebhookAvatar = 'https://raw.githubusercontent.com/ghtipi/cdn_bacsigaming/main/assets_UDS/logo.webp',
	WebhookUsername = 'Ban quản trị',
	AnnounceMentionEveryone = true,
}
