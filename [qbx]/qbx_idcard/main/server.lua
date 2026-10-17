local sharedConfig = require 'config.shared'

local ox_inventory = exports.ox_inventory

function NewMetaDataLicense(src, itemName)
    local newMetaDataItem = ox_inventory:Search(src, 1, itemName)
    for _, v in pairs(newMetaDataItem) do --luacheck: ignore
        newMetaDataItem = v
        break
    end
    newMetaDataItem.metadata.mugShot = lib.callback.await('um-idcard:client:callBack:getMugShot', src)
    if not newMetaDataItem.metadata.dinhdanh then
        local pData = exports.qbx_core:GetPlayer(src)
        local charinfo = pData and pData.PlayerData.charinfo
        local val = charinfo and (charinfo.dinhdanh or charinfo.dinh_danh) or (pData and pData.PlayerData.metadata and (pData.PlayerData.metadata.dinhdanh or pData.PlayerData.metadata.dinh_danh)) or 1
        newMetaDataItem.metadata.dinhdanh = val
    end
    if not newMetaDataItem.metadata.ngaycap then
        local pData = exports.qbx_core:GetPlayer(src)
        local charinfo = pData and pData.PlayerData.charinfo
        local val = charinfo and (charinfo.ngaycap or charinfo.ngay_cap) or (pData and pData.PlayerData.metadata and (pData.PlayerData.metadata.ngaycap or pData.PlayerData.metadata.ngay_cap)) or os.date('%d/%m/%Y')
        newMetaDataItem.metadata.ngaycap = val
    end
    ox_inventory:SetMetadata(src, newMetaDataItem.slot, newMetaDataItem.metadata)
end

RegisterNetEvent('um-idcard:server:sendData', function(src, item, metadata)
    if metadata.mugShot then
        local source = src

        lib.callback('um-idcard:client:callBack:getClosestPlayer', src, function(player)
            if player ~= 0 then
                TriggerClientEvent('um-idcard:client:notifyOx', src, {
                    title = 'You showed your idcard',
                    desc = 'You are showing your ID Card to the closest player',
                    icon = 'id-card',
                    iconColor = 'green'
                })

                src = player
            end

            local pData = exports.qbx_core:GetPlayer(source)
            local data = pData.PlayerData.charinfo
            data.sex = data.gender == 0 and 'Male' or 'Female' -- Resolve gender being int
            data.cardtype = item or "id_card" -- Define card type default if not found
            data.mugShot = metadata.mugShot -- Append mugshot to data obj
            data.Loaibang = metadata.Loaibang or '' -- Append license class for driver_license

            local rawDinhdanh = metadata.dinhdanh or metadata.dinh_danh or data.dinhdanh or data.dinh_danh or (pData.PlayerData.metadata and (pData.PlayerData.metadata.dinhdanh or pData.PlayerData.metadata.dinh_danh)) or 1
            if type(rawDinhdanh) == 'string' then
                if string.find(rawDinhdanh, '2') then
                    rawDinhdanh = 2
                elseif string.find(rawDinhdanh, '1') then
                    rawDinhdanh = 1
                end
            end
            data.dinhdanh = rawDinhdanh

            local rawNgaycap = metadata.ngaycap or metadata.ngay_cap or data.ngaycap or data.ngay_cap or (pData.PlayerData.metadata and (pData.PlayerData.metadata.ngaycap or pData.PlayerData.metadata.ngay_cap)) or os.date('%d/%m/%Y')
            data.ngaycap = rawNgaycap

            TriggerClientEvent('um-idcard:client:sendData', src, data)
        end)

        TriggerClientEvent('um-idcard:client:startAnim', src, item)
    else
        NewMetaDataLicense(src, item)
    end
end)

for k,_ in pairs(sharedConfig.licenses) do
    CreateRegisterItem(k)
end