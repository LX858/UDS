Config = {}
-------------------------------------------
-- exports['Zc_SwordFlag']:CheckFlag()   --- ** Lệnh kiểm tra có đang ở trong sự kiện không
-- TriggerEvent('zcSword_Auto', 'Random hoặc Select', số đội , thời gian (phút))  ---- Bật auto event
-- TriggerEvent('zcSword_Auto', 'Random', 2 , 1)  ---- Bật auto event

-- ░█████╗░░█████╗░███╗░░░███╗███╗░░░███╗░█████╗░███╗░░██╗██████╗░
-- ██╔══██╗██╔══██╗████╗░████║████╗░████║██╔══██╗████╗░██║██╔══██╗
-- ██║░░╚═╝██║░░██║██╔████╔██║██╔████╔██║███████║██╔██╗██║██║░░██║
-- ██║░░██╗██║░░██║██║╚██╔╝██║██║╚██╔╝██║██╔══██║██║╚████║██║░░██║
-- ╚█████╔╝╚█████╔╝██║░╚═╝░██║██║░╚═╝░██║██║░░██║██║░╚███║██████╔╝
-- ░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

Config.Commands = {
    startUI = 'cuopco',
    startNoUI = 'cuopco2', -- /cuopco2 <Random|Select> <số đội>  ví dụ: cuopco2 Select 2
    stop = 'dungcuopco' -- Dừng sự kiện
}
Config.AdminAce = 'AdminMenu' -- Quyền ACE của group.admin trong server.cfg
Config.Sounds = 'opening.ogg'
Config.Volume = 0.1
Config.JoinWaitSeconds = 600
Config.MaxPlayersPerTeam = 40
Config.Dimension = 1
Config.StartPoint = vector3(-1525.6219, -2934.9248, 13.9444)
Config.Distance = 80
Config.FreezeOnWarpSeconds = 10
Config.PassiveSeconds = 10
Config.LockOutfit = true
Config.OutfitCheckIntervalSeconds = 3
Config.GameDurationMinutes = 10
Config.ScorePerSecondHoldingFlag = 5
Config.PickupProgressSeconds = 3
Config.FlagPickupProgressSeconds = 10
Config.NewSwordRespawnSeconds = 3
Config.ReviveDelaySeconds = 10
Config.Revive = {
    tries = 3,
    retryDelayMs = 500
}
Config.TeleportBackOnOutOfBounds = true
Config.KillOnOutOfBounds = true
Config.CancelIfPlayersLessOrEqual = 0
-------------------------------------------



----- ███████╗██╗░░░░░░█████╗░░██████╗░---
----- ██╔════╝██║░░░░░██╔══██╗██╔════╝░---
----- █████╗░░██║░░░░░███████║██║░░██╗░---
----- ██╔══╝░░██║░░░░░██╔══██║██║░░╚██╗---
----- ██║░░░░░███████╗██║░░██║╚██████╔╝---
----- ╚═╝░░░░░╚══════╝╚═╝░░╚═╝░╚═════╝░---


Config.MinusFlagSword = 1 --- Ví dụ có 6 đội, muốn bớt bao nhiêu cờ/kiếm
Config.FlagText = "~g~ Dem diem"
Config.FlagSword = 'pmap_sword_1'
Config.SwordFloatOffset = 0.5
Config.FlagSwordFloatOffset = 0.5
Config.SwordSpawnIntervalMs = 5000 --- Khi bắt đầu sự kiện sẽ spawn kiếm dần dần theo khoảng thời gian (ms)
Config.SwordOutOfBoundsPadding = 15 -- Khoảng cách kéo kiếm vào trong so với mép vòng

---------------------------------
Config.MinusPoint = 10
Config.MaxSword = 20
Config.Sword =
{ --- Có 12 loại buff như ví dụ, một số loại không có BuffTime
    [1] = {
        Sword = 'pmap_sword_5',
        Percent = 50,
        Buff = 'X3',
        TextBuff = 'Diem x3',
        BuffTime = 100
    },
    [2] = {
        Sword = 'pmap_sword_2',
        Percent = 50,
        Buff = 'MinusPoint',
        TextBuff = 'Cat diem',
        BuffTime = 10
    },
    [3] = {
        Sword = 'pmap_sword_2',
        Percent = 50,
        Buff = 'X2',
        TextBuff = 'Diem x2',
        BuffTime = 10
    },
    [4] = {
        Sword = 'pmap_sword_3',
        Percent = 50,
        Buff = 'Armour',
        TextBuff = 'Tang giap'

    },
    [5] = {
        Sword = 'pmap_sword_4',
        Percent = 50,
        Buff = 'Heal',
        TextBuff = 'Tang mau'

    },
    [6] = {
        Sword = 'pmap_sword_6',
        Percent = 50,
        Buff = 'Revive',
        TextBuff = 'Hoi sinh dong doi'

    },
    [7] = {
        Sword = 'pmap_sword_7',
        Percent = 50,
        Buff = 'Fast',
        TextBuff = 'Chay nhanh',
        BuffTime = 10
    },

    [8] = {
        Sword = 'pmap_sword_8',
        Percent = 50,
        Buff = 'Drunk',
        TextBuff = 'Say ruou',
        BuffTime = 10
    },
    [9] = {
        Sword = 'pmap_sword_5',
        Percent = 50,
        Buff = 'Stunt',
        TextBuff = 'Choang',
        BuffTime = 5
    },
    [10] = {
        Sword = 'pmap_sword_4',
        Percent = 50,
        Buff = 'Freeze',
        TextBuff = 'Dong cung',
        BuffTime = 5
    },
    [11] = {
        Sword = 'pmap_sword_3',
        Percent = 30,
        Buff = 'Onfire',
        TextBuff = 'Boc chay',
        BuffTime = 5
    },
    [12] = {
        Sword = 'pmap_sword_2',
        Percent = 10,
        Buff = 'SetCoord',
        TextBuff = 'Keo ve diem xuat phat'
    }

}




----- ████████╗███████╗░█████╗░███╗░░░███╗-----
----- ╚══██╔══╝██╔════╝██╔══██╗████╗░████║-----
----- ░░░██║░░░█████╗░░███████║██╔████╔██║-----
----- ░░░██║░░░██╔══╝░░██╔══██║██║╚██╔╝██║-----
----- ░░░██║░░░███████╗██║░░██║██║░╚═╝░██║-----
----- ░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝-----

Config.TeamData = {
    [1] = {
        TeamName = 'Doi Do',
        PicTeam =
        'https://cdn.discordapp.com/attachments/1232254505580761108/1234167623709753475/Group_1321316035.png?ex=667101eb&is=666fb06b&hm=4ab5f86ed67e469b97dc5080b4ff795eba43b5db6ff4bee318b235ace2ec053c&',
        SpawnPoint = vector3(-1536.8801, -2890.7434, 14.3392),
        ColorTeam = '#D2132A',
        ColorBG = 'linear-gradient(180deg, rgba(0, 0, 0, 0.50) 0%, rgba(210, 19, 42, 0.75) 100%)',
        ColorBGSelect =
        'linear-gradient(90deg, rgba(210, 19, 42, 0.00) 0%, rgba(210, 19, 42, 0.75) 49.48%, rgba(210, 19, 42, 0.00) 100%)',
        ColorSelect = 'rgba(210, 19, 42, 0.5)',
        Cloth = {
            male = {
                ['tshirt_1'] = 46,
                ['tshirt_2'] = 0,
                ['torso_1'] = 87,
                ['torso_2'] = 1,
                ['pants_1'] = 26,
                ['pants_2'] = 0,
                ['arms'] = 1,
                ['arms_2'] = 0
            },
            female = {
                ['tshirt_1'] = 14,
                ['tshirt_2'] = 0,
                ['torso_1'] = 931,
                ['torso_2'] = 10,
                ['pants_1'] = 218,
                ['pants_2'] = 0,
                ['arms'] = 0,
                ['arms_2'] = 0
            }
        }

    },

    [2] = {
        TeamName = 'Doi Xanh',
        PicTeam =
        'https://cdn.discordapp.com/attachments/1232254505580761108/1234167623709753475/Group_1321316035.png?ex=667101eb&is=666fb06b&hm=4ab5f86ed67e469b97dc5080b4ff795eba43b5db6ff4bee318b235ace2ec053c&',
        SpawnPoint = vector3(-1524.6940, -2985.3513, 14.3138),
        ColorTeam = '#233FFF',
        ColorBG = 'linear-gradient(180deg, rgba(0, 0, 0, 0.50) 0%, rgba(35, 63, 255, 1) 100%)',
        ColorBGSelect =
        'linear-gradient(90deg, rgba(35, 63, 255, 0.38) 0%, rgba(35, 63, 255, 0.05) 50%, rgba(35, 63, 255, 0.38) 100%), rgba(0, 0, 0, 0.50)',
        ColorSelect = 'rgba(35, 63, 255, 0.5)',
        Cloth = {
            male = {
                ['tshirt_1'] = 46,
                ['tshirt_2'] = 0,
                ['torso_1'] = 87,
                ['torso_2'] = 2,
                ['pants_1'] = 26,
                ['pants_2'] = 0,
                ['arms'] = 1,
                ['arms_2'] = 0
            },
            female = {
                ['tshirt_1'] = 14,
                ['tshirt_2'] = 0,
                ['torso_1'] = 931,
                ['torso_2'] = 10,
                ['pants_1'] = 218,
                ['pants_2'] = 0,
                ['arms'] = 0,
                ['arms_2'] = 0
            }
        }

    },

    [3] = {
        TeamName = 'Doi Cam',
        PicTeam =
        'https://cdn.discordapp.com/attachments/1232254505580761108/1234167623709753475/Group_1321316035.png?ex=667101eb&is=666fb06b&hm=4ab5f86ed67e469b97dc5080b4ff795eba43b5db6ff4bee318b235ace2ec053c&',
        SpawnPoint = vector3(-1167.11, -28.04, 45.59),
        ColorTeam = '#FF731E',
        ColorBG = 'linear-gradient(180deg, rgba(0, 0, 0, 0.50) 0%, rgba(255, 115, 30, 0.75) 100%)',
        ColorBGSelect =
        'linear-gradient(90deg, rgba(255, 115, 30, 0.38) 0%, rgba(255, 115, 30, 0.05) 50%, rgba(255, 115, 30, 0.38) 100%)',
        ColorSelect = 'rgba(255, 115, 30, 1)',
        Cloth = {
            male = {
                ['tshirt_1'] = 15,
                ['tshirt_2'] = 0,
                ['torso_1'] = 87,
                ['torso_2'] = 3,
                ['pants_1'] = 193,
                ['pants_2'] = 0,
                ['arms'] = 1,
                ['arms_2'] = 0
            },
            female = {
                ['tshirt_1'] = 14,
                ['tshirt_2'] = 0,
                ['torso_1'] = 931,
                ['torso_2'] = 10,
                ['pants_1'] = 218,
                ['pants_2'] = 0,
                ['arms'] = 0,
                ['arms_2'] = 0
            }
        }

    },

    [4] = {
        TeamName = 'Doi Tim',
        PicTeam =
        'https://cdn.discordapp.com/attachments/1232254505580761108/1234167623709753475/Group_1321316035.png?ex=667101eb&is=666fb06b&hm=4ab5f86ed67e469b97dc5080b4ff795eba43b5db6ff4bee318b235ace2ec053c&',
        SpawnPoint = vector3(-1135.57, 70.47, 56.02),
        ColorTeam = '#9638DE',
        ColorBG = 'linear-gradient(180deg, rgba(0, 0, 0, 0.25) 0%, rgba(150, 56, 222, 0.38) 100%)',
        ColorBGSelect =
        'linear-gradient(90deg, rgba(150, 56, 222, 0.38) 0%, rgba(150, 56, 222, 0.05) 50%, rgba(150, 56, 222, 0.38) 100%)',
        ColorSelect = 'rgba(150, 56, 222, 0.5)',
        Cloth = {
            male = {
                ['tshirt_1'] = 15,
                ['tshirt_2'] = 0,
                ['torso_1'] = 87,
                ['torso_2'] = 5,
                ['pants_1'] = 193,
                ['pants_2'] = 0,
                ['arms'] = 1,
                ['arms_2'] = 0
            },
            female = {
                ['tshirt_1'] = 14,
                ['tshirt_2'] = 0,
                ['torso_1'] = 931,
                ['torso_2'] = 10,
                ['pants_1'] = 218,
                ['pants_2'] = 0,
                ['arms'] = 0,
                ['arms_2'] = 0
            }
        }

    }
}



-- ██████╗░███████╗░██╗░░░░░░░██╗░█████╗░██████╗░██████╗░
-- ██╔══██╗██╔════╝░██║░░██╗░░██║██╔══██╗██╔══██╗██╔══██╗
-- ██████╔╝█████╗░░░╚██╗████╗██╔╝███████║██████╔╝██║░░██║
-- ██╔══██╗██╔══╝░░░░████╔═████║░██╔══██║██╔══██╗██║░░██║
-- ██║░░██║███████╗░░╚██╔╝░╚██╔╝░██║░░██║██║░░██║██████╔╝
-- ╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░

----- Nếu không chọn qua UI sẽ nhận thưởng này
Config.Rewards = {}
Config.Rewards.WinnerDefault = {
    [1] = { name = 'test2', count = { 1, 10 } },
    [2] = { name = 'test2', count = { 1, 10 } },
    [3] = { name = 'test2', count = { 1, 10 } }
}

Config.Rewards.Consolation = {
    [1] = { name = 'test1', count = { 1, 10 } },
    [2] = { name = 'test1', count = { 1, 10 } },
    [3] = { name = 'test1', count = { 1, 10 } }
}


------ ██╗░░░██╗██╗------
------ ██║░░░██║██║------
------ ██║░░░██║██║------
------ ██║░░░██║██║------
------ ╚██████╔╝██║------
------ ░╚═════╝░╚═╝------

Config.UISETTING = {
    DetailServer = 'GTAVNRP.NET Cuớp cờ',
    ButtonAcceptEvent = 'U',
    ButtonDeniedEvent = 'X',
    DefaultColorUI = '#B50116',
    InventoryHud = "https://cdn.jsdelivr.net/gh/enderit171/cdn_underlord@main/ox_inventory/images/"
}

Config.Keys = {
    useSkill = 38, -- E
    pickupSword = 38 -- E
}
Config.Textx1 = '~w~Nhan ~r~[ E ]~w~ de su dung ky nang.'
Config.Textx2 = '~r~[ ~w~Nhan Z ~w~ de chon doi ~r~]'
Config.Text = {
    pickupPrompt = "Nhan ~g~ E ~w~ de nhat kiem",
    alreadyHasSword = "~r~ Ban da co 1 thanh kiem roi"
}



----- ██████╗░███████╗██████╗░██╗░░░██╗░██████╗░-----
----- ██╔══██╗██╔════╝██╔══██╗██║░░░██║██╔════╝░-----
----- ██║░░██║█████╗░░██████╦╝██║░░░██║██║░░██╗░-----
----- ██║░░██║██╔══╝░░██╔══██╗██║░░░██║██║░░╚██╗-----
----- ██████╔╝███████╗██████╦╝╚██████╔╝╚██████╔╝-----
----- ╚═════╝░╚══════╝╚═════╝░░╚═════╝░░╚═════╝░-----

Config.Server = {
    debugClearSwordFromCoordMs = 2000,
    startDelayBeforeTimerSeconds = 15
}
