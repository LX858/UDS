local function DebugPrint(...)
    if Config and Config.EnableDebug then
        print(...)
    end
end

-- =====================================================
-- PED GENDER DETECTION - Xác định giới tính từ ped model
-- Nguồn thực tế nhất: model của ped hiện tại
-- =====================================================
local MALE_FREEMODE_MODEL = joaat('mp_m_freemode_01')
local FEMALE_FREEMODE_MODEL = joaat('mp_f_freemode_01')

local function isFemalePedForClothes(ped)
    ped = ped or PlayerPedId()
    return IsPedModel(ped, FEMALE_FREEMODE_MODEL)
end

local function getPedSexForClothes(ped)
    ped = ped or PlayerPedId()
    return isFemalePedForClothes(ped) and "female" or "male"
end

-- Sync giới tính ped lên server
-- Gọi trước khi mở NUI để server có đúng gender khi roll item
local lastSentGender = nil
local function syncPedGenderToServer(force)
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    local currentGender = getPedSexForClothes(ped)
    if force or currentGender ~= lastSentGender then
        lastSentGender = currentGender
        TriggerServerEvent('xn_case:updatePedGender', currentGender)
        DebugPrint('^2[xn_case]^7 Synced ped gender to server: ' .. currentGender)
    end
end

local display = false
function SetDisplay(bool)
    display = bool
    SetNuiFocus(bool, bool)
    -- Gửi event cho React UI
    SendNUIMessage({
        action = "setVisible",
        data = bool
    })
end

RegisterNUICallback("exit",function(data, cb)
    SetDisplay(false)
    cb('ok')
end)

RegisterNUICallback("NUIFocusOff",function(data, cb)
    SetDisplay(false)
    cb('ok')
end)

RegisterNUICallback('give', function(data, cb) 
    ----print("CLIENT GIVE DATA:", json.encode(data))
    ----print("DoHiem from data.case:", data.case and data.case.DoHiem or "nil")
    TriggerServerEvent('give', data.case)
    cb('ok')
end)

RegisterNetEvent('es-case:depositCompleted', function()
    local Framework = GetFramework()
    if not Framework then return end
    Framework.Functions.TriggerCallback("Profile", function(gold, bank, name, avatar, wonCounts)
        SendNUIMessage({
            type = "purchase",
            gold = gold,
            bank = bank,
            name = name,
            avatar = avatar,
            wonCounts = wonCounts
        })
    end)
end)

-- =====================================================
-- INVENTORY FULL CONFIRMATION - Popup xác nhận khi kho đầy
-- =====================================================
local inventoryFullResolve = nil

-- NUI callback nhận response từ React popup
RegisterNUICallback('inventoryFullResponse', function(data, cb)
    if inventoryFullResolve then
        inventoryFullResolve(data)
        inventoryFullResolve = nil
    end
    cb('ok')
end)

-- Server callback: hiển thị popup xác nhận và chờ player trả lời
lib.callback.register('es-case:confirmInventoryFull', function()
    local p = promise.new()
    
    inventoryFullResolve = function(result)
        p:resolve(result)
    end
    
    -- Gửi NUI message để React hiển thị popup
    SendNUIMessage({
        action = "confirmInventoryFull"
    })
    
    -- Chờ player trả lời (timeout 30s)
    local result = Citizen.Await(p)
    return result
end)

-- =====================================================
-- STORAGE FULL WARNING - Popup cảnh báo đỏ khi bưu cục đầy
-- =====================================================
RegisterNetEvent('es-case:storageFullWarning', function(itemLabel)
    SendNUIMessage({
        action = 'storageFullWarning',
        itemLabel = itemLabel or 'Không rõ'
    })
end)

-- =====================================================
-- OPTIMIZED DEEP COPY (Nhanh hơn json.encode/decode 10-20x)
-- =====================================================
local function DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for k, v in pairs(orig) do
            copy[k] = DeepCopy(v)
        end
    else
        copy = orig
    end
    return copy
end

-- =====================================================
-- CACHED LIVE CASES - Chỉ build 1 lần khi resource start
-- =====================================================
local cachedLiveCases = nil
local cacheVersion = 0

local function BuildLiveCasesInternal(async)
    local cases = {}
    local allGenders = {"male", "female"} -- Di chuyển ra ngoài loop
    local itemCount = 0

    for _, case in ipairs(Config.Live) do
        local newCase = DeepCopy(case)
        local originalItems = newCase.items
        newCase.items = {}

        for _, item in ipairs(originalItems) do
            if item.type == "clothing" then
                for _, gender in ipairs(allGenders) do
                    if item.DoHiem and item.DoHiem[gender] then
                        for rarityLevel, drawableList in pairs(item.DoHiem[gender]) do
                            for _, d in ipairs(drawableList) do
                                local newItem = DeepCopy(item)
                                newItem.drawable = d
                                newItem.sex = gender
                                newItem.DoHiem = rarityLevel

                                local base = Config.Items and Config.Items[newItem.item]
                                local label_sex = gender == "male" and "Nam" or "Nữ"
                                if base then
                                    newItem.label = base.label .. " #" .. d .. " (" .. label_sex .. ")"
                                    newItem.component = newItem.component or base.component
                                    newItem.clothesSlotID = newItem.clothesSlotID or base.clothesSlotID
                                    newItem.prop = base.prop or false
                                else
                                    newItem.label = newItem.item .. " #" .. d .. " (" .. label_sex .. ")"
                                    newItem.prop = false
                                end

                                newCase.items[#newCase.items + 1] = newItem
                                itemCount = itemCount + 1
                                
                                -- Yield thread mỗi 200 items để không đứng server
                                if async and itemCount % 200 == 0 then
                                    Wait(0)
                                end
                            end
                        end
                    end
                end
            else
                local newItem = DeepCopy(item)
                if not newItem.label then
                    local base = Config.Items and Config.Items[newItem.item]
                    newItem.label = base and base.label or newItem.item
                end
                
                newItem.uniqueId = newItem.item .. "_" .. (newItem.count or 1) .. "_" .. (newItem.DoHiem or "common")
                
                -- Pre-compute image path (không dùng random mỗi lần)
                if newItem.type == "item" then
                    newItem.baseImage = Config.OxInventoryImagePath .. newItem.item .. '.webp'
                else
                    newItem.image = 'https://raw.githubusercontent.com/QuocHuyCrow/imagestellacity/main/Items_KhoDo/' .. newItem.item .. '.webp'
                end
                
                newCase.items[#newCase.items + 1] = newItem
            end
        end

        -- Thêm specialItem vào items để UI hiển thị ảnh thực
        if newCase.specialItem then
            local si = newCase.specialItem
            newCase.items[#newCase.items + 1] = {
                item          = si.item,
                label         = si.label or si.item,
                DoHiem        = 'Legendary',
                type          = 'item',
                isSpecialItem = true,
                baseImage     = string.format('https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.webp', si.item),
                chance        = si.chance,
            }
        end

        -- Thêm từng Chibi ped vào items để UI hiển thị ảnh riêng cho mỗi ped
        if newCase.Chibi_item and newCase.Chibi_item.peds then
            for _, pedConfig in ipairs(newCase.Chibi_item.peds) do
                local chibiItem = {
                    item       = pedConfig.metaped,
                    label      = pedConfig.label or ((newCase.Chibi_item.label or 'Chibi Pet') .. ' - ' .. pedConfig.metaped),
                    DoHiem     = pedConfig.DoHiem or 'Legendary',
                    type       = 'item',
                    isChibiItem = true,
                    baseImage  = string.format('https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.webp', pedConfig.metaped),
                    chance     = pedConfig.chance,
                }
                newCase.items[#newCase.items + 1] = chibiItem
            end
        end

        cases[#cases + 1] = newCase
        
        -- Yield sau mỗi case
        if async then
            Wait(0)
        end
    end 

    return cases
end

-- Build cache khi resource start (async để không đứng)
CreateThread(function()
    Wait(500) -- Đợi config load xong
    cachedLiveCases = BuildLiveCasesInternal(true) -- async = true
    cacheVersion = GetGameTimer()
    DebugPrint('^2[ES-CASE]^7 Case cache built successfully')
end)

-- Hàm lấy cases với cache (thêm random image version khi cần)
local function BuildLiveCases()
    if not cachedLiveCases then
        cachedLiveCases = BuildLiveCasesInternal(false) -- sync mode khi cần ngay
    end
    
    -- Chỉ cập nhật random version cho images khi cần
    local randomVersion = math.random(1000, 9999)
    for _, case in ipairs(cachedLiveCases) do
        for _, item in ipairs(case.items) do
            if item.baseImage then
                item.image = item.baseImage .. '?v=' .. randomVersion
            end
        end
    end
    
    return cachedLiveCases
end

-- Export để refresh cache khi cần (ví dụ admin thay đổi config)
exports('RefreshCaseCache', function()
    cachedLiveCases = BuildLiveCasesInternal(false) -- sync cho admin command
    cacheVersion = GetGameTimer()
    nuiDataInitialized = false -- buộc resend khi UI mở lần tiếp theo
end)

-- =====================================================
-- NUI DELTA - Chỉ gửi config nặng 1 lần, sau đó skip
-- nuiDataInitialized = true sau lần OpenCaseMenu đầu tiên
-- =====================================================
nuiDataInitialized = false


if Config.Framework == 'QBCore' or Config.Framework == 'OLDQBCore'  then
     if Config.Framework == "OLDQBCore" then
          while Framework == nil do
               TriggerEvent('QBCore:GetObject', function(obj) Framework = obj end)
               Citizen.Wait(4)
          end
     else
          local ok, core = pcall(function()
               return exports['qb-core']:GetCoreObject()
          end)
          if ok and core then
               Framework = core
          else
               print("^1[xn_case]^7 Không lấy được Core — cần qbx_core start trước xn_case")
          end
     end

     RegisterNUICallback("Purchase",function(data, cb)
        Framework.Functions.TriggerCallback("GetPurchase", function(result, amount)
            cb(
                {
                    variable = result,
                    amount = amount
                }
            )
        end, data)
        end)

        RegisterNUICallback('sell', function(data, cb) 
            Framework.Functions.TriggerCallback("GetSell", function(result, new)
                cb(
                    {
                        variable = result,
                        amount = new
                    }
                )
           end, data)
       end)
       
       RegisterNUICallback('GetCase', function(data, cb) 
        Framework.Functions.TriggerCallback("GetCase", function(result)
            cb(result)
            -- Cập nhật tiền/xu realtime sau khi quay
            if result and (result.success or result.check) then
                Framework.Functions.TriggerCallback("Profile", function(gold, bank, name, avatar, wonCounts)
                    SendNUIMessage({
                        type = "purchase",
                        gold = gold,
                        bank = bank,
                        name = name,
                        avatar = avatar,
                        wonCounts = wonCounts
                    })
                end)
            end
           end, data)
       end)

       RegisterNUICallback('Case', function(data, cb) 
        Framework.Functions.TriggerCallback("Case", function(result)
            cb(result)
            -- Cập nhật tiền/xu realtime sau khi quay
            if result and result.success then
                Framework.Functions.TriggerCallback("Profile", function(gold, bank, name, avatar, wonCounts)
                    SendNUIMessage({
                        type = "purchase",
                        gold = gold,
                        bank = bank,
                        name = name,
                        avatar = avatar,
                        wonCounts = wonCounts
                    })
                end)
            end
           end, data)
       end)

       -- QR Player Info Callbacks - Now Framework is loaded
       RegisterNUICallback('GetPlayerInfo', function(data, cb)
           --print("🔍 NUI GetPlayerInfo called via client")
           Framework.Functions.TriggerCallback('GetPlayerInfo', function(response)
               --print("🔍 Server callback response:", json.encode(response))
               cb(response)
           end)
       end)

       RegisterNUICallback('directPlayerInfo', function(data, cb)
           --print("🔍 NUI directPlayerInfo called via client")
           Framework.Functions.TriggerCallback('directPlayerInfo', function(response)
               --print("🔍 Direct callback response:", json.encode(response))
               cb(response)
           end)
       end)

       RegisterNUICallback('testConnection', function(data, cb)
           Framework.Functions.TriggerCallback('testConnection', function(response)
               cb(response)
           end)
       end)

       local function AwaitDepositCallback(callbackName, payload)
           local ok, result = pcall(function()
               return lib.callback.await(callbackName, false, payload)
           end)
           if not ok then
               print(("^1[xn_case]^7 %s lỗi: %s"):format(callbackName, tostring(result)))
               return nil
           end
           return result
       end

       RegisterNUICallback('getDepositConfig', function(data, cb)
           local sepay = Config and Config.SePay
           if not sepay then
               cb({ success = false, message = "Thiếu Config.SePay" })
               return
           end
           cb({
               bankInfo = {
                   accountNumber = sepay.accountNumber,
                   accountName = sepay.accountName,
                   bankCode = sepay.bankCode,
               },
               minAmount = sepay.minAmount or 10000,
               rate = sepay.rate or 1000,
               paymentTimeoutMinutes = sepay.paymentTimeoutMinutes or 15,
           })
       end)

       RegisterNUICallback('createPayment', function(data, cb)
            DebugPrint(("^3[xn_case]^7 NUI createPayment amount=%s"):format(tostring(data and data.amount or "nil")))
            local response = AwaitDepositCallback('xn_case:createPayment', data)
            DebugPrint(("^3[xn_case]^7 createPayment response: %s"):format(json.encode(response or {})))
           cb(response or { success = false, message = "Server không phản hồi (createPayment)" })
       end)

       RegisterNUICallback('cancelPayment', function(data, cb)
           cb(AwaitDepositCallback('xn_case:cancelPayment', data) or { success = false, message = "Server không phản hồi" })
       end)

       RegisterNUICallback('checkPaymentStatus', function(data, cb)
           cb(AwaitDepositCallback('xn_case:checkPaymentStatus', data) or { status = "error" })
       end)

       RegisterNUICallback('getPendingPayment', function(data, cb)
           cb(AwaitDepositCallback('xn_case:getPendingPayment', data))
       end)

       RegisterNUICallback('getDepositHistory', function(data, cb)
           cb(AwaitDepositCallback('xn_case:getDepositHistory', data) or {})
       end)

       RegisterNUICallback('getProfile', function(data, cb)
           Framework.Functions.TriggerCallback("Profile", function(gold, bank, name, avatar, wonCounts)
               cb({ gold = gold, bank = bank, name = name, avatar = avatar, wonCounts = wonCounts })
           end)
       end)

       RegisterNUICallback("Check",function(data)
        Framework.Functions.TriggerCallback("Profile", function(gold, bank, name, avatar, wonCounts)
               SendNUIMessage(
                   {
                       type = "purchase",
                       gold =  gold,
                       bank =  bank,
                       name =  name,
                       avatar = avatar,
                       wonCounts = wonCounts
                   }
               )
           end)
       end)

       -- Function để mở hòm (OPTIMIZED)
       -- Pre-cache static config để không build lại mỗi lần
       local cachedStaticConfig = nil
       local function GetStaticConfig()
           if not cachedStaticConfig then
               cachedStaticConfig = {
                   standart = Config.Standart,
                   things = Config.System['List_Item_Show_Header'],
                   gold = Config.System['Store Gold Section'],
                   categories = Config.System['Case Categories'],
                   itemsell = Config.Itemsell,
                   rarityRates = Config.RarityRates,
                   bags = Config.BagTypes,
                   cardBoxes = Config.CardBoxes,
                   openBoxes = Config.OpenBoxes,
                   newItems = Config.NewItems
               }
           end
           return cachedStaticConfig
       end

       local function OpenCaseMenu()
           -- Sync giới tính ped lên server trước khi mở UI
           syncPedGenderToServer(true)
           -- Lấy cached data trước (không block)
           local liveCases = BuildLiveCases()
           local staticConfig = GetStaticConfig()
           
           -- DELTA: chỉ gửi config nặng lần đầu (sau đó NUI đã cache trong store)
           if not nuiDataInitialized then
               -- Gửi case data trước để NUI có thể render
                SendNUIMessage({
                    type = "case",
                    cases = liveCases,
                    standart = staticConfig.standart,
                    things = staticConfig.things,
                    gold = staticConfig.gold,
                    categories = staticConfig.categories,
                    itemsell = staticConfig.itemsell,
                    rarityRates = staticConfig.rarityRates,
                    newItems = staticConfig.newItems
                })
               
               -- Gửi bag selection data
               SendNUIMessage({
                   type = 'showBagSelection',
                   bags = staticConfig.bags,
               })

                -- Gửi card boxes data
                local cardBoxesData = {}
                if Config.CardBoxes then
                    for i, box in ipairs(Config.CardBoxes) do
                        local expandedItems = {}
                        if box.items then
                            for _, item in ipairs(box.items) do
                                if item.group_items then
                                    for _, subItem in ipairs(item.group_items) do
                                        local copyItem = {}
                                        for k, v in pairs(item) do
                                            copyItem[k] = v
                                        end
                                        copyItem.item = subItem
                                        copyItem.label = item.group_labels and item.group_labels[subItem] or subItem
                                        copyItem.rarity = item.group_rarities and item.group_rarities[subItem] or item.rarity
                                        copyItem.group_items = nil
                                        copyItem.group_labels = nil
                                        copyItem.group_rarities = nil
                                        expandedItems[#expandedItems + 1] = copyItem
                                    end
                                else
                                    expandedItems[#expandedItems + 1] = item
                                end
                            end
                        end
                        cardBoxesData[#cardBoxesData + 1] = {
                            index = i,
                            label = box.label,
                            icon = box.icon,
                            iconcard = box.iconcard,
                            size = box.size,
                            price = box.price,
                            currency = box.currency,
                            isNew = box.isNew,
                            items = expandedItems
                        }
                    end
                end
                SendNUIMessage({
                    type = 'showCardBoxes',
                    cardBoxes = cardBoxesData,
                })
 
                -- Gửi open boxes data (Mở Thính)
                local openBoxesData = {}
                if Config.OpenBoxes then
                    for i, box in ipairs(Config.OpenBoxes) do
                        local expandedItems = {}
                        if box.items then
                            for _, item in ipairs(box.items) do
                                if item.group_items then
                                    for _, subItem in ipairs(item.group_items) do
                                        local copyItem = {}
                                        for k, v in pairs(item) do
                                            copyItem[k] = v
                                        end
                                        copyItem.item = subItem
                                        copyItem.label = item.group_labels and item.group_labels[subItem] or subItem
                                        copyItem.rarity = item.group_rarities and item.group_rarities[subItem] or item.rarity
                                        copyItem.group_items = nil
                                        copyItem.group_labels = nil
                                        copyItem.group_rarities = nil
                                        expandedItems[#expandedItems + 1] = copyItem
                                    end
                                else
                                    expandedItems[#expandedItems + 1] = item
                                end
                            end
                        end
                        openBoxesData[#openBoxesData + 1] = {
                            index = i,
                            label = box.label,
                            icon = box.icon,
                            iconcard = box.iconcard,
                            size = box.size,
                            price = box.price,
                            currency = box.currency,
                            isNew = box.isNew,
                            items = expandedItems
                        }
                    end
                end
                SendNUIMessage({
                    type = 'showOpenBoxes',
                    openBoxes = openBoxesData,
                })

               nuiDataInitialized = true
           end
           
           -- Set display và focus 1 lần duy nhất
           SetDisplay(true)
           
           -- Phát âm thanh
           PlaySoundFrontend(-1, Config.Sounds['bag_open'].name, Config.Sounds['bag_open'].set, false)
           
           -- Load profile async (không block UI) - LUÔN gửi vì tiền có thể thay đổi
           Framework.Functions.TriggerCallback("Profile", function(gold, bank, name, avatar, wonCounts)
               SendNUIMessage({
                   type = "purchase",
                   gold = gold,
                   bank = bank,
                   name = name,
                   avatar = avatar,
                   wonCounts = wonCounts
               })
           end)
       end

       -- RegisterCommand để mở hòm bằng lệnh
       RegisterCommand('case', function()
           OpenCaseMenu()
       end)

       -- RegisterKeyMapping để mở hòm bằng phím F5
       RegisterKeyMapping('case', 'Mở menu Case Gacha', 'keyboard', 'F5')

       -- RegisterNetEvent để mở hòm từ script khác
       RegisterNetEvent('es-case:client:openCase', function()
           OpenCaseMenu()
       end)

       -- RegisterNetEvent để mở hòm với case cụ thể (OPTIMIZED)
       RegisterNetEvent('es-case:client:openSpecificCase', function(caseKey)
           local liveCases = BuildLiveCases()
           local specificCase = nil
           
           -- Tìm case cụ thể theo key_required
           for _, case in ipairs(liveCases) do
               if case.key_required == caseKey then
                   specificCase = case
                   break
               end
           end
           
           if specificCase then
               local staticConfig = GetStaticConfig()
               
               -- Gửi case data trước
               SendNUIMessage({
                   type = "case",
                   cases = {specificCase},
                   standart = staticConfig.standart,
                   things = staticConfig.things,
                   gold = staticConfig.gold,
                   categories = staticConfig.categories,
                   rarityRates = staticConfig.rarityRates,
                   newItems = staticConfig.newItems,
                   specificCase = true
               })
               
               SetDisplay(true)
               
               -- Load profile async
               Framework.Functions.TriggerCallback("Profile", function(gold, bank, name, avatar, wonCounts)
                   SendNUIMessage({
                       type = "purchase",
                       gold = gold,
                       bank = bank,
                       name = name,
                       avatar = avatar,
                       wonCounts = wonCounts
                   })
               end)
           end
       end)

       RegisterNUICallback('GetGold', function(data, cb) 
        Framework.Functions.TriggerCallback("GoldBuy", function(result, bank)
            cb(
               {
               data = result,
               bank = bank,
               }
            )
           end, data)
       end)

       -- Callback để mua item từ cửa hàng
        RegisterNUICallback('BuyShopItem', function(data, cb)
         DebugPrint('[BuyShopItem CLIENT] Received data:', json.encode(data))
         Framework.Functions.TriggerCallback("BuyShopItem", function(result)
             DebugPrint('[BuyShopItem CLIENT] Result from server:', json.encode(result))
             cb(result)
         end, data)
        end)

       -- Callback để mở thẻ bài (chỉ roll items, không trừ tiền)
       RegisterNUICallback('OpenCardBox', function(data, cb)
        Framework.Functions.TriggerCallback("OpenCardBox", function(result)
            cb(result)
        end, data)
       end)

       -- Callback để lật 1 thẻ (trừ tiền cho thẻ đó)
       RegisterNUICallback('FlipCard', function(data, cb)
        Framework.Functions.TriggerCallback("FlipCard", function(result)
            cb(result)
            if result and result.success then
                Framework.Functions.TriggerCallback("Profile", function(gold, bank, name, avatar, wonCounts)
                    SendNUIMessage({
                        type = "purchase",
                        gold = gold,
                        bank = bank,
                        name = name,
                        avatar = avatar,
                        wonCounts = wonCounts
                    })
                end)
            end
        end, data)
       end)

       -- Callback để nhận thưởng (add items đã lật vào inventory)
       RegisterNUICallback('CollectCards', function(data, cb)
        Framework.Functions.TriggerCallback("CollectCards", function(result)
            cb(result)
        end, data)
       end)

       -- Callback mở hộp thính (trừ tiền + roll items)
       RegisterNUICallback('OpenOpenBox', function(data, cb)
        Framework.Functions.TriggerCallback("OpenOpenBox", function(result)
            cb(result)
            -- Cập nhật tiền/xu realtime sau khi trừ
            if result and result.success then
                Framework.Functions.TriggerCallback("Profile", function(gold, bank, name, avatar, wonCounts)
                    SendNUIMessage({
                        type = "purchase",
                        gold = gold,
                        bank = bank,
                        name = name,
                        avatar = avatar,
                        wonCounts = wonCounts
                    })
                end)
            end
        end, data)
       end)

       -- Callback nhận thưởng hộp thính
       RegisterNUICallback('CollectOpenBoxCards', function(data, cb)
        Framework.Functions.TriggerCallback("CollectOpenBoxCards", function(result)
            cb(result)
        end, data)
       end)

end


    
-- Các phần khác giữ nguyên như code gốc
local currentBagType = nil

-- NUI Callback được cập nhật để hỗ trợ count
RegisterNUICallback('openBag', function(data, cb)
     if not data.bagType then
        cb({ success = false, message = "Thiếu bagType" })
        return
    end

    local count = tonumber(data.count) or 1

    local result = lib.callback.await(
        "esx_bag:openBag",
        false,
        data.bagType,
        count
    )

    cb(result)

    -- if data.bagType then
    --     local count = data.count or 1
    --     local result = lib.callback.await("esx_bag:openBag", false, data.bagType, count)
    --     print(result)
    --     cb(result)
    -- end
end)

-- NUI Callback được cập nhật để hỗ trợ count
RegisterNUICallback('claimBag', function(data, cb)
    if data.bagType then
        local count = data.count or 1
        local result = lib.callback.await("esx_bag:claimBag", false, data.bagType, count)
        -- print(result)
        cb(result)
    end
end)
-- Hàm mở UI chọn túi (mới)
function openBagSelectionUI()
   
    SetNuiFocus(true, true)
    
    -- Gửi tất cả config túi và túi có sẵn đến UI
    SendNUIMessage({
        type = 'showBagSelection',
        bags = Config.BagTypes,
    })
    
    -- Phát âm thanh
    PlaySoundFrontend(-1, Config.Sounds['bag_open'].name, Config.Sounds['bag_open'].set, false)
end

-- Hàm mở UI túi đơn (giữ lại để tương thích)
local function openBagUI(bagType)
    
    currentBagType = bagType
    
    SetNuiFocus(true, true)
    
    -- Gửi dữ liệu túi đến UI
    local bagConfig = Config.BagTypes[bagType]
    SendNUIMessage({
        type = 'showBagUI',
        bagInfo = bagConfig,
        bagType = bagType
    })
    
    -- Phát âm thanh
    PlaySoundFrontend(-1, Config.Sounds['bag_open'].name, Config.Sounds['bag_open'].set, false)
end

-- Hàm đóng UI
local function closeBagUI()
   
    currentBagType = nil
    
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'hideBagUI'
    })
end

-- Event nhận phần thưởng từ server
RegisterNetEvent('esx_bag:showRewards')
AddEventHandler('esx_bag:showRewards', function(rewards, bagType)
    SendNUIMessage({
        type = 'showRewards',
        rewards = rewards,
        bagType = bagType
    })
    
    -- Phát âm thanh nhận phần thưởng
    PlaySoundFrontend(-1, Config.Sounds['item_received'].name, Config.Sounds['item_received'].set, false)
end)

RegisterNUICallback('closeBagUI', function(data, cb)
    closeBagUI()
    cb('ok')
end)


RegisterNUICallback('playSound', function(data, cb)
    local soundName = data.sound or 'CLICK_BACK'
    local soundSet = data.set or 'HUD_FRONTEND_DEFAULT_SOUNDSET'
    PlaySoundFrontend(-1, soundName, soundSet, false)
    cb('ok')
end)

-- Lệnh mở túi đơn (giữ lại để tương thích)
-- RegisterCommand('openbag', function(source, args, rawCommand)
--     local bagType = args[1]
    
--     if not bagType then
--         QBCore.Functions.Notify('Sử dụng: /openbag [loại túi]', 'error')
--         QBCore.Functions.Notify('Các loại túi: common_bag, rare_bag, epic_bag, legendary_bag', 'info')
--         return
--     end
    
--     if not Config.BagTypes[bagType] then
--         QBCore.Functions.Notify('Loại túi không tồn tại!', 'error')
--         return
--     end
    
--     openBagUI(bagType)
-- end, false)

-- Lệnh mở UI chọn túi (mới)
-- RegisterCommand('openbags', function()
--     openBagSelectionUI()
-- end, false)

-- Lệnh kiểm tra túi có sẵn
-- RegisterCommand('checkbags', function()
--     TriggerServerEvent('esx_bag:checkBags')
-- end, false)

-- Event nhận danh sách túi có sẵn
RegisterNetEvent('esx_bag:receiveAvailableBags')
AddEventHandler('esx_bag:receiveAvailableBags', function(availableBags)
    if next(availableBags) == nil then
        QBCore.Functions.Notify('Bạn không có túi nào!', 'error')
        return
    end
    
    local message = 'Túi của bạn:\n'
    for bagType, count in pairs(availableBags) do
        local bagConfig = Config.BagTypes[bagType]
        if bagConfig then
            message = message .. string.format('• %s: %dx\n', bagConfig.label, count)
        end
    end
    
    QBCore.Functions.Notify(message, 'info')
end)

-- Export functions cho các script khác
exports('openBagUI', openBagUI)
exports('openBagSelectionUI', openBagSelectionUI)
exports('closeBagUI', closeBagUI)

-- Event sử dụng túi
RegisterNetEvent('esx_bag:useBag')
AddEventHandler('esx_bag:useBag', function(bagType)
    openBagUI(bagType)
end)

-- =====================================================
-- ADMIN ADD COIN UI POPUP
-- =====================================================
RegisterNetEvent('xn_case:client:openAddCoinUI', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openAddCoin"
    })
end)

RegisterNUICallback('addCoinClose', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "closeAddCoin"
    })
    cb('ok')
end)

RegisterNUICallback('addCoinSubmit', function(data, cb)
    local result = lib.callback.await('xn_case:server:processAddCoin', false, data)
    if result and result.success then
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = "addCoinResult",
            success = true,
            message = result.message
        })
    else
        SendNUIMessage({
            action = "addCoinResult",
            success = false,
            message = result and result.message or "Có lỗi xảy ra khi thực hiện tặng coin!"
        })
    end
    cb('ok')
end)

-- Callback hiển thị dialog nhập thông tin tặng coin (fallback)
lib.callback.register('xn_case:client:showAddCoinDialog', function()
    local dialog = lib.inputDialog('Tặng Coin - Đơn / Hàng Loạt', {
        {
            type = 'textarea',
            label = 'Danh Sách Người Nhận (ID/PID & Số Coin)',
            description = 'Mỗi người 1 dòng theo cú pháp: [ID hoặc PID] : [Số coin]\nVí dụ:\n1 : 500\n1024 : 1000\nPID88 : 250\n(Nếu chỉ nhập ID/PID không ghi coin thì sẽ lấy Số coin mặc định bên dưới)',
            placeholder = "1 : 500\n1024 : 1000\nPID88 : 250",
            required = true,
            autosize = true
        },
        {
            type = 'number',
            label = 'Số Coin Mặc Định (Tùy chọn)',
            description = 'Áp dụng cho dòng nào chỉ ghi ID/PID mà không ghi số coin',
            placeholder = 'Nhập số coin mặc định...',
            required = false,
            min = 1
        },
        {
            type = 'input',
            label = 'Mã Xác Minh (Bắt buộc)',
            placeholder = 'Nhập mã 9 ký tự từ Discord...',
            required = true
        }
    })
    return dialog
end)


