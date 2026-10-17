local QBX = exports.qbx_core

-- Tự động tạo bảng gang_clothes nếu chưa tồn tại
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `gang_clothes` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `gang` VARCHAR(50) NOT NULL COMMENT 'Mã gang (qbx_core gang name)',
            `name` VARCHAR(100) NOT NULL COMMENT 'Tên bộ đồ',
            `gender` VARCHAR(10) DEFAULT 'all' COMMENT 'all / male / female',
            `grades` LONGTEXT NOT NULL COMMENT 'JSON array danh sách cấp bậc [0, 1, 2, 3]',
            `components` LONGTEXT NOT NULL COMMENT 'JSON object components (drawable, texture)',
            `props` LONGTEXT DEFAULT NULL COMMENT 'JSON object props (drawable, texture)',
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX `idx_gang` (`gang`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

-- Helper helper convert row DB to Lua Table
local function ParseOutfitRow(row)
    if not row then return nil end
    local grades = {}
    if row.grades then
        if type(row.grades) == 'table' then
            grades = row.grades
        else
            local ok, decoded = pcall(json.decode, row.grades)
            if ok and type(decoded) == 'table' then grades = decoded end
        end
    end

    local components = {}
    if row.components then
        if type(row.components) == 'table' then
            components = row.components
        else
            local ok, decoded = pcall(json.decode, row.components)
            if ok and type(decoded) == 'table' then components = decoded end
        end
    end

    local props = {}
    if row.props then
        if type(row.props) == 'table' then
            props = row.props
        else
            local ok, decoded = pcall(json.decode, row.props)
            if ok and type(decoded) == 'table' then props = decoded end
        end
    end

    return {
        id = row.id,
        gang = row.gang,
        name = row.name,
        gender = row.gender or 'all',
        grades = grades,
        components = components,
        props = props,
        created_at = row.created_at
    }
end

-- Callback lấy danh sách trang phục theo gang (Dành cho người chơi trong game)
lib.callback.register('qbx_housing:server:getGangOutfits', function(source, gangName)
    if not gangName or gangName == '' then return {} end
    
    local rows = MySQL.query.await('SELECT * FROM `gang_clothes` WHERE `gang` = ? ORDER BY `id` ASC', { gangName })
    if not rows or #rows == 0 then return {} end

    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, ParseOutfitRow(r))
    end
    return list
end)

-- Callback lấy danh sách trang phục (Dành cho Admin Panel)
lib.callback.register('qbx_housing:server:adminGetGangOutfits', function(source, gangName)
    local player = QBX:GetPlayer(source)
    if not player then return {} end

    local query = 'SELECT * FROM `gang_clothes`'
    local params = {}
    if gangName and gangName ~= '' and gangName ~= 'all' then
        query = query .. ' WHERE `gang` = ? ORDER BY `id` ASC'
        params = { gangName }
    else
        query = query .. ' ORDER BY `gang` ASC, `id` ASC'
    end

    local rows = MySQL.query.await(query, params)
    if not rows or #rows == 0 then return {} end

    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, ParseOutfitRow(r))
    end
    return list
end)

-- Callback lưu trang phục (Thêm mới hoặc Cập nhật)
lib.callback.register('qbx_housing:server:adminSaveGangOutfit', function(source, data)
    local player = QBX:GetPlayer(source)
    if not player then return false, 'Player not found' end

    if not IsPlayerAceAllowed(source, 'command.createhousing') then
        return false, 'Bạn không có quyền thực hiện thao tác này!'
    end

    if not data or not data.gang or data.gang == '' then
        return false, 'Mã Xã Đoàn không được để trống!'
    end

    if not data.name or data.name == '' then
        return false, 'Tên bộ đồ không được để trống!'
    end

    local gradesJson = json.encode(data.grades or {0, 1, 2, 3})
    local componentsJson = json.encode(data.components or {})
    local propsJson = json.encode(data.props or {})
    local gender = data.gender or 'all'

    if data.id and tonumber(data.id) and tonumber(data.id) > 0 then
        local outfitId = tonumber(data.id)
        local affected = MySQL.update.await([[
            UPDATE `gang_clothes` 
            SET `gang` = ?, `name` = ?, `gender` = ?, `grades` = ?, `components` = ?, `props` = ?
            WHERE `id` = ?
        ]], {
            data.gang,
            data.name,
            gender,
            gradesJson,
            componentsJson,
            propsJson,
            outfitId
        })

        if affected and affected > 0 then
            return true, 'Đã cập nhật bộ trang phục thành công!', outfitId
        else
            return false, 'Không tìm thấy bộ trang phục để cập nhật!'
        end
    else
        local insertId = MySQL.insert.await([[
            INSERT INTO `gang_clothes` (`gang`, `name`, `gender`, `grades`, `components`, `props`)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], {
            data.gang,
            data.name,
            gender,
            gradesJson,
            componentsJson,
            propsJson
        })

        if insertId then
            return true, 'Đã thêm mới bộ trang phục thành công!', insertId
        else
            return false, 'Không thể thêm trang phục vào database!'
        end
    end
end)

-- Callback xóa trang phục
lib.callback.register('qbx_housing:server:adminDeleteGangOutfit', function(source, outfitId)
    local player = QBX:GetPlayer(source)
    if not player then return false, 'Player not found' end

    if not IsPlayerAceAllowed(source, 'command.createhousing') then
        return false, 'Bạn không có quyền thực hiện thao tác này!'
    end

    if not outfitId or tonumber(outfitId) == nil then
        return false, 'Mã trang phục không hợp lệ!'
    end

    local affected = MySQL.update.await('DELETE FROM `gang_clothes` WHERE `id` = ?', { tonumber(outfitId) })
    if affected and affected > 0 then
        return true, 'Đã xóa bộ trang phục thành công!'
    else
        return false, 'Không tìm thấy bộ trang phục để xóa!'
    end
end)
