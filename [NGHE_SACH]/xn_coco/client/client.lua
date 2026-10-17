
local QBCore = exports['qb-core']:GetCoreObject()
local Targets = {}
local Props = {}
local inProgress = false
local time = 1000
local PlayerJob = {}
local shopNPC = nil

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
    SpawnTrees()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

AddEventHandler('onResourceStart', function(resource) 
    if GetCurrentResourceName() ~= resource then 
        return 
    end
    if QBCore.Functions.GetPlayerData() ~= {} then
        PlayerJob = QBCore.Functions.GetPlayerData().job
        SpawnTrees()
    end
end)

function loadModel(model) if not HasModelLoaded(model) then
	if Config.Debug then print("^5Debug^7: ^2Loading Model^7: '^6"..model.."^7'") end
		while not HasModelLoaded(model) do
			if time > 0 then time = time - 1 RequestModel(model)
			else time = 1000 print("^5Debug^7: ^3LoadModel^7: ^2Timed out loading model ^7'^6"..model.."^7'") break
			end
			Wait(10)
		end
	end
end

function unloadModel(model) if Config.Debug then print("^5Debug^7: ^2Removing Model^7: '^6"..model.."^7'") end SetModelAsNoLongerNeeded(model) end

local function LoadModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Wait(1)
    end
end

function makeProp(data, freeze, synced)
    loadModel(data.prop)
    local prop = CreateObject(data.prop, data.coords.x, data.coords.y, data.coords.z-1.03, synced or false, synced or false, 0)
    SetEntityHeading(prop, data.coords.w+180.0)
    FreezeEntityPosition(prop, freeze or 0)
    if Config.Debug then print("^5Debug^7: ^6Prop ^2Created ^7: '^6"..prop.."^7'") end
    return prop
end

function removeJob()
	for k in pairs(Targets) do exports.ox_target:removeZone(k) end
	for i = 1, #Props do unloadModel(GetEntityModel(Props[i])) DeleteObject(Props[i]) end
	
	-- Clean up NPC
	if shopNPC then
		exports.ox_target:removeLocalEntity(shopNPC)
		DeleteEntity(shopNPC)
		shopNPC = nil
	end
end

function SpawnTrees()
    for k, v in pairs(Config.SpawnTrees) do
        Props[#Props+1] = makeProp({coords = v, prop = `8p_climb_palm_1`}, 1, false)
        if Config.ItemRequire then
        Targets["Coconut"..k] =
            exports.ox_target:addSphereZone({
                coords = vector3(v.x, v.y, v.z+9.03),
                radius = 0.6,
                debug = Config.Debug,
                options = {
                    {
                        event = "xx_coco:client:PickCoconut",
                        icon = Config.TargetPickIcon,
                        label = Languages.Picking,
                        name = "Coconut"..k,
                        items = Config.ItemRequireName,
                        stone = Props[#Props],
                        model = k
                    }
                },
                distance = 0.8
            })
        else
            Targets["Coconut"..k] =
            exports.ox_target:addSphereZone({
                coords = vector3(v.x, v.y, v.z+9.03),
                radius = 0.6,
                debug = Config.Debug,
                options = {
                    {
                        event = "xx_coco:client:PickCoconut",
                        icon = Config.TargetPickIcon,
                        label = Languages.Picking,
                        name = "Coconut"..k,
                        stone = Props[#Props],
                        model = k
                    }
                },
                distance = 0.8
            })
        end
    end
    if Config.Blip then
        local loc = Config.Locations["Blips"]
        local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
        SetBlipAsShortRange(blip, true)
        SetBlipSprite(blip, loc.sprite)
        SetBlipColour(blip, loc.col)
        SetBlipScale(blip, loc.size)
        SetBlipDisplay(blip, loc.display)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(loc.name)
        EndTextCommandSetBlipName(blip)
    end
end

function lookEnt(entity)
	if type(entity) == "vector3" then
		if not IsPedHeadingTowardsPosition(PlayerPedId(), entity.x, entity.y, entity.z, 10.0) then
			TaskTurnPedToFaceCoord(PlayerPedId(), entity.x, entity.y, entity.z, 1500)
			if Config.Debug then print("^5Debug^7: ^2Turning Player to^7: '^6"..json.encode(entity).."^7'") end
			Wait(1500)
		end
	else
		if DoesEntityExist(entity) then
			local coords = GetEntityCoords(entity)
			if not IsPedHeadingTowardsPosition(PlayerPedId(), coords.x, coords.y, coords.z, 30.0) then
				TaskTurnPedToFaceCoord(PlayerPedId(), coords.x, coords.y, coords.z, 1500)
				if Config.Debug then print("^5Debug^7: ^2Turning Player to^7: '^6"..entity.."^7'") end
				Wait(1500)
			end
		end
	end
end

-- NPC Shop Functions
function SpawnShopNPC()
    if not Config.NPCShop.enabled then return end
    
    local location = Config.NPCShop.location
    local model = Config.NPCShop.model
    
    -- Load NPC model
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    -- Create NPC
    shopNPC = CreatePed(4, model, location.x, location.y, location.z - 1.0, location.w, false, true)
    
    -- Configure NPC
    FreezeEntityPosition(shopNPC, true)
    SetEntityInvincible(shopNPC, true)
    SetBlockingOfNonTemporaryEvents(shopNPC, true)
    
    -- Add target zone for NPC
    exports.ox_target:addLocalEntity(shopNPC, {
        {
            name = 'npc_shop',
            icon = 'fa-solid fa-store',
            label = Languages.ShopTitle,
            onSelect = function()
                OpenShopMenu()
            end
        }
    })
    
    -- Create blip if enabled
    if Config.NPCShop.blip.enabled then
        local blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(blip, Config.NPCShop.blip.sprite)
        SetBlipColour(blip, Config.NPCShop.blip.color)
        SetBlipScale(blip, Config.NPCShop.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.NPCShop.blip.name)
        EndTextCommandSetBlipName(blip)
    end
end

function OpenShopMenu()
    local options = {}
    
    for i, item in ipairs(Config.NPCShop.items) do
        options[#options + 1] = {
            title = item.label,
            description = item.description .. '\n💰 Giá: $' .. item.price,
            icon = 'fa-solid fa-shopping-cart',
            onSelect = function()
                OpenQuantityInput(item)
            end
        }
    end
    
    lib.registerContext({
        id = 'npc_shop_menu',
        title = Languages.ShopTitle,
        options = options
    })
    
    lib.showContext('npc_shop_menu')
end

function OpenQuantityInput(item)
    local input = lib.inputDialog(Languages.EnterQuantity, {
        {
            type = 'number',
            label = Languages.QuantityLabel,
            required = true,
            min = 1,
            max = 50
        }
    })
    
    if input and input[1] then
        local quantity = tonumber(input[1])
        if quantity and quantity > 0 then
            TriggerServerEvent('xx_coco:server:buyItem', item.name, quantity, item.price)
        else
            QBCore.Functions.Notify(Languages.InvalidQuantity, 'error')
        end
    end
end

RegisterNetEvent('xx_coco:client:PickCoconut')
AddEventHandler('xx_coco:client:PickCoconut', function(data)
    local ped = PlayerPedId()
    local tree = data.model
    local pos = GetEntityCoords(PlayerPedId())
    
    -- Kiểm tra khoảng cách: đảm bảo người chơi đang đứng gần cây này nhất
    -- Sử dụng tọa độ target (z+9.03) thay vì tọa độ gốc cây
    local targetTreeCoords = Config.SpawnTrees[tree]
    local targetPos = vector3(targetTreeCoords.x, targetTreeCoords.y, targetTreeCoords.z + 9.03)
    local distanceToTarget = #(pos - targetPos)
    
    -- Kiểm tra xem có cây nào khác gần hơn không
    local closestTree = tree
    local closestDistance = distanceToTarget
    for k, v in pairs(Config.SpawnTrees) do
        local treeTargetPos = vector3(v.x, v.y, v.z + 9.03)
        local dist = #(pos - treeTargetPos)
        if dist < closestDistance then
            closestDistance = dist
            closestTree = k
        end
    end
    
    -- Nếu cây gần nhất không phải là cây đang tương tác, từ chối
    if closestTree ~= tree then
        QBCore.Functions.Notify('Bạn đang đứng quá xa cây dừa này!', 'error')
        return
    end
    
    QBCore.Functions.TriggerCallback('xx_coco:checkCanPick',function(can)
        if can then
            if inProgress then
                return
            end
            local HasItem = exports.ox_inventory:Search('count', Config.ItemRequireName)
            if Config.ItemRequire and HasItem <= 0 then
                QBCore.Functions.Notify('Không có kéo để cắt dừa', 'error', 6000)
                return
            end
            local amount = Config.Reward
            inProgress = true
            FreezeEntityPosition(ped, true)
            if lib.progressBar({
                duration = Config.PickingProgressbarTime,
                label = Languages.ProgressPicking,
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true,
                },
                anim = {
                    dict = 'anim@gangops@facility@servers@',
                    clip = 'hotwire'
                },
            }) then
                exports['monitors']:TriggerProtectedServerEvent('xx_coco:server:addCoconut', data.model, amount, false)
                FreezeEntityPosition(ped, false)
                ClearPedTasks(ped)
                inProgress = false
            else
                FreezeEntityPosition(ped, false)
                inProgress = false
                ClearPedTasks(ped)
                QBCore.Functions.Notify("Đã hủy")
            end
        end
    end, tree)
end)




AddEventHandler('onResourceStop', function(resource) if resource ~= GetCurrentResourceName() then return end
	for k in pairs(Targets) do exports.ox_target:removeZone(k) end
    removeJob()
end)

