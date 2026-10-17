Config = {}

Config.framework = 'qb-core' -- Framework
-- Lệnh trigger và kết nối autoeven 
-- TriggerEvent('Zc_Bomberautoeven') 
Config.NewMode = true
Config.ThoiGianTruocKhiNoBomp = 50 -- Thời gian trước khi bom nổ (giây)
-----------------------------------
Config.SoNguoiToiDa = 9999 -- Số người tham gia tối đa
---- Admin ----
Config.LenhBatDau = 'bomber' -- Lệnh để bắt đầu sự kiện bomber
-- Config.CountDown đã bị thay thế bằng waitTime từ UI admin (mặc định: 30 giây)
-- Logic chiến thắng: người còn sống sót cuối cùng (chỉ còn 1 người)

------ Cài đặt Skin ------

Config.DoiSkin = true -- Có đổi skin khi vào sự kiện không? (TẮT ĐI NẾU BỊ CRASH)
Config.TenSkin = 'Bomberman' -- Tên skin sẽ đổi (model ped phải hợp lệ: mp_m_freemode_01, s_m_y_clown_01, a_m_y_hipster_01...)
Config.TenPropBom = 'mondaye_prop_bomb_0_1' -- Tên prop bom
Config.LenhResetSkin = 'pet-shinchan1' -- Nếu người chơi bị lỗi skin hoặc restart script trong sự kiện, gõ lệnh /reskinall

----------------------  Địa điểm sự kiện  ----------------------
Config.JoinNPC = {
    enabled = true,
    model = 'Bomberman',
    coords = vec4(173.7040, -910.8263, 31.2894, 343.2606),
    label = 'Event Bomber',
    icon = 'fas fa-bomb'
}

Config.HienThiVong = true -- Hiển thị vòng tròn sự kiện (false = tắt vòng + tắt kiểm tra boundary)

-- Cấu hình các map
Config.Maps = {
    ['map1'] = {
        name = 'Map 1 - Đảo Bomber',
        coords = vec3(3129.1885, 7159.8750, 308.9947),
        radius = 100.0,
        dimension = 1
    }
}

-- Map mặc định (để tương thích code cũ)
Config.ToaDoDiemSuKien = Config.Maps['map1'].coords
Config.BanKinhVong = 100.0 -- Bán kính vòng sự kiện
Config.PhamViSpawnNgauNhien = 10 -- Phạm vi spawn ngẫu nhiên khi vào (mét)
Config.Dimension = 1 -- Chuyển sang dimension nào? 0 là dimension chính

----------------------  Celebration - Ăn mừng chiến thắng  ----------------------
-- Tọa độ hiển thị ăn mừng sau khi kết thúc game
Config.CelebrationLocations = {
    WinnerBase = vec4(3138.8887, 7118.0938, 314.4570, 240.9976),  -- Vị trí người thắng
    LoserBase  = vec4(3146.2690, 7113.2974, 308.9937, 53.5039)     -- Vị trí người thua
}
Config.CelebrationTime = 15 -- Thời gian ăn mừng (giây)
Config.AntiCheatDistance = 150 -- Khoảng cách tối đa từ spawn (mét) - kiểm tra trong 30s đầu

----------------------  Người cầm bom  ----------------------
Config.SoNguoiCamBom = 1 -- Số người cầm bom trong sự kiện
Config.ChayNhanh = true -- Cầm bom sẽ chạy nhanh hơn
Config.TocDoChay = 1.2 -- Tốc độ chạy (tối đa 1.49, tối thiểu 1.0)
Config.ChayKhongMet = true -- Cầm bom sẽ chạy không mệt
Config.HoiSinhTrongSuKien = true -- Nếu true sẽ hồi sinh người chết trong sự kiện

--------------- Người chơi thường ---------------
Config.ThongBaoVapChan = "<font face='font4thai'>Nhấn ~g~ E ~w~ để đưa bom </font>"
Config.NutVapChan = 38 -- Phím E
Config.ThoiGianNguLon = 5 -- Thời gian ngã lăn (giây)

-----------------Phần thưởng-----------------------------------
-- Tiền thưởng người thắng = (Phí tham gia × Số người chơi) - 10% thuế
-- Tính toán tự động trong server.lua dựa trên phí từ UI admin
Config.TaxPercent = 10 -- Phần trăm thuế (%) trừ từ tổng phí

-- Item thưởng người thắng
Config.PhanThuongItem = {
    -- Item QBCore thường
    items = {
        { name = 'bua_may_man', count = 1, label = 'Xộ mắn mắn' },
    },
    -- Item quần áo qua XNClothes
    clothes = {
        { type = 'shirt', id = 9999, texture = 0, count = 1 }, -- Áo khoác số 9999 (3 cái)
    },
}

---------------------------------------------


-------- Debug -----------
Config.KhongNo = false -- Bom không nổ (dùng để test)
Config.SucManh = 1.0 -- Sức mạnh vụ nổ
Config.ThoiGianChoTruocKhiChuyen = 1 -- Thời gian chờ trước khi chuyển bom (giây)
Config.NgheKhongThamGia = {} -- Các nghề không cần tham gia
Config.TestModeAllDead = false -- Bật lên: phải chết hết mới kết thúc (không tính thắng khi còn 1 người)
Config.BomNoCodinh = true -- Bật: thời gian bom tiếp tục đếm khi chuyển (A còn 14s → B nhận còn 14s). Tắt: reset về thời gian ban đầu mỗi lần chuyển

------------ Hàm hồi sinh người chết ---------------
function revive()
    -- Sử dụng cho QB-Core
    TriggerEvent('hospital:client:Revive')
    Wait(1000)
    SetEntityHealth(PlayerPedId(), 200)
end


--------- Cài đặt âm thanh -----------
Config.SoundURL = "https://github.com/xuannguyen995/sound/blob/main/" -- URL thư mục chứa nhạc (ví dụ: "https://ten-mien.com/sounds/"). Để trống nếu dùng file local trong thư mục html/sounds (yêu cầu bỏ comment 'html/sounds/*.*' trong fxmanifest.lua).

Config.NhacTruocKhiVaoSuKien = {
    TenNhac = 'OpenBomber.mp3',
    AmLuong = 0.1
}
Config.NhacTrongSuKien = {
    TenNhac = 'Bomberrun.mp3',
    AmLuong = 0.2
}
Config.TiengEffectChuyenBom = {
    TenNhac = 'teleport.mp3',
    AmLuong = 0.1
}

Config.NhacKhiCamBom = {
    TenNhac = 'timebomb.mp3',
    AmLuong = 0.1
}

--------- Cài đặt thông báo -----------
Config.ThongBaoSuKien = {
    BatDau = {
        Title = '🎮 SỰ KIỆN BOMBER',
        Message = 'Sự kiện Bomber đã bắt đầu! Hãy đến garage trung tâm tìm NPC Bomber Man để tham gia ngay!',
        Duration = 7000,
        Type = 'success'
    },
    KetThuc = {
        Title = '🏆 KẾT THÚC SỰ KIỆN BOMBER',
        Message = 'Chúc mừng {winner} đã giành chiến thắng!', -- {winner} sẽ được thay bằng tên người thắng
        Duration = 10000,
        Type = 'success'
    }
}


function join(source)
    -- Thêm log người tham gia
    -- Kết nối battle pass người tham gia  
end

function reward(source,item,count)
    -- Thêm log người nhận phần thưởng
end



function Cheatlog(id)
    -- Thêm log người cheat
end