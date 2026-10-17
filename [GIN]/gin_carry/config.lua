Config = {}

-- Tên item yêu cầu trong ox_inventory để vác người chơi
Config.ItemName = 'carry_item'

-- Cấu hình Animation (Vác người trên vai - Fireman Carry)
Config.Animations = {
    carrier = {
        dict = 'missfinale_c2mcs_1',
        anim = 'fin_c2_mcs_1_camman',
        flag = 49 -- Loop + Thân trên + Cho phép di chuyển
    },
    target = {
        dict = 'nm',
        anim = 'firetoss_drop_p2',
        flag = 33 -- Loop + Thân bất động gục trên vai
    }
}

-- Cấu hình vị trí gắn người chơi được vác lên vai
-- Bone 0: SKEL_ROOT (Gốc Ped) hoặc 40572 (SKEL_L_Clavicle - Vai trái)
Config.Attach = {
    bone = 0,
    pos = vector3(0.27, 0.15, 1.53), -- Z = 0.63 nâng cơ thể lên nằm chuẩn trên vai
    rot = vector3(0.0, 0.0, 0.0)
}

-- Khoảng cách tối đa để tương tác (meters)
Config.MaxDistance = 3.0

-- Phím tắt để thả người chơi (Mặc định: Phím X)
Config.DropKey = 'X'

-- Ngôn ngữ & Thông báo (Locales)
Config.Locales = {
    target_label = 'Vác người chơi (Cần item)',
    target_icon = 'fa-solid fa-hands-holding',
    no_item = 'Bạn cần có vật phẩm vác người!',
    target_not_dead = 'Người chơi này chưa chết!',
    already_carrying = 'Bạn đang vác một người chơi khác!',
    being_carried = 'Bạn đang bị người khác vác!',
    too_far = 'Người chơi ở quá xa!',
    started_carrying = 'Bạn đã bắt đầu vác người chơi.',
    being_carried_notify = 'Bạn đang bị người chơi khác vác.',
    stopped_carrying = 'Đã thả người chơi xuống.',
    target_left = 'Người chơi được vác đã thoát game.',
    carrier_left = 'Người vác bạn đã thoát game.',
    drop_text_ui = '[X] - Thả người chơi xuống'
}
