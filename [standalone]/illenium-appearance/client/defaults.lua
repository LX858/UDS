local function getComponentConfig()
    return {
        masks = false,
        upperBody = false,
        lowerBody = false,
        bags = false,
        shoes = false,
        scarfAndChains = false,
        bodyArmor = false,
        shirts = false,
        decals = false,
        jackets = false,
    }
end

local function getPropConfig()
    return {
        hats = false,
        glasses = false,
        ear = false,
        watches = false,
        bracelets = false,
    }
end

function GetDefaultConfig()
    return {
        ped = false,
        headBlend = false,
        faceFeatures = false,
        headOverlays = false,
        components = false,
        componentConfig = getComponentConfig(),
        props = false,
        propConfig = getPropConfig(),
        tattoos = false,
        enableExit = true,
        hasTracker = Config.PreventTrackerRemoval and Framework.HasTracker(),
        automaticFade = Config.AutomaticFade
    }
end
