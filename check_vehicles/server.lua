-- =========================================================================
-- SCRIPT KIỂM TRA AI SỞ HỮU TỪ 7/9 MẪU XE TRỞ LÊN (QBCore / oxmysql / mysql-async)
-- =========================================================================

-- Danh sách 9 mẫu xe trong sự kiện/bộ sưu tập
local targetVehicles = {
    'r2f2fgtr34',
    'r2f2fgts',
    'r2f2fs2000',
    'r2f2fmle7',
    'fnfrx7',
    'chargerf8',
    'r2f2fmk4',
    'fnfmits',
    'godz95gsx'
}

local TOTAL_TARGETS = #targetVehicles -- 9 xe
local REQUIRED_COUNT = 7              -- Chỉ cần có từ 7 xe trở lên trong số 9 xe là báo

-- Hàm thực thi SQL an toàn
local function ExecuteSQL(query, params)
    local p = promise.new()
    
    if exports.oxmysql then
        exports.oxmysql:query(query, params or {}, function(result)
            p:resolve(result)
        end)
    elseif MySQL and MySQL.query then
        MySQL.query(query, params or {}, function(result)
            p:resolve(result)
        end)
    elseif MySQL and MySQL.Async and MySQL.Async.fetchAll then
        MySQL.Async.fetchAll(query, params or {}, function(result)
            p:resolve(result)
        end)
    else
        print("^1[CHECK XE - LỖI]^7 Không tìm thấy resource oxmysql hoặc mysql-async!")
        p:resolve(nil)
    end
    
    return Citizen.Await(p)
end

--- Hàm kiểm tra những citizenid sở hữu từ 7/9 mẫu xe trở lên
--- @param targetSrc number? ID của người chơi muốn nhận kết quả vào F8 (nếu có)
local function CheckSpecialVehicles(targetSrc)
    print("^3============================================================^7")
    print(("^2[CHECK XE]^7 Đang quét tìm người sở hữu từ ^6%s/%s^7 mẫu xe trong danh sách..."):format(REQUIRED_COUNT, TOTAL_TARGETS))

    -- Tạo danh sách chuỗi SQL xe
    local formattedVehicles = {}
    for _, v in ipairs(targetVehicles) do
        table.insert(formattedVehicles, string.format("'%s'", string.lower(v)))
    end
    local vehicleInClause = table.concat(formattedVehicles, ", ")

    local queryVehicles = string.format([[
        SELECT citizenid, vehicle, plate, garage, state 
        FROM player_vehicles 
        WHERE LOWER(vehicle) IN (%s)
        ORDER BY citizenid ASC
    ]], vehicleInClause)

    local results = ExecuteSQL(queryVehicles)

    if not results or #results == 0 then
        print("^1[CHECK XE]^7 Không tìm thấy ai có xe nào trong danh sách 9 xe!")
        print("^3============================================================^7")
        if targetSrc and targetSrc > 0 then
            TriggerClientEvent('checkvehicles:client:printF8', targetSrc, {}, REQUIRED_COUNT, TOTAL_TARGETS)
        end
        return {}
    end

    -- Gom nhóm theo từng CitizenID và đếm số mẫu xe độc nhất
    local citizenData = {}
    for _, row in ipairs(results) do
        local cid = row.citizenid
        local vehNameLower = string.lower(row.vehicle)

        if not citizenData[cid] then
            citizenData[cid] = {
                citizenid = cid,
                uniqueVehicles = {},
                vehicleList = {},
                totalUnique = 0
            }
        end

        if not citizenData[cid].uniqueVehicles[vehNameLower] then
            citizenData[cid].uniqueVehicles[vehNameLower] = true
            citizenData[cid].totalUnique = citizenData[cid].totalUnique + 1
        end

        table.insert(citizenData[cid].vehicleList, {
            vehicle = row.vehicle,
            plate = row.plate,
            garage = row.garage or "N/A",
            state = row.state or 0
        })
    end

    -- Lọc chỉ lấy những CitizenID có từ REQUIRED_COUNT (7) mẫu xe trở lên
    local qualifiedCitizens = {}
    local qualifiedCidList = {}

    for cid, data in pairs(citizenData) do
        if data.totalUnique >= REQUIRED_COUNT then
            table.insert(qualifiedCitizens, data)
            table.insert(qualifiedCidList, string.format("'%s'", cid))
        end
    end

    -- Sắp xếp người có nhiều xe nhất lên đầu (9/9 -> 8/9 -> 7/9)
    table.sort(qualifiedCitizens, function(a, b)
        return a.totalUnique > b.totalUnique
    end)

    if #qualifiedCitizens == 0 then
        print(("^1[CHECK XE]^7 Không có ai đạt đủ điều kiện sở hữu từ %s/%s xe!"):format(REQUIRED_COUNT, TOTAL_TARGETS))
        print("^3============================================================^7")
        if targetSrc and targetSrc > 0 then
            TriggerClientEvent('checkvehicles:client:printF8', targetSrc, {}, REQUIRED_COUNT, TOTAL_TARGETS)
        end
        return {}
    end

    -- Lấy tên nhân vật từ bảng players cho những người đạt điều kiện
    local playerNames = {}
    local queryPlayers = string.format([[
        SELECT citizenid, charinfo 
        FROM players 
        WHERE citizenid IN (%s)
    ]], table.concat(qualifiedCidList, ", "))
    
    local playerResults = ExecuteSQL(queryPlayers)
    if playerResults then
        for _, pRow in ipairs(playerResults) do
            if pRow.charinfo then
                local ok, charinfo = pcall(json.decode, pRow.charinfo)
                if ok and charinfo then
                    local fullName = ("%s %s"):format(charinfo.firstname or "", charinfo.lastname or "")
                    playerNames[pRow.citizenid] = fullName
                end
            end
        end
    end

    -- Gán tên nhân vật vào danh sách
    for _, qPlayer in ipairs(qualifiedCitizens) do
        qPlayer.playerName = playerNames[qPlayer.citizenid] or "Không xác định / Đã xóa"
    end

    -- In kết quả ra Server Console
    print(("^2[CHECK XE - THÀNH CÔNG]^7 Tìm thấy ^6%s^7 người sở hữu từ ^3%s/%s^7 xe:"):format(#qualifiedCitizens, REQUIRED_COUNT, TOTAL_TARGETS))
    print("------------------------------------------------------------")
    for idx, qPlayer in ipairs(qualifiedCitizens) do
        print(("^3[%s] CitizenID: ^6%s^7 | Tên: ^2%s^7 | Sở hữu: ^5%s/%s xe^7"):format(
            idx, qPlayer.citizenid, qPlayer.playerName, qPlayer.totalUnique, TOTAL_TARGETS
        ))
        for vIdx, v in ipairs(qPlayer.vehicleList) do
            print(("^5   - Xe %s:^7 %-15s | Biển: ^6%-10s^7 | Garage: ^4%s^7"):format(vIdx, v.vehicle, v.plate, v.garage))
        end
    end
    print("^3============================================================^7")

    -- Lưu file JSON kết quả
    local fileName = "qualified_vehicles_result.json"
    SaveResourceFile(GetCurrentResourceName(), fileName, json.encode(qualifiedCitizens, { indent = true }), -1)
    print(("^2[CHECK XE]^7 Đã lưu báo cáo ra file: ^5%s^7"):format(fileName))

    -- Gửi kết quả về Client F8
    if targetSrc and targetSrc > 0 then
        TriggerClientEvent('checkvehicles:client:printF8', targetSrc, qualifiedCitizens, REQUIRED_COUNT, TOTAL_TARGETS)
    end

    return qualifiedCitizens
end

-- Export
exports('CheckSpecialVehicles', CheckSpecialVehicles)

-- Event nhận request từ Client F8 / chat
RegisterNetEvent('checkvehicles:server:requestCheck', function()
    local src = source
    CheckSpecialVehicles(src)
end)

-- Command chạy trực tiếp từ Server Console
RegisterCommand('checkvehicles_sv', function(source, args, raw)
    if source == 0 then
        CheckSpecialVehicles(nil)
    end
end, false)
