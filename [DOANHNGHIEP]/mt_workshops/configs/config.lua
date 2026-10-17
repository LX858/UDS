Config = Config or {}

Config.framework = 'qbx' -- qb, qbx, esx (need to change the export on the Config.core)
Config.core = exports['qb-core']:GetCoreObject() -- core export (for qb is exports['qb-core']:GetCoreObject()) (for esx is exports.es_extended:getSharedObject()) (for qbx you can just delete this line and add '@qbx_core/modules/playerdata.lua', to the fxmanifest.lua client_scripts)
Config.inventory = 'ox_inventory' -- ox_inventory, qb-inventory, qb-inventory-old, ... (Remember that only with ox_inventory you'll have the best usage of all script features!!)
Config.target = 'ox_target' -- ox_target, qb-target, interact, ...
Config.keys = 'Renewed-Vehiclekeys' -- qb-vehiclekesy, Renewed-Vehiclekeys, qbx_vehiclekeys, ... (can change at server/functions.lua)
Config.banking = 'Renewed-Banking' -- qb-banking, Renewed-Banking, ... (can change at server/functions.lua)

Config.locale = 'en' -- this is the locales that'll show on the script UI

Config.inventoryDirectory = 'ox_inventory/web/images/'

Config.debug = false-- if true it'll --print some debug on F8/console and active all zones debug

Config.useOxInventoryCraft = true -- if true it'll use the ox_inventory crafting system on all crafts (only for ox_invntory, check docs for that)

Config.givePerformanceItems = true -- if true it'll give the performance installed items back when removing it

Config.toggleDutyZones = false -- Nếu đúng, nhiệm vụ của người chơi sẽ chuyển đổi khi tham gia khu vực

Config.useClasses = false -- Nếu sai, nó sẽ bỏ qua các lớp xe, hãy đảm bảo cập nhật các cấu hình/hiệu suất.lua để sửa nhiều phần hiệu suất
Config.useQBSharedClasses = false -- if true it'll use the qb-core/shared/vehicles.lua file to get the added classes if false the vehicle and the class needs to be added to the configs/classes.lua
Config.classesCommand = 'class'

Config.times = {
    repairEngine = 5000,
    repairBody = 5000,
    repairTank = 5000,
    wash = 30000,
    installingMod = 5000,
    removingMod = 5000,
    installingCosmetic = 5000,
    askMission = 5000
}

Config.repairItems = {
    engine = { count = 1, item = 'phutung' },
    body = { count = 1, item = 'thanvo' },
    wash = { count = 1, item = 'bolauxe' },
    repairAll = { count = 100, item = 'money' }, -- Item cho xe đặc biệt (công an, bác sĩ)
}

Config.specialVehiclesIgnoreZone = true -- Nếu true, xe ngành không cần đứng trong zone garage mới sửa được

-- Danh sách xe đặc biệt (công an, bác sĩ) - chỉ có option "Repair All"
Config.specialVehicles = {
    'police',
    'police2',
    'police3',
    'police4',
    'policeb',
    'policeold1',
    'policeold2',
    'policet',
    'sheriff',
    'sheriff2',
    'ambulance',
    'firetruk',
    'pranger',
    'dc_mdoracle',
    'ShuttleBus',
    'dc_mdbuffalo',
    'dc_mdg4m82',
    'nkvigero2',
    'r1200rtp',
    'nkdoradoac',
    'nkbuffalo4',
    'nkfugitive',
    'nkgtx',
    'polcoq4',
    'sultanpoli',
    'wmfenyrcop',
    'ist57bsrf',
    -- Thêm xe đặc biệt khác ở đây
}

Config.preview = {
    command = 'doxe',
    lockJob = false,
    useItem = true, -- Nếu true, sử dụng item tuner_pad thay vì command
    item = 'tuner_pad' -- Item để mở menu preview
}

Config.toolboxOptions = {
    engine = true,
    body = true,
    tank = false,
    wash = true
}

Config.hoadon = {
    pricePerPercentBody = 30,    -- Giá tiền trên 1% thân vỏ sửa chữa
    pricePerPercentEngine = 30,  -- Giá tiền trên 1% động cơ sửa chữa
}

Config.itemLabels = {
    -- Paint & Cosmetics Items
    ['mechspray'] = 'Sơn xe',
    ['chameleon_spray'] = 'Sơn Chameleon',
    ['cosmetics'] = 'Đồ trang trí xe',
    ['neon_custom'] = 'Bóng đèn gầm',
    
    -- Wheels & Rims
    ['car_wheel'] = 'Mâm xe',
    
    -- Body Parts
    ['spoiler'] = 'Cánh gió',
    ['front_bumper'] = 'Cản trước',
    ['rear_bumper'] = 'Cản sau',
    ['skirtcar'] = 'Ốp hông',
    ['exhaust'] = 'Ống xả',
    ['car_hood'] = 'Nắp capo',
    
    -- Interior Items
    ['horn'] = 'Còi xe',
    ['internals'] = 'Phụ kiện nội thất',
    ['seats'] = 'Ghế xe',
    
    -- Engine & Performance
    ['engine_block'] = 'Khối động cơ',
    
    -- Plates & Livery
    ['vanity_plate'] = 'Biển số trang trí',
    ['livery'] = 'Tem dán',
    
    -- Performance Items
    ['engine_s'] = 'Động cơ cấp S',
    ['engine_a'] = 'Động cơ cấp A',
    ['engine_b'] = 'Động cơ cấp B',
    ['engine_c'] = 'Động cơ cấp C',
    ['engine_d'] = 'Động cơ cấp D',
    
    ['transmission_s'] = 'Hộp số cấp S',
    ['transmission_a'] = 'Hộp số cấp A',
    ['transmission_b'] = 'Hộp số cấp B',
    ['transmission_c'] = 'Hộp số cấp C',
    ['transmission_d'] = 'Hộp số cấp D',
    
    ['brake_s'] = 'Phanh cấp S',
    ['brake_a'] = 'Phanh cấp A',
    ['brake_b'] = 'Phanh cấp B',
    ['brake_c'] = 'Phanh cấp C',
    ['brake_d'] = 'Phanh cấp D',
    
    ['suspension_s'] = 'Giảm xóc cấp S',
    ['suspension_a'] = 'Giảm xóc cấp A',
    ['suspension_b'] = 'Giảm xóc cấp B',
    ['suspension_c'] = 'Giảm xóc cấp C',
    ['suspension_d'] = 'Giảm xóc cấp D',
    
    ['armour_s'] = 'Giáp xe cấp S',
    ['armour_a'] = 'Giáp xe cấp A',
    ['armour_b'] = 'Giáp xe cấp B',
    ['armour_c'] = 'Giáp xe cấp C',
    ['armour_d'] = 'Giáp xe cấp D',
    
    ['turbo_s'] = 'Turbo cấp S',
    ['turbo_a'] = 'Turbo cấp A',
    ['turbo_b'] = 'Turbo cấp B',
    ['turbo_c'] = 'Turbo cấp C',
    ['turbo_d'] = 'Turbo cấp D',
    
    -- Other Items
    ['neons_controller'] = 'Điều khiển đèn neon',
    ['engine_repair_kit'] = 'Bộ sửa chữa động cơ',
    ['extras_controller'] = 'Điều khiển phụ kiện',
    
    -- Repair Items
    ['phutung'] = 'Phụ tung',
    ['thanvo'] = 'Thân vỏ',
    ['phutungdacbiet'] = 'Phụ tùng xe đặc biệt',
    
    -- Tuner Items
    ['tuner_pad'] = 'Máy tính độ xe',
}

Config.webhookURL = "123" -- Thay bằng webhook URL của bạn