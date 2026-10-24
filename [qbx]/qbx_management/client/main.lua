local config = require 'config.client'
local JOBS = exports.qbx_core:GetJobs()
local GANGS = exports.qbx_core:GetGangs()
local isLoggedIn = LocalPlayer.state.isLoggedIn
local dynamicMenuItems = {}

-- Adds item to the boss/gang menu.
---@param menuItem ContextMenuItem Requires args.type to be set to know which menu to place in.
---@return number? menuId ID of the menu item added
local function addMenuItem(menuItem)
    local menuId = #dynamicMenuItems + 1
    if not menuItem.args.type then return end
    dynamicMenuItems[menuId] = lib.table.deepclone(menuItem)
    return menuId
end
exports('AddBossMenuItem', addMenuItem)
exports('AddGangMenuItem', addMenuItem)

-- Remove menu item at particular id
---@param id number Menu ID to remove
local function removeMenuItem(id)
    dynamicMenuItems[id] = nil
end
exports('RemoveBossMenuItem', removeMenuItem)
exports('RemoveGangMenuItem', removeMenuItem)

-- Finds nearby players and returns a table of server ids
---@return table
local function findPlayers()
    local coords = GetEntityCoords(cache.ped)
    local closePlayers = lib.getNearbyPlayers(coords, 10, false)
    for _, v in pairs(closePlayers) do
        v.id = GetPlayerServerId(v.id)
    end
    return lib.callback.await('qbx_management:server:getPlayers', false, closePlayers)
end

-- Presents a menu to manage a specific employee including changing grade or firing them
---@param player table Player data for managing a specific employee
---@param groupName string Name of job/gang of employee being managed
---@param groupType GroupType
local function manageEmployee(player, groupName, groupType)
    local employeeMenu = {}
    local employeeLoop = groupType == 'gang' and GANGS[groupName].grades or JOBS[groupName].grades
    for groupGrade, gradeTitle in pairs(employeeLoop) do
        employeeMenu[#employeeMenu + 1] = {
            title = gradeTitle.name,
            description = locale('menu.grade')..groupGrade,
            onSelect = function()
                lib.callback.await('qbx_management:server:updateGrade', false, player.cid, player.grade, tonumber(groupGrade), groupType)
                OpenBossMenu(groupType)
            end,
        }
    end

    table.sort(employeeMenu, function(a, b)
        return a.description < b.description
    end)

    local isCooldownJob = groupType == 'job' and (groupName == 'police' or groupName == 'ambulance')

    employeeMenu[#employeeMenu + 1] = {
        title = groupType == 'gang' and locale('menu.expel_gang') or locale('menu.fire_employee'),
        icon = 'user-large-slash',
        onSelect = function()
            if isCooldownJob then
                lib.registerContext({
                    id = 'fireChoiceMenu',
                    title = locale('cooldown.fire_options') .. ': ' .. player.name,
                    menu = 'memberMenu',
                    options = {
                        {
                            title = locale('cooldown.resignation'),
                            description = locale('cooldown.resignation_desc'),
                            icon = 'user-minus',
                            onSelect = function()
                                local alert = lib.alertDialog({
                                    header = locale('cooldown.confirm_resignation_title'),
                                    content = locale('cooldown.confirm_resignation_content', player.name),
                                    centered = true,
                                    cancel = true,
                                    labels = {
                                        cancel = locale('cooldown.cancel'),
                                        confirm = locale('cooldown.confirm')
                                    }
                                })
                                if alert == 'confirm' then
                                    lib.callback.await('qbx_management:server:fireEmployeeWithCooldown', false, player.cid, groupType, 'resignation', nil)
                                    OpenBossMenu(groupType)
                                end
                            end,
                        },
                        {
                            title = locale('cooldown.blacklist'),
                            description = locale('cooldown.blacklist_desc'),
                            icon = 'ban',
                            onSelect = function()
                                local input = lib.inputDialog(locale('cooldown.reason_title'), {
                                    {
                                        type = 'input',
                                        label = locale('cooldown.reason_label'),
                                        placeholder = locale('cooldown.reason_placeholder'),
                                        required = true,
                                    }
                                })
                                if not input or not input[1] or input[1] == '' then
                                    return
                                end
                                local reason = input[1]
                                local alert = lib.alertDialog({
                                    header = locale('cooldown.confirm_blacklist_title'),
                                    content = locale('cooldown.confirm_blacklist_content', player.name, reason),
                                    centered = true,
                                    cancel = true,
                                    labels = {
                                        cancel = locale('cooldown.cancel'),
                                        confirm = locale('cooldown.confirm')
                                    }
                                })
                                if alert == 'confirm' then
                                    lib.callback.await('qbx_management:server:fireEmployeeWithCooldown', false, player.cid, groupType, 'blacklist', reason)
                                    OpenBossMenu(groupType)
                                end
                            end,
                        }
                    }
                })
                lib.showContext('fireChoiceMenu')
            else
                lib.callback.await('qbx_management:server:fireEmployee', false, player.cid, groupType)
                OpenBossMenu(groupType)
            end
        end,
    }


    lib.registerContext({
        id = 'memberMenu',
        title = player.name,
        menu = 'memberListMenu',
        options = employeeMenu,
    })

    lib.showContext('memberMenu')
end

-- Presents a menu of employees the work for a job or gang.
-- Allows selection of an employee to perform further actions
---@param groupType GroupType
local function employeeList(groupType)
    local employeesMenu = {}
    local groupName = QBX.PlayerData[groupType].name
    local employees = lib.callback.await('qbx_management:server:getEmployees', false, groupName, groupType)
    for _, employee in pairs(employees) do
        local employeesData = {
            title = employee.name,
            description = groupType == 'job' and JOBS[groupName].grades[employee.grade].name or GANGS[groupName].grades[employee.grade].name,
            onSelect = function()
                manageEmployee(employee, groupName, groupType)
            end,
        }
        if employee.hours and employee.last_checkin then
            employeesData.metadata = {
                { label = locale('menu.employee_status'), value = employee.onduty and locale('menu.on_duty') or locale('menu.off_duty') },
                { label = locale('menu.hours_in_days'), value = employee.hours },
                { label = locale('menu.last_checkin'), value = employee.last_checkin },
            }
        end
        employeesMenu[#employeesMenu + 1] = employeesData
    end

    lib.registerContext({
        id = 'memberListMenu',
        title = groupType == 'gang' and locale('menu.manage_gang') or locale('menu.manage_employees'),
        menu = 'openBossMenu',
        options = employeesMenu,
    })

    lib.showContext('memberListMenu')
end

-- Presents a list of possible employees to hire for a job or gang.
---@param groupType GroupType
local function showHireMenu(groupType)
    local hireMenu = {}
    local players = findPlayers()
    local hireName = QBX.PlayerData[groupType].name
    for _, player in pairs(players) do
        if player[groupType].name ~= hireName then
            hireMenu[#hireMenu + 1] = {
                title = player.name,
                description = locale('menu.citizen_id')..player.citizenid..' - '..locale('menu.id')..player.source,
                onSelect = function()
                    lib.callback.await('qbx_management:server:hireEmployee', false, player.source, groupType)
                    OpenBossMenu(groupType)
                end,
            }
        end
    end

    lib.registerContext({
        id = 'hireMenu',
        title = groupType == 'gang' and locale('menu.hire_gang') or locale('menu.hire_civilians'),
        menu = 'openBossMenu',
        options = hireMenu,
    })

    lib.showContext('hireMenu')
end

local function showIdentityChangeMenu(groupType, targetPlayer)
    local currentLevel = tonumber(targetPlayer.dinhdanh) or 1
    local hasIdCard = targetPlayer.hasIdCard == true

    local options = {
        {
            title = '📋 Thông tin hiện tại',
            description = string.format("Người chơi: %s\nID: %d | CitizenID: %s\nCấp định danh: Cấp %d\nThẻ ID Card: %s", targetPlayer.name, targetPlayer.source, targetPlayer.citizenid, currentLevel, hasIdCard and "Có mang theo" or "❌ Không có"),
            icon = 'info-circle'
        },
        {
            title = currentLevel == 1 and (hasIdCard and '⭐ Nâng cấp lên Cấp 2' or '🚫 Nâng cấp lên Cấp 2 (Thiếu Thẻ ID)') or '✅ Cấp 2 (Hiện tại)',
            description = (not hasIdCard and currentLevel == 1) and '⚠️ Yêu cầu người chơi phải có Thẻ Định Danh (id_card) trong túi đồ!' or 'Thiết lập cấp định danh của người chơi này thành Cấp 2 (Max: 2)',
            icon = 'circle-up',
            iconColor = (currentLevel == 1 and hasIdCard) and '#2ecc71' or '#7f8c8d',
            disabled = (currentLevel == 2) or (not hasIdCard),
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Xác nhận Nâng Cấp Định Danh',
                    content = string.format("Bạn có chắc chắn muốn nâng cấp định danh cho **%s** (ID: %d) lên **Cấp 2**?", targetPlayer.name, targetPlayer.source),
                    centered = true,
                    cancel = true,
                    labels = { cancel = 'Hủy', confirm = 'Xác nhận' }
                })
                if confirm == 'confirm' then
                    local success = lib.callback.await('qbx_management:server:setIdentityLevel', false, targetPlayer.source, 2)
                    if success then
                        showIdentityNearbyPlayersMenu(groupType)
                    end
                end
            end
        },
        {
            title = currentLevel == 2 and (hasIdCard and '🔻 Hạ cấp xuống Cấp 1' or '🚫 Hạ cấp xuống Cấp 1 (Thiếu Thẻ ID)') or '✅ Cấp 1 (Hiện tại)',
            description = (not hasIdCard and currentLevel == 2) and '⚠️ Yêu cầu người chơi phải có Thẻ Định Danh (id_card) trong túi đồ!' or 'Thiết lập cấp định danh của người chơi này thành Cấp 1 (Min: 1)',
            icon = 'circle-down',
            iconColor = (currentLevel == 2 and hasIdCard) and '#e74c3c' or '#7f8c8d',
            disabled = (currentLevel == 1) or (not hasIdCard),
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Xác nhận Hạ Cấp Định Danh',
                    content = string.format("Bạn có chắc chắn muốn hạ cấp định danh cho **%s** (ID: %d) xuống **Cấp 1**?", targetPlayer.name, targetPlayer.source),
                    centered = true,
                    cancel = true,
                    labels = { cancel = 'Hủy', confirm = 'Xác nhận' }
                })
                if confirm == 'confirm' then
                    local success = lib.callback.await('qbx_management:server:setIdentityLevel', false, targetPlayer.source, 1)
                    if success then
                        showIdentityNearbyPlayersMenu(groupType)
                    end
                end
            end
        },
        {
            title = '📇 Thu hồi Thẻ Định Danh (ID Card)',
            description = hasIdCard and 'Tịch thu và xóa vật phẩm Thẻ Định Danh khỏi túi đồ của người chơi' or '⚠️ Người chơi không có Thẻ Định Danh (id_card) trong túi đồ',
            icon = 'id-card',
            iconColor = hasIdCard and '#e74c3c' or '#7f8c8d',
            disabled = not hasIdCard,
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Xác nhận Thu Hồi Thẻ Định Danh',
                    content = string.format("Bạn có chắc chắn muốn thu hồi và xóa Thẻ Định Danh (ID Card) của **%s** (ID: %d)?", targetPlayer.name, targetPlayer.source),
                    centered = true,
                    cancel = true,
                    labels = { cancel = 'Hủy', confirm = 'Xác nhận thu hồi' }
                })
                if confirm == 'confirm' then
                    local success = lib.callback.await('qbx_management:server:revokeIdentityCard', false, targetPlayer.source)
                    if success then
                        showIdentityNearbyPlayersMenu(groupType)
                    end
                end
            end
        }
    }

    lib.registerContext({
        id = 'identityChangeMenu_' .. targetPlayer.source,
        title = 'ĐỊNH DANH: ' .. targetPlayer.name,
        menu = 'identityNearbyPlayersMenu',
        options = options
    })

    lib.showContext('identityChangeMenu_' .. targetPlayer.source)
end

function showIdentityNearbyPlayersMenu(groupType)
    if groupType ~= 'job' or QBX.PlayerData.job.name ~= 'police' then return end
    local players = findPlayers()
    if not players or #players == 0 then
        lib.notify({ title = 'Thông báo', description = 'Không tìm thấy người chơi nào ở gần!', type = 'inform' })
        OpenBossMenu(groupType)
        return
    end

    local options = {}
    for _, player in pairs(players) do
        local currentLevel = tonumber(player.dinhdanh) or 1
        local hasIdCard = player.hasIdCard == true

        options[#options + 1] = {
            title = player.name,
            description = string.format("Mã công dân: %s | ID: %d | Định danh: Cấp %d | %s", player.citizenid, player.source, currentLevel, hasIdCard and "📇 Có Thẻ ID" or "⚠️ Thiếu Thẻ ID"),
            icon = 'user',
            iconColor = hasIdCard and '#2ecc71' or '#e74c3c',
            onSelect = function()
                showIdentityChangeMenu(groupType, player)
            end
        }
    end

    lib.registerContext({
        id = 'identityNearbyPlayersMenu',
        title = 'NÂNG / HẠ CẤP & THU HỒI ĐỊNH DANH',
        menu = 'openBossMenu',
        options = options
    })

    lib.showContext('identityNearbyPlayersMenu')
end

function showIdentityMainMenu(groupType)
    showIdentityNearbyPlayersMenu(groupType)
end

local function showWeaponLicenseActionMenu(groupType, targetPlayer)
    local currentLevel = tonumber(targetPlayer.dinhdanh) or 1
    local hasIdCard = targetPlayer.hasIdCard == true
    local canGrant = (currentLevel == 2 and hasIdCard)

    local statusText = "❌ (Yêu cầu Định danh Cấp 2)"
    local titleText = '🚫 Cấp Giấy phép vũ khí (Yêu cầu Cấp 2)'
    local descText = '⚠️ Người chơi chưa hoàn thành Định danh Cấp 2!'

    if currentLevel == 2 then
        if hasIdCard then
            statusText = "✅ (Đủ điều kiện cấp)"
            titleText = '🔫 Cấp Giấy phép vũ khí'
            descText = 'Cấp vật phẩm Giấy phép vũ khí cho người chơi này'
        else
            statusText = "❌ (Thiếu Thẻ Định Danh id_card)"
            titleText = '🚫 Cấp Giấy phép vũ khí (Thiếu Thẻ ID)'
            descText = '⚠️ Người chơi không mang Thẻ Định Danh (id_card) trong túi đồ!'
        end
    end

    local options = {
        {
            title = '📋 Thông tin người chơi',
            description = string.format("Người chơi: %s\nID: %d | CitizenID: %s\nĐịnh danh: Cấp %d\nThẻ ID Card: %s\nTrạng thái: %s", targetPlayer.name, targetPlayer.source, targetPlayer.citizenid, currentLevel, hasIdCard and "Có mang theo" or "Không có", statusText),
            icon = 'info-circle'
        },
        {
            title = titleText,
            description = descText,
            icon = 'gun',
            iconColor = canGrant and '#2ecc71' or '#e74c3c',
            disabled = not canGrant,
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Xác nhận Cấp Giấy Phép Vũ Khí',
                    content = string.format("Bạn có chắc chắn muốn cấp Giấy Phép Vũ Khí cho **%s** (ID: %d)?", targetPlayer.name, targetPlayer.source),
                    centered = true,
                    cancel = true,
                    labels = { cancel = 'Hủy', confirm = 'Xác nhận cấp' }
                })
                if confirm == 'confirm' then
                    local success = lib.callback.await('qbx_management:server:grantWeaponLicense', false, targetPlayer.source)
                    if success then
                        showWeaponLicenseNearbyPlayersMenu(groupType)
                    end
                end
            end
        },
        {
            title = '🚫 Thu hồi Giấy phép vũ khí',
            description = 'Tịch thu và xóa vật phẩm Giấy phép vũ khí khỏi người chơi',
            icon = 'trash-can',
            iconColor = '#e74c3c',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Xác nhận Thu Hồi Giấy Phép Vũ Khí',
                    content = string.format("Bạn có chắc chắn muốn thu hồi Giấy Phép Vũ Khí của **%s** (ID: %d)?", targetPlayer.name, targetPlayer.source),
                    centered = true,
                    cancel = true,
                    labels = { cancel = 'Hủy', confirm = 'Xác nhận thu hồi' }
                })
                if confirm == 'confirm' then
                    local success = lib.callback.await('qbx_management:server:revokeWeaponLicense', false, targetPlayer.source)
                    if success then
                        showWeaponLicenseNearbyPlayersMenu(groupType)
                    end
                end
            end
        }
    }

    lib.registerContext({
        id = 'weaponLicenseActionMenu_' .. targetPlayer.source,
        title = 'VŨ KHÍ: ' .. targetPlayer.name,
        menu = 'weaponLicenseNearbyPlayersMenu',
        options = options
    })

    lib.showContext('weaponLicenseActionMenu_' .. targetPlayer.source)
end

function showWeaponLicenseNearbyPlayersMenu(groupType)
    if groupType ~= 'job' or QBX.PlayerData.job.name ~= 'police' then return end
    local players = findPlayers()
    if not players or #players == 0 then
        lib.notify({ title = 'Thông báo', description = 'Không tìm thấy người chơi nào ở gần!', type = 'inform' })
        OpenBossMenu(groupType)
        return
    end

    local options = {}
    for _, player in pairs(players) do
        local currentLevel = tonumber(player.dinhdanh) or 1
        local hasIdCard = player.hasIdCard == true
        local canGrant = (currentLevel == 2 and hasIdCard)

        local statusDesc = string.format("Mã công dân: %s | ID: %d | Định danh: Cấp %d (Chưa đủ Cấp 2)", player.citizenid, player.source, currentLevel)
        if currentLevel == 2 then
            if hasIdCard then
                statusDesc = string.format("Mã công dân: %s | ID: %d | Định danh: Cấp 2 | 📇 Có Thẻ ID", player.citizenid, player.source)
            else
                statusDesc = string.format("Mã công dân: %s | ID: %d | Định danh: Cấp 2 | ⚠️ Thiếu Thẻ ID", player.citizenid, player.source)
            end
        end

        options[#options + 1] = {
            title = player.name,
            description = statusDesc,
            icon = 'user',
            iconColor = canGrant and '#2ecc71' or '#e74c3c',
            onSelect = function()
                showWeaponLicenseActionMenu(groupType, player)
            end
        }
    end

    lib.registerContext({
        id = 'weaponLicenseNearbyPlayersMenu',
        title = 'CẤP GIẤY PHÉP VŨ KHÍ',
        menu = 'openBossMenu',
        options = options
    })

    lib.showContext('weaponLicenseNearbyPlayersMenu')
end

-- Opens main boss menu changing function based on the group provided.
---@param groupType GroupType
function OpenBossMenu(groupType)
    if groupType ~= 'gang' and groupType ~= 'job' or not QBX.PlayerData[groupType].name or not QBX.PlayerData[groupType].isboss then return end

    local bossMenu = {
        {
            title = groupType == 'gang' and locale('menu.manage_gang') or locale('menu.manage_employees'),
            description = groupType == 'gang' and locale('menu.check_gang') or locale('menu.check_employee'),
            icon = 'list',
            onSelect = function()
                employeeList(groupType)
            end,
        },
        {
            title = groupType == 'gang' and locale('menu.hire_members') or locale('menu.hire_employees'),
            description = groupType == 'gang' and locale('menu.hire_gang') or locale('menu.hire_civilians'),
            icon = 'hand-holding',
            onSelect = function()
                showHireMenu(groupType)
            end,
        },
    }

    if groupType == 'job' and QBX.PlayerData.job.name == 'police' then
        bossMenu[#bossMenu + 1] = {
            title = 'Cấp định danh',
            description = 'Quản lý, Nâng/hạ cấp và Thu hồi định danh cho người chơi ở gần',
            icon = 'id-card',
            onSelect = function()
                showIdentityNearbyPlayersMenu(groupType)
            end,
        }
        bossMenu[#bossMenu + 1] = {
            title = 'Cấp giấy phép vũ khí',
            description = 'Cấp giấy phép vũ khí cho người chơi định danh Cấp 2 ở gần',
            icon = 'shield-halved',
            onSelect = function()
                showWeaponLicenseNearbyPlayersMenu(groupType)
            end,
        }
    end



    for _, menuItem in pairs(dynamicMenuItems) do
        if string.lower(menuItem.args.type) == groupType then
            bossMenu[#bossMenu + 1] = menuItem
        end
    end

    lib.registerContext({
        id = 'openBossMenu',
        title = groupType == 'gang' and string.upper(QBX.PlayerData.gang.label) or string.upper(QBX.PlayerData.job.label),
        options = bossMenu,
    })

    lib.showContext('openBossMenu')
end

exports('OpenBossMenu', OpenBossMenu)

local zoneIndex = 0
local function createZone(zoneInfo)
    zoneIndex = zoneIndex + 1
    if config.useTarget then
        exports.ox_target:addBoxZone({
            coords = zoneInfo.coords,
            size = zoneInfo.size or vec3(1.5, 1.5, 1.5),
            rotation = zoneInfo.rotation or 0.0,
            debug = config.debugPoly,
            options = {
                {
                    name = zoneInfo.name or (zoneInfo.groupName..'_menu_'..zoneIndex),
                    icon = 'right-to-bracket',
                    label = zoneInfo.type == 'gang' and locale('menu.gang_menu') or locale('menu.boss_menu'),
                    canInteract = function()
                        return zoneInfo.groupName == QBX.PlayerData[zoneInfo.type].name and QBX.PlayerData[zoneInfo.type].isboss
                    end,
                    onSelect = function()
                        OpenBossMenu(zoneInfo.type)
                    end
                }
            }
        })
    else
        lib.zones.box({
            coords = zoneInfo.coords,
            size = zoneInfo.size or vec3(1.5, 1.5, 1.5),
            rotation = zoneInfo.rotation or 0.0,
            debug = config.debugPoly,
            onEnter = function()
                if zoneInfo.groupName == QBX.PlayerData[zoneInfo.type].name and QBX.PlayerData[zoneInfo.type].isboss then
                    lib.showTextUI(zoneInfo.type == 'gang' and locale('menu.gang_management') or locale('menu.boss_management'))
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            inside = function()
                if IsControlJustPressed(0, 51) then -- E
                    if zoneInfo.groupName == QBX.PlayerData[zoneInfo.type].name and QBX.PlayerData[zoneInfo.type].isboss then
                        OpenBossMenu(zoneInfo.type)
                        lib.hideTextUI()
                    end
                end
            end
        })
    end
end

local function initZones()
    local menus
    for i = 1, 5 do
        local success, result = pcall(function()
            return lib.callback.await('qbx_management:server:getBossMenus', false)
        end)
        if success and result then
            menus = result
            break
        end
        Wait(500)
    end
    if not menus then return end
    for _, menuInfo in pairs(menus) do
        createZone(menuInfo)
    end
end

RegisterNetEvent('qbx_management:client:bossMenuRegistered', function(menuInfo)
    createZone(menuInfo)
end)

if GetConvar('qbx:enablebridge', 'true') == 'true' then
    RegisterNetEvent('qb-bossmenu:client:OpenMenu', function()
        OpenBossMenu('job')
    end)
    RegisterNetEvent('qb-gangmenu:client:OpenMenu', function()
        OpenBossMenu('gang')
    end)
end

AddEventHandler('onClientResourceStart', function(resource)
    if cache.resource ~= resource then return end
    initZones()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
end)

CreateThread(function()
    if not isLoggedIn then return end
end)

local function openAdminCooldownMenu()
    local cooldowns = lib.callback.await('qbx_management:server:getAdminCooldownList', false)
    if not cooldowns or #cooldowns == 0 then
        lib.notify({ title = 'Thông báo', description = 'Hiện không có người chơi nào đang bị Countdown!', type = 'inform' })
        return
    end

    local menuOptions = {}

    for i = 1, #cooldowns do
        local item = cooldowns[i]
        local fireTypeLabel = item.fire_type == 'blacklist' and '⛔ Đình chỉ (Blacklist)' or '📋 Nghỉ việc (Thông thường)'
        local timeRemainingStr = string.format("%d ngày %d giờ %d phút", item.daysLeft, item.hoursLeft, item.minsLeft)

        menuOptions[#menuOptions + 1] = {
            title = string.format("%s (%s)", item.playerName, item.citizenid),
            description = string.format("Ban ngành: %s | %s\nCòn lại: %s", item.jobLabel, fireTypeLabel, timeRemainingStr),
            icon = item.fire_type == 'blacklist' and 'ban' or 'clock',
            onSelect = function()
                lib.registerContext({
                    id = 'admin_cooldown_detail_' .. item.id,
                    title = 'Thông tin: ' .. item.playerName,
                    menu = 'admin_cooldown_list_menu',
                    options = {
                        {
                            title = '👤 Tên người chơi',
                            description = item.playerName,
                            icon = 'user'
                        },
                        {
                            title = '🆔 Citizen ID',
                            description = item.citizenid,
                            icon = 'id-card'
                        },
                        {
                            title = '🏢 Ban ngành',
                            description = string.format("%s (%s)", item.jobLabel, item.job),
                            icon = 'building'
                        },
                        {
                            title = '📋 Hình thức',
                            description = fireTypeLabel,
                            icon = 'file-contract'
                        },
                        {
                            title = '📝 Lý do sa thải',
                            description = (item.reason and item.reason ~= '') and item.reason or 'Không có',
                            icon = 'comment-dots'
                        },
                        {
                            title = '👮 Người thực hiện sa thải',
                            description = string.format("%s (%s)", item.firedByName or 'N/A', item.firedBy or 'N/A'),
                            icon = 'user-shield'
                        },
                        {
                            title = '⏳ Thời hạn Hết hạn',
                            description = string.format("%s (Còn lại: %s)", item.expireDateStr, timeRemainingStr),
                            icon = 'hourglass-half'
                        },
                        {
                            title = '🗑️ Hủy Countdown',
                            description = 'Click vào đây để xóa dữ liệu Countdown của người chơi này trong SQL',
                            icon = 'trash-can',
                            iconColor = '#ff4d4d',
                            onSelect = function()
                                local input = lib.inputDialog('Hủy Countdown: ' .. item.playerName, {
                                    {
                                        type = 'input',
                                        label = 'Lý do gỡ Countdown',
                                        placeholder = 'Nhập lý do gỡ countdown (ví dụ: Ân xá, Thâm niên tốt...)',
                                        required = true,
                                    }
                                })
                                if not input or not input[1] or input[1] == '' then return end
                                local removeReason = input[1]

                                local confirm = lib.alertDialog({
                                    header = 'Xác nhận Hủy Countdown',
                                    content = string.format("Bạn có chắc chắn muốn Hủy Countdown cho **%s** (Citizen ID: `%s`)?\n\n**Lý do gỡ:** %s\n\nHành động này sẽ xóa dữ liệu trong SQL.", item.playerName, item.citizenid, removeReason),
                                    centered = true,
                                    cancel = true,
                                    labels = {
                                        cancel = 'Hủy bỏ',
                                        confirm = 'Xác nhận xóa'
                                    }
                                })
                                if confirm == 'confirm' then
                                    local success = lib.callback.await('qbx_management:server:removeCooldown', false, item.id, item.citizenid, removeReason)
                                    if success then
                                        openAdminCooldownMenu()
                                    end
                                end
                            end
                        }
                    }
                })
                lib.showContext('admin_cooldown_detail_' .. item.id)
            end
        }
    end

    lib.registerContext({
        id = 'admin_cooldown_list_menu',
        title = '📋 DANH SÁCH COUNTDOWN BAN NGÀNH',
        options = menuOptions
    })

    lib.showContext('admin_cooldown_list_menu')
end

RegisterNetEvent('qbx_management:client:openAdminCooldownMenu', function()
    openAdminCooldownMenu()
end)
