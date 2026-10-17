

-- Cleaned from decompiled output: L#_# temporaries renamed, goto-based ternaries
-- turned into `and/or`, and unrolled multi-return copies (L3_2[1]=L4_2 ...) collapsed
-- into plain table literals.

local resourceName = GetCurrentResourceName()

local MARKER       = '[OXLYN-NOTIFYKIT BRIDGE]'
local LINE_TAG     = '-- ' .. MARKER                  -- tags a bridge line inserted on its own line
local BLOCK_TAG    = '--[=[' .. MARKER .. ']=]'       -- tags a bridge inserted inline after a header
local BACKUP_SUFFIX = '.oxlyn-backup'
local COMMAND      = (Config.Commands and Config.Commands.installer) or 'notifykit'

Installer = {}

-- ---------------------------------------------------------------------------
-- Targets
-- ---------------------------------------------------------------------------

local Targets = {
    esx = {
        label = 'ESX',
        resource = 'es_extended',
        file = 'client/functions.lua',
        functions = {
            { name = 'ESX.ShowNotification', export = 'ESX', params = 'message, notifyType, length, title, position' },
            { name = 'ESX.ShowAdvancedNotification', export = 'ESXAdvanced', optional = true,
              params = 'sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex' },
        },
    },
    qbcore = {
        label = 'QBCore',
        resource = 'qb-core',
        file = 'client/functions.lua',
        functions = {
            { name = 'QBCore.Functions.Notify', export = 'QBCore', params = 'text, texttype, length, icon' },
        },
    },
    oxlib = {
        label = 'ox_lib',
        resource = 'ox_lib',
        file = 'resource/interface/client/notify.lua',
        functions = {
            { name = 'lib.notify', export = 'OxLib', params = 'data' },
        },
    },
}

local Order = { 'esx', 'qbcore', 'oxlib' }

local Aliases = {
    es_extended = 'esx', ['es-extended'] = 'esx',
    qb = 'qbcore', ['qb-core'] = 'qbcore', qbcore = 'qbcore',
    ox = 'oxlib', ox_lib = 'oxlib', ['ox-lib'] = 'oxlib', lib = 'oxlib',
}

Installer.Targets = Targets
Installer.Order = Order

-- ---------------------------------------------------------------------------
-- String / code helpers
-- ---------------------------------------------------------------------------

local function escapePattern(str)
    return (str:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%0'))
end

local function luaQuote(str)
    return "'" .. str:gsub('\\', '\\\\'):gsub("'", "\\'") .. "'"
end

-- The line injected into the target function: forwards to our export when we are running
local function buildBridgeCall(fn, params)
    local res = luaQuote(resourceName)
    return ('if GetResourceState(%s) == \'started\' then return exports[%s]:%s(%s) end'):format(res, res, fn.export, params)
end

-- Matches an inline bridge (the BLOCK_TAG form) so it can be stripped again
local INLINE_BRIDGE_PATTERN = " if GetResourceState%b() == 'started' then return exports%b[]:[%w_]+%b() end "
    .. escapePattern(BLOCK_TAG)

-- Turns a raw "(a, b, ...)" parameter list into a clean "a, b, ..." string.
-- Returns nil if the list contains anything but plain identifiers (or a trailing "...").
local function parseParams(inner)
    local cleaned = inner
        :gsub('%-%-%[(=*)%[.-%]%1%]', '')   -- block comments
        :gsub('%-%-[^\n]*', '')             -- line comments
        :gsub('%s+', ' ')
        :gsub('^ ', '')
        :gsub(' $', '')

    if cleaned == '' then return '' end

    local names = {}
    for part in (cleaned .. ','):gmatch('([^,]*),') do
        local name = part:gsub('^%s+', ''):gsub('%s+$', '')
        if name == '...' or name:match('^[%a_][%w_]*$') then
            names[#names + 1] = name
        else
            return nil
        end
    end

    -- "..." is only legal as the last parameter
    for i = 1, #names - 1 do
        if names[i] == '...' then return nil end
    end

    return table.concat(names, ', ')
end

-- Finds every definition of `name` in src ("function name(...)" or "name = function(...)")
local function findHeaders(src, name)
    local esc = escapePattern(name)
    local patterns = {
        '^([ \t]*)function[ \t]+' .. esc .. '[ \t]*(%b())',
        '^([ \t]*)' .. esc .. '[ \t]*=[ \t]*function[ \t]*(%b())',
    }

    local headers = {}
    local pos = 1
    while pos <= #src do
        for _, pattern in ipairs(patterns) do
            local _, close, indent, parens = src:find(pattern, pos)
            if close then
                local inner = parens:sub(2, -2)
                headers[#headers + 1] = {
                    lineStart = pos,
                    close = close,
                    indent = indent,
                    inner = inner,
                    params = parseParams(inner),
                }
                break
            end
        end

        local nl = src:find('\n', pos, true)
        if not nl then break end
        pos = nl + 1
    end

    return headers
end

-- Returns the rest of the header's line (after the closing paren) and the index of its newline
local function restOfHeaderLine(src, header)
    local nl = src:find('\n', header.close + 1, true)
    local rest = src:sub(header.close + 1, (nl or (#src + 1)) - 1):gsub('\r$', '')
    return rest, nl
end

local function isBlankOrComment(line)
    if line:match('^%s*$') then return true end
    return line:match('^%s*%-%-') ~= nil
end

-- Is this header already carrying one of our bridges?
local function isHeaderPatched(src, header)
    local rest, nl = restOfHeaderLine(src, header)
    if rest:find(BLOCK_TAG, 1, true) then return true end
    if not nl then return false end

    local nextNl = src:find('\n', nl + 1, true)
    local nextLine = src:sub(nl + 1, (nextNl or (#src + 1)) - 1)
    return nextLine:find(LINE_TAG, 1, true) ~= nil
end

-- Indent of the function body, so the injected line matches the file's style
local function getBodyIndent(src, header, headerEnd)
    local pos = headerEnd + 1
    while pos <= #src do
        local nl = src:find('\n', pos, true)
        local line = src:sub(pos, (nl or (#src + 1)) - 1):gsub('\r$', '')

        if line:match('%S') then
            local indent = line:match('^[ \t]*')
            if #indent > #header.indent then return indent end
            break
        end

        if not nl then break end
        pos = nl + 1
    end

    return header.indent .. (header.indent:find('\t') and '\t' or '    ')
end

-- Injects the bridge call into every matching function in src. Returns patched source and insert count.
local function patchSource(src, target)
    local inserts = {}

    for _, fn in ipairs(target.functions) do
        for _, header in ipairs(findHeaders(src, fn.name)) do
            if header.params then
                local call = buildBridgeCall(fn, header.params)
                local rest, nl = restOfHeaderLine(src, header)

                if nl and isBlankOrComment(rest) then
                    -- Header ends its line: insert the bridge as the first body line
                    local eol = (src:sub(nl - 1, nl - 1) == '\r') and '\r\n' or '\n'
                    inserts[#inserts + 1] = {
                        at = nl,
                        text = getBodyIndent(src, header, nl) .. call .. ' ' .. LINE_TAG .. eol,
                    }
                else
                    -- Body starts on the same line: insert inline right after the parameter list
                    inserts[#inserts + 1] = { at = header.close, text = ' ' .. call .. ' ' .. BLOCK_TAG }
                end
            end
        end
    end

    -- Apply back-to-front so earlier offsets stay valid
    table.sort(inserts, function(a, b) return a.at > b.at end)
    for _, insert in ipairs(inserts) do
        src = src:sub(1, insert.at) .. insert.text .. src:sub(insert.at + 1)
    end

    return src, #inserts
end

-- Strips every bridge we injected. Returns cleaned source and number of bridges removed.
local function unpatchSource(src)
    if not src:find(MARKER, 1, true) then
        return src, 0
    end

    local removed
    src, removed = src:gsub(INLINE_BRIDGE_PATTERN, '')

    local kept = {}
    local pos, len = 1, #src
    while pos <= len do
        local nl = src:find('\n', pos, true)
        local stop = nl or len
        local line = src:sub(pos, stop)

        if line:find(LINE_TAG, 1, true) then
            removed = removed + 1
        else
            kept[#kept + 1] = line
        end

        pos = stop + 1
    end

    return table.concat(kept), removed
end

-- Does the code still compile? (checked before/after patching so we never write a broken file)
local function compiles(code)
    local ok, fn = pcall(load, code, '=notifykit-check', 't', {})
    return ok and fn ~= nil
end

Installer.FindHeaders = findHeaders
Installer.Patch = patchSource
Installer.Unpatch = unpatchSource

-- ---------------------------------------------------------------------------
-- Resource / file helpers
-- ---------------------------------------------------------------------------

local function resourceExists(name)
    local ok, found = pcall(function()
        for i = 0, GetNumResources() - 1 do
            if GetResourceByFindIndex(i) == name then return true end
        end
        return false
    end)
    return ok and found == true
end

local function readFile(resource, file)
    local ok, data = pcall(LoadResourceFile, resource, file)
    if ok and type(data) == 'string' and data ~= '' then
        return data
    end
    return nil
end

local function writeFile(resource, file, content)
    local ok, result = pcall(SaveResourceFile, resource, file, content, -1)
    return ok and result ~= false
end

local function resolveTarget(name)
    if type(name) ~= 'string' then return nil end
    name = name:lower()
    name = Aliases[name] or name
    return Targets[name] and name or nil
end

-- ---------------------------------------------------------------------------
-- Target inspection
-- ---------------------------------------------------------------------------

local function inspectTarget(key)
    local target = Targets[key]
    local info = {
        key = key,
        label = target.label,
        resource = target.resource,
        file = target.file,
        functions = {},
        bridges = 0,
    }

    if not resourceExists(target.resource) then
        info.state, info.why = 'missing', 'resource'
        return info
    end

    local src = readFile(target.resource, target.file)
    if not src then
        info.state, info.why = 'missing', 'file'
        return info
    end

    info.src = src
    info.clean, info.bridges = unpatchSource(src)
    info.backup = readFile(target.resource, target.file .. BACKUP_SUFFIX) ~= nil

    local unsupported = false
    local totalFound, totalBridged = 0, 0

    for _, fn in ipairs(target.functions) do
        local found, bridged, firstParams = 0, 0, nil

        for _, header in ipairs(findHeaders(src, fn.name)) do
            if header.params then
                found = found + 1
                firstParams = firstParams or header.params
                if isHeaderPatched(src, header) then bridged = bridged + 1 end
            end
        end

        info.functions[#info.functions + 1] = {
            name = fn.name,
            export = fn.export,
            found = found,
            bridged = bridged,
            params = firstParams or fn.params,
            optional = fn.optional == true,
        }

        if found == 0 and not fn.optional then unsupported = true end
        totalFound = totalFound + found
        totalBridged = totalBridged + bridged
    end

    if unsupported then
        info.state = 'unsupported'
    elseif totalFound > 0 and totalBridged == totalFound then
        info.state = 'installed'
    else
        info.state = 'available'
    end

    return info
end

-- Manual-install instructions shown when auto-patching isn't possible
local function buildManualHints(key)
    local target = Targets[key]
    local info = inspectTarget(key)
    local lines = {}

    for i, fn in ipairs(target.functions) do
        local fnInfo = info.functions[i]
        lines[#lines + 1] = { text = _U('in_manual', fn.name, target.resource, target.file), level = 'hint' }
        lines[#lines + 1] = {
            text = '    ' .. buildBridgeCall(fn, (fnInfo and fnInfo.params) or fn.params) .. ' ' .. LINE_TAG,
            level = 'code',
        }
    end

    return lines
end

local function message(level, key, ...)
    return { text = _U(key, ...), level = level }
end

local function skipped(msg)
    msg.skip = true
    return msg
end

-- ---------------------------------------------------------------------------
-- Installer API
-- ---------------------------------------------------------------------------

function Installer.Status()
    local status = {}
    for _, key in ipairs(Order) do
        local ok, info = pcall(inspectTarget, key)
        status[key] = (ok and info.state) or 'missing'
    end
    return status
end

function Installer.Details()
    local details = {}
    for _, key in ipairs(Order) do
        local ok, info = pcall(inspectTarget, key)
        if ok then
            info.clean, info.src = nil, nil   -- don't ship whole files around
            details[#details + 1] = info
        end
    end
    return details
end

-- Returns: success, messages, changedFiles
function Installer.Install(name)
    local key = resolveTarget(name)
    if not key then
        return false, { message('err', 'in_unknown_target', tostring(name)) }, false
    end

    local target = Targets[key]
    local info = inspectTarget(key)

    if info.state == 'missing' then
        if info.why == 'resource' then
            return false, { skipped(message('info', 'in_missing', target.label, target.resource)) }, false
        end
        return false, { message('err', 'in_missing_file', target.label, target.resource, target.file) }, false
    end

    if info.state == 'unsupported' then
        local msgs = { message('err', 'in_unsupported', target.label, target.functions[1].name, target.resource, target.file) }
        for _, line in ipairs(buildManualHints(key)) do msgs[#msgs + 1] = line end
        return false, msgs, false
    end

    if info.state == 'installed' then
        return true, { message('ok', 'in_already', target.label) }, false
    end

    local patched, count = patchSource(info.clean, target)
    if count == 0 then
        return false, { message('err', 'in_unsupported', target.label, target.functions[1].name, target.resource, target.file) }, false
    end

    -- Never write a file that compiled before but wouldn't after patching
    if compiles(info.clean) and not compiles(patched) then
        return false, { message('err', 'in_compile_failed', target.label, target.file) }, false
    end

    local msgs = {}

    -- Keep a backup of the pristine (unpatched) file
    local backupFile = target.file .. BACKUP_SUFFIX
    local existingBackup = info.backup and readFile(target.resource, backupFile) or nil
    if existingBackup ~= info.clean then
        if writeFile(target.resource, backupFile, info.clean) then
            msgs[#msgs + 1] = message('info', existingBackup and 'in_backup_updated' or 'in_backup_saved',
                target.resource .. '/' .. backupFile)
        end
    end

    if not writeFile(target.resource, target.file, patched) then
        return false, { message('err', 'in_write_failed', target.label, target.resource, target.file) }, false
    end

    -- Read back to confirm the write actually landed
    if readFile(target.resource, target.file) ~= patched then
        return false, { message('err', 'in_verify_failed', target.label, target.resource, target.file) }, true
    end

    table.insert(msgs, 1, message('ok', 'in_installed', target.label, target.resource, target.file, count))
    msgs[#msgs + 1] = message('hint', 'in_restart', target.resource)
    return true, msgs, true
end

function Installer.Uninstall(name)
    local key = resolveTarget(name)
    if not key then
        return false, { message('err', 'in_unknown_target', tostring(name)) }, false
    end

    local target = Targets[key]

    if not resourceExists(target.resource) then
        return false, { skipped(message('info', 'in_missing', target.label, target.resource)) }, false
    end

    local src = readFile(target.resource, target.file)
    if not src then
        return false, { message('err', 'in_missing_file', target.label, target.resource, target.file) }, false
    end

    local clean, count = unpatchSource(src)
    if count == 0 then
        return true, { message('ok', 'in_not_installed', target.label) }, false
    end

    if not writeFile(target.resource, target.file, clean) then
        return false, { message('err', 'in_write_failed', target.label, target.resource, target.file) }, false
    end

    if readFile(target.resource, target.file) ~= clean then
        return false, { message('err', 'in_verify_failed', target.label, target.resource, target.file) }, true
    end

    return true, {
        message('ok', 'in_uninstalled', target.label, target.resource, target.file),
        message('hint', 'in_restart', target.resource),
    }, true
end

function Installer.Restore(name, mode)
    local key = resolveTarget(name)
    if not key then
        return false, { message('err', 'in_unknown_target', tostring(name)) }, false
    end

    local target = Targets[key]

    if not resourceExists(target.resource) then
        return false, { skipped(message('info', 'in_missing', target.label, target.resource)) }, false
    end

    local backupFile = target.file .. BACKUP_SUFFIX
    local backup = readFile(target.resource, backupFile)
    if not backup then
        return false, { skipped(message('err', 'in_no_backup', target.label, target.resource .. '/' .. backupFile)) }, false
    end

    local current = readFile(target.resource, target.file)
    if current == backup then
        return true, { message('ok', 'in_restore_same', target.label) }, false
    end

    -- The live file has changed beyond our patches (e.g. framework update): require "force"
    local currentDiffers = current ~= nil and (unpatchSource(current)) ~= backup
    if currentDiffers and mode ~= 'force' then
        return false, {
            message('err', 'in_restore_refused', target.label, target.resource),
            message('hint', 'in_restore_force', COMMAND, key),
        }, false
    end

    if not writeFile(target.resource, target.file, backup) then
        return false, { message('err', 'in_write_failed', target.label, target.resource, target.file) }, false
    end

    local msgs = { message('ok', 'in_restored', target.label, target.resource, target.file, backupFile) }
    if currentDiffers then
        msgs[#msgs + 1] = message('hint', 'in_restore_differs', target.resource)
    end
    msgs[#msgs + 1] = message('hint', 'in_restart', target.resource)
    return true, msgs, true
end

local Actions = {
    install = Installer.Install,
    uninstall = Installer.Uninstall,
    restore = Installer.Restore,
}

-- Runs an action on one target or on "all". Returns: success, messages, changedFiles
function Installer.Run(action, targetArg, mode)
    local handler = Actions[type(action) == 'string' and action:lower() or '']
    if not handler then
        return false, { message('err', 'in_usage', COMMAND) }, false
    end

    local targets
    if type(targetArg) == 'string' and targetArg:lower() == 'all' then
        targets = Order
    else
        local key = resolveTarget(targetArg)
        if not key then
            return false, { message('err', 'in_unknown_target', tostring(targetArg)) }, false
        end
        targets = { key }
    end

    local allOk, anyChanged = true, false
    local messages = {}
    local processed = 0

    for _, key in ipairs(targets) do
        local called, ok, msgs, changed = pcall(handler, key, mode)
        if not called then
            -- handler threw: `ok` holds the error
            msgs = { { text = Targets[key].label .. ': ' .. tostring(ok), level = 'err' } }
            ok, changed = false, false
        end

        -- When running "all", a target that simply isn't applicable shouldn't fail the whole run
        local soft = #targets > 1 and not ok
        if not ok and not soft then allOk = false end
        if not soft then processed = processed + 1 end
        if changed then anyChanged = true end

        for _, msg in ipairs(msgs) do
            if soft and msg.level == 'err' then msg.level = 'info' end
            messages[#messages + 1] = msg
        end
    end

    if processed == 0 then allOk = false end

    -- Qbox ships as qbx_core and is not auto-patched: point the user at the manual route
    if #targets > 1 and action:lower() == 'install' and Targets.qbcore
        and not resourceExists('qb-core') and resourceExists('qbx_core') then
        messages[#messages + 1] = message('hint', 'in_qbox_hint')
    end

    return allOk, messages, anyChanged
end

-- ---------------------------------------------------------------------------
-- Console / chat output
-- ---------------------------------------------------------------------------

local LEVEL_COLORS = { ok = '^2', err = '^1', info = '^7', hint = '^3', code = '^5' }
local STATE_COLORS = { installed = '^2', available = '^3', missing = '^8', unsupported = '^1' }

local function buildStatusMessages()
    local lines = { { text = _U('in_title'), level = 'info' } }

    for _, info in ipairs(Installer.Details()) do
        local location = ('%s/%s'):format(info.resource, info.file)

        local counts = {}
        for _, fn in ipairs(info.functions) do
            if fn.found > 0 then
                counts[#counts + 1] = ('%s %d/%d'):format(fn.name, fn.bridged, fn.found)
            end
        end

        local stateText = _U('in_state_' .. info.state)
        local suffix = #counts > 0 and ('  (' .. table.concat(counts, ', ') .. ')') or ''

        lines[#lines + 1] = {
            text = ('  %-7s %-46s %s%s^7%s'):format(info.label, location, STATE_COLORS[info.state] or '^7', stateText, suffix),
            level = 'raw',
            plain = ('%s: %s'):format(info.label, stateText),   -- colour-free version for the in-game feedback
        }

        if info.state == 'unsupported' or info.state == 'available' then
            for _, line in ipairs(buildManualHints(info.key)) do
                lines[#lines + 1] = line
            end
        end
    end

    lines[#lines + 1] = { text = _U('in_usage', COMMAND), level = 'hint' }
    return lines
end

-- Console output for the command (this is the command's actual result, not debug logging)
local function printMessages(messages)
    for _, msg in ipairs(messages) do
        if msg.level == 'raw' then
            print('^5[OXLYN-NOTIFYKIT]^7 ' .. msg.text)
        else
            print(('^5[OXLYN-NOTIFYKIT]^7 %s%s^7'):format(LEVEL_COLORS[msg.level] or '^7', msg.text))
        end
    end
end

-- Plain-text version for the in-game feedback event (no colour codes, no code snippets)
local function toPlainText(messages)
    local out = {}
    for _, msg in ipairs(messages) do
        if msg.level ~= 'code' then
            local text = (msg.plain or msg.text):gsub('%^%d', ''):gsub('^%s+', '')
            out[#out + 1] = text
        end
    end
    return table.concat(out, '\n')
end

-- ---------------------------------------------------------------------------
-- Permissions + status cache
-- ---------------------------------------------------------------------------

-- Returns true when the player is DENIED
local function denyIfNotAdmin(src)
    if NKServer and NKServer.Denied then
        return NKServer.Denied(src)
    end

    if Bridge.IsAdmin(src) then
        return false
    end

    TriggerClientEvent('oxlyn-notifykit:feedback', src, 'msg_no_permission', 'error')
    return true
end

local statusCache, statusCachedAt = nil, 0

local function getInstallerStatus()
    local now = GetGameTimer()
    if not statusCache or (now - statusCachedAt) > 2000 then
        statusCache = Installer.Status()
        statusCachedAt = now
    end
    return statusCache
end

local function execute(src, action, target, mode)
    local ok, messages, changed = Installer.Run(action, target, mode)

    if changed then statusCache = nil end

    if src ~= 0 then
        table.insert(messages, 1, {
            text = _U('in_done_by', Bridge.GetName(src), action, tostring(target)),
            level = 'info',
        })
    end

    printMessages(messages)
    return ok, messages, changed
end

-- ---------------------------------------------------------------------------
-- Command + events
-- ---------------------------------------------------------------------------

RegisterCommand(COMMAND, function(src, args)
    if src ~= 0 and denyIfNotAdmin(src) then return end

    local sub = type(args[1]) == 'string' and args[1]:lower() or 'status'
    local target = args[2]
    local ok, messages = true, nil

    if sub == 'status' then
        messages = buildStatusMessages()
        printMessages(messages)
    elseif Actions[sub] then
        if type(target) ~= 'string' or target == '' then
            ok = false
            messages = { message('err', 'in_usage', COMMAND) }
            printMessages(messages)
        else
            local mode = type(args[3]) == 'string' and args[3]:lower() or nil
            ok, messages = execute(src, sub, target, mode)
        end
    else
        ok = false
        messages = { message('err', 'in_usage', COMMAND) }
        printMessages(messages)
    end

    if src ~= 0 then
        TriggerClientEvent('oxlyn-notifykit:feedbackRaw', src, toPlainText(messages), ok and 'success' or 'error')
        TriggerClientEvent('oxlyn-notifykit:installerStatus', src, getInstallerStatus())
    end
end, false)

RegisterNetEvent('oxlyn-notifykit:installerStatus', function()
    local src = source
    TriggerClientEvent('oxlyn-notifykit:installerStatus', src, getInstallerStatus())
end)

RegisterNetEvent('oxlyn-notifykit:installer', function(action, target)
    local src = source
    if denyIfNotAdmin(src) then return end

    if type(action) ~= 'string' or not Actions[action:lower()] or type(target) ~= 'string' then
        return
    end

    local ok, messages = execute(src, action, target)
    statusCache = nil

    TriggerClientEvent('oxlyn-notifykit:installerStatus', src, getInstallerStatus())
    TriggerClientEvent('oxlyn-notifykit:feedbackRaw', src, toPlainText(messages), ok and 'success' or 'error')
end)

-- Hint in the server console for any framework that can be bridged but isn't yet
CreateThread(function()
    Wait(2500)

    for _, key in ipairs(Order) do
        local ok, info = pcall(inspectTarget, key)
        if ok and info.state == 'available' then
            Utils.Info('%s', _U('in_hint_available', info.label, COMMAND .. ' install ' .. key))
        end
    end
end)

-- ---------------------------------------------------------------------------
-- oxlyn-notify compatibility exports (only when the real oxlyn-notify isn't running)
-- ---------------------------------------------------------------------------

local OXLYN_NOTIFY = 'oxlyn-notify'

local function isOxlynNotifyRunning()
    local ok, running = pcall(function()
        for i = 0, GetNumResources() - 1 do
            local name = GetResourceByFindIndex(i)
            if name == OXLYN_NOTIFY and name ~= resourceName then
                return GetResourceState(name) == 'started'
            end
        end
        return false
    end)
    return ok and running == true
end

-- Builds the notification payload, copying any extra non-function options
local function buildPayload(notifyType, title, msg, duration, extra)
    local payload = {}

    if type(extra) == 'table' then
        for k, v in pairs(extra) do
            if type(v) ~= 'function' then payload[k] = v end
        end
    end

    payload.duration = tonumber(duration)
    payload.message = msg
    payload.title = title
    payload.type = notifyType
    return payload
end

-- Registers an export on behalf of oxlyn-notify; it stays inert if the real resource is running
local function registerCompatExport(name, handler)
    AddEventHandler(('__cfx_export_%s_%s'):format(OXLYN_NOTIFY, name), function(setCallback)
        if isOxlynNotifyRunning() then return end

        setCallback(function(...)
            local ok, result = pcall(handler, ...)
            if ok then return result end

            Utils.Warn('%s', _U('cp_error', OXLYN_NOTIFY .. ':' .. name, tostring(result)))
            return false
        end)
    end)
end

local compat = Config.Compat or {}

if compat.oxlyn_notify ~= false and not isOxlynNotifyRunning() then
    registerCompatExport('ShowNotification', function(target, notifyType, title, msg, duration, extra)
        target = tonumber(target)
        if not target or target <= 0 then return false end
        return NKServer.Notify(target, buildPayload(notifyType, title, msg, duration, extra))
    end)

    registerCompatExport('ShowNotificationToAll', function(notifyType, title, msg, duration, extra)
        return NKServer.Notify(-1, buildPayload(notifyType, title, msg, duration, extra))
    end)

    registerCompatExport('ClearNotifications', function(target)
        target = tonumber(target)
        if not target or target <= 0 then return false end
        return NKServer.Clear(target)
    end)

    registerCompatExport('ClearAllNotifications', function()
        return NKServer.Clear(-1)
    end)
end

