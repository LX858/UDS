local shownGangMenu = false
local DynamicMenuItems = {}

-- ============================================================
-- RESOURCE LOCAL CACHE (QBX CACHE OPTIMIZATION)
-- ============================================================
local PlayerCache = {
    loaded = false,
    data = {},
    citizenid = nil,
    gang = {
        name = 'none',
        label = 'No Affiliation',
        isboss = false,
        grade = { level = 0, name = '' }
    }
}

local function ClearPlayerCache()
    PlayerCache.loaded = false
    PlayerCache.data = {}
    PlayerCache.citizenid = nil
    PlayerCache.gang = {
        name = 'none',
        label = 'No Affiliation',
        isboss = false,
        grade = { level = 0, name = '' }
    }
end

local function RefreshPlayerCache()
    local data = exports.qbx_core and exports.qbx_core:GetPlayerData()
    if not data or not data.citizenid then
        ClearPlayerCache()
        return
    end

    PlayerCache.data = data
    PlayerCache.citizenid = data.citizenid
    PlayerCache.gang = data.gang or {
        name = 'none',
        label = 'No Affiliation',
        isboss = false,
        grade = { level = 0, name = '' }
    }
    PlayerCache.loaded = true
end

-- Event-driven cache management
RegisterNetEvent('qbx_core:client:onPlayerLoaded', function()
    RefreshPlayerCache()
end)

RegisterNetEvent('qbx_core:client:playerLoggedOn', function()
    RefreshPlayerCache()
end)

RegisterNetEvent('qbx_core:client:playerLoggedOff', function()
    ClearPlayerCache()
end)

RegisterNetEvent('qbx_core:client:onSetGang', function(infoGang)
    PlayerCache.gang = infoGang or {
        name = 'none',
        label = 'No Affiliation',
        isboss = false,
        grade = { level = 0, name = '' }
    }
    if PlayerCache.data then
        PlayerCache.data.gang = PlayerCache.gang
    end
end)

-- Backward compatibility events
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    RefreshPlayerCache()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    ClearPlayerCache()
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(infoGang)
    PlayerCache.gang = infoGang or {
        name = 'none',
        label = 'No Affiliation',
        isboss = false,
        grade = { level = 0, name = '' }
    }
    if PlayerCache.data then
        PlayerCache.data.gang = PlayerCache.gang
    end
end)

RegisterNetEvent('QBCore:Client:SetPlayerData', function(val)
    if not val or not val.citizenid then return end
    PlayerCache.data = val
    PlayerCache.citizenid = val.citizenid
    if val.gang then
        PlayerCache.gang = val.gang
    end
    PlayerCache.loaded = true
end)

RegisterNetEvent('qbx_core:client:onGroupUpdate', function()
    RefreshPlayerCache()
end)

-- Safe init on resource start / restart
CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end
    RefreshPlayerCache()
end)

-- Helper cache readers
local function GetPlayerGang()
    return PlayerCache.gang
end

local function GetPlayerCitizenId()
    return PlayerCache.citizenid or (PlayerCache.data and PlayerCache.data.citizenid) or ''
end

local function HasGang()
    RefreshPlayerCache()
    return PlayerCache.loaded and PlayerCache.gang and PlayerCache.gang.name ~= nil and PlayerCache.gang.name ~= "none"
end

local function GetItemLabel(itemName)
    if not itemName then return '' end
    local item = exports.ox_inventory:Items(itemName)
    if not item then
        item = exports.ox_inventory:Items(string.lower(itemName))
    end
    if not item then
        item = exports.ox_inventory:Items(string.upper(itemName))
    end
    return (item and item.label) or itemName
end

local function Notify(message, notifyType, duration)
    exports.qbx_core:Notify(message, notifyType or 'info', duration or 5000)
end

local function comma_valueGang(amount)
    local formatted = tostring(amount or 0)
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then
            break
        end
    end
    return formatted
end

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

local function AddGangMenuItem(data, id)
    local menuID = id or (#DynamicMenuItems + 1)
    DynamicMenuItems[menuID] = deepcopy(data)
    return menuID
end

exports("AddGangMenuItem", AddGangMenuItem)

local function GetNearbyPlayerServerIds(maxDistance)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local nearbyIds = {}
    local nearby = (lib and lib.getNearbyPlayers and lib.getNearbyPlayers(coords, maxDistance or 10.0, false))
    if nearby and #nearby > 0 then
        for _, n in ipairs(nearby) do
            local sId = GetPlayerServerId(n.id or n.player)
            if sId and sId > 0 and sId ~= GetPlayerServerId(PlayerId()) then
                nearbyIds[#nearbyIds + 1] = sId
            end
        end
    else
        for _, player in ipairs(GetActivePlayers()) do
            if player ~= PlayerId() then
                local targetPed = GetPlayerPed(player)
                local targetCoords = GetEntityCoords(targetPed)
                if #(coords - targetCoords) <= (maxDistance or 10.0) then
                    local sId = GetPlayerServerId(player)
                    if sId and sId > 0 then
                        nearbyIds[#nearbyIds + 1] = sId
                    end
                end
            end
        end
    end
    return nearbyIds
end

RegisterNetEvent('xn_gangmenu:client:OpenMenu', function()
    RefreshPlayerCache()
    local currentGang = GetPlayerGang()
    local myCitizenId = GetPlayerCitizenId()

    if HasGang() then
        local gLevel = (currentGang.grade and currentGang.grade.level) or 0
        SendNUIMessage({
            action = "open_menu",
            isboss = currentGang.isboss or false,
            citizenid = myCitizenId,
            gradeLevel = gLevel,
            gangLabel = currentGang.label or currentGang.name,
            gangName = currentGang.name,
        })
        SetNuiFocus(true, true)

        -- 1. Get employees
        lib.callback('xn_gangmenu:server:GetEmployees', false, function(cb)
            for _, v in pairs(cb or {}) do
                SendNUIMessage({
                    action = "tongquan", 
                    player = v,
                    name_pl = v.name_show,
                    work = currentGang
                })
            end
        end, currentGang.name)

        -- 2. Get players nearby using Client-Side Streaming Detection (Zero server thread lag)
        local nearbyServerIds = GetNearbyPlayerServerIds(10.0)
        if #nearbyServerIds > 0 then
            lib.callback('xn_gangmenu:server:GetNearbyPlayersData', false, function(players)
                for _, v in pairs(players or {}) do
                    local pid = exports.qbx_core and exports.qbx_core:GetPlayerPidByServerId(v.sourceplayer)
                    v.pid = pid or v.sourceplayer
                    SendNUIMessage({
                        action = "getplayer", 
                        selectplayer = v,
                    })
                end
            end, nearbyServerIds)
        end

        -- 3. Get gang stats
        lib.callback('xn_gangmenu:getthongbao', false, function(thong_bao, max_member, cap_do, exp, diem_chiemdong, max_exp, so_member, phi_nangcap, logo, quyGang, require_items)
            SendNUIMessage({
                action = "thong_bao", 
                thong_bao = thong_bao,
                max_member = max_member,
                cap_do = cap_do,
                exp = exp,
                diem_chiemdong = diem_chiemdong,
                max_exp = max_exp,
                so_member = so_member,
                phi_nangcap = phi_nangcap,
                logo = logo,
                quy_gang = quyGang,
                require_items = require_items or {},
            })
        end)

        -- 4. Get warehouse resources
        lib.callback('xn_gangmenu:server:GetGangWarehouse', false, function(resources)
            SendNUIMessage({
                action = "get_warehouse",
                resources = resources or {}
            })
        end, currentGang.name)

        -- 5. Get all config (nhiemvu, doiqua, doiitemcash, doiqua_gang)
        lib.callback('xn_gangmenu:getAllConfig', false, function(allConfig)
            if not allConfig then return end
            -- nhiemvu
            for _, v in pairs(allConfig.nhiemvu or {}) do
                SendNUIMessage({
                    action = "get_nhiemvu", 
                    nhiemvu = v,
                    vatpham = GetItemLabel(v.vatpham),
                    img_vp  = v.vatpham
                })
            end
            -- doiqua
            for _, v in pairs(allConfig.doiqua or {}) do
                SendNUIMessage({
                    action = "get_doiqua", 
                    nhiemvu = v,
                    vatpham = GetItemLabel(v.vatpham),
                    img_vp  = v.vatpham
                })
            end
            -- doiitemcash
            for _, v in pairs(allConfig.doiitemcash or {}) do
                SendNUIMessage({
                    action = "get_doiitemcash", 
                    nhiemvu = v,
                    vatpham = v.label or GetItemLabel(v.vatpham),
                    img_vp  = v.vatpham
                })
            end
            -- doiqua_gang
            for _, v in pairs(allConfig.doiqua_gang or {}) do
                SendNUIMessage({
                    action = "getdoiqua_gang", 
                    nhiemvu = v,
                    vatpham = GetItemLabel(v.vatpham),
                    img_vp  = v.vatpham
                })
            end
        end)

        -- 6. Get qua chiem dong
        lib.callback('xn_gangmenu:quachiemdong', false, function(cb)
            local Check_Table = {}
            for _, v in pairs(cb or {}) do
                table.insert(Check_Table, { ['id_nv'] = v.id_nv })
            end 

            local ProductTable = {}
            for k, v in pairs(Config.Qua_ChiemDong or {}) do
                local ten_vp = (v.type == 'item' and GetItemLabel(v.item)) or "Tiền mặt"
                table.insert(ProductTable, {
                    ['id_nv'] = k,
                    ['item'] = v.item,
                    ['sodiem'] = v.sodiem,
                    ['type'] = v.type,
                    ['amount'] = v.amount,
                    ['ten_vp'] = ten_vp
                })
            end

            SendNUIMessage({ action = "quachiemdong", ProductList = ProductTable, Check_PT = Check_Table })
        end)

        -- 7. Get gang welfare (Mốc thành viên đủ thời gian chơi)
        lib.callback('xn_gangmenu:server:GetGangWelfare', false, function(welfareData)
            SendNUIMessage({
                action = "gang_welfare",
                claimed = welfareData and welfareData.claimed or {},
                milestones = welfareData and welfareData.milestones or {},
                qualifiedCount = welfareData and welfareData.qualifiedCount or 0,
                playtimeRequired = welfareData and welfareData.playtimeRequired or 259200,
            })
        end)
        
    else 
        -- Người chơi chưa có gang: kiểm tra đơn đăng ký hiện tại và nạp dữ liệu No-Gang Hub
        lib.callback('xn_gangmenu:server:CheckGangRequest', false, function(reqData)
            lib.callback('xn_gangmenu:topgang', false, function(topGangs)
                SendNUIMessage({
                    action = "open_no_gang",
                    request = reqData,
                    createGangCost = Config.CreateGangCost or 1000000,
                    maxDescriptionWords = Config.MaxDescriptionWords or 100,
                    topGangs = topGangs or {},
                })
            end)
        end)
    end 
    SetNuiFocus(true, true)
end)

-- NUI: Nộp đơn đăng ký tạo gang mới
RegisterNUICallback('submit_gang_request', function(data, cb)
    lib.callback('xn_gangmenu:server:SubmitGangRequest', false, function(response)
        if cb then cb(response or { success = false, message = "Không nhận được phản hồi từ máy chủ!" }) end
    end, data)
end)

-- NUI: Người chơi xác nhận nhận gang sau khi Admin phê duyệt
RegisterNUICallback('claim_approved_gang', function(data, cb)
    lib.callback('xn_gangmenu:server:ClaimApprovedGang', false, function(response)
        if cb then cb(response or { success = false, message = "Lỗi kích hoạt xã đoàn!" }) end
        if response and response.success then
            Citizen.Wait(500)
            RefreshPlayerCache()
            TriggerEvent("xn_gangmenu:client:OpenMenu")
        end
    end)
end)

-- NUI: Người chơi xác nhận nhận lại tiền cọc khi bị từ chối
RegisterNUICallback('claim_refund_gang', function(data, cb)
    lib.callback('xn_gangmenu:server:ClaimRejectedRefund', false, function(response)
        if cb then cb(response or { success = false, message = "Lỗi khi nhận hoàn tiền!" }) end
        if response and response.success then
            Citizen.Wait(300)
            TriggerEvent("xn_gangmenu:client:OpenMenu")
        end
    end)
end)

-- NUI: Admin lấy danh sách đơn pending
RegisterNUICallback('admin_get_requests', function(data, cb)
    lib.callback('xn_gangmenu:server:GetPendingRequests', false, function(response)
        if cb then cb(response) end
    end)
end)

-- NUI: Admin Duyệt Đơn
RegisterNUICallback('admin_approve_request', function(data, cb)
    lib.callback('xn_gangmenu:server:AdminApproveGang', false, function(response)
        if cb then cb(response) end
    end, data)
end)

-- NUI: Admin Từ Chối Đơn
RegisterNUICallback('admin_reject_request', function(data, cb)
    lib.callback('xn_gangmenu:server:AdminRejectGang', false, function(response)
        if cb then cb(response) end
    end, data)
end)

-- Event: Mở giao diện Quản Lý Gang cho Admin (/quanlygang)
RegisterNetEvent('xn_gangmenu:client:OpenAdminManagement', function()
    lib.callback('xn_gangmenu:server:GetPendingRequests', false, function(res)
        if res and res.success then
            SendNUIMessage({
                action = "open_admin_panel",
                requests = res.requests or {},
            })
            SetNuiFocus(true, true)
        else
            Notify(res and res.message or "Lỗi khi tải danh sách đơn đăng ký!", "error")
        end
    end)
end)

-- click xem bxh khi dang co gang
RegisterNUICallback('bxh', function(data, cb)
    SetNuiFocus(true, true)
    lib.callback('xn_gangmenu:topgang', false, function(result)
        for _, v in pairs(result or {}) do
            SendNUIMessage({
                action = "top_gang", 
                gang = v,
                has_gang = 1,
            })
        end
    end)
    if cb then cb('ok') end
end)

RegisterNUICallback('doi_quacd', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent("xn_gang:server:doi_quacd", data.id_nv, data.sodiem, data.item, data.types, data.amount)
    if cb then cb('ok') end
end)

-- Receive realtime point updates from server and forward to NUI
RegisterNetEvent('xn_gangmenu:client:updatePoints', function(data)
    SendNUIMessage({
        action = "update_points",
        success = data.success,
        citizenid = data.citizenid,
        conghien = data.conghien,
        tien_conghien = data.tien_conghien,
        gang_exp = data.gang_exp,
        quyGang = data.quyGang,
        warehouseResources = data.warehouseResources,
    })
end)

RegisterNetEvent('xn_gangmenu:client:newMember', function(data)
    SendNUIMessage({
        action = "new_member",
        member = data,
    })
end)

RegisterNetEvent('xn_gangmenu:client:removeMember', function(citizenid)
    SendNUIMessage({
        action = "remove_member",
        citizenid = citizenid,
    })
end)

RegisterNetEvent('xn_gangmenu:client:levelUp', function(data)
    SendNUIMessage({
        action = "level_up",
        capDo = data.capDo,
        exp = data.exp,
        maxExp = data.maxExp,
        maxMember = data.maxMember,
        phiNangcap = data.phiNangcap,
        quyGang = data.quyGang,
        warehouseResources = data.warehouseResources,
        requireItems = data.requireItems,
    })
end)

-- click xem bxh khi dang co gang
RegisterNUICallback('chiemdong', function(data, cb)
    SetNuiFocus(true, true)
    lib.callback('xn_gangmenu:top_chiemdong', false, function(result)
        for _, v in pairs(result or {}) do
            SendNUIMessage({
                action = "top_chiemdong", 
                gang = v,
                has_gang = 1,
            })
        end
    end)
    if cb then cb('ok') end
end)

RegisterNUICallback('thoatgang', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent("xn_gang:server:thoatgang")
    if cb then cb('ok') end
end)

-- Client action debounce
local lastActionTime = 0
local function CanPerformAction(cooldownMs)
    local now = GetGameTimer()
    if now - lastActionTime < (cooldownMs or 500) then
        return false
    end
    lastActionTime = now
    return true
end

local lastLogoTime = 0

RegisterNUICallback('doicash', function(data, cb)
    if CanPerformAction(1000) then
        TriggerServerEvent("xn_gang:server:doicash", data.cash)
    end
    if cb then cb('ok') end
end)

RegisterNUICallback('doi_qua', function(data, cb)
    if CanPerformAction(1000) then
        TriggerServerEvent("xn_gang:server:doiqua", data.vatpham, data.soluong, data.sodiem)
    end
    if cb then cb('ok') end
end)

RegisterNUICallback('mua_item', function(data, cb)
    if CanPerformAction(1000) then
        TriggerServerEvent("xn_gang:server:mua_item", data.vatpham, data.soluong, data.sodiem)
    end
    if cb then cb('ok') end
end)

RegisterNUICallback('doi_qua_gang', function(data, cb)
    if CanPerformAction(1000) then
        TriggerServerEvent("xn_gang:server:doiquagang", data.vatpham, data.soluong, data.sodiem)
    end
    if cb then cb('ok') end
end)

RegisterNUICallback('doi_item', function(data, cb)
    if CanPerformAction(1000) then
        TriggerServerEvent("xn_gang:server:doidiem", data.vatpham, data.soluong, data.sodiem)
    end
    if cb then cb('ok') end
end)

RegisterNUICallback('logo', function(data, cb)
    SetNuiFocus(false, false)
    local now = GetGameTimer()
    if now - lastLogoTime >= 30000 then
        lastLogoTime = now
        TriggerServerEvent("xn_gang:server:update_logo", data.logo)
    else
        Notify("Bạn cần đợi 30 giây trước khi đổi logo mới", 'error')
    end
    if cb then cb('ok') end
end)

RegisterNUICallback('upcap_gang', function(data, cb)
    TriggerServerEvent("xn_gang:server:update_cap_do")
    if cb then cb('ok') end
end)

RegisterNUICallback('tat', function(data, cb)
    SetNuiFocus(false, false)
    if cb then cb('ok') end
end)

RegisterNUICallback('khaitru', function(data, cb)
    TriggerServerEvent("xn_gangmenu:server:FireMember", data.citizent_id)
    if cb then cb('ok') end
end)

RegisterNUICallback('quanly', function(data, cb)
    SetNuiFocus(true, true)
    local allGangs = exports.qbx_core:GetGangs()
    if data and data.dt_work and allGangs and allGangs[data.dt_work] and allGangs[data.dt_work].grades then
        for k, v in pairs(allGangs[data.dt_work].grades) do
            SendNUIMessage({
                action = "quanly", 
                cid = data.empSource,
                grade = tonumber(k),
                gradename = v.name
            })
        end
    end
    if cb then cb('ok') end
end)

RegisterNUICallback('motagang', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent("xn_gangmenu:server:motagang", data.noi_dung)
    if cb then cb('ok') end
end)

RegisterNUICallback('themthanhvien', function(data, cb)
    TriggerServerEvent("xn_gangmenu:server:HireMember", tonumber(data.id_member))
    if cb then cb('ok') end
end)

RegisterNUICallback('chucvu', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent("xn_gangmenu:server:GradeUpdate", tonumber(data.id_chucvu), data.id_work, data.id_empSource)
    if cb then cb('ok') end
end)

RegisterNUICallback('claim_gang_welfare', function(data, cb)
    lib.callback('xn_gangmenu:server:ClaimGangWelfare', false, function(response)
        if cb then cb(response or { success = false, message = "Không nhận được phản hồi từ server!" }) end
    end, tonumber(data.milestoneId))
end)

RegisterNetEvent('xn_gangmenu:client:SocietyMenu', function()
    local currentGang = GetPlayerGang()
    lib.callback('xn_gangmenu:server:GetAccount', false, function(cb)
        local SocietyMenu = {
            {
                header = Lang:t("bodygang.balance").. comma_valueGang(cb) .. " - " .. string.upper(currentGang.label or currentGang.name or 'XÃ ĐOÀN'),
                isMenuHeader = true,
                icon = "fa-solid fa-circle-info",
            },
            {
                header = Lang:t("bodygang.deposit"),
                icon = "fa-solid fa-money-bill-transfer",
                txt = Lang:t("bodygang.depositd"),
                params = {
                    event = "xn_gangmenu:client:SocietyDeposit",
                    args = comma_valueGang(cb)
                }
            },
            {
                header = Lang:t("bodygang.withdraw"),
                icon = "fa-solid fa-money-bill-transfer",
                txt = Lang:t("bodygang.withdrawd"),
                params = {
                    event = "xn_gangmenu:client:SocietyWithdraw",
                    args = comma_valueGang(cb)
                }
            },
            {
                header = Lang:t("bodygang.return"),
                icon = "fa-solid fa-angle-left",
                params = {
                    event = "xn_gangmenu:client:OpenMenu",
                }
            },
        }
        exports['qb-menu']:openMenu(SocietyMenu)
    end, currentGang.name)
end)

RegisterNetEvent('xn_gangmenu:client:SocietyDeposit', function(saldoattuale)
    local deposit = exports['qb-input']:ShowInput({
        header = Lang:t("bodygang.depositm").. saldoattuale,
        submitText = Lang:t("bodygang.submit"),
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'amount',
                text = Lang:t("bodygang.amount")
            }
        }
    })
    if deposit then
        if not deposit.amount then return end
        TriggerServerEvent("xn_gangmenu:server:depositMoney", tonumber(deposit.amount))
    end
end)

RegisterNetEvent('xn_gangmenu:client:SocietyWithdraw', function(saldoattuale)
    local withdraw = exports['qb-input']:ShowInput({
        header = Lang:t("bodygang.withdrawm").. saldoattuale,
        submitText = Lang:t("bodygang.submit"),
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'amount',
                text = Lang:t("bodygang.amount")
            }
        }
    })
    if withdraw then
        if not withdraw.amount then return end
        TriggerServerEvent("xn_gangmenu:server:withdrawMoney", tonumber(withdraw.amount))
    end
end)

-- ============================================================
-- TARGET LOCATIONS SETUP (OX_TARGET / QB-TARGET)
-- ============================================================
local CreatedTargetZones = {}

local function InitTargetLocations()
    if not Config.TargetLocations or #Config.TargetLocations == 0 then return end

    for i, loc in ipairs(Config.TargetLocations) do
        local coords = loc.coords
        local radius = loc.radius or 1.5
        local label = loc.label or 'Mở Quản Lý Xã Đoàn'
        local icon = loc.icon or 'fa-solid fa-users'

        if GetResourceState('ox_target') == 'started' then
            local zoneId = exports.ox_target:addSphereZone({
                coords = coords,
                radius = radius,
                debug = false,
                options = {
                    {
                        name = 'xn_gangmenu_target_' .. i,
                        icon = icon,
                        label = label,
                        onSelect = function()
                            TriggerEvent('xn_gangmenu:client:OpenMenu')
                        end,
                        distance = 2.5
                    }
                }
            })
            CreatedTargetZones[#CreatedTargetZones + 1] = { type = 'ox_target', id = zoneId }
        elseif GetResourceState('qb-target') == 'started' then
            local zoneName = 'xn_gangmenu_zone_' .. i
            exports['qb-target']:AddCircleZone(zoneName, coords, radius, {
                name = zoneName,
                debugPoly = false,
            }, {
                options = {
                    {
                        type = 'client',
                        event = 'xn_gangmenu:client:OpenMenu',
                        icon = icon,
                        label = label,
                    },
                },
                distance = 2.5
            })
            CreatedTargetZones[#CreatedTargetZones + 1] = { type = 'qb-target', name = zoneName }
        end
    end
end

CreateThread(function()
    InitTargetLocations()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, z in ipairs(CreatedTargetZones) do
        if z.type == 'ox_target' and exports.ox_target and exports.ox_target.removeZone then
            exports.ox_target:removeZone(z.id)
        elseif z.type == 'qb-target' and exports['qb-target'] and exports['qb-target'].RemoveZone then
            exports['qb-target']:RemoveZone(z.name)
        end
    end
end)
