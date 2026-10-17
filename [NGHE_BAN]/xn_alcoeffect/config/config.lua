Config = {}

Config.Framework = 'QBcore'                                -- Framework used: 'ESX' or 'QBcore'
Config.OxLib = true                                     -- Use ox_lib (true/false)

Config.Language = 'en'                                  -- Language
-- Available languages:
-- 'pl'  - Polish
-- 'en'  - English
-- 'fr'  - French
-- 'it'  - Italian
-- 'pt'  - Portuguese
-- 'sv'  - Swedish
-- 'es'  - Spanish
-- 'de'  - German
-- 'tr'  - Turkish

Config.SaveDrunkStatusInMetadata = true                 -- Lưu trạng thái say xỉn vào Player Metadata (Tối ưu cho Qbox / QBCore, không tạo query SQL riêng)
Config.SavaDrunkStatusInSQL = false                     -- (Legacy) Lưu vào bảng SQL riêng nrg_drunkeffect bằng oxmysql (Đặt false khi dùng metadata)
Config.ClearAllEffectAfterDead = true                   

Config.AlcocholItems = {
    ["beer"] = {drunk = 5, notify = 'You drank a beer', prop = 'prop_beer_pissh', propoffset = {x = 0.03, y = -0.195, z = 0.045}, thirst = {"add", 100000}, stress = {"remove", 100}},  

    ["vodka"] = {drunk = 11, notify = 'You chugged a whole bottle of vodka', prop = 'prop_vodka_bottle', propoffset = {x = -0.011, y = -0.255, z = 0.090}, thirst = {"add", 100}, stress = {"remove", 100}}, 
    ["vodka_shot"] = {drunk = 7, notify = 'You took a vodka shot', prop = 'prop_cs_shot_glass', propoffset = {x = 0.12, y = -0.01, z = 0.045}, thirst = {"add", 50}, stress = {"remove", 50}}, 

    ["whiskey"] = {drunk = 12, notify = 'You downed a bottle of whiskey', prop = 'prop_whiskey_bottle', propoffset = {x = 0.02, y = -0.16, z = 0.05}, thirst = {"add", 100}, stress = {"remove", 100}},
    ["whiskey_glass"] = {drunk = 6, notify = 'You drank a glass of whiskey', prop = 'prop_drink_whisky', propoffset = {x = 0.12, y = -0.03, z = 0.055}, thirst = {"add", 50}, stress = {"remove", 50}}, 

    ["tequila"] = {drunk = 10, notify = 'You smashed a bottle of tequila', prop = 'prop_tequila_bottle', propoffset = {x = 0.01, y = -0.26, z = 0.06}, thirst = {"add", 100}, stress = {"remove", 100}}, 
    ["tequila_shot"] = {drunk = 5, notify = 'You took a shot of tequila', prop = 'prop_cs_shot_glass', propoffset = {x = 0.12, y = -0.01, z = 0.045}, thirst = {"add", 50}, stress = {"remove", 50}}, 

    ["wine"] = {drunk = 9, notify = 'You drank a bottle of wine', prop = 'prop_wine_bot_01', propoffset = {x = 0.00, y = -0.25, z = 0.07}, thirst = {"add", 50}, stress = {"remove", 50}}, 
    ["wine_glass"] = {drunk = 5, notify = 'You sipped a glass of wine', prop = 'p_wine_glass_s', propoffset = {x = 0.13, y = -0.045, z = 0.05}, thirst = {"add", 25}, stress = {"remove", 25}}, 
    ["white_wine_glass"] = {drunk = 5, notify = 'You drank a glass of white wine', prop = 'p_wine_glass_s', propoffset = {x = 0.13, y = -0.045, z = 0.05}, thirst = {"add", 25}, stress = {"remove", 25}}, 
    ["rose_wine_glass"] = {drunk = 10, notify = 'You drank a glass of rose wine', prop = 'p_wine_glass_s', propoffset = {x = 0.13, y = -0.045, z = 0.05}, thirst = {"add", 25}, stress = {"remove", 25}}, 
    ["red_wine_glass"] = {drunk = 12, notify = 'You drank a glass of red wine', prop = 'p_wine_glass_s', propoffset = {x = 0.13, y = -0.045, z = 0.05}, thirst = {"add", 25}, stress = {"remove", 25}}, 

    ["rum"] = {drunk = 11, notify = 'You finished off a bottle of rum', prop = 'prop_rum_bottle', propoffset = {x = 0.03, y = -0.24, z = 0.065}, thirst = {"add", 100}, stress = {"remove", 100}},
    ["rum_glass"] = {drunk = 7, notify = 'You drank a glass of rum', prop = 'prop_drink_whisky', propoffset = {x = 0.12, y = -0.03, z = 0.055}, thirst = {"add", 50}, stress = {"remove", 50}}, 

    ["champagne_glass"] = {drunk = 6, notify = 'You drank a glass of champagne', prop = 'prop_drink_champ', propoffset = {x = 0.025, y = -0.16, z = 0.055}, thirst = {"add", 50}, stress = {"remove", 50}}, 
    ["mojito"] = {drunk = 4, notify = 'You drank a refreshing mojito', prop = 'prop_mojito', propoffset = {x = 0.05, y = -0.12, z = 0.06}, thirst = {"add", 25}, stress = {"remove", 25}},   
    ["martini"] = {drunk = 5, notify = 'You sipped a classy martini', prop = 'prop_tequila', propoffset = {x = 0.05, y = -0.10, z = 0.06}, thirst = {"add", 25}, stress = {"remove", 25}}, 
    ["bloody_mary"] = {drunk = 5, notify = 'You had a spicy Bloody Mary', prop = 'prop_daiquiri', propoffset = {x = 0.05, y = -0.10, z = 0.06}, thirst = {"add", 25}, stress = {"remove", 25}}, 
    ["sex_on_the_beach"] = {drunk = 6, notify = 'You enjoyed a fruity Sex on the Beach', prop = 'prop_tequsunrise', propoffset = {x = 0.08, y = -0.07, z = 0.045}, thirst = {"add", 25}, stress = {"remove", 25}}, 
    ["pina_colada"] = {drunk = 6, notify = 'You had a tropical Piña Colada', prop = 'prop_tequsunrise', propoffset = {x = 0.08, y = -0.07, z = 0.045}, thirst = {"add", 25}, stress = {"remove", 25}}, 
}


Config.DropDrunkLevelTime = 60                          -- Khoảng thời gian (giây) giữa mỗi lần giảm nồng độ cồn
Config.DropDrunkLevelCount = 1                           -- Lượng nồng độ cồn giảm sau mỗi DropDrunkLevelTime (giảm 1/100 mỗi 60s)

Config.DrunkStageOneFrom = 1                            -- Giai đoạn 1 (hơi say) bắt đầu từ mức nồng độ cồn này (1 - 100)
Config.DrunkStageTwoFrom = 20                           -- Giai đoạn 2 (say) bắt đầu từ mức nồng độ cồn này (1 - 100)
Config.DrunkStageThreeFrom = 35                         -- Giai đoạn 3 (rất say) bắt đầu từ mức nồng độ cồn này (1 - 100)
Config.DrunkStageFourFrom = 55                          -- Giai đoạn 4 (say bí tỉ) bắt đầu từ mức nồng độ cồn này (trên 50%)

Config.Vomit = true                                     -- Bật tính năng nôn khi nồng độ cồn giảm từ giai đoạn 4 xuống giai đoạn 3
Config.VomitLos = 70                                    -- Tỷ lệ 70% xảy ra nôn khi nồng độ cồn giảm từ giai đoạn 4 xuống giai đoạn 3

Config.BwFromOverDrink = true                           -- Bật tính năng bất tỉnh (BW) khi uống quá nhiều
Config.BwOverDrinkCount = 75                            -- Mức nồng độ cồn khiến người chơi tự động bất tỉnh (BW) (75/100)
Config.BwOverDrinkPassProcent = 95                      -- Mức nồng độ cồn chắc chắn bất tỉnh nếu vượt qua (95/100)
Config.ProcentForBw = 50                                -- Tỷ lệ (%) bị bất tỉnh — hiện không được sử dụng

Config.CarDriveDifficultWhenDrunk = true                -- Bật hiệu ứng khó điều khiển phương tiện khi say
Config.CarDriveDefficultOver = 20                       -- Mức nồng độ cồn bắt đầu khiến việc lái xe khó khăn hơn (20/100)
Config.CarDriveDefficultHold = {min = 200, max = 600}   -- Thời gian duy trì hiệu ứng khó điều khiển xe (mili giây)

Config.RagdollWhenDrunk = true                          -- Bật hiệu ứng ngã/ragdoll ngẫu nhiên khi say
Config.RagdollOverDrunk = 40                            -- Mức nồng độ cồn bắt đầu kích hoạt ragdoll ngẫu nhiên (40/100)
Config.NextRagdollRandomTimer = {min = 20, max = 40}    -- Thời gian chờ trước lần ragdoll tiếp theo (giây)
Config.RagdollRandomTimer = {min = 1, max = 5}          -- Thời gian bị ragdoll mỗi lần (giây)

Config.LostControlFromOverDrink = true                  -- Bật tính năng mất kiểm soát khi say nặng
Config.LostControlAction = true                         -- Tạm thời vô hiệu hóa chuột và bàn phím theo từng khoảng thời gian khi người chơi say nặng
Config.LostControlCount = 55                            -- Mức nồng độ cồn bắt đầu kích hoạt trạng thái mất kiểm soát (55/100)
Config.LostControlRadialToMove = 500.0                  -- Bán kính mà người chơi có thể tự di chuyển ngẫu nhiên
Config.LostControlTimeOut = 80                          -- Thời gian tối đa trước khi trả lại quyền điều khiển nếu chưa đến đích (giây)
Config.ProcentForLostControl = 50                       -- Tỷ lệ (%) xảy ra mất kiểm soát khi đủ điều kiện


Config.BreathalyzerItemName = 'breathalyzer'            -- Tên vật phẩm dùng để đo nồng độ cồn
Config.BreathalyzerCheckTimer = 10                      -- Thời gian thực hiện kiểm tra nồng độ cồn (giây)


Config.StomachLavageTarget = false                      -- Bật tính năng rửa dạ dày thông qua hệ thống target; export vẫn hoạt động dù để false
Config.StomachLavageTargetType = 'ox_target'            -- Hệ thống target sử dụng: 'ox_target' hoặc 'qb-target'
Config.StomachLavageTargetAllow = {'ambulance'}         -- Các job được phép thực hiện rửa dạ dày thông qua target