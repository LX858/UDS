---@diagnostic disable: undefined-global
local QBX = exports.qbx_core
local savedClothing = {}
local isWearingUniform = false
local warnedConfigs = {}

-- Fallback for Config.Props if not defined in config.lua
if not Config.Props then
    Config.Props = {
        ['helmet'] = 0,     -- Hats/Helmets
        ['glasses'] = 1,    -- Glasses
        ['ear'] = 2,        -- Ears/Earrings
        ['watch'] = 6,      -- Watches
        ['bracelet'] = 7,   -- Bracelets
    }
end

if Config.Debug then
    print('^2[Auto Clothing]^7 Client script loaded!')
    print('^2[Auto Clothing]^7 Configured jobs:', json.encode(Config.Jobs))
end

-- Hàm kiểm tra xem player có job được config không
local function IsConfiguredJob(jobName)
    for _, job in ipairs(Config.Jobs) do
        if job == jobName then
            return true
        end
    end
    return false
end

-- Hàm kiểm tra xem decal drawable có thuộc uniform nào trong Config không
local function IsUniformDecal(drawable)
    if not drawable or drawable <= 0 then return false end
    if not Config.Uniforms then return false end
    for _, genders in pairs(Config.Uniforms) do
        if type(genders) == 'table' then
            for _, ranks in pairs(genders) do
                if type(ranks) == 'table' then
                    for _, data in pairs(ranks) do
                        if type(data) == 'table' and data.clothing and data.clothing.decals then
                            if data.clothing.decals.drawable == drawable then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Hàm kiểm tra xem player đang mặc đồ trong whitelist police hay không
local function HasWhitelistedPoliceClothing()
    local PlayerData = QBX:GetPlayerData()
    if not PlayerData or not PlayerData.job or PlayerData.job.name ~= 'police' then
        return false
    end

    local whitelist = Config.PoliceClothingWhitelist
    if not whitelist then
        return false
    end

    local ped = PlayerPedId()
    for component, entries in pairs(whitelist) do
        local componentId = Config.Components[component]
        if componentId and type(entries) == 'table' then
            local currentDrawable = GetPedDrawableVariation(ped, componentId)
            local currentTexture = GetPedTextureVariation(ped, componentId)

            for _, entry in ipairs(entries) do
                if type(entry) == 'number' then
                    if currentDrawable == entry then
                        return true
                    end
                elseif type(entry) == 'table' then
                    local targetDrawable = entry.drawable
                    local targetTexture = entry.texture

                    if targetDrawable ~= nil and currentDrawable == targetDrawable then
                        if targetTexture == nil or currentTexture == targetTexture then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

-- Hàm kiểm tra và dọn dẹp uniform decal nếu người chơi không on duty
local function CheckAndCleanUniformDecals()
    if LocalPlayer.state.vxAirdropActive then return end
    local PlayerData = QBX:GetPlayerData()
    local isOnDuty = false
    if PlayerData and PlayerData.job and IsConfiguredJob(PlayerData.job.name) and PlayerData.job.onduty then
        isOnDuty = true
    end

    if not isOnDuty then
        local ped = PlayerPedId()
        local currentDecal = GetPedDrawableVariation(ped, 10)
        if currentDecal > 0 and IsUniformDecal(currentDecal) then
            if Config.Debug then
                print('^3[Auto Clothing]^7 Detected uniform decal on off-duty player, resetting to 0!')
            end
            SetPedComponentVariation(ped, 10, 0, 0, 0)
            
            -- Lưu lại ngoại hình mới
            if exports['illenium-appearance'] then
                local appearance = exports['illenium-appearance']:getPedAppearance(ped)
                TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
            end
        end
    end
end


-- Hàm kiểm tra và áp dụng uniform khi player load
local function CheckAndApplyUniformOnLoad()
    Wait(2000) -- Đợi 2s để đảm bảo player data đã load đầy đủ
    local PlayerData = QBX:GetPlayerData()
    
    if Config.Debug then
        print('^2[Auto Clothing]^7 ===== Player Load Check =====')
        print('^2[Auto Clothing]^7 Job Name:', PlayerData.job and PlayerData.job.name or 'none')
        print('^2[Auto Clothing]^7 Job Grade:', PlayerData.job and PlayerData.job.grade.level or 'none')
        print('^2[Auto Clothing]^7 On Duty:', PlayerData.job and PlayerData.job.onduty or false)
        print('^2[Auto Clothing]^7 Is Configured Job:', PlayerData.job and IsConfiguredJob(PlayerData.job.name) or false)
    end
    
    if PlayerData.job and IsConfiguredJob(PlayerData.job.name) then
        if PlayerData.job.onduty then
            if Config.Debug then
                print('^2[Auto Clothing]^7 Player is on duty, applying uniform')
            end
            -- Reset state để đảm bảo uniform được áp dụng
            isWearingUniform = false
            savedClothing = {}
            WearUniform(false)
        else
            if Config.Debug then
                print('^2[Auto Clothing]^7 Player is off duty, no uniform needed')
            end
            -- Dọn dẹp decal nếu lỡ bị dính từ phiên trước
            CreateThread(function()
                Wait(2500) -- Đợi XNClothes load xong
                CheckAndCleanUniformDecals()
            end)
        end
    else
        if Config.Debug then
            print('^3[Auto Clothing]^7 Player job not configured for auto clothing')
        end
        -- Dọn dẹp decal nếu lỡ bị dính từ phiên trước
        CreateThread(function()
            Wait(2500) -- Đợi XNClothes load xong
            CheckAndCleanUniformDecals()
        end)
    end
end

-- Lấy dữ liệu player khi vào server
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    if Config.Debug then
        print('^2[Auto Clothing]^7 QBCore:Client:OnPlayerLoaded event triggered')
    end
    CheckAndApplyUniformOnLoad()
end)

-- Thêm event cho QBX Core
RegisterNetEvent('qbx_core:client:onPlayerLoaded', function()
    if Config.Debug then
        print('^2[Auto Clothing]^7 qbx_core:client:onPlayerLoaded event triggered')
    end
    CheckAndApplyUniformOnLoad()
end)

AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    savedClothing = {}
    isWearingUniform = false
end)

-- Event khi job của người chơi thay đổi (QBCore)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    Wait(500)
    if not IsConfiguredJob(JobInfo.name) or not JobInfo.onduty then
        if isWearingUniform then
            RestoreSavedClothing()
        else
            CheckAndCleanUniformDecals()
        end
    end
end)

-- Event khi job của người chơi thay đổi (QBX Core)
RegisterNetEvent('qbx_core:client:onJobUpdate', function(job)
    Wait(500)
    if not IsConfiguredJob(job.name) or not job.onduty then
        if isWearingUniform then
            RestoreSavedClothing()
        else
            CheckAndCleanUniformDecals()
        end
    end
end)

-- Hàm lưu quần áo hiện tại
local function SaveCurrentClothing()
    local ped = PlayerPedId()
    savedClothing = {
        ['helmet'] = {drawable = GetPedDrawableVariation(ped, 0), texture = GetPedTextureVariation(ped, 0)},
        ['mask'] = {drawable = GetPedDrawableVariation(ped, 1), texture = GetPedTextureVariation(ped, 1)},
        ['hair'] = {drawable = GetPedDrawableVariation(ped, 2), texture = GetPedTextureVariation(ped, 2)},
        ['torso'] = {drawable = GetPedDrawableVariation(ped, 3), texture = GetPedTextureVariation(ped, 3)},
        ['pants'] = {drawable = GetPedDrawableVariation(ped, 4), texture = GetPedTextureVariation(ped, 4)},
        ['bag'] = {drawable = GetPedDrawableVariation(ped, 5), texture = GetPedTextureVariation(ped, 5)},
        ['shoes'] = {drawable = GetPedDrawableVariation(ped, 6), texture = GetPedTextureVariation(ped, 6)},
        ['accessory'] = {drawable = GetPedDrawableVariation(ped, 7), texture = GetPedTextureVariation(ped, 7)},
        ['tshirt'] = {drawable = GetPedDrawableVariation(ped, 8), texture = GetPedTextureVariation(ped, 8)},
        ['bproof'] = {drawable = GetPedDrawableVariation(ped, 9), texture = GetPedTextureVariation(ped, 9)},
        ['decals'] = {drawable = GetPedDrawableVariation(ped, 10), texture = GetPedTextureVariation(ped, 10)},
        ['tops'] = {drawable = GetPedDrawableVariation(ped, 11), texture = GetPedTextureVariation(ped, 11)}
    }
end

-- Hàm khôi phục quần áo đã lưu
local function RestoreSavedClothing()
    if LocalPlayer.state.vxAirdropActive then return end
    if Config.Debug then
        print('^2[Auto Clothing]^7 Restoring original clothing via clothes:reloadPlayerClothes')
    end
    
    -- Gọi event để load lại quần áo gốc của người chơi
    TriggerServerEvent('clothes:reloadPlayerClothes')
    
    -- Khôi phục decal về giá trị gốc trước khi mặc đồng phục (hoặc mặc định về 0)
    local ped = PlayerPedId()
    local defaultDecalDrawable = 0
    local defaultDecalTexture = 0
    if savedClothing['decals'] then
        defaultDecalDrawable = savedClothing['decals'].drawable or 0
        defaultDecalTexture = savedClothing['decals'].texture or 0
    end
    
    -- Áp dụng decal ngay lập tức trên client
    SetPedComponentVariation(ped, 10, defaultDecalDrawable, defaultDecalTexture, 0)
    
    -- Tạo một luồng để áp dụng lại sau khi XNClothes chạy xong và lưu ngoại hình mới vào DB
    CreateThread(function()
        Wait(500)
        local currentPed = PlayerPedId()
        SetPedComponentVariation(currentPed, 10, defaultDecalDrawable, defaultDecalTexture, 0)
        
        if exports['illenium-appearance'] then
            local appearance = exports['illenium-appearance']:getPedAppearance(currentPed)
            TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
        end
    end)
    
    -- Clear saved data
    savedClothing = {}
    isWearingUniform = false
end

-- Hàm lấy uniform phù hợp với grade
local function GetUniformForGrade(jobName, gender, grade)
    if Config.Debug then
        print('^3[Auto Clothing Debug]^7 GetUniformForGrade called')
        print('  Job:', jobName)
        print('  Gender:', gender)
        print('  Grade:', grade)
    end
    
    local jobUniforms = Config.Uniforms[jobName]
    if not jobUniforms then 
        if Config.Debug then
            print('^1[Auto Clothing]^7 No uniform config for job:', jobName)
        end
        return nil, nil 
    end
    
    local genderUniforms = jobUniforms[gender]
    if not genderUniforms then 
        if Config.Debug then
            print('^1[Auto Clothing]^7 No uniform config for gender:', gender, 'in job:', jobName)
        end
        return nil, nil 
    end
    
    for rankName, uniformData in pairs(genderUniforms) do
        if Config.Debug then
            print('  Checking rank:', rankName, 'with grades:', json.encode(uniformData.grades))
        end
        for _, gradeNum in ipairs(uniformData.grades) do
            if gradeNum == grade then
                if Config.Debug then
                    print('^2[Auto Clothing]^7 Found uniform for grade', grade, 'in rank', rankName)
                end
                return uniformData.clothing, uniformData.props
            end
        end
    end
    
    if Config.Debug then
        print('^1[Auto Clothing]^7 No uniform found for grade:', grade)
    end
    return nil, nil
end

-- Hàm kiểm tra xem có đang mặc đúng uniform không
local function IsWearingCorrectUniform(uniform, props)
    local ped = PlayerPedId()
    
    -- Kiểm tra components
    if uniform then
        for component, data in pairs(uniform) do
            local componentId = Config.Components[component]
            if componentId then
                local currentDrawable = GetPedDrawableVariation(ped, componentId)
                local currentTexture = GetPedTextureVariation(ped, componentId)
                
                -- Bỏ qua nếu là -1
                if data.drawable == -1 then
                    goto continue
                end
                
                -- Kiểm tra xem drawable và texture có hợp lệ không trước khi so sánh
                local numDrawables = GetNumberOfPedDrawableVariations(ped, componentId)
                if data.drawable >= 0 and data.drawable < numDrawables then
                    local numTextures = GetNumberOfPedTextureVariations(ped, componentId, data.drawable)
                    local targetTexture = data.texture
                    if targetTexture >= numTextures then
                        local PlayerData = QBX:GetPlayerData()
                        local jobName = PlayerData.job and PlayerData.job.name or "unknown"
                        local warnKey = string.format("%s_%s_%d_%d", jobName, component, data.drawable, targetTexture)
                        if not warnedConfigs[warnKey] then
                            warnedConfigs[warnKey] = true
                            print(string.format('^1[Auto Clothing Config Error]^7 Job %s: Texture %d for %s (drawable %d) is invalid! Max texture index available is %d. Resetting to 0.', 
                                jobName, targetTexture, component, data.drawable, numTextures - 1))
                        end
                        targetTexture = 0
                    end
                    
                    if currentDrawable ~= data.drawable or currentTexture ~= targetTexture then
                        return false
                    end
                end
                
                ::continue::
            end
        end
    end
    
    -- Kiểm tra props
    if props then
        for propName, data in pairs(props) do
            local propId = Config.Props[propName]
            if propId then
                local currentDrawable = GetPedPropIndex(ped, propId)
                local currentTexture = GetPedPropTextureIndex(ped, propId)
                
                -- Bỏ qua nếu là -1
                if data.drawable == -1 then
                    goto continueProp
                end
                
                local numProps = GetNumberOfPedPropDrawables(ped, propId)
                if data.drawable >= 0 and data.drawable < numProps then
                    local numTextures = GetNumberOfPedPropTextureVariations(ped, propId, data.drawable)
                    local targetTexture = data.texture
                    if targetTexture >= numTextures then
                        targetTexture = 0
                    end
                    
                    if currentDrawable ~= data.drawable or currentTexture ~= targetTexture then
                        return false
                    end
                end
                
                ::continueProp::
            end
        end
    end
    
    return true
end

-- Hàm mặc đồng phục
function WearUniform(showNotification)
    if LocalPlayer.state.vxAirdropActive then return end
    local PlayerData = QBX:GetPlayerData()
    if not PlayerData.job then 
        if Config.Debug then
            print('^1[Auto Clothing]^7 No job data!')
        end
        return 
    end
    
    if not IsConfiguredJob(PlayerData.job.name) then
        if Config.Debug then
            print('^1[Auto Clothing]^7 Job not configured:', PlayerData.job.name)
        end
        return
    end
    
    local ped = PlayerPedId()
    local gender = GetEntityModel(ped) == GetHashKey("mp_m_freemode_01") and "male" or "female"
    local grade = PlayerData.job.grade.level
    
    local uniform, props = GetUniformForGrade(PlayerData.job.name, gender, grade)
    if not uniform then
        if Config.Debug then
            print('^1[Auto Clothing]^7 No uniform found for job:', PlayerData.job.name, 'gender:', gender, 'grade:', grade)
        end
        exports.qbx_core:Notify('Không tìm thấy đồng phục phù hợp với cấp bậc của bạn!', 'error')
        return
    end
    
    if Config.Debug then
        print('^2[Auto Clothing]^7 Uniform found, checking if already wearing...')
    end

    -- Nếu police đang mặc đồ trong whitelist thì giữ nguyên outfit và không auto-apply uniform
    if HasWhitelistedPoliceClothing() then
        if Config.Debug then
            print('^3[Auto Clothing]^7 Police whitelist clothing detected, skipping uniform enforcement')
        end
        isWearingUniform = false
        return
    end
    
    -- Kiểm tra xem đã mặc đúng uniform chưa
    if IsWearingCorrectUniform(uniform, props) then
        if Config.Debug then
            print('^2[Auto Clothing]^7 Already wearing correct uniform, skipping...')
        end
        isWearingUniform = true
        return
    end
    
    if Config.Debug then
        print('^2[Auto Clothing]^7 Applying uniform for grade:', PlayerData.job.grade.level)
    end
    
    -- Lưu quần áo hiện tại trước khi thay đổi
    if not isWearingUniform then
        SaveCurrentClothing()
    end
    
    local changedCount = 0
    
    -- Nếu đồng phục mới không cấu hình decal, ta reset decal về 0
    if not uniform['decals'] then
        local currentDecal = GetPedDrawableVariation(ped, 10)
        if currentDecal ~= 0 then
            SetPedComponentVariation(ped, 10, 0, 0, 0)
            changedCount = changedCount + 1
        end
    end
    
    -- Áp dụng đồng phục (components)
    for component, data in pairs(uniform) do
        local componentId = Config.Components[component]
        if componentId then
            local currentDrawable = GetPedDrawableVariation(ped, componentId)
            local currentTexture = GetPedTextureVariation(ped, componentId)
            
            -- Chỉ set nếu khác với hiện tại
            if data.drawable >= 0 then
                -- Kiểm tra xem drawable có hợp lệ không
                local numDrawables = GetNumberOfPedDrawableVariations(ped, componentId)
                if data.drawable < numDrawables then
                    local numTextures = GetNumberOfPedTextureVariations(ped, componentId, data.drawable)
                    local targetTexture = data.texture
                    if targetTexture >= numTextures then
                        local warnKey = string.format("%s_%s_%d_%d", PlayerData.job.name, component, data.drawable, targetTexture)
                        if not warnedConfigs[warnKey] then
                            warnedConfigs[warnKey] = true
                            print(string.format('^1[Auto Clothing Config Error]^7 Job %s: Texture %d for %s (drawable %d) is invalid! Max texture index available is %d. Resetting to 0.', 
                                PlayerData.job.name, targetTexture, component, data.drawable, numTextures - 1))
                        end
                        targetTexture = 0
                    end
                    
                    if currentDrawable ~= data.drawable or currentTexture ~= targetTexture then
                        SetPedComponentVariation(ped, componentId, data.drawable, targetTexture, 0)
                        changedCount = changedCount + 1
                        if Config.Debug then
                            print(string.format('[Auto Clothing] Set %s (ID:%d) to drawable:%d texture:%d', 
                                component, componentId, data.drawable, targetTexture))
                        end
                    end
                else
                    if Config.Debug then
                        print(string.format('^3[Auto Clothing Warning]^7 Invalid drawable for %s: %d (max: %d)', 
                            component, data.drawable, numDrawables - 1))
                    end
                end
            elseif data.drawable == -1 then
                -- -1 có nghĩa là bỏ component này (chỉ set nếu hiện tại đang khác 0)
                if currentDrawable ~= 0 then
                    SetPedComponentVariation(ped, componentId, 0, 0, 0)
                    changedCount = changedCount + 1
                end
            end
        end
    end
    
    -- Áp dụng props (mũ, hoa tai, kính, etc)
    if props then
        for propName, data in pairs(props) do
            local propId = Config.Props[propName]
            if propId then
                local currentDrawable = GetPedPropIndex(ped, propId)
                local currentTexture = GetPedPropTextureIndex(ped, propId)
                
                -- Chỉ set nếu khác với hiện tại
                if data.drawable >= 0 then
                    -- Kiểm tra xem prop có hợp lệ không
                    local numProps = GetNumberOfPedPropDrawables(ped, propId)
                    if data.drawable < numProps then
                        local numTextures = GetNumberOfPedPropTextureVariations(ped, propId, data.drawable)
                        local targetTexture = data.texture
                        if targetTexture >= numTextures then
                            targetTexture = 0
                        end
                        
                        if currentDrawable ~= data.drawable or currentTexture ~= targetTexture then
                            SetPedPropIndex(ped, propId, data.drawable, targetTexture, true)
                            changedCount = changedCount + 1
                            if Config.Debug then
                                print(string.format('[Auto Clothing] Set prop %s (ID:%d) to drawable:%d texture:%d', 
                                    propName, propId, data.drawable, targetTexture))
                            end
                        end
                    else
                        if Config.Debug then
                            print(string.format('^3[Auto Clothing Warning]^7 Invalid prop drawable for %s: %d (max: %d)', 
                                propName, data.drawable, numProps - 1))
                        end
                    end
                elseif data.drawable == -1 then
                    -- -1 có nghĩa là bỏ prop này (chỉ clear nếu đang có đeo)
                    if currentDrawable ~= -1 then
                        ClearPedProp(ped, propId)
                        changedCount = changedCount + 1
                    end
                end
            end
        end
    end
    
    if changedCount > 0 then
        isWearingUniform = true
        if showNotification then
            exports.qbx_core:Notify('Đã mặc đồng phục!', 'success')
        end
        if Config.Debug then
            print(string.format('^2[Auto Clothing]^7 Changed %d items (components + props)', changedCount))
        end
    end
end

-- Event khi duty state thay đổi
RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    if Config.Debug then
        print('^3[Auto Clothing]^7 QBCore:Client:SetDuty triggered:', duty)
    end
    local PlayerData = QBX:GetPlayerData()
    if not PlayerData.job or not IsConfiguredJob(PlayerData.job.name) then return end
    
    Wait(500)
    if LocalPlayer.state.vxAirdropActive then return end
    
    if duty then
        if Config.Debug then
            print('^2[Auto Clothing]^7 ON DUTY detected')
        end
        WearUniform(true)
    else
        if Config.Debug then
            print('^2[Auto Clothing]^7 OFF DUTY detected')
        end
        RestoreSavedClothing()
        TriggerServerEvent('XNClothes:Server:ForceUnequipBag')
        exports.qbx_core:Notify('Đã thay về quần áo thường!', 'info')
    end
end)

-- Event cho qbx_core
RegisterNetEvent('qbx_core:client:onSetDuty', function(duty)
    if Config.Debug then
        print('^3[Auto Clothing]^7 qbx_core:client:onSetDuty triggered:', duty)
    end
    local PlayerData = QBX:GetPlayerData()
    if not PlayerData.job or not IsConfiguredJob(PlayerData.job.name) then return end
    
    Wait(500)
    if LocalPlayer.state.vxAirdropActive then return end
    
    if duty then
        if Config.Debug then
            print('^2[Auto Clothing]^7 ON DUTY detected (qbx event)')
        end
        WearUniform(true)
    else
        if Config.Debug then
            print('^2[Auto Clothing]^7 OFF DUTY detected (qbx event)')
        end
        RestoreSavedClothing()
        TriggerServerEvent('XNClothes:Server:ForceUnequipBag')
        exports.qbx_core:Notify('Đã thay về quần áo thường!', 'info')
    end
end)

-- Command để thủ công mặc đồng phục (optional)
RegisterCommand('uniform', function()
    local PlayerData = QBX:GetPlayerData()
    if Config.Debug then
        print('^2[Auto Clothing]^7 /uniform command - Job:', PlayerData.job and PlayerData.job.name or 'none')
    end
    
    if not PlayerData.job or not IsConfiguredJob(PlayerData.job.name) then
        exports.qbx_core:Notify('Bạn không có job được cấu hình đồng phục!', 'error')
        return
    end
    
    if not PlayerData.job.onduty then
        exports.qbx_core:Notify('Bạn phải on duty trước!', 'error')
        return
    end
    
    WearUniform(true)
end, false)

-- Command để khôi phục quần áo (optional)
RegisterCommand('civilian', function()
    local PlayerData = QBX:GetPlayerData()
    if not PlayerData.job or not IsConfiguredJob(PlayerData.job.name) then return end
    
    if PlayerData.job.onduty then
        exports.qbx_core:Notify('Bạn phải off duty trước!', 'error')
        return
    end
    
    RestoreSavedClothing()
end, false)

-- Kiểm tra khi resource start
CreateThread(function()
    Wait(3000)
    if Config.Debug then
        print('^2[Auto Clothing]^7 Starting duty check...')
    end
    local PlayerData = QBX:GetPlayerData()
    if PlayerData and PlayerData.job then
        if Config.Debug then
            print('^2[Auto Clothing]^7 Job:', PlayerData.job.name, 'OnDuty:', PlayerData.job.onduty)
        end
        if IsConfiguredJob(PlayerData.job.name) and PlayerData.job.onduty then
            if Config.Debug then
                print('^2[Auto Clothing]^7 Applying initial uniform')
            end
            WearUniform(false)
        end
    else
        if Config.Debug then
            print('^1[Auto Clothing]^7 No player data on start!')
        end
    end
end)

-- Kiểm tra duty status định kỳ
local lastDutyState = nil

CreateThread(function()
    Wait(5000) -- Đợi 5s trước khi bắt đầu loop
    if Config.Debug then
        print('^2[Auto Clothing]^7 Starting duty monitor loop...')
    end
    
    while true do
        Wait(3000) -- Tăng lên 3s để giảm stress
        if not LocalPlayer.state.vxAirdropActive then
        local PlayerData = QBX:GetPlayerData()
        if PlayerData and PlayerData.job then
            if IsConfiguredJob(PlayerData.job.name) then
                local currentDutyState = PlayerData.job.onduty
                
                if currentDutyState ~= lastDutyState and lastDutyState ~= nil then
                    if Config.Debug then
                        print('^3[Auto Clothing]^7 Duty changed:', lastDutyState, '->', currentDutyState)
                    end
                    lastDutyState = currentDutyState
                    
                    if currentDutyState then
                        if Config.Debug then
                            print('^2[Auto Clothing]^7 ON DUTY - Checking uniform')
                        end
                        WearUniform(true)
                    else
                        if Config.Debug then
                            print('^2[Auto Clothing]^7 OFF DUTY - Restoring clothes')
                        end
                        RestoreSavedClothing()
                        TriggerServerEvent('XNClothes:Server:ForceUnequipBag')
                        exports.qbx_core:Notify('Đã thay về quần áo thường!', 'info')
                    end
                elseif lastDutyState == nil then
                    lastDutyState = currentDutyState
                    if Config.Debug then
                        print('^2[Auto Clothing]^7 Initial duty state:', currentDutyState)
                    end
                    if currentDutyState then
                        WearUniform(false)
                    end
                elseif currentDutyState and isWearingUniform then
                    -- Kiểm tra xem có đang mặc đúng uniform không (mỗi 3s)
                    if Config.EnforceUniform ~= false then
                        local ped = PlayerPedId()
                        local gender = GetEntityModel(ped) == GetHashKey("mp_m_freemode_01") and "male" or "female"
                        local grade = PlayerData.job.grade.level
                        local uniform, props = GetUniformForGrade(PlayerData.job.name, gender, grade)
                        
                        if HasWhitelistedPoliceClothing() then
                            if Config.Debug then
                                print('^3[Auto Clothing]^7 Police whitelist clothing detected, skipping uniform reapply')
                            end
                            isWearingUniform = false
                        elseif uniform and not IsWearingCorrectUniform(uniform, props) then
                            if Config.Debug then
                                print('^3[Auto Clothing]^7 Detected uniform change, reapplying...')
                            end
                            WearUniform(false)
                        end
                    end
                end
            end
        end
        end
    end
end)

-- Debug command
RegisterCommand('checkduty', function()
    local PlayerData = QBX:GetPlayerData()
    if PlayerData and PlayerData.job then
        print('^2=== Auto Clothing Debug ===^7')
        print('Job:', PlayerData.job.name)
        print('On Duty:', PlayerData.job.onduty)
        print('Grade:', PlayerData.job.grade.level)
        print('Last State:', lastDutyState)
        print('Is Wearing Uniform:', isWearingUniform)
        print('^2========================^7')
    else
        print('^1No job data^7')
    end
end, false)

RegisterNetEvent("reload:skin",function()
    Wait(500)
    if LocalPlayer.state.vxAirdropActive then return end
    TriggerServerEvent('clothes:reloadPlayerClothes')
end)

-- Debug test command
RegisterCommand('testwear', function()
    local PlayerData = QBX:GetPlayerData()
    if not PlayerData or not PlayerData.job then
        print('No player data found!')
        return
    end
    
    local ped = PlayerPedId()
    local gender = GetEntityModel(ped) == GetHashKey("mp_m_freemode_01") and "male" or "female"
    local grade = PlayerData.job.grade.level
    
    print('Testing WearUniform for job: ' .. tostring(PlayerData.job.name) .. ' | Gender: ' .. gender .. ' | Grade: ' .. tostring(grade))
    
    local uniform, props = GetUniformForGrade(PlayerData.job.name, gender, grade)
    if not uniform then
        print('No uniform configuration found for this grade/gender!')
        return
    end
    
    print('Uniform config for this grade: ' .. json.encode(uniform))
    
    local componentId = 8 -- tshirt
    local currentDrawable = GetPedDrawableVariation(ped, componentId)
    local currentTexture = GetPedTextureVariation(ped, componentId)
    local numDrawables = GetNumberOfPedDrawableVariations(ped, componentId)
    
    print(string.format('T-Shirt Component 8: Current Drawable: %d, Current Texture: %d', currentDrawable, currentTexture))
    print(string.format('Max Drawables Available: %d', numDrawables))
    
    if uniform['tshirt'] then
        local targetDrawable = uniform['tshirt'].drawable
        local targetTexture = uniform['tshirt'].texture
        local numTextures = GetNumberOfPedTextureVariations(ped, componentId, targetDrawable)
        
        print(string.format('Config Target: Drawable: %d, Texture: %d', targetDrawable, targetTexture))
        print(string.format('Available Texture Variations for drawable %d: %d (indices 0 to %d)', targetDrawable, numTextures, numTextures - 1))
        
        -- Let's apply it directly and see what happens
        SetPedComponentVariation(ped, componentId, targetDrawable, targetTexture, 0)
        
        local appliedDrawable = GetPedDrawableVariation(ped, componentId)
        local appliedTexture = GetPedTextureVariation(ped, componentId)
        print(string.format('After native application -> Applied Drawable: %d, Applied Texture: %d', appliedDrawable, appliedTexture))
    else
        print('No tshirt component defined in this job uniform configuration!')
    end
end, false)
