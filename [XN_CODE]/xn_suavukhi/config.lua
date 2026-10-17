Config = {}

-- Danh sách các bộ sửa chữa và vũ khí tương ứng
-- Bạn có thể dễ dàng thêm nhiều bộ sửa vũ khí khác tại đây
Config.RepairKits = {
    ['bosuavukhi_cole'] = {
        label = 'Bộ Sửa Cờ Lê',
        weapon = 'WEAPON_WRENCH',          -- Tên item vũ khí trong ox_inventory
        weaponLabel = 'Cờ Lê',              -- Tên hiển thị
        icon = 'wrench',                    -- Icon FontAwesome
        duration = 5000,                    -- Thời gian sửa chữa (ms)
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_ped',
        },
    },
    ['bosuavukhi_machete'] = {
        label = 'Bộ Sửa Machete',
        weapon = 'WEAPON_MACHETE',          -- Tên item vũ khí trong ox_inventory
        weaponLabel = 'Machete (Dao Rựa)',  -- Tên hiển thị
        icon = 'hammer',                    -- Icon FontAwesome
        duration = 5000,                    -- Thời gian sửa chữa (ms)
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_ped',
        },
    },
    -- Ví dụ thêm bộ sửa vũ khí khác:
    -- ['bosuavukhi_bat'] = {
    --     label = 'Bộ Sửa Gậy Bóng Chày',
    --     weapon = 'WEAPON_BAT',
    --     weaponLabel = 'Gậy Bóng Chày',
    --     icon = 'baseball-bat-ball',
    --     duration = 5000,
    --     anim = {
    --         dict = 'mini@repair',
    --         clip = 'fixing_a_ped',
    --     },
    -- },
}
