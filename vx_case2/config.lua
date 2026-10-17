Config = {}

Config.Dependencies = {} -- Required resources loaded to start
Config.Locale = 'vi'

Config.Settings = {
  locale = Locales[Config.Locale] or Locales['default']
}

Config.Debug = true
Config.Nui = true
Config.Dev = true
---@type "qbx"
Config.Framework = "qbx"
Config.ClientLazyLoad = false

Config.RefreshCost = 5
Config.MilestoneTarget = 3500
Config.MaxPurchaseQuantity = 999
Config.CashAccount = "cash"
Config.ActionLockSeconds = 12

function L(key, ...)
  if Config.Settings.locale[key] then
    return string.format(Config.Settings.locale[key], ...)
  else
    return key
  end
end

Config.PriceItems = {
  { id = 1, name = "skin_babytree_2026", label = "Skin Baby Tree 2026", price = 1500, priceMoney = 1500000 },
  { id = 2, name = "skin_rich_2026", label = "Skin Rich 2026", price = 1500, priceMoney = 1500000 },
  { id = 3, name = "the_outfit", label = "Thẻ Trang Phục", price = 500, priceMoney = 500000 },
  { id = 4, name = "the_skin", label = "Thẻ Skin", price = 650, priceMoney = 650000 },
  { id = 5, name = "the_trung_thu", label = "Thẻ Trung Thu", price = 350 },
  { id = 6, name = "banh_trung_thu", label = "Bánh Trung Thu", price = 99 },
  { id = 7, name = "hom_trung_thu", label = "Hòm Trung Thu", price = 299, priceMoney = 299000 },
  { id = 8, name = "cloth_outfit", label = "Trang Phục", price = 850, priceMoney = 850000 },
}

Config.SpinRewards = {
  { id = 1, label = "-50%", type = "discount", value = 50 },
  { id = 2, label = "29 XU", type = "coins", value = 29 },
  { id = 3, label = "QUA LƯỢT", type = "freeSpin", value = 1 },
  { id = 4, label = "99 XU", type = "coins", value = 99 },
  { id = 5, label = "-10%", type = "discount", value = 10 },
  { id = 6, label = "QUA LƯỢT", type = "freeSpin", value = 1 },
  { id = 7, label = "-80%", type = "discount", value = 80 },
  { id = 8, label = "-30%", type = "discount", value = 30 },
}

Config.RewardItems = {
  { key = "milestone_outfit", name = "the_outfit", label = "Thẻ Trang Phục", amount = 1 },
  { key = "milestone_skin", name = "the_skin", label = "Thẻ Skin", amount = 1 },
  { key = "milestone_midautumn", name = "the_trung_thu", label = "Thẻ Trung Thu", amount = 1 },
}
