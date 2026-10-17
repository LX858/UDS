

local CompanyCallsDisabled = {}

local Calls = {}

local function generateCallId()
    local id = math.random(999999999)
    while Calls[id] ~= nil do
        id = math.random(999999999)
    end
    return id
end

local function isPlayerInAnyCall(src)
    for callId, call in pairs(Calls) do
        if (call.caller and call.caller.source == src) or (call.callee and call.callee.source == src) then
            return true, callId
        end
    end
    return false
end

local function _hasAirplaneMode(number)
    debugprint("checking if", number, "has airplane mode enabled")
    local settings = GetSettings(number)
    if not settings then
        debugprint("no settings found for", number)
        return
    end
    return settings.airplaneMode
end

HasAirplaneMode = _hasAirplaneMode

exports("HasAirplaneMode", HasAirplaneMode)

function GetContact(ownerNumber, contactNumber, cb)
    local sql = [[
        SELECT
            CONCAT(firstname, ' ', lastname) AS name,
            profile_image AS avatar,
            firstname, lastname, email, address,
            contact_phone_number AS number,
            favourite,
            EXISTS(
                SELECT 1 FROM phone_phone_blocked_numbers b
                WHERE b.phone_number = ? AND b.blocked_number = `number`
            ) AS blocked
        FROM phone_phone_contacts
        WHERE contact_phone_number = ? AND phone_number = ?
    ]]

    local params = { ownerNumber, contactNumber, ownerNumber }
    if cb then
        return MySQL.single(sql, params, cb)
    else
        return MySQL.single.await(sql, params)
    end
end

function CreateContact(ownerNumber, data)
    local sql = [[
        INSERT INTO phone_phone_contacts
            (contact_phone_number, firstname, lastname, profile_image, email, address, phone_number)
        VALUES
            (@contactNumber, @firstname, @lastname, @avatar, @email, @address, @phoneNumber)
        ON DUPLICATE KEY UPDATE
            firstname=@firstname, lastname=@lastname, profile_image=@avatar, email=@email, address=@address
    ]]

    local ok = MySQL.Sync.execute(sql, {
        ["@contactNumber"] = data.number,
        ["@firstname"]     = data.firstname,
        ["@lastname"]      = data.lastname or "",
        ["@avatar"]        = data.avatar,
        ["@email"]         = data.email,
        ["@address"]       = data.address,
        ["@phoneNumber"]   = ownerNumber
    })

    return ok > 0
end

BaseCallback("saveContact", function(_, ownerNumber, data)
    return CreateContact(ownerNumber, data)
end, false)

BaseCallback("getContacts", function(_, ownerNumber)
    local sql = [[
        SELECT
            contact_phone_number AS number,
            firstname, lastname,
            profile_image AS avatar,
            favourite,
            EXISTS(
                SELECT 1 FROM phone_phone_blocked_numbers b
                WHERE b.phone_number=@phoneNumber AND b.blocked_number=`number`
            ) AS blocked
        FROM phone_phone_contacts c
        WHERE c.phone_number=@phoneNumber
    ]]
    return MySQL.query.await(sql, { ["@phoneNumber"] = ownerNumber })
end, {})

BaseCallback("toggleBlock", function(_, ownerNumber, targetNumber, shouldBlock)
    local sql
    if shouldBlock then
        sql = "INSERT INTO phone_phone_blocked_numbers (phone_number, blocked_number) VALUES (@phoneNumber, @number) ON DUPLICATE KEY UPDATE phone_number=@phoneNumber"
    else
        sql = "DELETE FROM phone_phone_blocked_numbers WHERE phone_number=@phoneNumber AND blocked_number=@number"
    end
    MySQL.update.await(sql, { ["@phoneNumber"] = ownerNumber, ["@number"] = targetNumber })
    return shouldBlock
end, false)

BaseCallback("toggleFavourite", function(_, ownerNumber, contactNumber, fav)
    local sql = "UPDATE phone_phone_contacts SET favourite=@favourite WHERE contact_phone_number=@number AND phone_number=@phoneNumber"
    MySQL.update.await(sql, {
        ["@phoneNumber"] = ownerNumber,
        ["@number"] = contactNumber,
        ["@favourite"] = (true == fav)
    })
    return true
end, false)

BaseCallback("removeContact", function(_, ownerNumber, contactNumber)
    MySQL.update.await("DELETE FROM phone_phone_contacts WHERE contact_phone_number=? AND phone_number=?", { contactNumber, ownerNumber })
    return true
end, false)

BaseCallback("updateContact", function(_, ownerNumber, data)
    local sql = [[
        UPDATE phone_phone_contacts
        SET firstname=@firstname, lastname=@lastname, profile_image=@avatar, email=@email, address=@address, contact_phone_number=@newNumber
        WHERE contact_phone_number=@number AND phone_number=@phoneNumber
    ]]
    MySQL.update.await(sql, {
        ["@phoneNumber"] = ownerNumber,
        ["@number"]      = data.oldNumber,
        ["@newNumber"]   = data.number,
        ["@firstname"]   = data.firstname,
        ["@lastname"]    = data.lastname or "",
        ["@avatar"]      = data.avatar,
        ["@email"]       = data.email,
        ["@address"]     = data.address
    })
    return true
end, false)

BaseCallback("getRecentCalls", function(_, number, onlyMissed, beforeId)
    local onlyMiss = (true == onlyMissed)
    local params = { number, number, number, number, number } 
    local sql = [[
        SELECT
            c.id,
            c.duration,
            c.answered,
            (c.caller = ?) AS called,
            IF(c.callee = ?, c.caller, c.callee) AS `number`,
            IF(c.callee = ?, c.hide_caller_id, FALSE) AS hideCallerId,
            EXISTS (SELECT 1 FROM phone_phone_blocked_numbers b WHERE b.phone_number=? AND b.blocked_number=`number`) AS blocked,
            c.`timestamp`
        FROM phone_phone_calls c
        WHERE (c.callee = ? {MISSED})
        {PAGINATION}
        ORDER BY c.id DESC
        LIMIT 25
    ]]

    if onlyMiss then
        sql = sql:gsub("{MISSED}", "AND c.answered = 0")
    else
        sql = sql:gsub("{MISSED}", "OR c.caller = ?")
        params[#params + 1] = number
    end

    if beforeId then
        sql = sql:gsub("{PAGINATION}", "AND c.id < ?")
        params[#params + 1] = beforeId
    else
        sql = sql:gsub("{PAGINATION}", "")
    end

    local rows = MySQL.query.await(sql, params)

    -- normalize booleans + anonymize if needed
    for _, r in ipairs(rows) do
        r.hideCallerId = (true == r.hideCallerId)
        r.blocked      = (true == r.blocked)
        r.called       = (true == r.called)
        if r.hideCallerId then
            r.number = L("BACKEND.CALLS.NO_CALLER_ID")
        end
    end

    return rows
end, {})

BaseCallback("getBlockedNumbers", function(_, ownerNumber)
    return MySQL.query.await("SELECT blocked_number AS `number` FROM phone_phone_blocked_numbers WHERE phone_number=?", { ownerNumber })
end, {})

local function logCall(caller, callee, duration, answered, hideCallerId, equippedNumber)
    MySQL.insert.await(
        "INSERT INTO phone_phone_calls (caller, callee, duration, answered, hide_caller_id) VALUES (@caller, @callee, @duration, @answered, @hide)",
        { ["@caller"] = caller, ["@callee"] = callee, ["@duration"] = duration, ["@answered"] = answered, ["@hide"] = hideCallerId }
    )

    if answered or equippedNumber == callee then return end

    local exists = MySQL.scalar.await("SELECT TRUE FROM phone_phones WHERE phone_number = ?", { callee })
    if not exists then return end

    if hideCallerId then
        SendNotification(callee, {
            app = "Phone",
            title = L("BACKEND.CALLS.NO_CALLER_ID"),
            content = L("BACKEND.CALLS.MISSED_CALL"),
            showAvatar = false
        })
        return
    end

    GetContact(caller, callee, function(contact)
        SendNotification(callee, {
            app = "Phone",
            title = (contact and contact.name) or caller,
            content = L("BACKEND.CALLS.MISSED_CALL"),
            avatar = contact and contact.avatar or nil,
            showAvatar = true
        })
    end)

    SendMessage(caller, callee, "<!CALL-NO-ANSWER!>")
end

RegisterNetEvent("phone:logCall", function(targetNumber, duration, answered)
    local src = source
    local myNumber = GetEquippedPhoneNumber(src)
    if not (myNumber and targetNumber) or (answered == nil) then return end
    logCall(myNumber, targetNumber, duration, answered, false, myNumber)
end)

RegisterNetEvent("phone:phone:disableCompanyCalls", function(disable)
    local src = source
    if disable then
        CompanyCallsDisabled[src] = true
    else
        CompanyCallsDisabled[src] = nil
    end
end)

BaseCallback("call", function(src, myNumber, payload)
    debugprint("phone:phone:call", src, myNumber, payload)

    if isPlayerInAnyCall(src) then
        debugprint(src, "is in call, returning")
        return false
    end

    local callId = generateCallId()
    local call = {
        started = os.time(),
        answered = false,
        videoCall = (true == payload.videoCall),
        hideCallerId = (true == payload.hideCallerId),
        callId = callId,
        caller = { source = src, number = myNumber, nearby = {} }
    }

    if payload.company then
        if not (Config.Companies.Enabled) or payload.videoCall then
            debugprint("company calls are disabled in config or trying to call with video")
            TriggerClientEvent("phone:phone:userBusy", src)
            return false
        end

        local validCompany = Config.Companies.Contacts[payload.company] ~= nil
        if not validCompany then
            for _, svc in ipairs(Config.Companies.Services) do
                if svc.job == payload.company then
                    validCompany = true
                    break
                end
            end
        end
        if not validCompany then
            debugprint("invalid company (does not exist in Config.Companies.Contacts or Config.Companies.Services)")
            return false
        end

        if not Config.Companies.AllowAnonymous then
            call.hideCallerId = false
        end

        call.videoCall = false
        call.company = payload.company
        call.callee = { nearby = {} }

        local employees = GetEmployees(payload.company)
        debugprint("GetEmployees result:", employees)
        for _, empSrc in ipairs(employees) do
            if not isPlayerInAnyCall(empSrc) and empSrc ~= src and not CompanyCallsDisabled[empSrc] then
                TriggerClientEvent("phone:phone:setCall", empSrc, {
                    callId = callId,
                    number = myNumber,
                    company = payload.company,
                    companylabel = payload.companylabel,
                    hideCallerId = call.hideCallerId
                })
            else
                debugprint("employee", empSrc, "is in call or have disabled company calls")
            end
        end

    else
        local blocked = MySQL.Sync.fetchScalar([[
            SELECT TRUE FROM phone_phone_blocked_numbers WHERE
                (phone_number = @n1 AND blocked_number = @n2)
                OR (phone_number = @n2 AND blocked_number = @n1)
        ]], { ["@n1"] = myNumber, ["@n2"] = payload.number })

        if blocked then
            debugprint(src, "tried to call", payload.number, "but they are blocked")
            TriggerClientEvent("phone:phone:userBusy", src)
            return false
        end

        if payload.number == myNumber then
            debugprint(src, "tried to call themselves")
            TriggerClientEvent("phone:phone:userBusy", src)
            return false
        end

        local calleeSrc = GetSourceFromNumber(payload.number)
        local calleeBusy = calleeSrc and isPlayerInAnyCall(calleeSrc)

        if not (calleeSrc and not calleeBusy) or IsPhoneDead(payload.number) or HasAirplaneMode(payload.number) then
            logCall(myNumber, payload.number, 0, false, payload.hideCallerId)
            if calleeBusy then
                debugprint(src, "tried to call", payload.number, "but they are in call")
                TriggerClientEvent("phone:phone:userBusy", src)
            else
                debugprint(src, "tried to call", payload.number, "but they are not online / their phone is dead")
                TriggerClientEvent("phone:phone:userUnavailable", src)
            end
            return false
        end

        call.callee = { source = calleeSrc, number = payload.number, nearby = {} }
        debugprint(src, "is calling", payload.number, "with callId", callId)

        TriggerClientEvent("phone:phone:setCall", calleeSrc, {
            callId = callId,
            number = myNumber,
            videoCall = payload.videoCall,
            webRTC = payload.webRTC,
            hideCallerId = payload.hideCallerId
        })
    end

    Calls[callId] = call
    TriggerEvent("lb-phone:newCall", call)
    return callId
end)

RegisterLegacyCallback("answerCall", function(src, cb, callId)
    debugprint("phone:phone:answerCall", src, callId)
    local call = Calls[callId]
    if not call then
        debugprint("phone:phone:answerCall: invalid call id")
        return cb(false)
    end

    if call.company then
        if call.callee.source then
            return cb(false)
        end
        for _, empSrc in ipairs(GetEmployees(call.company)) do
            if (not isPlayerInAnyCall(empSrc)) and empSrc ~= src and not CompanyCallsDisabled[empSrc] then
                TriggerClientEvent("phone:phone:endCall", empSrc, callId)
            end
        end
        call.callee.source = src
    else
        if call.callee.source ~= src then
            debugprint("phone:phone:answerCall: invalid source")
            return cb(false)
        end
    end

    local callerSrc = call.caller.source
    local calleeSrc = call.callee.source

    local callerState = Player(callerSrc).state
    local calleeState = Player(calleeSrc).state

    callerState.speakerphone = false
    calleeState.speakerphone = false
    callerState.mutedCall = false
    calleeState.mutedCall = false
    callerState.otherMutedCall = false
    calleeState.otherMutedCall = false
    callerState.onCallWith = calleeSrc
    calleeState.onCallWith = callerSrc
    callerState.callAnswered = true
    calleeState.callAnswered = true

    call.answered = true

    TriggerClientEvent("phone:phone:connectCall", src, callId)
    TriggerClientEvent("phone:phone:connectCall", callerSrc, callId, (true == call.exportCall))

    
    TriggerClientEvent("phone:phone:setCallEffect", src, callerSrc, true)
    TriggerClientEvent("phone:phone:setCallEffect", callerSrc, src, true)

    TriggerEvent("lb-phone:callAnswered", call)
    debugprint("phone:phone:answerCall: answered call", callId)
    cb(true)
end)



BaseCallback("requestVideoCall", function(src, _, callId, metadata)
    if not callId or not Calls[callId] then
        debugprint("requestVideoCall: invalid call id", callId, json.encode(Calls, { indent = true }))
        return false
    end
    debugprint("requestVideoCall", src, callId, metadata)
    local call = Calls[callId]
    if call.videoCall or not call.answered then return false end

    local other = (call.caller.source == src and call.callee.source) or call.caller.source
    call.videoRequested = true
    TriggerClientEvent("phone:phone:videoRequested", other, metadata)
end)

BaseCallback("answerVideoRequest", function(src, _, callId, accept)
    if not callId or not Calls[callId] then
        debugprint("answerVideoRequest: invalid call id")
        return false
    end
    debugprint("answerVideoRequest", src, callId, accept)
    local call = Calls[callId]
    local other = (call.caller.source == src and call.callee.source) or call.caller.source

    if call.videoCall or not call.answered or not call.videoRequested then
        return false
    end

    call.videoRequested = false
    call.videoCall = (true == accept)
    TriggerClientEvent("phone:phone:videoRequestAnswered", other, accept)
    return true
end)

BaseCallback("stopVideoCall", function(src, _, callId)
    if not callId or not Calls[callId] then
        debugprint("stopVideoCall: invalid call id")
        return false
    end
    local call = Calls[callId]
    local other = (call.caller.source == src and call.callee.source) or call.caller.source
    if not (call.videoCall and call.answered) then return false end

    call.videoCall = false
    TriggerClientEvent("phone:phone:stopVideoCall", src)
    TriggerClientEvent("phone:phone:stopVideoCall", other)
    return true
end)



local function EndCall(src, cb)
    local inCall, callId = isPlayerInAnyCall(src)
    debugprint("^5EndCall^7:", src, inCall, callId)
    if not (inCall and callId and Calls[callId]) then
        if cb then cb(false) end
        debugprint("^5EndCall^7: not in call/invalid callId")
        return false
    end

    local call = Calls[callId]
    local callerSrc = call.caller.source
    local calleeSrc = call.callee.source

    if calleeSrc then
        debugprint("^5EndCall^7: ending call for callee", callId, calleeSrc)
        TriggerClientEvent("phone:phone:endCall", calleeSrc)
        TriggerClientEvent("phone:phone:removeVoiceTarget", -1, calleeSrc, true)
        TriggerClientEvent("phone:phone:removeVoiceTarget", -1, callerSrc, true)
        TriggerClientEvent("phone:phone:setCallEffect", calleeSrc, callerSrc, false)
        TriggerClientEvent("phone:phone:setCallEffect", callerSrc, calleeSrc, false)
    elseif call.company then
        for _, empSrc in ipairs(GetEmployees(call.company)) do
            if not isPlayerInAnyCall(empSrc) and not CompanyCallsDisabled[empSrc] then
                TriggerClientEvent("phone:phone:endCall", empSrc, callId)
            end
        end
    end

    if callerSrc then
        debugprint("^5EndCall^7: ending call for caller", callId, callerSrc)
        TriggerClientEvent("phone:phone:endCall", callerSrc)
    end

    if callerSrc then
        local st = Player(callerSrc)
        if st then
            st = st.state
            st.onCallWith = nil
            st.speakerphone = false
            st.mutedCall = false
            st.otherMutedCall = false
            st.callAnswered = false
        end
    end

    if calleeSrc then
        local st = Player(calleeSrc)
        if st then
            st = st.state
            st.onCallWith = nil
            st.speakerphone = false
            st.mutedCall = false
            st.otherMutedCall = false
            st.callAnswered = false
        end
    end

    
    local callerNear = call.caller.nearby
    local calleeNear = call.callee.nearby

    if callerNear and calleeSrc then
        for _, p in ipairs(callerNear) do
            TriggerClientEvent("phone:phone:removeVoiceTarget", calleeSrc, p, true)
            TriggerClientEvent("phone:phone:removeVoiceTarget", p, calleeSrc, true)
        end
    end

    if calleeNear and callerSrc then
        for _, p in ipairs(calleeNear) do
            TriggerClientEvent("phone:phone:removeVoiceTarget", callerSrc, p, true)
            TriggerClientEvent("phone:phone:removeVoiceTarget", p, callerSrc, true)
        end
    end

    
    if not call.company then
        local duration = os.time() - call.started
        local equipped = GetEquippedPhoneNumber(src)
        logCall(call.caller.number, call.callee.number, duration, call.answered, call.hideCallerId, equipped)
    end

    TriggerEvent("lb-phone:callEnded", call)

    Log("Calls", call.caller.source, "info",
        L("BACKEND.LOGS.CALL_ENDED"),
        L("BACKEND.LOGS.CALL_DESCRIPTION"), {
            duration = (os.time() - call.started),
            caller = FormatNumber(call.caller.number),
            callee = (call.callee.number and FormatNumber(call.callee.number)) or call.company,
            answered = call.answered
        }
    )

    Calls[callId] = nil
    if cb then cb(true) end
    return true
end

RegisterNetEvent("phone:endCall", function()
    EndCall(source)
end)

exports("EndCall", EndCall)
exports("IsInCall", isPlayerInAnyCall)



BaseCallback("getRecentVoicemails", function(_, number, page)
    local sql = [[
        SELECT id,
               IF(hide_caller_id, NULL, caller) AS `number`,
               url, duration, hide_caller_id AS hideCallerId, `timestamp`
        FROM phone_phone_voicemail
        WHERE callee = ?
        ORDER BY `timestamp` DESC
        LIMIT ?, ?
    ]]
    local offset = (page or 0) * 25
    return MySQL.query.await(sql, { number, offset, 25 })
end, {})

BaseCallback("deleteVoiceMail", function(_, number, id)
    local affected = MySQL.update.await("DELETE FROM phone_phone_voicemail WHERE id = ? AND callee = ?", { id, number })
    return affected > 0
end)

BaseCallback("sendVoicemail", function(_, callerNumber, data)
    MySQL.insert.await(
        "INSERT INTO phone_phone_voicemail (caller, callee, url, duration, hide_caller_id) VALUES (@caller, @callee, @url, @duration, @hide)",
        {
            ["@caller"] = callerNumber,
            ["@callee"] = data.number,
            ["@url"] = data.src,
            ["@duration"] = data.duration,
            ["@hide"] = (true == data.hideCallerId)
        }
    )
    SendNotification(data.number, { app = "Phone", title = L("BACKEND.CALLS.NEW_VOICEMAIL") })
    return true
end)


exports("CreateCall", function(caller, calleeOrCompany, options)
    assert(type(caller) == "table", "caller must be a table")
    assert(type(caller.source) == "number", "caller.source must be a number")
    assert(type(caller.phoneNumber) == "string", "caller.phoneNumber must be a string")
    assert(type(calleeOrCompany) == "string", "callee/options.company must be a string")
    options = options or {}
    assert(type(options) == "table", "options must be a table or nil")

    local callerSrc = caller.source
    local callerNumber = caller.phoneNumber

    if not GetPlayerName(callerSrc) then
        return debugprint("CreateCall: callerSrc is not a valid player")
    end

    if options.requirePhone then
        if IsPhoneDead(callerNumber) or not HasPhoneItem(callerSrc, callerNumber) then
            return debugprint("CreateCall: caller does not have a phone")
        end
    end

    if isPlayerInAnyCall(callerSrc) then
        return debugprint("CreateCall: caller is already in a call")
    end

    local callId = generateCallId()
    local call = {
        started = os.time(),
        answered = false,
        videoCall = false,
        hideCallerId = (true == options.hideNumber),
        callId = callId,
        caller = { source = callerSrc, number = callerNumber },
        exportCall = true
    }

    if options.company then
        if not Config.Companies.Enabled then
            debugprint("company calls are disabled in config")
            return
        end

        local validCompany, label = false, options.company
        if Config.Companies.Contacts[options.company] then
            label = Config.Companies.Contacts[options.company].name
            validCompany = true
        else
            for _, svc in ipairs(Config.Companies.Services) do
                if svc.job == options.company then
                    validCompany = true
                    label = svc.name
                    break
                end
            end
        end
        if not validCompany then
            debugprint("invalid company")
            return
        end

        call.company = options.company
        call.callee = {}

        local employees = GetEmployees(options.company)
        for _, empSrc in ipairs(employees) do
            if (not isPlayerInAnyCall(empSrc)) and empSrc ~= callerSrc and not CompanyCallsDisabled[empSrc] then
                TriggerClientEvent("phone:phone:setCall", empSrc, {
                    callId = callId,
                    number = callerNumber,
                    company = options.company,
                    companylabel = label
                })
            end
        end
    else
        local calleeSrc = GetSourceFromNumber(calleeOrCompany)
        if not calleeSrc then return debugprint("CreateCall: calleeSrc is not a valid player") end
        if isPlayerInAnyCall(calleeSrc) then return debugprint("CreateCall: caller or callee is in call") end
        call.callee = { source = calleeSrc, number = calleeOrCompany }

        TriggerClientEvent("phone:phone:setCall", calleeSrc, {
            callId = callId,
            number = callerNumber,
            hideCallerId = (true == options.hideNumber)
        })
    end

    Calls[callId] = call
    TriggerEvent("lb-phone:newCall", call)
    TriggerClientEvent("phone:phone:enableExportCall", callerSrc)
    return callId
end)

exports("GetCall", function(callId)
    return Calls[callId]
end)

exports("AddContact", function(ownerNumber, data)
    assert(type(ownerNumber) == "string", "phoneNumber must be a string")
    assert(type(data) == "table", "data must be a table")
    local success = CreateContact(ownerNumber, data)
    debugprint("AddContact: success", success)
    local src = GetSourceFromNumber(ownerNumber)
    if src and success then
        TriggerClientEvent("phone:phone:contactAdded", src, data)
    end
end)


exports("EndCall", EndCall)
exports("IsInCall", isPlayerInAnyCall)



RegisterNetEvent("phone:phone:toggleMute", function(muted)
    local src = source
    local st = Player(src).state
    st.mutedCall = (true == muted)

    local inCall, callId = isPlayerInAnyCall(src)
    if inCall then
        local call = Calls[callId]
        local other = (call.caller.source == src and call.callee.source) or call.caller.source
        Player(other).state.otherMutedCall = (true == muted)
    end
end)

RegisterNetEvent("phone:phone:toggleSpeaker", function(enabled)
    local st = Player(source).state
    st.speakerphone = (true == enabled)
end)

RegisterNetEvent("phone:phone:enteredCallProximity", function(targetSrc)
    local src = source
    local inCall, callId = isPlayerInAnyCall(targetSrc)
    if not inCall then return end

    local call = Calls[callId]
    if not call.answered then return end

    local isCaller = (call.caller.source == targetSrc)
    local nearby = isCaller and call.caller.nearby or call.callee.nearby
    local other = isCaller and (call.callee.source or call.caller.source) or (call.caller.source or call.callee.source)

    TriggerClientEvent("phone:phone:addVoiceTarget", other, src, true, true)
    TriggerClientEvent("phone:phone:addVoiceTarget", src, other, false, true)

    if table.contains(nearby, src) then return end
    nearby[#nearby + 1] = src
end)

RegisterNetEvent("phone:phone:leftCallProximity", function(targetSrc)
    local src = source
    local inCall, callId = isPlayerInAnyCall(targetSrc)
    if not inCall then return end

    local call = Calls[callId]
    if not call.answered then return end

    local isCaller = (call.caller.source == targetSrc)
    local nearby = isCaller and call.caller.nearby or call.callee.nearby
    local found, idx = table.contains(nearby, src)

    if found then
        local other = isCaller and (call.callee.source or call.caller.source) or (call.caller.source or call.callee.source)
        TriggerClientEvent("phone:phone:removeVoiceTarget", other, src, true)
        TriggerClientEvent("phone:phone:removeVoiceTarget", src, other, true)
        table.remove(nearby, idx)
    end
end)

RegisterNetEvent("phone:phone:listenToPlayer", function(otherSrc)
    local src = source
    debugprint(src, "started listening to", otherSrc)
    TriggerClientEvent("phone:phone:addVoiceTarget", src, otherSrc, true, true)
    TriggerClientEvent("phone:phone:addVoiceTarget", otherSrc, src, false, true)
end)

RegisterNetEvent("phone:phone:stopListeningToPlayer", function(otherSrc)
    local src = source
    debugprint(src, "stopped listening to", otherSrc)
    TriggerClientEvent("phone:phone:removeVoiceTarget", src, otherSrc)
    TriggerClientEvent("phone:phone:removeVoiceTarget", otherSrc, src)
end)


AddEventHandler("playerDropped", function()
    local src = source
    CompanyCallsDisabled[src] = nil
    EndCall(src)
end)
