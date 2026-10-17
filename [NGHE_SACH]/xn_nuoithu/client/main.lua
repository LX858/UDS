local ANIMAL = {}
local Count = 0
local Anti_Spam_ChoAn = false
local Anti_Spam_ThuHoach = false
local _SpamSpawn = false
local UIVisible = false
local PlayerUpgradeData = nil
local MaxCapacity = 5
local InZone = false

-- Hàm gửi data tới NUI
function UpdateAnimalUI()
	local animalData = {}
	for i, animal in ipairs(ANIMAL) do
		table.insert(animalData, {
			type = animal.PedType or "pigagle",
			hungry = animal.Hungry or 0
		})
	end
	
	SendNUIMessage({
		action = "updateAnimals",
		animals = animalData
	})
end

function ShowAnimalUI(show)
	UIVisible = show
	SetNuiFocus(false, false)
	
	if show then
		-- Lấy dữ liệu nâng cấp khi mở UI
		TriggerServerEvent('vie-chamsocthucung:server:GetUpgradeData')
	end
	
	local animalData = {}
	for i, animal in ipairs(ANIMAL) do
		table.insert(animalData, {
			type = animal.PedType or "pigagle",
			hungry = animal.Hungry or 0
		})
	end
	
	SendNUIMessage({
		action = "showUI",
		show = show,
		animals = animalData,
		maxAnimals = MaxCapacity,
		upgradeData = PlayerUpgradeData
	})
end

-- Nhận dữ liệu nâng cấp từ server
RegisterNetEvent('vie-chamsocthucung:client:ReceiveUpgradeData', function(upgradeData, maxCapacity)
	PlayerUpgradeData = upgradeData
	MaxCapacity = maxCapacity
	
	-- Cập nhật Config.SoLuong_ChamSoc_ToiDa
	Config.SoLuong_ChamSoc_ToiDa = maxCapacity
	
	-- Gửi dữ liệu lên NUI
	SendNUIMessage({
		action = "updateUpgradeData",
		upgradeData = upgradeData,
		maxAnimals = maxCapacity
	})
end)

-- Event nhận từ server khi bắt đầu nâng cấp (sau khi validate đủ item/skill points)
RegisterNetEvent('vie-chamsocthucung:client:StartUpgradeAnimation', function(statType, nextLevel)
	SendNUIMessage({
		action = "startUpgradeAnimation",
		statType = statType,
		nextLevel = nextLevel
	})
end)

-- NUI Callback
RegisterNUICallback('closeUI', function(data, cb)
	ShowAnimalUI(false)
	cb('ok')
end)

-- NUI Callback cho nâng cấp (nhận selectedSlots từ NUI)
RegisterNUICallback('upgradeStat', function(data, cb)
	TriggerServerEvent('vie-chamsocthucung:server:UpgradeStat', data.statType, data.selectedSlots)
	cb('ok')
end)

-- NUI Callback lấy clothing inventory
RegisterNUICallback('getClothingInventory', function(data, cb)
	TriggerServerEvent('vie-chamsocthucung:server:GetClothingInventory')
	cb('ok')
end)

-- Nhận clothing inventory từ server
RegisterNetEvent('vie-chamsocthucung:client:ReceiveClothingInventory', function(clothingItems)
	SendNUIMessage({
		action = "updateClothingInventory",
		clothingItems = clothingItems
	})
end)

-- Hàm random động vật theo tỷ lệ (có tính buff may mắn)
function GetRandomAnimal()
	local luckLevel = 0
	if PlayerUpgradeData and PlayerUpgradeData.luck_level then
		luckLevel = PlayerUpgradeData.luck_level
	end
	
	--print("^3[DEBUG] Luck Level: " .. luckLevel .. "^0")
	
	-- Tính chance với công thức: Level 0 = 85/14/1/0.5/0.5, Level 5 = 74/20/3/1.5/1.5
	local chances = {}
	
	for i, animalType in ipairs(Config.AnimalTypes) do
		local chance = animalType.chance
		
		if i == 1 then
			-- Heo: giảm 2.2% mỗi level (85 → 74)
			chance = chance - (luckLevel * 2.2)
		elseif i == 2 then
			-- Bò: tăng 1.2% mỗi level (14 → 20)
			chance = chance + (luckLevel * 1.2)
		elseif i == 3 then
			-- Zebra: tăng 0.4% mỗi level (1 → 3)
			chance = chance + (luckLevel * 0.4)
		elseif i == 4 then
			-- Capibara_Cute: tăng 0.2% mỗi level (0.5 → 1.5)
			chance = chance + (luckLevel * 0.2)
		elseif i == 5 then
			-- Littleram_ped: tăng 0.2% mỗi level (0.5 → 1.5)
			chance = chance + (luckLevel * 0.2)
		end
		
		-- Đảm bảo không âm
		chance = math.max(chance, 0.1)
		
		table.insert(chances, {ped = animalType.ped, chance = chance})
	end
	
	-- Tính tổng để normalize về 100%
	local totalChance = 0
	for _, data in ipairs(chances) do
		totalChance = totalChance + data.chance
	end
	
	-- Normalize và tính range
	local currentChance = 0
	local normalizedChances = {}
	
	for i, data in ipairs(chances) do
		local normalizedChance = (data.chance / totalChance) * 100
		table.insert(normalizedChances, {
			ped = data.ped,
			chance = normalizedChance,
			rangeStart = currentChance + 1,
			rangeEnd = currentChance + normalizedChance
		})
		currentChance = currentChance + normalizedChance
		
		-- print(string.format("^2[DEBUG] %s: %.1f%% (Range: %.1f-%.1f)^0", 
		-- 	data.ped, normalizedChance, normalizedChances[i].rangeStart, normalizedChances[i].rangeEnd))
	end
	
	-- Random (dùng float để hỗ trợ tỷ lệ nhỏ hơn 1%)
	local random = math.random() * 100
	--print("^3[DEBUG] Random: " .. random .. "^0")
	
	-- Chọn con dựa trên random
	for i, data in ipairs(normalizedChances) do
		if random <= data.rangeEnd then
			--print("^1[DEBUG] Selected: " .. data.ped .. "^0")
			return data.ped
		end
	end
	
	-- Fallback về pig nếu có lỗi
	return "pigagle"
end

local Zone_ChamSoc = lib.zones.poly({
    points = { 
        vector3(1468.78, 1054.46, 114.33),
        vector3(1468.69, 1080.28, 114.33),
        vector3(1506.67, 1080.61, 114.33),
        vector3(1506.69, 1054.3, 114.33)
    },
    thickness = 50,
    debug = false,
    inside = function()
        -- Inside zone - hiển thị UI
        InZone = true
        if not UIVisible then
            ShowAnimalUI(true)
        end
    end,
    onEnter = function()
        -- Entering zone
        InZone = true
        ShowAnimalUI(true)
    end,
    onExit = function()
        -- Exiting zone - ẩn UI
        InZone = false
        ShowAnimalUI(false)
    end
})

-- CreateThread(function()
-- 	while true do 
-- 		Wait(1)
-- 		point = GetEntityCoords(PlayerPedId(),true)
-- 		local In_Zone_ChamSoc = Zone_ChamSoc:contains(point)
-- 		if In_Zone_ChamSoc then
-- 			-- Đã có NUI hiển thị, không cần text nữa
-- 			-- for i=1, #Config.Feed, 1 do
-- 			-- 	BUDRAWTEXT(0.429, 0.90, "<FONT FACE='Oswald'>Chăm sóc tối đa: "..Count.."<FONT FACE='Oswald'>/"..Config.SoLuong_ChamSoc_ToiDa.."")
-- 			-- 	BUDRAWTEXT(0.410, 0.93, Config.Feed[i].text)
-- 			-- 	DisableControlAction(1, 25, true) -- Right Mouse Button
-- 			-- 	DisableControlAction(1, 140, true) -- R
-- 			-- 	DisableControlAction(1, 141, true) -- Q
-- 			-- 	DisableControlAction(1, 142, true) -- Left Mouse Button
-- 			-- 	DisableControlAction(1, 21, true) -- Left Shift
-- 			-- 	DisableControlAction(1, 19, true) -- Left Alt
-- 			-- end
-- 			-- DisableControlAction(1, 25, true)
-- 			-- DisableControlAction(1, 140, true)
-- 			-- DisableControlAction(1, 141, true)
-- 			-- DisableControlAction(1, 142, true)
-- 			-- DisableControlAction(1, 21, true)
-- 			-- DisableControlAction(1, 19, true)
-- 		end
-- 	end
-- end)

function BUDRAWTEXT(a,b,c)
	SetTextScale(0.0, 0.4)
	SetTextDropShadow()
	SetTextOutline()
	SetTextColour(255, 255, 255, 500)
	SetTextEntry("STRING")
	AddTextComponentString(""..c.."")
	DrawText(a,b)
end
--======================================== Heo ========================================
RegisterNetEvent("vie-chamsocthucung:client:Start")
AddEventHandler("vie-chamsocthucung:client:Start", function(a)
	point = GetEntityCoords(PlayerPedId(),true)
	local In_Zone_ChamSoc = Zone_ChamSoc:contains(point)

	if _SpamSpawn == false then
		if In_Zone_ChamSoc then
			StartAnimals(a)
		else
			exports.qbx_core:Notify("Bạn không ở trong khu vực chăm sóc thú cưng", "error")
		end
	else
		exports.qbx_core:Notify("Chậm cái tay thôi nè đừng có spam như vậy!", "warning")
	end
end)

function StartAnimals(BU)
	Heo = true
	if not Start then
		if Count < Config.SoLuong_ChamSoc_ToiDa then
			if lib.progressBar({
				duration = math.random(1000, 1500),
				label = "Đang thả Heo",
				useWhileDead = false,
				canCancel = true,
				disable = {
					car = true,
				},
			}) then 
				Count = Count + 1
				Start = true

				for i =1, #Config.Feed, 1 do
					TriggerServerEvent("vie-chamsocthucung:server:RemoveItemHeo")
				end

				if not HasAnimDictLoaded('anim@heists@money_grab@briefcase') then RequestAnimDict('anim@heists@money_grab@briefcase') while not HasAnimDictLoaded('anim@heists@money_grab@briefcase') do Wait(1) end end
				TaskPlayAnim(PlayerPedId(), 'anim@heists@money_grab@briefcase', 'put_down_case', 8.0, -8.0, -1, 1, 0, false, false, false)
				Wait(1000)
				ClearPedTasks(PlayerPedId())
			
				CreateThread(function()
					local animal 
					for i =1, #Config.Feed, 1 do
						if Config.Feed[i].item.use == BU.item.use then
						-- Random động vật theo tỷ lệ
						local selectedPed = GetRandomAnimal()
						
							-- Lấy thời gian phát triển của động vật
							local growTime = 10 * 1000 -- Default
							for _, animalType in ipairs(Config.AnimalTypes) do
								if animalType.ped == selectedPed then
									growTime = animalType.growTime
									
									-- Áp dụng buff thời gian cho bò và lạc đà
									if selectedPed ~= "pigagle" and PlayerUpgradeData and PlayerUpgradeData.time_level then
										local timeReduction = PlayerUpgradeData.time_level * 60 * 1000 -- Mỗi level giảm 1 phút
										growTime = math.max(growTime - timeReduction, 60 * 1000) -- Tối thiểu 1 phút
									end
									break
								end
							end
							
							RequestModel(GetHashKey(selectedPed))
							while not HasModelLoaded(GetHashKey(selectedPed)) do Wait(1) end
							local pos = GetEntityCoords(PlayerPedId())
							animal = CreatePed(29, GetHashKey(selectedPed), pos.x + 0.5, pos.y + 0.5, pos.z - 0.9, 90, false, false)
							SetEntityInvincible(animal,true)
							Wait(100)
							_SpamSpawn = false
						
						-- Thêm vào bảng ANIMAL
						table.insert(ANIMAL, {Animal = animal, Hungry = 0, Give = false, Feed = false, Data = Config.Feed[i], Cool = 0, Status = false, PedType = selectedPed, GrowTime = growTime})
						
						-- Thêm ox_target cho động vật
						exports.ox_target:addLocalEntity(animal, {
							{
								name = 'feed_animal_' .. animal,
								icon = 'fas fa-drumstick-bite',
								label = 'Cho ăn',
								canInteract = function(entity)
									for _, k in pairs(ANIMAL) do
										if k.Animal == entity then
											return k.Feed == true and k.Give == false
										end
									end
									return false
								end,
								onSelect = function(data)
									ChoAnTarget(data.entity)
								end,
							},
							{
								name = 'harvest_animal_' .. animal,
								icon = 'fas fa-hand-holding-heart',
								label = 'Thu hoạch',
								canInteract = function(entity)
									for _, k in pairs(ANIMAL) do
										if k.Animal == entity then
											return k.Feed == false and k.Give == true
										end
									end
									return false
								end,
								onSelect = function(data)
									ThuHoachTarget(data.entity)
								end,
							}
						})
						
						-- Cập nhật UI
						UpdateAnimalUI()
							break
						end
					end
					CreateThread(function()
						while animal ~= nil do
							Wait(1e3)
							local x2, y2, z2 = table.unpack(GetEntityCoords(PlayerPedId()))
							TaskGoToCoordAnyMeans(animal, x2 + math.random(0, 5), y2 + math.random(0, 5), z2, 1, 0, 0, 7.86603e5, 1)
							Wait(math.random(7e3, 1.5e4))
						end
					end)
					CreateThread(function()
						while animal ~= nil do
							-- Tính thời gian tăng mỗi 1% dựa trên growTime
							local waitTime = BU.time_need
							for _,k in pairs(ANIMAL) do
								if k.Animal == animal then
									-- Chia growTime cho 100 để mỗi % tăng đều
									waitTime = (k.GrowTime or BU.time_need) / 100
									break
								end
							end
							
							Wait(waitTime)
							
							for _,k in pairs(ANIMAL) do
								if k.Animal == animal then
									if k.Give == false or k.Feed == true then
										if k.Hungry < 100 then
											k.Hungry = k.Hungry + 1
											UpdateAnimalUI() -- Cập nhật UI mỗi khi tăng
										end
										if k.Feed == true then
											if not k.Status then
												k.Cool = k.Cool + 1
												if k.Cool >= 20 then
													if not KILL then
														KILL = true
														SetEntityHealth(animal, 0)
														Wait(1500)
														DeleteEntity(animal)
														SetEntityInvincible(animal,false)
														table.remove(ANIMAL, _)
														Count = Count - 1
														UpdateAnimalUI() -- Cập nhật UI khi xóa
														KILL = false 
														k.Cool = 0
													end
												end
											end
										end
									end
								end
							end
						end
					end)
					CreateThread(function()
						while animal ~= nil do
							Wait(0)
							for _,k in pairs(ANIMAL) do
								if k.Animal == animal then
									if k.Give == false then
										if k.Hungry == 100 then
											k.Give = true
											k.Feed = false
										end
									end
								end
							end
						end
					end)
					CreateThread(function()
						while animal ~= nil do
							Wait(3000)
							for _,k in pairs(ANIMAL) do
								if k.Animal == animal then
									if k.Give == false then
										if k.Hungry >= BU.need then
											if k.Feed == false then
												k.Cool = 0
												for i=1, #BU.percent_feed, 1 do
													if k.Hungry == BU.percent_feed[i] then
														k.Feed = true
													end
												end
											end
										end
									end
								end
							end
						end
					end)
				end)
				Start = false
			end
		else
			exports.qbx_core:Notify("Bạn đang chăm sóc cùng lúc "..Config.SoLuong_ChamSoc_ToiDa.." thú cưng không thể chăm sóc thêm", "warning")
		end
	end
end
--========================================================================================================================
CreateThread(function()
	while true do
		Busleep = 500
		if Count > 0 then
			Busleep = 0
			for i=1, #ANIMAL, 1 do
				local A = 1 / GetFrameTime()
				local B = GetPedBoneCoords(ANIMAL[i].Animal, 1.2844e4, 0, 0, 0) + vector3(0, 0, 1.1) + GetEntityVelocity(ANIMAL[i].Animal) / A
				if math.floor(#(GetGameplayCamCoords() - B)) < 20 and World3dToScreen2d(B.x, B.y, B.z) then
					SetDrawOrigin(B, false)
					if ANIMAL[i].Feed == false and ANIMAL[i].Give == false then
						DrawMarker(20, B.x, B.y, B.z - 0.35, 0, 0, 0, 0, 180, 0, 0.3, 0.3, 0.3, Config.Setting.marker.normal.r, Config.Setting.marker.normal.g, Config.Setting.marker.normal.b, Config.Setting.marker.intensive, false, true, 2, true, false, false)
						ClearDrawOrigin()
					end
					if ANIMAL[i].Feed == true and ANIMAL[i].Give == false then
						DrawMarker(20, B.x, B.y, B.z - 0.35, 0, 0, 0, 0, 180, 0, 0.3, 0.3, 0.3, Config.Setting.marker.feed.r, Config.Setting.marker.feed.g, Config.Setting.marker.feed.b, Config.Setting.marker.intensive, false, true, 2, true, false, false)
						ClearDrawOrigin()
					end
					if ANIMAL[i].Feed == false and ANIMAL[i].Give == true then
						DrawMarker(20, B.x, B.y, B.z - 0.35, 0, 0, 0, 0, 180, 0, 0.3, 0.3, 0.3, Config.Setting.marker.kill.r, Config.Setting.marker.kill.g, Config.Setting.marker.kill.b, Config.Setting.marker.intensive, false, true, 2, true, false, false)
						ClearDrawOrigin()
					end
				end
			end
		end
		Wait(Busleep) 
	end
end)

CreateThread(function()
	while true do
		local Busleep = 1000
		for i=1, #ANIMAL, 1 do
			local ped = PlayerPedId()
			local pCoords = GetEntityCoords(ped)
			local coords = GetEntityCoords(ANIMAL[i].Animal)
			local dist = #(pCoords - coords)
			if dist < Config.Setting.animal.distance.text then
				Busleep = 0
				if ANIMAL[i].Feed == false and ANIMAL[i].Give == false then
					DrawText3Ds(GetEntityCoords(ANIMAL[i].Animal), "<FONT FACE='Oswald'>~o~[TRƯỞNG THÀNH]\n"..ANIMAL[i].Hungry.."<FONT FACE='Oswald'>%")
				end
				if ANIMAL[i].Feed == true and ANIMAL[i].Give == false then
					if Anti_Spam_ChoAn == false then
						DrawText3Ds(GetEntityCoords(ANIMAL[i].Animal), "<FONT FACE='Oswald'>~g~Có thể cho ăn")
					else
						DrawText3Ds(GetEntityCoords(ANIMAL[i].Animal), "<FONT FACE='Oswald'>~o~Đang cho ăn")
					end
				end
				if ANIMAL[i].Feed == false and ANIMAL[i].Give == true then
					if Anti_Spam_ThuHoach == false then
						DrawText3Ds(GetEntityCoords(ANIMAL[i].Animal), "<FONT FACE='Oswald'>~g~Có thể thu hoạch")
					else
						DrawText3Ds(GetEntityCoords(ANIMAL[i].Animal), "<FONT FACE='Oswald'>~o~Đang thu hoạch")
					end
				end
			end
		end
		Wait(Busleep) 
	end
end)

CreateThread(function()
	for i =1,#Config.Feed, 1 do
		if Config.Feed[i].blips.enabled then
			local B = AddBlipForCoord(Config.Feed[i].coords.x, Config.Feed[i].coords.y, Config.Feed[i].coords.z)
			SetBlipSprite(B, Config.Feed[i].blips.sprite)
			SetBlipScale(B, Config.Feed[i].blips.scale)
			SetBlipColour(B, Config.Feed[i].blips.color)
			SetBlipAsShortRange(B, true)
			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(Config.Feed[i].blips.text)
			EndTextCommandSetBlipName(B)
		end
	end
end)

-- Functions cho ox_target
function ChoAnTarget(entity)
	local busy = exports["progressbar"]:isDoingSomething()
	if busy then
		exports.qbx_core:Notify("Không thể thao tác lúc này!", "error")
		return
	end
	
	if Anti_Spam_ChoAn then
		exports.qbx_core:Notify("Đang cho ăn, chờ chút!", "warning")
		return
	end
	
	for i, k in pairs(ANIMAL) do
		if k.Animal == entity then
			Anti_Spam_ChoAn = true
			k.Status = true
			local HasItem = exports.ox_inventory:Search('count', Config.ThucAn)
			if HasItem > 0 then
				LocalPlayer.state.invBusy = true
				exports['progressbar']:Progress({
					name = "choan",
					duration = 2000,
					label = "Đang cho ăn",
					useWhileDead = false,
					canCancel = false,
					disarm = true,
					controlDisables = {
						disableMovement = true,
						disableCarMovement = true,
						disableMouse = false,
						disableCombat = true,
					},
					animation = {
						animDict = "amb@world_human_bum_wash@male@low@idle_a",
						anim = "idle_a",
						flags = 49,
					},
				}, function(status)
					LocalPlayer.state.invBusy = false
					if not status then
						k.Status = false
						k.Feed = false
						exports.qbx_core:Notify("Cho ăn thành công", "success")
						TriggerServerEvent("vie-chamsocthucung:server:RemoveItemthucan")
						Anti_Spam_ChoAn = false
					end
				end, function()
					Anti_Spam_ChoAn = false
					exports.qbx_core:Notify('Hủy thao tác cho ăn', 'error')
				end)
			else
				exports.qbx_core:Notify("Bạn không có thức ăn", "error")
				Anti_Spam_ChoAn = false
			end
			break
		end
	end
end

function ThuHoachTarget(entity)
	local busy = exports["progressbar"]:isDoingSomething()
	if busy then
		exports.qbx_core:Notify("Không thể thao tác lúc này!", "error")
		return
	end
	
	if Anti_Spam_ThuHoach then
		exports.qbx_core:Notify("Đang thu hoạch, chờ chút!", "warning")
		return
	end
	
	for i, k in pairs(ANIMAL) do
		if k.Animal == entity then
			Anti_Spam_ThuHoach = true
			FreezeEntityPosition(k.Animal, true)
			exports['progressbar']:Progress({
				name = "thuhoach",
				duration = 2000,
				label = "Đang thu hoạch",
				useWhileDead = false,
				canCancel = false,
				disarm = true,
				controlDisables = {
					disableMovement = true,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
				},
				animation = {
					animDict = "amb@world_human_bum_wash@male@low@idle_a",
					anim = "idle_a",
					flags = 49,
				},
			}, function(status)
				if not status then
					Count = Count - 1
					FreezeEntityPosition(k.Animal, false)
					SetEntityInvincible(k.Animal, false)
					
					-- Remove target trước khi xóa entity
					exports.ox_target:removeLocalEntity(k.Animal)
					
					-- Gửi server event để nhận thưởng
					exports['monitors']:TriggerProtectedServerEvent('vie-chamsocthucung:server:GiveReward', k.PedType or "pigagle")
					
					DeleteEntity(k.Animal)
					table.remove(ANIMAL, i)
					UpdateAnimalUI()
					Anti_Spam_ThuHoach = false
					
					if Count <= 0 then
						Corgi = false
					end
				end
			end, function()
				Anti_Spam_ThuHoach = false
				exports.qbx_core:Notify('Hủy thao tác thu hoạch', 'error')
			end)
			break
		end
	end
end

function DrawText3Ds(coords, text)
	SetTextScale(0.30, 0.30)
	SetTextEntry("STRING")
	AddTextComponentString(""..text.."")
	SetTextCentre(true)
	SetTextDropShadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextOutline()
	SetDrawOrigin(coords.x, coords.y, coords.z + 0.5, 0)
	DrawText(0.0, 0.0)
	ClearDrawOrigin()
end

AddEventHandler("onResourceStop", function(resource)
	if resource == GetCurrentResourceName() then
		if ANIMAL ~= nil then
			for i = 1,#ANIMAL, 1 do
				-- Remove target trước khi xóa entity
				exports.ox_target:removeLocalEntity(ANIMAL[i].Animal)
				DeleteEntity(ANIMAL[i].Animal)
				SetEntityInvincible(ANIMAL[i].Animal,false)
			end
		end
	end
end)


function KhoiTao_Ped_TC()
	CreatedPed_ShopTC = CreatePed(0, Hash_TC, Config.Pet_Shop_2.x, Config.Pet_Shop_2.y, Config.Pet_Shop_2.z -1, Config.Pet_Shop_2.w, false, true)
    FreezeEntityPosition(CreatedPed_ShopTC, true)
    SetEntityInvincible(CreatedPed_ShopTC, true)
    SetBlockingOfNonTemporaryEvents(CreatedPed_ShopTC, true)
end

CreateThread(function()
    Hash_TC = GetHashKey("u_m_m_streetart_01")
    RequestModel(Hash_TC)
    while not HasModelLoaded(Hash_TC) do
        Wait(1)
    end
    KhoiTao_Ped_TC()

	exports.ox_target:addBoxZone({
		coords = vec3(Config.Pet_Shop_2.x, Config.Pet_Shop_2.y,  Config.Pet_Shop_2.z),
		size = vec3(2, 2 ,2),
		rotation = 45,
		debug = false,
		options = {
		  {
			name = 'ChopShopParts',
			event = 'vie-chamsocthucung:client:fix_loi',
			icon = 'fas fa-hammer',
			label = 'Sửa lỗi chăm sóc thú cưng',
		  }
		}
	  })
end)

RegisterNetEvent('vie-chamsocthucung:client:fix_loi', function()
	if Anti_Spam_ChoAn == true and Anti_Spam_ThuHoach == true then
		Anti_Spam_ChoAn = false
		Anti_Spam_ThuHoach = false
		exports.qbx_core:Notify("Sửa lỗi cho ăn thành công", "success")
	else
		exports.qbx_core:Notify("Bạn không gặp lỗi !", "success")
	end
end)

-- Event mở giao diện nâng cấp
local UpgradePanelOpen = false

RegisterNetEvent('vie-chamsocthucung:client:OpenUpgradeUI', function()
	if UpgradePanelOpen then
		exports.qbx_core:Notify("Giao diện nâng cấp đã mở", "error")
		return
	end
	
	UpgradePanelOpen = true
	
	-- Lấy dữ liệu nâng cấp trước
	TriggerServerEvent('vie-chamsocthucung:server:GetUpgradeDataForCommand')
end)

-- Event nhận data và mở UI
RegisterNetEvent('vie-chamsocthucung:client:OpenUpgradePanel', function(upgradeData, maxCapacity)
	PlayerUpgradeData = upgradeData
	MaxCapacity = maxCapacity
	
	-- Tạo UI đặc biệt chỉ hiển thị upgrade panel
	SetNuiFocus(true, true)
	
	-- Gửi tín hiệu mở UI upgrade với data
	SendNUIMessage({
		action = "showUpgradeOnly",
		show = true,
		upgradeData = upgradeData,
		maxAnimals = maxCapacity
	})
end)

-- NUI Callback để đóng upgrade-only UI
RegisterNUICallback('closeUpgradeOnly', function(data, cb)
	-- Response cho NUI ngay
	cb('ok')
	
	-- Tắt focus ngay lập tức
	SetNuiFocus(false, false)
	UpgradePanelOpen = false
	
	-- Ẩn UI
	SendNUIMessage({
		action = "hideUpgradeOnly"
	})
	
	-- Nếu player đang trong zone, mở lại UI động vật
	if InZone then
		ShowAnimalUI(true)
	end
end)