-- ============================================
-- OX_INVENTORY ITEMS - NGHỀ NUÔI THÚ
-- ============================================
-- Copy các items này vào file data/items.lua trong ox_inventory
-- hoặc thêm vào items.lua của server

return {
    -- Item để spawn động vật
    ['trung_thu'] = {
        label = 'Trứng Thú',
        weight = 500,
        stack = true,
        close = true,
        description = 'Trứng dùng để sinh ra thú cưng trong khu vực chăm sóc'
    },

    -- Item thức ăn
    ['thucanthu'] = {
        label = 'Thức Ăn Thú',
        weight = 100,
        stack = true,
        close = true,
        description = 'Thức ăn để cho động vật ăn khi đói'
    },

    -- Phần thưởng từ Heo
    ['conheo'] = {
        label = 'Con Heo',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Con heo trưởng thành đã được chăm sóc'
    },

    -- Phần thưởng từ Bò
    ['conbo'] = {
        label = 'Con Bò',
        weight = 3000,
        stack = true,
        close = true,
        description = 'Con bò trưởng thành đã được chăm sóc'
    },

    -- Phần thưởng từ Deer
    ['aplaca'] = {
        label = 'Alpaca',
        weight = 2500,
        stack = true,
        close = true,
        description = 'Con alpaca trưởng thành đã được chăm sóc'
    },

    -- Item bổ sung (nếu có trong shop)
    ['corgi'] = {
        label = 'Corgi',
        weight = 1500,
        stack = true,
        close = true,
        description = 'Chó Corgi trưởng thành'
    },

    -- ========== PHI NÂNG CẤP ==========
    -- Phi nâng cấp cấp 1 (0->1)
    ['phoinangcap1'] = {
        label = 'Phi Nâng Cấp I',
        weight = 50,
        stack = true,
        close = true,
        description = 'Vật phẩm nâng cấp từ cấp 0 lên cấp 1 (Tỷ lệ 80%)'
    },

    -- Phi nâng cấp cấp 2 (1->2)
    ['phoinangcap2'] = {
        label = 'Phi Nâng Cấp II',
        weight = 50,
        stack = true,
        close = true,
        description = 'Vật phẩm nâng cấp từ cấp 1 lên cấp 2 (Tỷ lệ 50%)'
    },

    -- Phi nâng cấp cấp 3 (2->3)
    ['phoinangcap3'] = {
        label = 'Phi Nâng Cấp III',
        weight = 50,
        stack = true,
        close = true,
        description = 'Vật phẩm nâng cấp từ cấp 2 lên cấp 3 (Tỷ lệ 30%)'
    },

    -- Phi nâng cấp cấp 4 (3->4)
    ['phoinangcap4'] = {
        label = 'Phi Nâng Cấp IV',
        weight = 50,
        stack = true,
        close = true,
        description = 'Vật phẩm nâng cấp từ cấp 3 lên cấp 4 (Tỷ lệ 10%)'
    },

    -- Phi nâng cấp cấp 5 (4->5)
    ['phoinangcap5'] = {
        label = 'Phi Nâng Cấp V',
        weight = 50,
        stack = true,
        close = true,
        description = 'Vật phẩm nâng cấp từ cấp 4 lên cấp 5 (Tỷ lệ 5%)'
    },
}
