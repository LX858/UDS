local function LoadModel(model)
    if not IsModelValid(model) then
        print(("Invalid model: %s"):format(model))
        return false
    end
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    return true
end

local function CreateAndAttachProp(propData, ped)
    if not propData.model then return nil end
    
    if not LoadModel(propData.model) then
        return nil
    end
    
    local prop = CreateObject(
        propData.model, 
        0.0, 0.0, 0.0,  -- Position will be set by AttachEntityToEntity
        true, true, false
    )
    
    local boneIndex = GetPedBoneIndex(ped, propData.bone or 18905)
    local pos = propData.pos or vector3(0.12, 0.028, 0.001)
    local rot = propData.rot or vector3(10.0, 175.0, 0.0)
    
    AttachEntityToEntity(
        prop, ped, boneIndex,
        pos.x or pos[1], pos.y or pos[2], pos.z or pos[3],
        rot.x or rot[1], rot.y or rot[2], rot.z or rot[3],
        true, true, false, true, 1, true
    )
    
    SetModelAsNoLongerNeeded(propData.model)
    return prop
end

local function CleanupProps(props)
    for _, prop in ipairs(props) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    return {}
end

-- Event to receive notification from server
RegisterNetEvent("xn_eat:notify", function(message, type)
    Config.Notify(message, type)
end)

RegisterNetEvent("xn_eat:onEat", function(foodItem)
    local config = Config.Food[foodItem] or Config.Drinks[foodItem]
    if not config then
        print(("Invalid food/drink item: %s"):format(foodItem))
        return
    end

    local ped = PlayerPedId()
    local props = {}
    local propData = config.prop or {}
    local animData = config.anim or {}
    
    -- Handle multiple props if provided as an array
    if propData[1] then
        for _, prop in ipairs(propData) do
            local newProp = CreateAndAttachProp(prop, ped)
            if newProp then
                table.insert(props, newProp)
            end
        end
    else
        -- Single prop
        local prop = CreateAndAttachProp(propData, ped)
        if prop then
            table.insert(props, prop)
        end
    end

    -- Show progress bar with animation
    local label
    if config.effect == "thirst" then
        label = ("Drinking %s..."):format(config.name or foodItem)
    elseif config.effect == "stress" then
        label = ("Đang hút %s..."):format(config.name or foodItem)
    else
        label = ("Eating %s..."):format(config.name or foodItem)
    end
    lib.progressBar({
        duration = 7000,
        label = label,
        useWhileDead = false,
        canCancel = false,
        anim = {
            dict = animData.dict,
            clip = animData.clip
        },
        -- If no props were created, use the direct prop configuration
        prop = #props == 0 and propData.model and {
            model = propData.model,
            bone = propData.bone or 18905,
            pos = propData.pos or vector3(0.12, 0.028, 0.001),
            rot = propData.rot or vector3(10.0, 175.0, 0.0)
        } or nil
    })

    -- Apply stat effect after animation finishes
    TriggerServerEvent("xn_eat:applyEffect", foodItem)

    -- Notify after consuming
    if config.effect == "thirst" then
        Config.Notify("Đã quá đi thôi !", "success")
    elseif config.effect == "stress" then
        Config.Notify("Phê ghê, stress giảm rồi !", "success")
    else
        Config.Notify("Ngon quá chèn ơi !", "success")
    end

    -- Clean up props
    CleanupProps(props)
end)