

local albumShares = {}

BaseCallback("airShare:share", function(source, targetSource, sendToSource, device, shareData)
    local senderName = Player(source).state.phoneName
    if not senderName then
        debugprint("No sender name")
        return false
    end
    
    shareData.sender = {
        name = senderName,
        source = source,
        device = "phone"
    }
    
    if device == "tablet" then
        if GetResourceState("lb-tablet") == "started" then
            if Player(sendToSource).state.lbTabletOpen then
                TriggerClientEvent("tablet:airShare:received", sendToSource, shareData)
            else
                return false
            end
        else
            return false
        end
    elseif device == "phone" then
        if not Player(sendToSource).state.phoneOpen then
            debugprint("sendToSource's phone is not open")
            return false
        end
        TriggerClientEvent("phone:airShare:received", sendToSource, shareData)
    end
    
    if shareData.type == "album" then
        if not albumShares[sendToSource] then
            albumShares[sendToSource] = {}
        end
        albumShares[sendToSource][source] = shareData.album.id
    end
    
    return true
end, false)

RegisterNetEvent("phone:airShare:interacted", function(senderSource, senderDevice, accepted)
    local source = source
    
    if type(senderSource) == "number" and type(senderDevice) == "string" then
        if senderDevice == "tablet" then
            TriggerClientEvent("tablet:airShare:interacted", senderSource, source, accepted)
        elseif senderDevice == "phone" then
            TriggerClientEvent("phone:airShare:interacted", senderSource, source, accepted)
        end
        
        if albumShares[source] then
            local albumId = albumShares[source][senderSource]
            if albumId then
                albumShares[source][senderSource] = nil
                if not next(albumShares[source]) then
                    albumShares[source] = nil
                end
                
                if not accepted then
                    debugprint("AirShare: denied album share", albumId)
                    return
                end
                
                debugprint("AirShare: accepted album share", albumId)
                HandleAcceptAirShareAlbum(source, senderSource, albumId)
            end
        end
    else
        debugprint("AirShare:interacted: Invalid senderSource or senderDevice", senderSource, senderDevice)
    end
end)

local validShareTypes = {
    image = true,
    contact = true,
    location = true,
    note = true,
    voicememo = true
}

exports("AirShare", function(senderSource, targetSource, shareType, data)
    assert(type(senderSource) == "number", "Invalid sender")
    assert(type(targetSource) == "number", "Invalid target")
    assert(validShareTypes[shareType], "Invalid shareType")
    assert(type(data) == "table", "Invalid data")
    
    local phoneNumber = GetEquippedPhoneNumber(senderSource)
    if not phoneNumber then
        return false
    end
    
    local shareData = {
        type = shareType,
        sender = {
            name = Player(senderSource).state.phoneName or phoneNumber,
            source = senderSource,
            device = "phone"
        }
    }
    
    if shareType == "image" then
        shareData.attachment = data
        assert(data.src, "Invalid image data (missing src)")
        if not shareData.attachment.timestamp then
            shareData.attachment.timestamp = os.time() * 1000
        end
    elseif shareType == "contact" then
        shareData.contact = data
        assert(type(shareData.contact.number) == "string", "Invalid/missing contact data (contact.number)")
        assert(type(shareData.contact.firstname) == "string", "Invalid/missing contact data (contact.firstname)")
    elseif shareType == "location" then
        assert(data.location, "Invalid location data (missing location)")
        assert(type(data.name) == "string", "Invalid/missing location data (location.name)")
        shareData.location = data.location
        shareData.name = data.name
    elseif shareType == "note" then
        shareData.note = data
        assert(type(shareData.note.title) == "string", "Invalid/missing note data (note.title)")
        assert(type(shareData.note.content) == "string", "Invalid/missing note data (note.content)")
    elseif shareType == "voicememo" then
        shareData.voicememo = data
        assert(type(shareData.voicememo.title) == "string", "Invalid/missing voicememo data (voicememo.title)")
        assert(type(shareData.voicememo.src) == "string", "Invalid/missing voicememo data (voicememo.src)")
        assert(type(shareData.voicememo.duration) == "number", "Invalid/missing voicememo data (voicememo.duration)")
    end
    
    TriggerClientEvent("phone:airShare:received", targetSource, shareData)
end)

AddEventHandler("playerDropped", function()
    albumShares[source] = nil
end)
