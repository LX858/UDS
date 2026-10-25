config = {}
Config = config

-- Giới hạn ngày thuê tối đa (DD/MM/YYYY)
Config.dayrent = "10/11/2026"

-- Giới hạn chi phí thuê mỗi ngày (Ví dụ: < 10000)
Config.maxDailyRent = 10000

-- Chi phí dọn dẹp phòng tự động mỗi bãi bẩn ($20/bãi)
Config.cleanPricePerPile = 20

Config.GetMaxRentDays = function(currentTime)
	if not os then
		return 365
	end
	if not Config.dayrent or Config.dayrent == "" then
		return 365
	end
	local day, month, year = string.match(Config.dayrent, "(%d+)/(%d+)/(%d+)")
	if day and month and year then
		local limitTime = os.time({
			day = tonumber(day),
			month = tonumber(month),
			year = tonumber(year),
			hour = 23,
			min = 59,
			sec = 59
		})
		local current = currentTime or os.time()
		local diff = limitTime - current
		if diff <= 0 then
			return 0
		end
		return math.floor(diff / 86400)
	end
	return 365
end

config.debug = false -- Set to true to enable debug logging for key validation (turn off in production)
config.discordWebhook = {
	rental    = '', -- Log cho thuê phòng (fallback toàn cục)
	extension = '', -- Log gia hạn phòng (fallback toàn cục)
	cleanup   = '', -- Log dọn dẹp phòng (fallback toàn cục)
}
config.wardrobe = 'illenium-appearance' -- choose your skin menu
config.target = true -- false = markers zones type. true = ox_target, qb-target
config.business = true -- cho phép người chơi mua nhà trọ
config.autokickIfExpire = true --Auto đá người cư ngụ nếu tiền thuê là đến hạn.Nếu chủ sở hữu sai của Motel phải đá người cư ngụ
config.confiscateOnExpire = true -- Tịch thu đồ vào SQL (bảng motel_hethan) khi hết hạn thuê, player dùng item chuotdonhatro để lấy lại trong 7 ngày
config.breakinJobs = { -- jobs can break in to door using gunfire in doors
	['police'] = true,
	['swat'] = true,
}
config.wardrobes = { -- skin menus
	['renzu_clothes'] = function()
		exports.renzu_clothes:OpenClotheInventory()
	end,
	['fivem-appearance'] = function()
		return exports['fivem-appearance']:startPlayerCustomization() -- you could replace this with outfits events
	end,
	['illenium-appearance'] = function()
		return TriggerEvent('illenium-appearance:client:openOutfitMenu')
	end,
	['qb-clothing'] = function()
		return TriggerEvent('qb-clothing:client:openOutfitMenu')
	end,
	['esx_skin'] = function()
		TriggerEvent('esx_skin:openSaveableMenu')
	end,
}

-- Shells Offsets and model name
config.shells = {
	['standard'] = {
		shell = `standardmotel_shell`, -- kambi shell
		offsets = {
			exit = vec3(-0.43,-2.51,1.16),
			stash = vec3(1.368164, -3.134506, 1.16),
			wardrobe = vec3(-0.34,-0.51,1.16), 
		}
	},
	['modern'] = {
		shell = `modernhotel_shell`, -- kambi shell
		offsets = {
			exit = vec3(5.410095, 4.299301, 0.9),
			stash = vec3(-4.068207, 4.046188, 0.9),
			wardrobe = vec3(-4.80157, -0.06439, 1.78537),
		}
	},
}

config.messageApi = function(data) -- {title,message,motel}
	local motel = (GetMotelSnapshot and GetMotelSnapshot() or GlobalState.Motels)[data.motel]
	local identifier = motel.owned -- owner identifier
	-- add your custom message here. ex. SMS phone 

	-- basic notification (remove this if using your own message system)
	local success = lib.callback.await('renzu_motels:MessageOwner',false,{identifier = identifier, message = data.message, title = data.title, motel = data.motel})
	if success then
		Notify('message has been sent', 'success')
	else
		Notify('message fail  \n  owner is not available yet', 'error')
	end
end


-- Cấu hình phòng ngủ nhanh mặc định (Quick Sleep Room)
-- Khách sạn nào cũng có thể vào trực tiếp để ngủ (coord wardrobe) với giá 1,500$
-- 90% số tiền (1,350$) sẽ được chuyển vào quỹ của khách sạn đó
config.quickSleep = {
	enabled = true,
	price = 1500,        -- Phí mỗi lần vào phòng ($1,500)
	hotelCut = 0.90,     -- 90% tiền gửi về quỹ khách sạn
	payment = 'money',   -- 'money' (tiền mặt) hoặc 'bank' (ngân hàng)
	shell = 'standard',  -- Shell phòng ngủ
	label = 'Phòng ngủ nhanh',
	maxSleepiness = 50,  -- Chỉ nhận về tối đa 50% sleepiness khi ngủ tạm
}

-- Default stash inventory config
config.defaultStash = {
	slots = 25,
	weight = 60000
}

-- Cấu hình kiểm kê tủ lạnh mặc định
config.defaultFridge = {
	slots = 5,
	weight = 5000
}

-- Available NPC models for motel rental points
config.npcModels = {
	business_male = `a_m_m_business_01`,
	business_female = `a_f_m_business_02`,
	salesman = `s_m_m_generic_01`,
	receptionist = `a_f_y_business_04`,
	security = `s_m_y_doorman_01`
}

config.clothesHotel1 = {
	['quet_don'] = {
		male = {
			-- ["arms"] = { clotheId = 8, variation = 0 },
			-- ["pants"] = { clotheId = 318, variation = 0 },
			-- ["shoes"] = { clotheId = 285, variation = 0 },
			-- ["t-shirt"] = { clotheId = 169, variation = 6 },
			-- ["torso"] = { clotheId = 934, variation = 0 },
		},
		female = {
		},
	},
	['nhan_vien'] = {
		male = {
			-- ["arms"] = { clotheId = 8, variation = 0 },
			-- ["pants"] = { clotheId = 318, variation = 0 },
			-- ["shoes"] = { clotheId = 285, variation = 0 },
			-- ["t-shirt"] = { clotheId = 169, variation = 6 },
			-- ["torso"] = { clotheId = 934, variation = 0 },
		},
		female = {
			-- ["arms"] = { clotheId = 274, variation = 0 },
			-- ["pants"] = { clotheId = 273, variation = 0 },
			-- ["shoes"] = { clotheId = 244, variation = 0 },
			-- ["t-shirt"] = { clotheId = 2, variation = 0 },
			-- ["torso"] = { clotheId = 957, variation = 0 },
		},
	},
	['quan_ly'] = {
		male = {
			-- ["arms"] = { clotheId = 8, variation = 0 },
			-- ["pants"] = { clotheId = 319, variation = 0 },
			-- ["shoes"] = { clotheId = 286, variation = 0 },
			-- ["t-shirt"] = { clotheId = 218, variation = 0 },
			-- ["torso"] = { clotheId = 935, variation = 0 },
		},
		female = {
			-- ["arms"] = { clotheId = 274, variation = 0 },
			-- ["pants"] = { clotheId = 273, variation = 0 },
			-- ["shoes"] = { clotheId = 244, variation = 0 },
			-- ["t-shirt"] = { clotheId = 2, variation = 0 },
			-- ["torso"] = { clotheId = 957, variation = 0 },
		},
	},
}

config.clothesHotel2 = {
	['quet_don'] = {
		male = {
			["mask"] = { clotheId = 0, variation = 0 },
			["arms"] = { clotheId = 0, variation = 0 },
			["pants"] = { clotheId = 9, variation = 2 },
			["bag"] = { clotheId = 0, variation = 0 },
			["shoes"] = { clotheId = 25, variation = 0 },
			["t-shirt"] = { clotheId = 59, variation = 2 },
			["torso"] = { clotheId = 226, variation = 2 },
			["decals"] = { clotheId = 0, variation = 0 },
			["kevlar"] = { clotheId = 0, variation = 0 },
		},
		maleHelmet = { clotheId = 145, variation = 2 },
		female = {
			["mask"] = { clotheId = 0, variation = 0 },
			["arms"] = { clotheId = 0, variation = 0 },
			["pants"] = { clotheId = 109, variation = 2 },
			["bag"] = { clotheId = 0, variation = 0 },
			["shoes"] = { clotheId = 25, variation = 0 },
			["t-shirt"] = { clotheId = 36, variation = 2 },
			["torso"] = { clotheId = 236, variation = 2 },
			["decals"] = { clotheId = 0, variation = 0 },
			["kevlar"] = { clotheId = 0, variation = 0 },
		},
		femaleHelmet = { clotheId = 144, variation = 2 },
	},
	['nhan_vien'] = {
		male = {
			["arms"] = { clotheId = 1, variation = 0 },
			["pants"] = { clotheId = 10, variation = 1 },
			["shoes"] = { clotheId = 10, variation = 0 },
			["t-shirt"] = { clotheId = 15, variation = 1 },
			["torso"] = { clotheId = 13, variation = 1 },
		},
		female = {
			["arms"] = { clotheId = 3, variation = 0 },
			["pants"] = { clotheId = 6, variation = 1 },
			["shoes"] = { clotheId = 13, variation = 0 },
			["t-shirt"] = { clotheId = 14, variation = 1 },
			["torso"] = { clotheId = 6, variation = 1 },
		},
	},
	['quan_ly'] = {
		male = {
			["arms"] = { clotheId = 4, variation = 0 },
			["pants"] = { clotheId = 28, variation = 1 },
			["shoes"] = { clotheId = 21, variation = 0 },
			["t-shirt"] = { clotheId = 26, variation = 1 },
			["torso"] = { clotheId = 29, variation = 1 },
		},
		female = {
			["arms"] = { clotheId = 3, variation = 0 },
			["pants"] = { clotheId = 37, variation = 1 },
			["shoes"] = { clotheId = 29, variation = 0 },
			["t-shirt"] = { clotheId = 35, variation = 1 },
			["torso"] = { clotheId = 27, variation = 1 },
		},
	},
}

config.clothesHotel3 = {
	['quet_don'] = {
		male = {
			["mask"] = { clotheId = 0, variation = 0 },
			["arms"] = { clotheId = 0, variation = 0 },
			["pants"] = { clotheId = 9, variation = 3 },
			["bag"] = { clotheId = 0, variation = 0 },
			["shoes"] = { clotheId = 25, variation = 0 },
			["t-shirt"] = { clotheId = 59, variation = 3 },
			["torso"] = { clotheId = 226, variation = 3 },
			["decals"] = { clotheId = 0, variation = 0 },
			["kevlar"] = { clotheId = 0, variation = 0 },
		},
		maleHelmet = { clotheId = 145, variation = 3 },
		female = {
			["mask"] = { clotheId = 0, variation = 0 },
			["arms"] = { clotheId = 0, variation = 0 },
			["pants"] = { clotheId = 109, variation = 3 },
			["bag"] = { clotheId = 0, variation = 0 },
			["shoes"] = { clotheId = 25, variation = 0 },
			["t-shirt"] = { clotheId = 36, variation = 3 },
			["torso"] = { clotheId = 236, variation = 3 },
			["decals"] = { clotheId = 0, variation = 0 },
			["kevlar"] = { clotheId = 0, variation = 0 },
		},
		femaleHelmet = { clotheId = 144, variation = 3 },
	},
	['nhan_vien'] = {
		male = {
			["arms"] = { clotheId = 1, variation = 0 },
			["pants"] = { clotheId = 10, variation = 2 },
			["shoes"] = { clotheId = 10, variation = 0 },
			["t-shirt"] = { clotheId = 15, variation = 2 },
			["torso"] = { clotheId = 13, variation = 2 },
		},
		female = {
			["arms"] = { clotheId = 3, variation = 0 },
			["pants"] = { clotheId = 6, variation = 2 },
			["shoes"] = { clotheId = 13, variation = 0 },
			["t-shirt"] = { clotheId = 14, variation = 2 },
			["torso"] = { clotheId = 6, variation = 2 },
		},
	},
	['quan_ly'] = {
		male = {
			["arms"] = { clotheId = 4, variation = 0 },
			["pants"] = { clotheId = 28, variation = 2 },
			["shoes"] = { clotheId = 21, variation = 0 },
			["t-shirt"] = { clotheId = 26, variation = 2 },
			["torso"] = { clotheId = 29, variation = 2 },
		},
		female = {
			["arms"] = { clotheId = 3, variation = 0 },
			["pants"] = { clotheId = 37, variation = 2 },
			["shoes"] = { clotheId = 29, variation = 0 },
			["t-shirt"] = { clotheId = 35, variation = 2 },
			["torso"] = { clotheId = 27, variation = 2 },
		},
	},
}

config.clothesHotel4 = {
	['quet_don'] = {
		male = {
			["arms"] = { clotheId = 4, variation = 0 },
			["pants"] = { clotheId = 260, variation = 0 },
			["t-shirt"] = { clotheId = 15, variation = 0 },
			["torso"] = { clotheId = 349, variation = 0},
		},
		maleHelmet = { clotheId = 145, variation = 1 },
		female = {
		},
		femaleHelmet = { clotheId = 144, variation = 1 },
	},
	['nhan_vien'] = {
		male = {
			["arms"] = { clotheId = 4, variation = 0 },
			["pants"] = { clotheId = 260, variation = 0 },
			["t-shirt"] = { clotheId = 15, variation = 0 },
			["torso"] = { clotheId = 349, variation = 0},
		},
		female = {

		},
	},
	['quan_ly'] = {
		male = {
			["arms"] = { clotheId = 4, variation = 0 },
			["pants"] = { clotheId = 260, variation = 0 },
			["t-shirt"] = { clotheId = 15, variation = 0 },
			["torso"] = { clotheId = 349, variation = 0},
		},
		female = {

		},
	},
}

config.clothesHotel5 = {
	['quet_don'] = {
		male = {
			["mask"] = { clotheId = 0, variation = 0 },
			["arms"] = { clotheId = 0, variation = 0 },
			["pants"] = { clotheId = 9, variation = 0 },
			["bag"] = { clotheId = 0, variation = 0 },
			["shoes"] = { clotheId = 25, variation = 0 },
			["t-shirt"] = { clotheId = 59, variation = 0 },
			["torso"] = { clotheId = 226, variation = 0 },
			["decals"] = { clotheId = 0, variation = 0 },
			["kevlar"] = { clotheId = 0, variation = 0 },
		},
		maleHelmet = { clotheId = 145, variation = 0 },
		female = {
			["mask"] = { clotheId = 0, variation = 0 },
			["arms"] = { clotheId = 0, variation = 0 },
			["pants"] = { clotheId = 109, variation = 0 },
			["bag"] = { clotheId = 0, variation = 0 },
			["shoes"] = { clotheId = 25, variation = 0 },
			["t-shirt"] = { clotheId = 36, variation = 0 },
			["torso"] = { clotheId = 236, variation = 0 },
			["decals"] = { clotheId = 0, variation = 0 },
			["kevlar"] = { clotheId = 0, variation = 0 },
		},
		femaleHelmet = { clotheId = 144, variation = 0 },
	},
	['nhan_vien'] = {
		male = {
			["arms"] = { clotheId = 1, variation = 0 },
			["pants"] = { clotheId = 10, variation = 4 },
			["shoes"] = { clotheId = 10, variation = 0 },
			["t-shirt"] = { clotheId = 15, variation = 4 },
			["torso"] = { clotheId = 13, variation = 4 },
		},
		female = {
			["arms"] = { clotheId = 3, variation = 0 },
			["pants"] = { clotheId = 6, variation = 4 },
			["shoes"] = { clotheId = 13, variation = 0 },
			["t-shirt"] = { clotheId = 14, variation = 4 },
			["torso"] = { clotheId = 6, variation = 4 },
		},
	},
	['quan_ly'] = {
		male = {
			["arms"] = { clotheId = 4, variation = 0 },
			["pants"] = { clotheId = 28, variation = 4 },
			["shoes"] = { clotheId = 21, variation = 0 },
			["t-shirt"] = { clotheId = 26, variation = 4 },
			["torso"] = { clotheId = 29, variation = 4 },
		},
		female = {
			["arms"] = { clotheId = 3, variation = 0 },
			["pants"] = { clotheId = 37, variation = 4 },
			["shoes"] = { clotheId = 29, variation = 0 },
			["t-shirt"] = { clotheId = 35, variation = 4 },
			["torso"] = { clotheId = 27, variation = 4 },
		},
	},
}

config.clothesHotel6 = {
	['quet_don'] = {
		male = {
			["arms"] = { clotheId = 4, variation = 0 },
			["pants"] = { clotheId = 260, variation = 0 },
			["t-shirt"] = { clotheId = 15, variation = 0 },
			["torso"] = { clotheId = 349, variation = 0},
		},
		maleHelmet = { clotheId = 145, variation = 1 },
		female = {
		},
		femaleHelmet = { clotheId = 144, variation = 1 },
	},
	['nhan_vien'] = {
		male = {
			["arms"] = { clotheId = 4, variation = 0 },
			["pants"] = { clotheId = 260, variation = 0 },
			["t-shirt"] = { clotheId = 15, variation = 0 },
			["torso"] = { clotheId = 349, variation = 0},
		},
		female = {

		},
	},
	['quan_ly'] = {
		male = {
			["arms"] = { clotheId = 4, variation = 0 },
			["pants"] = { clotheId = 260, variation = 0 },
			["t-shirt"] = { clotheId = 15, variation = 0 },
			["torso"] = { clotheId = 349, variation = 0},
		},
		female = {

		},
	},
}

config.motels = {
	[1] = { -- index name of motel
		manual = false, -- Đặt nhà trọ để tự động chấp nhận người cư ngụ hoặc chỉ sai chủ sở hữu của Motel mới có thể chấp nhận người cư ngụ
		Mlo = false, -- if MLO you need to configure each doors coordinates,stash etc. if false resource will use shells
		shell = 'modern', -- shell type, configure only if using Mlo = true
		label = '9H Hotel',
		blipLabel = '9H Hotel', -- Tên hiển thị trên map và UI (nếu không set sẽ dùng label)
		webhook = {
			rental    = '', -- Log cho thuê phòng
			extension = '', -- Log gia hạn phòng
			cleanup   = '', -- Log dọn dẹp phòng
		},
		rental_period = 'day',-- hour, day, month
		rate = 5000, -- cost per period
		businessprice = 1000,
		motel = 'dxmotel_motels',
		payment = 'money', -- money, bank
		items_boss = nil,
		door = `gabz_pinkcage_doors_front`, -- door hash for MLO type
		rentcoord = vec3(352.4140, -1653.9818, 38.2958),
		coord = vec3(352.4140, -1653.9818, 38.2958), -- center of the motel location
		radius = 50.0, -- radius of motel location
		maxoccupants = 1, -- maximum renters per room
		returnmoney = false,
		uniquestash = false, -- Nếu đúng.Mỗi người chơi có ID Stash duy nhất (không thể chia sẻ và không thể đánh cắp).Nếu stash sai được chia sẻ cho tất cả người cư ngụ nếu MaxOccupans là> 1
		-- NPC config for rental point
		npc = {
			model = `a_m_m_hasjew_01`, -- NPC model hash
			heading = 45.000 -- NPC facing direction
		},
		-- Stash inventory config for this motel
		stash = {
			slots = 25,
			weight = 99000
		},
		-- Fridge inventory config for this motel
		fridge = {
			slots = 5,
			weight = 5000
		},
		-- Tính năng công ty (Office)
		office = {
			enabled = true,
			label = 'Executive Cool',
			coord = vec3(-141.5429, -620.9524, 168.8204),
			locker = vec3(-138.2, -623.5, 168.82),
			bucket = 9004,
		},
		doors = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56,
				57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80},
		clothesEnabled = true,
		clothes = config.clothesHotel1,
	},

	[2] = { -- index name of motel
		manual = false, -- Đặt nhà trọ để tự động chấp nhận người cư ngụ hoặc chỉ sai chủ sở hữu của Motel mới có thể chấp nhận người cư ngụ
		Mlo = false, -- if MLO you need to configure each doors coordinates,stash etc. if false resource will use shells
		shell = 'modern', -- shell type, configure only if using Mlo = true
		label = 'NVR 95 HOTEL',
		blipLabel = 'NVR 95 HOTEL', -- Tên hiển thị trên map và UI (nếu không set sẽ dùng label)
		webhook = {
			rental    = '', -- Log cho thuê phòng
			extension = '', -- Log gia hạn phòng
			cleanup   = '', -- Log dọn dẹp phòng
		},
		rental_period = 'day',-- hour, day, month
		rate = 5000, -- cost per period
		businessprice = 1000,
		motel = 'night_motels',
		payment = 'money', -- money, bank
		items_boss = nil,
		door = `gabz_pinkcage_doors_front`, -- door hash for MLO type
		rentcoord = vec3(-310.2503, 221.7927, 87.9280),
		coord = vec3(-310.2503, 221.7927, 87.9280), -- center of the motel location
		radius = 100.0, -- radius of motel location
		maxoccupants = 1, -- maximum renters per room
		returnmoney = false,
		uniquestash = false, -- Nếu đúng.Mỗi người chơi có ID Stash duy nhất (không thể chia sẻ và không thể đánh cắp).Nếu stash sai được chia sẻ cho tất cả người cư ngụ nếu MaxOccupans là> 1
		-- NPC config for rental point
		npc = {
			model = `a_m_m_polynesian_01`, -- NPC model hash
			heading = 6.7903 -- NPC facing direction-310.3264, 222.4129, 87.9260, 6.7903
		},
		-- Stash inventory config for this motel
		stash = {
			slots = 25,
			weight = 99000
		},
		-- Fridge inventory config for this motel
		fridge = {
			slots = 5,
			weight = 5000
		},		-- Tính năng công ty (Office)
		office = {
			enabled = true,
			label = 'Executive Cool',
			coord = vec3(-141.5429, -620.9524, 168.8204),
			locker = vec3(-138.2, -623.5, 168.82),
			bucket = 9005,
		},
		doors = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56,
				57, 58, 59, 60, 61, 62, 63, 64, 65},
		clothesEnabled = false,
		clothes = config.clothesHotel5,
	},

	[3] = { -- index name of motel
		manual = false, -- Đặt nhà trọ để tự động chấp nhận người cư ngụ hoặc chỉ sai chủ sở hữu của Motel mới có thể chấp nhận người cư ngụ
		Mlo = false, -- if MLO you need to configure each doors coordinates,stash etc. if false resource will use shells
		shell = 'modern', -- shell type, configure only if using Mlo = true
		label = 'SD MOTEL',
		blipLabel = 'SD MOTEL', -- Tên hiển thị trên map và UI (nếu không set sẽ dùng label)
		webhook = {
			rental    = '', -- Log cho thuê phòng
			extension = '', -- Log gia hạn phòng
			cleanup   = '', -- Log dọn dẹp phòng
		},
		rental_period = 'day',-- hour, day, month
		rate = 5000, -- cost per period
		businessprice = 1000,
		motel = 'sdhp_motels',
		payment = 'money', -- money, bank
		items_boss = nil,
		door = `gabz_pinkcage_doors_front`, -- door hash for MLO type
		rentcoord = vec3(389.4106, 1.7214, 91.4146),
		coord = vec3(389.4106, 1.7214, 91.4146), -- center of the motel location
		radius = 50.0, -- radius of motel location
		maxoccupants = 1, -- maximum renters per room
		returnmoney = false,
		uniquestash = false, -- Nếu đúng.Mỗi người chơi có ID Stash duy nhất (không thể chia sẻ và không thể đánh cắp).Nếu stash sai được chia sẻ cho tất cả người cư ngụ nếu MaxOccupans là> 1
		-- NPC config for rental point
		npc = {
			model = `a_m_m_polynesian_01`, -- NPC model hash
			heading = 68.9799-- NPC facing direction
		},
		-- Stash inventory config for this motel
		stash = {
			slots = 25,
			weight = 99000
		},
		-- Fridge inventory config for this motel
		fridge = {
			slots = 5,
			weight = 5000
		},		-- Tính năng công ty (Office)
		office = {
			enabled = true,
			label = 'Executive Cool',
			coord = vec3(-141.5429, -620.9524, 168.8204),
			locker = vec3(-138.2, -623.5, 168.82),
			bucket = 9006,
		},
		doors = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56,
				57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80},
		clothesEnabled = true,
		clothes = config.clothesHotel6,
	},
}

config.extrafunction = {
	['bed'] = function(data,identifier)
		TriggerEvent('luckyme')
	end,
	['fridge'] = function(data,identifier)
		-- Find motel config by motel string name
		local fridgeConfig = config.defaultFridge
		for motelIndex, motelData in pairs(config.motels) do
			if motelData.motel == data.motel and motelData.fridge then
				fridgeConfig = motelData.fridge
				break
			end
		end
		
		TriggerEvent('ox_inventory:openInventory', 'stash', {
			id = 'fridge_'..data.motel..'_'..identifier..'_'..data.index, 
			name = 'Fridge - Room #'..data.index, 
			slots = fridgeConfig.slots, 
			weight = fridgeConfig.weight, 
			coords = GetEntityCoords(cache.ped)
		})
	end,
	['exit'] = function(data)
		local coord = LocalPlayer.state.lastloc or vec3(data.coord.x,data.coord.y,data.coord.z)
		DoScreenFadeOut(500)
		while not IsScreenFadedOut() do
			Wait(10)
		end
		SendNUIMessage({
			type = 'door'
		})
		return Teleport(coord.x,coord.y,coord.z,0.0,true)
	end,
}

config.Text = {
	['stash'] = 'Kho',
	['fridge'] = 'Tủ Lạnh',
	['wardrobe'] = 'Giường Ngủ',
	['bed'] = 'Giường Ngủ',
	['door'] = 'Cửa',
	['exit'] = 'Thoát',
	['changePed'] = 'Thay đổi Ped',
}

config.icons = {
	['door'] = 'fas fa-door-open',
	['stash'] = 'fas fa-box',
	['wardrobe'] = 'fas fa-bed',
	['fridge'] = 'fas fa-ice-cream',
	['bed'] = 'fas fa-bed',
	['exit'] = 'fas fa-door-open',
	['changePed'] = 'fas fa-user-circle',
}

config.stashblacklist = {
	['stash'] = { -- type of inventory
		blacklist = { -- list of blacklists items
			money = true,
			black_money = true,
		},
	},
	['fridge'] = { -- type of inventory
		blacklist = { -- list of blacklists items
			WEAPON_PISTOL = true,
		},
	},
}

config.trashOffsets = {
	['standard'] = {
		vec3(-1.0, -1.0, 0.0),
		vec3(1.0, 1.0, 0.0),
		vec3(-1.5, 1.5, 0.0),
		vec3(1.5, -1.5, 0.0),
		vec3(0.5, -2.5, 0.0),
		vec3(-0.5, 2.5, 0.0),
		vec3(-1.2, -2.0, 0.0),
		vec3(1.2, 2.0, 0.0),
		vec3(0.0, -0.5, 0.0),
		vec3(-2.0, 0.0, 0.0),
		vec3(2.0, 0.0, 0.0),
		vec3(-0.8, 1.8, 0.0),
	},
	['modern'] = {
		vec3(-3.0, -2.0, 0.0),
		vec3(3.0, 2.0, 0.0),
		vec3(-4.0, 2.0, 0.0),
		vec3(4.0, -2.0, 0.0),
		vec3(1.0, -3.0, 0.0),
		vec3(-1.0, 3.0, 0.0),
		vec3(-2.0, -4.0, 0.0),
		vec3(2.0, 4.0, 0.0),
		vec3(0.0, -2.0, 0.0),
		vec3(-3.0, 0.0, 0.0),
		vec3(3.0, 0.0, 0.0),
		vec3(-1.5, 1.5, 0.0),
	}
}

PlayerData,ESX,QBCORE,zones,shelzones,blips = {},nil,nil,{},{},{}

function import(file)
	local name = ('%s.lua'):format(file)
	local content = LoadResourceFile(GetCurrentResourceName(),name)
	local f, err = load(content)
	return f()
end

if GetResourceState('es_extended') == 'started' then
	ESX = exports['es_extended']:getSharedObject()
elseif GetResourceState('qb-core') == 'started' then
	QBCORE = exports['qb-core']:GetCoreObject()
end