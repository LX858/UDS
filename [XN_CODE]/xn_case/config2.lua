Config = Config or {}

-- =====================================================
-- TỶ LỆ RARITY CHO CASE OPENING - PITY SYSTEM
-- =====================================================
-- HỆ THỐNG ĐẢM BẢO (PITY):
-- - 5 lần quay  = Chắc chắn 1 Rare
-- - 15 lần quay = Chắc chắn 1 Epic
-- - 30 lần quay = Chắc chắn 1 Legendary
-- - 60 lần quay = Chắc chắn 1 Mythic
-- =====================================================

-- Tỷ lệ cơ bản (Base rates) - Tổng = 100%
Config.RarityRates = {
    Common = 56.4,    -- 56.6% - Thường gặp (tăng để bù)
    Uncommon = 30,    -- 30% - Không thường
    Rare = 10,        -- 20% - Hiếm (1/5 = 20%)
    Epic = 3,         -- 3% - Cực hiếm
    Legendary = 0.4,  -- 0.4% - Huyền thoại (cực kỳ hiếm)
    Mythic = 0.2        -- 0.2% - Thần thoại
}
-- Tổng = 100% chính xác

-- Số lần quay RANDOM trước khi ĐẢM BẢO nhận được rarity (PITY SYSTEM)
-- Mỗi player sẽ có ngưỡng pity khác nhau trong khoảng [min, max]
Config.PitySystem = {
    Rare = {min = 10, max = 20},           -- Random 4-6 lần → Force Rare
    Epic = {min = 50, max = 60},         -- Random 12-18 lần → Force Epic
    Legendary = {min = 100, max = 120},    -- Random 25-35 lần → Force Legendary
    Mythic = {min = 50, max = 70}        -- Random 50-70 lần → Force Mythic
}

-- Bật/tắt Pity System
Config.EnablePitySystem = true

Config.Itemsell = {
    [1] = {
        name = "boombox",
        label = "Máy phát nhạc",
        price = 499,
        type = "item"
    },

    -- [2] = {
    --     name = "icon_vip",
    --     label = "Thẻ thời gian VIP",
    --     price = 499,
    --     type = "item"
    -- },

    [2] = {
        name = "manhkimloai",
        label = "Mảnh Kim Loại",
        price = 199,
        type = "item"
    },

    [3] = {
        name = "vdm_ngaunhien",
        label = "Vé đổi mẫu ngẫu nhiên",
        price = 299,
        type = "item"
    },

    [4] = {
        name = "vdm_tuychon",
        label = "Vé đổi mẫu tùy chọn",
        price = 999,
        type = "item"
    },

    [5] = {
        name = "thedoithongtin",
        label = "Thẻ đổi Tên",
        price = 299,
        type = "item"
    },

    [6] = {
        name = "vebanxevip",
        label = "Vé bán xe VIP",
        price = 499,
        type = "item"
    },

    [7] = {
        name = "hom_trung_thu",
        label = "Hòm Trung Thu",
        price = 10,
        type = "item"
    },
}

Config.EnableDebug = false
Config.CooldownTime = 5000 -- Thời gian chờ giữa các lần mở túi (ms)
-- Các loại túi có thể cấu hình
Config.BagTypes = {
    ['goi_pet1'] = {
        label = 'Gói Best Friend',
        description = 'Có cơ hội nhận được thú cưng Poodle và Golden Retriever',
        image = "t1",
        animation_duration = 5000, 
        amount = 22,
        type = 'coin',
        items = {
           {
                item = 'pet_a_c_retriever_2',
                label = 'Pet Golden Retriever',
                rarity = 'Legendary',
                min_amount = 1,
                max_amount = 1,
                chance = 0.0,
                PitySystem = {min = 120, max = 180},
                pity_group = 'legendary_pets'
            },
           {
                item = 'pet_a_c_poodle_2',
                label = 'Pet Poodle',
                rarity = 'Legendary',
                min_amount = 1,
                max_amount = 1,
                chance = 0.0,
                PitySystem = {min = 120, max = 180},
                pity_group = 'legendary_pets'
            },
            {
                item = 'rose',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'controller',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'hat',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'hat2',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'teddybear',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'glasses',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'glasses2',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'coolglasses',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar2',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar3',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar4',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar5',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar6',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar7',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'bluebandana',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'blackbandana',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn2',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn3',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn4',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn5',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn6',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn7',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn8',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn9',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat2',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat3',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat4',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat5',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat6',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat7',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat8',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat9',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat10',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'beewings',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'batmanvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'redvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'elytecollar',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'blackvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'bowtie',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'daisyvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'petchef',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'daisycrown',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'petdeer',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'petchain',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'partyglasses',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'beetail',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'beadnecklace',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'pinksweater',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'xmasvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'brownshoes',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'fairyvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'k9vest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            
            {
                item = 'cloth_tshirt',
                label = 'Áo thun ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = { },
                        ['Uncommon'] = {},
                        ['Rare'] = {},
                        ['Epic'] = {},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = { },
                        ['Uncommon'] = {},
                        ['Rare'] = {},
                        ['Epic'] = {},
                        ['Legendary'] = {}
                    }
                },
            },
            {
                item = 'cloth_torso',
                label = 'Áo khoác ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = {549, 550, 551, 552, 553, 554, 555, 556, 562,
                 565, 566, 567, 569, 571, 573, 574, 575, 576, 580, 583, 586, 591, 595,
                 601, 603, 604, 605, 608, 611, 614, 615, 620, 621, 622, 626, 627, 628,
                 630, 632, 634, 635, 637, 638, 639, 640, 642, 646, 647, 649, 650, 653,
                 655, 657, 667, 673, 674, 676, 681, 682, 684, 693, 695, 696, 700, 703,
                 706, 707, 708, 709, 711, 712, 714, 715, 716, 719, 721, 722, 723, 727,
                 729, 732, 734, 735, 738, 739, 742, 747, 748, 749, 750, 751, 752, 753,
                 754, 755, 756, 757, 758, 759, 760, 763, 764, 765, 766, 767, 768, 769,
                 770, 771, 773, 775, 776, 777, 778, 780, 781, 782, 784, 785, 787, 788,
                 791, 792, 793, 795, 796, 797, 798, 799, 800, 801, 802, 804, 806, 807,
                 808, 809, 810, 812, 813, 814, 815, 817, 818, 819, 821, 822, 823, 824,
                 825, 827, 828, 829, 830, 831, 832, 833, 834, 835, 836, 838, 839, 840,
                 843, 845, 846, 848, 852, 853, 855, 856, 857, 859, 861, 862, 863, 864,
                 865, 868, 869, 873, 874, 875, 882, 907, 910, 915, 916, 917, 918, 920,
                 921, 923, 926, 928, 929, 933, 934, 935, 936, 939, 940, 943, 944, 946,
                
                 1034, 1035, 1036, 1037, 1038, 1040, 1041, 1042, 1043, 1045, 1046, 1049,
                 1050, 1051, 1052, 1054, 1055, 1056, 1057, 1059, 1060, 1061, 1062, 1063,
                1065, 1068, 1069, 1070, 1071, 1072, 1073, 1087, 1089, 1102, 1115, 1116, 
                1127, 1128, 1129, 1132, 1134, 1137, 1138, 1151,},
                        ['Uncommon'] = {559, 560, 561, 563, 568, 570, 572, 588, 589, 592, 599, 600, 602, 610, 612, 
                613, 625, 629, 631, 633, 658, 659, 666, 668, 670, 671, 672, 675,
                677, 688, 689, 690, 691, 692, 725, 736, 737, 741, 762, 805, 811, 816, 945,
            
                1044, 1047, 1053, 1067, 1081, 1082, 1084, 1088, 1091, 1092, 1094, 1098, 1109, 1110,
                1111, 1113, 1120, 1122, 1123, 1124, 1126, 1135,},
                        ['Rare'] = {557, 558, 564, 577, 587, 590, 594, 598, 606, 607, 609, 618, 623, 641, 644, 
                654, 656, 662, 663, 664, 665, 669, 678, 679, 680, 683, 685, 687,
                699, 701, 702, 704, 705, 720, 724, 730, 731, 745, 746, 761, 789, 790, 794, 
                803, 820, 841, 842, 844, 851, 858, 860, 867, 870, 871, 872, 876,
                877, 878, 879, 891, 909, 922,
            
                1039, 1048, 1058, 1074, 1076, 1077, 1080, 1083, 1085, 1090, 1093, 1095, 1096,
                1101, 1103, 1104, 1105, 1106, 1107, 1108, 1112, 1114, 1117, 1118, 1119, 1125, 
                1130, 1131, 1136, 1142, 1143, 1145, 1147, 1148, 1149, 1150, 1156, 1157, 1159, 
                1160, 1161,},
                        ['Epic'] = {579, 582, 593, 616, 617, 619, 624, 636, 643, 645, 648, 651, 652, 661, 694, 
                697, 698, 710, 713, 718, 726, 733, 740, 774, 779, 783, 786, 854,
                866, 883, 884, 892, 906, 919, 925, 927, 932, 937, 938, 941, 942, 18, 51, 52,
                116, 194, 195, 497, 985, 986, 987, 988, 989,
            
                1064, 1075, 1078, 1079, 1097, 1100, 1133, 1141, 1144, 1146, 1153, 1154, 1155, 
                1162, 1163,},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = {593, 595, 596, 597, 598, 599, 600, 605, 606, 607, 608, 
                609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619, 620, 621, 622, 623, 624, 625, 
                626, 627, 628, 629, 632, 634, 636, 637, 638, 639, 644, 646, 648, 650, 652, 653, 656, 
                657, 660, 661, 665, 666, 668, 669, 670, 671, 672, 674, 676, 678, 679, 681, 682, 684, 
                686, 687, 688, 691, 693, 696, 697, 698, 704, 707, 710, 712, 715, 716, 719, 723, 725, 
                726, 732, 733, 735, 738, 739, 744, 747, 748, 749, 756, 758, 760, 762, 763, 765, 766, 
                768, 769, 772, 773, 777, 778, 780, 781, 783, 786, 787, 788, 790, 792, 793, 798, 809, 
                812, 814, 815, 817, 818, 819, 820, 821, 822, 823, 824, 825, 826, 827, 828, 830, 832, 
                833, 839, 840, 842, 847, 848, 849, 850, 851, 852, 853, 854, 855, 856, 858, 859, 860, 
                862, 863, 866, 867, 868, 869, 870, 874, 875, 877, 878, 881, 884, 885, 886, 888, 889, 
                891, 895, 905, 907, 908, 909, 911, 912, 913, 914, 915, 918, 919, 922, 923, 924, 925, 
                926, 928, 929, 931, 935, 936, 937, 938, 939, 942, 943, 944, 945, 946, 950, 951, 952, 
                954, 957, 958, 961, 962, 966, 968, 969, 970, 972, 974, 975, 977, 978, 979, 983, 984, 
                985, 986, 996, 997, 999, 1010, 1011, 1014, 1015, 1019, 1020, 1021, 1022, 1023, 1024, 
                1026, 1028, 1029, 1030, 1032, 1037, 1039, 1041, 1042, 1043, 1044, 1045, 1046, 1048, 
                1049, 1050, 1051, 1052, 1054, 1055, 1056, 1057, 1058, 1059, 1062, 1065, 1066, 1067, 
                1068, 1069, 1070, 1072, 1079, 1090, 1092, 1093, 1095, 1099, 1100, 1101, 1102, 1103, 
                1104, 1107, 1109, 1110, 1111, 1112, 1113, 1114, 1117, 1119, 1121, 1122, 1124, 1126, 
                1127, 1129, 1130, 1131, 1133, 1134, 1136, 1137, 1141, 1142, 1143, 1144, 1145, 1146, 
                1147, 1148, 1149, 1154, 1155, 1156, 1157, 1158, 1159, 1160, 1161, 1162, 1163, 1164, 
                1166, 1167, 1168, 1169, 1173, 1175, 1177, 1181, 1183, 1184, 1186, 1187, 1190, 1191, 
                1192, 1196, 1198, 1199, 1204, 1205, 1206, 1208, 1211, 1212, 1213, 1215, 1216, 1218, 
                1220, 1221, 1224, 1225, 1226, 1228, 1229, 1230, 1231, 1232, 1233, 1235, 1238, 1239, 
                1241, 1242, 1243, 1244, 1245, 1246, 1247, 1252, 1256, 1259, 1260, 1266, 1267, 1268, 
                1269, 1270, 1276, 1277, 1280, 1286, 1287, 1288, 1290,
                1299, 1305, 1306, 1307, 1308, 1310, 1319, 1320, 1321, 1322, 1323, 1325, 
                1327, 1328, 1329, 1333, 1334, 1336, 1337, 1338, 1339, 1340, 1341, 1344, 1346, 1347, 
                1355, 1356, 1358, 1359, 1360, 1361, 1362,
            
                1444, 1457, 1460, 1464, 1468, 1473, 1481, 1482, 1485, 1486, 1487, 1489, 1490, 1491, 1492,
                1495, 1497, 1498, 1499, 1503, 1504, 1506, 1509, 1511, 1521, 1549, 1552, 1554, 1558,},
                        ['Uncommon'] = {708, 741, 750, 751, 752, 782, 791, 795, 796, 799, 800, 804, 808, 880, 883, 893, 897, 903, 
                904, 906, 959, 976, 1009, 1013, 1027, 1033, 1178, 1209, 1254, 1265, 1278, 1304, 1331, 601, 
                631, 633, 643, 647, 655, 663, 664, 667, 675, 695, 699, 711, 714, 717, 731, 742, 743, 745, 
                753, 779, 784, 785, 789, 801, 802, 803, 805, 806, 807, 810, 811, 813, 835, 836, 837, 838, 
                841, 887, 890, 892, 896, 898, 899, 900, 901, 902, 940, 941, 948, 953, 955, 956, 960, 963, 
                964, 988, 991, 993, 1002, 1003, 1004, 1005, 1060, 1061, 1086, 1087, 1088, 1089, 1091, 1094, 
                1096, 1097, 1105, 1106, 1108, 1115, 1116, 1118, 1120, 1176, 1179, 1180, 1182, 1185, 1188, 
                1200, 1201, 1271, 1272, 1273, 1274, 1275, 1289, 1363, 1364, 1365,
            
                1454, 1470, 1471, 1480, 1483, 1484, 1488, 1501, 1502, 1505, 1510, 1512, 1516, 1519, 1520, 1522,
                1524, 1525, 1526, 1529, 1539, 1540, 1541, 1550,},
                        ['Rare'] = {1076, 1253, 1264, 1303, 604, 630, 635, 642, 
                645, 658, 659, 662, 673, 677, 680, 683, 685, 702, 713, 718, 728, 729, 730, 734, 740, 767, 771, 
                775, 776, 797, 829, 831, 834, 843, 844, 857, 864, 872, 873, 876, 879, 880, 882, 932, 934, 947, 
                965, 967, 971, 980, 981, 982, 987, 989, 990, 994, 995, 998, 1000, 1001, 1007, 1008, 1016, 1017, 
                1018, 1040, 1047, 1073, 1074, 1075, 1077, 1081, 1082, 1083, 1098, 1123, 1125, 1128, 1132, 1135, 
                1150, 1151, 1152, 1165, 1170, 1171, 1172, 1174, 1219, 1222, 1223, 1227, 1237, 1240, 1296, 1300, 
                1301, 1309, 1311, 1342, 1345,
            
                1445, 1448, 1453, 1455, 1456, 1459, 1461, 1465, 1466, 1469, 1472, 1474, 1477, 1478, 1479, 1496, 
                1500, 1507, 1508, 1515, 1517, 1527, 1528, 1530, 1531, 1536, 1538, 1544, 1545, 1546, 1547, 1548,
                1553, 1555, 1559,},
                        ['Epic'] = {750, 751, 1027, 
                1257, 1350, 
                1427, 1428, 1444, 1445, 1446, 1447, 1448, 1449, 1450, 1451, 1452, 1453, 1454, 1455, 1456, 1457, 
                1458, 602, 603, 640, 649, 651, 689, 690, 692, 694, 701, 705, 706, 720, 721, 722, 724, 727, 736, 
                737, 746, 754, 755, 757, 759, 761, 764, 770, 774, 794, 816, 845, 846, 861, 865, 871, 910, 916, 
                917, 920, 921, 992, 1006, 1012, 1025, 1031, 1034, 1035, 1036, 1038, 1053, 1063, 1064, 1071, 1078, 
                1080, 1084, 1085, 1138, 1139, 1140, 1153, 1203, 1210, 1214, 1217, 1234, 1236, 1248, 1279, 1312, 
                1315, 1316, 1317, 1318, 1324, 1326, 1330, 1332, 1335, 1348, 1349, 1352, 1353, 1354, 1357, 44, 45,
                19, 1291, 1293, 1297, 1298, 536, 452, 196, 197, 108, 933,
            
                1458, 1462, 1467, 1475, 1476, 1493, 1494, 1513, 1518, 1523, 1534, 1535, 1537, 1556, 1557,},
                        ['Legendary'] = {}
                    }
                },
                min_amount = 1,
                max_amount = 1,
                chance = 90.0,
            },
            {
                item = 'cloth_pants',
                label = 'Quần ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = {202, 203, 204, 207, 208, 209, 211, 212, 213, 223, 225, 226, 227, 233,
                234, 235, 238, 244, 245, 246, 247, 248, 250, 252, 253, 254, 255, 256, 257,
                258, 259, 262, 263, 264, 265, 266, 267, 268,
            
                305, 306, 307, 326, 329, 330, 331, 332, 333, 334, 342, 344, },
                        ['Uncommon'] = {205, 206, 214, 215, 224, 228, 229, 230, 240, 241, 242, 243, 274, 275,
            
                308, 312, 313, 315, 316, 317, 318, 319, 320, 321, 322, 323, 324, 325, 335, 336, 340, 341, 343, 
                349,},
                        ['Rare'] = {210, 217, 222, 231, 236, 269, 271, 272, 57,
            
                309, 310, 311, 327, 328, 337, 338, 339, 345, 346, 347, 348, },
                        ['Epic'] = {216, 218, 219, 220, 221, 237, 239, 251, 260, 261, 270, 273, 293, 294, 295,
            
                216, 218, 219, 220, 221, 237, 239, 251, 260, 261, 270, 273, 293, 294, 295},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = {216, 217, 219, 220, 222, 223, 224, 226, 227, 228, 229, 231, 233, 234, 235, 237, 239, 241, 242, 243, 246, 248, 249, 250, 251, 253, 254,
                256, 258, 259, 260, 264, 265, 267, 268, 269, 271, 272},
                        ['Uncommon'] = {218, 221, 232, 236, 238, 244, 252, 270},
                        ['Rare'] = {225, 240, 247, 257, 266225, 240, 247, 257, 266},
                        ['Epic'] = {261, 262, 287, 288, 293, 294, 59, 60, 119,
                285, 286, 287, 288},
                        ['Legendary'] = {}
                    }
                },
                min_amount = 1,
                max_amount = 1,
                chance = 90.0,
            },
            {
                item = 'cloth_shoes',
                label = 'Giày ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = {145, 148, 149, 150, 154, 167, 168, 169, 180, 181, 183, 186, 188, 192, 195, 196, 199, 204, 205, 208, 209,
            
                222, 223, 226, 229, 230, 239, 240, 241, 242, 243, 244, 245, 249, 250, 253, 255, 256, 262, 265, 266, 267, 268,
                274, 275, 276, 277, 278, 279, 283, 284, 285, 286, 288, 293, 294, 295, 296, 297, 298, 299, 300, 302, 303, 305, 
                307, 308, 309, 310, 311, 312, 313, 321, 322, 323, 324, 325, 326, 327, 328, 329, 330, 331, 332, 333, 334, 335,},
                        ['Uncommon'] = {146, 147, 160, 164, 165, 172, 184, 185, 189, 190, 191, 193, 194, 202, 203, 206, 207, 216,
            
                231, 234, 235, 238, 246, 254, 257, 259, 260, 261, 263, 264, 271, 272, 273, 280, 287, 289, 290, 291, 292, 301, 
                314, 315, 316, 318, 319, 320,},
                        ['Rare'] = {151, 152, 153, 155, 156, 157, 158, 159, 161, 162, 166, 170, 171, 178, 179, 182, 200, 201, 210, 211, 212, 213, 214, 215, 218,
                219, 220, 221,
            
                224, 236, 237, 247, 248, 251, 252, 269, 304,},
                        ['Epic'] = {173, 174, 175, 176, 177, 187, 198, 217,
            
                232, 270, 281, 306,},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = {130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155,
                156, 157, 158, 159, 162, 163, 167, 168, 169, 171, 178, 180, 185,
                188, 190, 192, 194, 195, 198, 201, 202, 203, 204, 205, 211, 213, 215,
                217, 218, 222, 223, 224, 232, 235, 240, 243, 248, 
                255, 256, 257, 268, 273, 275, 277, 281, 290, 292,
                293, 294, 297,
            
                327, 331, 334, 338, 340, 343, 345, 348, 350, 351, 353, 357, 359, 360, 364, 366, 368, 372, 376, 377,},
                        ['Uncommon'] = {165, 172, 176, 206, 208, 214, 227, 226, 236, 238, 239, 242, 241, 250, 251, 265, 264, 271, 272, 276, 301, 299, 296, 160, 164, 170, 
                173, 174, 175, 177, 179, 225, 229, 230, 231, 233, 234, 244, 246, 247, 249, 252, 253, 254, 259, 260, 288, 289, 291, 297,
            
                317, 322, 323, 324, 325, 328, 330, 332, 339, 341, 349, 352, 356, 358, 363, 365, 367, 370, 373, 374, 381,},
                        ['Rare'] = {161, 216, 237, 262, 266, 267, 274, 295, 298, 300, 302, 181, 186, 187, 189, 191, 193, 196, 197, 199, 200, 209, 210, 212, 218, 219, 
                220, 221, 261, 263, 269, 280, 282, 283,
            
                318, 319, 320, 321, 329, 337, 342, 344, 347, 355, 361, 371, 380,},
                        ['Epic'] = {182, 183, 184, 207, 284, 285, 286, 245,
            
                326, 333, 335, 336, 346, 369, 375, 382,},
                        ['Legendary'] = {}
                    }
                },
                min_amount = 1,
                max_amount = 1,
                chance = 90.0,
            },
           
        }
    },

    ['goi_pet2'] = {
        label = 'Gói Hoàng Thượng',
        description = 'Có cơ hội nhận được thú cưng Mồn Lèo và Sphynx',
        image = "t2",
        animation_duration = 5000, 
        amount = 22,
        type = 'coin',
        items = {
           {
                item = 'pet_a_c_cat_01',
                label = 'Pet Cat',
                rarity = 'Legendary',
                min_amount = 1,
                max_amount = 1,
                chance = 0.0,
                PitySystem = {min = 120, max = 180},
                pity_group = 'legendary_pets'
            },
           {
                item = 'pet_dusa_sphynx',
                label = 'Pet Sphynx',
                rarity = 'Legendary',
                min_amount = 1,
                max_amount = 1,
                chance = 0.0,
                PitySystem = {min = 120, max = 180},
                pity_group = 'legendary_pets'
            },
            {
                item = 'rose',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'controller',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'hat',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'hat2',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'teddybear',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'glasses',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'glasses2',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'coolglasses',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar2',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar3',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar4',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar5',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar6',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar7',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'bluebandana',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'blackbandana',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn2',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn3',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn4',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn5',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn6',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn7',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn8',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn9',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat2',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat3',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat4',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat5',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat6',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat7',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat8',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat9',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat10',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'beewings',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'batmanvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'redvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'elytecollar',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'blackvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'bowtie',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'daisyvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'petchef',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'daisycrown',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'petdeer',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'petchain',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'partyglasses',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'beetail',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'beadnecklace',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'pinksweater',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'xmasvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'brownshoes',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'fairyvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'k9vest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
           
            {
                item = 'cloth_tshirt',
                label = 'Áo thun ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = {211, 212, 215, 216, 217, 218, 219, 220, 221, 223, 226, 228, 230, 
                234, 235, 237, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 
                250, 251, 259, 264,
            
                303, 304, 305, 310, 311, 312, 317, 318, 319, 320, 321, 324, 325, 329, 334, 335, 336, 337, 338, 
                340, 341, 344, 345, 346, 347, 348, 350, 352, 353, 354, 355, 356, 358, 359, 363,},
                        ['Uncommon'] = {225, 227, 229, 231, 232, 236, 252, 260, 263,
            
                314, 327, 328, 330, 342, 349, 361, 362,},
                        ['Rare'] = {224, 238, 257, 258, 261,
            
                306, 307, 308, 315, 326, 331, 332, 333, 343, 357, 360,},
                        ['Epic'] = {233, 253, 255, 256, 262, 222,
            
                302, 309, 316, 323, 351,},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = {262, 263, 264, 265, 267, 268, 269, 281, 283, 284, 291, 292, 293, 294, 296, 299, 
                302, 304, 305, 308, 310, 313, 314, 319, 320, 321, 326, 327, 328, 330, 331, 333, 334, 335, 337, 
                338, 339, 340, 344, 346, 349, 350, 351, 352, 353, 356, 358, 359, 360, 361, 363, 365, 366, 368, 
                369, 370, 374, 376, 377, 379, 380, 387, 388, 390, 391, 392, 393, 397, 399, 401, 402, 404, 405, 
                406, 407, 409, 410, 411, 416, 417, 418, 420, 421, 422, 423, 424, 426, 427, 428, 430, 434, 436, 
                437, 438, 439, 441, 442, 443, 445, 449, 450, 451, 452, 453, 454, 456, 457, 458, 459, 460, 461, 
                462, 463, 464, 465, 466, 468, 470, 471, 472, 473, 474, 479, 480, 484, 485, 486, 487, 488, 489, 
                490, 491, 492, 493, 495, 498, 502, 503, 504, 505, 506, 507, 510, 512, 513, 515, 516, 517, 518, 
                519, 520, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 533, 535, 538, 539, 540, 541, 542, 
                543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 555, 556, 557, 558, 559, 561, 562, 563, 
                565, 566, 567, 568, 569, 570, 572, 574, 575, 576, 577, 578, 579, 580, 581, 582, 583, 584, 
                585, 586, 587, 588, 589, 590, 591, 592, 593, 594, 595, 596, 597, 598, 599, 600, 601, 602, 604, 
                605, 606, 607, 608, 609, 610, 611, 612, 613, 617, 619, 620,
            
                663, 664, 665, 681, 682, 694, 698, 700, 702, 705, 706, 708, 729, 753, 757, 758,},
                        ['Uncommon'] = {266, 270, 271, 273, 275, 276, 277, 282, 285, 289, 295, 311, 312, 316, 317, 318, 342, 343, 347, 
                362, 378, 381, 396, 425, 429, 431, 432, 447, 469, 477, 478, 499, 500, 501, 532, 534, 615, 616, 
                618, 621,
            
                668, 669, 671, 672, 673, 674, 676, 678, 683, 688, 690, 692, 693, 695, 704, 707, 709, 724, 731,
                732, 735, 737, 738, 741, 742, 743, 752, 754, 756, 762,},
                        ['Rare'] = {272, 274, 278, 279, 280, 286, 287, 290, 297, 298, 300, 301, 315, 322, 324, 325, 329, 348, 357, 
                364, 367, 382, 383, 394, 395, 403, 419, 433, 435, 446, 475, 476, 483, 508, 509, 511, 531, 564, 
                571, 622, 655, 656,
            
                662, 666, 667, 677, 680, 684, 685, 686, 687, 689, 691, 696, 697, 699, 710, 711, 714, 719, 720,
                721, 723, 725, 730, 733, 736, 739, 745, 746, 747, 748, 750, 755, 759, 761, 763,},
                        ['Epic'] = {288, 303, 306, 307, 323, 332, 336, 354, 355, 371, 373, 375, 384, 385, 389, 398, 400, 412, 415, 
                440, 444, 448, 455, 467, 481, 482, 494, 536, 537, 554, 560, 603, 614, 654,
            
                670, 675, 678, 701, 703, 713, 715, 716, 717, 718, 722, 728, 734, 740, 744, 749, 751, 760,},
                        ['Legendary'] = {}
                    }
                },
                min_amount = 1,
                max_amount = 1,
                chance = 90.0,
            },
            {
                item = 'cloth_torso',
                label = 'Áo khoác ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = {549, 550, 551, 552, 553, 554, 555, 556, 562,
                 565, 566, 567, 569, 571, 573, 574, 575, 576, 580, 583, 586, 591, 595,
                 601, 603, 604, 605, 608, 611, 614, 615, 620, 621, 622, 626, 627, 628,
                 630, 632, 634, 635, 637, 638, 639, 640, 642, 646, 647, 649, 650, 653,
                 655, 657, 667, 673, 674, 676, 681, 682, 684, 693, 695, 696, 700, 703,
                 706, 707, 708, 709, 711, 712, 714, 715, 716, 719, 721, 722, 723, 727,
                 729, 732, 734, 735, 738, 739, 742, 747, 748, 749, 750, 751, 752, 753,
                 754, 755, 756, 757, 758, 759, 760, 763, 764, 765, 766, 767, 768, 769,
                 770, 771, 773, 775, 776, 777, 778, 780, 781, 782, 784, 785, 787, 788,
                 791, 792, 793, 795, 796, 797, 798, 799, 800, 801, 802, 804, 806, 807,
                 808, 809, 810, 812, 813, 814, 815, 817, 818, 819, 821, 822, 823, 824,
                 825, 827, 828, 829, 830, 831, 832, 833, 834, 835, 836, 838, 839, 840,
                 843, 845, 846, 848, 852, 853, 855, 856, 857, 859, 861, 862, 863, 864,
                 865, 868, 869, 873, 874, 875, 882, 907, 910, 915, 916, 917, 918, 920,
                 921, 923, 926, 928, 929, 933, 934, 935, 936, 939, 940, 943, 944, 946,
                
                 1034, 1035, 1036, 1037, 1038, 1040, 1041, 1042, 1043, 1045, 1046, 1049,
                 1050, 1051, 1052, 1054, 1055, 1056, 1057, 1059, 1060, 1061, 1062, 1063,
                1065, 1068, 1069, 1070, 1071, 1072, 1073, 1087, 1089, 1102, 1115, 1116, 
                1127, 1128, 1129, 1132, 1134, 1137, 1138, 1151,},
                        ['Uncommon'] = {559, 560, 561, 563, 568, 570, 572, 588, 589, 592, 599, 600, 602, 610, 612, 
                613, 625, 629, 631, 633, 658, 659, 666, 668, 670, 671, 672, 675,
                677, 688, 689, 690, 691, 692, 725, 736, 737, 741, 762, 805, 811, 816, 945,
            
                1044, 1047, 1053, 1067, 1081, 1082, 1084, 1088, 1091, 1092, 1094, 1098, 1109, 1110,
                1111, 1113, 1120, 1122, 1123, 1124, 1126, 1135,},
                        ['Rare'] = {557, 558, 564, 577, 587, 590, 594, 598, 606, 607, 609, 618, 623, 641, 644, 
                654, 656, 662, 663, 664, 665, 669, 678, 679, 680, 683, 685, 687,
                699, 701, 702, 704, 705, 720, 724, 730, 731, 745, 746, 761, 789, 790, 794, 
                803, 820, 841, 842, 844, 851, 858, 860, 867, 870, 871, 872, 876,
                877, 878, 879, 891, 909, 922,
            
                1039, 1048, 1058, 1074, 1076, 1077, 1080, 1083, 1085, 1090, 1093, 1095, 1096,
                1101, 1103, 1104, 1105, 1106, 1107, 1108, 1112, 1114, 1117, 1118, 1119, 1125, 
                1130, 1131, 1136, 1142, 1143, 1145, 1147, 1148, 1149, 1150, 1156, 1157, 1159, 
                1160, 1161,},
                        ['Epic'] = {579, 582, 593, 616, 617, 619, 624, 636, 643, 645, 648, 651, 652, 661, 694, 
                697, 698, 710, 713, 718, 726, 733, 740, 774, 779, 783, 786, 854,
                866, 883, 884, 892, 906, 919, 925, 927, 932, 937, 938, 941, 942, 18, 51, 52,
                116, 194, 195, 497, 985, 986, 987, 988, 989,
            
                1064, 1075, 1078, 1079, 1097, 1100, 1133, 1141, 1144, 1146, 1153, 1154, 1155, 
                1162, 1163,},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = {593, 595, 596, 597, 598, 599, 600, 605, 606, 607, 608, 
                609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619, 620, 621, 622, 623, 624, 625, 
                626, 627, 628, 629, 632, 634, 636, 637, 638, 639, 644, 646, 648, 650, 652, 653, 656, 
                657, 660, 661, 665, 666, 668, 669, 670, 671, 672, 674, 676, 678, 679, 681, 682, 684, 
                686, 687, 688, 691, 693, 696, 697, 698, 704, 707, 710, 712, 715, 716, 719, 723, 725, 
                726, 732, 733, 735, 738, 739, 744, 747, 748, 749, 756, 758, 760, 762, 763, 765, 766, 
                768, 769, 772, 773, 777, 778, 780, 781, 783, 786, 787, 788, 790, 792, 793, 798, 809, 
                812, 814, 815, 817, 818, 819, 820, 821, 822, 823, 824, 825, 826, 827, 828, 830, 832, 
                833, 839, 840, 842, 847, 848, 849, 850, 851, 852, 853, 854, 855, 856, 858, 859, 860, 
                862, 863, 866, 867, 868, 869, 870, 874, 875, 877, 878, 881, 884, 885, 886, 888, 889, 
                891, 895, 905, 907, 908, 909, 911, 912, 913, 914, 915, 918, 919, 922, 923, 924, 925, 
                926, 928, 929, 931, 935, 936, 937, 938, 939, 942, 943, 944, 945, 946, 950, 951, 952, 
                954, 957, 958, 961, 962, 966, 968, 969, 970, 972, 974, 975, 977, 978, 979, 983, 984, 
                985, 986, 996, 997, 999, 1010, 1011, 1014, 1015, 1019, 1020, 1021, 1022, 1023, 1024, 
                1026, 1028, 1029, 1030, 1032, 1037, 1039, 1041, 1042, 1043, 1044, 1045, 1046, 1048, 
                1049, 1050, 1051, 1052, 1054, 1055, 1056, 1057, 1058, 1059, 1062, 1065, 1066, 1067, 
                1068, 1069, 1070, 1072, 1079, 1090, 1092, 1093, 1095, 1099, 1100, 1101, 1102, 1103, 
                1104, 1107, 1109, 1110, 1111, 1112, 1113, 1114, 1117, 1119, 1121, 1122, 1124, 1126, 
                1127, 1129, 1130, 1131, 1133, 1134, 1136, 1137, 1141, 1142, 1143, 1144, 1145, 1146, 
                1147, 1148, 1149, 1154, 1155, 1156, 1157, 1158, 1159, 1160, 1161, 1162, 1163, 1164, 
                1166, 1167, 1168, 1169, 1173, 1175, 1177, 1181, 1183, 1184, 1186, 1187, 1190, 1191, 
                1192, 1196, 1198, 1199, 1204, 1205, 1206, 1208, 1211, 1212, 1213, 1215, 1216, 1218, 
                1220, 1221, 1224, 1225, 1226, 1228, 1229, 1230, 1231, 1232, 1233, 1235, 1238, 1239, 
                1241, 1242, 1243, 1244, 1245, 1246, 1247, 1252, 1256, 1259, 1260, 1266, 1267, 1268, 
                1269, 1270, 1276, 1277, 1280, 1286, 1287, 1288, 1290,
                1299, 1305, 1306, 1307, 1308, 1310, 1319, 1320, 1321, 1322, 1323, 1325, 
                1327, 1328, 1329, 1333, 1334, 1336, 1337, 1338, 1339, 1340, 1341, 1344, 1346, 1347, 
                1355, 1356, 1358, 1359, 1360, 1361, 1362,
            
                1444, 1457, 1460, 1464, 1468, 1473, 1481, 1482, 1485, 1486, 1487, 1489, 1490, 1491, 1492,
                1495, 1497, 1498, 1499, 1503, 1504, 1506, 1509, 1511, 1521, 1549, 1552, 1554, 1558,},
                        ['Uncommon'] = {708, 741, 750, 751, 752, 782, 791, 795, 796, 799, 800, 804, 808, 880, 883, 893, 897, 903, 
                904, 906, 959, 976, 1009, 1013, 1027, 1033, 1178, 1209, 1254, 1265, 1278, 1304, 1331, 601, 
                631, 633, 643, 647, 655, 663, 664, 667, 675, 695, 699, 711, 714, 717, 731, 742, 743, 745, 
                753, 779, 784, 785, 789, 801, 802, 803, 805, 806, 807, 810, 811, 813, 835, 836, 837, 838, 
                841, 887, 890, 892, 896, 898, 899, 900, 901, 902, 940, 941, 948, 953, 955, 956, 960, 963, 
                964, 988, 991, 993, 1002, 1003, 1004, 1005, 1060, 1061, 1086, 1087, 1088, 1089, 1091, 1094, 
                1096, 1097, 1105, 1106, 1108, 1115, 1116, 1118, 1120, 1176, 1179, 1180, 1182, 1185, 1188, 
                1200, 1201, 1271, 1272, 1273, 1274, 1275, 1289, 1363, 1364, 1365,
            
                1454, 1470, 1471, 1480, 1483, 1484, 1488, 1501, 1502, 1505, 1510, 1512, 1516, 1519, 1520, 1522,
                1524, 1525, 1526, 1529, 1539, 1540, 1541, 1550,},
                        ['Rare'] = {1076, 1253, 1264, 1303, 604, 630, 635, 642, 
                645, 658, 659, 662, 673, 677, 680, 683, 685, 702, 713, 718, 728, 729, 730, 734, 740, 767, 771, 
                775, 776, 797, 829, 831, 834, 843, 844, 857, 864, 872, 873, 876, 879, 880, 882, 932, 934, 947, 
                965, 967, 971, 980, 981, 982, 987, 989, 990, 994, 995, 998, 1000, 1001, 1007, 1008, 1016, 1017, 
                1018, 1040, 1047, 1073, 1074, 1075, 1077, 1081, 1082, 1083, 1098, 1123, 1125, 1128, 1132, 1135, 
                1150, 1151, 1152, 1165, 1170, 1171, 1172, 1174, 1219, 1222, 1223, 1227, 1237, 1240, 1296, 1300, 
                1301, 1309, 1311, 1342, 1345,
            
                1445, 1448, 1453, 1455, 1456, 1459, 1461, 1465, 1466, 1469, 1472, 1474, 1477, 1478, 1479, 1496, 
                1500, 1507, 1508, 1515, 1517, 1527, 1528, 1530, 1531, 1536, 1538, 1544, 1545, 1546, 1547, 1548,
                1553, 1555, 1559,},
                        ['Epic'] = {750, 751, 1027, 
                1257, 1350, 
                1427, 1428, 1444, 1445, 1446, 1447, 1448, 1449, 1450, 1451, 1452, 1453, 1454, 1455, 1456, 1457, 
                1458, 602, 603, 640, 649, 651, 689, 690, 692, 694, 701, 705, 706, 720, 721, 722, 724, 727, 736, 
                737, 746, 754, 755, 757, 759, 761, 764, 770, 774, 794, 816, 845, 846, 861, 865, 871, 910, 916, 
                917, 920, 921, 992, 1006, 1012, 1025, 1031, 1034, 1035, 1036, 1038, 1053, 1063, 1064, 1071, 1078, 
                1080, 1084, 1085, 1138, 1139, 1140, 1153, 1203, 1210, 1214, 1217, 1234, 1236, 1248, 1279, 1312, 
                1315, 1316, 1317, 1318, 1324, 1326, 1330, 1332, 1335, 1348, 1349, 1352, 1353, 1354, 1357, 44, 45,
                19, 1291, 1293, 1297, 1298, 536, 452, 196, 197, 108, 933,
            
                1458, 1462, 1467, 1475, 1476, 1493, 1494, 1513, 1518, 1523, 1534, 1535, 1537, 1556, 1557,},
                        ['Legendary'] = {}
                    }
                },
                min_amount = 1,
                max_amount = 1,
                chance = 90.0,
            },
            {
                item = 'cloth_pants',
                label = 'Quần ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = {202, 203, 204, 207, 208, 209, 211, 212, 213, 223, 225, 226, 227, 233,
                234, 235, 238, 244, 245, 246, 247, 248, 250, 252, 253, 254, 255, 256, 257,
                258, 259, 262, 263, 264, 265, 266, 267, 268,
            
                305, 306, 307, 326, 329, 330, 331, 332, 333, 334, 342, 344, },
                        ['Uncommon'] = {205, 206, 214, 215, 224, 228, 229, 230, 240, 241, 242, 243, 274, 275,
            
                308, 312, 313, 315, 316, 317, 318, 319, 320, 321, 322, 323, 324, 325, 335, 336, 340, 341, 343, 
                349,},
                        ['Rare'] = {210, 217, 222, 231, 236, 269, 271, 272, 57,
            
                309, 310, 311, 327, 328, 337, 338, 339, 345, 346, 347, 348, },
                        ['Epic'] = {216, 218, 219, 220, 221, 237, 239, 251, 260, 261, 270, 273, 293, 294, 295,
            
                216, 218, 219, 220, 221, 237, 239, 251, 260, 261, 270, 273, 293, 294, 295},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = {216, 217, 219, 220, 222, 223, 224, 226, 227, 228, 229, 231, 233, 234, 235, 237, 239, 241, 242, 243, 246, 248, 249, 250, 251, 253, 254,
                256, 258, 259, 260, 264, 265, 267, 268, 269, 271, 272},
                        ['Uncommon'] = {218, 221, 232, 236, 238, 244, 252, 270},
                        ['Rare'] = {225, 240, 247, 257, 266225, 240, 247, 257, 266},
                        ['Epic'] = {261, 262, 287, 288, 293, 294, 59, 60, 119,
                285, 286, 287, 288},
                        ['Legendary'] = {}
                    }
                },
                min_amount = 1,
                max_amount = 1,
                chance = 90.0,
            },
            {
                item = 'cloth_shoes',
                label = 'Giày ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = {145, 148, 149, 150, 154, 167, 168, 169, 180, 181, 183, 186, 188, 192, 195, 196, 199, 204, 205, 208, 209,
            
                222, 223, 226, 229, 230, 239, 240, 241, 242, 243, 244, 245, 249, 250, 253, 255, 256, 262, 265, 266, 267, 268,
                274, 275, 276, 277, 278, 279, 283, 284, 285, 286, 288, 293, 294, 295, 296, 297, 298, 299, 300, 302, 303, 305, 
                307, 308, 309, 310, 311, 312, 313, 321, 322, 323, 324, 325, 326, 327, 328, 329, 330, 331, 332, 333, 334, 335,},
                        ['Uncommon'] = {146, 147, 160, 164, 165, 172, 184, 185, 189, 190, 191, 193, 194, 202, 203, 206, 207, 216,
            
                231, 234, 235, 238, 246, 254, 257, 259, 260, 261, 263, 264, 271, 272, 273, 280, 287, 289, 290, 291, 292, 301, 
                314, 315, 316, 318, 319, 320,},
                        ['Rare'] = {151, 152, 153, 155, 156, 157, 158, 159, 161, 162, 166, 170, 171, 178, 179, 182, 200, 201, 210, 211, 212, 213, 214, 215, 218,
                219, 220, 221,
            
                224, 236, 237, 247, 248, 251, 252, 269, 304,},
                        ['Epic'] = {173, 174, 175, 176, 177, 187, 198, 217,
            
                232, 270, 281, 306,},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = {130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155,
                156, 157, 158, 159, 162, 163, 167, 168, 169, 171, 178, 180, 185,
                188, 190, 192, 194, 195, 198, 201, 202, 203, 204, 205, 211, 213, 215,
                217, 218, 222, 223, 224, 232, 235, 240, 243, 248, 
                255, 256, 257, 268, 273, 275, 277, 281, 290, 292,
                293, 294, 297,
            
                327, 331, 334, 338, 340, 343, 345, 348, 350, 351, 353, 357, 359, 360, 364, 366, 368, 372, 376, 377,},
                        ['Uncommon'] = {165, 172, 176, 206, 208, 214, 227, 226, 236, 238, 239, 242, 241, 250, 251, 265, 264, 271, 272, 276, 301, 299, 296, 160, 164, 170, 
                173, 174, 175, 177, 179, 225, 229, 230, 231, 233, 234, 244, 246, 247, 249, 252, 253, 254, 259, 260, 288, 289, 291, 297,
            
                317, 322, 323, 324, 325, 328, 330, 332, 339, 341, 349, 352, 356, 358, 363, 365, 367, 370, 373, 374, 381,},
                        ['Rare'] = {161, 216, 237, 262, 266, 267, 274, 295, 298, 300, 302, 181, 186, 187, 189, 191, 193, 196, 197, 199, 200, 209, 210, 212, 218, 219, 
                220, 221, 261, 263, 269, 280, 282, 283,
            
                318, 319, 320, 321, 329, 337, 342, 344, 347, 355, 361, 371, 380,},
                        ['Epic'] = {182, 183, 184, 207, 284, 285, 286, 245,
            
                326, 333, 335, 336, 346, 369, 375, 382,},
                        ['Legendary'] = {}
                    }
                },
                min_amount = 1,
                max_amount = 1,
                chance = 90.0,
            },
           
        }
    },

    ['goi_pet3'] = {
        label = 'Gói Pet 3',
        description = 'Có cơ hội nhận được thú cưng Pug và Doberman',
        image = "t3",
        animation_duration = 5000, 
        amount = 22,
        type = 'coin',
        isNew = true,
        items = {
           {
                item = 'pet_a_c_pug',
                label = 'Pet Pug',
                rarity = 'Legendary',
                min_amount = 1,
                max_amount = 1,
                chance = 0.0,
                PitySystem = {min = 120, max = 180},
                pity_group = 'legendary_pets'
            },
           {
                item = 'pet_dusa_doberman',
                label = 'Pet Doberman',
                rarity = 'Legendary',
                min_amount = 1,
                max_amount = 1,
                chance = 0.0,
                PitySystem = {min = 120, max = 180},
                pity_group = 'legendary_pets'
            },
            {
                item = 'rose',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'controller',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'hat',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'hat2',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'teddybear',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'glasses',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'glasses2',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'coolglasses',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar2',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar3',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar4',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar5',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar6',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'collar7',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'bluebandana',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'blackbandana',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn2',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn3',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn4',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn5',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn6',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn7',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn8',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'unihorn9',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat2',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat3',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat4',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat5',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat6',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat7',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat8',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat9',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'tinyhat10',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'beewings',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'batmanvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'redvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'elytecollar',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'blackvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'bowtie',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'daisyvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'petchef',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'daisycrown',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'petdeer',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'petchain',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'partyglasses',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'beetail',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'beadnecklace',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'pinksweater',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'xmasvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'brownshoes',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'fairyvest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
            {
                item = 'k9vest',
                label = 'Phụ kiện pet',
                rarity = 'Epic',
                min_amount = 1,
                max_amount = 1,
                chance = 1.0
            },
           
            {
                item = 'cloth_tshirt',
                label = 'Áo thun ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = {211, 212, 215, 216, 217, 218, 219, 220, 221, 223, 226, 228, 230, 
                234, 235, 237, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 
                250, 251, 259, 264,
            
                303, 304, 305, 310, 311, 312, 317, 318, 319, 320, 321, 324, 325, 329, 334, 335, 336, 337, 338, 
                340, 341, 344, 345, 346, 347, 348, 350, 352, 353, 354, 355, 356, 358, 359, 363,},
                        ['Uncommon'] = {225, 227, 229, 231, 232, 236, 252, 260, 263,
            
                314, 327, 328, 330, 342, 349, 361, 362,},
                        ['Rare'] = {224, 238, 257, 258, 261,
            
                306, 307, 308, 315, 326, 331, 332, 333, 343, 357, 360,},
                        ['Epic'] = {233, 253, 255, 256, 262, 222,
            
                302, 309, 316, 323, 351,},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = {262, 263, 264, 265, 267, 268, 269, 281, 283, 284, 291, 292, 293, 294, 296, 299, 
                302, 304, 305, 308, 310, 313, 314, 319, 320, 321, 326, 327, 328, 330, 331, 333, 334, 335, 337, 
                338, 339, 340, 344, 346, 349, 350, 351, 352, 353, 356, 358, 359, 360, 361, 363, 365, 366, 368, 
                369, 370, 374, 376, 377, 379, 380, 387, 388, 390, 391, 392, 393, 397, 399, 401, 402, 404, 405, 
                406, 407, 409, 410, 411, 416, 417, 418, 420, 421, 422, 423, 424, 426, 427, 428, 430, 434, 436, 
                437, 438, 439, 441, 442, 443, 445, 449, 450, 451, 452, 453, 454, 456, 457, 458, 459, 460, 461, 
                462, 463, 464, 465, 466, 468, 470, 471, 472, 473, 474, 479, 480, 484, 485, 486, 487, 488, 489, 
                490, 491, 492, 493, 495, 498, 502, 503, 504, 505, 506, 507, 510, 512, 513, 515, 516, 517, 518, 
                519, 520, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 533, 535, 538, 539, 540, 541, 542, 
                543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 555, 556, 557, 558, 559, 561, 562, 563, 
                565, 566, 567, 568, 569, 570, 572, 574, 575, 576, 577, 578, 579, 580, 581, 582, 583, 584, 
                585, 586, 587, 588, 589, 590, 591, 592, 593, 594, 595, 596, 597, 598, 599, 600, 601, 602, 604, 
                605, 606, 607, 608, 609, 610, 611, 612, 613, 617, 619, 620,
            
                663, 664, 665, 681, 682, 694, 698, 700, 702, 705, 706, 708, 729, 753, 757, 758,},
                        ['Uncommon'] = {266, 270, 271, 273, 275, 276, 277, 282, 285, 289, 295, 311, 312, 316, 317, 318, 342, 343, 347, 
                362, 378, 381, 396, 425, 429, 431, 432, 447, 469, 477, 478, 499, 500, 501, 532, 534, 615, 616, 
                618, 621,
            
                668, 669, 671, 672, 673, 674, 676, 678, 683, 688, 690, 692, 693, 695, 704, 707, 709, 724, 731,
                732, 735, 737, 738, 741, 742, 743, 752, 754, 756, 762,},
                        ['Rare'] = {272, 274, 278, 279, 280, 286, 287, 290, 297, 298, 300, 301, 315, 322, 324, 325, 329, 348, 357, 
                364, 367, 382, 383, 394, 395, 403, 419, 433, 435, 446, 475, 476, 483, 508, 509, 511, 531, 564, 
                571, 622, 655, 656,
            
                662, 666, 667, 677, 680, 684, 685, 686, 687, 689, 691, 696, 697, 699, 710, 711, 714, 719, 720,
                721, 723, 725, 730, 733, 736, 739, 745, 746, 747, 748, 750, 755, 759, 761, 763,},
                        ['Epic'] = {288, 303, 306, 307, 323, 332, 336, 354, 355, 371, 373, 375, 384, 385, 389, 398, 400, 412, 415, 
                440, 444, 448, 455, 467, 481, 482, 494, 536, 537, 554, 560, 603, 614, 654,
            
                670, 675, 678, 701, 703, 713, 715, 716, 717, 718, 722, 728, 734, 740, 744, 749, 751, 760,},
                        ['Legendary'] = {}
                    }
                },
                min_amount = 1,
                max_amount = 1,
                chance = 90.0,
            },
            {
                item = 'cloth_torso',
                label = 'Áo khoác ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = {549, 550, 551, 552, 553, 554, 555, 556, 562,
                 565, 566, 567, 569, 571, 573, 574, 575, 576, 580, 583, 586, 591, 595,
                 601, 603, 604, 605, 608, 611, 614, 615, 620, 621, 622, 626, 627, 628,
                 630, 632, 634, 635, 637, 638, 639, 640, 642, 646, 647, 649, 650, 653,
                 655, 657, 667, 673, 674, 676, 681, 682, 684, 693, 695, 696, 700, 703,
                 706, 707, 708, 709, 711, 712, 714, 715, 716, 719, 721, 722, 723, 727,
                 729, 732, 734, 735, 738, 739, 742, 747, 748, 749, 750, 751, 752, 753,
                 754, 755, 756, 757, 758, 759, 760, 763, 764, 765, 766, 767, 768, 769,
                 770, 771, 773, 775, 776, 777, 778, 780, 781, 782, 784, 785, 787, 788,
                 791, 792, 793, 795, 796, 797, 798, 799, 800, 801, 802, 804, 806, 807,
                 808, 809, 810, 812, 813, 814, 815, 817, 818, 819, 821, 822, 823, 824,
                 825, 827, 828, 829, 830, 831, 832, 833, 834, 835, 836, 838, 839, 840,
                 843, 845, 846, 848, 852, 853, 855, 856, 857, 859, 861, 862, 863, 864,
                 865, 868, 869, 873, 874, 875, 882, 907, 910, 915, 916, 917, 918, 920,
                 921, 923, 926, 928, 929, 933, 934, 935, 936, 939, 940, 943, 944, 946,
                
                 1034, 1035, 1036, 1037, 1038, 1040, 1041, 1042, 1043, 1045, 1046, 1049,
                 1050, 1051, 1052, 1054, 1055, 1056, 1057, 1059, 1060, 1061, 1062, 1063,
                1065, 1068, 1069, 1070, 1071, 1072, 1073, 1087, 1089, 1102, 1115, 1116, 
                1127, 1128, 1129, 1132, 1134, 1137, 1138, 1151,},
                        ['Uncommon'] = {559, 560, 561, 563, 568, 570, 572, 588, 589, 592, 599, 600, 602, 610, 612, 
                613, 625, 629, 631, 633, 658, 659, 666, 668, 670, 671, 672, 675,
                677, 688, 689, 690, 691, 692, 725, 736, 737, 741, 762, 805, 811, 816, 945,
            
                1044, 1047, 1053, 1067, 1081, 1082, 1084, 1088, 1091, 1092, 1094, 1098, 1109, 1110,
                1111, 1113, 1120, 1122, 1123, 1124, 1126, 1135,},
                        ['Rare'] = {557, 558, 564, 577, 587, 590, 594, 598, 606, 607, 609, 618, 623, 641, 644, 
                654, 656, 662, 663, 664, 665, 669, 678, 679, 680, 683, 685, 687,
                699, 701, 702, 704, 705, 720, 724, 730, 731, 745, 746, 761, 789, 790, 794, 
                803, 820, 841, 842, 844, 851, 858, 860, 867, 870, 871, 872, 876,
                877, 878, 879, 891, 909, 922,
            
                1039, 1048, 1058, 1074, 1076, 1077, 1080, 1083, 1085, 1090, 1093, 1095, 1096,
                1101, 1103, 1104, 1105, 1106, 1107, 1108, 1112, 1114, 1117, 1118, 1119, 1125, 
                1130, 1131, 1136, 1142, 1143, 1145, 1147, 1148, 1149, 1150, 1156, 1157, 1159, 
                1160, 1161,},
                        ['Epic'] = {579, 582, 593, 616, 617, 619, 624, 636, 643, 645, 648, 651, 652, 661, 694, 
                697, 698, 710, 713, 718, 726, 733, 740, 774, 779, 783, 786, 854,
                866, 883, 884, 892, 906, 919, 925, 927, 932, 937, 938, 941, 942, 18, 51, 52,
                116, 194, 195, 497, 985, 986, 987, 988, 989,
            
                1064, 1075, 1078, 1079, 1097, 1100, 1133, 1141, 1144, 1146, 1153, 1154, 1155, 
                1162, 1163,},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = {593, 595, 596, 597, 598, 599, 600, 605, 606, 607, 608, 
                609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619, 620, 621, 622, 623, 624, 625, 
                626, 627, 628, 629, 632, 634, 636, 637, 638, 639, 644, 646, 648, 650, 652, 653, 656, 
                657, 660, 661, 665, 666, 668, 669, 670, 671, 672, 674, 676, 678, 679, 681, 682, 684, 
                686, 687, 688, 691, 693, 696, 697, 698, 704, 707, 710, 712, 715, 716, 719, 723, 725, 
                726, 732, 733, 735, 738, 739, 744, 747, 748, 749, 756, 758, 760, 762, 763, 765, 766, 
                768, 769, 772, 773, 777, 778, 780, 781, 783, 786, 787, 788, 790, 792, 793, 798, 809, 
                812, 814, 815, 817, 818, 819, 820, 821, 822, 823, 824, 825, 826, 827, 828, 830, 832, 
                833, 839, 840, 842, 847, 848, 849, 850, 851, 852, 853, 854, 855, 856, 858, 859, 860, 
                862, 863, 866, 867, 868, 869, 870, 874, 875, 877, 878, 881, 884, 885, 886, 888, 889, 
                891, 895, 905, 907, 908, 909, 911, 912, 913, 914, 915, 918, 919, 922, 923, 924, 925, 
                926, 928, 929, 931, 935, 936, 937, 938, 939, 942, 943, 944, 945, 946, 950, 951, 952, 
                954, 957, 958, 961, 962, 966, 968, 969, 970, 972, 974, 975, 977, 978, 979, 983, 984, 
                985, 986, 996, 997, 999, 1010, 1011, 1014, 1015, 1019, 1020, 1021, 1022, 1023, 1024, 
                1026, 1028, 1029, 1030, 1032, 1037, 1039, 1041, 1042, 1043, 1044, 1045, 1046, 1048, 
                1049, 1050, 1051, 1052, 1054, 1055, 1056, 1057, 1058, 1059, 1062, 1065, 1066, 1067, 
                1068, 1069, 1070, 1072, 1079, 1090, 1092, 1093, 1095, 1099, 1100, 1101, 1102, 1103, 
                1104, 1107, 1109, 1110, 1111, 1112, 1113, 1114, 1117, 1119, 1121, 1122, 1124, 1126, 
                1127, 1129, 1130, 1131, 1133, 1134, 1136, 1137, 1141, 1142, 1143, 1144, 1145, 1146, 
                1147, 1148, 1149, 1154, 1155, 1156, 1157, 1158, 1159, 1160, 1161, 1162, 1163, 1164, 
                1166, 1167, 1168, 1169, 1173, 1175, 1177, 1181, 1183, 1184, 1186, 1187, 1190, 1191, 
                1192, 1196, 1198, 1199, 1204, 1205, 1206, 1208, 1211, 1212, 1213, 1215, 1216, 1218, 
                1220, 1221, 1224, 1225, 1226, 1228, 1229, 1230, 1231, 1232, 1233, 1235, 1238, 1239, 
                1241, 1242, 1243, 1244, 1245, 1246, 1247, 1252, 1256, 1259, 1260, 1266, 1267, 1268, 
                1269, 1270, 1276, 1277, 1280, 1286, 1287, 1288, 1290,
                1299, 1305, 1306, 1307, 1308, 1310, 1319, 1320, 1321, 1322, 1323, 1325, 
                1327, 1328, 1329, 1333, 1334, 1336, 1337, 1338, 1339, 1340, 1341, 1344, 1346, 1347, 
                1355, 1356, 1358, 1359, 1360, 1361, 1362,
            
                1444, 1457, 1460, 1464, 1468, 1473, 1481, 1482, 1485, 1486, 1487, 1489, 1490, 1491, 1492,
                1495, 1497, 1498, 1499, 1503, 1504, 1506, 1509, 1511, 1521, 1549, 1552, 1554, 1558,},
                        ['Uncommon'] = {708, 741, 750, 751, 752, 782, 791, 795, 796, 799, 800, 804, 808, 880, 883, 893, 897, 903, 
                904, 906, 959, 976, 1009, 1013, 1027, 1033, 1178, 1209, 1254, 1265, 1278, 1304, 1331, 601, 
                631, 633, 643, 647, 655, 663, 664, 667, 675, 695, 699, 711, 714, 717, 731, 742, 743, 745, 
                753, 779, 784, 785, 789, 801, 802, 803, 805, 806, 807, 810, 811, 813, 835, 836, 837, 838, 
                841, 887, 890, 892, 896, 898, 899, 900, 901, 902, 940, 941, 948, 953, 955, 956, 960, 963, 
                964, 988, 991, 993, 1002, 1003, 1004, 1005, 1060, 1061, 1086, 1087, 1088, 1089, 1091, 1094, 
                1096, 1097, 1105, 1106, 1108, 1115, 1116, 1118, 1120, 1176, 1179, 1180, 1182, 1185, 1188, 
                1200, 1201, 1271, 1272, 1273, 1274, 1275, 1289, 1363, 1364, 1365,
            
                1454, 1470, 1471, 1480, 1483, 1484, 1488, 1501, 1502, 1505, 1510, 1512, 1516, 1519, 1520, 1522,
                1524, 1525, 1526, 1529, 1539, 1540, 1541, 1550,},
                        ['Rare'] = {1076, 1253, 1264, 1303, 604, 630, 635, 642, 
                645, 658, 659, 662, 673, 677, 680, 683, 685, 702, 713, 718, 728, 729, 730, 734, 740, 767, 771, 
                775, 776, 797, 829, 831, 834, 843, 844, 857, 864, 872, 873, 876, 879, 880, 882, 932, 934, 947, 
                965, 967, 971, 980, 981, 982, 987, 989, 990, 994, 995, 998, 1000, 1001, 1007, 1008, 1016, 1017, 
                1018, 1040, 1047, 1073, 1074, 1075, 1077, 1081, 1082, 1083, 1098, 1123, 1125, 1128, 1132, 1135, 
                1150, 1151, 1152, 1165, 1170, 1171, 1172, 1174, 1219, 1222, 1223, 1227, 1237, 1240, 1296, 1300, 
                1301, 1309, 1311, 1342, 1345,
            
                1445, 1448, 1453, 1455, 1456, 1459, 1461, 1465, 1466, 1469, 1472, 1474, 1477, 1478, 1479, 1496, 
                1500, 1507, 1508, 1515, 1517, 1527, 1528, 1530, 1531, 1536, 1538, 1544, 1545, 1546, 1547, 1548,
                1553, 1555, 1559,},
                        ['Epic'] = {750, 751, 1027, 
                1257, 1350, 
                1427, 1428, 1444, 1445, 1446, 1447, 1448, 1449, 1450, 1451, 1452, 1453, 1454, 1455, 1456, 1457, 
                1458, 602, 603, 640, 649, 651, 689, 690, 692, 694, 701, 705, 706, 720, 721, 722, 724, 727, 736, 
                737, 746, 754, 755, 757, 759, 761, 764, 770, 774, 794, 816, 845, 846, 861, 865, 871, 910, 916, 
                917, 920, 921, 992, 1006, 1012, 1025, 1031, 1034, 1035, 1036, 1038, 1053, 1063, 1064, 1071, 1078, 
                1080, 1084, 1085, 1138, 1139, 1140, 1153, 1203, 1210, 1214, 1217, 1234, 1236, 1248, 1279, 1312, 
                1315, 1316, 1317, 1318, 1324, 1326, 1330, 1332, 1335, 1348, 1349, 1352, 1353, 1354, 1357, 44, 45,
                19, 1291, 1293, 1297, 1298, 536, 452, 196, 197, 108, 933,
            
                1458, 1462, 1467, 1475, 1476, 1493, 1494, 1513, 1518, 1523, 1534, 1535, 1537, 1556, 1557,},
                        ['Legendary'] = {}
                    }
                },
                min_amount = 1,
                max_amount = 1,
                chance = 90.0,
            },
            {
                item = 'cloth_pants',
                label = 'Quần ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = {202, 203, 204, 207, 208, 209, 211, 212, 213, 223, 225, 226, 227, 233,
                234, 235, 238, 244, 245, 246, 247, 248, 250, 252, 253, 254, 255, 256, 257,
                258, 259, 262, 263, 264, 265, 266, 267, 268,
            
                305, 306, 307, 326, 329, 330, 331, 332, 333, 334, 342, 344, },
                        ['Uncommon'] = {205, 206, 214, 215, 224, 228, 229, 230, 240, 241, 242, 243, 274, 275,
            
                308, 312, 313, 315, 316, 317, 318, 319, 320, 321, 322, 323, 324, 325, 335, 336, 340, 341, 343, 
                349,},
                        ['Rare'] = {210, 217, 222, 231, 236, 269, 271, 272, 57,
            
                309, 310, 311, 327, 328, 337, 338, 339, 345, 346, 347, 348, },
                        ['Epic'] = {216, 218, 219, 220, 221, 237, 239, 251, 260, 261, 270, 273, 293, 294, 295,
            
                216, 218, 219, 220, 221, 237, 239, 251, 260, 261, 270, 273, 293, 294, 295},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = {216, 217, 219, 220, 222, 223, 224, 226, 227, 228, 229, 231, 233, 234, 235, 237, 239, 241, 242, 243, 246, 248, 249, 250, 251, 253, 254,
                256, 258, 259, 260, 264, 265, 267, 268, 269, 271, 272},
                        ['Uncommon'] = {218, 221, 232, 236, 238, 244, 252, 270},
                        ['Rare'] = {225, 240, 247, 257, 266225, 240, 247, 257, 266},
                        ['Epic'] = {261, 262, 287, 288, 293, 294, 59, 60, 119,
                285, 286, 287, 288},
                        ['Legendary'] = {}
                    }
                },
                min_amount = 1,
                max_amount = 1,
                chance = 90.0,
            },
            {
                item = 'cloth_shoes',
                label = 'Giày ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = {145, 148, 149, 150, 154, 167, 168, 169, 180, 181, 183, 186, 188, 192, 195, 196, 199, 204, 205, 208, 209,
            
                222, 223, 226, 229, 230, 239, 240, 241, 242, 243, 244, 245, 249, 250, 253, 255, 256, 262, 265, 266, 267, 268,
                274, 275, 276, 277, 278, 279, 283, 284, 285, 286, 288, 293, 294, 295, 296, 297, 298, 299, 300, 302, 303, 305, 
                307, 308, 309, 310, 311, 312, 313, 321, 322, 323, 324, 325, 326, 327, 328, 329, 330, 331, 332, 333, 334, 335,},
                        ['Uncommon'] = {146, 147, 160, 164, 165, 172, 184, 185, 189, 190, 191, 193, 194, 202, 203, 206, 207, 216,
            
                231, 234, 235, 238, 246, 254, 257, 259, 260, 261, 263, 264, 271, 272, 273, 280, 287, 289, 290, 291, 292, 301, 
                314, 315, 316, 318, 319, 320,},
                        ['Rare'] = {151, 152, 153, 155, 156, 157, 158, 159, 161, 162, 166, 170, 171, 178, 179, 182, 200, 201, 210, 211, 212, 213, 214, 215, 218,
                219, 220, 221,
            
                224, 236, 237, 247, 248, 251, 252, 269, 304,},
                        ['Epic'] = {173, 174, 175, 176, 177, 187, 198, 217,
            
                232, 270, 281, 306,},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = {130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155,
                156, 157, 158, 159, 162, 163, 167, 168, 169, 171, 178, 180, 185,
                188, 190, 192, 194, 195, 198, 201, 202, 203, 204, 205, 211, 213, 215,
                217, 218, 222, 223, 224, 232, 235, 240, 243, 248, 
                255, 256, 257, 268, 273, 275, 277, 281, 290, 292,
                293, 294, 297,
            
                327, 331, 334, 338, 340, 343, 345, 348, 350, 351, 353, 357, 359, 360, 364, 366, 368, 372, 376, 377,},
                        ['Uncommon'] = {165, 172, 176, 206, 208, 214, 227, 226, 236, 238, 239, 242, 241, 250, 251, 265, 264, 271, 272, 276, 301, 299, 296, 160, 164, 170, 
                173, 174, 175, 177, 179, 225, 229, 230, 231, 233, 234, 244, 246, 247, 249, 252, 253, 254, 259, 260, 288, 289, 291, 297,
            
                317, 322, 323, 324, 325, 328, 330, 332, 339, 341, 349, 352, 356, 358, 363, 365, 367, 370, 373, 374, 381,},
                        ['Rare'] = {161, 216, 237, 262, 266, 267, 274, 295, 298, 300, 302, 181, 186, 187, 189, 191, 193, 196, 197, 199, 200, 209, 210, 212, 218, 219, 
                220, 221, 261, 263, 269, 280, 282, 283,
            
                318, 319, 320, 321, 329, 337, 342, 344, 347, 355, 361, 371, 380,},
                        ['Epic'] = {182, 183, 184, 207, 284, 285, 286, 245,
            
                326, 333, 335, 336, 346, 369, 375, 382,},
                        ['Legendary'] = {}
                    }
                },
                min_amount = 1,
                max_amount = 1,
                chance = 90.0,
            },
           
        }
    },    
    
    
    ['goi_van_truot'] = {
        label = 'Gói Ván Trượt',
        description = 'Có cơ hội nhận được Ván trượt',
        image = "s1",
        animation_duration = 5000, 
        amount = 22,
        type = 'coin',
        items = {
           {
                item = 'skateboard',
                label = 'Skateboard',
                rarity = 'Legendary',
                min_amount = 1,
                max_amount = 1,
                chance = 0.0,
                PitySystem = {min = 45, max = 90},
            },

            {
                item = 'cloth_tshirt',
                label = 'Áo thun ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = {211, 212, 215, 216, 217, 218, 219, 220, 221, 223, 226, 228, 230, 
                234, 235, 237, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 
                250, 251, 259, 264,
            
                303, 304, 305, 310, 311, 312, 317, 318, 319, 320, 321, 324, 325, 329, 334, 335, 336, 337, 338, 
                340, 341, 344, 345, 346, 347, 348, 350, 352, 353, 354, 355, 356, 358, 359, 363,},
                        ['Uncommon'] = {225, 227, 229, 231, 232, 236, 252, 260, 263,
            
                314, 327, 328, 330, 342, 349, 361, 362,},
                        ['Rare'] = {224, 238, 257, 258, 261,
            
                306, 307, 308, 315, 326, 331, 332, 333, 343, 357, 360,},
                        ['Epic'] = {233, 253, 255, 256, 262, 222,
            
                302, 309, 316, 323, 351,},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = {262, 263, 264, 265, 267, 268, 269, 281, 283, 284, 291, 292, 293, 294, 296, 299, 
                302, 304, 305, 308, 310, 313, 314, 319, 320, 321, 326, 327, 328, 330, 331, 333, 334, 335, 337, 
                338, 339, 340, 344, 346, 349, 350, 351, 352, 353, 356, 358, 359, 360, 361, 363, 365, 366, 368, 
                369, 370, 374, 376, 377, 379, 380, 387, 388, 390, 391, 392, 393, 397, 399, 401, 402, 404, 405, 
                406, 407, 409, 410, 411, 416, 417, 418, 420, 421, 422, 423, 424, 426, 427, 428, 430, 434, 436, 
                437, 438, 439, 441, 442, 443, 445, 449, 450, 451, 452, 453, 454, 456, 457, 458, 459, 460, 461, 
                462, 463, 464, 465, 466, 468, 470, 471, 472, 473, 474, 479, 480, 484, 485, 486, 487, 488, 489, 
                490, 491, 492, 493, 495, 498, 502, 503, 504, 505, 506, 507, 510, 512, 513, 515, 516, 517, 518, 
                519, 520, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 533, 535, 538, 539, 540, 541, 542, 
                543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 555, 556, 557, 558, 559, 561, 562, 563, 
                565, 566, 567, 568, 569, 570, 572, 574, 575, 576, 577, 578, 579, 580, 581, 582, 583, 584, 
                585, 586, 587, 588, 589, 590, 591, 592, 593, 594, 595, 596, 597, 598, 599, 600, 601, 602, 604, 
                605, 606, 607, 608, 609, 610, 611, 612, 613, 617, 619, 620,
            
                663, 664, 665, 681, 682, 694, 698, 700, 702, 705, 706, 708, 729, 753, 757, 758,},
                        ['Uncommon'] = {266, 270, 271, 273, 275, 276, 277, 282, 285, 289, 295, 311, 312, 316, 317, 318, 342, 343, 347, 
                362, 378, 381, 396, 425, 429, 431, 432, 447, 469, 477, 478, 499, 500, 501, 532, 534, 615, 616, 
                618, 621,
            
                668, 669, 671, 672, 673, 674, 676, 678, 683, 688, 690, 692, 693, 695, 704, 707, 709, 724, 731,
                732, 735, 737, 738, 741, 742, 743, 752, 754, 756, 762,},
                        ['Rare'] = {272, 274, 278, 279, 280, 286, 287, 290, 297, 298, 300, 301, 315, 322, 324, 325, 329, 348, 357, 
                364, 367, 382, 383, 394, 395, 403, 419, 433, 435, 446, 475, 476, 483, 508, 509, 511, 531, 564, 
                571, 622, 655, 656,
            
                662, 666, 667, 677, 680, 684, 685, 686, 687, 689, 691, 696, 697, 699, 710, 711, 714, 719, 720,
                721, 723, 725, 730, 733, 736, 739, 745, 746, 747, 748, 750, 755, 759, 761, 763,},
                        ['Epic'] = {288, 303, 306, 307, 323, 332, 336, 354, 355, 371, 373, 375, 384, 385, 389, 398, 400, 412, 415, 
                440, 444, 448, 455, 467, 481, 482, 494, 536, 537, 554, 560, 603, 614, 654,
            
                670, 675, 678, 701, 703, 713, 715, 716, 717, 718, 722, 728, 734, 740, 744, 749, 751, 760,},
                        ['Legendary'] = {}
                    }
                },
                min_amount = 1,
                max_amount = 1,
                chance = 90.0,
            },
            {
                item = 'cloth_torso',
                label = 'Áo khoác ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = {549, 550, 551, 552, 553, 554, 555, 556, 562,
                 565, 566, 567, 569, 571, 573, 574, 575, 576, 580, 583, 586, 591, 595,
                 601, 603, 604, 605, 608, 611, 614, 615, 620, 621, 622, 626, 627, 628,
                 630, 632, 634, 635, 637, 638, 639, 640, 642, 646, 647, 649, 650, 653,
                 655, 657, 667, 673, 674, 676, 681, 682, 684, 693, 695, 696, 700, 703,
                 706, 707, 708, 709, 711, 712, 714, 715, 716, 719, 721, 722, 723, 727,
                 729, 732, 734, 735, 738, 739, 742, 747, 748, 749, 750, 751, 752, 753,
                 754, 755, 756, 757, 758, 759, 760, 763, 764, 765, 766, 767, 768, 769,
                 770, 771, 773, 775, 776, 777, 778, 780, 781, 782, 784, 785, 787, 788,
                 791, 792, 793, 795, 796, 797, 798, 799, 800, 801, 802, 804, 806, 807,
                 808, 809, 810, 812, 813, 814, 815, 817, 818, 819, 821, 822, 823, 824,
                 825, 827, 828, 829, 830, 831, 832, 833, 834, 835, 836, 838, 839, 840,
                 843, 845, 846, 848, 852, 853, 855, 856, 857, 859, 861, 862, 863, 864,
                 865, 868, 869, 873, 874, 875, 882, 907, 910, 915, 916, 917, 918, 920,
                 921, 923, 926, 928, 929, 933, 934, 935, 936, 939, 940, 943, 944, 946,
                
                 1034, 1035, 1036, 1037, 1038, 1040, 1041, 1042, 1043, 1045, 1046, 1049,
                 1050, 1051, 1052, 1054, 1055, 1056, 1057, 1059, 1060, 1061, 1062, 1063,
                1065, 1068, 1069, 1070, 1071, 1072, 1073, 1087, 1089, 1102, 1115, 1116, 
                1127, 1128, 1129, 1132, 1134, 1137, 1138, 1151,},
                        ['Uncommon'] = {559, 560, 561, 563, 568, 570, 572, 588, 589, 592, 599, 600, 602, 610, 612, 
                613, 625, 629, 631, 633, 658, 659, 666, 668, 670, 671, 672, 675,
                677, 688, 689, 690, 691, 692, 725, 736, 737, 741, 762, 805, 811, 816, 945,
            
                1044, 1047, 1053, 1067, 1081, 1082, 1084, 1088, 1091, 1092, 1094, 1098, 1109, 1110,
                1111, 1113, 1120, 1122, 1123, 1124, 1126, 1135,},
                        ['Rare'] = {557, 558, 564, 577, 587, 590, 594, 598, 606, 607, 609, 618, 623, 641, 644, 
                654, 656, 662, 663, 664, 665, 669, 678, 679, 680, 683, 685, 687,
                699, 701, 702, 704, 705, 720, 724, 730, 731, 745, 746, 761, 789, 790, 794, 
                803, 820, 841, 842, 844, 851, 858, 860, 867, 870, 871, 872, 876,
                877, 878, 879, 891, 909, 922,
            
                1039, 1048, 1058, 1074, 1076, 1077, 1080, 1083, 1085, 1090, 1093, 1095, 1096,
                1101, 1103, 1104, 1105, 1106, 1107, 1108, 1112, 1114, 1117, 1118, 1119, 1125, 
                1130, 1131, 1136, 1142, 1143, 1145, 1147, 1148, 1149, 1150, 1156, 1157, 1159, 
                1160, 1161,},
                        ['Epic'] = {579, 582, 593, 616, 617, 619, 624, 636, 643, 645, 648, 651, 652, 661, 694, 
                697, 698, 710, 713, 718, 726, 733, 740, 774, 779, 783, 786, 854,
                866, 883, 884, 892, 906, 919, 925, 927, 932, 937, 938, 941, 942, 18, 51, 52,
                116, 194, 195, 497, 985, 986, 987, 988, 989,
            
                1064, 1075, 1078, 1079, 1097, 1100, 1133, 1141, 1144, 1146, 1153, 1154, 1155, 
                1162, 1163,},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = {593, 595, 596, 597, 598, 599, 600, 605, 606, 607, 608, 
                609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619, 620, 621, 622, 623, 624, 625, 
                626, 627, 628, 629, 632, 634, 636, 637, 638, 639, 644, 646, 648, 650, 652, 653, 656, 
                657, 660, 661, 665, 666, 668, 669, 670, 671, 672, 674, 676, 678, 679, 681, 682, 684, 
                686, 687, 688, 691, 693, 696, 697, 698, 704, 707, 710, 712, 715, 716, 719, 723, 725, 
                726, 732, 733, 735, 738, 739, 744, 747, 748, 749, 756, 758, 760, 762, 763, 765, 766, 
                768, 769, 772, 773, 777, 778, 780, 781, 783, 786, 787, 788, 790, 792, 793, 798, 809, 
                812, 814, 815, 817, 818, 819, 820, 821, 822, 823, 824, 825, 826, 827, 828, 830, 832, 
                833, 839, 840, 842, 847, 848, 849, 850, 851, 852, 853, 854, 855, 856, 858, 859, 860, 
                862, 863, 866, 867, 868, 869, 870, 874, 875, 877, 878, 881, 884, 885, 886, 888, 889, 
                891, 895, 905, 907, 908, 909, 911, 912, 913, 914, 915, 918, 919, 922, 923, 924, 925, 
                926, 928, 929, 931, 935, 936, 937, 938, 939, 942, 943, 944, 945, 946, 950, 951, 952, 
                954, 957, 958, 961, 962, 966, 968, 969, 970, 972, 974, 975, 977, 978, 979, 983, 984, 
                985, 986, 996, 997, 999, 1010, 1011, 1014, 1015, 1019, 1020, 1021, 1022, 1023, 1024, 
                1026, 1028, 1029, 1030, 1032, 1037, 1039, 1041, 1042, 1043, 1044, 1045, 1046, 1048, 
                1049, 1050, 1051, 1052, 1054, 1055, 1056, 1057, 1058, 1059, 1062, 1065, 1066, 1067, 
                1068, 1069, 1070, 1072, 1079, 1090, 1092, 1093, 1095, 1099, 1100, 1101, 1102, 1103, 
                1104, 1107, 1109, 1110, 1111, 1112, 1113, 1114, 1117, 1119, 1121, 1122, 1124, 1126, 
                1127, 1129, 1130, 1131, 1133, 1134, 1136, 1137, 1141, 1142, 1143, 1144, 1145, 1146, 
                1147, 1148, 1149, 1154, 1155, 1156, 1157, 1158, 1159, 1160, 1161, 1162, 1163, 1164, 
                1166, 1167, 1168, 1169, 1173, 1175, 1177, 1181, 1183, 1184, 1186, 1187, 1190, 1191, 
                1192, 1196, 1198, 1199, 1204, 1205, 1206, 1208, 1211, 1212, 1213, 1215, 1216, 1218, 
                1220, 1221, 1224, 1225, 1226, 1228, 1229, 1230, 1231, 1232, 1233, 1235, 1238, 1239, 
                1241, 1242, 1243, 1244, 1245, 1246, 1247, 1252, 1256, 1259, 1260, 1266, 1267, 1268, 
                1269, 1270, 1276, 1277, 1280, 1286, 1287, 1288, 1290,
                1299, 1305, 1306, 1307, 1308, 1310, 1319, 1320, 1321, 1322, 1323, 1325, 
                1327, 1328, 1329, 1333, 1334, 1336, 1337, 1338, 1339, 1340, 1341, 1344, 1346, 1347, 
                1355, 1356, 1358, 1359, 1360, 1361, 1362,
            
                1444, 1457, 1460, 1464, 1468, 1473, 1481, 1482, 1485, 1486, 1487, 1489, 1490, 1491, 1492,
                1495, 1497, 1498, 1499, 1503, 1504, 1506, 1509, 1511, 1521, 1549, 1552, 1554, 1558,},
                        ['Uncommon'] = {708, 741, 750, 751, 752, 782, 791, 795, 796, 799, 800, 804, 808, 880, 883, 893, 897, 903, 
                904, 906, 959, 976, 1009, 1013, 1027, 1033, 1178, 1209, 1254, 1265, 1278, 1304, 1331, 601, 
                631, 633, 643, 647, 655, 663, 664, 667, 675, 695, 699, 711, 714, 717, 731, 742, 743, 745, 
                753, 779, 784, 785, 789, 801, 802, 803, 805, 806, 807, 810, 811, 813, 835, 836, 837, 838, 
                841, 887, 890, 892, 896, 898, 899, 900, 901, 902, 940, 941, 948, 953, 955, 956, 960, 963, 
                964, 988, 991, 993, 1002, 1003, 1004, 1005, 1060, 1061, 1086, 1087, 1088, 1089, 1091, 1094, 
                1096, 1097, 1105, 1106, 1108, 1115, 1116, 1118, 1120, 1176, 1179, 1180, 1182, 1185, 1188, 
                1200, 1201, 1271, 1272, 1273, 1274, 1275, 1289, 1363, 1364, 1365,
            
                1454, 1470, 1471, 1480, 1483, 1484, 1488, 1501, 1502, 1505, 1510, 1512, 1516, 1519, 1520, 1522,
                1524, 1525, 1526, 1529, 1539, 1540, 1541, 1550,},
                        ['Rare'] = {1076, 1253, 1264, 1303, 604, 630, 635, 642, 
                645, 658, 659, 662, 673, 677, 680, 683, 685, 702, 713, 718, 728, 729, 730, 734, 740, 767, 771, 
                775, 776, 797, 829, 831, 834, 843, 844, 857, 864, 872, 873, 876, 879, 880, 882, 932, 934, 947, 
                965, 967, 971, 980, 981, 982, 987, 989, 990, 994, 995, 998, 1000, 1001, 1007, 1008, 1016, 1017, 
                1018, 1040, 1047, 1073, 1074, 1075, 1077, 1081, 1082, 1083, 1098, 1123, 1125, 1128, 1132, 1135, 
                1150, 1151, 1152, 1165, 1170, 1171, 1172, 1174, 1219, 1222, 1223, 1227, 1237, 1240, 1296, 1300, 
                1301, 1309, 1311, 1342, 1345,
            
                1445, 1448, 1453, 1455, 1456, 1459, 1461, 1465, 1466, 1469, 1472, 1474, 1477, 1478, 1479, 1496, 
                1500, 1507, 1508, 1515, 1517, 1527, 1528, 1530, 1531, 1536, 1538, 1544, 1545, 1546, 1547, 1548,
                1553, 1555, 1559,},
                        ['Epic'] = {750, 751, 1027, 
                1257, 1350, 
                1427, 1428, 1444, 1445, 1446, 1447, 1448, 1449, 1450, 1451, 1452, 1453, 1454, 1455, 1456, 1457, 
                1458, 602, 603, 640, 649, 651, 689, 690, 692, 694, 701, 705, 706, 720, 721, 722, 724, 727, 736, 
                737, 746, 754, 755, 757, 759, 761, 764, 770, 774, 794, 816, 845, 846, 861, 865, 871, 910, 916, 
                917, 920, 921, 992, 1006, 1012, 1025, 1031, 1034, 1035, 1036, 1038, 1053, 1063, 1064, 1071, 1078, 
                1080, 1084, 1085, 1138, 1139, 1140, 1153, 1203, 1210, 1214, 1217, 1234, 1236, 1248, 1279, 1312, 
                1315, 1316, 1317, 1318, 1324, 1326, 1330, 1332, 1335, 1348, 1349, 1352, 1353, 1354, 1357, 44, 45,
                19, 1291, 1293, 1297, 1298, 536, 452, 196, 197, 108, 933,
            
                1458, 1462, 1467, 1475, 1476, 1493, 1494, 1513, 1518, 1523, 1534, 1535, 1537, 1556, 1557,},
                        ['Legendary'] = {}
                    }
                },
                min_amount = 1,
                max_amount = 1,
                chance = 90.0,
            },
            {
                item = 'cloth_pants',
                label = 'Quần ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = {202, 203, 204, 207, 208, 209, 211, 212, 213, 223, 225, 226, 227, 233,
                234, 235, 238, 244, 245, 246, 247, 248, 250, 252, 253, 254, 255, 256, 257,
                258, 259, 262, 263, 264, 265, 266, 267, 268,
            
                305, 306, 307, 326, 329, 330, 331, 332, 333, 334, 342, 344, },
                        ['Uncommon'] = {205, 206, 214, 215, 224, 228, 229, 230, 240, 241, 242, 243, 274, 275,
            
                308, 312, 313, 315, 316, 317, 318, 319, 320, 321, 322, 323, 324, 325, 335, 336, 340, 341, 343, 
                349,},
                        ['Rare'] = {210, 217, 222, 231, 236, 269, 271, 272, 57,
            
                309, 310, 311, 327, 328, 337, 338, 339, 345, 346, 347, 348, },
                        ['Epic'] = {216, 218, 219, 220, 221, 237, 239, 251, 260, 261, 270, 273, 293, 294, 295,
            
                216, 218, 219, 220, 221, 237, 239, 251, 260, 261, 270, 273, 293, 294, 295},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = {216, 217, 219, 220, 222, 223, 224, 226, 227, 228, 229, 231, 233, 234, 235, 237, 239, 241, 242, 243, 246, 248, 249, 250, 251, 253, 254,
                256, 258, 259, 260, 264, 265, 267, 268, 269, 271, 272},
                        ['Uncommon'] = {218, 221, 232, 236, 238, 244, 252, 270},
                        ['Rare'] = {225, 240, 247, 257, 266225, 240, 247, 257, 266},
                        ['Epic'] = {261, 262, 287, 288, 293, 294, 59, 60, 119,
                285, 286, 287, 288},
                        ['Legendary'] = {}
                    }
                },
                min_amount = 1,
                max_amount = 1,
                chance = 90.0,
            },
            {
                item = 'cloth_shoes',
                label = 'Giày ngẫu nhiên',
                rarity = {
                    ["male"] = {
                        ['Common'] = {145, 148, 149, 150, 154, 167, 168, 169, 180, 181, 183, 186, 188, 192, 195, 196, 199, 204, 205, 208, 209,
            
                222, 223, 226, 229, 230, 239, 240, 241, 242, 243, 244, 245, 249, 250, 253, 255, 256, 262, 265, 266, 267, 268,
                274, 275, 276, 277, 278, 279, 283, 284, 285, 286, 288, 293, 294, 295, 296, 297, 298, 299, 300, 302, 303, 305, 
                307, 308, 309, 310, 311, 312, 313, 321, 322, 323, 324, 325, 326, 327, 328, 329, 330, 331, 332, 333, 334, 335,},
                        ['Uncommon'] = {146, 147, 160, 164, 165, 172, 184, 185, 189, 190, 191, 193, 194, 202, 203, 206, 207, 216,
            
                231, 234, 235, 238, 246, 254, 257, 259, 260, 261, 263, 264, 271, 272, 273, 280, 287, 289, 290, 291, 292, 301, 
                314, 315, 316, 318, 319, 320,},
                        ['Rare'] = {151, 152, 153, 155, 156, 157, 158, 159, 161, 162, 166, 170, 171, 178, 179, 182, 200, 201, 210, 211, 212, 213, 214, 215, 218,
                219, 220, 221,
            
                224, 236, 237, 247, 248, 251, 252, 269, 304,},
                        ['Epic'] = {173, 174, 175, 176, 177, 187, 198, 217,
            
                232, 270, 281, 306,},
                        ['Legendary'] = {}
                    },
                    ["female"] = {
                        ['Common'] = {130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155,
                156, 157, 158, 159, 162, 163, 167, 168, 169, 171, 178, 180, 185,
                188, 190, 192, 194, 195, 198, 201, 202, 203, 204, 205, 211, 213, 215,
                217, 218, 222, 223, 224, 232, 235, 240, 243, 248, 
                255, 256, 257, 268, 273, 275, 277, 281, 290, 292,
                293, 294, 297,
            
                327, 331, 334, 338, 340, 343, 345, 348, 350, 351, 353, 357, 359, 360, 364, 366, 368, 372, 376, 377,},
                        ['Uncommon'] = {165, 172, 176, 206, 208, 214, 227, 226, 236, 238, 239, 242, 241, 250, 251, 265, 264, 271, 272, 276, 301, 299, 296, 160, 164, 170, 
                173, 174, 175, 177, 179, 225, 229, 230, 231, 233, 234, 244, 246, 247, 249, 252, 253, 254, 259, 260, 288, 289, 291, 297,
            
                317, 322, 323, 324, 325, 328, 330, 332, 339, 341, 349, 352, 356, 358, 363, 365, 367, 370, 373, 374, 381,},
                        ['Rare'] = {161, 216, 237, 262, 266, 267, 274, 295, 298, 300, 302, 181, 186, 187, 189, 191, 193, 196, 197, 199, 200, 209, 210, 212, 218, 219, 
                220, 221, 261, 263, 269, 280, 282, 283,
            
                318, 319, 320, 321, 329, 337, 342, 344, 347, 355, 361, 371, 380,},
                        ['Epic'] = {182, 183, 184, 207, 284, 285, 286, 245,
            
                326, 333, 335, 336, 346, 369, 375, 382,},
                        ['Legendary'] = {}
                    }
                },
                min_amount = 1,
                max_amount = 1,
                chance = 90.0,
            },
           
        }
    },
    
    
    -- ['goi_ky_lan'] = {
    --     label = 'Gói Kỳ Lân',
    --     description = 'Có cơ hội nhận được Pet Kỳ Lân',
    --     image = "kylan",
    --     animation_duration = 5000, 
    --     amount = 50,
    --     type = 'coin',
    --     items = {
    --        {
    --             item = 'pet_lion',
    --             label = 'Pet Kỳ Lân',
    --             rarity = 'Legendary',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 0.0,
    --             PitySystem = {min = 200, max = 300},
    --         },
    --         {
    --             item = 'rose',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'controller',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'hat',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'hat2',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'teddybear',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'glasses',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'glasses2',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'coolglasses',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'collar',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'collar2',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'collar3',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'collar4',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'collar5',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'collar6',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'collar7',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'bluebandana',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'blackbandana',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'unihorn',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'unihorn2',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'unihorn3',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'unihorn4',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'unihorn5',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'unihorn6',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'unihorn7',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'unihorn8',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'unihorn9',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'tinyhat',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'tinyhat2',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'tinyhat3',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'tinyhat4',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'tinyhat5',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'tinyhat6',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'tinyhat7',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'tinyhat8',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'tinyhat9',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'tinyhat10',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'beewings',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'batmanvest',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'redvest',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'elytecollar',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'blackvest',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'bowtie',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'daisyvest',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'petchef',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'daisycrown',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'petdeer',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'petchain',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'partyglasses',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'beetail',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'beadnecklace',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'pinksweater',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'xmasvest',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'brownshoes',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'fairyvest',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'k9vest',
    --             label = 'Phụ kiện pet',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0
    --         },
    --         {
    --             item = 'phoinangcap4',
    --             label = 'Phôi nâng cấp 4',
    --             rarity = 'Epic',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 1.0,
    --             PitySystem = {min = 10, max = 20},
    --         },
    --         {
    --             item = 'phoinangcap3',
    --             label = 'Phôi nâng cấp 3',
    --             rarity = 'Rare',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 5.0,
    --             PitySystem = {min = 5, max = 10},
    --         },
    --         {
    --             item = 'phoinangcap2',
    --             label = 'Phôi nâng cấp 2',
    --             rarity = 'Uncommon',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 70.0,
    --         },
    --         {
    --             item = 'phoinangcap1',
    --             label = 'Phôi nâng cấp 1',
    --             rarity = 'Common',
    --             min_amount = 1,
    --             max_amount = 3,
    --             chance = 90.0,
    --         },
           
    --     }
    -- }


    -- ['goi_combo'] = {
    --     label = 'gói combo',
    --     description = 'Một chiếc gói sử thi chứa những vật phẩm cực kì quý hiếm',
    --     image = "b4",
    --     amount = 10000,
    --     type = 'bank',
    --     animation_duration = 3000,
    --     items = {
    --        {
    --             item = 'banhmi',
    --             label = 'Bánh Mì',
    --             rarity = 'common',
    --             min_amount = 1,
    --             max_amount = 2,
    --             chance = 70.0
    --         },
    --         {
    --             item = 'trung_thu',
    --             label = 'Trứng Thú',
    --             rarity = 'common',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 40.0
    --         },
    --         {
    --             item = 'phoinangcap4',
    --             label = 'Phôi nâng cấp 4',
    --             rarity = 'Rare',
    --             min_amount = 1,
    --             max_amount = 1,
    --             chance = 17.0,
    --             PitySystem = {min = 20, max = 30}
    --         },
    --     }
    -- },
}

-- Cấu hình clothing items
Config.ClothingItems = {
    ['cloth_bags'] = {
        component = 5,
        prop = false,
        label = 'Túi xách'
    },
    ['cloth_mask'] = {
        component = 1,
        prop = false,
        label = 'Mặt nạ'
    },
    ['cloth_helmet'] = {
        component = 0,
        prop = true,
        label = 'Mũ'
    },
    ['cloth_ears'] = {
        component = 2,
        prop = true,
        label = 'Phụ kiện tai'
    },
    ['cloth_glasses'] = {
        component = 1,
        prop = true,
        label = 'Kính mắt'
    },
    ['cloth_tshirt'] = {
        component = 8,
        prop = false,
        label = 'Áo thun'
    },
    ['cloth_torso'] = {
        component = 11,
        prop = false,
        label = 'Áo khoác'
    },
    ['cloth_bproof'] = {
        component = 9,
        prop = false,
        label = 'Áo chống đạn'
    },
    ['cloth_bracelets'] = {
        component = 7,
        prop = true,
        label = 'Vòng tay'
    },
    ['cloth_watches'] = {
        component = 6,
        prop = true,
        label = 'Đồng hồ'
    },
    ['cloth_chain'] = {
        component = 7,
        prop = false,
        label = 'Dây chuyền'
    },
    ['cloth_pants'] = {
        component = 4,
        prop = false,
        label = 'Quần dài'
    },
    ['cloth_shoes'] = {
        component = 6,
        prop = false,
        label = 'Giày'
    },
    ['cloth_arms'] = {
        component = 3,
        prop = false,
        label = 'Phụ kiện tay'
    }
}

-- Cấu hình âm thanh
Config.Sounds = {
    ['bag_open'] = {
        name = 'MENU_ACCEPT',
        set = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
    },
    ['item_received'] = {
        name = 'PICKUP_WEAPON',
        set = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
    }
}

-- Cài đặt thông báo
Config.Notifications = {
    ['bag_opened'] = 'Bạn đã mở túi và nhận được các vật phẩm!',
    ['bag_not_found'] = 'Không tìm thấy túi trong túi đồ!',
    ['cooldown_active'] = 'Bạn cần chờ %s giây trước khi mở túi tiếp theo!',
    ['inventory_full'] = 'Túi đồ của bạn đã đầy!',
    ['item_received'] = 'Bạn đã nhận được %sx %s',
    ['money_received'] = 'Bạn đã nhận được $%s',
    ['black_money_received'] = 'Bạn đã nhận được $%s tiền đen'
}

Config.EventPoin = {
    ["Hòm Tân Niên"] = function(citizenid, name)
        exports['XN_NoelBox']:AddICPoints(citizenid, name, 1)
    end,
    ["Hòm Bính Ngọ"] = function(citizenid, name)
        exports['XN_NoelBox']:AddOCPoints(citizenid, name, 1)
    end
}
Config.caseLabel = "Hòm Noel"
