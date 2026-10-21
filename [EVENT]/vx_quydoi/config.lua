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

-- Item used to pay for outfits (a group can override it with `costItem`).
Config.OutfitCostItem = "the_outfit_hlw"

-- Outfit types usable as `type` in Config.Trades.outfits (same definitions as XNClothes).
-- component: component/prop id, prop: true if it is a prop, itemname: ox_inventory item,
-- clothesSlotID: inventory slot, label: shown in the trade name and item metadata.
local function calculateSlot(slot)
  return slot
end

Config.OutfitTypes = {
  hat = { component = 0, prop = true, itemname = 'cloth_helmet', clothesSlotID = calculateSlot(6), camera = 'head', label = 'Mũ' },
  decal = { component = 10, prop = false, itemname = 'cloth_decals', clothesSlotID = calculateSlot(16), camera = 'body', label = 'Phụ kiện' },
  mask = { component = 1, prop = false, itemname = 'cloth_mask', clothesSlotID = calculateSlot(7), camera = 'head', label = 'Mặt nạ' },
  glasses = { component = 1, prop = true, itemname = 'cloth_glasses', clothesSlotID = calculateSlot(8), camera = 'head', label = 'Kính' },
  chain = { component = 7, prop = false, itemname = 'cloth_chain', clothesSlotID = calculateSlot(9), camera = 'default', label = 'Dây chuyền' },
  gloves = { component = 3, prop = false, itemname = 'cloth_arms', clothesSlotID = calculateSlot(10), camera = 'default', label = 'Găng tay' },
  torso = { component = 11, prop = false, itemname = 'cloth_torso', clothesSlotID = calculateSlot(11), camera = 'body', label = 'Áo khoác' },
  watch = { component = 6, prop = true, itemname = 'cloth_watches', clothesSlotID = calculateSlot(12), camera = 'head', label = 'Đồng hồ' },
  pants = { component = 4, prop = false, itemname = 'cloth_pants', clothesSlotID = calculateSlot(13), camera = 'pants', label = 'Quần' },
  clothes = { itemname = 'clothes', clothesSlotID = calculateSlot(14), label = 'Trang phục' }, -- full set, not tradable here
  earrings = { component = 2, prop = true, itemname = 'cloth_ears', clothesSlotID = calculateSlot(16), camera = 'head', label = 'Khuyên tai' },
  bag = { component = 5, prop = false, itemname = 'cloth_bags', clothesSlotID = calculateSlot(17), camera = 'default', label = 'Túi xách' },
  shirt = { component = 8, prop = false, itemname = 'cloth_tshirt', clothesSlotID = calculateSlot(18), camera = 'body', label = 'Áo thun' },
  vest = { component = 9, prop = false, itemname = 'cloth_bproof', clothesSlotID = calculateSlot(19), camera = 'default', label = 'Áo chống đạn' },
  bracelets = { component = 7, prop = true, itemname = 'cloth_bracelets', clothesSlotID = calculateSlot(20), camera = 'default', label = 'Vòng tay' },
  shoes = { component = 6, prop = false, itemname = 'cloth_shoes', clothesSlotID = calculateSlot(21), camera = 'bottom', label = 'Giày' },
}

Config.TraderNpc = {
  enabled = true,
  model = "a_m_m_business_01",
  coords = vector4(-1685.3926, -292.0206, 51.8924, 144.4010),
  target = {
    icon = "fa-solid fa-gift",
    label = "Mở quầy quy đổi",
    distance = 2.5,
  },
}
-- The server is authoritative for every recipe. The NUI only receives the
-- display data and sends an entry id plus quantity when the player confirms.
-- Add recipes to chests, items, or outfits in the order they should appear.
-- Every recipe uses the same card in the UI; no position or special flag is needed.
-- Example item recipe (use item names registered in ox_inventory):
-- { id = "example", name = "Vật phẩm mẫu", image = "example_item",
--   reward = { item = "example_item", amount = 1 },
--   costs = { { item = "example_token", amount = 10 } } },
-- image accepts an item name, a local ./assets/... path, or an image URL.
--
-- Outfits are configured in groups: one group = one type (Config.OutfitTypes) + one gender,
-- and `items` is a list of { drawable, price } (optional 3rd value: texture, default 0).
-- Id, name, image and cost are generated automatically, e.g. id "female-shoes-289",
-- name "Giày Nữ 289" (type label + gender + drawable), price paid in Config.OutfitCostItem.
-- Example: { type = "shoes", gender = "female", items = { { 289, 30 }, { 290, 100 } } },
-- Optional per group: costItem = "other_item", image = "<url or item name>",
-- label = "Custom label" (replaces the type label in the name), idPrefix = "custom" (replaces the type in the id).
Config.Trades = {
  chests = {
    {
      id = "mid-autumn-box1",
      name = "Hòm Halloween IG",
      image = "./assets/hom_hlw_ig.webp",
      reward = { item = "hom_hlw_ig", amount = 1 },
      costs = {
        { item = "candy_corn", amount = 100 },
      },
    },
    {
      id = "mid-autumn-box2",
      name = "Hòm Halloween IG",
      image = "./assets/hom_hlw_ig.webp",
      reward = { item = "hom_hlw_ig", amount = 1 },
      costs = {
        { item = "chocolate_bar", amount = 100 },
      },
    },
    {
      id = "mid-autumn-box3",
      name = "Hòm Halloween IG",
      image = "./assets/hom_hlw_ig.webp",
      reward = { item = "hom_hlw_ig", amount = 1 },
      costs = {
        { item = "event_token", amount = 10 },
      },
    },
    {
      id = "mid-autumn-box4",
      name = "Hòm Halloween IG",
      image = "./assets/hom_hlw_ig.webp",
      reward = { item = "hom_hlw_ig", amount = 1 },
      costs = {
        { item = "pumpkin_basket", amount = 1 },
      },
    },
  },
  items = {
    {
      id = "skin-hlw-1",
      name = "Skin Halloween 1",
      image = "./assets/skin_hlw_1.png",
      reward = { item = "skin_machete_nam", amount = 1 },
      costs = {
        { item = "the_skin_hlw", amount = 99 },
      },
    },
    {
      id = "skin-hlw-2",
      name = "Skin Halloween 2",
      image = "./assets/skin_hlw_2.png",
      reward = { item = "skin_machete_sau", amount = 1 },
      costs = {
        { item = "the_skin_hlw", amount = 99 },
      },
    },
    {
      id = "vehicle-hlw1",
      name = "Vé Đổi Xe Kogine HLW",
      image = "./assets/ve_doi_xe_hlw1.png",
      maxQuantity = 1,
      reward = { item = "ve_doi_xe_hlw1", amount = 1 },
      costs = {
        { item = "the_hlw", amount = 499 },
      },
    },
    {
      id = "vehicle-hlw2",
      name = "Vé Đổi Xe Poscher HLW",
      image = "./assets/ve_doi_xe_hlw2.png",
      maxQuantity = 1,
      reward = { item = "ve_doi_xe_hlw2", amount = 1 },
      costs = {
        { item = "the_hlw", amount = 299 },
      },
    },
  },
  outfits = {
    -- NỮ
    {
      type = "torso", label = "Áo khoác", idPrefix = "outfit",
      gender = "female",
      items = {
        { 1187, 100 }, { 1192, 100 }, { 1196, 100 }, { 1194, 100 }, { 1199, 50 },
        { 1201, 100 }, { 1106, 100 }, { 722, 100 }, { 800, 100 }, { 967, 50 },
        { 1166, 100 },
      },
    },
    {
      type = "pants",
      gender = "female",
      items = {
        { 259, 50 }, { 269, 50 }, { 239, 50 }, { 260, 50 }, { 270, 50 }, { 262, 50 },
      },
    },
    {
      type = "mask",
      gender = "female",
      items = {
        { 2, 70 }, { 7, 70 }, { 60, 70 }, { 241, 70 }, { 261, 100 },
      },
    },
    {
      type = "decal",
      gender = "female",
      items = {
        { 328, 100 }, { 329, 70 }, { 330, 70 }, { 331, 70 }, { 356, 70 },
        { 357, 70 }, { 354, 100 }, { 343, 100 },
      },
    },
    {
      type = "glasses",
      gender = "female",
      items = {
        { 83, 70 }, { 84, 70 },
      },
    },
    -- NAM
    {
      type = "torso", label = "Áo khoác", idPrefix = "outfit",
      gender = "male",
      items = {
        { 1057, 100 }, { 1063, 50 }, { 1030, 100 }, { 1021, 100 }, { 1039, 100 },
        { 1073, 50 }, { 989, 50 }, { 976, 100 }, { 1062, 50 }, { 1066, 50 },
      },
    },
    {
      type = "pants",
      gender = "male",
      items = {
        { 352, 70 }, { 372, 50 }, { 373, 50 }, { 338, 70 }, { 292, 50 }, { 350, 70 },
      },
    },
    {
      type = "mask",
      gender = "male",
      items = {
        { 2, 70 }, { 7, 70 }, { 60, 70 }, { 225, 70 }, { 256, 70 },
      },
    },
    {
      type = "decal",
      gender = "male",
      items = {
        { 286, 70 }, { 273, 100 }, { 285, 70 }, { 284, 100 }, { 277, 100 },
      },
    },
    {
      type = "glasses",
      gender = "male",
      items = {
        { 79, 70 }, { 80, 70 },
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
