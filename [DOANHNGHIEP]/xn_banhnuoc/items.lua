--[[
    HƯỚNG DẪN THÊM ITEMS VÀO OX_INVENTORY
    
    Copy các items bên dưới vào file: ox_inventory/data/items.lua
    
    Cấu trúc item ox_inventory:
    ['item_name'] = {
        label = 'Tên hiển thị',
        weight = 100,           -- Trọng lượng (gram)
        stack = true,           -- Có thể xếp chồng không
        close = true,           -- Đóng inventory khi dùng
        description = 'Mô tả',  -- Mô tả item
        consume = 1,            -- Số lượng tiêu thụ khi dùng (0 = không tiêu thụ)
        
        -- Tùy chọn cho thức ăn/đồ uống (cần thêm vào server export)
        -- client = { ... }     -- Client-side effects
        -- server = { ... }     -- Server-side effects
    },
]]

-- =============================================
-- NGUYÊN LIỆU QUÁN NƯỚC (bar - job: quannuoc)
-- =============================================

--[[
    -- Sản phẩm hoàn chỉnh
    ['nuoc_cam'] = {
        label = 'Nước cam',
        weight = 250,
        stack = true,
        close = true,
        description = 'Nước cam tươi mát, giải khát',
        consume = 1,
    },

    -- Nguyên liệu
    ['nuoc_cam_nguyen_chat'] = {
        label = 'Nước cam nguyên chất',
        weight = 200,
        stack = true,
        close = false,
        description = 'Nước cam nguyên chất chưa pha chế',
    },

    ['ly'] = {
        label = 'Ly',
        weight = 50,
        stack = true,
        close = false,
        description = 'Ly nhựa dùng để đựng đồ uống',
    },

    ['ong_hut'] = {
        label = 'Ống hút',
        weight = 5,
        stack = true,
        close = false,
        description = 'Ống hút giấy thân thiện môi trường',
    },

    ['duong'] = {
        label = 'Đường',
        weight = 50,
        stack = true,
        close = false,
        description = 'Đường trắng tinh luyện',
    },
]]

-- =============================================
-- NGUYÊN LIỆU NHÀ HÀNG (restaurant - job: quanan)
-- =============================================

--[[
    -- Sản phẩm hoàn chỉnh
    ['com_tam'] = {
        label = 'Cơm tấm',
        weight = 450,
        stack = true,
        close = true,
        description = 'Cơm tấm sườn bì chả, đặc sản Sài Gòn',
        consume = 1,
    },

    -- Nguyên liệu
    ['suon_nuong'] = {
        label = 'Sườn nướng',
        weight = 200,
        stack = true,
        close = false,
        description = 'Sườn heo đã được tẩm ướp và nướng chín',
    },

    ['hop_com'] = {
        label = 'Hộp cơm',
        weight = 30,
        stack = true,
        close = false,
        description = 'Hộp xốp đựng cơm mang đi',
    },

    ['dung_cu_an_uong'] = {
        label = 'Dụng cụ ăn uống',
        weight = 20,
        stack = true,
        close = false,
        description = 'Bộ muỗng nĩa dùng một lần',
    },

    ['gao'] = {
        label = 'Gạo',
        weight = 100,
        stack = true,
        close = false,
        description = 'Gạo tấm đã vo sạch',
    },
]]

-- =============================================
-- ITEMS SHOP BÁN (config trong Config.Shops)
-- =============================================

--[[
    ['ciga'] = {
        label = 'Thuốc lá',
        weight = 20,
        stack = true,
        close = true,
        description = 'Một điếu thuốc lá',
    },

    ['bao_thuoc_lion'] = {
        label = 'Bao thuốc Lion',
        weight = 100,
        stack = true,
        close = true,
        description = 'Bao thuốc lá hiệu Lion',
    },

    ['coco_bar'] = {
        label = 'Coco Bar',
        weight = 200,
        stack = true,
        close = true,
        description = 'Đồ uống dừa tươi mát',
        consume = 1,
    },

    -- RƯỢU VANG QUÁN BAR (quanbar)
    ['red_wine_glass'] = {
        label = 'Ly Rượu Vang Đỏ',
        weight = 200,
        stack = true,
        close = true,
        description = 'Một ly rượu vang đỏ thơm nồng, quyến rũ',
        consume = 1,
    },

    ['white_wine_glass'] = {
        label = 'Ly Rượu Vang Trắng',
        weight = 200,
        stack = true,
        close = true,
        description = 'Một ly rượu vang trắng thanh mát, tinh tế',
        consume = 1,
    },

    ['rose_wine_glass'] = {
        label = 'Ly Rượu Vang Hồng',
        weight = 200,
        stack = true,
        close = true,
        description = 'Một ly rượu vang hồng ngọt ngào, lãng mạn',
        consume = 1,
    },
]]

-- =============================================
-- VÍ DỤ ITEM VỚI HIỆU ỨNG (cần thêm vào server)
-- =============================================

--[[
    -- Item với hiệu ứng hồi máu/khát
    ['com_tam'] = {
        label = 'Cơm tấm',
        weight = 450,
        stack = true,
        close = true,
        description = 'Cơm tấm sườn bì chả, đặc sản Sài Gòn',
        consume = 1,
        
        -- Nếu dùng esx_status hoặc qb-status
        -- Thêm vào ox_inventory/modules/items/server.lua:
        -- exports.ox_inventory:UseItem('com_tam', function(source, item)
        --     TriggerClientEvent('hud:client:SetFood', source, 100000)
        --     exports.ox_inventory:RemoveItem(source, 'com_tam', 1)
        -- end)
    },

    ['nuoc_cam'] = {
        label = 'Nước cam',
        weight = 250,
        stack = true,
        close = true,
        description = 'Nước cam tươi mát, giải khát',
        consume = 1,
        
        -- Thêm vào ox_inventory/modules/items/server.lua:
        -- exports.ox_inventory:UseItem('nuoc_cam', function(source, item)
        --     TriggerClientEvent('hud:client:SetThirst', source, 100000)
        --     exports.ox_inventory:RemoveItem(source, 'nuoc_cam', 1)
        -- end)
    },
]]

--[[
    =============================================
    CÁCH THÊM ITEM VÀO OX_INVENTORY:
    =============================================
    
    1. Mở file: ox_inventory/data/items.lua
    
    2. Tìm return { } và thêm items vào bên trong
    
    3. Ví dụ:
       return {
           -- Items có sẵn của ox_inventory...
           
           -- Thêm items mới ở đây:
           ['nuoc_cam'] = {
               label = 'Nước cam',
               weight = 250,
               stack = true,
               close = true,
               description = 'Nước cam tươi mát',
           },
           
           ['com_tam'] = {
               label = 'Cơm tấm',
               weight = 450,
               stack = true,
               close = true,
               description = 'Cơm tấm sườn bì chả',
           },
           
           -- ... các items khác
       }
    
    4. Restart ox_inventory hoặc server để áp dụng
    
    =============================================
    THÊM HÌNH ẢNH CHO ITEMS:
    =============================================
    
    1. Đặt file hình vào: ox_inventory/web/images/
    2. Tên file phải trùng với tên item: nuoc_cam.png, com_tam.png
    3. Kích thước đề xuất: 100x100 px hoặc 200x200 px
    4. Định dạng: PNG với nền trong suốt
    
    Hoặc sử dụng URL hình ảnh từ config:
    Config.GlobalSettings.itemImageUrl = 'https://your-url/items/'
]]
