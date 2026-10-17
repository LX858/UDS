Config = {}

Config.TVModel = "prop_tv_flat_01" 
Config.TVPosition = vector3(70.30, -425.67, 40.14)
Config.TVHeading = 337.96 --270.97

Config.RenderDistance = 300  -- Khoảng cách render
Config.ScreenResolution = { width = 1700, height = 1080 }
Config.DoChuoi = 5.0
Config.Scale = 0.065

Config.RenderURL = string.format('nui://%s/html/index.html', GetCurrentResourceName())
Config.Texture = {
    TXD = 'BAMBIENSO_SCREEN_TXD',
    TXN = 'BAMBIENSO_SCREEN_TXN',
}

Config.RenderScreen = {
    Position = vector3(69.275, -425.32, 41.18),
    Rotation = vector3(0.0, 337.96 + 44.6, 0.0),
}

Config.SettingsNPC = {
    Location = vec4(68.39, -434.1, 39.14, 259.43),
}

Config.Debug = false