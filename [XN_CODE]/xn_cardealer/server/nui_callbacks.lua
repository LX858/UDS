-- NUI Management System
-- Callbacks cho việc quản lý xe thông qua NUI hỗ trợ Multi-Dealer

local QBCore = exports["qb-core"]:GetCoreObject()

local function IsModOrAdmin(src)
    if not src then return false end
    return (IsPlayerMod and IsPlayerMod(src))
        or QBCore.Functions.HasPermission(src, 'admin')
        or QBCore.Functions.HasPermission(src, 'god')
        or QBCore.Functions.HasPermission(src, 'mod')
        or IsPlayerAceAllowed(tostring(src), 'command')
        or IsPlayerAceAllowed(tostring(src), 'admin')
        or IsPlayerAceAllowed(tostring(src), 'mod')
        or (exports.qbx_core and exports.qbx_core:HasPermission(src, 'mod'))
        or (exports.qbx_core and exports.qbx_core:HasPermission(src, 'admin'))
end

local function HasDealerAccess(Player, minGrade)
    if not Player then return false, nil end
    local src = Player.PlayerData.source
    if IsModOrAdmin(src) then
        return true, 'mod'
    end
    local jobName = Player.PlayerData.job and Player.PlayerData.job.name
    local dealerId, dealerCfg = GetDealerByJob(jobName)
    if not dealerId then return false, nil end
    local grade = (Player.PlayerData.job.grade and Player.PlayerData.job.grade.level) or 0
    if minGrade and grade < minGrade then
        return false, dealerId
    end
    return true, dealerId
end

-- Callback lấy danh sách tất cả xe (hỗ trợ lọc theo dealer)
lib.callback.register("1307_Cardealer:server:GetAllVehicles", function(source, dealerId)
    local targetDealer = dealerId or 'cardealer'
    local result = exports.oxmysql:executeSync('SELECT * FROM cardealer_stock WHERE dealer = ? ORDER BY category, vehicle', { targetDealer })
    return result or {}
end)

-- Callback lấy danh sách các category đã tồn tại (cho dropdown & tabs)
lib.callback.register("1307_Cardealer:server:GetCategories", function(source, dealerId)
    local query = 'SELECT DISTINCT category FROM cardealer_stock'
    local params = {}
    if dealerId then
        query = query .. ' WHERE dealer = ?'
        params = { dealerId }
    end
    query = query .. ' ORDER BY category'
    
    local result = exports.oxmysql:executeSync(query, params)
    local categories = {}
    if result then
        for _, row in ipairs(result) do
            if row.category and row.category ~= '' then
                table.insert(categories, row.category)
            end
        end
    end
    return categories
end)

-- Callback đổi tên tab/category
lib.callback.register('1307_Cardealer:server:RenameCategory', function(source, oldName, newName, dealerId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    local hasAccess, playerDealer = HasDealerAccess(Player, 3)
    if not hasAccess then
        return { success = false, message = 'Bạn không có quyền thực hiện thao tác này!' }
    end
    
    local targetDealer = dealerId or playerDealer or 'cardealer'
    if not oldName or not newName or oldName == '' or newName == '' then
        return { success = false, message = 'Tên tab không hợp lệ!' }
    end
    
    local done, success, message, affectedRows = false, false, '', 0
    
    exports.oxmysql:execute('UPDATE cardealer_stock SET category = ? WHERE category = ? AND dealer = ?', {
        newName, oldName, targetDealer
    }, function(result)
        affectedRows = type(result) == 'number' and result or (result and result.affectedRows or 0)
        if affectedRows > 0 then
            BuildVehicleCache(function()
                success = true
                message = 'Đã đổi tên tab "' .. oldName .. '" thành "' .. newName .. '" cho ' .. affectedRows .. ' xe!'
                done = true
            end)
        else
            message = 'Không tìm thấy xe nào trong tab "' .. oldName .. '"!'
            done = true
        end
    end)
    
    while not done do Wait(0) end
    
    return { success = success, message = message }
end)

-- Callback thêm xe mới
lib.callback.register('1307_Cardealer:server:AddVehicle', function(source, data)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    local hasAccess, playerDealer = HasDealerAccess(Player, 3)
    if not hasAccess then
        return { success = false, message = 'Bạn không có quyền thực hiện thao tác này!' }
    end
    
    local targetDealer = data.dealerId or playerDealer or 'cardealer'
    
    local checkExist = exports.oxmysql:executeSync('SELECT * FROM cardealer_stock WHERE vehicle = ? AND dealer = ?', { data.vehicle, targetDealer })
    if checkExist and #checkExist > 0 then
        local existingVeh = checkExist[1]
        return { success = false, message = 'Xe "' .. data.vehicle .. '" đã tồn tại trong danh mục "' .. existingVeh.category .. '" của đại lý này!' }
    end
    
    local categoryValue = data.category and data.category ~= '' and data.category or data.vehicleClass
    local done, success, message = false, false, ''
    
    exports.oxmysql:insert('INSERT INTO cardealer_stock (dealer, category, vehicle, stock, priceToOwners, priceToCustomers, danhap, gioihan, nochangeprice, isNew, isHot, originalPrice, discountPercent) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        targetDealer, categoryValue, data.vehicle, 0,
        data.priceToOwners, data.priceToCustomers, 0,
        data.gioihan, data.nochangeprice,
        data.isNew and 1 or 0, data.isHot and 1 or 0,
        data.originalPrice, data.discountPercent
    }, function(insertId)
        if insertId then
            BuildVehicleCache(function()
                success = true
                message = 'Đã thêm xe thành công vào ' .. targetDealer .. '!'
                done = true
            end)
        else
            message = 'Có lỗi khi thêm xe!'
            done = true
        end
    end)
    
    while not done do Wait(0) end
    return { success = success, message = message }
end)

-- Callback cập nhật xe
lib.callback.register('1307_Cardealer:server:UpdateVehicle', function(source, data)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    local hasAccess, playerDealer = HasDealerAccess(Player, 4)
    if not hasAccess then
        return { success = false, message = 'Bạn không có quyền thực hiện thao tác này!' }
    end
    
    local isMod = IsModOrAdmin(src)
    local updateQuery, updateParams
    
    if isMod then
        -- Admin / Mod: Sửa toàn bộ thông tin
        if data.stock then
            updateQuery = 'UPDATE cardealer_stock SET category = ?, priceToOwners = ?, priceToCustomers = ?, gioihan = ?, nochangeprice = ?, stock = ?, isNew = ?, isHot = ?, originalPrice = ?, discountPercent = ? WHERE id = ?'
            updateParams = {
                data.vehicleClass or data.category,
                data.priceToOwners, data.priceToCustomers,
                data.gioihan, data.nochangeprice, data.stock,
                data.isNew and 1 or 0, data.isHot and 1 or 0,
                data.originalPrice, data.discountPercent, data.id
            }
        else
            updateQuery = 'UPDATE cardealer_stock SET category = ?, priceToOwners = ?, priceToCustomers = ?, gioihan = ?, nochangeprice = ?, isNew = ?, isHot = ?, originalPrice = ?, discountPercent = ? WHERE id = ?'
            updateParams = {
                data.vehicleClass or data.category,
                data.priceToOwners, data.priceToCustomers,
                data.gioihan, data.nochangeprice,
                data.isNew and 1 or 0, data.isHot and 1 or 0,
                data.originalPrice, data.discountPercent, data.id
            }
        end
    else
        -- Giám đốc đại lý (grade == 4): CHỈ được sửa tab hiển thị (category) và loại NEW/HOT
        -- KHÔNG được sửa giá gốc, % giảm giá, giá bán, giới hạn, tồn kho, tăng giảm giá
        updateQuery = 'UPDATE cardealer_stock SET category = ?, isNew = ?, isHot = ? WHERE id = ?'
        updateParams = {
            data.vehicleClass or data.category,
            data.isNew and 1 or 0, data.isHot and 1 or 0,
            data.id
        }
    end
    
    local done, success, message = false, false, ''
    
    exports.oxmysql:execute(updateQuery, updateParams, function(result)
        local affectedRows = type(result) == 'number' and result or (result and result.affectedRows or 0)
        if affectedRows > 0 then
            BuildVehicleCache(function()
                success = true
                message = 'Đã cập nhật xe thành công!'
                done = true
            end)
        else
            message = 'Không tìm thấy xe để cập nhật!'
            done = true
        end
    end)
    
    while not done do Wait(0) end
    return { success = success, message = message }
end)

-- Callback xóa xe
lib.callback.register('1307_Cardealer:server:DeleteVehicle', function(source, vehicleId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not IsModOrAdmin(src) then
        return { success = false, message = 'Chỉ Admin/Mod mới có quyền xóa xe!' }
    end
    
    local done, success, message = false, false, ''
    
    exports.oxmysql:execute('DELETE FROM cardealer_stock WHERE id = ?', { vehicleId }, function(result)
        local affectedRows = type(result) == 'number' and result or (result and result.affectedRows or 0)
        if affectedRows > 0 then
            BuildVehicleCache(function()
                success = true
                message = 'Đã xóa xe thành công!'
                done = true
            end)
        else
            message = 'Không tìm thấy xe để xóa!'
            done = true
        end
    end)
    
    while not done do Wait(0) end
    return { success = success, message = message }
end)

-- Callback lấy lịch sử bán xe
lib.callback.register('1307_Cardealer:server:GetSalesHistory', function(source, page, limit, search, dealerId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    local hasAccess, playerDealer = HasDealerAccess(Player, 3)
    if not hasAccess then
        return { success = false, message = 'Bạn không có quyền xem lịch sử bán xe!' }
    end
    
    local targetDealer = dealerId or playerDealer or 'cardealer'
    local pageVal = tonumber(page) or 1
    local limitVal = tonumber(limit) or 10
    local offsetVal = (pageVal - 1) * limitVal
    local searchStr = search and tostring(search):gsub("^%s*(.-)%s*$", "%1") or ""
    
    local done, history = false, {}
    
    if searchStr ~= "" then
        local queryParam = '%' .. searchStr .. '%'
        local query = [[
            SELECT * FROM cardealer_sales_history 
            WHERE (dealer = ? OR dealer IS NULL)
              AND (buyer_source LIKE ? 
               OR buyer_name LIKE ? 
               OR buyer_citizenid LIKE ? 
               OR seller_source LIKE ? 
               OR seller_name LIKE ? 
               OR seller_citizenid LIKE ?
               OR vehicle LIKE ? 
               OR vehicle_name LIKE ? 
               OR plate LIKE ?)
            ORDER BY created_at DESC 
            LIMIT ? OFFSET ?
        ]]
        exports.oxmysql:execute(query, {
            targetDealer,
            queryParam, queryParam, queryParam, queryParam, queryParam, queryParam, queryParam, queryParam, queryParam,
            limitVal, offsetVal
        }, function(result)
            history = result or {}
            done = true
        end)
    else
        exports.oxmysql:execute('SELECT * FROM cardealer_sales_history WHERE (dealer = ? OR dealer IS NULL) ORDER BY created_at DESC LIMIT ? OFFSET ?', {
            targetDealer, limitVal, offsetVal
        }, function(result)
            history = result or {}
            done = true
        end)
    end
    
    while not done do Wait(0) end
    local hasMore = #history >= limitVal
    
    return {
        success = true,
        data = history,
        hasMore = hasMore
    }
end)
