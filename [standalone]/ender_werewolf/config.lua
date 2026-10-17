Config = {}

Config.Dependencies = {}

Config.Settings = {
	Command = 'werewolf',
	CommandAlias = 'ww',
	-- false = chỉ tương tác qua NPC ox_target
	UseCommand = false,
}

Config.EnableModules = {
	['Main'] = {
		enabled = true,
		client = true,
		priority = 2,
	},
}

Config.Debug = false
Config.Nui = true
Config.Dev = false

---@type 'qb' | 'esx' | 'standalone'
Config.Framework = 'qb'
Config.ClientLazyLoad = false

Config.Main = {
	MinPlayers = 6,
	MaxPlayers = 12,
	MaxLobbies = 4,
	RoomCodeLength = 6,

	Timers = {
		NightRole = 30,
		Discussion = 90,
		Voting = 45,
		HunterShot = 20,
	},


	RoleDistribution = {
		[2] = { werewolf = 1, seer = 1 }, -- test
		[6] = { werewolf = 2, seer = 1, doctor = 1, villager = 2 },
		[7] = { werewolf = 2, seer = 1, doctor = 1, witch = 1, villager = 2 },
		[8] = { werewolf = 2, seer = 1, doctor = 1, witch = 1, villager = 3 },
		[9] = { werewolf = 3, seer = 1, doctor = 1, witch = 1, villager = 3 },
		[10] = { werewolf = 3, seer = 1, doctor = 1, witch = 1, hunter = 1, villager = 3 },
		[11] = { werewolf = 3, seer = 1, doctor = 1, witch = 1, hunter = 1, villager = 4 },
		[12] = { werewolf = 4, seer = 1, doctor = 1, witch = 1, hunter = 1, villager = 4 },
	},

	-- Điểm blip / trả người chơi về sau khi rời phòng
	HubLocation = {
		coords = vector3(-269.4, -955.3, 31.2),
		radius = 3.0,
		label = 'Sảnh Werewolf',
	},

	-- NPC ox_target: tạo phòng / vào phòng (thay lệnh /werewolf)
	Npc = {
		enabled = true,
		model = 'cs_priest',
		coords = vector4(-269.4, -955.3, 31.2, 180.0),
		scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
		targetLabel = 'Chơi Werewolf',
		targetDistance = 2.5,
	},

	-- Tối đa 4 lobby, mỗi lobby một khu vực riêng (proximity voice không lẫn nhau)
	LobbyLocations = {

		[1] = {
			label = 'Lobby 1',
			center = vector4(-270.0, -960.0, 31.2, 180.0),
			spectator = vector4(-285.0, -960.0, 31.2, 90.0),
			spawnRadius = 3.0,
		},

		[2] = {
			label = 'Lobby 2',
			center = vector4(-250.0, -960.0, 31.2, 180.0),
			spectator = vector4(-235.0, -960.0, 31.2, 270.0),
			spawnRadius = 3.0,
		},

		[3] = {
			label = 'Lobby 3',
			center = vector4(-270.0, -940.0, 31.2, 0.0),
			spectator = vector4(-285.0, -940.0, 31.2, 90.0),
			spawnRadius = 3.0,
		},

		[4] = {
			label = 'Lobby 4',
			center = vector4(-250.0, -940.0, 31.2, 0.0),
			spectator = vector4(-235.0, -940.0, 31.2, 270.0),
			spawnRadius = 3.0,
		},
	},

	-- UI: ban ngày / ban đêm chờ lượt = passive (hiện UI + dòng chữ, không NuiFocus → PTT bình thường)
	-- Bỏ phiếu / hành động = Focus + KeepInput (chuột click UI, PTT qua passthrough)
	Nui = {
		KeepInputForVoice = true,
		BlockControlsOnFocus = true,
	},

	Voice = {
		Enabled = true,
		Resource = 'pma-voice',
		RadioBase = 7000,
		DayProximity = 12.0,
		NightProximity = 0.5,
		DeadProximity = 0.0,
		-- Ma Sói ban đêm: proximity = 0 để người đứng gần không nghe lén khi bấm radio
		WerewolfProximity = 0.0,
	},

	Blip = {
		enabled = true,
		sprite = 480,
		color = 1,
		scale = 0.8,
		label = 'Werewolf',
	},
}
