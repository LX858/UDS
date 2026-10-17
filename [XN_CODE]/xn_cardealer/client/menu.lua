function OpenVehicleCategories(dealerId)
    Citizen.Wait(100)
    local targetDealer = dealerId or (QBX.PlayerData.job and GetDealerByJob(QBX.PlayerData.job.name))
    local data = lib.callback.await("1307_Cardealer:server:GetData", false, targetDealer)
    Client_Vehicle_Data = data
    
    local VehicleCategoryOptions = {}
    local categories = {}
    
    if Client_Vehicle_Data then
        for k, v in pairs(Client_Vehicle_Data) do
            if not categories[v.category] then
                categories[v.category] = true
                VehicleCategoryOptions[#VehicleCategoryOptions+1] = {
                    title = v.category,
                    onSelect = function(option) 
                        OpenVehicleListOrder(v.category, targetDealer)
                    end
                }
            end
        end
    end

    if #VehicleCategoryOptions == 0 then
        exports.qbx_core:Notify("Không có xe nào trong kho! Vui lòng dùng NUI để thêm xe", "error")
        return
    end

    lib.registerContext({
        id = '1307_OpenVehicleCategories',
        title = "DANH SÁCH XE",
        options = VehicleCategoryOptions 
    })
    lib.showContext('1307_OpenVehicleCategories')
end

function ClearShowroom(dealerId)
    local targetDealer = dealerId or (QBX.PlayerData.job and GetDealerByJob(QBX.PlayerData.job.name)) or 'cardealer'
    local dealerCfg = GetDealerById(targetDealer)
    if not dealerCfg or not dealerCfg.showroomLocations then
        return exports.qbx_core:Notify("Không tìm thấy cấu hình showroom", "error")
    end

    local totalDeleted = 0
    
    for k, v in pairs(dealerCfg.showroomLocations) do
        local coords = vector3(v.x, v.y, v.z)
        for radius = 1, 3 do
            local vehinarea = GetVehiclesInArea(coords, radius)
            if #vehinarea > 0 then
                for i = 1, #vehinarea do
                    local vehicle = vehinarea[i]
                    if DoesEntityExist(vehicle) then
                        local plate = GetVehicleNumberPlateText(vehicle)
                        if plate == "XEBAN999" then
                            FreezeEntityPosition(vehicle, false)
                            SetEntityAsMissionEntity(vehicle, true, true)
                            DeleteVehicle(vehicle)
                            totalDeleted = totalDeleted + 1
                        end
                    end
                end
                if #vehinarea > 0 then
                    break
                end
            end
        end
    end
    
    Citizen.Wait(500)
    
    local allShowroomVehicles = {}
    for k, v in pairs(dealerCfg.showroomLocations) do
        local coords = vector3(v.x, v.y, v.z)
        local vehinarea = GetVehiclesInArea(coords, 5)
        for i = 1, #vehinarea do
            local vehicle = vehinarea[i]
            if DoesEntityExist(vehicle) then
                local plate = GetVehicleNumberPlateText(vehicle)
                if plate == "XEBAN999" and not table.contains(allShowroomVehicles, vehicle) then
                    table.insert(allShowroomVehicles, vehicle)
                end
            end
        end
    end
    
    for i = 1, #allShowroomVehicles do
        local vehicle = allShowroomVehicles[i]
        if DoesEntityExist(vehicle) then
            FreezeEntityPosition(vehicle, false)
            SetEntityAsMissionEntity(vehicle, true, true)
            DeleteVehicle(vehicle)
            totalDeleted = totalDeleted + 1
        end
    end
    
    if totalDeleted > 0 then
        exports.qbx_core:Notify("Đã dọn sạch " .. totalDeleted .. " xe trong Showroom", "success", 3000)
    else
        exports.qbx_core:Notify("Không tìm thấy xe nào trong Showroom để dọn dẹp", "info", 2500)
    end
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function ForceClearShowroomArea(dealerId)
    local totalDeleted = 0
    local playerCoords = GetEntityCoords(PlayerPedId())
    local allVehicles = GetGamePool('CVehicle')
    
    for i = 1, #allVehicles do
        local vehicle = allVehicles[i]
        if DoesEntityExist(vehicle) then
            local vehCoords = GetEntityCoords(vehicle)
            local distance = #(playerCoords - vehCoords)
            
            if distance < 50 then
                local plate = GetVehicleNumberPlateText(vehicle)
                if plate == "XEBAN999" or string.find(plate, "XETEST") then
                    FreezeEntityPosition(vehicle, false)
                    SetEntityAsMissionEntity(vehicle, true, true)
                    DeleteVehicle(vehicle)
                    totalDeleted = totalDeleted + 1
                end
            end
        end
    end
    
    exports.qbx_core:Notify("Force clear: Đã xóa " .. totalDeleted .. " xe", totalDeleted > 0 and "success" or "info", 3000)
end

function OpenShowroomVehicleCategories(dealerId)
    local targetDealer = dealerId or (QBX.PlayerData.job and GetDealerByJob(QBX.PlayerData.job.name))
    local data = lib.callback.await("1307_Cardealer:server:GetData", false, targetDealer)
    Client_Vehicle_Data = data
    
    local VehicleCategoryOptions = {}
    local categories = {}
    
    if Client_Vehicle_Data then
        for k, v in pairs(Client_Vehicle_Data) do
            if not categories[v.category] then
                categories[v.category] = true
                VehicleCategoryOptions[#VehicleCategoryOptions+1] = {
                    title = v.category,
                    description = "Chọn để đặt vị trí trong showroom",
                    onSelect = function(option) 
                        OpenVehicleList(v.category, targetDealer)
                    end
                }
            end
        end
    end

    VehicleCategoryOptions[#VehicleCategoryOptions+1] = {
        title = "🔧 Dọn sạch tất cả các xe đang trưng bày trong showroom",
        description = "Phương pháp thông thường để dọn dẹp showroom",
        onSelect = function(option) 
            ClearShowroom(targetDealer)
        end
    }
    
    if QBX.PlayerData.job and QBX.PlayerData.job.grade and QBX.PlayerData.job.grade.level >= 1 then
        VehicleCategoryOptions[#VehicleCategoryOptions+1] = {
            title = "⚠️ FORCE CLEAR - Dọn sạch mạnh",
            description = "Dành cho Admin/Manager - Xóa tất cả xe showroom trong khu vực",
            onSelect = function(option) 
                ForceClearShowroomArea(targetDealer)
            end
        }
    end

    lib.registerContext({
        id = '1307_OpenShowroomVehicleCategories',
        title = "🚗 Sắp Xếp Showroom",
        options = VehicleCategoryOptions 
    })
    lib.showContext('1307_OpenShowroomVehicleCategories')
end

function OpenVehicleListOrder(brand, dealerId)
    Citizen.Wait(100)
    local targetDealer = dealerId or (QBX.PlayerData.job and GetDealerByJob(QBX.PlayerData.job.name))
    local data = lib.callback.await("1307_Cardealer:server:GetData", false, targetDealer)
    Client_Vehicle_Data = data
    
    if not Client_Vehicle_Data or type(Client_Vehicle_Data) ~= "table" then
        exports.qbx_core:Notify("Không có dữ liệu xe! Vui lòng dùng NUI để thêm xe", "error")
        return
    end
    
    local VehicleStockOptions = {}
    for k, v in pairs(Client_Vehicle_Data) do 
        if v.category == brand then
            local vehInfo = exports.qbx_core:GetVehiclesByName()[v.vehicle]
            if vehInfo then
                VehicleStockOptions[#VehicleStockOptions+1] = {
                    title = vehInfo.name,
                    description = "📦 Còn hàng : "..v.stock.." | 💵 Giá cố định : "..string.format("%.2f", v.priceToCustomers).."$ ",
                    onSelect = function(option) 
                        if Config.NhapXe_Grade[QBX.PlayerData.job.grade.level] then
                            OpenConfirmOrderList(v.vehicle, v.priceToCustomers, brand, targetDealer)
                        else 
                            exports.qbx_core:Notify("Bạn không đủ thẩm quyền để nhập xe", "error")
                        end
                    end
                }
            end
        end
    end
    
    if #VehicleStockOptions == 0 then
        exports.qbx_core:Notify("Không có xe nào trong danh mục " .. brand, "error")
        return
    end
    
    lib.registerContext({
        id = '1307_OpenVehicleListOrder',
        title = "📝 Danh sách xe " .. brand,
        options = VehicleStockOptions 
    })
    lib.showContext('1307_OpenVehicleListOrder')
end

function OpenShowroomOptions(vehicle, dealerId)
    local targetDealer = dealerId or (QBX.PlayerData.job and GetDealerByJob(QBX.PlayerData.job.name)) or 'cardealer'
    local dealerCfg = GetDealerById(targetDealer)
    local ShowroomOptions = {}

    if dealerCfg and dealerCfg.showroomLocations then
        for k, v in pairs(dealerCfg.showroomLocations) do
            ShowroomOptions[#ShowroomOptions+1] = {
                title = "Vị trí "..k,
                onSelect = function(option) 
                    local data = {
                        vehicle = vehicle, 
                        key = k,
                        dealerId = targetDealer
                    }
                    SpawnShowroom(data)
                end
            }
        end
    end

    lib.registerContext({
        id = '1307_OpenShowroomOptions',
        title = "📝 Danh sách vị trí Showroom " .. (dealerCfg and dealerCfg.label or ""),
        options = ShowroomOptions 
    })
    lib.showContext('1307_OpenShowroomOptions')
end

function OpenVehicleList(brand, dealerId)
    local targetDealer = dealerId or (QBX.PlayerData.job and GetDealerByJob(QBX.PlayerData.job.name))
    local data = lib.callback.await("1307_Cardealer:server:GetData", false, targetDealer)
    Client_Vehicle_Data = data
    
    if not Client_Vehicle_Data or type(Client_Vehicle_Data) ~= "table" then
        exports.qbx_core:Notify("Không có dữ liệu xe! Vui lòng dùng NUI để thêm xe", "error")
        return
    end
    
    local VehicleStockOptions = {}
    for k, v in pairs(Client_Vehicle_Data) do 
        if v.category == brand then
            local vehicleData = exports.qbx_core:GetVehiclesByName()[v.vehicle]
            if vehicleData and vehicleData.name then
                VehicleStockOptions[#VehicleStockOptions+1] = {
                    title = vehicleData.name,
                    description = "📦 Còn hàng : "..v.stock.." <br> 💵 Giá cố định : "..string.format("%.2f", v.priceToCustomers).."$ ",
                    onSelect = function(option) 
                        OpenShowroomOptions(v.vehicle, targetDealer)
                    end
                }
            end
        end
    end
    
    if #VehicleStockOptions == 0 then
        exports.qbx_core:Notify("Không có xe nào trong danh mục " .. brand, "error")
        return
    end
    
    lib.registerContext({
        id = '1307_OpenVehicleList',
        title = "📝 Danh sách xe " .. brand .. " để trưng bày",
        options = VehicleStockOptions 
    })
    lib.showContext('1307_OpenVehicleList')
end

function OpenConfirmOrderList(vehicle, price, brand, dealerId)
    local ConfirmOptions = {}
    ConfirmOptions[#ConfirmOptions+1] = {
        title = "✅ Đồng Ý",
        description = "Số tiền sẽ không thể hoàn trả lại khi đã đặt hàng",
        onSelect = function(option) 
            OrderingVehicle(vehicle, price, brand, dealerId)
        end
    }

    local vehName = exports.qbx_core:GetVehiclesByName()[vehicle] and exports.qbx_core:GetVehiclesByName()[vehicle]["name"] or vehicle
    lib.registerContext({
        id = '1307_OpenConfirmOrderList',
        title = "Bạn có chắc chắn muốn đặt hàng chiếc xe " .. vehName .. " với giá $" .. price .. "?",
        options = ConfirmOptions 
    })
    lib.showContext('1307_OpenConfirmOrderList')
end

function List_OpenVehicleCategories(dealerId)
    local targetDealer = dealerId or (QBX.PlayerData.job and GetDealerByJob(QBX.PlayerData.job.name))
    local data = lib.callback.await("1307_Cardealer:server:GetData", false, targetDealer)
    Client_Vehicle_Data = data
    
    local VehicleCategoryOptions = {}
    local categories = {}
    
    if Client_Vehicle_Data then
        for k, v in pairs(Client_Vehicle_Data) do
            if not categories[v.category] then
                categories[v.category] = true
                VehicleCategoryOptions[#VehicleCategoryOptions+1] = {
                    title = v.category,
                    onSelect = function(option) 
                        List_OpenVehicleListOrder(v.category, targetDealer)
                    end
                }
            end
        end
    end

    if #VehicleCategoryOptions == 0 then
        exports.qbx_core:Notify("Không có xe nào trong kho!", "error")
        return
    end

    lib.registerContext({
        id = '1307_List_OpenVehicleCategories',
        title = "📝 Danh sách các loại xe có trong cửa hàng",
        options = VehicleCategoryOptions 
    })
    lib.showContext('1307_List_OpenVehicleCategories')
end

function List_OpenVehicleListOrder(brand, dealerId)
    local targetDealer = dealerId or (QBX.PlayerData.job and GetDealerByJob(QBX.PlayerData.job.name))
    local data = lib.callback.await("1307_Cardealer:server:GetData", false, targetDealer)
    Client_Vehicle_Data = data
    
    local VehicleStockOptions = {}
    
    if not Client_Vehicle_Data or next(Client_Vehicle_Data) == nil then
        return
    end

    for k, v in pairs(Client_Vehicle_Data) do 
        if not brand or v.category == brand then
            local vehicleData = exports.qbx_core:GetVehiclesByName()[v.vehicle]
            if vehicleData and vehicleData.name then
                VehicleStockOptions[#VehicleStockOptions+1] = {
                    title = vehicleData.name,
                    description = "📦 Còn hàng : "..v.stock.."",
                    onSelect = function(option) 
                        exports.qbx_core:Notify("Liên hệ nhân viên đại lý để được tư vấn và lái thử", "info")
                    end
                }
            end
        end
    end

    if not VehicleStockOptions or next(VehicleStockOptions) == nil then
        exports.qbx_core:Notify("Không có xe nào trong danh mục này", "error")
        return
    end

    local title = brand and ("📝 Danh sách xe " .. brand) or "📝 Danh sách các loại xe có trong cửa hàng"
    lib.registerContext({
        id = '1307_List_OpenVehicleListOrder',
        title = title,
        options = VehicleStockOptions
    })
    lib.showContext('1307_List_OpenVehicleListOrder')
end
