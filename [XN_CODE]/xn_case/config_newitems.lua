Config = Config or {}

-- =========================================================================================
--                                 CẤU HÌNH ĐỒ MỚI (NEW)
-- =========================================================================================
-- File cấu hình này dùng để gắn nhãn "NEW" bo góc cho các vật phẩm, trang phục trong mục
-- "CÓ THỂ NHẬN ĐƯỢC" ở tất cả các giao diện (Mở Thính, Mở Hòm, Thẻ Bài, Mở Túi...).
--
-- Hướng dẫn:
-- 1. clothing: Khai báo theo tên loại đồ (cloth_torso, cloth_pants, cloth_shoes, cloth_tshirt, cloth_mask, ...)
--    - Chia theo giới tính: female (Nữ) và male (Nam)
--    - Cách 1: Khai báo theo khoảng drawable: { min = 963, max = 1170 }
--    - Cách 2: Khai báo theo số ID drawable lẻ: 965, 968, 1002
--
-- 2. items: Khai báo danh sách tên vật phẩm thường (ox_inventory / xe / vé...)
--    - Ví dụ: 'key_mustang', 'vedoixevf9', 'bua_may_man', ...
-- =========================================================================================

Config.NewItems = {
    -- 1. Cấu hình trang phục / phụ kiện (Clothing)
    clothing = {
        -- Áo khoác (Torso)
        cloth_torso = {
            female = {
                { min = 963, max = 1170 }, -- Demo áo khoác nữ có drawable từ 963 đến 1170
                592, 619, 819
            },
            male = {
                { min = 940, max = 1001 },
                595, 600, 701, 548, 575, 783
            }
        },

        -- Quần dài (Pants)
        cloth_pants = {
            female = {
                -- { min = 300, max = 350 },
            },
            male = {
                { min = 318, max = 359 },
            }
        },

        -- Áo thun (T-Shirt)
        cloth_tshirt = {
            female = {
                { min = 467, max = 649 },
            },
            male = {}
        },

        -- Giày dép (Shoes)
        cloth_shoes = {
            female = {
                { min = 244, max = 369 },
            },
            male = {
                { min = 280, max = 342 },
            }
        },

        -- Mặt nạ (Mask)
        cloth_mask = {
            female = {},
            male = {}
        },

        -- Áo chống đạn (Bulletproof)
        cloth_bproof = {
            female = {},
            male = {}
        },

        -- Mũ / Nón (Helmet)
        cloth_helmet = {
            female = {},
            male = {}
        },

        -- Kính (Glasses)
        cloth_glasses = {
            female = {},
            male = {}
        },

        -- Dây chuyền (Chain)
        cloth_chain = {
            female = {},
            male = {}
        },

        -- Balo (Bags)
        cloth_bags = {
            female = {},
            male = {}
        },

        -- Bông tai (Ears)
        cloth_ears = {
            female = {},
            male = {}
        },

        -- Đồng hồ (Watches)
        cloth_watches = {
            female = {},
            male = {}
        },

        -- Vòng tay (Bracelets)
        cloth_bracelets = {
            female = {},
            male = {}
        }
    },

    -- 2. Cấu hình vật phẩm thường (Items / Vehicles / Vouchers / ...)
    items = {
        -- 'key_mustang',
        -- 'vedoixevf9',
        -- 'vdm_ngaunhien',
    }
}
