Config = Config or {}

-- [[ CÀI ĐẶT CHUNG ]] --
Config.TestDriveTimer = 60000 -- Thời gian lái thử (mili giây = 60 giây)

-- [[ VỊ TRÍ CẢNG NHẬP XE CHUNG ]] --
Config.PortLocation = {
    [1] = vector4(1195.09, -2942.77, 5.9, 94.13),
    [2] = vector4(1185.09, -2942.77, 5.9, 94.13),
    [3] = vector4(1175.09, -2942.77, 5.9, 94.13),
    [4] = vector4(1195.09, -2926.77, 5.9, 94.13),
    [5] = vector4(1185.09, -2926.77, 5.9, 94.13),
    [6] = vector4(1175.09, -2926.77, 5.9, 94.13),
    [7] = vector4(1195.09, -2914.77, 5.9, 94.13),
    [8] = vector4(1185.09, -2914.77, 5.9, 94.13),
    [9] = vector4(1175.09, -2914.77, 5.9, 94.13),
}

-- [[ CẤP BẬC ĐƯỢC PHÉP NHẬP XE ]] --
Config.NhapXe_Grade = {
    [1] = true,
    [2] = true,
    [3] = true,
    [4] = true,
    [5] = true,
}

-- [[ KIỂM TRA XE TRÙNG LẶP ]] --
Config.DuplicateCheck = {
    enabled = true,
    vehicles = {
        ["blista"] = true,
        ["faggio3"] = true,
    }
}

-- [[ MÃ GIẢM GIÁ (COUPONS) ]] --
Config.DiscountCoupons = {
    ['ve_doi_xe_civic'] = {
        label = 'Vé đổi xe Civic',
        discount = 100,
        vehicle = 'thecivir23',
        event = true,
    },
    ['ve_doi_xe_titanh'] = {
        label = 'Vé đổi xe Titanh2',
        discount = 100,
        vehicle = 'titanh2',
        event = true,
    },
    ['key_sh350'] = {
        label = 'Vé đổi xe SH350i',
        discount = 100,
        vehicle = 'sh350',
        event = true,
    },
    ['key_yaz'] = {
        label = 'Vé đổi xe YAZ',
        discount = 100,
        vehicle = 'yaz',
        event = true,
    },
    ['key_jackal'] = {
        label = 'Vé đổi xe Jackal',
        discount = 100,
        vehicle = 'jackal',
        event = true,
    },
    ['key_dodgecharger'] = {
        label = 'Vé đổi xe Dodge Charger',
        discount = 100,
        vehicle = 'chargerf8',
        event = true,
    },
    ['key_suprahong'] = {
        label = 'Vé đổi xe Honda S200',
        discount = 100,
        vehicle = 'r2f2fs2000',
        event = true,
    },
    ['key_supracam'] = {
        label = 'Vé đổi xe Toyota Supra',
        discount = 100,
        vehicle = 'fnfmk4',
        event = true,
    },
    ['key_tires'] = {
        label = 'Vé đổi xe Evolution',
        discount = 100,
        vehicle = 'fnflan',
        event = true,
    },
    ['key_r34'] = {
        label = 'Vé đổi xe R34',
        discount = 100,
        vehicle = 'r2f2fgtr34',
        event = true,
    },
    ['key_spydergts'] = {
        label = 'Vé đổi xe spydergts',
        discount = 100,
        vehicle = 'r2f2fgts',
        event = true,
    },
    ['key_rx7'] = {
        label = 'Vé đổi xe Mazda RX7',
        discount = 100,
        vehicle = 'fnfrx7',
        event = true,
    },
    ['key_eclipse'] = {
        label = 'Vé đổi xe Mitsubishi Eclipse',
        discount = 100,
        vehicle = 'fnfmits',
        event = true,
    },
    ['key_supra_equator'] = {
        label = 'Vé đổi xe Supra Equator',
        discount = 100,
        vehicle = 'r2f2fmk4',
        event = true,
    },
    ['key_evomanz'] = {
        label = 'Vé đổi xe Evolution Manz',
        discount = 100,
        vehicle = 'r2f2fmle7',
        event = true,
    },
    ['key_bmwm8'] = {
        label = 'Vé đổi xe BMW M8',
        discount = 100,
        vehicle = 'bmwm8',
        event = true,
    },
    ['key_draugur'] = {
        label = 'Vé đổi xe draugur',
        discount = 100,
        vehicle = 'draugur',
        event = true,
    },
    ['vedoixevf9'] = {
        label = 'Vé đổi xe VF9',
        discount = 100,
        vehicle = 'vf9',
        event = true,
    },
    ['vedoixevf3'] = {
        label = 'Vé đổi xe VF3',
        discount = 100,
        vehicle = 'vf3',
        event = true,
    },
    ['vedoixevf8'] = {
        label = 'Vé đổi xe VF8',
        discount = 100,
        vehicle = 'vf8',
        event = true,
    },
    ['key_trophy'] = {
        label = 'Vé đổi xe Trophy',
        discount = 100,
        vehicle = 'tundrat',
        event = true,
    },
    ['kamachoitem'] = {
        label = 'Vé đổi xe Kamacho',
        discount = 100,
        vehicle = 'kamacho',
        event = true,
    },
    ['key_mustang'] = {
        label = 'Vé đổi xe Mustang',
        discount = 100,
        vehicle = 'rmodmustang',
        event = true,
    },
    ['ve_doi_xe_r35'] = {
        label = 'Vé đổi xe R35',
        discount = 100,
        vehicle = 'r35ultra',
        event = true,
    },
    ['ve_doi_xe_rongngao'] = {
        label = 'Vé đổi xe Rồng Ngáo',
        discount = 100,
        vehicle = 'shabudragon',
        event = true,
    },
    ['xe_gang_1'] = {
        label = 'Vé đổi xe Gang 1',
        discount = 100,
        vehicle = 'granger',
        event = true,
    },
    ['xe_gang_2'] = {
        label = 'Vé đổi xe Gang 2',
        discount = 100,
        vehicle = 'granger2',
        event = true,
    },
    ['xe_gang_3'] = {
        label = 'Vé đổi xe Gang 3',
        discount = 100,
        vehicle = 'contender',
        event = true,
    },
    ['key_bmwm5'] = {
        label = 'Vé đổi xe BMW M5',
        discount = 100,
        vehicle = 'm5g60',
        event = true,
    },
    ['key_amggt'] = {
        label = 'Vé đổi xe AMG GT',
        discount = 100,
        vehicle = 'ikx3gtblack',
        event = true,
    },
    ['key_omnisegt'] = {
        label = 'Vé đổi xe OMNIS E-GT',
        discount = 100,
        vehicle = 'omnisegt',
        event = true,
    },
}

-- =========================================================================
-- CẤU HÌNH CÁC ĐẠI LÝ XE (MULTI-DEALER SYSTEM)
-- Mỗi dealer có cấu hình Job, Vị trí, Showroom, Stash, Ngân hàng riêng biệt
-- =========================================================================
Config.Dealers = {
    -- [[ 1. ĐẠI LÝ XE PHỔ THÔNG (CARDEALER) ]] --
    ['cardealer'] = {
        label = "Showroom Xe Phổ Thông",
        job = "cardealer",
        bankAccount = "cardealer", -- Tài khoản ngân hàng công ty (Renewed-Banking)
        taxAccount = "bcso",       -- Tài khoản nhận thuế 90% (nếu bán xe thường)
        
        -- Webhook Discord riêng cho đại lý
        webhook = {
            datXe = '',
            banXe = 'https://discord.com/api/webhooks/1515754248573554773/UGvFVR6qb2-GgNbFHaJu-zmQZrAwmeG5-BD1zEnpCN3K9t7-cgq1l7Us1yZjjv1Vb3Ev',
        },
        
        -- Blip bản đồ
        blip = {
            enabled = false,
            coords = vector3(-791.6490, -223.1951, 37.2414),
            sprite = 225,
            color = 0,
            scale = 0.7,
            name = "[DOANH NGHIỆP] Car Dealer"
        },
        
        -- Các điểm tương tác
        locations = {
            duty = vector3(-810.0717, -210.4093, 44.1311),          -- On/Off duty & Quản lý nhân viên
            spawn = vector4(-800.9794, -198.7550, 37.1359, 299.62), -- Điểm giao xe khi khách mua
            testSpawn = vector4(516.8058, -268.6154, 46.5450, 144.04), -- Điểm spawn xe lái thử
            testBack = vector4(-791.6490, -223.1951, 37.2414, 0.0),    -- Điểm teleport người chơi về sau khi lái thử
            stockIn = vector3(381.59, -336.74, 48.24),              -- Điểm [E] nhập xe kéo vào kho
            removeFlatbed = vector3(395.7222, -357.720, 46.814),    -- Điểm [E] trả xe kéo flatbed
            stash = vector3(363.3533, -317.269, 48.238),           -- Kho đồ ox_inventory
        },
        
        -- Vùng Polyzone cho phép xóa xe showroom / xe rác
        zoneFarm = {
            points = {
                vec3(-818.6317, -200.5865, 37.5050),
                vec3(-787.9325, -249.4312, 37.0278),
                vec3(-761.1864, -239.1277, 37.2458),
                vec3(-791.3221, -185.2732, 37.2836),
            },
            thickness = 30.0,
        },
        
        -- Danh sách các vị trí trưng bày xe Showroom
        showroomLocations = {
            [1] = vector4(-794.3557, -208.6683, 37.0493, 106.2690),
            [2] = vector4(-791.6940, -212.9669, 37.0117, 102.7136),
            [3] = vector4(-800.5888, -217.6668, 36.9708, 133.9940),
            [4] = vector4(-802.7023, -213.3453, 37.0082, 135.2634),
            [5] = vector4(-791.4682, -228.2090, 36.7739, 208.0249),
            [6] = vector4(-771.5214, -238.5119, 43.4426, 49.4681),
            [7] = vector4(-779.7319, -242.6396, 43.4067, 48.1391),
            [8] = vector4(-795.0696, -232.6956, 43.2675, 329.5564),
            [9] = vector4(-797.6091, -227.4289, 43.3125, 287.0129),
            [10] = vector4(-800.5843, -221.9332, 43.3594, 284.3891),
        },
        
        -- Điểm mở UI xem xe dành cho khách (Public UI)
        publicViewPoints = {
            {
                type = "prop",
                model = "energy_c_pedestal",
                label = "Xem Xe"
            }
            -- {
            --     type = "coords",
            --     coords = vector3(-791.6490, -223.1951, 37.2414),
            --     radius = 1.5,
            --     label = "Xem Danh Sách Xe Phổ Thông"
            -- }
        }
    },

    -- [[ 2. ĐẠI LÝ SIÊU XE (LUXURY CAR DEALER) ]] --
    ['luxurycar'] = {
        label = "Showroom Siêu Xe Luxury Car",
        job = "luxurycar",
        bankAccount = "luxurycar",
        taxAccount = "bcso",
        
        -- Webhook Discord riêng cho đại lý
        webhook = {
            datXe = '',
            banXe = '',
        },
        
        blip = {
            enabled = false,
            coords = vector3(715.6982, -942.3056, 25.0511),
            sprite = 523,
            color = 5,
            scale = 0.7,
            name = "[DOANH NGHIỆP] Luxury Car Dealer"
        },
        
        locations = {
            duty = vector3(715.6982, -942.3056, 25.0511),
            spawn = vector4(694.6907, -959.4307, 23.9571, 180.9140),
            testSpawn = vector4(694.6907, -959.4307, 23.9571, 180.9140),
            testBack = vector4(694.2039, -943.0125, 24.7249, 171.1324),
            stockIn = vector3(694.6907, -959.4307, 23.9571),
            removeFlatbed = vector3(694.6907, -959.4307, 23.9571),
            stash = vector3(715.6982, -942.3056, 25.0511),
        },
        
        zoneFarm = {
            points = {
                vec3(751.9983, -985.2539, 25.0),
                vec3(686.4094, -986.2260, 25.0),
                vec3(686.1100, -934.5261, 25.0),
                vec3(761.4136, -937.0105, 25.0),
            },
            thickness = 30.0,
        },
        
        showroomLocations = {
            [1] = vector4(743.1706, -967.2830, 24.7623, 224.1086),
            [2] = vector4(715.6747, -952.9583, 24.3690, 175.7641),
            [3] = vector4(694.6077, -948.9628, 24.1455, 180.6425),
            [4] = vector4(731.3896, -960.0886, 23.9338, 269.7974),
            [5] = vector4(731.1422, -963.2596, 23.9338, 268.6146),
            [6] = vector4(731.3435, -966.4626, 23.9342, 269.1716),
            [7] = vector4(731.2497, -969.6913, 23.9337, 269.4595),
            [8] = vector4(731.4160, -973.0486, 23.9341, 270.2784),
        },
        
        publicViewPoints = {
            -- {
            --     type = "prop",
            --     model = "energy_c_pedestal",
            --     label = "Xem Xe"
            -- }
        }
    }
}

-- [[ HELPER FUNCTIONS ]] --
function GetDealerByJob(jobName)
    if not jobName then return nil, nil end
    for dealerId, dealerCfg in pairs(Config.Dealers) do
        if dealerCfg.job == jobName then
            return dealerId, dealerCfg
        end
    end
    return nil, nil
end

function GetDealerById(dealerId)
    if not dealerId then return nil end
    return Config.Dealers[dealerId]
end

function GetDealerAtCoords(coords, maxDist)
    local maxDistance = maxDist or 60.0
    local closestDealerId = nil
    local closestDist = maxDistance

    for dealerId, dealerCfg in pairs(Config.Dealers) do
        if dealerCfg.locations and dealerCfg.locations.duty then
            local dist = #(coords - dealerCfg.locations.duty)
            if dist < closestDist then
                closestDist = dist
                closestDealerId = dealerId
            end
        end
    end
    return closestDealerId, closestDealerId and Config.Dealers[closestDealerId] or nil
end
