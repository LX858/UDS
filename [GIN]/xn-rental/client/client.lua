local DrawMarker                  = DrawMarker
local IsEntityDead                = IsEntityDead
local IsControlJustPressed        = IsControlJustPressed
local AddBlipForCoord             = AddBlipForCoord
local SetBlipSprite               = SetBlipSprite
local SetBlipDisplay              = SetBlipDisplay
local SetBlipScale                = SetBlipScale
local SetBlipColour               = SetBlipColour
local SetBlipAsShortRange         = SetBlipAsShortRange
local BeginTextCommandSetBlipName = BeginTextCommandSetBlipName
local AddTextComponentString      = AddTextComponentString
local EndTextCommandSetBlipName   = EndTextCommandSetBlipName
local positions                   = {}

local function onEnter(self)
    if Config.Target then
        if not self.ped then
            local ped = utils.createPed(self.rental.pedModel, self.rental.pos)

            exports.ox_target:addLocalEntity(ped, {
                {
                    name = "rental_ped" .. ped,
                    label = "Thuê phương tiện",
                    icon = 'fa-solid fa-car',
                    onSelect = function(entity)
                        openRentalMenu(self.rental)
                    end
                }
            })

            self.ped = ped
        end
    else
        if not self.ped then
        local ped = utils.createPed(self.rental.pedModel, vector4(self.rental.pos.x, self.rental.pos.y - 0.05, self.rental.pos.z - 2.0, self.rental.pos.w))

        lib.showTextUI('[E] - Thuê xe / Gọi taxi',
        {
            position = "top-center",
            icon = 'hand',
            style = { borderRadius = 0, backgroundColor = '#3a4d57', color = 'white' }
        })
        
        self.ped = ped
        end
    end
end

local function onExit(self)
    lib.hideTextUI()

    if self.ped then
        DeletePed(self.ped)
        self.ped = nil
    end
end

local function onNearby(self)
    if not Config.Target then
        DrawMarker(21, self.coords.x, self.coords.y, self.coords.z - 1, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.6, 0.6, 0.6, 58,
            77, 87, 200, false, true, 2, nil, nil, false)
        
        -- Vẽ marker trên đầu ped
        if self.ped and DoesEntityExist(self.ped) then
            local pedCoords = GetEntityCoords(self.ped)
            DrawMarker(0, pedCoords.x, pedCoords.y, pedCoords.z + 1.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 255, 0, 200, true, true, 2, nil, nil, false)
            
            -- Text [E] bên cạnh marker
            local onScreen, screenX, screenY = World3dToScreen2d(pedCoords.x, pedCoords.y, pedCoords.z + 2.0)
            if onScreen then
                SetTextScale(0.35, 0.35)
                SetTextFont(4)
                SetTextProportional(1)
                SetTextColour(255, 255, 255, 215)
                SetTextOutline()
                SetTextEntry("STRING")
                SetTextCentre(1)
                AddTextComponentString("[E] Thuê xe")
                DrawText(screenX, screenY)
            end
        end
    end

    if self.currentDistance < 2 and not IsEntityDead(cache.ped) and IsControlJustPressed(0, 38) then
        openRentalMenu(self.rental)
    end
end

local function initRentals()
    if next(positions) then return end

    for i = 1, #Config.Rentals do
        local cfg = Config.Rentals[i]

        if cfg.blip.enable then
            local blip = AddBlipForCoord(cfg.pos.xy)
            SetBlipSprite(blip, cfg.blip.type)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, cfg.blip.scale)
            SetBlipColour(blip, cfg.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(cfg.blip.name)
            EndTextCommandSetBlipName(blip)
        end

        positions[i] = lib.points.new({
            coords = cfg.pos.xyz,
            distance = Config.Target and 60 or 15,
            rental = cfg,
            onEnter = onEnter,
            onExit = onExit,
            nearby = onNearby
        })
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    initRentals()
end)

CreateThread(function()
    Wait(500)
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.isLoggedIn then
        initRentals()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for i = 1, #positions do
        local point = positions[i]
        if point and point.ped then
            DeletePed(point.ped)
        end
    end
end)


