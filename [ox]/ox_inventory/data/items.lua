return {
    ['the_da_quy'] = {
        label = 'Thẻ Đá Quý',
        weight = 100,
        client = {},
        stack = true,
        close = true,
        description = "Vật phẩm sự kiện"
    },
    ['the_can_thu'] = {
        label = 'Thẻ Cần Thủ',
        weight = 100,
        client = {},
        stack = true,
        close = true,
        description = "Vật phẩm sự kiện"
    },
    ["cloth_outfit"] = {
        label = 'Trang phục',
        weight = 1,
        stack = false,
        close = false,
        durability = 100
    },
    ["cloth_torso"] = {
        label = 'Áo khoác',
        weight = 0.0,
        stack = false,
        close = false,
        -- degrade = 720,
        durability = 100,
        client = {
            -- export = 'XNClothes.clothes'
        }
    },

    ["cloth_tshirt"] = {
        label = 'Áo thun',
        weight = 0.0,
        stack = false,
        close = false,
        -- degrade = 720,
        durability = 100,
        client = {
            -- export = 'XNClothes.clothes'
        }
    },
    ["cloth_arms"] = {
        label = 'Tay áo',
        weight = 0,
        stack = false,
        close = false,
        -- degrade = 720,
        durability = 100,
        client = {
            -- export = 'XNClothes.clothes'
        }
    },
    ["cloth_pants"] = {
        label = 'Quần',
        weight = 0.0,
        stack = false,
        close = false,
        -- degrade = 720,
        durability = 100,
        client = {
            -- export = 'XNClothes.clothes'
        }
    },
    ["cloth_shoes"] = {
        label = 'Giày',
        weight = 0.80,
        stack = false,
        close = false,
        -- degrade = 720,
        durability = 100,
        client = {
            -- export = 'XNClothes.clothes'
        }
    },

    ["cloth_ears"] = {
        label = "Khuyên tai",
        weight = 0.0,
        stack = false,
        close = false,
        -- degrade = 720,
        durability = 100,
        client = {
            -- export = 'XNClothes.clothes'
        }
    },
    ["cloth_mask"] = {
        label = 'Mặt nạ',
        weight = 0.01,
        stack = false,
        close = false,
        -- degrade = 720,
        durability = 100,
        client = {
            -- export = 'XNClothes.clothes'
        }
    },
    ["cloth_bproof"] = {
        label = 'Áo chống đạn',
        weight = 0.0,
        stack = false,
        close = false,
        -- degrade = 720,
        durability = 100,
        client = {
            -- export = 'XNClothes.clothes'
        }
    },
    ["cloth_chain"] = {
        label = 'Dây chuyền',
        weight = 0.0,
        stack = false,
        close = false,
        -- degrade = 720,
        durability = 100,
        client = {
            -- export = 'XNClothes.clothes'
        }
    },
    ["cloth_bags"] = {
        label = 'Túi xách',
        weight = 0.0,
        stack = false,
        close = false,
        durability = 100,
        client = {
            -- export = 'XNClothes.clothes'
        }
    },
    ["cloth_glasses"] = {
        label = 'Kính',
        weight = 0.01,
        stack = false,
        close = false,
        -- degrade = 720,
        durability = 100,
        client = {
            -- export = 'XNClothes.clothes'
        }
    },
    ["cloth_watches"] = {
        label = 'Đồng hồ',
        weight = 0.01,
        stack = false,
        close = false,
        -- degrade = 720,
        durability = 100,
        client = {
            -- export = 'XNClothes.clothes'
        }
    },
    ["cloth_decals"] = {
        label = 'Phụ kiện',
        weight = 0.05,
        stack = false,
        close = false,
        -- degrade = 720,
        durability = 100,
        client = {
            -- export = 'XNClothes.clothes'
        }
    },
    ["cloth_bracelets"] = {
        label = 'Vòng tay',
        weight = 0.01,
        stack = false,
        close = false,
        -- degrade = 720,
        durability = 100,
        client = {
            -- export = 'XNClothes.clothes'
        }
    },
    ["cloth_helmet"] = {
        label = 'Mũ/Nón',
        weight = 0.05,
        stack = false,
        close = false,
        -- degrade = 720,
        durability = 100,
        client = {
            -- export = 'XNClothes.clothes'
        }
    },
    ["clothes"] = {
        label = 'Quần áo',
        weight = 1,
        stack = false,
        close = true,
        -- degrade = 720,
        durability = 100,
        client = {
            anim = {dict = 'clothingshirt', clip = 'try_shirt_positive_d'},
            usetime = 2500,
            export = 'XNClothes.useClothes'
        }
    },

    ['towremote'] = {
        label = 'điều khiển Kéo',
        weight = 100,
        stack = true,
        close = true
    },
    ['reponote'] = {label = 'towNote', weight = 100, stack = true, close = true},

    ["ve_slost_xe_mod"] = {
        label = "Vé slost xe MOD",
        weight = 100,
        stack = true,
        close = true,
        description = "Slot xe MOD (liên hệ admin)"
    },

    ["ve_doi_xe_r35"] = {
        label = 'Vé đổi xe R35',
        weight = 100,
        stack = true,
    },

    
    ["carry_item"] = {
        label = "Carry",
        weight = 100,
        stack = true,
        close = true,
        description = "Dung de caryry nguoi choi da chet"
    },
    ["ve_doi_xe_rongngao"] = {
        label = 'Vé đổi xe Rồng Ngáo',
        weight = 100,
        stack = true,
    },

    ["nam_tram_ca"] = {
        label = "Vé 500k VNĐ",
        weight = 100,
        stack = true,
        close = true,
        description = "Đổi 500k VNĐ. Liên hệ ADMIN Giao dịch"
    },
    ["ba_tram_ca"] = {
        label = "Vé 300k VNĐ",
        weight = 100,
        stack = true,
        close = true,
        description = "Đổi 300k VNĐ. Liên hệ ADMIN Giao dịch"
    },
    ["hai_tram_ca"] = {
        label = "Vé 200k VNĐ",
        weight = 100,
        stack = true,
        close = true,
        description = "Đổi 200k VNĐ. Liên hệ ADMIN Giao dịch"
    },
    ["mot_tram_ca"] = {
        label = "Vé 100k VNĐ",
        weight = 100,
        stack = true,
        close = true,
        description = "Đổi 100k VNĐ. Liên hệ ADMIN Giao dịch"
    },
    ["ve_quay_slot_xe_mod"] = {
        label = "vé quay slot xe Mod",
        weight = 100,
        stack = true,
        close = true,
        description = "vé quay slot xe MOD. Liên hệ ADMIN"
    },

    ["ve_quay_ak_box"] = {
        label = "Vé quay AK Box",
        weight = 100,
        stack = true,
        close = true,
        description = "Quay đồ (dùng thẻ đổi hòm lệnh /mohom)"
    },
    ["ve_quay_skin_ak"] = {
        label = "Vé quay skin AK",
        weight = 100,
        stack = true,
        close = true,
        description = "Quay đồ (dùng thẻ đổi hòm lệnh /mohom)"
    },
    ["son_redrage_green"] = {
        label = "Sơn REDRAGE xanh lá",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu xanh lá cây (vật liệu biến đổi skin súng)"
    },

    ["son_redrage_white"] = {
        label = "Sơn REDRAGE trắng",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu trắng (vật liệu biến đổi skin súng)"
    },

    ["son_redrage_yelow"] = {
        label = "Sơn REDRAGE vàng",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu vàng (vật liệu biến đổi skin súng)"
    },

    ["son_redrage_violet"] = {
        label = "Sơn REDRAGE tím",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu tím (vật liệu biến đổi skin súng)"
    },

    ["son_smile_blue"] = {
        label = "Sơn SMILE xanh biển",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu xanh dương (vật liệu biến đổi skin súng)"
    },

    ["son_smile_red"] = {
        label = "Sơn SMILE đỏ",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu đỏ (vật liệu biến đổi skin súng)"
    },

    ["son_smile_purple"] = {
        label = "Sơn SMILE tím",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu tím (vật liệu biến đổi skin súng)"
    },

    ["son_smile_orange"] = {
        label = "Sơn SMILE cam",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu cam (vật liệu biến đổi skin súng)"
    },

    ["son_smile_green"] = {
        label = "Sơn SMILE xanh lá",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu xanh lá cây (vật liệu biến đổi skin súng)"
    },

    ["son_smile_pink"] = {
        label = "Sơn SMILE hồng",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu hồng (vật liệu biến đổi skin súng)"
    },

    ["son_red_eye_blue"] = {
        label = "Sơn RED EYE Blue",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu xanh dương (vật liệu biến đổi skin súng)"
    },

    ["son_red_eye_red"] = {
        label = "Sơn RED EYE Red",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu đỏ (vật liệu biến đổi skin súng)"
    },

    ["son_red_eye_green"] = {
        label = "Sơn RED EYE Green",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu xanh lá cây (vật liệu biến đổi skin súng)"
    },

    ["son_red_eye_purple"] = {
        label = "Sơn RED EYE Purple",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu tím (vật liệu biến đổi skin súng)"
    },

    ["son_red_eye_yelow"] = {
        label = "Sơn RED EYE Yelow",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu vàng (vật liệu biến đổi skin súng)"
    },

    ["son_red_eye_pink"] = {
        label = "Sơn RED EYE Pink",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu hồng (vật liệu biến đổi skin súng)"
    },

    ["son_red_eye_orange"] = {
        label = "Sơn RED EYE Orange",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu cam (vật liệu biến đổi skin súng)"
    },

    ["son_red_eye_grey"] = {
        label = "Sơn RED EYE Grey",
        weight = 100,
        stack = true,
        close = true,
        description = "Màu xám (vật liệu biến đổi skin súng)"
    },

    ["seed"] = {
        label = "Cây giống",
        weight = 1000,
        stack = true,
        close = true
    },
    ["hop_mu"] = {
        label = "Hộp mù",
        weight = 100,
        stack = true,
        close = true,
        description = "Mở ra nhiều phần quà hấp dẫn"
    },
    ["hom_che_ak"] = {
        label = "Hòm chế AK",
        weight = 100,
        stack = true,
        close = true,
        description = "Mở ra nhiều phần quà hấp dẫn"
    },
    ["hom_ak_box"] = {
        label = "Hòm AK",
        weight = 100,
        stack = true,
        close = true,
        description = "Mở ra nhiều phần quà hấp dẫn"
    },
    ["hom_skin_ak"] = {
        label = "Hòm Skin AK",
        weight = 100,
        stack = true,
        close = true,
        description = "Mở ra nhiều phần quà hấp dẫn"
    },
    ["phieu_giam_gia_10"] = {
        label = "Discount 10%",
        weight = 100,
        stack = true,
        close = true,
        description = "10% discount"
    },
    ["phieu_giam_gia_20"] = {
        label = "Discount 20%",
        weight = 100,
        stack = true,
        close = true,
        description = "20% discount"
    },
    ["phieu_giam_gia_30"] = {
        label = "Discount 30%",
        weight = 100,
        stack = true,
        close = true,
        description = "30% discount"
    },
    ["phieu_giam_gia_50"] = {
        label = "Discount 50%",
        weight = 100,
        stack = true,
        close = true,
        description = "50% discount"
    },
    ["the_giveaway"] = {
        label = "Thẻ giveaway",
        weight = 100,
        stack = true,
        close = true,
        description = "Thẻ giveaway /mohom rinh quà khủng"
    },

    ["the_doi_mau_gang"] = {
        label = "Thẻ đổi màu gang",
        weight = 100,
        stack = true,
        close = true,
        description = "Thẻ đổi màu blip gang"
    },

    ["qua_gang_1"] = {
        label = "Quà Xã đoàn 1",
        weight = 1000,
        stack = true,
        close = true,
        description = "Phần quà hỗ trợ cho xã đoàn có trên 10 thành viên đạt thời gian hoạt động trên 72h"
    },

    ["qua_gang_2"] = {
        label = "Quà Xã đoàn 2",
        weight = 1000,
        stack = true,
        close = true,
        description = "Phần quà hỗ trợ cho xã đoàn có trên 20 thành viên đạt thời gian hoạt động trên 72h"
    },

    ["qua_gang_3"] = {
        label = "Quà Xã đoàn 3",
        weight = 1000,
        stack = true,
        close = true,
        description = "Phần quà hỗ trợ cho xã đoàn có trên 30 thành viên đạt thời gian hoạt động trên 72h"
    },

    ["xe_gang_1"] = {
        label = "Xe xã đoàn LV1",
        weight = 1000,
        stack = true,
        close = true,
        description = "Phần quà hỗ trợ cho xã đoàn có trên 10 thành viên đạt thời gian hoạt động trên 72h"
    },

    ["xe_gang_2"] = {
        label = "Xe xã đoàn LV2",
        weight = 1000,
        stack = true,
        close = true,
        description = "Phần quà hỗ trợ cho xã đoàn có trên 20 thành viên đạt thời gian hoạt động trên 72h"
    },

    ["xe_gang_3"] = {
        label = "Xe xã đoàn LV3",
        weight = 1000,
        stack = true,
        close = true,
        description = "Phần quà hỗ trợ cho xã đoàn có trên 30 thành viên đạt thời gian hoạt động trên 72h"
    },

    ["thedoithongtin"] = {
        label = "Thẻ đổi tên",
        weight = 0,
        stack = true,
        close = true,
        description = "Đổi tên khác mà bạn yêu thích <3"
    },
    ['testburger'] = {
        label = 'Test Burger',
        weight = 220,
        degrade = 60,
        client = {
            status = {hunger = 400000},
            anim = 'eating',
            prop = 'burger',
            usetime = 2500,
            export = 'ox_inventory_examples.testburger'
        },
        server = {
            export = 'ox_inventory_examples.testburger',
            test = 'what an amazingly delicious burger, amirite?'
        },
        buttons = {
            {
                label = 'Lick it',
                action = function(slot)
                    print('You licked the burger')
                end
            }, {
                label = 'Squeeze it',
                action = function(slot)
                    print('You squeezed the burger :(')
                end
            }
        },
        consume = 0.3
    },

    ['bandage'] = {
        label = 'Băng gạc',
        weight = 1000,
        stack = true,
        close = true,
        cangive = true,
        allowArmed = true

    },

    ['bandage_lv2'] = {
        label = 'Băng gạc gang',
        weight = 1000,
        stack = true,
        close = true,
        allowArmed = true,
        description = "Băng gạc dành cho xã đoàn"
    },

    ['ao_giap_gang_lv1'] = {
        label = 'Áo giáp LV1',
        weight = 3000,
        stack = true,
        close = true,
        description = "Áo giáp gang LV1 dành cho băng đảng, hồi 50% giáp"
    },

    ['bandagepolice'] = {
        label = 'Băng gạc ngành',
        weight = 500,
        stack = true,
        close = true,
        -- client = {
        -- 	anim = { dict = 'rcmfanatic3', clip = 'kneel_idle_a', flag = 1},--, blendIn = 3.0, blendOut = 1.0, flag = 0 ,playbackRate= 0, lockX=0,lockY=0,lockZ=0 },
        -- 	usetime = 4000,
        -- 	useWhileDead = false,
        -- 	cancel = true,
        -- 	disable = {move = true, car = true, combat = true}
        -- },
        allowArmed = true

    },

    ['black_money'] = {
        label = 'Sao Bẩn',
        description = "Cẩn thận bị bắt đó"
    },

    ['banhmi'] = {
        label = 'Bánh Mì',
        weight = 500,
        cangive = true,
        client = {
            status = {hunger = 500000},
            anim = 'eating',
            prop = 'burger',
            usetime = 10000,
            notification = 'Đã sử dụng một Burger'
        }
    },

    ['balonewbie'] = {
        label = 'Balo Newbie',
        weight = 500,
        cangive = true,
        description = "Nhấn sử dụng để nhận balo tân thủ"
    },

    ['com_ga'] = {
        label = 'Cơm Gà',
        weight = 300,
        client = {
            status = {hunger = 300000},
            anim = 'eating',
            prop = 'burger',
            usetime = 10000,
            notification = 'Đã sử dụng một cơm gà'
        },
        allowArmed = true
    },

    ['cola'] = {
        label = 'eCola',
        weight = 350,
        client = {
            status = {thirst = 200000},
            anim = {dict = 'mp_player_intdrink', clip = 'loop_bottle'},
            prop = {
                model = prop_ecola_can,
                pos = vec3(0.01, 0.01, 0.06),
                rot = vec3(5.0, 5.0, -180.5)
            },
            usetime = 5000
            -- notification = 'You quenched your thirst with cola'
        }
    },

    ['parachute'] = {
        label = 'Parachute',
        weight = 8000,
        stack = false,
        client = {
            anim = {dict = 'clothingshirt', clip = 'try_shirt_positive_d'},
            usetime = 1500
        }
    },

    ['garbage'] = {label = 'Rác thải', stack = true, weight = 100},

    ['paperbag'] = {
        label = 'Paper Bag',
        weight = 1,
        stack = false,
        close = false,
        consume = 0
    },

    ['lenhbai_tl'] = {
        label = 'Thiên long lệnh',
        weight = 1000,
        stack = true,
        close = false,
        description = "Lệnh bài Thiên long (VIP)"

    },

    ['lenhbai_tlvip'] = {
        label = 'Thiên long lệnh',
        weight = 1000,
        stack = true,
        close = false,
        description = "Lệnh bài Thiên long (VIP)"
    },

    ['identification'] = {label = 'Identification'},

    ['panties'] = {
        label = 'Knickers',
        weight = 10,
        consume = 0,
        client = {
            status = {stress = -250000},
            anim = {dict = 'mp_player_intdrink', clip = 'loop_bottle'},
            prop = {
                model = prop_cs_panties_02,
                pos = vec3(0.03, 0.0, 0.02),
                rot = vec3(0.0, -13.5, -1.5)
            },
            usetime = 2500
        }
    },

    ["cigarette"] = {
        label = "Thuốc Lá",
        weight = 50,
        stack = true,
        close = true,
        description = "Thơm ngon như Cáo",
        client = {
            status = {stress = 0},
            anim = {
                dict = 'amb@world_human_smoking@male@male_b@base',
                clip = 'base'
            },
            prop = {
                model = ba_prop_battle_vape_01,
                pos = vec3(-0.0290, 0.0070, -0.0050),
                rot = vec3(91.0, 270.0, -360.0)
            },
            usetime = 5000,
            notification = 'Thuốc lá này hết hạn hãy tìm mua thuốc lá mới ở quán bar nhé !'

        }
    },

    ["id_card"] = {
        label = "Căn Cước",
        weight = 0,
        stack = false,
        close = false,
        description = "Một thẻ chứa tất cả thông tin của bạn để xác định chính bạn",
        client = {}
    },

    
    ["megaphone"] = {
        label = "Megaphone",
        weight = 0,
        stack = false,
        close = false,
        description = "Loa",
        client = {}
    },

    ["license_bike"] = {
        label = "Bằng lái xe",
        weight = 0,
        stack = false,
        close = false,
        description = "Cho phép cho thấy bạn có thể lái xe",
        client = {}
    },

    ["driver_license"] = {
        label = "Bằng lái xe",
        weight = 0,
        stack = false,
        close = false,
        description = "Cho phép cho thấy bạn có thể lái xe",
        client = {}
    },

    ['advalockpicknced'] = {
        label = 'Phá khóa nâng cao',
        weight = 500,
        client = {event = 'lockpick:use'}
    },

    ['lockpick'] = {
        label = 'Lockpick',
        weight = 160,
        client = {event = 'lockpick:use'}
    },

    ['vehiclekey'] = {
        label = 'Chìa khóa xe',
        weight = 100,
        stack = false,
        close = false
    },

    ['keyring'] = {
        label = 'túi chìa khóa',
        weight = 1,
        stack = false,
        close = false,
        consume = 0,
        description = "Dùng để đựng chìa khóa xe"

    },

    ['keys'] = {
        label = 'Vòng khóa',
        weight = 300,
        stack = false,
        close = false,
        description = "Chìa khóa nhà"

    },

    ["bupbe1"] = {
        label = "TINH LINH 1",
        weight = 50,
        stack = false,
        close = false,
        description = "PED TINH LINH TRANG TRÍ.",
        client = {}
    },

    ["bupbe2"] = {
        label = "TINH LINH 2",
        weight = 50,
        stack = false,
        close = false,
        description = "PED TINH LINH TRANG TRÍ.",
        client = {}
    },

    ["bupbe3"] = {
        label = "TINH LINH 3",
        weight = 50,
        stack = false,
        close = false,
        description = "PED TINH LINH TRANG TRÍ.",
        client = {}
    },

    ["bupbe4"] = {
        label = "TINH LINH 4",
        weight = 50,
        stack = false,
        close = false,
        description = "PED TINH LINH TRANG TRÍ.",
        client = {}
    },

    ["bupbe5"] = {
        label = "TINH LINH 5",
        weight = 50,
        stack = false,
        close = false,
        description = "PED TINH LINH TRANG TRÍ.",
        client = {}
    },

    ["bupbe6"] = {
        label = "TINH LINH 6",
        weight = 50,
        stack = false,
        close = false,
        description = "PED TINH LINH TRANG TRÍ.",
        client = {}
    },

    ["bupbe7"] = {
        label = "TINH LINH 7",
        weight = 50,
        stack = false,
        close = false,
        description = "PED TINH LINH TRANG TRÍ.",
        client = {}
    },

    ["bupbe8"] = {
        label = "TINH LINH 8",
        weight = 50,
        stack = false,
        close = false,
        description = "PED TINH LINH TRANG TRÍ.",
        client = {}
    },

    ["bupbe9"] = {
        label = "TINH LINH 9",
        weight = 50,
        stack = false,
        close = false,
        description = "PED TINH LINH TRANG TRÍ.",
        client = {}
    },

    ["bupbe10"] = {
        label = "TINH LINH 10",
        weight = 50,
        stack = false,
        close = false,
        description = "PED TINH LINH TRANG TRÍ.",
        client = {}
    },

    ["bupbe11"] = {
        label = "TINH LINH 11",
        weight = 50,
        stack = false,
        close = false,
        description = "PED TINH LINH TRANG TRÍ.",
        client = {}
    },

    ["bupbe12"] = {
        label = "TINH LINH 12",
        weight = 50,
        stack = false,
        close = false,
        description = "PED TINH LINH TRANG TRÍ.",
        client = {}
    },

    ["phone"] = {
        label = "Iphone 20 Pro Max",
        weight = 500,
        stack = false,
        description = "Iphone 20 Pro Max",
        consume = 0,
        client = {
        }
    },

    ['money'] = {
        label = 'Tiền',
        description = "Đồng tiền từ mồ hôi nước mắt",
        cangive = true
    },

    ['mustard'] = {
        label = 'Gấp đôi canxi',
        weight = 500,
        description = "Uống vào là gấp đôi sức mạnh. Có thể đấm bay admin",
        client = {
            status = {hunger = 400000, thirst = 400000},
            anim = {dict = 'mp_player_intdrink', clip = 'loop_bottle'},
            prop = {
                model = prop_food_mustard,
                pos = vec3(0.01, 0.0, -0.07),
                rot = vec3(1.0, 1.0, -1.5)
            },
            usetime = 10000
            -- notification = 'You.. drank mustard'
        }
    },

    ['nuocsuoi'] = {
        label = 'Nước Lavie',
        weight = 500,
        cangive = true,
        client = {
            status = {thirst = 500000},
            anim = {dict = 'mp_player_intdrink', clip = 'loop_bottle'},
            prop = {
                model = prop_ld_flow_bottle,
                pos = vec3(0.03, 0.03, 0.02),
                rot = vec3(0.0, 0.0, -1.5)
            },
            usetime = 10000,
            cancel = true,
            notification = 'Đã uống một nước lọc và giải khát 50%'
        },
        stack = true,
        allowArmed = true
    },

    ['nuocloc'] = {
        label = 'Nước lọc',
        weight = 500,
        client = {},
        stack = true,
        close = true,
        description = "Nguyên liệu pha trà"
    },

    ['afk_item'] = {
        label = 'Dâu Tây',
        weight = 100,
        stack = true,
        close = true,

    },

    ['the_cau_ca'] = {
        label = 'Thẻ Câu Cá',
        weight = 100,
        client = {},
        stack = true,
        close = true,
        description = "Vật phẩm sự kiện"
    },

    ['the_du_du'] = {
        label = 'Thẻ Du Đủ',
        weight = 100,
        client = {},
        stack = true,
        close = true,
        description = "Vật phẩm sự kiện"
    },

    ['the_hai_cam'] = {
        label = 'Thẻ Hái Cam',
        weight = 100,
        client = {},
        stack = true,
        close = true,
        description = "Vật phẩm sự kiện"
    },

    ['the_dao_da'] = {
        label = 'Thẻ Đào Đá',
        weight = 100,
        client = {},
        stack = true,
        close = true,
        description = "Vật phẩm sự kiện"
    },

    ['the_hoa_mn'] = {
        label = 'Thẻ Hoa Mỹ nhân',
        weight = 100,
        client = {},
        stack = true,
        close = true,
        description = "Vật phẩm sự kiện"
    },

    ['the_pvp'] = {
        label = 'Thẻ PVP',
        weight = 100,
        client = {},
        stack = true,
        close = true,
        description = "Vật phẩm sự kiện"
    },

    ['la_che'] = {
        label = 'Lá Chè',
        weight = 300,
        stack = true,
        close = true,
        description = 'Lá chè tươi, dùng để pha trà',
        client = { image = 'trasua.webp' }

    },

    ['tra_kho'] = {
        label = 'Trà khô',
        weight = 300,
        stack = true,
        close = true,
        description = 'Lá chè đã sơ chế cho quán nước',
        client = { image = 'trasua.webp' }
    },

    ['dua_soche'] = {
        label = 'Dừa sơ chế',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Dừa đã sơ chế cho quán nước và nhà hàng',
        client = { image = 'coconut.webp' }
    },

    ['radio'] = {
        label = 'Radio',
        weight = 500,
        stack = false,
        close = true,
        description = "Dùng để liên lạc nhóm radio."
    },

    ['armour'] = {
        label = 'Bulletproof Vest',
        weight = 3000,
        stack = false,
        client = {
            anim = {dict = 'clothingshirt', clip = 'try_shirt_positive_d'},
            usetime = 3500
        },
        consume = 0
    },

    ['clothing'] = {label = 'Clothing', consume = 0},

    ['mastercard'] = {label = 'Mastercard', stack = false, weight = 10},

    ['scrapmetal'] = {label = 'Scrap Metal', weight = 500},

    ["alive_chicken"] = {
        label = "Gà sống",
        weight = 1000,
        stack = true,
        close = true
    },

    ["ifaks"] = {
        label = "ifaks",
        weight = 200,
        stack = true,
        close = true,
        description = "Dùng để nâng cấp bộ cứu.",
        client = {image = "ifaks.webp"}
    },

    ["painkillers"] = {
        label = "Painkillers",
        weight = 0,
        stack = true,
        close = true,
        description = "For pain you can't stand anymore, take this pill that'd make you feel great again",
        client = {image = "painkillers.webp"}
    },

    ["firstaid"] = {
        label = "First Aid",
        weight = 500,
        stack = true,
        close = true,
        description = "Bạn có thể sử dụng bộ dụng cụ sơ cứu này để cứu chữa mọi người",
        client = {image = "firstaid.webp"}
    },

    ["phoinangcap1"] = {
        label = "Phôi vải nâng cấp 1",
        weight = 100,
        stack = true,
        close = true,
        metadata = {DoHiem = 'Common'}
    },

    ["phoinangcap2"] = {
        label = "Phôi vải nâng cấp 2",
        weight = 100,
        stack = true,
        close = true,
        metadata = {DoHiem = 'Uncommon'}
    },

    ["phoinangcap3"] = {
        label = "Phôi vải nâng cấp 3",
        weight = 100,
        stack = true,
        close = true,
        metadata = {DoHiem = 'Rare'}
    },

    ["phoinangcap4"] = {
        label = "Phôi vải nâng cấp 4",
        weight = 100,
        stack = true,
        close = true,
        metadata = {DoHiem = 'Epic'}
    },

    ["phoinangcap5"] = {
        label = "Phôi vải nâng cấp 5",
        weight = 100,
        stack = true,
        close = true,
        metadata = {DoHiem = 'Legendary'}
    },

    ["traitimvn"] = {
        label = "Tôi yêu Việt Nam",
        weight = 100,
        stack = true,
        close = true,
        description = "Sự kiện 2.9 - Tôi yêu Việt Nam",
        metadata = {DoHiem = 'Legendary'}
    },

    ["dominatoritem"] = {
        label = "Vé đổi xe Dominator",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe Dominator",
        metadata = {DoHiem = 'Epic'}
    },

    ["dodge"] = {
        label = "Vé đổi xe DodgeRS",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe Dodge RS",
        metadata = {DoHiem = 'Epic'}
    },

    ["kamachoitem"] = {
        label = "Vé đổi xe Kamacho",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe Kamacho",
        metadata = {DoHiem = 'Epic'}
    },

    ["guardian_card"] = {
        label = "Vé xe guardian",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe guardian",
        metadata = {DoHiem = 'Epic'}
    },

    ["vedoixevf3"] = {
        label = "Vé đổi xe VF3",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe VF3",
        metadata = {DoHiem = 'Epic'}
    },

    ["vedoixevf8"] = {
        label = "Vé đổi xe VF8",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe VF8",
        metadata = {DoHiem = 'Epic'}
    },

    ["ve_doi_xe_outlaw"] = {
        label = "Vé đổi xe Outlaw",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Outlaw",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["vedoixevf9"] = {
        label = "Vé đổi xe VF9",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe VF9",
        metadata = {DoHiem = 'Epic'}
    },

    ["ve_doi_xe_civic"] = {
        label = "Vé đổi xe Civic",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Civic",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_trophy"] = {
        label = "Vé đổi xe Trophy",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Toyota Trophy",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_mustang"] = {
        label = "Vé đổi xe Mustang",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Ford Mustang",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_bmwm5"] = {
        label = "Vé đổi xe BMW M5",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe BMW M5 G60",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_sh350"] = {
        label = "Vé đổi xe SH350i",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe SH350i",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_r34"] = {
        label = "Vé đổi xe R34",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe R34",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_gsx"] = {
        label = "Vé đổi xe GSX",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Mitsubishi Eclipse GSX",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_jackal"] = {
        label = "Vé đổi xe Jackal",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Jackal",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_yaz"] = {
        label = "Vé đổi xe YAZ",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe YAZ",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_dodgecharger"] = {
        label = "Vé đổi xe Dodge Charger",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Dodge Charger",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_suprahong"] = {
        label = "Vé đổi xe Honda S2000",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Honda S2000",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_supracam"] = {
        label = "Vé đổi xe Toyota Supra",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Toyota Supra",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_rx7"] = {
        label = "Vé đổi xe Mazda RX7",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Mazda RX7",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_eclipse"] = {
        label = "Vé đổi xe Eclipse",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Mitsubishi Eclipse",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_supra_equator"] = {
        label = "Vé đổi xe Supra Equator",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Supra Equato",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_evomanz"] = {
        label = "Vé đổi xe Evolution Manz",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Evolution Manz",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_evomanz"] = {
        label = "Vé đổi xe Evolution Manz",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Evolution Manz",
        metadata = {DoHiem = 'Lengendary'}
    },
    
    ["key_tires"] = {
        label = "Vé đổi xe Lancer Evolution",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Lancer Evolution",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["key_spydergts"] = {
        label = "Vé đổi xe Spyder GTS",
        weight = 1000,
        stack = false,
        close = true,
        description = "Vé đổi xe Spyder GTS",
        metadata = {DoHiem = 'Lengendary'}
    },

    ["ve_doi_xe_m8"] = {
        label = "Đổi xe BMW M8",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé Đổi xe BMW M8",
        metadata = {DoHiem = 'Epic'}
    },

    ["ve_doi_xe_jeep"] = {
        label = "Đổi xe JEEP",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé Đổi xe JEEP Rubicon",
        metadata = {DoHiem = 'Epic'}
    },

    ["ve_doi_xe_skyline"] = {
        label = "Vé đổi xe Skyline",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe Skyline",
        metadata = {DoHiem = 'Epic'}
    },

    ["ve_doi_xe_mx5"] = {
        label = "Vé đổi xe MX5",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe MX5",
        metadata = {DoHiem = 'Epic'}
    },

    ["ve_doi_xe_rx7"] = {
        label = "Vé đổi xe RX5",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe RX7",
        metadata = {DoHiem = 'Epic'}
    },

    ["ve_doi_xe_boor"] = {
        label = "Vé đổi xe Karin",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe Karin Boor",
        metadata = {DoHiem = 'Epic'}
    },

    ["manh_gep_mx5"] = {
        label = "mảnh xe MX5",
        weight = 100,
        stack = true,
        close = true,
        description = "Mảnh xe MX5",
        metadata = {DoHiem = 'Uncommon'}
    },

    ["manh_gep_m8"] = {
        label = "mảnh xe BMW M8",
        weight = 100,
        stack = true,
        close = true,
        description = "Mảnh xe BMW M8",
        metadata = {DoHiem = 'Uncommon'}
    },

    ["manh_gep_jeep"] = {
        label = "mảnh xe JEEP",
        weight = 100,
        stack = true,
        close = true,
        description = "Mảnh xe JEEP Rubicon",
        metadata = {DoHiem = 'Uncommon'}
    },

    ["manh_gep_rx7"] = {
        label = "mảnh xe RX7",
        weight = 100,
        stack = true,
        close = true,
        description = "Mảnh xe RX7",
        metadata = {DoHiem = 'Uncommon'}
    },

    ["manh_gep_boor"] = {
        label = "mảnh xe Karin",
        weight = 100,
        stack = true,
        close = true,
        description = "Mảnh xe Karin Boor",
        metadata = {DoHiem = 'Uncommon'}
    },

    ["manh_gep_skyline"] = {
        label = "mảnh xe Skyline",
        weight = 100,
        stack = true,
        close = true,
        description = "Mảnh xe Skyline",
        metadata = {DoHiem = 'Uncommon'}
    },

    ["ve_doi_xe_sanctus"] = {
        label = "Vé đổi xe Sanctus",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe Sanctus",
        metadata = {DoHiem = 'Epic'}
    },

    ["ve_doi_xe_btype2"] = {
        label = "Vé đổi xe btype2",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe btype2",
        metadata = {DoHiem = 'Epic'}
    },

    ["ve_doi_xe_titanh"] = {
        label = "Vé đổi xe Nissan",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe Nissan",
        metadata = {DoHiem = 'Epic'}
    },

    ["hummeritem"] = {
        label = "Vé đổi xe Hummer",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe Hummer",
        metadata = {DoHiem = 'Epic'}
    },

    ["raptoritem"] = {
        label = "Vé đổi xe Raptor",
        weight = 1000,
        stack = true,
        close = true,
        description = "Vé đổi xe Raptor",
        metadata = {DoHiem = 'Epic'}
    },

    ["manhgepraptor"] = {
        label = "Mảnh gép xe Raptor",
        weight = 100,
        stack = true,
        close = true,
        description = "Thu thập đủ 100 mảnh gép bạn có thể đổi xe Raptor",
        metadata = {DoHiem = 'Uncommon'}
    },

    ["manhtatto_s"] = {
        label = "Thẻ tattoo",
        weight = 100,
        stack = true,
        close = true,
        description = "Thu thập mảnh tatto, bạn có thể đổi được những tattoo độc đáo"
    },

    ["manh_gep_civic"] = {
        label = "Mảnh gép Civic",
        weight = 100,
        stack = true,
        close = true,
        description = "Thu thập đủ 100 mảnh gép bạn có thể đổi xe Civic R",
        metadata = {DoHiem = 'Uncommon'}
    },

    ["manh_gep_titanh"] = {
        label = "Mảnh gép Nissan",
        weight = 100,
        stack = true,
        close = true,
        description = "Thu thập đủ 100 mảnh gép bạn có thể đổi xe Nissan",
        metadata = {DoHiem = 'Uncommon'}
    },

    ["manhgephummer"] = {
        label = "Mảnh gép xe Hummer",
        weight = 100,
        stack = true,
        close = true,
        description = "Thu thập đủ 100 mảnh gép bạn có thể đổi xe Hummer",
        metadata = {DoHiem = 'Uncommon'}
    },

    ["xe_ngua"] = {
        label = "Mảnh gép xe Hummer",
        weight = 100,
        stack = true,
        close = true,
        description = "Thu thập đủ 100 mảnh gép bạn có thể đổi xe Hummer",
        metadata = {DoHiem = 'Uncommon'}
    },

    ["manhgepdodge"] = {
        label = "Mảnh gép xe DodgeRS",
        weight = 100,
        stack = true,
        close = true,
        description = "Thu thập đủ 100 mảnh gép bạn có thể đổi xe DodgeRS",
        metadata = {DoHiem = 'Uncommon'}
    },

    ["manhgepkamacho"] = {
        label = "Mảnh gép xe Kamacho",
        weight = 100,
        stack = true,
        close = true,
        description = "Thu thập đủ 100 mảnh gép bạn có thể đổi xe Kamacho",
        metadata = {DoHiem = 'Uncommon'}
    },

    ["manhgep_guardian"] = {
        label = "Mảnh gép guardian",
        weight = 100,
        stack = true,
        close = true,
        description = "Thu thập đủ 150 mảnh gép bạn có thể đổi xe Guardian",
        metadata = {DoHiem = 'Uncommon'}
    },

    ["manhgepdominator"] = {
        label = "Mảnh gép xe Dominator",
        weight = 100,
        stack = true,
        close = true,
        description = "Thu thập đủ 100 mảnh gép bạn có thể đổi xe Dorminator",
        metadata = {DoHiem = 'Uncommon'}
    },

    ["xewave110"] = {
        label = "Xe wave110",
        weight = 100,
        stack = true,
        close = true,
        description = "Sử dụng để đổi xe Wave110",
        metadata = {DoHiem = 'Uncommon'}
    },

    manhghep1 = {
        label = 'Mảnh ghép 1',
        weight = 50,
        stack = true,
        close = true,
        description = 'Mảnh ghép số 1 để hoàn thành bức tranh bí ẩn',
        client = {image = 'manhghep1.webp'}
    },

    manhghep2 = {
        label = 'Mảnh ghép 2',
        weight = 50,
        stack = true,
        close = true,
        description = 'Mảnh ghép số 2 để hoàn thành bức tranh bí ẩn',
        client = {image = 'manhghep2.webp'}
    },

    manhghep3 = {
        label = 'Mảnh ghép 3',
        weight = 50,
        stack = true,
        close = true,
        description = 'Mảnh ghép số 3 để hoàn thành bức tranh bí ẩn',
        client = {image = 'manhghep3.webp'}
    },

    manhghep4 = {
        label = 'Mảnh ghép 4',
        weight = 50,
        stack = true,
        close = true,
        description = 'Mảnh ghép số 4 để hoàn thành bức tranh bí ẩn',
        client = {image = 'manhghep4.webp'}
    },

    manhghep5 = {
        label = 'Mảnh ghép 5',
        weight = 50,
        stack = true,
        close = true,
        description = 'Mảnh ghép số 5 để hoàn thành bức tranh bí ẩn',
        client = {image = 'manhghep5.webp'}
    },

    manhghep6 = {
        label = 'Mảnh ghép 6',
        weight = 50,
        stack = true,
        close = true,
        description = 'Mảnh ghép số 6 để hoàn thành bức tranh bí ẩn',
        client = {image = 'manhghep6.webp'}
    },

    manhghep7 = {
        label = 'Mảnh ghép 7',
        weight = 50,
        stack = true,
        close = true,
        description = 'Mảnh ghép số 7 để hoàn thành bức tranh bí ẩn',
        client = {image = 'manhghep7.webp'}
    },

    manhghep8 = {
        label = 'Mảnh ghép 8',
        weight = 50,
        stack = true,
        close = true,
        description = 'Mảnh ghép số 8 để hoàn thành bức tranh bí ẩn',
        client = {image = 'manhghep8.webp'}
    },

    manhghep9 = {
        label = 'Mảnh ghép 9',
        weight = 50,
        stack = true,
        close = true,
        description = 'Mảnh ghép số 9 để hoàn thành bức tranh bí ẩn',
        client = {image = 'manhghep9.webp'}
    },

    ["binh_xang"] = {
        label = "Bình xăng cứu hộ",
        weight = 1000,
        stack = true
    },

    ["blowpipe"] = {label = "Blowtorch", weight = 2, stack = true, close = true},

    ["bread"] = {
        label = "Bánh mì dân tổ",
        weight = 200,
        stack = true,
        close = true,
        client = {
            status = {hunger = 400000},
            anim = 'eating',
            prop = 'burger',
            usetime = 2500
            -- notification = 'Bạn đang ăn bánh mì'
        },
        allowArmed = true
    },

    ["carokit"] = {label = "Body Kit", weight = 3, stack = true, close = true},

    ["carotool"] = {label = "Tools", weight = 2, stack = true, close = true},

    ["clothe"] = {
        label = "Quần áo",
        weight = 1000,
        stack = true,
        close = true
    },

    ["copper"] = {label = "Đồng", weight = 250, stack = true, close = true},

    ["rubber"] = {label = "Cao Su", weight = 200, stack = true, close = true, description = 'Nguyên liệu khai thác được từ nghề rã xe (Đồ bẩn)'},

    ["silver"] = {label = "Bạc", weight = 300, stack = true, close = true},

    ["go_xe"] = {label = "Gỗ Xẻ", weight = 500, stack = true, close = true},

    ["fabric"] = {label = "Vải", weight = 1000, stack = true, close = true},

    ["fixkit"] = {
        label = "Bộ sửa xe",
        weight = 2000,
        stack = true,
        close = true
    },

    ["fixweapon"] = {
        label = "Bộ sữa vũ khí",
        weight = 2000,
        stack = true,
        close = true
    },

    ["fixtool"] = {
        label = "Repair Tools",
        weight = 2,
        stack = true,
        close = true
    },

    ["gazbottle"] = {
        label = "Gas Bottle",
        weight = 2,
        stack = true,
        close = true
    },

    ["gold"] = {label = "Vàng", weight = 200, stack = true, close = true},

    ["iron"] = {label = "Sắt", weight = 500, stack = true, close = true},

    ["ruou"] = {label = "Rượu", weight = 300, stack = true, close = true},

    ["skin_bat1"] = {
        label = "Skin Gậy Bóng Chày",
        weight = 280,
        stack = true,
        close = true
    },

    ["bangsung"] = {
        label = "Bằng Súng",
        weight = 0,
        stack = true,
        close = true
    },

    ["moi_cau"] = {
        label = "Mồi Câu",
        weight = 200,
        stack = true,
        close = true
    },

    ["can_cau"] = {
        label = "Cần Câu",
        weight = 200,
        stack = false,
        close = true,
        durability = 1.5
        -- consume = 0.2,
    },

    ['stevo_policebadge'] = {
        label = 'Thẻ nghành',
        weight = 250,
        stack = false
    },

    ['tracker'] = {
        label = 'JOB TOOLS',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Một thiết bị để theo dõi nhân viên của các sĩ quan và EMS của bạn'
    },

    ['may_khoan_da'] = {
        label = 'Máy khoan đá',
        weight = 1000,
        stack = false,
        close = true,
        description = 'máy khoan đá',
        durability = 100
    },

    ['can_cau_go'] = {
        label = 'Cần câu gỗ',
        weight = 500,
        stack = false,
        close = true,
        description = 'Cần câu cơ bản làm từ gỗ',
        client = {export = 'xn_cauca.useFishingRod'},
        durability = 100
    },

    ['can_cau_thep'] = {
        label = 'Cần câu thép',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Cần câu chắc chắn làm từ thép',
        client = {export = 'xn_cauca.useFishingRod'},
        durability = 100
    },

    ['can_cau_carbon'] = {
        label = 'Cần câu carbon',
        weight = 600,
        stack = false,
        close = true,
        description = 'Cần câu nhẹ và bền làm từ carbon',
        client = {export = 'xn_cauca.useFishingRod'},
        durability = 100
    },

    ['can_cau_titan'] = {
        label = 'Cần câu titan',
        weight = 700,
        stack = false,
        close = true,
        description = 'Cần câu cao cấp làm từ titan',
        client = {export = 'xn_cauca.useFishingRod'},
        durability = 100
    },

    ['can_cau_vip'] = {
        label = 'Cần câu VIP',
        weight = 500,
        stack = false,
        close = true,
        description = 'Cần câu đặc biệt với độ bền vượt trội',
        client = {export = 'xn_cauca.useFishingRod'},
        durability = 100
    },

    ["giong_ca_thu"] = {
        label = "Giống cá thu",
        weight = 500,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["giong_ca_chim"] = {
        label = "Giống cá Chim",
        weight = 500,
        stack = true,
        close = true
        -- consume = 0.2,
    },

    -- ["giong_ca_ngu"] = {
    -- 	label = "Giống cá Ngừ",
    -- 	weight = 500,
    -- 	stack = true,
    -- 	close = true,
    -- 	-- consume = 0.2,
    -- },
    ["cay_huong"] = {
        label = "Cây hương thường",
        weight = 100,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["cay_huong_luxury"] = {
        label = "Cây hương Luxury",
        weight = 100,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["hat_giong_cay"] = {
        label = "Cây giống",
        weight = 1000,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["xo_rong"] = {
        label = "Xô rỗng",
        weight = 500,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["xo_co_nuoc"] = {
        label = "Xô có nước",
        weight = 500,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["coconut"] = {
        label = "Trái dừa",
        weight = 1000,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["dua_long"] = {
        label = "Trái dừa lòng",
        weight = 2000,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["keo"] = {
        label = "Kéo hái dừa",
        weight = 2000,
        stack = false,
        close = true,
        durability = 100,
        description = "Công cụ hái dừa"
        -- consume = 0.2,
    },
    ["go_quy"] = {
        label = "Gỗ quý",
        weight = 1000,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["go_thuong"] = {
        label = "Gỗ thường",
        weight = 500,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["mu_cay"] = {
        label = "Mũ cây",
        weight = 100,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["thuc_an_ca"] = {
        label = "Thức ăn cá",
        weight = 1000,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["ca_thu_che_bien"] = {
        label = "Cá thu chế biến",
        weight = 500,
        stack = true,
        close = true
        -- consume = 0.2,
    },

    ["ca_ngua"] = {
        label = "Cá ngựa",
        weight = 1000,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["bach_tuoc"] = {
        label = "Bạch tuộc",
        weight = 2000,
        stack = true,
        close = true
        -- consume = 0.2,
    },

    ["tramco"] = {
        label = "Cá trắm cỏ",
        weight = 300,
        stack = true,
        close = true,
        description = "Một loại cá phổ thông sống ở các ao hồ"
        -- consume = 0.2,
    },

    ["rophi"] = {
        label = "Cá rô phi",
        weight = 1000,
        stack = true,
        close = true,
        description = "Một loại cá phổ thông sống ở các ao hồ giá trị trung bình"
        -- consume = 0.2,
    },

    ["cachep"] = {
        label = "Cá chép hồ",
        weight = 2000,
        stack = true,
        close = true,
        description = "Là vua của tầng đáy, giá trị cao"
        -- consume = 0.2,
    },

    ["ca_bong_mu_giong"] = {
        label = "Cá bóng mú giống",
        weight = 1000,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["ca_duoi_giong"] = {
        label = "Cá đuối giống",
        weight = 1000,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["ca_ngu_giong"] = {
        label = "Cá ngừ giống",
        weight = 1000,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["tom_hum_giong"] = {
        label = "Tôm hùm giống",
        weight = 1000,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    -- ["rua_bien_giong"] = {
    -- 	label = "Rùa biển giống",
    -- 	weight = 1000,
    -- 	stack = true,
    -- 	close = true,
    -- 	-- consume = 0.2,
    -- },

    ["ca_bong_mu"] = {
        label = "Cá bóng mú",
        weight = 2000,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["ca_duoi"] = {
        label = "Cá đuối",
        weight = 2000,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["ca_ngu"] = {
        label = "Cá ngừ",
        weight = 7000,
        stack = true,
        close = true,
        description = "Một loại hải sản đặc biệt chất lượng cao, giá trị kinh tế cao"
        -- consume = 0.2,
    },
    ["tom_hum"] = {
        label = "Tôm hùm",
        weight = 2000,
        stack = true,
        close = true,
        description = "Một loại Hải sản đặc biệt"
        -- consume = 0.2,
    },
    ["rua_bien"] = {
        label = "Rùa biển",
        weight = 2000,
        stack = true,
        close = true
        -- consume = 0.2,
    },

    ["ca_thu"] = {
        label = "Cá thu",
        weight = 5000,
        stack = true,
        close = true,
        description = "Một loài cá phổ biến ở biển"
        -- consume = 0.2,
    },

    ["ca_chim"] = {
        label = "Cá Chim",
        weight = 2000,
        stack = true,
        close = true,
        description = "Cá chim trắng nước ngọt"
        -- consume = 0.2,
    },

    ["ca_hoi"] = {
        label = "Cá Hồi",
        weight = 3000,
        stack = true,
        close = true,
        description = "Một loại cá nước ngọt quý hiếm có giá trị cao"
        -- consume = 0.2,
    },

    ["cagiongbongmu"] = {
        label = "cagiongbongmu",
        weight = 1000,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["ruagiong"] = {
        label = "Rùa Gióng",
        weight = 1000,
        stack = true,
        close = true
        -- consume = 0.2,
    },
    ["can_xang"] = {
        label = "Can Xăng",
        weight = 10000,
        stack = false,
        close = true
    },

    ['box_police'] = {
        label = 'Hộp Quần Dụng',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Một hộp chứa trang bị cơ bản cho cảnh sát',
        client = {export = 'xn_pdtools.usePoliceBox'}
    },

    ["tigersharkmeat"] = {
        label = "Cá mập hổ",
        weight = 2000,
        stack = true,
        close = true,
        description = "Có thể đem bán hoặc phóng sinh",
        client = {image = "tigersharkmeat.webp"}
    },

    ["dolphin"] = {
        label = "Cá heo",
        weight = 3000,
        stack = true,
        close = true,
        description = "Có thể đem bán hoặc phóng sinh",
        client = {image = "dolphin.webp"}
    },

    ["killerwhales"] = {
        label = "Cá voi sát thủ",
        weight = 4000,
        stack = true,
        close = true,
        description = "Có thể đem bán hoặc phóng sinh",
        client = {image = "killerwhales.webp"}
    },

    ["sharkhammer"] = {
        label = "Cá mập đầu búa",
        weight = 5000,
        stack = true,
        close = true,
        description = "Có thể đem bán hoặc phóng sinh",
        client = {image = "sharkhammer.webp"}
    },

    ["medkit_che"] = {
        label = "Bộ Cứu Thương",
        weight = 1000,
        stack = true,
        close = true,
        do_hiem = 1
    },
    ["medikit"] = {
        label = "Bộ Cứu Thương BS",
        weight = 2000,
        stack = true,
        close = true,
        do_hiem = 3
    },

    ["medlangbam"] = {
        label = "Medikit Lang Băm",
        weight = 1000,
        stack = true,
        close = true
    },

    ["packaged_chicken"] = {
        label = "Gà Đóng Gói",
        weight = 1000,
        stack = true,
        close = true
    },

    ["go_my_nghe"] = {
        label = "Gỗ Mỹ Nghệ",
        weight = 500,
        stack = true,
        close = true
    },

    ["mu_cao_su"] = {
        label = "Mủ Cao Su",
        weight = 200,
        stack = true,
        close = true
    },

    ["dau_tho"] = {
        label = "Dầu Thô",
        weight = 1000,
        stack = true,
        close = true
    },

    ["pin_nang_luong"] = {
        label = "Pin Năng Lượng",
        weight = 1000,
        stack = true,
        close = true
    },

    ["dau_tinh_luyen"] = {
        label = "Dầu tinh luyện",
        weight = 1000,
        stack = true,
        close = true
    },

    ["xang"] = {label = "Xăng", weight = 1000, stack = true, close = true},

    ["manhgepgacha"] = {
        label = "Mảnh ghép gacha",
        weight = 100,
        stack = true,
        close = true
    },

    ["gachabox2"] = {
        label = "Gacha Box 02",
        weight = 5000,
        stack = true,
        close = true,
        description = "Mở ra sao sạch, các vật phẩm event khác"
    },

    ["gachaboxevent"] = {
        label = "Rương Event IC",
        weight = 5000,
        stack = true,
        close = true,
        description = "Tích cực quay tay vận may sẽ tới"
    },

    ["gachabox3"] = {
        label = "Gacha Box 03",
        weight = 10000,
        stack = true,
        close = true,
        description = "Thuộc tính cao nhất có thể nhận được là Rare (Tím)"
    },

    ["gachabox4"] = {
        label = "Gacha Box 04",
        weight = 5000,
        stack = true,
        close = true,
        description = "Thuộc tính cao nhất có thể nhận được là Epic (Vàng cam)"
    },

    ["keygacha"] = {
        label = "chìa khóa gacha vàng",
        weight = 100,
        stack = true,
        close = true,
        description = "Chìa khóa gacha vàng"
    },

    ["key_halloween"] = {
        label = "chìa khóa halloween",
        weight = 100,
        stack = true,
        close = true,
        description = "Chìa khóa gacha halloween"
    },

    ['keygacha_tshirt'] = {
        label = 'Chìa khóa hòm áo thun',
        weight = 10,
        stack = true,
        close = true,
        description = 'Chìa khóa để mở hòm áo thun premium'
    },

    ['keygacha_torso'] = {
        label = 'Chìa khóa hòm áo khoác',
        weight = 10,
        stack = true,
        close = true,
        description = 'Chìa khóa để mở hòm áo khoác premium'
    },

    ['keygacha_pants'] = {
        label = 'Chìa khóa hòm quần dài',
        weight = 10,
        stack = true,
        close = true,
        description = 'Chìa khóa để mở hòm quần dài premium'
    },

    ['keygacha_shoes'] = {
        label = 'Chìa khóa hòm giày',
        weight = 10,
        stack = true,
        close = true,
        description = 'Chìa khóa để mở hòm giày premium'
    },

    ['keygacha_glasses'] = {
        label = 'Chìa khóa hòm kính',
        weight = 10,
        stack = true,
        close = true,
        description = 'Chìa khóa để mở hòm kính premium'
    },

    ['keygachaic_tshirt'] = {
        label = 'Chìa khóa hòm áo thun IC',
        weight = 10,
        stack = true,
        close = true,
        description = 'Chìa khóa để mở hòm áo thun IC'
    },

    ['keygachaic_torso'] = {
        label = 'Chìa khóa hòm áo khoác IC',
        weight = 10,
        stack = true,
        close = true,
        description = 'Chìa khóa để mở hòm áo khoác IC'
    },

    ['keygachaic_pants'] = {
        label = 'Chìa khóa hòm quần dài IC',
        weight = 10,
        stack = true,
        close = true,
        description = 'Chìa khóa để mở hòm quần dài IC'
    },

    ['keygachaic_shoes'] = {
        label = 'Chìa khóa hòm giày IC',
        weight = 10,
        stack = true,
        close = true,
        description = 'Chìa khóa để mở hòm giày IC'
    },

    ['keygachaic_glasses'] = {
        label = 'Chìa khóa hòm kính IC',
        weight = 10,
        stack = true,
        close = true,
        description = 'Chìa khóa để mở hòm kính IC'
    },

    ["keysiver"] = {
        label = "chìa khóa gacha bạc",
        weight = 100,
        stack = true,
        close = true,
        description = "Chìa khóa Gacha ingame"
    },

    ["manh_1"] = {
        label = "Mảnh ghép xe 1",
        weight = 100,
        stack = true,
        close = true
    },

    ["manh_2"] = {
        label = "Mảnh ghép xe 2",
        weight = 100,
        stack = true,
        close = true
    },

    ["manh_3"] = {
        label = "Mảnh ghép xe 3",
        weight = 100,
        stack = true,
        close = true
    },

    ["manh_4"] = {
        label = "Mảnh ghép xe 4",
        weight = 100,
        stack = true,
        close = true
    },

    ["case_che_tao"] = {
        label = "Case Chế Tạo",
        weight = 200,
        stack = true,
        close = true,
        allowArmed = true,
        consume = 0,
        server = {export = 'w_mohom.hom'}
    },

    ["case_sung_ak"] = {
        label = "Case Súng Ak",
        weight = 200,
        stack = true,
        close = true
    },

    ["case_ingame"] = {
        label = "Case Ingame",
        weight = 200,
        stack = true,
        close = true
    },

    ["bang_sung_ak"] = {
        label = "Báng Súng AK",
        weight = 500,
        stack = true,
        close = true,
        do_hiem = 2
    },

    ["than_sung_ak"] = {
        label = "Thân Súng AK",
        weight = 1000,
        stack = true,
        close = true,
        do_hiem = 2
    },

    ["nong_sung_ak"] = {
        label = "Nòng Súng AK",
        weight = 1000,
        stack = true,
        close = true,
        do_hiem = 2
    },

    ["scuba_tube_l1"] = {
        label = "Ống lặn 1",
        weight = 1000,
        stack = false,
        close = true,
        description = "An oxygen tube and a rebreather",
        client = {image = "diving-tube-level1.webp"}
    },

    ["scuba_tube_l2"] = {
        label = "Ống lặn 2",
        weight = 2000,
        stack = false,
        close = true,
        description = "An oxygen tube and a rebreather",
        client = {image = "diving-tube-level2.webp"}
    },

    ["scuba_tube_l3"] = {
        label = "Ống lặn 3",
        weight = 3000,
        stack = false,
        close = true,
        description = "An oxygen tube and a rebreather",
        client = {image = "diving-tube-level3.webp"}
    },

    ["scuba_gear"] = {
        label = "Bình Oxy",
        weight = 1000,
        stack = false,
        close = true,
        description = "Một bình oxy và một bộ tái cấu trúc",
        client = {image = "scuba_gear.webp"}
    },

    ["liftbag"] = {
        label = "Túi nâng",
        weight = 1000,
        stack = true,
        close = true,
        description = "Một túi nâng để nâng vật nặng",
        client = {image = "liftbag.webp"}
    },

    ["dao_roc_vali"] = {
        label = "Dao rọc vali",
        weight = 1000,
        stack = true,
        close = true,
        description = "Một túi nâng để nâng vật nặng",
        client = {image = "weapon_knife.webp"}
    },

    ["ban_thiet_ke_ak"] = {
        label = "Bản Thiết Kế AK",
        weight = 200,
        stack = true,
        close = true,
        do_hiem = 3
    },

    ['icon_vip'] = {
        label = 'Thẻ VIP',
        weight = 0,
        stack = true,
        close = true,
        description = 'Sử dụng để nhận 24.67 giờ playtime ngay lập tức',
        client = {
            export = 'Tipi_menu.icon_vip'  
        }
    },

    ["khuon_duc"] = {
        label = "Khuôn Đúc",
        weight = 1000,
        stack = true,
        close = true
    },

    ["kim_loai"] = {
        label = "Kim Loại",
        weight = 200,
        stack = true,
        close = true
    },

    ["giay_but"] = {
        label = "Giấy Bút",
        weight = 100,
        stack = true,
        close = true
    },
    ["giay_phep_sung"] = {
        label = "Giấy phép vũ khí",
        weight = 0,
        stack = true,
        close = true
    },

    ["giaytoxe"] = {
        label = "Giấy tờ xe",
        weight = 100,
        stack = false,
        close = true,
        description = "Đem tới đồn công an TP để đăng ký biển số se"

    },

    ["biensoxe"] = {
        label = "Biển số xe",
        weight = 100,
        stack = false,
        close = true,
        description = "Đứng gần phương tiện để thay đổi biển số"
    },

    ["chai_keo"] = {
        label = "Chai Keo",
        weight = 280,
        stack = true,
        close = true
    },

    ["oc_vit"] = {label = "Ốc Vít", weight = 200, stack = true, close = true},

    ["scratch_ticket"] = {
        label = "Vé số",
        weight = 1000,
        stack = true,
        close = true
    },

    ["slaughtered_chicken"] = {
        label = "Thịt Gà",
        weight = 1000,
        stack = true,
        close = true
    },

    ["khuc_go"] = {
        label = "Khúc Gỗ",
        weight = 1000,
        stack = true,
        close = true
    },

    ["wool"] = {label = "Bông", weight = 1000, stack = true, close = true},

    ["fish"] = {label = "Cá Thu", weight = 500, stack = true, close = true},

    ["fishbait"] = {
        label = "Mồi Câu Cá",
        weight = 500,
        stack = true,
        close = true
    },

    ["handcuffs"] = {
        label = "Còng tay",
        weight = 100,
        stack = false,
        close = true,
        description = "Còng tay của công an",
        client = {}
    },

    ["notz_prop_bnncat_anim"] = {
        label = "Phụ kiện 180",
        weight = 100,
        stack = false,
        close = true,
        description = "Phụ kiện trang trí",
        client = {image = "phukien_180.webp"}
    },

    ["phieu_giam_gia"] = {
        label = "Phiếu Giảm Giá",
        weight = 100,
        stack = false,
        close = true,
        description = "Phiếu giảm giá 50% slot xe độc quyền",
        client = {image = "phieu_giam_gia.webp"}
    },

    ["phieu_luong_y"] = {
        label = "phiếu lương y",
        weight = 100,
        stack = true,
        close = true,
        description = "lương y như từ mẫu",
        client = {}
    },

    ["hoadonsuaxe"] = {
        label = "Hóa đơn sửa xe",
        weight = 100,
        stack = true,
        close = true,
        cangive = true,
        description = "Hóa đơn sửa xe",
        client = {}
    },
    ["day_thung"] = {
        label = "Dây thừng",
        weight = 100,
        stack = true,
        close = true,
    },
    ["day_cuoc"] = {
        label = "Dây cước",
        weight = 100,
        stack = true,
        close = true,
    },
    ["dao_cat"] = {
        label = "Dao cắt dây",
        weight = 100,
        stack = true,
        close = true,
    },

    ["hoadonxangdau"] = {
        label = "Hóa đơn xăng đầu",
        weight = 100,
        stack = true,
        close = true,
        cangive = true,
        description = "Hóa đơn xăng dầu",
        client = {}
    },

    ["dinhsat"] = {
        label = "Đinh sắt",
        weight = 100,
        stack = true,
        close = true,
        description = "Đinh sắt, dành cho người hay sống tốt",
        client = {}
    },

    ["ticket_doxe_10"] = {
        label = "Phiếu Giảm Giá",
        weight = 100,
        stack = true,
        close = true,
        description = "Phiếu giảm giá 10% chi phí độ xe",
        client = {}
    },

    ["ticket_doxe_20"] = {
        label = "Phiếu Giảm Giá",
        weight = 100,
        stack = true,
        close = true,
        description = "Phiếu giảm giá 20% chi phí độ xe",
        client = {}
    },

    ["ticket_doxe_30"] = {
        label = "Phiếu Giảm Giá",
        weight = 100,
        stack = true,
        close = true,
        description = "Phiếu giảm giá 30% chi phí độ xe",
        client = {}
    },

    ["ticket_denphaxe"] = {
        label = "Phiếu Free độ",
        weight = 100,
        stack = true,
        close = true,
        description = "Miễn phí độ đèn pha xe 1 lần",
        client = {}
    },

    ["ticket_dengamxe"] = {
        label = "Phiếu Free độ",
        weight = 100,
        stack = true,
        close = true,
        description = "Miễn phí độ đèn gầm xe 1 lần",
        client = {}
    },

    ["ticket_sonmau"] = {
        label = "Phiếu Free độ",
        weight = 100,
        stack = true,
        close = true,
        description = "Miễn phí độ sơn màu xe 1 lần (1 loại sơn: chính, phụ, ánh,...)",
        client = {}
    },

    ["illegalfishbait"] = {
        label = "Mồi Câu Cá",
        weight = 100,
        stack = true,
        close = true
    },

    ["fishingrod"] = {
        label = "Cần Câu",
        weight = 500,
        stack = true,
        close = true
    },

    ['fishingrod1'] = {
        label = 'Cần Câu (Lv.1)',
        weight = 1000,
        stack = false,
        close = true,
        client = {export = 'xn_cauca.useFishingRod'},
        durability = 100,
        description = 'Cần câu cơ bản dành cho người mới.'
    },

    ['fishingrod2'] = {
        label = 'Cần Câu (Lv.2)',
        weight = 1000,
        stack = false,
        close = true,
        client = {export = 'xn_cauca.useFishingRod'},
        durability = 100,
        description = 'Cần câu nâng cấp nhẹ giúp câu cá ổn định hơn.'
    },

    ['fishingrod3'] = {
        label = 'Cần Câu (Lv.3)',
        weight = 1000,
        stack = false,
        close = true,
        client = {export = 'xn_cauca.useFishingRod'},
        durability = 100,
        description = 'Cần câu chất lượng giúp bắt được cá to.'
    },

    ['fishingrod4'] = {
        label = 'Cần Câu (Lv.4)',
        weight = 1000,
        stack = false,
        close = true,
        client = {export = 'xn_cauca.useFishingRod'},
        durability = 100,
        description = 'Cần câu cao cấp dành cho dân chuyên nghiệp.'
    },

    ['fishingrod5'] = {
        label = 'Cần Câu (Lv.5)',
        weight = 1000,
        stack = false,
        close = true,
        client = {export = 'xn_cauca.useFishingRod'},
        durability = 100,
        description = 'Cần câu tối thượng dành cho thợ câu lão luyện.'
    },

    ["shark"] = {
        label = "Cá Mập",
        weight = 10000,
        stack = true,
        close = true,
        description = "Một loại cá biển lớn, vua của đại dương, giá trị kinh tế rất cao"
    },

    ["turtle"] = {label = "Rùa", weight = 500, stack = true, close = true},

    ["turtlebait"] = {
        label = "Mồi Rùa",
        weight = 500,
        stack = true,
        close = true
    },

    ["neo_thuyen"] = {
        label = "Neo Thuyền",
        weight = 500,
        stack = true,
        close = true
    },

    ["stones"] = {label = "Đá", weight = 1000, stack = true, close = true},

    ["washedstones"] = {
        label = "Đá Sạch",
        weight = 1000,
        stack = true,
        close = true
    },

    ["cannabis"] = {
        label = "Lá cần Sa",
        weight = 2000,
        stack = true,
        close = true
    },

    ["creatcrews"] = {
        label = "Thẻ Tạo Crew",
        weight = 100,
        stack = true,
        close = true,
        description = "Tạo 1 Gang mà bạn muốn quản lý"
    },

    ["marijuana"] = {
        label = "Điếu Cần Sa",
        weight = 2000,
        stack = true,
        close = true
    },

    ["heroin"] = {
        label = "Túi Heroin",
        weight = 2000,
        stack = true,
        close = true
    },

    ["package"] = {
        label = "Gói hàng",
        weight = 1000,
        stack = false,
        close = true,
        description = "Sản phẩm phi pháp..."

    },

    ["oxy"] = {
        label = "Ô XY",
        weight = 300,
        stack = true,
        close = true,
        description = "Sản phẩm phi pháp..."

    },

    ["poppyresin"] = {
        label = "Hoa Anh Túc",
        weight = 2000,
        stack = true,
        close = true
    },

    ["stolen_sign"] = {
        label = "Biển báo",
        weight = 3000,
        stack = true,
        close = true,
        description = "Đồ bẩn"
    },

    ["coca_leaf"] = {
        label = "Lá Coke",
        weight = 2000,
        stack = true,
        close = true
    },

    ["coke1g"] = {
        label = "Lọ thuốc phiện",
        weight = 2000,
        stack = true,
        close = true
    },
    ["lucky_box"] = {
        label = "Lucky Box",
        weight = 0,
        description = "Sử dụng để nhận được nhiều vật phẩm",
        stack = true,
        close = true
    },

    ["jewels"] = {
        label = "Trang Sức",
        weight = 500,
        stack = true,
        close = true
    },

    ["hydrochloric_acid"] = {
        label = "Lá Thảo Dược",
        weight = 3000,
        stack = true,
        close = true
    },

    ["meth1g"] = {
        label = "Thảo Dược",
        weight = 1000,
        stack = true,
        close = true
    },

    ["armor12"] = {
        label = "Giáp 1/2",
        weight = 190,
        stack = true,
        close = true,
        client = {
            anim = {dict = 'rcmfanatic3', clip = 'kneel_idle_a', flag = 1}, -- , blendIn = 3.0, blendOut = 1.0, flag = 0 ,playbackRate= 0, lockX=0,lockY=0,lockZ=0 },
            -- usetime = 5000,
            useWhileDead = false,
            cancel = true,
            disable = {move = true, car = true, combat = true}
        },
        allowArmed = true,
        do_hiem = 1
    },

    ["armor"] = {
        label = "Giáp",
        weight = 1000,
        stack = true,
        close = true,
        client = {
            anim = {dict = 'rcmfanatic3', clip = 'kneel_idle_a', flag = 1}, -- , blendIn = 3.0, blendOut = 1.0, flag = 0 ,playbackRate= 0, lockX=0,lockY=0,lockZ=0 },
            -- usetime = 5000,
            useWhileDead = false,
            cancel = true,
            disable = {move = true, car = true, combat = true}
        },
        allowArmed = true,
        do_hiem = 1
        -- consume = 1
    },

    -- ["armorpolice"] = {
    -- 	label = "Giáp Police",
    -- 	weight = 3000,
    -- 	stack = true,
    -- 	close = true,
    -- 	client = {
    -- 		anim = { dict = 'rcmfanatic3', clip = 'kneel_idle_a', flag = 1},--, blendIn = 3.0, blendOut = 1.0, flag = 0 ,playbackRate= 0, lockX=0,lockY=0,lockZ=0 },
    -- 		usetime = 5000,
    -- 		useWhileDead = false,
    -- 		cancel = true,
    -- 		disable = {move = true, car = true, combat = true}
    -- 	},
    -- 	allowArmed = true
    -- 	--consume = 1
    -- },

    ["oxygenmask"] = {
        label = "Bình Lặn",
        weight = 2000,
        stack = true,
        close = true,
        do_hiem = 1
        -- client = {
        -- 	usetime = 0,
        -- },
        -- allowArmed = true
    },

    ["binoculars"] = {
        label = "Ống Nhòm",
        weight = 500,
        stack = false,
        close = true,
        description = "Nhìn xa trông rộng, định đoạt thiên hạ",
        client = {event = 'qbx_binoculars:client:toggle'},
        consume = 0,
        allowArmed = true
    },

    ["latxe"] = {
        label = "Dụng cụ lật xe",
        weight = 500,
        stack = true,
        close = true,
        allowArmed = true
    },

    ["hifi"] = {
        label = "Loa phát nhạc",
        weight = 10,
        stack = true,
        close = true,
        client = {usetime = 0},
        consume = 0,
        allowArmed = true
    },

    ["bosuasung"] = {
        label = "Bộ sửa súng",
        weight = 2000,
        stack = true,
        close = true,
        -- client={
        -- 	usetime = 0
        -- },
        allowArmed = true
    },

    ["bosuavukhi_cole"] = {
        label = "Bộ sửa vũ khí cờ lê",
        weight = 2000,
        stack = true,
        close = true,
        allowArmed = true
    },

    ["bosuavukhi_machete"] = {
        label = "Bộ sửa vũ khí machete",
        weight = 2000,
        stack = true,
        close = true,
        allowArmed = true
    },

    ["ticket_event"] = {
        label = "Ticket GiveAWay",
        weight = 100,
        stack = true,
        close = true,
        -- client={
        -- 	usetime = 0
        -- },
        allowArmed = true
    },

    ["bosuasungnganh"] = {
        label = "Bộ sửa súng ngành",
        weight = 500,
        stack = true,
        close = true,
        -- client={
        -- 	usetime = 0
        -- },
        allowArmed = true
    },

    ["contract"] = {
        label = "Hợp đồng bán xe",
        weight = 0,
        stack = true,
        close = true
    },

    ["bchop_contract"] = {
        label = "Hợp đồng rã xe",
        weight = 1000,
        stack = false,
        close = true,
        cangive = true,
        description = "Hợp đồng rã xe (Đồ bẩn)"
    },

    ["badge"] = {label = "Coin", weight = 100, stack = true, close = true},

    ["badge1"] = {label = "Coin 1", weight = 100, stack = true, close = true},

    ["badge2"] = {label = "Coin 2", weight = 500, stack = true, close = true},

    ["badge3"] = {label = "Coin 3", weight = 500, stack = true, close = true},

    ["badge4"] = {label = "Coin 4", weight = 500, stack = true, close = true},

    ["badge5"] = {label = "Coin 5", weight = 500, stack = true, close = true},

    ["key"] = {label = "Key", weight = 100, stack = true, close = true},

    ['diamond_dice'] = {
        label = 'Diamond Dice',
        weight = 50,
        stack = false,
        close = true,
        consume = 0.05, -- 20 uses
        description = 'Rolls 2d20',
        metadata = {dices = 2, sides = 20}
    },
    ['wooden_dice'] = {
        label = 'Wooden Dice',
        weight = 50,
        stack = true,
        close = true,
        consume = 0.1, -- 10 uses
        description = 'Rolls 1d6',
        metadata = {dices = 1, sides = 6}
    },

    ["banthietkear"] = {
        label = "Bản thiết kế AR",
        weight = 100,
        stack = true,
        close = true
    },

    ["repairkit"] = {
        label = "Dụng cụ sửa xe",
        weight = 1000,
        stack = true,
        close = true,
        description = "Bộ sửa chữa phương tiện"
    },

    ["repair_kit"] = {
        label = "Dụng cụ sửa xe",
        weight = 1000,
        stack = true,
        close = true,
        description = "Bộ sửa chữa phương tiện"
    },

    ["cleanvehicles"] = {
        label = "Dụng cụ lau xe",
        weight = 100,
        stack = true,
        close = true,
        client = {
            usetime = 5000,
            cancel = true,
            anim = {
                dict = 'amb@prop_human_bum_bin@idle_a',
                clip = 'idle_a',
                flag = 1
            }, -- , blendIn = 3.0, blendOut = 1.0, flag = 0 ,playbackRate= 0, lockX=0,lockY=0,lockZ=0 },
            useWhileDead = false,
            disable = {move = true, car = true, combat = true}
        },
        consume = 0
    },

    ["melon"] = {
        label = "Dưa Hấu",
        weight = 500,
        stack = true,
        close = true,
        description = "Sản phẩm từ nghề trồng chọt",
        client = {}
    },

    ["melon_seed"] = {
        label = "Hạt Giống Dưa Hấu",
        weight = 100,
        stack = true,
        close = true,
        description = "Hạt giống dưa",
        client = {}
    },

    ["hatgionglua"] = {
        label = "Hạt Giống Lúa",
        weight = 1000,
        stack = true,
        close = true,
        description = "Hạt giống lúa nước",
        client = {}
    },

    ["hatgiong_hoamynhan"] = {
        label = "Hạt Giống hoa d",
        weight = 1000,
        stack = true,
        close = true,
        description = "Hạt giống lúa nước",
        client = {}
    },

    ["hatgiongluami"] = {
        label = "Hạt Giống Lúa mì",
        weight = 1000,
        stack = true,
        close = true,
        description = "Hạt giống Lúa mì",
        client = {}
    },

    ['rodungche'] = {
        label = 'Rổ Hái chè',
        weight = 1000,
        stack = false,
        close = true,
        durability = 100,
        description = 'Rổ dùng để hái chè'
    },


    ["hatgiongbingo"] = {
        label = "Hạt Giống Bí ngô",
        weight = 1000,
        stack = true,
        close = true,
        description = "Hạt giống bí ngô",
        client = {}
    },

    ["hatgiongbong"] = {
        label = "Hạt Giống Bông",
        weight = 1000,
        stack = true,
        close = true,
        description = "Hạt giống bông",
        client = {}
    },

    ["hatgiongdudu"] = {
        label = "Hạt Giống Đu Đủ",
        weight = 1000,
        stack = true,
        close = true,
        description = "Hạt giống đu đủ",
        client = {}
    },

    ["bonggon"] = {
        label = "Bông gòn",
        weight = 10,
        stack = true,
        close = true,
        description = "Bông gòn",
        client = {}
    },

    ["luanuoc"] = {
        label = "Lúa nước",
        weight = 1000,
        stack = true,
        close = true,
        description = "Lúa nước chất lượng cao",
        client = {}
    },

    ["luami"] = {
        label = "Lúa mì",
        weight = 1000,
        stack = true,
        close = true,
        description = "Lúa mì chất lượng cao",
        client = {}
    },

    ["bingo"] = {
        label = "Bí ngô",
        weight = 1000,
        stack = true,
        close = true,
        description = "Bí ngô chất lượng cao",
        client = {}
    },

    ["pesticide_basic"] = {
        label = "Thuốc trừ sâu thường",
        weight = 1000,
        stack = true,
        close = true,
        description = "Thuốc trừ sâu chất lượng cao",
        client = {}
    },

    ["pesticide_advanced"] = {
        label = "Thuốc trừ sâu nâng cao",
        weight = 1000,
        stack = true,
        close = true,
        description = "Thuốc trừ sâu chất lượng cao",
        client = {}
    },

    ["banh_deo"] = {
        label = "Bánh Đẻo",
        weight = 300,
        stack = true,
        close = true,
        description = "Bánh đẻo truyền thống",
        client = {}
    },

    ["ban_nuong"] = {
        label = "Bánh Nướng",
        weight = 300,
        stack = true,
        close = true,
        description = "Bánh nướng chất lượng cao",
        client = {}
    },

    ["trung_muoi"] = {
        label = "Trứng muối",
        weight = 100,
        stack = true,
        close = true,
        description = "Trứng muối chất lượng cao",
        client = {}
    },

    ["trung_ga"] = {
        label = "Trứng gà",
        weight = 100,
        stack = true,
        close = true,
        description = "Trứng gà chất lượng cao",
        client = {}
    },

    ["huy_hieu_trung_thu"] = {
        label = "Trung thu 2025",
        weight = 100,
        stack = true,
        close = true,
        description = "Dùng để tham gia Event trung thu 2025",
        client = {}
    },

    ["bot_mi"] = {
        label = "Bột Mì",
        weight = 100,
        stack = true,
        close = true,
        description = "Bột mì chất lượng cao",
        client = {}
    },

    ["bot_nep"] = {
        label = "Bột Nếp",
        weight = 100,
        stack = true,
        close = true,
        description = "Bột nếp chất lượng cao",
        client = {}
    },

    ["duong_mia"] = {
        label = "Đường Mía",
        weight = 100,
        stack = true,
        close = true,
        description = "Đường mía chất lượng cao",
        client = {}
    },

    -- Even halloween
    ['event_token'] = {
        label = 'Xu halloween',
        weight = 100,
        description = "Sự kiện halloween 2025"
    },
    ['candy_corn'] = {label = 'Candy Corn', weight = 10},
    ['chocolate_bar'] = {label = 'Sô cô la', weight = 10},
    ['pumpkin_basket'] = {label = 'Giỏ bí ngô', weight = 100},
    ['rotten_casket'] = {label = 'Hòm thối', weight = 1000},

    ["hom_hlw"] = {
        label = 'Hòm Halloween',
        weight = 100,
        stack = true,
        close = true,
        description = "Hòm Halloween Mở ra nhiều phần quà hấp dẫn"
    },

    ["hom_hlw_ig"] = {
        label = 'Hòm Halloween IG',
        weight = 100,
        stack = true,
        close = true,
        description = "Hòm Halloween (IG) Mở ra nhiều phần quà hấp dẫn"
    },

    ["the_outfit_hlw"] = {
        label = 'Thẻ Trang Phục',
        weight = 100,
        stack = true,
    },

    ["the_skin_hlw"] = {
        label = 'Thẻ Skin',
        weight = 50,
        stack = true,
    },

    ["the_hlw"] = {
        label = 'Thẻ Halloween',
        weight = 10,
        stack = true,
    },

    ["ve_doi_xe_hlw1"] = {
        label = 'Vé đổi xe KOENICSE',
        weight = 100,
        stack = true,
        description = "Xe Koenicse Halloween"
    },
    
    ["ve_doi_xe_hlw2"] = {
        label = 'Vé đổi xe Poscher',
        weight = 100,
        stack = true,
        description = "Xe Poscher Halloween"
    },

    ["fertilizer"] = {
        label = "Phân bón",
        weight = 100,
        stack = true,
        close = true,
        description = "Phân bón chất lượng cao",
        client = {}
    },

    ["saubenh"] = {
        label = "Sâu bệnh",
        weight = 100,
        stack = true,
        close = true,
        description = "Phá hoại mùa màng",
        client = {}
    },

    ["sanho"] = {label = "San hô", weight = 2000, stack = true, close = true},

    ["skin_picolo"] = {
        label = "Skin picolo",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },

    ["skin_ronin"] = {
        label = "Skin Ronin",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },

    ["skin_doctorstrange"] = {
        label = "Skin Doctorstrage",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_deadpool"] = {
        label = "Skin Deadpool",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_hagane"] = {
        label = "Skin Hagane",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_haku"] = {
        label = "Skin Haku",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_haku2"] = {
        label = "Skin Haku 2",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_ia"] = {
        label = "Skin IA",
        weight = 1000,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_kamada"] = {
        label = "Skin Kamada",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_lily"] = {
        label = "Skin Lily",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_meiko"] = {
        label = "Skin Meiko",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_miki"] = {
        label = "Skin Miki",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_miku"] = {
        label = "Skin Miku",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_neru"] = {
        label = "Skin Neru",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_nezuko"] = {
        label = "Skin Nezuko",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_rin"] = {
        label = "Skin Hagane Rin",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_zenitsu"] = {
        label = "Skin Zenitsu",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_chrono"] = {
        label = "Skin Chorono",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_sally"] = {
        label = "Skin Sally",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_ultraman"] = {
        label = "Skin Ultraman",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_bicaso"] = {
        label = "Skin Bicaso",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_girl"] = {
        label = "Skin Girl",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_tigress"] = {
        label = "Skin Tigress",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_shifu"] = {
        label = "Skin Shifu",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_po"] = {
        label = "Skin Po",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },

    ["bansungar"] = {
        label = "Bán súng AR",
        weight = 100,
        stack = true,
        close = true

    },

    ["thansungar"] = {
        label = "Thân súng AR",
        weight = 100,
        stack = true,
        close = true

    },

    ["nongsungar"] = {
        label = "Nòng súng AR",
        weight = 100,
        stack = true,
        close = true

    },

    ["skin_ironman"] = {
        label = "Skin Ironman",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },

    ["skin_duck"] = {
        label = "Skin Duck",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_jinitaimei"] = {
        label = "Skin Jinitaimei",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["skin_shinchan"] = {
        label = "Skin Shin",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },

    ["fashion_hnganh_wing1"] = {
        label = "Fashion cánh éc quỷ",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_angelring"] = {
        label = "Fashion vòng thiên sứ",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_pcube2"] = {
        label = "Fashion tai nghe xanh nước",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_sunglasses"] = {
        label = "Fashion kính thuglife",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_pcube22"] = {
        label = "Fashion tai nghe hồng",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_pcube222"] = {
        label = "Fashion tai nghe xanh lá",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_arcadeahri"] = {
        label = "Fashion tai nghe tím",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_angelwing"] = {
        label = "Fashion cánh kim loại bạc",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_angelwing2"] = {
        label = "Fashion cánh kim loại vàng",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_angelwing3"] = {
        label = "Fashion cánh thường",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_angelwing19"] = {
        label = "Fashion cánh kim loại xanh",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_bearhat"] = {
        label = "Fashion mũ gấu",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_birdcooper"] = {
        label = "Fashion chim vẹt",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_chii"] = {
        label = "Fashion mèo",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_digger"] = {
        label = "Fashion cú phù thủy",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_dragon"] = {
        label = "Fashion rồng",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_heartpink"] = {
        label = "Fashion trái tim",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_hellwing"] = {
        label = "Fashion cánh quỷ",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_cathat"] = {
        label = "Fashion mũ mèo",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["wingshalloween"] = {
        label = "Fashion cánh halloween",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_wingsrender"] = {
        label = "Fashion cánh vàng",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_wing_gb_blue"] = {
        label = "Fashion cánh blue",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_wing_gb_green"] = {
        label = "Fashion cánh blue green",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },
    ["fashion_wing_gb_pink"] = {
        label = "Fashion cánh blue pink",
        weight = 100,
        stack = true,
        close = true,
        allowArmed = true
    },

    ['balo'] = {
        label = 'Balo',
        weight = 1000,
        stack = false,
        close = true,
        description = "Tăng 50kg",
        allowArmed = true

    },

    ['thetp'] = {
        label = 'Thẻ tp',
        weight = 500,
        stack = true,
        close = true,
        allowArmed = true,
        client = {
            anim = {
                dict = 'anim@arena@celeb@podium@no_prop@',
                clip = 'regal_c_1st',
                flag = 1
            }, -- , blendIn = 3.0, blendOut = 1.0, flag = 0 ,playbackRate= 0, lockX=0,lockY=0,lockZ=0 },
            usetime = 4000,
            useWhileDead = false,
            cancel = true,
            disable = {move = true, car = true, combat = true}
        }

    },
    ['thespamrhino'] = {
        label = 'Thẻ gọi rhino',
        weight = 2000,
        stack = true,
        close = true,
        allowArmed = true,
        client = {
            anim = {
                dict = 'anim@arena@celeb@flat@solo@no_props@',
                clip = 'cap_a_player_a',
                flag = 1
            }, -- , blendIn = 3.0, blendOut = 1.0, flag = 0 ,playbackRate= 0, lockX=0,lockY=0,lockZ=0 },
            usetime = 5000,
            useWhileDead = false,
            cancel = true,
            disable = {move = true, car = true, combat = true}
        }

    },

    ['thespamscarab3'] = {
        label = 'Thẻ gọi scarab3',
        weight = 2000,
        stack = true,
        close = true,
        allowArmed = true,
        client = {
            anim = {
                dict = 'anim@arena@celeb@flat@solo@no_props@',
                clip = 'cap_a_player_a',
                flag = 1
            }, -- , blendIn = 3.0, blendOut = 1.0, flag = 0 ,playbackRate= 0, lockX=0,lockY=0,lockZ=0 },
            usetime = 5000,
            useWhileDead = false,
            cancel = true,
            disable = {move = true, car = true, combat = true}
        }

    },

    ["bee-hive"] = {
        label = "Tổ ong",
        weight = 1000,
        stack = false,
        close = true,
        description = "Tổ ong thợ (tạo ra mật ong)",
        consume = 0,
        client = {image = "bee-hive.webp"},
        server = {export = 'sd-beekeeping.useBee-hive'}
    },

    -- Bee Honey (Basic)
    ["bee-honey"] = {
        label = "Mật ong thường",
        weight = 300,
        stack = true,
        close = true,
        description = "Mật ong nguyên chất được thu hoạch trực tiếp từ tổ ong, phong phú về vị ngọt tự nhiên.",
        consume = 0,
        client = {image = "bee-honey.webp"}
    },

    -- Chiliad Honey
    ["chiliad-honey"] = {
        label = "Mật ong chiliad",
        weight = 300,
        stack = true,
        close = true,
        description = "Một mật ong mạnh mẽ truyền vào bản chất của hệ thực vật hoang dã của Chiliad.",
        consume = 0,
        client = {image = "chiliad-honey.webp"}
    },

    -- Green Hills Honey
    ["green-hills-honey"] = {
        label = "Mật Green Hills",
        weight = 300,
        stack = true,
        close = true,
        description = "Mật ong tinh tế được chế tác từ những cánh đồng cỏ ba lá phong phú của những ngọn đồi xanh.",
        consume = 0,
        client = {image = "green-hills-honey.webp"}
    },

    -- Alamo Honey
    ["alamo-honey"] = {
        label = "Mật Alamo",
        weight = 300,
        stack = true,
        close = true,
        description = "Mật ong tinh tế có nguồn gốc từ Grove Alamo Serene, được biết đến với hương vị độc đáo của nó.",
        consume = 0,
        client = {image = "alamo-honey.webp"}
    },

    -- Bee Wax
    ["bee-wax"] = {
        label = "Bee Wax",
        weight = 300,
        stack = true,
        close = true,
        description = "Sáp ong đa năng, hoàn hảo để chế tạo nến, mỹ phẩm và hàng hóa thủ công.",
        consume = 0,
        client = {image = "bee-wax.webp"}
    },

    ["bee-house"] = {
        label = "Nhà nuôi ong",
        weight = 1000,
        stack = false,
        close = true,
        description = "Tổ nuôi ong (Sinh sản ong và nuôi ong chúa)",
        consume = 0,
        client = {image = "bee-house.webp"},
        server = {export = 'sd-beekeeping.useBee-house'}
    },

    ["bee-queen"] = {
        label = "Ong chúa",
        weight = 500,
        stack = true,
        close = true,
        description = "Ong chúa dùng để nuôi trồng sinh sản ong thợ",
        consume = 0,
        client = {image = "bee-queen.webp"}
    },

    ["bee-worker"] = {
        label = "Ong thợ",
        weight = 300,
        stack = true,
        close = true,
        description = "Những chú ong chăm chỉ mang lại mật ngọt cho bạn hàng ngày",
        consume = 0,
        client = {image = "bee-worker.webp"}
    },

    ["thymol"] = {
        label = "Thuốc Thymol",
        weight = 500,
        stack = true,
        close = true,
        description = "Một phương pháp điều trị tự nhiên có nguồn gốc từ dầu húng tây, có hiệu quả trong việc chống nhiễm trùng tổ ong và hỗ trợ sức khỏe của ong.",
        consume = 0,
        client = {image = "thymol.webp"}
    },

    ["bee-smoker"] = {
        label = "Bình hun ong",
        weight = 1000,
        stack = false,
        description = "Bình hun khói cầm tay được sử dụng để làm dịu ong, làm cho việc quản lý ong an toàn hơn và dễ dàng hơn.",
        consume = 0,
        client = {image = "bee-smoker.webp"}
    },

    ["cat1"] = {
        label = "Mèo lv1",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng tốc độ chạy 5%",
        degrade = 4320,
        decay = true
    },
    ["cat2"] = {
        label = "Mèo lv2",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng tốc độ chạy 10%",
        degrade = 5760,
        decay = true
    },
    ["cat3"] = {
        label = "Mèo lv3",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng tốc độ chạy 15%",
        degrade = 7200,
        decay = true
    },
    ["cat4"] = {
        label = "Mèo lv4",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng tốc độ chạy 20%",
        degrade = 8640,
        decay = true
    },
    ["cat5"] = {
        label = "Mèo lv5",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng tốc độ chạy 30%",
        degrade = 10080,
        decay = true
    },

    ["monkey1"] = {
        label = "Khỉ lv1",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng giá trị máu khi dùng bandage 10%",
        degrade = 4320,
        decay = true
    },
    ["monkey2"] = {
        label = "Khỉ lv2",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng giá trị máu khi dùng bandage 20%",
        degrade = 5760,
        decay = true
    },
    ["monkey3"] = {
        label = "Khỉ lv3",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng giá trị máu khi dùng bandage 30%",
        degrade = 7200,
        decay = true
    },
    ["monkey4"] = {
        label = "Khỉ lv4",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng giá trị máu khi dùng bandage 40%",
        degrade = 8640,
        decay = true
    },
    ["monkey5"] = {
        label = "Khỉ lv5",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng giá trị máu khi dùng bandage 50%",
        degrade = 10080,
        decay = true
    },

    ["chicken1"] = {
        label = "Gà lv1",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Giảm thời gian làm nghề bước 1 10%",
        degrade = 4320,
        decay = true
    },
    ["chicken2"] = {
        label = "Gà lv2",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Giảm thời gian làm nghề bước 1 20%",
        degrade = 5760,
        decay = true
    },
    ["chicken3"] = {
        label = "Gà lv3",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Giảm thời gian làm nghề bước 1 30%",
        degrade = 7200,
        decay = true
    },
    ["chicken4"] = {
        label = "Gà lv4",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Giảm thời gian làm nghề bước 1 40%",
        degrade = 8640,
        decay = true
    },
    ["chicken5"] = {
        label = "Gà lv5",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Giảm thời gian làm nghề bước 1 50%",
        degrade = 10080,
        decay = true
    },

    ["husky1"] = {
        label = "Husky lv1",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng giá trị giáp khi dùng giáp 10%",
        degrade = 4320,
        decay = true
    },
    ["husky2"] = {
        label = "Husky lv2",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng giá trị giáp khi dùng giáp 20%",
        degrade = 5760,
        decay = true
    },
    ["husky3"] = {
        label = "Husky lv3",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng giá trị giáp khi dùng giáp 30%",
        degrade = 7200,
        decay = true
    },
    ["husky4"] = {
        label = "Husky lv4",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng giá trị giáp khi dùng giáp 40%",
        degrade = 8640,
        decay = true
    },
    ["husky5"] = {
        label = "Husky lv5",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng giá trị giáp khi dùng giáp 50%",
        degrade = 10080,
        decay = true
    },
    ["coyote"] = {
        label = "Sói vip",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = true,
        description = "Tăng gấp đôi vật phẩm nhận được ở bước 1",
        decay = true
    },

    ["hopkim"] = {label = "Hợp kim", weight = 100, stack = true, close = true},

    ["gocaocap"] = {
        label = "Gỗ cao cấp",
        weight = 100,
        stack = true,
        close = true
    },

    ["vaicaocap"] = {
        label = "Vải cao cấp",
        weight = 100,
        stack = true,
        close = true
    },

    ["vairach"] = {
        label = "Vải rách",
        weight = 100,
        stack = true,
        close = true
    },

    ["bluesky"] = {label = "Blue Sky", weight = 100, stack = true, close = true},

    ["daucaocap"] = {
        label = "Xăng 95",
        weight = 100,
        stack = true,
        close = true
    },

    ["gacaocap"] = {label = "KFC", weight = 100, stack = true, close = true},

    ["black_phone"] = {
        label = "Black Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["blue_phone"] = {
        label = "Blue Phone",
        weight = 0,
        stack = true,
        close = true
    },
    ["blue_card"] = {
        label = "Blue Card",
        weight = 100,
        stack = false,
        close = true
    },

    ["classic_phone"] = {
        label = "Classic Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["gold_phone"] = {
        label = "Gold Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["greenlight_phone"] = {
        label = "Green Light Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["green_phone"] = {
        label = "Green Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["phone_module"] = {
        label = "Phone Module",
        weight = 10,
        stack = true,
        close = true
    },

    ["pink_phone"] = {
        label = "Pink Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["powerbank"] = {
        label = "Power Bank",
        weight = 0,
        stack = true,
        close = true
    },

    ["red_phone"] = {
        label = "Red Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["wet_black_phone"] = {
        label = "Wet Black Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["wet_blue_phone"] = {
        label = "Wet Blue Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["wet_classic_phone"] = {
        label = "Wet Classic Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["wet_gold_phone"] = {
        label = "Wet Gold Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["wet_greenlight_phone"] = {
        label = "Wet Green Light Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["wet_green_phone"] = {
        label = "Wet Green Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["wet_pink_phone"] = {
        label = "Wet Pink Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["wet_red_phone"] = {
        label = "Wet Red Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["wet_white_phone"] = {
        label = "Wet White Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["white_phone"] = {
        label = "White Phone",
        weight = 0,
        stack = true,
        close = true
    },

    ["cainit"] = {
        label = "Cái nịt",
        weight = 1,
        stack = true,
        close = true,
        description = 'Còn đúng cái nịt'
    },

    ["anchovy"] = {
        label = "Cá Trích",
        weight = 100,
        stack = true,
        close = true
    },

    ["smallbluefish"] = {
        label = "Cá Đuối Nhỏ",
        weight = 200,
        stack = true,
        close = true
    },

    ["bluefish"] = {
        label = "Cá Chim Vây Vàng",
        weight = 300,
        stack = true,
        close = true
    },

    ["garfish"] = {
        label = "Cá Nóc Gai",
        weight = 500, -- 3000,
        stack = true,
        close = true
    },

    ["bonitosfish"] = {
        label = "Cá Kiếm Xanh",
        weight = 500, ---2000,
        stack = true,
        close = true
    },

    ["perch"] = {
        label = "Cá Hồi Đại Dương",
        weight = 1000, -- 3000,
        stack = true,
        close = true
    },

    ["volon"] = {
        label = "Vỏ lon",
        weight = 200,
        stack = true,
        close = true,
        description = "Vỏ lon nước ngọt rỗng"
    },

    ["vochai"] = {
        label = "Vỏ chai",
        weight = 200,
        stack = true,
        close = true,
        description = "Vỏ chai nước rỗng"
    },

    ["carettacaretta"] = {
        label = "Cá Ngừ Vây Xanh",
        weight = 10000, -- 3000,
        stack = true,
        close = true
    },

    ["pantfish"] = {
        label = "Cá Mập Trắng Lớn",
        weight = 10000,
        stack = true,
        close = true
    },

    ["sharkfish"] = {
        label = "Cá Chà Bặc",
        weight = 10000, -- 5000,
        stack = true,
        close = true
    },

    ["boomc4"] = {label = "Boom C4", weight = 1000, stack = true, close = true},

    ["kimphaboom"] = {
        label = "Kìm Phá Boom",
        weight = 1000,
        stack = true,
        close = true
    },

    ["thanduoc"] = {
        label = "Thần dược",
        weight = 1000,
        stack = true,
        close = true
    },

    ["banthietkem4"] = {
        label = "Bản thiết kế m4a4",
        weight = 1000,
        stack = true,
        close = true
    },
    ["premium_pass"] = {
        label = "Sổ premium",
        weight = 1000,
        stack = true,
        close = true
    },

    ["hom_skin_ig"] = {
        label = "Hom Skin Ingame",
        weight = 1000,
        stack = true,
        close = true,
        allowArmed = true,
        consume = 0,
        server = {export = 'w_mohom.hom'}
    },

    ["hom_skin_donate"] = {
        label = "Hom Skin",
        weight = 1000,
        stack = true,
        close = true,
        allowArmed = true,
        consume = 0,
        server = {export = 'w_mohom.hom'}
    },

    ["sh"] = {
        label = "Xe SH",
        weight = 1000,
        stack = true,
        close = true,
        client = {usetime = 0},
        allowArmed = true
    },

    ["xecat"] = {
        label = "Xe Cat",
        weight = 1000,
        stack = true,
        close = true,
        client = {usetime = 0},
        allowArmed = true
    },

    ["liartable"] = {
        label = "Bàn Liar",
        weight = 1000,
        stack = true,
        close = true
    },

    ["keycar"] = {
        label = "Chìa khóa xe",
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        degrade = 10080,
        decay = true,
        allowArmed = true,
        server = {export = 'w_keycar.keycar'}
    },

    ["seednoel"] = {
        label = "Hạt giống noel",
        weight = 1000,
        stack = true,
        close = true,
        allowArmed = true,
        consume = 0,
        server = {export = 'w_noel.seednoel'}
    },

    ["nuoctuoicay"] = {
        label = "Nước tưới cây",
        weight = 500,
        stack = true,
        close = true
    },

    ["phannpk"] = {
        label = "Phân NPK",
        weight = 500,
        stack = true,
        close = true
    },

    ["gonoel"] = {
        label = "Gỗ Thông",
        weight = 500,
        stack = true,
        close = true
    },

    ["ngoisao"] = {
        label = "Ngôi sao",
        weight = 500,
        stack = true,
        close = true
    },

    ["quachau"] = {
        label = "Quả châu",
        weight = 500,
        stack = true,
        close = true
    },

    ["qua_cherry"] = {
        label = "Quả Cherry",
        weight = 200,
        stack = true,
        close = true
    },

    ["qua_dao"] = {
        label = "Quả Đào",
        weight = 200,
        stack = true,
        close = true
    },

    ["qua_nho"] = {
        label = "Quả Nho",
        weight = 200,
        stack = true,
        close = true
    },

    ["qua_tao"] = {
        label = "Quả Táo",
        weight = 200,
        stack = true,
        close = true
    },

    ["qua_chuoi"] = {
        label = "Quả Chuối",
        weight = 200,
        stack = true,
        close = true
    },

    ['meat'] = {
        label = 'Thịt bò',
        weight = 350,
        degrade = 7160,
        decay = true,
        stack = true,
        close = true,
        description = 'Thị bò'
    },

    ['boxed_meat'] = {
        label = 'Thùng đựng thịt',
        weight = 2500,
        degrade = 7160,
        decay = true,
        stack = false,
        close = true,
        description = 'Thùng thịt bò',
        client = {usetime = 5000}
    },

    ["giay"] = {label = "Giấy", weight = 100, stack = true, close = true},

    ["box"] = {
        label = "Thùng rỗng",
        weight = 2000,
        stack = true,
        close = true
    },

    ["bia_trai_caycherry"] = {
        label = "Bia Cherry",
        weight = 5000,
        stack = true,
        close = true
    },

    ["bia_trai_caytao"] = {
        label = "Bia Táo",
        weight = 5000,
        stack = true,
        close = true
    },

    ["bia_trai_caynho"] = {
        label = "Bia Nho",
        weight = 5000,
        stack = true,
        close = true
    },

    ["bia_trai_caychuoi"] = {
        label = "Bia Chuối",
        weight = 5000,
        stack = true,
        close = true
    },

    ["bia_trai_caydao"] = {
        label = "Bia Đào",
        weight = 5000,
        stack = true,
        close = true
    },

    ["homgiangsinh"] = {
        label = "Hòm giáng sinh",
        weight = 500,
        stack = true,
        close = true,
        allowArmed = true,
        consume = 0,
        server = {export = 'w_mohom.hom'}
    },

    ["bitcoin"] = {label = "Bit coin", weight = 1, stack = true, close = true},

    ["coin"] = {
        label = "Coin",
        weight = 0,
        stack = true,
        close = true,
        description = "Dùng để đổi Coin"
    },

    ["the_nha_manh_1"] = {
        label = "Thẻ nhà mảnh 1",
        weight = 200,
        stack = true,
        close = true,
        description = "Đồ bẩn từ một vụ lau nhà"
    },

    ["the_nha_manh_2"] = {
        label = "Thẻ nhà mảnh 2",
        weight = 200,
        stack = true,
        close = true,
        description = "Đồ bẩn từ một vụ lau nhà"
    },

    ["the_nha"] = {
        label = "Thẻ Nhà",
        weight = 20,
        stack = true,
        close = true,
        description = "Đồ bẩn từ một vụ lau nhà"
    },

    ["the_outfit"] = {
        label = "Thẻ Quần áo",
        weight = 100,
        stack = true,
        close = true,
        description = "Vật phẩm Event"
    },


    ["banh_trung_thu"] = {
        label = "Bánh Trung thu",
        weight = 100,
        stack = true,
        close = true,
        description = "Vật phẩm Event"
    },

    ["hom_trung_thu"] = {
        label = "Hòm Quay Trung thu",
        weight = 100,
        stack = true,
        close = true,
        description = "Vật phẩm Event"
    },

    ["hom_trung_thu_ig"] = {
        label = "Hòm Quay Trung thu IG",
        weight = 100,
        stack = true,
        close = true,
        description = "Vật phẩm Event"
    },

    ["dong_ho"] = {
        label = "Đồng Hồ",
        weight = 300,
        stack = true,
        close = true,
        description = "Đồ bẩn từ một vụ lau nhà"
    },

    ["vong_tay"] = {
        label = "Vòng Tay",
        weight = 300,
        stack = true,
        close = true,
        description = "Đồ bẩn từ một vụ lau nhà"
    },

    ["nhan"] = {
        label = "Nhẫn",
        weight = 300,
        stack = true,
        close = true,
        description = "Đồ bẩn từ một vụ lau nhà"
    },

    ["tv"] = {
        label = "TiVI",
        weight = 1000,
        stack = true,
        close = true,
        description = "Đồ bẩn từ một vụ lau nhà"
    },
    ["lovisong"] = {
        label = "Lò Vi Sóng",
        weight = 10000,
        stack = false,
        close = true,
        description = "Đồ bẩn từ một vụ lau nhà"
    },

    ["but"] = {label = "Bút", weight = 1, stack = true, close = true},

    ["xichcho"] = {
        label = "Xích Chó",
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        description = "Dây xích để bắt chó khi đi bộ. Đứng gần chó và sử dụng item này.",
        client = {export = 'xn_tromcho.UseXichCho'}
    },

    ["thonglong"] = {
        label = "Thòng Lọng",
        weight = 800,
        stack = true,
        close = true,
        description = "Thòng lọng để bắt chó từ xa khi đang trên xe máy. Ngồi sau xe và sử dụng khi gần chó.",
        client = {export = 'xn_tromcho.UseThongLong'}
    },

    ["cho_husky"] = {
        label = "Chó Husky",
        weight = 15000,
        stack = false,
        close = true,
        description = "Một con chó Husky đã được bắt. (đồ bẩn)"
    },

    ["cho_poodle"] = {
        label = "Chó Poodle",
        weight = 8000,
        stack = false,
        close = true,
        description = "Một con chó Poodle đã được bắt. (đồ bẩn)"
    },

    ["cho_pug"] = {
        label = "Chó Pug",
        weight = 7000,
        stack = false,
        close = true,
        description = "Một con chó Pug đã được bắt. (đồ bẩn)"
    },

    ["cho_retriever"] = {
        label = "Chó Retriever",
        weight = 18000,
        stack = false,
        close = true,
        description = "Một con chó Retriever đã được bắt. (đồ bẩn)"
    },

    ["cho_rottweiler"] = {
        label = "Chó Rottweiler",
        weight = 20000,
        stack = false,
        close = true,
        description = "Một con chó Rottweiler đã được bắt. (đồ bẩn)"
    },

    ["cho_shepherd"] = {
        label = "Chó Shepherd",
        weight = 19000,
        stack = false,
        close = true,
        description = "Một con chó Shepherd đã được bắt. (đồ bẩn)"
    },

    ["cho_westy"] = {
        label = "Chó Westy",
        weight = 6000,
        stack = false,
        close = true,
        description = "Một con chó Westy đã được bắt. (đồ bẩn)"
    },

    ["casino_coke"] = {
        label = "Casino Kofola",
        weight = 0,
        stack = true,
        close = true
    },

    ["casino_donut"] = {
        label = "Casino Donut",
        weight = 0,
        stack = true,
        close = true
    },

    ["casino_ego_chaser"] = {
        label = "Casino Ego Chaser",
        weight = 0,
        stack = true,
        close = true
    },

    ["casino_luckypotion"] = {
        label = "Casino Lucky Potion",
        weight = 0,
        stack = true,
        close = true
    },

    ["casino_psqs"] = {
        label = "Casino Ps & Qs",
        weight = 0,
        stack = true,
        close = true
    },

    ["casino_sandwitch"] = {
        label = "Casino Sandwitch",
        weight = 0,
        stack = true,
        close = true
    },

    ["casino_sprite"] = {
        label = "Casino Sprite",
        weight = 0,
        stack = true,
        close = true
    },

    ["casino_beer"] = {
        label = "Casino Beer",
        weight = 0,
        stack = true,
        close = true
    },

    ["casinochips"] = {
        label = "Casino Chips",
        weight = 1,
        stack = true,
        close = false
    },

    ["casino_burger"] = {
        label = "Casino Burger",
        weight = 0,
        stack = true,
        close = true
    },

    ["casino_chips"] = {
        label = "Casino Chips",
        weight = 0,
        stack = true,
        close = true
    },

    ["casino_coffee"] = {
        label = "Casino Coffee",
        weight = 0,
        stack = true,
        close = true
    },

    ["gv_bearbites"] = {
        label = "Phụ kiện 118",
        weight = 100,
        stack = false,
        close = true,
        description = "Phụ kiện trang trí"
    },

    ["acc_hat_nonla"] = {
        label = "Phụ kiện 159",
        weight = 100,
        stack = false,
        close = true,
        description = "Phụ kiện trang trí"
    },

    ["digger"] = {
        label = "Phụ kiện 113",
        weight = 100,
        stack = false,
        close = true,
        description = "Phụ kiện trang trí",
        client = {image = "phukien_113.webp"}
    },

    ["acc_hat_mucoi"] = {
        label = "Phụ kiện 169",
        weight = 100,
        stack = false,
        close = true,
        description = "Phụ kiện trang trí",
        client = {image = "phukien_169.webp"}
    },

    ["gv_crownf"] = {
        label = "Phụ kiện 17",
        weight = 100,
        stack = false,
        close = true,
        description = "Phụ kiện trang trí",
        client = {image = "phukien_17.webp"}
    },

    ["gv_tet_catyummi"] = {
        label = "Phụ kiện 69",
        weight = 100,
        stack = false,
        close = true,
        description = "Phụ kiện trang trí",
        client = {image = "phukien_69.webp"}
    },
    ["quanoel"] = {
        label = "Quà Noel",
        weight = 200,
        stack = false,
        close = true,
        description = "Phụ kiện trang trí",
        client = {image = "quanoel.webp"},
        server = {export = 'w_mohom.hom'}
    },
    ["quanoel_vip"] = {
        label = "Quà Noel",
        weight = 200,
        stack = false,
        close = true,
        description = "Phụ kiện trang trí",
        client = {image = "quanoel_pre.webp"},
        server = {export = 'w_mohom.hom'}
    },
    ["gv_samuraiprop"] = {
        label = "Phụ kiện 62",
        weight = 100,
        stack = false,
        close = true,
        description = "Phụ kiện trang trí",
        client = {image = "phukien_62.webp"}
    },
    ["gv_razor"] = {
        label = "Phụ kiện 60",
        weight = 100,
        stack = false,
        close = true,
        description = "Phụ kiện trang trí",
        client = {image = "phukien_60.webp"}
    },
    ["gv_dogsit"] = {
        label = "Phụ kiện 187",
        weight = 100,
        stack = false,
        close = true,
        description = "Phụ kiện trang trí",
        client = {image = "phukien_187.webp"}
    },
    ["gv_elvesgirlblack"] = {
        label = "Phụ kiện 33",
        weight = 100,
        stack = false,
        close = true,
        description = "Phụ kiện trang trí",
        client = {image = "phukien_33.webp"}
    },

    ["boombox1"] = {
        label = "Boombox công dân",
        weight = 100,
        stack = false,
        close = true,
        description = "Hết Nhạc Con Về",
        client = {}
    },

    ["boombox"] = {
        label = "Boombox",
        weight = 100,
        stack = false,
        close = true,
        description = "Hết Nhạc Con Về",
        client = {}
    },

    ["wood"] = {label = "Wood", weight = 1, stack = true, close = true},

    ["stone"] = {label = "Stone", weight = 1, stack = true, close = true},

    ["aluminum"] = {
        label = "Nhôm",
        weight = 100,
        stack = true,
        close = false,
        description = "Mảnh kim loại đẹp mà bạn có thể sử dụng cho một thứ",
        client = {image = "aluminum.webp"}
    },

    ["plastic"] = {
        label = "Nhụa",
        weight = 500,
        stack = true,
        close = false,
        description = "Nhựa đã tinh luyện",
        client = {image = "plastic.webp"}
    },

    ["hdpe"] = {
        label = "Nhựa HDPE",
        weight = 200,
        stack = true,
        close = false,
        description = 'Nguyên liệu khai thác được từ nghề rã xe (Đồ bẩn)'
    },

    ["metalscrap"] = {
        label = "Sắt vụn",
        weight = 500,
        stack = true,
        close = false,
        description = 'Nguyên liệu khai thác được từ nghề rã xe (Đồ bẩn)'
    },

    ["glass"] = {
        label = "Thủy tinh vỡ",
        weight = 500,
        stack = true,
        close = false,
        description = "Thủy tinh thô"
    },

    ["vaivun"] = {
        label = "Vải vụn",
        weight = 500,
        stack = true,
        close = false,
        description = "Thường được dùng làm giẻ lau"
    },

    ["phutung"] = {
        label = "Phụ Tùng xe",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },

    ["thanvo"] = {
        label = "Thân vỏ xe",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },

    ["dochoixe"] = {
        label = "Đồ chơi xe",
        weight = 500,
        stack = true,
        close = true,
        description = 'Nguyên liệu khai thác được từ nghề rã xe (Đồ bẩn)'
    },

    ["packaged_plank"] = {
        label = "Packaged wood",
        weight = 1,
        stack = true,
        close = true
    },

    ["cutted_wood"] = {
        label = "Cut wood",
        weight = 1,
        stack = true,
        close = true
    },

    ["petrol_raffin"] = {
        label = "Processed oil",
        weight = 1,
        stack = true,
        close = true
    },

    ["essence"] = {label = "Gas", weight = 1, stack = true, close = true},

    ["washed_stone"] = {
        label = "Washed stone",
        weight = 1,
        stack = true,
        close = true
    },

    ["petrol"] = {label = "Oil", weight = 1, stack = true, close = true},

    ["dig"] = {label = "Trái Đào", weight = 200, stack = true, close = true},

    ["grape"] = {label = "Chùm Nho", weight = 200, stack = true, close = true},

    ["banana"] = {
        label = "Nải Chuối",
        weight = 200,
        stack = true,
        close = true
    },

    ["cherry"] = {
        label = "Quả Cherry",
        weight = 200,
        stack = true,
        close = true
    },

    ["apple"] = {label = "Quả Táo", weight = 200, stack = true, close = true},

    ["emptybox"] = {
        label = "Thùng Hàng",
        weight = 2000,
        stack = true,
        close = true,
        description = 'Nguyên liệu quan trọng đến từ kho hàng thành phố'
    },

    ['the_dau_gia'] = {
        label = 'Thẻ đấu giá',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lightstick dau gia'
    },

    ['stick1'] = {
        label = 'Lightstick Allstar 1',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lightstick dau gia',
        client = {export = 'stickxnallstars.use_stick1'}
    },

    ['stick2'] = {
        label = 'Lightstick Allstar 2',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lightstick dau gia',
        client = {export = 'stickxnallstars.use_stick2'}
    },

    ['stick3'] = {
        label = 'Lightstick Allstar 3',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lightstick dau gia',
        client = {export = 'stickxnallstars.use_stick3'}
    },

    ['stick4'] = {
        label = 'Lightstick Allstar 4',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lightstick dau gia',
        client = {export = 'stickxnallstars.use_stick4'}
    },

    ['stick5'] = {
        label = 'Lightstick Allstar 5',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lightstick dau gia',
        client = {export = 'stickxnallstars.use_stick5'}
    },

    ['stick6'] = {
        label = 'Lightstick Allstar 6',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lightstick dau gia',
        client = {export = 'stickxnallstars.use_stick6'}
    },

    ['stick7'] = {
        label = 'Lightstick Allstar 7',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lightstick dau gia',
        client = {export = 'stickxnallstars.use_stick7'}
    },

    ['stick8'] = {
        label = 'Lightstick Allstar 8',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lightstick dau gia',
        client = {export = 'stickxnallstars.use_stick8'}
    },

    ['stick9'] = {
        label = 'Lightstick Allstar 9',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lightstick dau gia',
        client = {export = 'stickxnallstars.use_stick9'}
    },

    ['stick10'] = {
        label = 'Lightstick Allstar 10',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lightstick dau gia',
        client = {export = 'stickxnallstars.use_stick10'}
    },

    ["ls_coal_ore"] = {
        label = "Qặng thô",
        weight = 1000,
        stack = true,
        close = true
    },

    ["ls_iron_ingot"] = {
        label = "Thỏi thép",
        weight = 1000,
        stack = true,
        close = true
    },

    ["ls_silver_ingot"] = {
        label = "Thỏi Bạc",
        weight = 1000,
        stack = true,
        close = true
    },

    ["ls_copper_ingot"] = {
        label = "Thỏi Đồng",
        weight = 1000,
        stack = true,
        close = true
    },

    ["may_cau"] = {
        label = "Máy câu",
        weight = 500,
        stack = true,
        close = true
    },

    ["steel"] = {label = "thép", weight = 300, stack = true, close = true},

    ["dong"] = {label = "Đồng", weight = 1000, stack = true, close = true},

    ["carbon"] = {label = "Carbon", weight = 100, stack = true, close = true},

    ["ngoclucbao"] = {
        label = "Ngọc Lục Bảo",
        weight = 300,
        stack = true,
        close = true
    },
    ["ruby"] = {label = "Ngọc Ruby", weight = 200, stack = true, close = true},
    ["damatho"] = {
        label = "Đá Mắt Hổ",
        weight = 400,
        stack = true,
        close = true
    },
    ["thachanhtim"] = {
        label = "Bùa Trống sịt",
        weight = 400,
        stack = true,
        close = true,
        description = "Dùng để trống sịt khi đập đồ"
    },

    ["bua_may_man"] = {
        label = "Đồng xu Bốn lá",
        weight = 1000,
        stack = true,
        close = true,
        description = "Dùng để đảm bảo không bị tụt cấp khi nâng cấp đồ"
    },

    ["co_bon_la_1"] = {
        label = "Cỏ bốn lá số 1",
        weight = 100,
        stack = true,
        close = true,
        description = "Dùng để đổi bùa trống sịt"
    },

    ["co_bon_la_2"] = {
        label = "Cỏ bốn lá số 2",
        weight = 100,
        stack = true,
        close = true,
        description = "Dùng để đổi bùa trống sịt"
    },

    ["co_bon_la_3"] = {
        label = "Cỏ bốn lá số 3",
        weight = 100,
        stack = true,
        close = true,
        description = "Dùng để đổi bùa trống sịt"
    },

    ["co_bon_la_4"] = {
        label = "Cỏ bốn lá số 4",
        weight = 100,
        stack = true,
        close = true,
        description = "Dùng để đổi bùa trống sịt"
    },

    ["co_bon_la_5"] = {
        label = "Cỏ bốn lá số 5",
        weight = 100,
        stack = true,
        close = true,
        description = "Dùng để đổi bùa trống sịt"
    },

    ["co_bon_la_6"] = {
        label = "Cỏ bốn lá số 6",
        weight = 100,
        stack = true,
        close = true,
        description = "Dùng để đổi bùa trống sịt"
    },

    ["co_bon_la_7"] = {
        label = "Cỏ bốn lá số 7",
        weight = 100,
        stack = true,
        close = true,
        description = "Dùng để đổi bùa trống sịt"
    },

    ["co_bon_la_8"] = {
        label = "Cỏ bốn lá số 8",
        weight = 100,
        stack = true,
        close = true,
        description = "Dùng để đổi bùa trống sịt"
    },

    ["co_bon_la_9"] = {
        label = "Cỏ bốn lá số 9",
        weight = 100,
        stack = true,
        close = true,
        description = "Dùng để đổi bùa trống sịt"
    },

    ["co_bon_la_10"] = {
        label = "Cỏ bốn lá số 10",
        weight = 100,
        stack = true,
        close = true,
        description = "Dùng để đổi bùa trống sịt"
    },

    ["diamond"] = {
        label = "Kim Cương",
        weight = 75,
        stack = true,
        close = true
    },

    ["vantruot_muc"] = {
        label = "ván trượt mực",
        weight = 500,
        stack = true,
        close = true
    },

    ["beer"] = {label = "Beer", weight = 1, stack = true, close = true},

    ["oldmoneywash"] = {
        label = "Máy giặt cũ",
        weight = 5000,
        stack = false,
        close = true,
        description = "Công cụ nghề bửn"
    },

    ["deluxemoneywash"] = {
        label = "Máy giặt cũ",
        weight = 7000,
        stack = false,
        close = true,
        description = "Công cụ nghề bửn"
    },

    ["xa_beng"] = {
        label = "Xà beng",
        weight = 7000,
        stack = false,
        close = true,
        description = "Đồ bẩn dùng để cậy nắp cống"
    },

    ["nap_cong"] = {
        label = "Nắp cống",
        weight = 7000,
        stack = false,
        close = true,
        description = "Nắp cống ăn trộm"
    },

    ["pokertable"] = {
        label = "Poker Table",
        weight = 1,
        stack = true,
        close = true
    },

    -------mechanic
    ---
    ["paints_chameleon"] = {
        label = "Sơn Đặc biệt",
        weight = 1000,
        stack = true,
        close = true,
        description = "Dùng để sơn các màu sắc siêu đặc biệt cho xế yêu"
    },
    
    ["engine_s"] = {
        label = "Engine S",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["engine_a"] = {
        label = "Engine A",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["engine_b"] = {
        label = "Engine B",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["engine_c"] = {
        label = "Engine C",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["engine_d"] = {
        label = "Engine D",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["transmission_s"] = {
        label = "Transmission S",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["transmission_a"] = {
        label = "Transmission A",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["transmission_b"] = {
        label = "Transmission B",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["transmission_c"] = {
        label = "Transmission C",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["transmission_d"] = {
        label = "Transmission D",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["suspension_s"] = {
        label = "Suspension S",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["suspension_a"] = {
        label = "Suspension A",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["suspension_b"] = {
        label = "Suspension B",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["suspension_c"] = {
        label = "Suspension C",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["suspension_d"] = {
        label = "Suspension D",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["brake_s"] = {
        label = "Brake S",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["brake_a"] = {
        label = "Brake A",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["brake_b"] = {
        label = "Brake B",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["brake_c"] = {
        label = "Brake C",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["brake_d"] = {
        label = "Brake D",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["turbo_s"] = {
        label = "Turbo S",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["turbo_a"] = {
        label = "Turbo A",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["turbo_b"] = {
        label = "Turbo B",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["turbo_c"] = {
        label = "Turbo C",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["turbo_d"] = {
        label = "Turbo D",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["armour_s"] = {
        label = "Armour S",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["armour_a"] = {
        label = "Armour A",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["armour_b"] = {
        label = "Armour B",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["armour_c"] = {
        label = "Armour C",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["armour_d"] = {
        label = "Armour D",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["engine_repair_kit"] = {
        label = "Engine repair kit",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },
    ["body_repair_kit"] = {
        label = "Body repair kit",
        weight = 1000,
        stack = true,
        close = true,
        description = ""
    },

    ['mechspray'] = {
        label = 'Sơn xe',
        weight = 500,
        stack = true,
        close = true,
        description = 'Dùng để sơn xe với nhiều màu khác nhau',
        client = {image = 'mechspray.webp'}
    },

    ['cosmetics'] = {
        label = 'Đồ trang trí xe',
        weight = 200,
        stack = true,
        close = true,
        description = 'Các phụ kiện trang trí cho xe'
    },

    ['neon_custom'] = {
        label = 'Bóng đèn gầm',
        weight = 200,
        stack = true,
        close = true,
        description = 'Các phụ kiện trang trí cho xe'
    },

    -- Wheels & Rims
    ['car_wheel'] = {
        label = 'Mâm xe',
        weight = 1500,
        stack = true,
        close = true,
        description = 'Mâm xe chất lượng cao cho nhiều loại xe'
    },

    -- Body Parts
    ['spoiler'] = {
        label = 'Cánh gió',
        weight = 800,
        stack = true,
        close = true,
        description = 'Cánh gió thể thao cho xe'
    },

    ['front_bumper'] = {
        label = 'Cản trước',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Cản trước thể thao'
    },

    ['rear_bumper'] = {
        label = 'Cản sau',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Cản sau thể thao'
    },

    ['skirtcar'] = {
        label = 'Ốp hông',
        weight = 600,
        stack = true,
        close = true,
        description = 'Ốp hông thể thao cho xe'
    },

    ['exhaust'] = {
        label = 'Ống xả',
        weight = 1200,
        stack = true,
        close = true,
        description = 'Ống xả thể thao, tăng hiệu suất'
    },

    ['car_hood'] = {
        label = 'Nắp capo',
        weight = 1500,
        stack = true,
        close = true,
        description = 'Nắp capo carbon fiber'
    },

    -- Interior Items
    ['horn'] = {
        label = 'Còi xe',
        weight = 100,
        stack = true,
        close = true,
        description = 'Còi xe với nhiều âm thanh khác nhau'
    },

    ['internals'] = {
        label = 'Phụ kiện nội thất',
        weight = 300,
        stack = true,
        close = true,
        description = 'Các phụ kiện trang trí nội thất xe'
    },

    ['seats'] = {
        label = 'Ghế xe',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Ghế thể thao chất lượng cao'
    },

    -- Engine & Performance
    ['engine_block'] = {
        label = 'Khối động cơ',
        weight = 5000,
        stack = true,
        close = true,
        description = 'Khối động cơ hiệu suất cao'
    },

    -- Plates & Livery
    ['vanity_plate'] = {
        label = 'Biển số trang trí',
        weight = 50,
        stack = true,
        close = true,
        description = 'Biển số tùy chỉnh'
    },

    ['livery'] = {
        label = 'Tem dán',
        weight = 100,
        stack = true,
        close = true,
        description = 'Tem dán trang trí cho xe'
    },

    ["mechanic_toolbox"] = {
        label = "Mechanics toolbox",
        weight = 1000,
        stack = true,
        close = true,
        description = "",
        client = {export = 'mt_workshops.openToolboxMenu'}
    },
    ["neons_controller"] = {
        label = "Neons controller",
        weight = 1000,
        stack = true,
        close = true,
        description = "Điều khiển dèn",
        client = {export = 'mt_workshops.openLightsController'}
    },
    ["mods_list"] = {
        label = "Vehicle mods list",
        weight = 0,
        stack = true,
        close = true,
        description = "",
        client = {export = 'mt_workshops.openCosmeticsMenu'}
    },
    ["extras_controller"] = {
        label = "Vehicle extras",
        weight = 0,
        stack = true,
        close = true,
        description = "",
        client = {export = 'mt_workshops.openExtrasMenu'}
    },

    ['chameleon_spray'] = {
        label = 'Sơn Chameleon',
        weight = 500,
        stack = true,
        description = 'Sơn đặc biệt với hiệu ứng đổi màu Chameleon'
    },

    ['chameleonpaint_161'] = {
        label = 'Monochrome Spray',
        weight = 1,
        stack = true,
        consume = 1,
        close = true,
        description = 223,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },
    ['chameleonpaint_162'] = {
        label = 'Night & Day Spray',
        weight = 1,
        stack = true,
        close = true,
        consume = 1,
        description = 224,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },
    ['chameleonpaint_163'] = {
        label = 'The Verlierer Spray',
        weight = 1,
        stack = true,
        consume = 1,
        close = true,
        description = 225,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },
    ['chameleonpaint_164'] = {
        label = 'Sprunk Extreme Spray',
        weight = 1,
        stack = true,
        consume = 1,
        close = true,
        description = 226,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },
    ['chameleonpaint_165'] = {
        label = 'Vice City Spray',
        weight = 1,
        stack = true,
        consume = 1,
        close = true,
        description = 227,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },
    ['chameleonpaint_166'] = {
        label = 'Synthwave Nights Spray',
        weight = 1,
        stack = true,
        consume = 1,
        close = true,
        description = 228,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },
    ['chameleonpaint_167'] = {
        label = 'Four Seasons Spray',
        weight = 1,
        stack = true,
        close = true,
        consume = 1,
        description = 229,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },
    ['chameleonpaint_168'] = {
        label = 'Maisonette 9 Throwback Spray',
        weight = 1,
        stack = true,
        consume = 1,
        close = true,
        description = 230,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },
    ['chameleonpaint_169'] = {
        label = 'Bubblegum Spray',
        weight = 1,
        consume = 1,
        stack = true,
        close = true,
        description = 231,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },
    ['chameleonpaint_170'] = {
        label = 'Full Rainbow Spray',
        weight = 1,
        stack = true,
        close = true,
        consume = 1,
        description = 232,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },
    ['chameleonpaint_171'] = {
        label = 'Sunset Spray',
        weight = 1,
        stack = true,
        close = true,
        consume = 1,
        description = 233,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },
    ['chameleonpaint_172'] = {
        label = 'The Seven Spray',
        weight = 1,
        stack = true,
        close = true,
        description = 234,
        consume = 1,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },
    ['chameleonpaint_173'] = {
        label = 'Kamen Rider Spray',
        weight = 1,
        stack = true,
        close = true,
        description = 235,
        consume = 1,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },
    ['chameleonpaint_174'] = {
        label = 'Chromatic Aberration Sprayool',
        weight = 1,
        stack = true,
        close = true,
        description = 236,
        consume = 1,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },
    ['chameleonpaint_175'] = {
        label = 'Its Christmas! Spray',
        weight = 1,
        stack = true,
        close = true,
        description = 237,
        consume = 1,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },
    ['chameleonpaint_176'] = {
        label = 'Temperature Spray',
        weight = 1,
        stack = true,
        close = true,
        description = 238,
        consume = 1,
        client = {export = 'chameleonpaint.chameleonpaint'}
    },

    ['bo_ly'] = {
        label = 'Bộ ly',
        weight = 1000,
        stack = false,
        close = true,
        durability = 100,
        description = 'Bộ ly thủy tinh'
    },

    ['bich_da'] = {
        label = 'Bịch đá',
        weight = 1000,
        stack = false,
        close = true,
        durability = 100,
        description = 'Bịch đá lạnh'
    },

    ['nuoc_cot_dua'] = {
        label = 'Nước cốt dừa',
        weight = 1000,
        stack = false,
        close = true,
        durability = 100,
        description = 'Dùng để chế biến các đồ uống từ dừa'
    },

    ['nuoc_dua'] = {
        label = 'Nước dừa tươi',
        weight = 300,
        client = {
            status = {thirst = 300000},
            anim = {dict = 'mp_player_intdrink', clip = 'loop_bottle'},
            prop = {
                model = prop_ld_flow_bottle,
                pos = vec3(0.03, 0.03, 0.02),
                rot = vec3(0.0, 0.0, -1.5)
            },
            usetime = 10000,
            cancel = true,
            notification = 'Đã quá CoCo ơi !'
        },
        stack = true,
        allowArmed = true
    },

    ['coco_bar'] = {
        label = 'cocktail dừa',
        weight = 200,
        client = {
            status = {thirst = 400000, stress = -100000},
            anim = {dict = 'mp_player_intdrink', clip = 'loop_bottle'},
            prop = {
                model = prop_ld_flow_bottle,
                pos = vec3(0.03, 0.03, 0.02),
                rot = vec3(0.0, 0.0, -1.5)
            },
            usetime = 5000,
            cancel = true,
            notification = 'Đã quá CoCo ơi !'
        },
        stack = true,
        allowArmed = true
    },

    ['bao_thuoc'] = {
        label = 'Bao thuốc lá',
        weight = 1000,
        stack = false,
        close = true,
        durability = 100,
        description = 'Bao thuốc lá'
    },

    ['bao_thuoc_lion'] = {
        label = 'Bao thuốc lá',
        weight = 1000,
        stack = false,
        close = true,
        durability = 100,
        description = 'Bao thuốc lá'
    },

    ['thung_thuoc_la'] = {
        label = 'Thùng thuốc lá',
        weight = 10000,
        stack = false,
        close = true,
        durability = 100,
        description = 'Thùng thuốc lá'
    },

    ["ciga"] = {
        label = "Thuốc Lá Lion",
        weight = 1000,
        stack = true,
        close = true,
        description = "Hết hạn",
        client = {
        }
    },

    ["ciga_hp"] = {
        label = "Thuốc Lá SD",
        weight = 1000,
        stack = true,
        close = true,
        description = "Thơm ngon như Cáo",
        client = {
        }
    },

    ["vodka"] = {
        label = 'Rượu Vodka',
        weight = 1000,
        stack = false,
        close = true,
        durability = 100,
        description = 'Dùng để pha chế'
    },
    --- lan bien
    ['diving_gear'] = {
        label = 'Bình lặn',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Sử dụng bình lặn để lặn dưới nước',
        client = {
            export = 'XN_DevMode.UseDivingGearCivilian'
        }
    },

    ['binhlannghanh'] = {
        label = 'Bình lặn ngành',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Sử dụng bình lặn để lặn dưới nước',
        client = {
            export = 'XN_DevMode.UseDivingGear'
        }
    },

    ['vesuaxenghanh'] = {
        label = 'Vé sửa xe nghành',
        weight = 100,
        stack = true,
        close = true,
        description = 'Vé sửa xe nghành',
        client = {}
    },

    ["aluminiumcan"] = {
        label = "Lon nhôm",
        weight = 100,
        stack = true,
        close = false,
        description = "Một chiếc lon rỗng bằng nhôm",
        client = {}
    },

    ["steelcan"] = {
        label = "Bình tưới nước bằng thép",
        weight = 100,
        stack = true,
        close = false,
        description = "Trông như đang bắt đầu rỉ sét",
        client = {}
    },

    ["brokenphone"] = {
        label = "Điện thoại hỏng",
        weight = 100,
        stack = true,
        close = false,
        description = "Có thể đáng giá nếu mang đến tiệm cầm đồ (đồ bẩn)",
        client = {}
    },

    ["pocketwatch"] = {
        label = "Đồng hồ bỏ túi",
        weight = 100,
        stack = true,
        close = false,
        description = "Kính của đồng hồ bị sứt mẻ (đồ bẩn)",
        client = {}
    },

    ["brokenknife"] = {
        label = "Con dao gãy",
        weight = 100,
        stack = true,
        close = false,
        description = "Có thể đáng giá nếu mang đến tiệm cầm đồ (đồ bẩn)",
        client = {}
    },

    ["brokengameboy"] = {
        label = "Máy Gameboy hỏng",
        weight = 100,
        stack = true,
        close = false,
        description = "Có thể đáng giá nếu mang đến tiệm cầm đồ (đồ bẩn)",
        client = {}
    },

    ["treasurekey"] = {
        label = "Chìa khóa kho báu",
        weight = 100,
        stack = true,
        close = false,
        description = "Trông như đang bắt đầu rỉ sét (đồ bẩn)",
        client = {}
    },

    ["whitepearl"] = {
        label = "Ngọc trai trắng",
        weight = 5000,
        stack = true,
        close = true,
        description = "Một viên ngọc từ biển cả (đồ bẩn)"
    },

    ["bluepearl"] = {
        label = "Ngọc trai xanh dương",
        weight = 5000,
        stack = true,
        close = true,
        description = "Một viên ngọc từ biển cả (đồ bẩn)"
    },

    ["redpearl"] = {
        label = "Ngọc trai đỏ",
        weight = 5000,
        stack = true,
        close = true,
        description = "Một viên ngọc từ biển cả (đồ bẩn)"
    },

    ["greenpearl"] = {
        label = "Ngọc trai xanh lá",
        weight = 5000,
        stack = true,
        close = true,
        description = "Một viên ngọc từ biển cả (đồ bẩn)"
    },

    ["yellowpearl"] = {
        label = "Ngọc trai vàng",
        weight = 5000,
        stack = true,
        close = true,
        description = "Một viên ngọc từ biển cả (đồ bẩn)"

    },

    ["antiquecoin"] = {
        label = "Đồng xu cổ",
        weight = 100,
        stack = true,
        close = false,
        description = "Đồng xu cũ, có thể đáng giá nếu mang đến tiệm cầm đồ (đồ bẩn)",
        client = {}
    },

    ["goldcoin"] = {
        label = "Đồng xu vàng",
        weight = 100,
        stack = true,
        close = false,
        description = "Có thể đáng giá nếu mang đến tiệm cầm đồ (đồ bẩn)",
        client = {}
    },

    ["aincientcoin"] = {
        label = "Đồng xu cổ xưa",
        weight = 1,
        stack = true,
        close = false,
        description = "Một đồng xu rất cổ (đồ bẩn)",
        client = {}
    },

    ["goldchain"] = {
        label = "Dây chuyền vàng",
        weight = 100,
        stack = true,
        close = false,
        description = "Có thể đáng giá nếu mang đến tiệm cầm đồ (đồ bẩn)",
        client = {}
    },

    ["10kgoldchain"] = {
        label = "Dây chuyền vàng 10k",
        weight = 100,
        stack = true,
        close = false,
        description = "Đồ cổ, có thể đáng giá nếu mang đến tiệm cầm đồ (đồ bẩn)",
        client = {}
    },

    ["rolex"] = {
        label = "Đồng hồ Rolex",
        weight = 100,
        stack = true,
        close = false,
        description = "Chiếc đồng hồ cao cấp sang trọng (Đồ bẩn)",
        client = {}
    },

    ["burriedtreasure"] = {
        label = "Kho báu chôn vùi",
        weight = 1000,
        stack = true,
        close = false,
        description = "Có thể đáng giá nếu mang đến tiệm cầm đồ (đồ bẩn)",
        client = {}
    },

    ["danangcap"] = {
        label = "Đá Nâng Cấp",
        weight = 200,
        stack = true,
        close = true,
        description = "Đá nâng cấp vũ khí"
    },

    ["cong_thuc_co_le"] = {
        label = "Công thức Cờ lê",
        weight = 100,
        stack = true,
        close = true,
        description = "Bản thiết kế cho một chiếc cờ lê",
        client = {}
    },

    ["cong_thuc_machete"] = {
        label = "Công thức Machete",
        weight = 100,
        stack = true,
        close = true,
        description = "Bản thiết kế cho một chiếc Machete",
        client = {}
    },

    ["buamaymancapmot"] = {
        label = "Bùa may mắn lV1",
        weight = 200,
        stack = true,
        close = true,
        description = "Tăng tỉ lệ may mắn khi nâng cấp"
    },

    ["buamaymancaphai"] = {
        label = "Bùa may mắn lV2",
        weight = 200,
        stack = true,
        close = true,
        description = "Tăng tỉ lệ may mắn khi nâng cấp"
    },

    ["buamaymancapba"] = {
        label = "Bùa may mắn lV3",
        weight = 200,
        stack = true,
        close = true,
        description = "Tăng tỉ lệ may mắn khi nâng cấp"
    },

    ['chieungu'] = {
        label = 'Tấm chiếu mới',
        weight = 1000,
        stack = false,
        close = true,
        cangive = true,
        durability = 100,
        description = "Một tấm chiếu mới, chưa từng trải"

    },

    ['chieungu_newbie'] = {
        label = 'Tấm chiếu mới',
        weight = 10,
        stack = true,
        close = true,
        cangive = true,
        durability = 100,
        description = "Một tấm chiếu mới, chưa từng trải, sử dụng để ngủ lang"

    },

    ['bolauxe'] = {
        label = 'Bộ lau xe',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Hãy giữ cho xế cưng luôn như mới',
        client = {}
    },

    -- Dụng cụ thám hiểm
    ['ongnhom'] = {
        label = 'Ống nhòm',
        weight = 500,
        stack = true,
        close = true,
        description = 'Ống nhòm để quan sát từ xa'
    },

  ['place_poster'] = {
      label = 'Poster',
      weight = 100,
      stack = true,
      close = true,
      description = 'Công cụ đặt poster'
  },

  ['remove_poster'] = {
      label = 'Clean tools',
      weight = 100,
      stack = true,
      close = true,
      description = 'Công cụ xóa poster'
  },
    
    -- Rèn vũ khí
    ['congcuren'] = {
        label = 'Công cụ rèn vũ khí',
        weight = 5000,
        stack = true,
        close = true,
        description = 'Công cụ chuyên dụng để rèn vũ khí'
    },

    ['vatlieuren'] = {
        label = 'Vật liệu rèn vũ khí',
        weight = 5000,
        stack = true,
        close = true,
        description = 'Vật liệu rèn vũ khí'
    },

    ['gochuyendung'] = {
        label = 'Gỗ chuyên dụng',
        weight = 5000,
        stack = true,
        close = true,
        description = 'Vật liệu rèn vũ khí'
    },

    ['manhkimloai'] = {
        label = 'Mảnh kim loại hiếm',
        weight = 5000,
        stack = true,
        close = true,
        description = 'Nguyên liệu hiếm từ Nghề cưa bom'
    },

    -- Nghề cưa bom
    ['maydomin'] = {
        label = 'Máy dò mìn',
        weight = 500,
        stack = false,
        close = true,
        durability = 100,
        description = 'Máy dò mìn, dùng trong Đồ bẩn Cưa bom'
    },

    ['traimin'] = {
        label = 'Trái mìn',
        weight = 3000,
        stack = true,
        close = true,
        description = 'Trái mìn, dùng trong Đồ bẩn Khó nói'
    },

    -- Nghề khoáng sản
    ["caixeng"] = {
        label = "Xẻng",
        weight = 500,
        stack = false,
        close = true,
        durability = 100,
        description = "Công cụ khai thác khoáng sản"
        -- consume = 0.2,
    },

    ["chaodaivang"] = {
        label = "Chảo khoáng sản",
        weight = 500,
        stack = false,
        close = true,
        durability = 100,
        description = "Công cụ khai thác khoáng sản"
        -- consume = 0.2,
    },

    ["chaodaivang1"] = {
        label = "Chảo khoáng sản",
        weight = 500,
        stack = false,
        close = true,
        durability = 100,
        description = "Công cụ khai thác khoáng sản LV1"
        -- consume = 0.2,
    },

    ["chaodaivang2"] = {
        label = "Chảo khoáng sản",
        weight = 500,
        stack = false,
        close = true,
        durability = 100,
        description = "Công cụ khai thác khoáng sản LV2"
        -- consume = 0.2,
    },

    ["chaodaivang3"] = {
        label = "Chảo khoáng sản",
        weight = 500,
        stack = false,
        close = true,
        durability = 100,
        description = "Công cụ khai thác khoáng sản LV3"
        -- consume = 0.2,
    },

    ["chaodaivang4"] = {
        label = "Chảo khoáng sản",
        weight = 500,
        stack = false,
        close = true,
        durability = 100,
        description = "Công cụ khai thác khoáng sản LV4"
        -- consume = 0.2,
    },

    ["chaodaivang5"] = {
        label = "Chảo khoáng sản",
        weight = 500,
        stack = false,
        close = true,
        durability = 100,
        description = "Công cụ khai thác khoáng sản LV5"
        -- consume = 0.2,
    },
    -- Nghề hốt rác
    ['dohotrac'] = {
        label = 'Đồ hốt rác',
        weight = 500,
        stack = false,
        close = true,
        durability = 100,
        description = 'Đồ hốt rác, dùng cho nghề hốt rác ở quảng trường'
    },

    ['racthai'] = {
        label = 'Rác thải',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Rác thải trong nghề hốt rác'
    },

    ['racthaidaphanloai'] = {
        label = 'Rác thải đã phân loại',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Rác thải đã phân loại trong nghề hốt rác'
    },

    -- Nguyên liệu từ nghề khoáng sản
    ['soi'] = {
        label = 'Sỏi',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Sỏi thu được từ nghề khoáng sản'
    },

    ['than'] = {
        label = 'Than',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Than thu được từ nghề khoáng sản'
    },

    ['sat'] = {
        label = 'Sắt',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Sắt thu được từ nghề khoáng sản'
    },

    ['vang'] = {
        label = 'Vàng',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Vàng thu được từ nghề khoáng sản'
    },

    ['kimcuong'] = {
        label = 'Kim cương',
        weight = 5000,
        stack = true,
        close = true,
        description = 'Kim cương thu được từ nghề khoáng sản'
    },

    ['broom'] = {
        label = 'Chổi',
        weight = 500,
        stack = false,
        close = true,
        description = 'Chổi dùng để quét rác'
    },

    ['trash'] = {
        label = 'Rác',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Rác từ công viên'
    },

    ['plastic_taiche'] = {
        label = 'Nhựa Tái Chế',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Nhựa được tái chế từ rác'
    },

    ['lachabon'] = {
        label = 'Lá Chà Bồn',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Chắc phải có công dụng gì đó?'
    },

    ['bones'] = {
        label = 'Xương',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Xương cũ được tìm thấy khi thăm dò',
        client = {image = 'bones.webp'}
    },

    ['nuts_and_bolts'] = {
        label = 'Đai ốc và bu lông',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Đai ốc và bu lông kim loại',
        client = {}
    },

    ['gold_ring'] = {
        label = 'Nhẫn vàng',
        weight = 20,
        stack = true,
        close = true,
        description = 'Một chiếc nhẫn vàng quý giá',
        client = {}
    },

    ['dragon_scales'] = {
        label = 'Vảy rồng',
        weight = 150,
        stack = true,
        close = true,
        description = 'Vảy rồng hiếm',
        client = {}
    },

    ['vodanhong'] = {
        label = 'Vỏ đạn hỏng',
        weight = 1000,
        stack = true,
        close = true,
        description = 'vỏ đạn đã qua sử dụng',
        client = {}
    },

    ['khuyentaicu'] = {
        label = 'Khuyên Tai Cũ',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Một chiếc khuyên tai cũ',
        client = {}
    },

    ['machdienchay'] = {
        label = 'Mạch Điện Cháy',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Mạch điện đã bị cháy',
        client = {}
    },

    ['thuocsung'] = {
        label = 'thuốc súng',
        weight = 1000,
        stack = true,
        close = true,
        description = 'khó nói (Black Item)',
        client = {}
    },

    ['manh_boom_vo'] = {
        label = 'Mảnh Bom',
        weight = 1000,
        stack = true,
        close = true,
        description = 'khó nói (Black Item)',
        client = {}
    },

    ['orange'] = {
        label = 'Cam sành',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Cam sành mọng nước'
    },

    ['fruit_basket'] = {
        label = 'Sọt hái cam',
        weight = 2000,
        stack = false,
        close = true,
        durability = 100,
        description = 'Dụng cụ hái cam sử dụng để chứa 20 quả cam'
    },

    ['cattho'] = {
        label = 'Cát thô',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Cát thô cần được sàng rửa'
    },

    ['kimloainang'] = {
        label = 'Kim loại nặng',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Kim loại quý hiếm'
    },

    ['hopquagiangsinh'] = {
        label = 'Hộp Quà',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Một hộp quà bí ẩn'
    },

    ['chuonggiangsinh'] = {
        label = 'Chuông giáng sinh',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Nguyên liệu để đổi một hộp quà'
    },

    ['tatgiangsinh'] = {
        label = 'Tất giáng sinh',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Nguyên liệu để đổi một hộp quà'
    },

    ['giaygoiqua'] = {
        label = 'Giấy gói quà',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Nguyên liệu để đổi một hộp quà'
    },

    ['firework_box'] = {
        label = 'Hộp Pháo Hoa',
        weight = 500,
        stack = true,
        close = true,
        client = {export = 'phaohoa.useFirework'},
        description = 'Sử dụng để tạo nên một màn trình diễn ánh sáng rực rỡ.'
    },

    ['thedoiten'] = {
        label = 'Thẻ Đổi Tên',
        weight = 50,
        stack = true,
        close = true,
        consume = 0,
        client = {export = 'thedoiten.UseChangeNameCard'},
        description = 'Sử dụng để đổi tên'
    },

    -- Item để spawn động vật
    ['trung_thu'] = {
        label = 'Trứng Thú',
        weight = 2000,
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
        weight = 5000,
        stack = true,
        close = true,
        description = 'Con bò trưởng thành đã được chăm sóc'
    },

    -- Phần thưởng từ Deer
    ['aplaca'] = {
        label = 'Alpaca',
        weight = 10000,
        stack = true,
        close = true,
        description = 'Con alpaca trưởng thành đã được chăm sóc'
    },

    ['rose'] = {
        label = 'Hoa hồng',
        weight = 100,
        stack = true,
        close = true,
        description = 'Dành cho Juliett'
    },

    ['controller'] = {
        label = 'Tay cầm chơi game',
        weight = 200,
        stack = true,
        close = true,
        description = 'FIFA tốt hơn'
    },

    ['hat'] = {
        label = 'Mũ nông dân',
        weight = 50,
        stack = true,
        close = true,
        description = 'Chúng tôi sống trên cánh đồng'
    },

    ['hat2'] = {
        label = 'Mũ cứng',
        weight = 100,
        stack = true,
        close = true,
        description = 'An toàn tính mạng là trên hết'
    },

    ['teddybear'] = {
        label = 'Gấu bông',
        weight = 300,
        stack = true,
        close = true,
        description = 'Chonkie...'
    },

    ['glasses'] = {
        label = 'Kính râm',
        weight = 50,
        stack = true,
        close = true,
        description = 'Mặt trời không được phép'
    },

    ['glasses2'] = {
        label = 'Tấm che màu cam',
        weight = 50,
        stack = true,
        close = true,
        description = 'Một tấm che màu cam đẹp'
    },

    ['tennisball'] = {
        label = 'Bóng Tennis',
        weight = 100,
        stack = true,
        close = true,
        description = 'Ném bóng cho thú cưng đi nhặt'
    },

    ['petbowl'] = {
        label = 'Bát ăn thú cưng',
        weight = 200,
        stack = true,
        close = true,
        description = 'Bát để cho thú cưng ăn uống'
    },

    ['petbed'] = {
        label = 'Giường thú cưng',
        weight = 500,
        stack = true,
        close = true,
        description = 'Giường ngủ cho thú cưng'
    },

    ['petbed2'] = {
        label = 'Giường thú cưng (Loại 2)',
        weight = 500,
        stack = true,
        close = true,
        description = 'Giường ngủ cho thú cưng'
    },

    ['nametag'] = {
        label = 'Thẻ tên',
        weight = 10,
        stack = true,
        close = true,
        description = 'Đặt tên cho thú cưng của bạn'
    },

    ['coolglasses'] = {
        label = 'Kính mát',
        weight = 50,
        stack = true,
        close = true,
        description = 'Người yêu tuyệt vời của tôi!'
    },

    -- VÒNG CỔ
    ['collar'] = {
        label = 'Cổ áo màu nâu',
        weight = 50,
        stack = true,
        close = true,
        description = 'Tôi có chủ rồi!'
    },

    ['collar2'] = {
        label = 'Cổ áo đen',
        weight = 50,
        stack = true,
        close = true,
        description = 'Tôi có chủ rồi!'
    },

    ['collar3'] = {
        label = 'Cổ áo trắng',
        weight = 50,
        stack = true,
        close = true,
        description = 'Tôi có chủ rồi!'
    },

    ['collar4'] = {
        label = 'Cổ áo màu vàng',
        weight = 50,
        stack = true,
        close = true,
        description = 'Tôi có chủ rồi!'
    },

    ['collar5'] = {
        label = 'Cổ áo xanh',
        weight = 50,
        stack = true,
        close = true,
        description = 'Tôi có chủ rồi!'
    },

    ['collar6'] = {
        label = 'Cổ áo màu hồng',
        weight = 50,
        stack = true,
        close = true,
        description = 'Tôi có chủ rồi!'
    },

    ['collar7'] = {
        label = 'Cổ áo có hoa văn',
        weight = 50,
        stack = true,
        close = true,
        description = 'Tôi có chủ rồi!'
    },

    ['bluebandana'] = {
        label = 'Khăn rằn màu xanh',
        weight = 50,
        stack = true,
        close = true,
        description = 'Băng nhóm, pug!'
    },

    ['blackbandana'] = {
        label = 'Khăn rằn màu đen',
        weight = 50,
        stack = true,
        close = true,
        description = 'Băng nhóm, pug!'
    },

    -- SỪNG UNICORN
    ['unihorn'] = {
        label = 'Sừng vàng',
        weight = 100,
        stack = true,
        close = true,
        description = 'Thú cưng của tôi ở xứ sở thần tiên'
    },

    ['unihorn2'] = {
        label = 'Sừng xanh',
        weight = 100,
        stack = true,
        close = true,
        description = 'Thú cưng của tôi ở xứ sở thần tiên'
    },

    ['unihorn3'] = {
        label = 'Sừng xanh (Loại 2)',
        weight = 100,
        stack = true,
        close = true,
        description = 'Thú cưng của tôi ở xứ sở thần tiên'
    },

    ['unihorn4'] = {
        label = 'Sừng cam',
        weight = 100,
        stack = true,
        close = true,
        description = 'Thú cưng của tôi ở xứ sở thần tiên'
    },

    ['unihorn5'] = {
        label = 'Sừng xanh hải quân',
        weight = 100,
        stack = true,
        close = true,
        description = 'Thú cưng của tôi ở xứ sở thần tiên'
    },

    ['unihorn6'] = {
        label = 'Sừng xanh nhạt',
        weight = 100,
        stack = true,
        close = true,
        description = 'Thú cưng của tôi ở xứ sở thần tiên'
    },

    ['unihorn7'] = {
        label = 'Sừng xám',
        weight = 100,
        stack = true,
        close = true,
        description = 'Thú cưng của tôi ở xứ sở thần tiên'
    },

    ['unihorn8'] = {
        label = 'Sừng hồng cam',
        weight = 100,
        stack = true,
        close = true,
        description = 'Thú cưng của tôi ở xứ sở thần tiên'
    },

    ['unihorn9'] = {
        label = 'Sừng màu be',
        weight = 100,
        stack = true,
        close = true,
        description = 'Thú cưng của tôi ở xứ sở thần tiên'
    },

    -- MŨ NHỎ
    ['tinyhat'] = {
        label = 'Mũ nhỏ màu nâu',
        weight = 50,
        stack = true,
        close = true,
        description = 'Một chiếc mũ nhỏ xinh xắn'
    },

    ['tinyhat2'] = {
        label = 'Mũ nhỏ màu vàng',
        weight = 50,
        stack = true,
        close = true,
        description = 'Một chiếc mũ nhỏ xinh xắn'
    },

    ['tinyhat3'] = {
        label = 'Mũ nhỏ màu xanh',
        weight = 50,
        stack = true,
        close = true,
        description = 'Một chiếc mũ nhỏ xinh xắn'
    },

    ['tinyhat4'] = {
        label = 'Mũ nhỏ màu lục lam',
        weight = 50,
        stack = true,
        close = true,
        description = 'Một chiếc mũ nhỏ xinh xắn'
    },

    ['tinyhat5'] = {
        label = 'Mũ nhỏ màu xanh (Loại 2)',
        weight = 50,
        stack = true,
        close = true,
        description = 'Một chiếc mũ nhỏ xinh xắn'
    },

    ['tinyhat6'] = {
        label = 'Mũ nhỏ màu tím',
        weight = 50,
        stack = true,
        close = true,
        description = 'Một chiếc mũ nhỏ xinh xắn'
    },

    ['tinyhat7'] = {
        label = 'Mũ nhỏ màu hồng',
        weight = 50,
        stack = true,
        close = true,
        description = 'Một chiếc mũ nhỏ xinh xắn'
    },

    ['tinyhat8'] = {
        label = 'Mũ nhỏ màu đỏ',
        weight = 50,
        stack = true,
        close = true,
        description = 'Một chiếc mũ nhỏ xinh xắn'
    },

    ['tinyhat9'] = {
        label = 'Mũ nhỏ màu cam',
        weight = 50,
        stack = true,
        close = true,
        description = 'Một chiếc mũ nhỏ xinh xắn'
    },

    ['tinyhat10'] = {
        label = 'Mũ nhỏ màu be',
        weight = 50,
        stack = true,
        close = true,
        description = 'Một chiếc mũ nhỏ xinh xắn'
    },

    -- ÁO VEST & PHỤ KIỆN
    ['beewings'] = {
        label = 'Cánh ong',
        weight = 100,
        stack = true,
        close = true,
        description = 'Bumblebeeeee'
    },

    ['batmanvest'] = {
        label = 'Áo khoác Batman',
        weight = 200,
        stack = true,
        close = true,
        description = 'Thành phố cần anh...'
    },

    ['redvest'] = {
        label = 'Áo khoác đỏ',
        weight = 200,
        stack = true,
        close = true,
        description = 'Thoải mái'
    },

    ['elytecollar'] = {
        label = 'Cổ áo Elyte',
        weight = 100,
        stack = true,
        close = true,
        description = 'Giai cấp tư sản!'
    },

    ['blackvest'] = {
        label = 'Áo vest đen',
        weight = 200,
        stack = true,
        close = true,
        description = 'Màu đen tốt hơn'
    },

    ['bowtie'] = {
        label = 'Cà vạt',
        weight = 50,
        stack = true,
        close = true,
        description = 'Sẵn sàng vào ban đêm'
    },

    ['daisyvest'] = {
        label = 'Áo hoa cúc',
        weight = 200,
        stack = true,
        close = true,
        description = 'Những bông hoa..'
    },

    ['petchef'] = {
        label = 'Mũ trùm',
        weight = 100,
        stack = true,
        close = true,
        description = 'Thơm ngon'
    },

    ['daisycrown'] = {
        label = 'Vương miện hoa cúc',
        weight = 100,
        stack = true,
        close = true,
        description = 'Daisy yêu thích của tôi'
    },

    ['petdeer'] = {
        label = 'Sừng hươu',
        weight = 150,
        stack = true,
        close = true,
        description = 'Giống như một con nai sừng tấm'
    },

    ['petchain'] = {
        label = 'Xích',
        weight = 150,
        stack = true,
        close = true,
        description = 'Nhỏ giọt thật mạnh'
    },

    ['partyglasses'] = {
        label = 'Kính Party',
        weight = 50,
        stack = true,
        close = true,
        description = 'Rung cảm'
    },

    ['beetail'] = {
        label = 'Đuôi ong',
        weight = 50,
        stack = true,
        close = true,
        description = 'Bumblebeeeee'
    },

    ['beadnecklace'] = {
        label = 'Vòng cổ hạt',
        weight = 100,
        stack = true,
        close = true,
        description = 'Vòng cổ hạt lạ mắt'
    },

    ['pinksweater'] = {
        label = 'Áo len hồng',
        weight = 200,
        stack = true,
        close = true,
        description = 'Giữ ấm áp và ấm cúng'
    },

    ['xmasvest'] = {
        label = 'Áo giáng sinh',
        weight = 200,
        stack = true,
        close = true,
        description = 'Giáng sinh vui vẻ'
    },

    ['brownshoes'] = {
        label = 'Giày màu nâu',
        weight = 150,
        stack = true,
        close = true,
        description = 'Kiểm tra nikey của tôi'
    },

    ['fairyvest'] = {
        label = 'Áo cổ tích',
        weight = 200,
        stack = true,
        close = true,
        description = 'Giống như một câu chuyện cổ tích'
    },

    ['k9vest'] = {
        label = 'Áo vest K9',
        weight = 250,
        stack = true,
        close = true,
        description = 'Cho chó cảnh sát chuyên nghiệp'
    },

    -- DÂY XÍch
    ['leash'] = {
        label = 'Dây xích thú cưng',
        weight = 100,
        stack = true,
        close = true,
        description = 'Dây dắt thú cưng đi dạo'
    },

    ['leash2'] = {
        label = 'Dây xích thú cưng (Loại 2)',
        weight = 100,
        stack = true,
        close = true,
        description = 'Dây dắt thú cưng đi dạo'
    },

    ['leash3'] = {
        label = 'Dây xích thú cưng (Loại 3)',
        weight = 100,
        stack = true,
        close = true,
        description = 'Dây dắt thú cưng đi dạo'
    },
    -- 🐱 MÈO (Cats - 2 pets)
    ['pet_a_c_cat_01'] = {
        label = 'Mèo',
        weight = 50,
        stack = false,
        close = true,
        description = 'Mèo (Thú cưng)',
        client = {export = 'dt-thucung.SpawnPetFromItem'}
    },

    ['pet_dusa_sphynx'] = {
        label = 'Mèo Sphynx',
        weight = 50,
        stack = false,
        close = true,
        description = 'Mèo Sphynx (Thú cưng)',
        client = {export = 'dt-thucung.SpawnPetFromItem'}
    },
    -- 🐕 CHÓ NHỎ (Small Dogs - 3 pets)
    ['pet_a_c_poodle_2'] = {
        label = 'Chó Poodle',
        weight = 100,
        stack = false,
        close = true,
        description = 'Chó Poodle (Thú cưng)',
        client = {export = 'dt-thucung.SpawnPetFromItem'}
    },

    ['pet_a_c_pug'] = {
        label = 'Chó Pug',
        weight = 100,
        stack = false,
        close = true,
        description = 'Chó Pug (Thú cưng)',
        client = {export = 'dt-thucung.SpawnPetFromItem'}
    },

    ['pet_a_c_westy_2'] = {
        label = 'Chó Westy',
        weight = 100,
        stack = false,
        close = true,
        description = 'Chó Westy (Thú cưng)',
        client = {export = 'dt-thucung.SpawnPetFromItem'}
    },

    -- 🐕 CHÓ VỪA (Mid Dogs - 3 pets)
    ['pet_a_c_retriever_2'] = {
        label = 'Chó Golden Retriever',
        weight = 120,
        stack = false,
        close = true,
        description = 'Chó Golden Retriever (Thú cưng)',
        client = {export = 'dt-thucung.SpawnPetFromItem'}
    },

    ['pet_a_c_husky_2'] = {
        label = 'Chó Husky',
        weight = 120,
        stack = false,
        close = true,
        description = 'Chó Husky (Thú cưng)',
        client = {export = 'dt-thucung.SpawnPetFromItem'}
    },

    ['pet_dusa_englishbulldog'] = {
        label = 'Chó Bulldog Anh',
        weight = 120,
        stack = false,
        close = true,
        description = 'Chó Bulldog Anh (Thú cưng)',
        client = {export = 'dt-thucung.SpawnPetFromItem'}
    },

    -- 🐕 CHÓ LỚN (Big Dogs - 4 pets)
    ['pet_a_c_chop'] = {
        label = 'Chó Rottweiler',
        weight = 150,
        stack = false,
        close = true,
        description = 'Chó Rottweiler (Thú cưng)',
        client = {export = 'dt-thucung.SpawnPetFromItem'}
    },

    ['pet_a_c_shepherd_2'] = {
        label = 'Chó Becgie',
        weight = 150,
        stack = false,
        close = true,
        description = 'Chó Becgie (Thú cưng)',
        client = {export = 'dt-thucung.SpawnPetFromItem'}
    },

    ['pet_dusa_cane'] = {
        label = 'Chó Cane Corso',
        weight = 150,
        stack = false,
        close = true,
        description = 'Chó Cane Corso (Thú cưng)',
        client = {export = 'dt-thucung.SpawnPetFromItem'}
    },

    ['pet_dusa_doberman'] = {
        label = 'Chó Doberman',
        weight = 150,
        stack = false,
        close = true,
        description = 'Chó Doberman (Thú cưng)',
        client = {export = 'dt-thucung.SpawnPetFromItem'}
    },
    ['thedoitenpet'] = {
        label = 'Thẻ Đổi Tên Pet',
        weight = 100,
        stack = true,
        close = true,
        description = 'Sử dụng để đổi tên thú cưng của bạn',
        client = {export = 'dt-thucung.UseRenamePetCard'}
    },

    ["chuc"] = {label = "Chúc", weight = 0, stack = true, close = true},

    ["mung"] = {label = "Mừng", weight = 0, stack = true, close = true},

    ["nam"] = {label = "Năm", weight = 0, stack = true, close = true},

    ["moi"] = {label = "Mới", weight = 0, stack = true, close = true},

    ["2026"] = {label = "2026", weight = 0, stack = true, close = true},

    ["banvevukhi"] = {
        label = "Bản Vẽ Vũ Khí",
        weight = 1000,
        stack = true,
        close = true,
        description = 'Nguyên liệu chế tạo vũ khí.'

    },
    
    ["banvevukhi1"] = {
        label = "Bản Vẽ Vũ Khí I",
        weight = 0,
        stack = true,
        close = true
    },

    ["banvevukhi2"] = {
        label = "Bản Vẽ Vũ Khí II",
        weight = 0,
        stack = true,
        close = true
    },

    ["banvevukhi3"] = {
        label = "Bản Vẽ Vũ Khí III",
        weight = 0,
        stack = true,
        close = true
    },

    ["banvevukhi4"] = {
        label = "Bản Vẽ Vũ Khí IV",
        weight = 0,
        stack = true,
        close = true
    },

    ["hopdongbannha"] = {
        label = "Hợp Đồng Bán Nhà",
        weight = 0,
        stack = true,
        close = true
    },
    ["setoi"] = {
        label = "Hàng Siêu Hiếm, Mới 99%",
        weight = 0,
        stack = false,
        close = true,
        client = {export = 'mini_dildo_item.useItem'}
    },
    ['plasma_drill'] = {
        label = 'Plasma Drill',
        weight = 10000,
        stack = false,
        close = true,
        description = 'Máy khoan plasma công nghệ cao để phá két sắt.'
    },
    ['skateboard'] = {
        label = 'Skateboard',
        weight = 2000,
        stack = false,
        close = true,
        description = 'Một chiếc ván trượt để dạo quanh thành phố Mini City.'
    },

    ['dongho_kimcuong'] = {
        label = 'Đồng Hồ Kim Cương',
        weight = 500, -- nặng 0.5kg, chỉnh lại nếu muốn
        stack = false, -- đồng hồ là đồ giá trị, thường không stack
        close = true, -- đóng menu sau khi nhặt / dùng
        description = 'Chiếc đồng hồ vàng đính kim cương cực kỳ sang trọng.'
    },

    ['khuyentai_lucbao'] = {
        label = 'Khuyên Tai Lục Bảo',
        weight = 100,
        stack = true, -- có thể sở hữu nhiều cặp
        close = true,
        description = 'Cặp khuyên tai đính lục bảo sáng rực.'
    },

    ['lactay_vang24k'] = {
        label = 'Lắc Tay Vàng 24K',
        weight = 300,
        stack = true,
        close = true,
        description = 'Lắc tay vàng 24K bản to, dành cho dân chơi đúng nghĩa.'
    },

    ["maykhoan"] = {
        label = 'Máy Khoan',
        weight = 2000,
        stack = false,
        close = true,
        description = 'Một cái máy khoan thông dụng.'
    },
    ["dienthoaihong"] = {
        label = 'Điện Thoại Hỏng',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Một cái điện thoại hỏng.'
    },
    ["vitien"] = {
        label = 'Ví cũ',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Một chiếc ví tiền.'
    },
    ["nhancuoi"] = {
        label = 'Nhẫn Cưới',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Một chiếc nhẫn cưới.'
    },
    ["boncau"] = {
        label = 'Bồn Cầu',
        weight = 20000,
        stack = true,
        close = true,
        description = 'Một cái bồn cầu.'
    },
    ["tablet"] = {
        label = 'Máy Tính Bảng',
        weight = 500,
        stack = true,
        close = true,
        description = 'Một chiếc máy tính bảng hiện đại.',
        client = {event = 'tablet:openMenu'}
    },

    ["racing_tablet"] = {
        label = 'Máy Tính Bảng',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Một chiếc máy tính bảng hiện đại.'
    },

    ['afk_rare_reward'] = {
        weight = 1000,
        label = "Vật Phẩm Hiếm",
        stack = true,
        close = true,
        description = "Vật phẩm dành cho những người Đẳng S Cấp"
    },

    ['the_sieu_trom'] = {
        label = 'Thẻ Siêu Trộm',
        weight = 1000,
        stack = true,
        close = true,
        description = "Vật phẩm dành cho những người Đẳng S Cấp"
    },

    ["tinhthach"] = {
        label = "Thiên Thạch",
        weight = 1000,
        stack = true,
        close = true,
        description = "Đồ có được từ đáo đá trái phép (Nghề bẩn)"
    },

    ["tinhthach_hiem"] = {
        label = "Tinh Thạch Hiếm",
        weight = 1000,
        stack = true,
        close = true,
        description = "Đồ có được từ đáo đá trái phép (Nghề bẩn)"
    },

    ['ladudu_tuoi'] = {
        label = 'Lá Đu Đủ Tươi',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Lá đu đủ vừa mới hái, cần phơi khô để chế biến (Đồ bẩn)'
    },

    ['ladudu_kho'] = {
        label = 'Lá Đu Đủ Khô',
        weight = 500,
        stack = true,
        close = true,
        description = 'Lá đu đủ đã được phơi khô, có thể quấn thành điếu (Đồ bẩn)'
    },

    ['lathuocla'] = {
        label = 'Lá thuốc lá',
        weight = 500,
        stack = true,
        close = true,
        description = 'Lá thuốc lá thơm ngon'
    },

    ['la_hoamynhan'] = {
        label = 'Lá Hoa mỹ nhân',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Lá Hoa mỹ nhân vừa mới hái, cần phơi khô để chế biến (Đồ bẩn)'
    },

    ['hoa_mynhan'] = {
        label = 'Hoa mỹ nhân',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Hoa mỹ nhân vừa mới hái, Đẹp như tiên nữ (Đồ bẩn)'
    },

    ['goi_dudu_say'] = {
        label = 'Gói đu đủ sấy',
        weight = 1000,
        stack = true,
        close = true,
        description = '1 điếu lên tiên (Đồ bẩn)'
    },

    ['traidudu'] = {
        label = 'Trái Đu Đủ',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Trái đu đủ đột biến gen (Đồ bẩn)'
    },

    ['sinhto_dudu'] = {
        label = 'Sinh Tố Đu Đủ',
        weight = 1000,
        stack = true,
        close = true,
        description = 'sinh tố đu đủ, được xay từ đu đủ đột biến gen, có tác dụng tăng cường sinh lực chị em rất thích (Đồ bẩn)'
    },

    ['dieududu'] = {
        label = 'Điếu Đu Đủ',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Một điếu đu đủ, cả thành phố hóa hư không',
        client = {export = 'mini_hethongnghien.UseItemClient'}
    },

    ["vebanxevip"] = {
        label = "Vé Bán Xe VIP",
        weight = 1000,
        stack = true,
        close = true,
        description = "Sử dụng để bán các dòng xe VIP tại chợ xe cũ"
    },


    ["gplxb"] = {
        label = "GPLX Hạng B",
        weight = 0,
        stack = false,
        close = false,
        description = "Giấy phép lái xe hạng B - Ô tô",
        client = {image = "driver_license.webp"}
    },

    ["gplxc"] = {
        label = "GPLX Hạng C",
        weight = 0,
        stack = false,
        close = false,
        description = "Giấy phép lái xe hạng C - Xe tải",
        client = {image = "driver_license.webp"}
    },

    ["gplxmaybay"] = {
        label = "GPLX Máy Bay",
        weight = 0,
        stack = false,
        close = false,
        description = "Giấy phép lái máy bay",
        client = {image = "driver_license.webp"}
    },

    ['baolixi'] = {
        label = 'Bao Lì Xì Tết',
        weight = 50,
        stack = true,
        close = true,
        description = 'Bao lì xì may mắn từ Linh Thú Tết năm 2026',
        client = {}
    },

    ["pet_lion"] = {
        label = 'Kỳ Lân',
        weight = 150,
        stack = false,
        close = true,
        description = 'Kỳ Lân (Thú cưng)',
        client = {export = 'dt-thucung.SpawnPetFromItem'}
    },

    ["voucher_cardealer_5"] = {
        label = 'Voucher Cardealer 5%',
        weight = 1,
        stack = true,
        close = true,
        description = 'Phiếu giảm giá xe 5%'
    },

    ["voucher_cardealer_10"] = {
        label = 'Voucher Cardealer 10%',
        weight = 1,
        stack = true,
        close = true,
        description = 'Phiếu giảm giá xe 10%'
    },

    ["voucher_cardealer_15"] = {
        label = 'Voucher Cardealer 15%',
        weight = 1,
        stack = true,
        close = true,
        description = 'Phiếu giảm giá xe 15%'
    },

    ["voucher_mechanic"] = {
        label = 'Voucher Mechanic',
        weight = 1,
        stack = true,
        close = true,
        description = 'Phiếu giảm giá sửa xe'
    },

    ["cammuoitu"] = {
        label = 'Cam Mười Tú',
        weight = 5000,
        stack = true,
        close = true,
        description = 'Cam Mười Tú'
    },

    ["lucbao"] = {
        label = 'Ngọc Lục Bảo',
        weight = 10000,
        stack = true,
        close = true,
        description = 'Ngọc Lục Bảo quý giá'
    },

    ['chibi_pet'] = {
        label = 'Chibi Pet',
        weight = 100,
        stack = false,
        close = true,
        description = 'Tinh linh xinh đẹp....'
    },
    ['bong_hoa'] = {
        label = 'Bông Hoa',
        weight = 100,
        stack = true,
        close = true,
        description = 'Một bông hoa tươi thắm dành tặng nhân dịp 8/3 🌸'
    },

    ['bo_hoa'] = {
        label = 'Bó Hoa',
        weight = 300,
        stack = true,
        close = true,
        description = 'Một bó hoa xinh đẹp dành tặng nhân dịp 8/3 💐'
    },

    ["chuocdonhatro"] = {
        label = 'Giấy chuộc đồ nhà trọ',
        weight = 100,
        stack = false,
        close = true,
        description = 'Dùng để chuộc lại đồ bị tịch thu khi hết hạn thuê trọ. Chỉ có hiệu lực trong vòng 7 ngày kể từ khi bị tịch thu.',
        client = {export = 'xn_motels.claimConfiscated'}
    },

    ["bienlai"] = {
        label = 'Biên lai',
        weight = 100,
        stack = true,
        close = true,
        description = "Biên lai giao dịch điếu đu đủ"
    },

    ["trangsucbac"] = {
        label = 'Trang sức bạc',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Trang sức bạc'
    },

    ["hopden"] = {
        label = 'Hộp Đen',
        weight = 5000,
        stack = true,
        close = true,
        description = 'Thiết bị giám sát hành trình'
    },
    ["fixkitnganh"] = {
        label = "Bộ sửa xe ngành",
        weight = 2000,
        stack = true,
        close = true
    },
    ["mayxaysinhto"] = {
        label = "Máy xay sinh tố",
        weight = 2000,
        stack = true,
        close = true,
        description = "máy xay sinh tố nhập khẩu từ nước ngoài về, có thể xay được tất cả các loại trái cây"
    },
    ["dududongthung"] = {
        label = "Thùng sinh tố đu đủ",
        weight = 8500,
        stack = false,
        close = true,
        description = "Thùng sinh tố đu đủ, được đóng gói từ những bịch sinh tố đột biến gen"
    },

    ["hommayman"] = {
        label = "Hòm may mắn",
        weight = 2000,
        stack = true,
        close = true,
        description = "Thùng sinh tố đu đủ, được đóng gói từ những bịch sinh tố đột biến gen"
    },
    ["mayhanmini"] = {
        label = 'Máy hàn mini',
        weight = 100,
        stack = true,
        close = true,
        description = "Máy hàn mini, dùng để hàn các vật liệu nhỏ. Mất 5% độ bền mỗi lần sử dụng."
    },

    ["roll"] = {
        label = "Linh Kiện Điện Tử",
        weight = 500,
        stack = true,
        close = true
    },

    ["lo_xo"] = {
        label = "Lò Xo Đốt Nóng",
        weight = 500,
        stack = true,
        close = true
    },

    ["canxangrong"] = {
        label = "Can xăng rỗng",
        weight = 500,
        stack = true,
        close = true,
        description = "Can xăng rỗng, tang vật sau khi đốt nhà."
    },

    ['nuoc_cam'] = {
        label = 'Nước cam',
        weight = 300,
        stack = true,
        close = true,
        description = 'Nước cam tươi mát, giải khát'
    },

    -- Nguyên liệu
    ['nuoc_cam_nguyen_chat'] = {
        label = 'Nước cam nguyên chất',
        weight = 300,
        stack = true,
        close = false,
        description = 'Nước cam nguyên chất chưa pha chế'
    },

    ['ly'] = {
        label = 'Ly',
        weight = 1000,
        stack = true,
        close = false,
        description = 'Ly nhựa dùng để đựng đồ uống'
    },

    ['ong_hut'] = {
        label = 'Ống hút',
        weight = 100,
        stack = true,
        close = false,
        description = 'Ống hút giấy thân thiện môi trường'
    },

    ['duong'] = {
        label = 'Đường',
        weight = 100,
        stack = true,
        close = false,
        description = 'Đường trắng tinh luyện'
    },

    ['com_suon_tam_9h'] = {
        label = 'Cơm sườn tấm 9H',
        weight = 300,
        stack = true,
        close = true,
        description = 'Cơm tấm sườn bì chả đặc biệt'
    },

    ['com_suon_tam'] = {
        label = 'Cơm sườn tấm',
        weight = 300,
        stack = true,
        close = true,
        description = 'Cơm tấm sườn bì chả đặc biệt'
    },

    ['com_bo_luc_lac'] = {
        label = 'Cơm Bò lúc lắc',
        weight = 300,
        stack = true,
        close = true,
        description = 'Cơm Bò lúc lắc'
    },

    -- Nguyên liệu
    ['suon_nuong'] = {
        label = 'Sườn nướng',
        weight = 300,
        stack = true,
        close = false,
        description = 'Sườn heo đã được tẩm ướp và nướng chín'
    },

    ['hop_com'] = {
        label = 'Hộp cơm',
        weight = 100,
        stack = true,
        close = false,
        description = 'Hộp xốp đựng cơm mang đi'
    },

    ['dung_cu_an_uong'] = {
        label = 'Dụng cụ ăn uống',
        weight = 100,
        stack = true,
        close = false,
        description = 'Bộ muỗng nĩa dùng một lần'
    },

    ['gao'] = {
        label = 'Gạo',
        weight = 100,
        stack = true,
        close = false,
        description = 'Gạo tấm đã vo sạch'
    },
    ['maycat'] = {
        label = 'Máy cắt sắt',
        weight = 8000,
        stack = false,
        close = true,
        description = 'Dùng để tháo dỡ phụ tùng xe, có độ bền'
    },
    ['cuaxecu'] = {
        label = 'Cua xe cu',
        weight = 5000,
        stack = false,
        close = true,
        description = 'Cua xe da thao, co the ban cho tho phe lieu'
    },

    ['capocu'] = {
        label = 'Capo cũ',
        weight = 8000,
        stack = false,
        close = true,
        description = 'ắp capo đã tháo, có thể bán cho thợ phế liệu'
    },
    ['dongcocu'] = {
        label = 'Động cơ cũ',
        weight = 25000,
        stack = false,
        close = true,
        description = 'Động cơ xe đã tháo, có thể bán cho thợ phế liệu'
    },

    ['banhxecu'] = {
        label = 'Bánh xe cũ',
        weight = 3000,
        stack = false,
        close = true,
        description = 'Bánh xe đã tháo, có thể bán cho thợ phế liệu'
    },
    ['tructruyendong'] = {
        label = 'Trục truyền động cũ',
        weight = 6000,
        stack = false,
        close = true,
        description = 'Trục truyền động đã tháo, có thể bán'
    },

    ['boxecu'] = {
        label = 'Bô xe cũ',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Bô xe đã tháo, có thể bán'
    },
    ['thedoibiensoxe'] = {
        label = 'Thẻ đổi biển số xe',
        weight = 50,
        stack = true,
        close = true,
        description = 'Thẻ đổi biển số xe, có thể sử dụng để thay đổi biển số xe',
        client = {export = 'thedoiten.UseChangePlateCard'}
    },
    ['thedoisodienthoai'] = {
        label = 'Thẻ đổi số điện thoại',
        weight = 50,
        stack = true,
        close = true,
        description = 'Thẻ đổi số điện thoại, có thể sử dụng để thay đổi số điện thoại',
        client = {export = 'thedoiten.UseChangePhoneCard'}
    },
    ['bochongtromxe'] = {
        label = 'Hệ thống chống trộm',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Hệ thống chống trộm xe',
        client = {export = 'thedoiten.UseAntiTheftSystem'}
    },
    ['tacos'] = {
        label = 'Bánh Tacos',
        weight = 500,
        stack = true,
        close = true,
        description = 'Bánh Tacos mới ra lò'
    },

    ['banhran_ht'] = {
        label = 'Bánh Rán Doremon',
        weight = 300,
        stack = true,
        close = true,
        description = 'Bánh Hết hạn'
    },

    ['banhrandua_ht'] = {
        label = 'Bánh Rán dừa',
        weight = 300,
        stack = true,
        close = true,
        description = 'Bánh Rán Doremon mới ra lò'
    },

    ['banhmochi_ht'] = {
        label = 'Bánh Mochi',
        weight = 300,
        stack = true,
        close = true,
        description = 'Bánh Rán Mochi mới ra lò'
    },

    ['pizza_ht'] = {
        label = 'Pizza NôBiTa',
        weight = 500,
        stack = true,
        close = true,
        description = 'Pizza NôBiTa mới ra lò'
    },

    ['trada_utso'] = {
        label = 'Trà Đá Bụi đời',
        weight = 300,
        stack = true,
        close = true,
        description = 'Trà Đá Bụi đời, Chát như tình yêu của tuổi trẻ'
    },

    ['nuocdua_utso'] = {
        label = 'Nước dừa Bụi đời',
        weight = 500,
        stack = true,
        close = true,
        description = 'Trà Đá Bụi đời, ngọt như tình yêu của tuổi trẻ'
    },

    ['trasua'] = {
        label = 'Trà Sữa',
        weight = 500,
        stack = true,
        close = true,
        description = 'Trà sữa trân châu đường đen'
    },
    ['key_windsor'] = {
        label = 'Chìa khóa Windsor',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Chìa khóa xe Enus Windsor'
    },
    ['key_chiron'] = {
        label = 'Chìa khóa Bugatti Chiron',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Chìa khóa xe Bugatti Chiron'
    },

    ['key_draugur'] = {
        label = 'Chìa khóa Draugur',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Chìa khóa xe Draugur'
    },

    ['key_bmwm8'] = {
        label = 'Chìa khóa BMW M8',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Chìa khóa xe BMW M8'
    },

    ['key_batti_hlw'] = {
        label = 'Chìa khóa Skull Bike',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Chìa khóa xe Skull Bike'
    },

    ['key_gladitor'] = {
        label = 'Chìa khóa Gladitor',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Chìa khóa xe Gladitor'
    },

    ['key_amggt'] = {
        label = 'Chìa khóa AMG GT',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Chìa khóa xe Mercedes AMG GT Black Series 2021'
    },

    ['key_omnisegt'] = {
        label = 'Chìa khóa Omnise GT',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Chìa khóa xe OMNISE GT'
    },

    ['key_zl1'] = {
        label = 'Chìa khóa ZL1',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Chìa khóa xe Camaro ZL1'
    },

    ['goitaotac'] = {
        label = 'Gói Tạo Tác',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Bộ công cụ làm da thủ công'
    },

    ['vdm_tuychon'] = {
        label = 'Vé đổi mẫu (Tùy chọn)',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Vé đổi mẫu balo tùy chọn'
    },

    ['vdm_ngaunhien'] = {
        label = 'Vé đổi mẫu (Ngẫu nhiên)',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Vé đổi mẫu balo ngẫu nhiên'
    },

    ['keyring1'] = {
        label = 'Chùm Chìa Khóa Cấp 1',
        weight = 100,
        stack = false,
        close = true,
        consume = 0,
        description = "Chùm chìa khóa cấp 1 - 2 ô, 500g. Sử dụng để mở kho chứa chìa khóa xe.",
        client = {export = 'mini_dapphukien.keyring1'}
    },

    ['keyring2'] = {
        label = 'Chùm Chìa Khóa Cấp 2',
        weight = 100,
        stack = false,
        close = true,
        consume = 0,
        description = "Chùm chìa khóa cấp 2 - 4 ô, 1kg. Nâng cấp từ cấp 1.",
        client = {export = 'mini_dapphukien.keyring2'}
    },

    ['keyring3'] = {
        label = 'Chùm Chìa Khóa Cấp 3',
        weight = 100,
        stack = false,
        close = true,
        consume = 0,
        description = "Chùm chìa khóa cấp 3 - 6 ô, 1.5kg. Nâng cấp từ cấp 2.",
        client = {export = 'mini_dapphukien.keyring3'}
    },

    ['keyring4'] = {
        label = 'Chùm Chìa Khóa Cấp 4',
        weight = 100,
        stack = false,
        close = true,
        consume = 0,
        description = "Chùm chìa khóa cấp 4 - 8 ô, 2kg. Nâng cấp từ cấp 3.",
        client = {export = 'mini_dapphukien.keyring4'}
    },

    ['keyring5'] = {
        label = 'Chùm Chìa Khóa Cấp 5',
        weight = 100,
        stack = false,
        close = true,
        consume = 0,
        description = "Chùm chìa khóa cấp 5 - 10 ô, 2.5kg. Cấp độ tối đa!",
        client = {export = 'mini_dapphukien.keyring5'}
    },

    -- ============== VÍ GIẤY TỜ ==============
    ['vigiayto'] = {
        label = 'Ví Giấy Tờ',
        weight = 100,
        stack = false,
        close = true,
        consume = 0,
        description = "Ví giấy tờ - đựng giấy tờ tùy thân. Chỉ để nhận diện, không có chức năng."
    },

    ['vigiayto1'] = {
        label = 'Ví Giấy Tờ Cấp 1',
        weight = 100,
        stack = false,
        close = true,
        consume = 0,
        description = "Ví giấy tờ cấp 1 - 2 ô, 500g.",
        client = {export = 'mini_dapphukien.vigiayto1'}
    },

    ['vigiayto2'] = {
        label = 'Ví Giấy Tờ Cấp 2',
        weight = 100,
        stack = false,
        close = true,
        consume = 0,
        description = "Ví giấy tờ cấp 2 - 4 ô, 1kg.",
        client = {export = 'mini_dapphukien.vigiayto2'}
    },

    ['vigiayto3'] = {
        label = 'Ví Giấy Tờ Cấp 3',
        weight = 100,
        stack = false,
        close = true,
        consume = 0,
        description = "Ví giấy tờ cấp 3 - 6 ô, 1.5kg.",
        client = {export = 'mini_dapphukien.vigiayto3'}
    },

    ['vigiayto4'] = {
        label = 'Ví Giấy Tờ Cấp 4',
        weight = 100,
        stack = false,
        close = true,
        consume = 0,
        description = "Ví giấy tờ cấp 4 - 8 ô, 2kg.",
        client = {export = 'mini_dapphukien.vigiayto4'}
    },

    ['vigiayto5'] = {
        label = 'Ví Giấy Tờ Cấp 5',
        weight = 100,
        stack = false,
        close = true,
        consume = 0,
        description = "Ví giấy tờ cấp 5 - 10 ô, 2.5kg. Cấp độ tối đa!",
        client = {export = 'mini_dapphukien.vigiayto5'}
    },

    ['vali'] = {
        label = 'Vali',
        weight = 200,
        stack = false,
        close = true,
        consume = 0,
        description = "Vali - chỉ để nhận diện, không có chức năng."
    },

    ['vali1'] = {
        label = 'Vali Cấp 1',
        weight = 200,
        stack = false,
        close = true,
        consume = 0,
        description = "Vali cấp 1 - 5 ô, 500g.",
        client = {export = 'mini_dapphukien.vali1'}
    },

    ['vali2'] = {
        label = 'Vali Cấp 2',
        weight = 200,
        stack = false,
        close = true,
        consume = 0,
        description = "Vali cấp 2 - 10 ô, 1kg.",
        client = {export = 'mini_dapphukien.vali2'}
    },

    ['vali3'] = {
        label = 'Vali Cấp 3',
        weight = 200,
        stack = false,
        close = true,
        consume = 0,
        description = "Vali cấp 3 - 15 ô, 1.5kg.",
        client = {export = 'mini_dapphukien.vali3'}
    },

    ['vali4'] = {
        label = 'Vali Cấp 4',
        weight = 200,
        stack = false,
        close = true,
        consume = 0,
        description = "Vali cấp 4 - 20 ô, 2kg.",
        client = {export = 'mini_dapphukien.vali4'}
    },

    ['vali5'] = {
        label = 'Vali Cấp 5',
        weight = 200,
        stack = false,
        close = true,
        consume = 0,
        description = "Vali cấp 5 - 25 ô, 2.5kg. Cấp độ tối đa!",
        client = {export = 'mini_dapphukien.vali5'}
    },

    ['nhuatinhche'] = {
        label = 'Nhựa Tinh Chế',
        weight = 1000,
        stack = true,
        close = true,
        description = "Dùng để chế tạo"
    },
    ['datinhche'] = {
        label = 'Da Tinh Chế',
        weight = 1000,
        stack = true,
        close = true,
        description = "Dùng để chế tạo"
    },
    ['kimloaitinhche'] = {
        label = 'Kim Loại Tinh Chế',
        weight = 1000,
        stack = true,
        close = true,
        description = "Dùng để chế tạo"
    },
    ['oplung'] = {
        label = 'Ốp Lưng Cũ',
        weight = 200,
        stack = true,
        close = true,
        description = "Ốp lưng điện thoại đã qua sử dụng"
    },

    ["veso"] = {
        label = 'vé số mini',
        weight = 100,
        stack = false,
        close = true,
        description = "Chưa tới 8h20 chưa biết ai giàu hơn ai.",
        client = {event = 'banveso:openTicketInfo'}
    },

    ["cuiveso"] = {
        label = "Cùi vé số",
        weight = 100,
        stack = true,
        close = true,
        description = "Cùi vé số dùng để in vé bán."
    },

    ["bienlaichuyennhanh"] = {
        label = "Biên lai chuyển nhanh",
        weight = 1,
        stack = false,
        close = true,
        description = "Biên lai ký quỹ chuyển phát nhanh. Dùng để xác nhận giao hàng cho người nhận.",
        client = {event = 'xn_express:client:useReceiptItem'}
    },

    -- ============== THỊT THÚ RỪNG ==============
    ['thit_ga_rung'] = {
        label = 'Thịt Gà Rừng',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Thịt gà rừng tươi săn được trong rừng, có thể chế biến thành nhiều món ăn ngon.'
    },

    ['thit_tho_rung'] = {
        label = 'Thịt Thỏ Rừng',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Thịt thỏ rừng tươi săn được trong rừng, thịt mềm và thơm ngon.'
    },
    ['thit_chon_hoi'] = {
        label = 'Thịt Chồn Hôi',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Thịt chồn tươi săn được trong rừng, thịt mềm và thơm ngon.'
    },
    ['thit_chon_lui'] = {
        label = 'Thịt Chồn Lùi',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Thịt chồn tươi săn được trong rừng, thịt mềm và thơm ngon.'
    },

    ['tuner_pad'] = {
        label = 'Ipad độ xe',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Ipad dùng để hỗ trợ độ xe.'
    },

    ['xucxac'] = {
        label = 'Xúc Xắc',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Xúc xắc may mắn'
    },

    ['ys_sim_card'] = {
        label = 'Sim Card',
        stack = false,
        weight = 1000,
        consume = 0
    },

    ['usb_cable'] = {
        label = 'USB Type-C',
        weight = 50,
        stack = true,
        close = true,
        description = 'USB cable for charging.',
        client = {export = "yseries.UseUSBCable"}
    },

    ["yboomer_black"] = {
        label = "Boomer Phone",
        weight = 1000,
        stack = false,
        consume = 0,
        client = {
            export = "yboomer-phone.UsePhoneItem",
            remove = function()
                TriggerEvent("yboomer:client:phone-item-removed")
            end,
            add = function()
                TriggerEvent("yboomer:client:phone-item-added")
            end
        }
    },

    ["yphone_natural"] = {
        label = "YPhone Natural",
        weight = 1000,
        stack = false,
        consume = 0,
        client = {
            export = "yseries.UsePhoneItem",
            remove = function()
                TriggerEvent("yseries:phone-item-removed")
            end,
            add = function() TriggerEvent("yseries:phone-item-added") end
        }
    },
    ["yphone_black"] = {
        label = "YPhone Black",
        weight = 1000,
        stack = false,
        consume = 0,
        client = {
            export = "yseries.UsePhoneItem",
            remove = function()
                TriggerEvent("yseries:phone-item-removed")
            end,
            add = function() TriggerEvent("yseries:phone-item-added") end
        }
    },
    ["yphone_white"] = {
        label = "YPhone White",
        weight = 1000,
        stack = false,
        consume = 0,
        client = {
            export = "yseries.UsePhoneItem",
            remove = function()
                TriggerEvent("yseries:phone-item-removed")
            end,
            add = function() TriggerEvent("yseries:phone-item-added") end
        }
    },
    ["yphone_blue"] = {
        label = "YPhone Blue",
        weight = 1000,
        stack = false,
        consume = 0,
        client = {
            export = "yseries.UsePhoneItem",
            remove = function()
                TriggerEvent("yseries:phone-item-removed")
            end,
            add = function() TriggerEvent("yseries:phone-item-added") end
        }
    },
    ["yflip_mint"] = {
        label = "YFlip Mint",
        weight = 1000,
        stack = false,
        consume = 0,
        client = {
            export = "yseries.UsePhoneItem",
            remove = function()
                TriggerEvent("yseries:phone-item-removed")
            end,
            add = function() TriggerEvent("yseries:phone-item-added") end
        }
    },
    ["yflip_gold"] = {
        label = "YFlip Gold",
        weight = 1000,
        stack = false,
        consume = 0,
        client = {
            export = "yseries.UsePhoneItem",
            remove = function()
                TriggerEvent("yseries:phone-item-removed")
            end,
            add = function() TriggerEvent("yseries:phone-item-added") end
        }
    },
    ["yflip_graphite"] = {
        label = "YFlip Graphite",
        weight = 1000,
        stack = false,
        consume = 0,
        client = {
            export = "yseries.UsePhoneItem",
            remove = function()
                TriggerEvent("yseries:phone-item-removed")
            end,
            add = function() TriggerEvent("yseries:phone-item-added") end
        }
    },
    ["yflip_lavender"] = {
        label = "YFlip Lavender",
        weight = 1000,
        stack = false,
        consume = 0,
        client = {
            export = "yseries.UsePhoneItem",
            remove = function()
                TriggerEvent("yseries:phone-item-removed")
            end,
            add = function() TriggerEvent("yseries:phone-item-added") end
        }
    },
    ["y24_black"] = {
        label = "Y24 Black",
        weight = 10000,
        stack = false,
        consume = 0,
        client = {
            export = "yseries.UsePhoneItem",
            remove = function()
                TriggerEvent("yseries:phone-item-removed")
            end,
            add = function() TriggerEvent("yseries:phone-item-added") end
        }
    },
    ["y24_silver"] = {
        label = "Y24 Silver",
        weight = 1000,
        stack = false,
        consume = 0,
        client = {
            export = "yseries.UsePhoneItem",
            remove = function()
                TriggerEvent("yseries:phone-item-removed")
            end,
            add = function() TriggerEvent("yseries:phone-item-added") end
        }
    },
    ["y24_violet"] = {
        label = "Y24 Violet",
        weight = 1000,
        stack = false,
        consume = 0,
        client = {
            export = "yseries.UsePhoneItem",
            remove = function()
                TriggerEvent("yseries:phone-item-removed")
            end,
            add = function() TriggerEvent("yseries:phone-item-added") end
        }
    },
    ["y24_yellow"] = {
        label = "Y24 Yellow",
        weight = 10000,
        stack = false,
        consume = 0,
        client = {
            export = "yseries.UsePhoneItem",
            remove = function()
                TriggerEvent("yseries:phone-item-removed")
            end,
            add = function() TriggerEvent("yseries:phone-item-added") end
        }
    },
    ["yfold_black"] = {
        label = "YFold Black",
        weight = 1000,
        stack = false,
        consume = 0,
        client = {
            export = "yseries.UsePhoneItem",
            remove = function()
                TriggerEvent("yseries:phone-item-removed")
            end,
            add = function() TriggerEvent("yseries:phone-item-added") end
        }
    },
    ["yphone_fold_black"] = {
        label = "YPhone Fold Black",
        weight = 1000,
        stack = false,
        consume = 0,
        client = {
            export = "yseries.UsePhoneItem",
            remove = function()
                TriggerEvent("yseries:phone-item-removed")
            end,
            add = function() TriggerEvent("yseries:phone-item-added") end
        }
    },

    ['scissors'] = {label = 'Kéo hái nho', weight = 2000, stack = true, close = true},

    ['scissors_dirty'] = {
        label = 'Kéo bẩn',
        weight = 2000,
        stack = true,
        close = true
    },

    ['dirty_wine_bottle'] = {
        label = 'Chai rượu bẩn',
        weight = 2000,
        stack = true,
        close = true
    },

    ['empty_wine_bottle'] = {
        label = 'Chai rượu rỗng',
        weight = 1000,
        stack = true,
        close = true
    },

    ['red_wine_grapes'] = {
        label = 'Nho đỏ',
        weight = 1000,
        stack = true,
        close = true
    },

    ['red_wine_prepared'] = {
        label = 'Nho đỏ đã sơ chế',
        weight = 1000,
        stack = true,
        close = true
    },

    ['red_wine_juice'] = {
        label = 'Nước ép nho đỏ',
        weight = 1000,
        stack = true,
        close = true
    },

    ['red_wine_bottle'] = {
        label = 'Chai rượu vang đỏ',
        weight = 1000,
        stack = true,
        close = true
    },

    ['red_wine_glass'] = {
        label = 'Ly rượu vang đỏ',
        weight = 1000,
        stack = true,
        close = true
    },

    ['white_wine_grapes'] = {
        label = 'Nho trắng',
        weight = 1000,
        stack = true,
        close = true
    },

    ['white_wine_prepared'] = {
        label = 'Nho trắng đã sơ chế',
        weight = 1000,
        stack = true,
        close = true
    },

    ['white_wine_juice'] = {
        label = 'Nước ép nho trắng',
        weight = 1000,
        stack = true,
        close = true
    },

    ['white_wine_bottle'] = {
        label = 'Chai rượu vang trắng',
        weight = 1000,
        stack = true,
        close = true
    },

    ['white_wine_glass'] = {
        label = 'Ly rượu vang trắng',
        weight = 1000,
        stack = true,
        close = true
    },

    ['rose_wine_grapes'] = {
        label = 'Nho hồng',
        weight = 1000,
        stack = true,
        close = true
    },

    ['rose_wine_prepared'] = {
        label = 'Nho hồng đã sơ chế',
        weight = 1000,
        stack = true,
        close = true
    },

    ['rose_wine_juice'] = {
        label = 'Nước ép nho hồng',
        weight = 1000,
        stack = true,
        close = true
    },

    ['rose_wine_bottle'] = {
        label = 'Chai rượu vang hồng',
        weight = 1000,
        stack = true,
        close = true
    },

    ['rose_wine_glass'] = {
        label = 'Ly rượu vang hồng',
        weight = 1000,
        stack = true,
        close = true
    },

    ['wine_label'] = {
        label = 'Nhãn chai rượu',
        weight = 1000,
        stack = true,
        close = true
    },

    ['empty_wine_bottle_labeled'] = {
        label = 'Chai rượu rỗng đã dán nhãn',
        weight = 1000,
        stack = true,
        close = true
    },

    ['wine_glass'] = {
        label = 'Ly rượu vang',
        weight = 1000,
        stack = true,
        close = true
    },
    ["cuoc_dao_da"] = {
        label = 'Cuốc đào đá',
        weight = 1000,
        stack = false,
        close = true,
        durability = 100
    },
    ["da_bi_an"] = {
        label = 'Đá bí ẩn',
        weight = 1000,
        stack = true,
        close = true
    },

    ['breathalyzer'] = {
        label = 'Máy thổi nồng độ cồn',
        weight = 500,
        stack = true,
    },

    ['acid'] = {
		label = 'Kẹo Thần tiên',
		weight = 1000,
		stack = true,
		close = true,
		description = 'Lên nóc nhà',
	},

    ['methadone'] = {
		label = 'Thuốc cai nghiện',
		weight = 1000,
		stack = true,
		close = true,
		description = 'thuốc chữa nghiện',
	},


    ["hom_trung_thu"] = {
        label = 'Hòm Trung Thu',
        weight = 100,
        stack = true,
        close = true,
        description = "Hòm trung thu Mở ra nhiều phần quà hấp dẫn"
    },

    ["hom_trung_thu_ig"] = {
        label = 'Hòm Trung Thu (IG)',
        weight = 100,
        stack = true,
        close = true,
        description = "Hòm Trung Thu (IG) Mở ra nhiều phần quà hấp dẫn"
    },

    ["the_outfit"] = {
        label = 'Thẻ Trang Phục',
        weight = 100,
        stack = true,
    },

    ["the_skin"] = {
        label = 'Thẻ Skin',
        weight = 50,
        stack = true,
    },

    ["the_trung_thu"] = {
        label = 'Thẻ Trung Thu',
        weight = 10,
        stack = true,
    },

    ["banh_trung_thu"] = {
        label = 'Bánh Trung Thu',
        weight = 100,
        stack = true,
    },

    ['torture'] = {
        label = 'Ghế Tra Tấn',
        weight = 1000,
        stack = true
    }
}
