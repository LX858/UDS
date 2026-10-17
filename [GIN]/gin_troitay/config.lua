Config = {}

-- Danh sách item sử dụng trong script
Config.Items = {
    DayThung = 'day_thung', -- Dây thừng: Cho phép chạy và nhảy
    DayCuoc  = 'day_cuoc',  -- Dây cước: Cho phép chạy, KHÔNG cho phép nhảy
    DaoCat   = 'dao_cat'    -- Dao cắt: Dùng để tháo/cắt trói
}

-- Bật true để TẮT minigame giúp test nhanh (Debug Mode)
Config.DebugDisableMinigame = false

-- Tỷ lệ % mất dây khi trói thành công (0 đến 100, 50 = 50% còn / 50% mất)
Config.RopeLoseChance = 100

-- Tỷ lệ % mất dao cắt khi cắt dây trói (0 đến 100, 50 = 50% còn / 50% mất)
Config.KnifeLoseChance = 50

-- Cấu hình minigame (ox_lib skillCheck cho tự cởi trói)
Config.Minigames = {
    -- Minigame khi bản thân tự cởi trói bằng dao
    SelfUntie = { 'medium', 'hard' }
}

-- Cấu hình Minigame Đối Kháng Kéo Co Trói Tay (Tug of War giữa 2 người chơi)
Config.DuelMinigame = {
    Duration = 10000,     -- Thời gian thi đấu đối kháng (10,000ms = 10 giây)
    PushPower = 4,        -- Mỗi lần spam phím E sẽ nhích 4% tiến trình
    InitialProgress = 0,  -- Vạch xuất phát ở 0%
    TyerWinTarget = 60,   -- Người trói đẩy vạch từ 0% đạt mốc 60% trở lên khi hết giờ là Thắng
    TargetWinTarget = 0   -- Nạn nhân giữ vạch dưới 60% khi hết giờ là Thắng (Thoát)
}


-- Thời gian thanh tiến trình trói người chơi (ms)
Config.TieDuration = 3000

-- Thời gian thanh tiến trình cắt dây trói người khác (ms)
Config.CutRopeDuration = 3000

-- Thời gian thanh tiến trình tự cởi trói (ms)
Config.SelfUntieDuration = 3000

-- Khoảng cách tối đa cho phép giữa người trói và nạn nhân (meters)
Config.MaxDistance = 3.0

-- Cấu hình phạt khi người trói bị thua game
Config.SlapOnLose = true        -- Bật/tắt người bị trói tát người trói khi thua minigame
Config.SlapDamage = 10          -- Máu người trói bị trừ khi bị tát
Config.SlapRagdollTime = 1500    -- Thời gian giữ ngã (ms) sau animation

-- Cấu hình Animation
Config.Animations = {
    -- Animation của người thực hiện trói
    Tying = {
        dict = 'mp_arresting',
        clip = 'a_uncuff'
    },
    -- Animation của người bị trói tay phía sau
    Tied = {
        dict = 'mp_arresting',
        clip = 'idle'
    },
    -- Animation khi cắt dây trói
    Cutting = {
        dict = 'amb@medic@standing@kneel@base',
        clip = 'base'
    },
    -- Animation người bị trói vung tay tát
    SlapAttacker = {
        dict = 'melee@unarmed@streamed_variations',
        clip = 'plyr_takedown_front_slap'
    },
    -- Animation người trói bị tát và ngã xuống
    SlapVictim = {
        dict = 'melee@unarmed@streamed_variations',
        clip = 'victim_takedown_front_slap'
    }
}

-- Danh sách các job ban ngành không được phép bị trói
Config.WhitelistedJobs = {
    ['police'] = false,
    ['ambulance'] = true
}

-- Thông báo (Notifications)
Config.Locales = {
    TargetAlreadyTied   = 'Người chơi này đã bị trói rồi!',
    TargetNotTied       = 'Người chơi này không bị trói!',
    TyingFailed         = 'Trói thất bại!',
    TyingSuccess        = 'Bạn đã trói người chơi thành công!',
    YouHaveBeenTied     = 'Bạn đã bị trói tay!',
    SelfUntieSuccess    = 'Bạn đã tự cắt dây trói thành công!',
    SelfUntieFailed     = 'Tự cởi trói thất bại!',
    OtherUntieSuccess   = 'Bạn đã cắt dây trói giải cứu người chơi!',
    YouHaveBeenUntied   = 'Bạn đã được giải cởi trói!',
    NoKnife             = 'Bạn cần có Con Dao (dao_cat) để cắt dây!',
    NoRope              = 'Bạn không có loại dây này!',
    TooFar              = 'Người chơi ở quá xa hoặc đã bỏ chạy!',
    CannotTieJob        = 'Không thể trói người thuộc ban ngành này!'
}
