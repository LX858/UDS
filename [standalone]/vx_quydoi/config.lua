Config = {}

Config.Dependencies = {} -- Reqired resources loaded to start
Config.Locale = 'vi'

Config.Settings = {
  locale = Locales[Config.Locale] or Locales['default']
}

Config.Debug = true
Config.Nui = true
Config.Dev = false
---@type "qbx" | "qb" | "esx" | "ProjectStarboy" | "standalone"
Config.Framework = "qbx"
Config.ClientLazyLoad = false

Config.Command = "trader"
Config.ExchangeCooldown = 1500
Config.MaxExchangeQuantity = 999

-- Keep outfit images and metadata compatible with XNClothes.
Config.XNClothes = {
  ImageUrl = "https://raw.githubusercontent.com/xuannguyen995/miniclothing/refs/heads/main",
  ImageExtension = "webp",
}
Config.TraderNpc = {
  enabled = true,
  model = "a_m_m_business_01",
  coords = vector4(201.1613, -966.8997, 31.5085, 63.9683),
  target = {
    icon = "fa-solid fa-gift",
    label = "Mở quầy quy đổi",
    distance = 2.5,
  },
}
-- The server is authoritative for every recipe. The NUI only receives the
-- display data and sends an entry id plus quantity when the player confirms.
Config.Trades = {
  chests = {
    {
      id = "mid-autumn-box1",
      name = "Hòm Trung Thu IG",
      image = "hom_trung_thu_ig",
      reward = { item = "hom_trung_thu_ig", amount = 1 },
      costs = {
        { item = "the_du_du", amount = 20 },
      },
    },
    {
      id = "mid-autumn-box2",
      name = "Hòm Trung Thu IG",
      image = "hom_trung_thu_ig",
      reward = { item = "hom_trung_thu_ig", amount = 1 },
      costs = {
        { item = "the_pvp", amount = 10 },
      },
    },
    {
      id = "mid-autumn-box3",
      name = "Hòm Trung Thu IG",
      image = "hom_trung_thu_ig",
      reward = { item = "hom_trung_thu_ig", amount = 1 },
      costs = {
        { item = "the_hoa_mn", amount = 20 },
      },
    },
    {
      id = "mid-autumn-box4",
      name = "Hòm Trung Thu IG",
      image = "hom_trung_thu_ig",
      reward = { item = "hom_trung_thu_ig", amount = 1 },
      costs = {
        { item = "the_hai_cam", amount = 15 },
      },
    },
    {
      id = "mid-autumn-box5",
      name = "Hòm Trung Thu IG",
      image = "hom_trung_thu_ig",
      reward = { item = "hom_trung_thu_ig", amount = 1 },
      costs = {
        { item = "the_dao_da", amount = 10 },
      },
    },
    {
      id = "mid-autumn-box6",
      name = "Hòm Trung Thu IG",
      image = "hom_trung_thu_ig",
      reward = { item = "hom_trung_thu_ig", amount = 1 },
      costs = {
        { item = "the_cau_ca", amount = 10 },
      },
    },
    {
      id = "mid-autumn-box7",
      name = "Hòm Trung Thu IG",
      image = "hom_trung_thu_ig",
      reward = { item = "hom_trung_thu_ig", amount = 1 },
      costs = {
        { item = "afk_rare_reward", amount = 3 },
      },
    },
    {
      id = "mid-autumn-box8",
      name = "Hòm Trung Thu IG",
      image = "hom_trung_thu_ig",
      reward = { item = "hom_trung_thu_ig", amount = 1 },
      costs = {
        { item = "banh_trung_thu", amount = 1 },
      },
    },
  },
  items = {
    {
      id = "skin-babytree-2026",
      name = "Skin Babytree 2026",
      image = "skin_machete_ba",
      reward = { item = "skin_machete_ba", amount = 1 },
      costs = {
        { item = "the_skin", amount = 99 },
      },
    },
    {
      id = "skin-rich-2026",
      name = "Skin Rich 2026",
      image = "skin_machete_hai",
      reward = { item = "skin_machete_hai", amount = 1 },
      costs = {
        { item = "the_skin", amount = 99 },
      },
    },
    {
      id = "vehicle-r35",
      name = "Vé Đổi Xe R35",
      image = "./assets/vedoixe.png",
      special = true,
      maxQuantity = 1,
      reward = { item = "ve_doi_xe_r35", amount = 1 },
      costs = {
        { item = "the_trung_thu", amount = 499 },
      },
    },
    {
      id = "vehicle-rongngao",
      name = "Vé Đổi Xe Rồng Ngáo",
      image = "./assets/rongngao.png",
      special = true,
      maxQuantity = 1,
      reward = { item = "ve_doi_xe_rongngao", amount = 1 },
      costs = {
        { item = "the_trung_thu", amount = 199 },
      },
    },
  },
  outfits = {
    {
      id = "male-outfit-958",
      name = "Bộ Nam 958",
      image = "", -- Them anh trang phuc tai day
      gender = "male",
      costs = { { item = "the_outfit", amount = 100 } },
      components = {
        { component_id = 11, drawable = 958, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "male-outfit-970",
      name = "Bộ Nam 970",
      image = "", -- Them anh trang phuc tai day
      gender = "male",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 11, drawable = 970, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "male-outfit-976",
      name = "Bộ Nam 976",
      image = "", -- Them anh trang phuc tai day
      gender = "male",
      costs = { { item = "the_outfit", amount = 100 } },
      components = {
        { component_id = 11, drawable = 976, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "male-outfit-986",
      name = "Bộ Nam 986",
      image = "", -- Them anh trang phuc tai day
      gender = "male",
      costs = { { item = "the_outfit", amount = 100 } },
      components = {
        { component_id = 11, drawable = 986, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "male-outfit-1000",
      name = "Bộ Nam 1000",
      image = "", -- Them anh trang phuc tai day
      gender = "male",
      costs = { { item = "the_outfit", amount = 100 } },
      components = {
        { component_id = 11, drawable = 1000, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-1004",
      name = "Bộ Nữ 1004",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 11, drawable = 1004, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-1072",
      name = "Bộ Nữ 1072",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 100 } },
      components = {
        { component_id = 11, drawable = 1072, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-1073",
      name = "Bộ Nữ 1073",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 70 } },
      components = {
        { component_id = 11, drawable = 1073, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-1082",
      name = "Bộ Nữ 1082",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 100 } },
      components = {
        { component_id = 11, drawable = 1082, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-762",
      name = "Bộ Nữ 762",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 11, drawable = 762, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-668",
      name = "Bộ Nữ 668",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 11, drawable = 668, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-663",
      name = "Bộ Nữ 663",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 30 } },
      components = {
        { component_id = 11, drawable = 663, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-963",
      name = "Bộ Nữ 963",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 11, drawable = 963, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-966",
      name = "Bộ Nữ 966",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 70 } },
      components = {
        { component_id = 11, drawable = 966, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-969",
      name = "Bộ Nữ 969",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 100 } },
      components = {
        { component_id = 11, drawable = 969, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-974",
      name = "Bộ Nữ 974",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 100 } },
      components = {
        { component_id = 11, drawable = 974, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-975",
      name = "Bộ Nữ 975",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 11, drawable = 975, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-976",
      name = "Bộ Nữ 976",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 11, drawable = 976, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-983",
      name = "Bộ Nữ 983",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 30 } },
      components = {
        { component_id = 11, drawable = 983, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-996",
      name = "Bộ Nữ 996",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 11, drawable = 996, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-999",
      name = "Bộ Nữ 999",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 11, drawable = 999, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-1034",
      name = "Bộ Nữ 1034",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 11, drawable = 1034, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-1046",
      name = "Bộ Nữ 1046",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 70 } },
      components = {
        { component_id = 11, drawable = 1046, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-1077",
      name = "Bộ Nữ 1077",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 11, drawable = 1077, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-1076",
      name = "Bộ Nữ 1076",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 70 } },
      components = {
        { component_id = 11, drawable = 1076, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-outfit-1038",
      name = "Bộ Nữ 1038",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 100 } },
      components = {
        { component_id = 11, drawable = 1038, texture = 0, name = "torso_1" },
      },
    },
    {
      id = "female-undershirt-494",
      name = "Áo Trong Nữ 494",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 15 } },
      components = {
        { component_id = 8, drawable = 494, texture = 0, name = "shirt_1" },
      },
    },
    {
      id = "female-undershirt-498",
      name = "Áo Trong Nữ 498",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 30 } },
      components = {
        { component_id = 8, drawable = 498, texture = 0, name = "shirt_1" },
      },
    },
    {
      id = "female-undershirt-507",
      name = "Áo Trong Nữ 507",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 40 } },
      components = {
        { component_id = 8, drawable = 507, texture = 0, name = "shirt_1" },
      },
    },
    {
      id = "female-undershirt-519",
      name = "Áo Trong Nữ 519",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 30 } },
      components = {
        { component_id = 8, drawable = 519, texture = 0, name = "shirt_1" },
      },
    },
    {
      id = "female-undershirt-520",
      name = "Áo Trong Nữ 520",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 20 } },
      components = {
        { component_id = 8, drawable = 520, texture = 0, name = "shirt_1" },
      },
    },
    {
      id = "female-undershirt-523",
      name = "Áo Trong Nữ 523",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 8, drawable = 523, texture = 0, name = "shirt_1" },
      },
    },
    {
      id = "female-undershirt-524",
      name = "Áo Trong Nữ 524",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 30 } },
      components = {
        { component_id = 8, drawable = 524, texture = 0, name = "shirt_1" },
      },
    },
    {
      id = "female-undershirt-537",
      name = "Áo Trong Nữ 537",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 8, drawable = 537, texture = 0, name = "shirt_1" },
      },
    },
    {
      id = "female-undershirt-542",
      name = "Áo Trong Nữ 542",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 99 } },
      components = {
        { component_id = 8, drawable = 542, texture = 0, name = "shirt_1" },
      },
    },
    {
      id = "female-undershirt-545",
      name = "Áo Trong Nữ 545",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 99 } },
      components = {
        { component_id = 8, drawable = 545, texture = 0, name = "shirt_1" },
      },
    },
    {
      id = "female-undershirt-549",
      name = "Áo Trong Nữ 549",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 8, drawable = 549, texture = 0, name = "shirt_1" },
      },
    },
    {
      id = "female-undershirt-647",
      name = "Áo Trong Nữ 647",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 100 } },
      components = {
        { component_id = 8, drawable = 647, texture = 0, name = "shirt_1" },
      },
    },
    {
      id = "female-shoes-289",
      name = "Giày Nữ 289",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 30 } },
      components = {
        { component_id = 6, drawable = 289, texture = 0, name = "shoes_1" },
      },
    },
    {
      id = "female-shoes-290",
      name = "Giày Nữ 290",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 100 } },
      components = {
        { component_id = 6, drawable = 290, texture = 0, name = "shoes_1" },
      },
    },
    {
      id = "female-shoes-293",
      name = "Giày Nữ 293",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 15 } },
      components = {
        { component_id = 6, drawable = 293, texture = 0, name = "shoes_1" },
      },
    },
    {
      id = "female-shoes-301",
      name = "Giày Nữ 301",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 30 } },
      components = {
        { component_id = 6, drawable = 301, texture = 0, name = "shoes_1" },
      },
    },
    {
      id = "female-shoes-294",
      name = "Giày Nữ 294",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 15 } },
      components = {
        { component_id = 6, drawable = 294, texture = 0, name = "shoes_1" },
      },
    },
    {
      id = "female-shoes-319",
      name = "Giày Nữ 319",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 20 } },
      components = {
        { component_id = 6, drawable = 319, texture = 0, name = "shoes_1" },
      },
    },
    {
      id = "female-shoes-320",
      name = "Giày Nữ 320",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 40 } },
      components = {
        { component_id = 6, drawable = 320, texture = 0, name = "shoes_1" },
      },
    },
    {
      id = "female-shoes-321",
      name = "Giày Nữ 321",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 40 } },
      components = {
        { component_id = 6, drawable = 321, texture = 0, name = "shoes_1" },
      },
    },
    {
      id = "female-shoes-332",
      name = "Giày Nữ 332",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 100 } },
      components = {
        { component_id = 6, drawable = 332, texture = 0, name = "shoes_1" },
      },
    },
    -- {
    --   id = "female-shoes-340",
    --   name = "Giày Nữ 340",
    --   image = "", -- Them anh trang phuc tai day
    --   gender = "female",
    --   costs = { { item = "the_outfit", amount = 999 } },
    --   components = {
    --     { component_id = 6, drawable = 340, texture = 0, name = "shoes_1" },
    --   },
    -- },
    -- {
    --   id = "female-shoes-341",
    --   name = "Giày Nữ 341",
    --   image = "", -- Them anh trang phuc tai day
    --   gender = "female",
    --   costs = { { item = "the_outfit", amount = 999 } },
    --   components = {
    --     { component_id = 6, drawable = 341, texture = 0, name = "shoes_1" },
    --   },
    -- },
    {
      id = "female-shoes-342",
      name = "Giày Nữ 342",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 10 } },
      components = {
        { component_id = 6, drawable = 342, texture = 0, name = "shoes_1" },
      },
    },
    {
      id = "female-shoes-345",
      name = "Giày Nữ 345",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 20 } },
      components = {
        { component_id = 6, drawable = 345, texture = 0, name = "shoes_1" },
      },
    },
    {
      id = "female-shoes-346",
      name = "Giày Nữ 346",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 6, drawable = 346, texture = 0, name = "shoes_1" },
      },
    },
    {
      id = "female-shoes-347",
      name = "Giày Nữ 347",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 70 } },
      components = {
        { component_id = 6, drawable = 347, texture = 0, name = "shoes_1" },
      },
    },
    {
      id = "female-shoes-362",
      name = "Giày Nữ 362",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 110 } },
      components = {
        { component_id = 6, drawable = 362, texture = 0, name = "shoes_1" },
      },
    },
    {
      id = "female-shoes-364",
      name = "Giày Nữ 364",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 50 } },
      components = {
        { component_id = 6, drawable = 364, texture = 0, name = "shoes_1" },
      },
    },
    {
      id = "female-shoes-367",
      name = "Giày Nữ 367",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 100 } },
      components = {
        { component_id = 6, drawable = 367, texture = 0, name = "shoes_1" },
      },
    },
    {
      id = "male-hat-235",
      name = "Mũ Nam 235",
      image = "", -- Them anh trang phuc tai day
      gender = "male",
      costs = { { item = "the_outfit", amount = 10 } },
      components = {},
      props = {
        { prop_id = 0, drawable = 235, texture = 0, name = "HAT" },
      },
    },
    {
      id = "female-hat-244",
      name = "Mũ Nữ 244",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 10 } },
      components = {},
      props = {
        { prop_id = 0, drawable = 244, texture = 0, name = "HAT" },
      },
    },
    {
      id = "female-hat-224",
      name = "Mũ Nữ 224",
      image = "", -- Them anh trang phuc tai day
      gender = "female",
      costs = { { item = "the_outfit", amount = 10 } },
      components = {},
      props = {
        { prop_id = 0, drawable = 224, texture = 0, name = "HAT" },
      },
    },
  },
}

function L(key, ...)
  if Config.Settings.locale[key] then
    return string.format(Config.Settings.locale[key], ...)
  else
    return key
  end
end
