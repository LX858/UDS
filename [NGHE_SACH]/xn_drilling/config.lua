Config = {}

Config.Platforms = json.decode(LoadResourceFile(GetCurrentResourceName(), "Platforms.json")) -- don't touch this
Config.DefaultQuantity = 1000 -- default quantity for all platforms


Config.Input = "ox-lib" --- ("ox-lib", "qb-input") input script will be used for menus (uncomment line fxmanifest.lua if you using ox-lib)
Config.EyeTarget = "ox_target"  --- you can use ox_target or qb-target

Config.UseEyeTarget = true -- enable or disable eye target for all platforms or disable for draw text

Config.RequireJob = false --- enable this if you want to use job only.
Config.JobName = "mining" --- job name Note: make sure you add job in your server accordingly your framework.

Config.Reward = { --- reward after drilling complete
    ['kerosene'] = {
        item = "dau_tho",
        qty = math.random(1,2),
    },
}

Config.UseBlips = true -- enable or disable blips for all platforms
Config.Blip = {
    Sprite = 648,
    Scale = 0.5,
    Color = 2,
    Label = 'Mining'
}

Config.UseSelling = false -- enable or disable selling
Config.Seller = {
    coords = vector4(1521.5197753906, -2114.2438964844, 76.804397583008, 275.16198730469),
    model = "g_m_m_chiboss_01"
}
Config.SellingPrices = {
    ["dau_tho"] = {label = "Dầu", price = math.random(100,150)},
}


Config.Language = {
    ['no_oil'] = "This drill was exhausted!",
    ['no_oil_1'] = "You don't have oil to sell",
    ['inventory_full'] = "Túi đồ của bạn đã đầy hoặc quá số ký!",
    ['draw_text'] = "[E] - Start Drilling",
    ['eye_target'] = "Start Drilling",
    ['sell_mining'] = "Sell your Petroleums",
    ['select_item'] = "Select Item",
    ['amount'] = "Amount",

}



