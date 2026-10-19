-- Isolated trucker procurement integration. Existing station flows remain in station_sv.lua.
if Config.PlayerOwnedGasStationsEnabled then
    local QBCore = exports['qb-core']:GetCoreObject()
    -- Trucker B2B procurement API. These exports are intentionally restricted to
    -- lr_trucker_job so station balances and reserves cannot be mutated directly.
    local PROCUREMENT_CALLER = 'lr_trucker_job'

    local function IsProcurementCaller()
        return GetInvokingResource() == PROCUREMENT_CALLER
    end

    exports('IsTruckerjobEnabled', function()
        return IsProcurementCaller() and Config.EnableTruckerjob == true
    end)

    local function ProcurementStation(location)
        local loc = math.floor(tonumber(location) or 0)
        if loc < 1 or not Config.GasStations or not Config.GasStations[loc] then return nil end
        return loc, Config.GasStations[loc]
    end

    local function HasProcurementAccess(src, location)
        local Player = QBCore.Functions.GetPlayer(math.floor(tonumber(src) or 0))
        if not Player or not Player.PlayerData then return false end
        local citizenId = tostring(Player.PlayerData.citizenid or '')
        if citizenId == '' then return false end
        local row = MySQL.single.await([[
            SELECT station.owner,
              EXISTS(
                SELECT 1 FROM fuel_station_employees employee
                WHERE employee.location = station.location AND employee.citizenid = ?
              ) AS employee_access
            FROM fuel_stations station
            WHERE station.location = ? AND station.owned = 1
            LIMIT 1
        ]], { citizenId, location })
        return row ~= nil and (
            tostring(row.owner or '') == citizenId or tonumber(row.employee_access) == 1
        )
    end

    exports('GetProcurementStations', function()
        if not IsProcurementCaller() then return {} end
        local stations = {}
        for location, station in ipairs(Config.GasStations or {}) do
            local coords = station.pedcoords
            if coords then
                stations[#stations + 1] = {
                    businessId = 'gas_station_' .. tostring(location),
                    location = location,
                    label = tostring(station.label or ('Trạm xăng #' .. tostring(location))),
                    x = coords.x + 0.0,
                    y = coords.y + 0.0,
                    z = coords.z + 0.0,
                    h = (coords.w or coords.h or 0.0) + 0.0,
                }
            end
        end
        return stations
    end)

    exports('GetProcurementContext', function(request)
        if not IsProcurementCaller() or type(request) ~= 'table' then return nil end
        local location, stationConfig = ProcurementStation(request.location)
        if not location or not HasProcurementAccess(request.source, location) then return nil end
        local row = MySQL.single.await([[
            SELECT label, balance, fuel FROM fuel_stations
            WHERE location = ? AND owned = 1 LIMIT 1
        ]], { location })
        if not row then return nil end
        return {
            location = location,
            label = tostring(row.label or stationConfig.label or ('Trạm xăng #' .. location)),
            balance = math.max(0, math.floor(tonumber(row.balance) or 0)),
            fuel = math.max(0, math.floor(tonumber(row.fuel) or 0)),
            maxFuel = math.max(1, math.floor(tonumber(Config.MaxFuelReserves) or 10000)),
        }
    end)

    exports('DebitProcurementOrder', function(request)
        if not Config.EnableTruckerjob then return false end
        if not IsProcurementCaller() or type(request) ~= 'table' then return false end
        local location = ProcurementStation(request.location)
        local amount = math.floor(tonumber(request.amount) or 0)
        local orderId = tostring(request.orderId or '')
        if not location or amount < 1 or orderId == ''
          or not HasProcurementAccess(request.source, location) then return false end

        -- Reserve the order ID first; debit and mark it paid in one atomic UPDATE.
        MySQL.update.await([[
            INSERT IGNORE INTO fuel_station_procurement_ledger
              (order_id, location, amount) VALUES (?, ?, ?)
        ]], { orderId, location, amount })
        local existing = MySQL.single.await([[
            SELECT location, amount, debited_at, refunded_at
            FROM fuel_station_procurement_ledger WHERE order_id = ? LIMIT 1
        ]], { orderId })
        if not existing or tonumber(existing.location) ~= location
          or tonumber(existing.amount) ~= amount or existing.refunded_at ~= nil then return false end
        if existing.debited_at ~= nil then return true end

        local changed = MySQL.update.await([[
            UPDATE fuel_stations station
            INNER JOIN fuel_station_procurement_ledger ledger
              ON ledger.location = station.location AND ledger.order_id = ?
            SET station.balance = station.balance - ledger.amount,
              ledger.debited_at = CURRENT_TIMESTAMP
            WHERE station.location = ? AND station.owned = 1
              AND station.balance >= ledger.amount
              AND ledger.debited_at IS NULL AND ledger.refunded_at IS NULL
        ]], { orderId, location })
        if tonumber(changed) == 1 then return true end
        local paid = MySQL.single.await([[
            SELECT debited_at, refunded_at FROM fuel_station_procurement_ledger
            WHERE order_id = ? AND location = ? LIMIT 1
        ]], { orderId, location })
        return paid ~= nil and paid.debited_at ~= nil and paid.refunded_at == nil
    end)

    exports('RefundProcurementOrder', function(request)
        if not IsProcurementCaller() or type(request) ~= 'table' then return false end
        local location = ProcurementStation(request.location)
        local orderId = tostring(request.orderId or '')
        if not location or orderId == '' then return false end
        -- An unpaid reservation can be cancelled without changing station money.
        MySQL.update.await([[
            UPDATE fuel_station_procurement_ledger SET refunded_at = CURRENT_TIMESTAMP
            WHERE order_id = ? AND location = ? AND debited_at IS NULL
              AND refunded_at IS NULL AND delivery_id IS NULL
        ]], { orderId, location })
        MySQL.update.await([[
            UPDATE fuel_stations station
            INNER JOIN fuel_station_procurement_ledger ledger
              ON ledger.location = station.location AND ledger.order_id = ?
            SET station.balance = station.balance + ledger.amount,
              ledger.refunded_at = CURRENT_TIMESTAMP
            WHERE station.location = ? AND ledger.debited_at IS NOT NULL
              AND ledger.refunded_at IS NULL AND ledger.delivery_id IS NULL
        ]], { orderId, location })
        local row = MySQL.single.await([[
            SELECT refunded_at FROM fuel_station_procurement_ledger
            WHERE order_id = ? AND location = ? LIMIT 1
        ]], { orderId, location })
        return row ~= nil and row.refunded_at ~= nil
    end)

    exports('CreditProcurementDelivery', function(request)
        if not IsProcurementCaller() or type(request) ~= 'table' then return false, 'UNAUTHORIZED' end
        local location = ProcurementStation(request.location)
        local orderId = tostring(request.orderId or '')
        local deliveryId = tostring(request.deliveryId or '')
        local liters = math.floor(tonumber(request.liters) or 0)
        if not location or orderId == '' or deliveryId == '' or liters < 1 then
            return false, 'INVALID_REQUEST'
        end
        local receipt = MySQL.single.await([[
            SELECT delivery_id, debited_at, refunded_at FROM fuel_station_procurement_ledger
            WHERE order_id = ? AND location = ? LIMIT 1
        ]], { orderId, location })
        if receipt and receipt.debited_at ~= nil and receipt.refunded_at == nil
          and tostring(receipt.delivery_id or '') == deliveryId then return true, '' end
        local changed = MySQL.update.await([[
            UPDATE fuel_stations station
            INNER JOIN fuel_station_procurement_ledger ledger
              ON ledger.location = station.location AND ledger.order_id = ?
            SET station.fuel = station.fuel + ?, ledger.delivery_id = ?,
              ledger.delivered_at = CURRENT_TIMESTAMP
            WHERE station.location = ? AND ledger.debited_at IS NOT NULL
              AND ledger.refunded_at IS NULL
              AND ledger.delivery_id IS NULL AND station.fuel + ? <= ?
        ]], {
            orderId, liters, deliveryId, location, liters,
            math.max(1, math.floor(tonumber(Config.MaxFuelReserves) or 10000)),
        })
        if (tonumber(changed) or 0) > 0 then return true, '' end
        return false, 'STATION_CAPACITY'
    end)

end
