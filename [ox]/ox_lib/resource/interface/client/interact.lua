--[[
    Interaction points: NoPixel V style "[E] LABEL" prompts drawn in the world.

    Walk near a point to see its ring, look at it (centre of the screen) when close
    enough to get the prompt, press E. Several options on one point: scroll with the
    arrow keys or the mouse wheel. Drawn with game sprites (no NUI), so prompts stay
    locked to the world. Settings: interact.lua; colours: theme.lua.

    lib.addInteraction({ coords = vec3(...), options = {...}, distance?, interactDst?, name? })
    lib.addLocalEntityInteraction({ entity = handle, offset?, ... })
    lib.addEntityInteraction({ netId = netId or entity, offset?, ... })
    lib.addEntityBoneInteraction({ entity = handle, bone = 'boot', offset?, ... })
    lib.addModelInteraction({ models = { 'prop_atm_01', ... } | modelData = { { model, offset } },
                              coords? = vec3 or list, radius? = 3.0, offset?, ... })
    lib.addGlobalVehicleInteraction / lib.addGlobalPedInteraction / lib.addGlobalPlayerInteraction({ bone?, offset?, ... })
    lib.removeInteraction(id), lib.removeInteractionOption(id, name), lib.updateInteraction(id, options),
    lib.removeInteractionByEntity(entity), lib.disableInteractions(state)

    Option: { label, name?, canInteract?(entity, coords, args), action?(entity, coords, args) |
              event? | serverEvent? | command?, args? }
    event / serverEvent receive { entity, coords, args, name }; command runs ExecuteCommand(command).
]]

local settings = {}

do
    local file = LoadResourceFile(cache.resource, 'interact.lua')
    local chunk = file and load(file, '@@ox_lib/interact.lua')
    local ok, result = pcall(chunk or function() end)

    if ok and type(result) == 'table' then
        settings = result
    else
        lib.print.warn('interact.lua could not be loaded, using the default interaction settings')
    end

    local defaults = {
        enabled = true, key = 'E', control = 38, uppercase = true, textSize = 13, keySize = 20, dotSize = 15,
        rowSpacing = 24, dimmedAlpha = 140, shadow = true, crosshair = true, hoverRadius = 0.06,
        defaultDistance = 8.0, defaultInteractDst = 1.2,
        disable = { dead = true, nuiFocus = true, inVehicle = true, cuffed = true },
        replaceTextUI = { enabled = false, anchor = 'world', connectors = { 'to' } },
    }

    for k, v in pairs(defaults) do
        if settings[k] == nil then settings[k] = v end
    end
end

if cache.game ~= 'fivem' then return end

---------------------------------------------------------------------------------------------------
-- Colours (theme.lua) and textures
---------------------------------------------------------------------------------------------------

-- '#rgb', '#rrggbb', '#rrggbbaa', 'rgb(r, g, b)' or 'rgba(r, g, b, a)' -> { r, g, b, a }
local function parseColour(value, fallback)
    if type(value) ~= 'string' then return fallback end
    value = value:gsub('%s', ''):lower()

    local hex = value:match('^#(%x+)$')
    if hex then
        if #hex == 3 then hex = hex:gsub('.', '%1%1') end
        if #hex == 6 then hex = hex .. 'ff' end
        if #hex == 8 then
            return { tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), tonumber(hex:sub(7, 8), 16) }
        end
    end

    local r, g, b, a = value:match('^rgba?%((%d+),(%d+),(%d+),?([%d%.]*)%)$')
    if r then
        return { tonumber(r), tonumber(g), tonumber(b), a ~= '' and math.floor(tonumber(a) * 255 + 0.5) or 255 }
    end

    return fallback
end

local theme = loadUiTheme and loadUiTheme() or {}
local colours = {
    text = parseColour(theme.text, { 255, 255, 255, 255 }),
    key = parseColour(theme.key, { 255, 255, 255, 255 }),
    keyText = parseColour(theme.keyText, { 11, 12, 14, 255 }),
}

local TXD = 'ox_lib_interact'

local font = json.decode(LoadResourceFile(cache.resource, 'assets/interact/font.json') or '{}')
local glyphs = font.glyphs or {}
local fallbackGlyph = glyphs['?'] or { x = 0, y = 0, w = 0, xoff = 0, adv = 0 }

--[[
    The alphabet is in more than one picture.

    One picture of it could not hold Chinese: the first filled up part
    way through, which is why a traditional label used to come out as
    question marks. So the rest of the characters are in a second
    picture beside it. Every glyph says which one it is in, and the
    pages say how big each one is -- a texture's own size is what turns
    a position inside it into the fraction DrawSpriteUv wants, so two
    pictures of different heights cannot share one divisor.

    An alphabet with no pages listed is the old single-picture one, and
    still works: everything then falls back to the first page.
]]
local FIRST = 'font'
local PAGES = font.pages or {}

if not PAGES[FIRST] then
    PAGES[FIRST] = { width = font.width, height = font.height }
end

--- Which picture a glyph is in, and how big that picture is.
--- @return string name, number width, number height
local function pageOf(glyph)
    local name = glyph.page or FIRST
    local page = PAGES[name] or PAGES[FIRST]
    return name, page.width, page.height
end

do
    local txd = CreateRuntimeTxd(TXD)

    for _, name in ipairs({ 'key', 'dot', 'crosshair' }) do
        CreateRuntimeTextureFromImage(txd, name, ('assets/interact/%s.png'):format(name))
    end

    -- Whatever pictures the alphabet says it is in, rather than a list
    -- written out here that has to be remembered when one is added.
    for name in pairs(PAGES) do
        CreateRuntimeTextureFromImage(txd, name, ('assets/interact/%s.png'):format(name))
    end
end

---------------------------------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------------------------------

local DrawSprite, DrawSpriteUv, SetDrawOrigin, ClearDrawOrigin = DrawSprite, DrawSpriteUv, SetDrawOrigin, ClearDrawOrigin
local string_gmatch = string.gmatch

--[[
    Walking the text one character at a time, not one byte at a time.

    A Chinese character is three bytes, and reading them singly handed
    the alphabet three pieces of nonsense instead of one letter. The
    pattern is used rather than utf8.codes because a malformed string
    makes that one throw, and a bad label should cost one wrong glyph,
    not the whole prompt.
]]
local UTF8 = utf8.charpattern
local PX = 1 / 1080 -- settings are pixels at 1080p; draw sizes are fractions of the screen height

-- Draws text from the atlas with its left edge at x and its capitals centred on y.
local function drawText(text, x, y, capHeight, aspect, r, g, b, a)
    local k = capHeight / font.capHeight
    -- The top of the line the letters sit on. A Latin cell fills it;
    -- the Chinese ones are shorter and sit further down it, so each
    -- carries its own height and drop.
    local bandTop = y + capHeight * 0.5 - font.ascent * k
    local kx = k / aspect
    local pen = x

    for char in string_gmatch(text, UTF8) do
        local glyph = glyphs[char] or fallbackGlyph

        if glyph.w > 0 then
            local cellH = glyph.h or font.lineHeight
            local drop = glyph.yoff or 0
            local page, pageW, pageH = pageOf(glyph)
            local u, v = glyph.x / pageW, glyph.y / pageH

            DrawSpriteUv(TXD, page,
                pen + (glyph.xoff + glyph.w * 0.5) * kx,
                bandTop + (drop + cellH * 0.5) * k,
                glyph.w * kx, cellH * k,
                u, v, u + glyph.w / pageW, v + cellH / pageH,
                0.0, r, g, b, a)
        end

        pen = pen + glyph.adv * kx
    end
end

-- Accented letters are drawn as their base letter ("accéder" -> "ACCEDER"),
-- because the atlas has no accents in it. Chinese it does have, so that is
-- left alone; see foldText.
local FOLD = {}
do
    local groups = {
        a = 'àáâãäåā', c = 'çćč', e = 'èéêëēėęě', i = 'ìíîïī', n = 'ñńň', o = 'òóôõöøőō', u = 'ùúûüűū',
        y = 'ýÿ', s = 'śšș', z = 'źżž', l = 'ł', r = 'ř', d = 'ď', t = 'ťț', g = 'ğ',
        A = 'ÀÁÂÃÄÅĀ', C = 'ÇĆČ', E = 'ÈÉÊËĒĖĘĚ', I = 'ÌÍÎÏĪİ', N = 'ÑŃŇ', O = 'ÒÓÔÕÖØŐŌ', U = 'ÙÚÛÜŰŪ',
        Y = 'ÝŸ', S = 'ŚŠȘ', Z = 'ŹŻŽ', L = 'Ł', R = 'Ř', D = 'Ď', T = 'ŤȚ', G = 'Ğ',
    }
    for base, chars in pairs(groups) do
        for _, code in utf8.codes(chars) do FOLD[utf8.char(code)] = base end
    end
    FOLD['ß'], FOLD['æ'], FOLD['Æ'], FOLD['œ'], FOLD['Œ'] = 'ss', 'ae', 'AE', 'oe', 'OE'
end

local function foldText(text)
    return (text:gsub(UTF8, function(ch)
        if #ch == 1 then return ch end

        -- An accent comes down to its plain letter first, so a French
        -- label reads as words rather than as a row of question marks.
        local folded = FOLD[ch]
        if folded then return folded end

        -- Anything the alphabet actually holds -- Chinese, and the
        -- full-width punctuation that comes with it -- is left be.
        if glyphs[ch] then return ch end

        return '?'
    end))
end

local function textWidth(text, capHeight, aspect)
    local kx = capHeight / font.capHeight / aspect
    local width = 0
    for char in string_gmatch(text, UTF8) do width = width + (glyphs[char] or fallbackGlyph).adv * kx end
    return width
end

local function drawLabel(text, x, y, aspect, alpha)
    local cap = settings.textSize * PX
    local c = colours.text

    if settings.shadow then
        local offset = cap * 0.09
        drawText(text, x + offset / aspect, y + offset, cap, aspect, 0, 0, 0, math.floor(alpha * 0.45))
    end

    drawText(text, x, y, cap, aspect, c[1], c[2], c[3], alpha)
end

local function drawDot(coords, aspect)
    local size = settings.dotSize * PX
    local c = colours.text
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    DrawSprite(TXD, 'dot', 0.0, 0.0, size / aspect, size, 0.0, c[1], c[2], c[3], 255)
    ClearDrawOrigin()
end

local function drawCrosshair(aspect)
    local size = 6 * PX
    DrawSprite(TXD, 'crosshair', 0.5, 0.5, size / aspect, size, 0.0, 255, 255, 255, 230)
end

-- "[E] LABEL": the badge sits on the point, the label to its right. With several options the
-- selected row stays on the point and the others are dimmed above and below it.
local function drawPrompt(coords, rows, selected, aspect)
    local keyH = settings.keySize * PX
    local keyW = keyH / aspect
    local keyCap = keyH * 0.5
    local labelX = keyW * 0.5 + 8 * PX / aspect
    local k, kt, alpha = colours.key, colours.keyText, colours.text[4]

    SetDrawOrigin(coords.x, coords.y, coords.z, 0)

    for i = 1, #rows do
        local y = (i - selected) * settings.rowSpacing * PX

        if i == selected then
            DrawSprite(TXD, 'key', 0.0, y, keyW, keyH, 0.0, k[1], k[2], k[3], k[4])
            drawText(settings.key, -textWidth(settings.key, keyCap, aspect) * 0.5, y, keyCap, aspect, kt[1], kt[2], kt[3], kt[4])
            drawLabel(rows[i].text, labelX, y, aspect, alpha)
        else
            drawLabel(rows[i].text, labelX, y, aspect, settings.dimmedAlpha)
        end
    end

    ClearDrawOrigin()
end

---------------------------------------------------------------------------------------------------
-- Server-wide: TextUI "[E]" prompts drawn as world prompts (interact.lua > replaceTextUI)
---------------------------------------------------------------------------------------------------

-- GTA control tokens scripts put in help text, e.g. "Press ~INPUT_PICKUP~ to ...".
local CONTROL_TOKENS = {
    INPUT_PICKUP = 38, INPUT_CONTEXT = 51, INPUT_CONTEXT_SECONDARY = 52, INPUT_DETONATE = 47,
    INPUT_ENTER = 23, INPUT_VEH_HORN = 86, INPUT_COVER = 44, INPUT_RELOAD = 45, INPUT_JUMP = 22,
    INPUT_SPRINT = 21, INPUT_DUCK = 36, INPUT_FRONTEND_ACCEPT = 201, INPUT_CELLPHONE_SELECT = 176,
    INPUT_VEH_EXIT = 75, INPUT_THROW_GRENADE = 58, INPUT_MULTIPLAYER_INFO = 20, INPUT_SPECIAL_ABILITY = 28,
}

local function keyForToken(name)
    local control = CONTROL_TOKENS[name]
    if not control then return 'E' end
    local button = GetControlInstructionalButton(0, control, true)
    return button and button:match('^t_(.+)$') or 'E'
end

local connectorSet = {}
for _, word in ipairs(settings.replaceTextUI.connectors or {}) do connectorSet[word:lower()] = true end

-- One line of prompt text -> { key, text }, or nil when the line has no key in it.
local function parsePromptLine(line)
    local key, rest

    local s, e, token = line:find('~(INPUT_[%u_]+)~')
    if s then
        key, rest = keyForToken(token), line:sub(e + 1)
    else
        -- "[E]", possibly wrapped in colour codes: "~b~[E]~s~"
        s, e, token = line:find('%[%s*([^%]]-)%s*%]')
        if not s or #token == 0 or #token > 8 then return end
        key, rest = token, line:sub(e + 1)
    end

    -- Drop colour codes (~b~, ~s~ ...), markdown, and the word joining the key to the action.
    rest = rest:gsub('~%a~', ''):gsub('%*%*', ''):gsub('^[%s%-:]+', '')
    local first, remainder = rest:match('^(%S+)%s+(.+)$')
    if first and connectorSet[first:lower()] then rest = remainder end
    rest = rest:gsub('[%.!]+%s*$', ''):gsub('%s+', ' ')

    if rest == '' then return end
    rest = foldText(rest)
    if settings.uppercase then rest = rest:upper() end

    return { key = (key:gsub('~%a~', '')):upper(), text = rest }
end

local worldPrompt = nil -- { rows, anchor } while a TextUI prompt is shown in the world
local lastAnchor, lastHidden = nil, 0 -- where the previous prompt was, to reuse it when it comes straight back
local FOLLOW_DISTANCE = 6.0 -- a prompt still shown this far away moves back in front of the player

local function promptAnchor()
    if settings.replaceTextUI.anchor == 'player' then
        return GetOffsetFromEntityInWorldCoords(cache.ped, 0.45, 0.25, 0.3)
    end

    -- 1 m ahead at chest height, in the direction the camera faces (close to the screen centre).
    local heading = math.rad(GetGameplayCamRot(2).z)
    local chest = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 0.0, 0.25)
    return vec3(chest.x - math.sin(heading), chest.y + math.cos(heading), chest.z)
end

-- What the world prompt is doing right now, for /uidebug.
local worldDebug = {}

local function drawKeyRows(coords, rows, aspect)
    local keyH = settings.keySize * PX
    local keyCap = keyH * 0.5
    local k, kt, alpha = colours.key, colours.keyText, colours.text[4]

    SetDrawOrigin(coords.x, coords.y, coords.z, 0)

    local top = -(#rows - 1) * 0.5 * settings.rowSpacing * PX

    for i = 1, #rows do
        local y = top + (i - 1) * settings.rowSpacing * PX
        local row = rows[i]
        -- Wide keys (ESC, SHIFT) get a wider badge.
        local keyW = math.max(keyH, textWidth(row.key, keyCap, 1) + keyH * 0.5) / aspect

        DrawSprite(TXD, 'key', 0.0, y, keyW, keyH, 0.0, k[1], k[2], k[3], k[4])
        drawText(row.key, -textWidth(row.key, keyCap, aspect) * 0.5, y, keyCap, aspect, kt[1], kt[2], kt[3], kt[4])
        drawLabel(row.text, keyW * 0.5 + 8 * PX / aspect, y, aspect, alpha)
    end

    ClearDrawOrigin()
end

-- Called by lib.showTextUI. Returns true when the text was taken over as a world prompt.
local promptGeneration = 0 -- one draw loop per prompt, even when hide/show happen in the same frame

-- Called by lib.showTextUI. Returns true when the text was taken over as a world prompt.
function showWorldPrompt(text)
    worldDebug.text = text
    if not settings.replaceTextUI.enabled or type(text) ~= 'string' then
        worldDebug.state = 'replaceTextUI is off'
        return false
    end

    local rows = {}
    for line in text:gsub('  \n', '\n'):gmatch('[^\n]+') do
        local row = parsePromptLine(line)
        if row then rows[#rows + 1] = row end
    end

    if #rows == 0 then
        worldDebug.state = 'no key found in the text, shown as the normal TextUI box'
        return false
    end

    local anchor = worldPrompt and worldPrompt.anchor

    -- Scripts often hide and show the same prompt again right away; keep it in the same place.
    if not anchor and lastAnchor and GetGameTimer() - lastHidden < 1500
        and #(lastAnchor - GetEntityCoords(cache.ped)) < FOLLOW_DISTANCE then
        anchor = lastAnchor
    end

    local usesE = false
    for i = 1, #rows do
        if rows[i].key == 'E' then usesE = true end
    end

    local running = worldPrompt ~= nil
    worldPrompt = { rows = rows, anchor = anchor or promptAnchor(), usesE = usesE, offScreenSince = nil }
    if running then return true end

    promptGeneration = promptGeneration + 1
    local generation = promptGeneration

    CreateThread(function()
        while worldPrompt and generation == promptGeneration do
            local prompt = worldPrompt

            if IsPauseMenuActive() then
                worldDebug.state = 'hidden: pause menu'
            elseif IsNuiFocused() then
                worldDebug.state = 'hidden: a resource has the mouse cursor (NUI focus)'
            else
                local aspect = GetAspectRatio(false)
                local anchor = prompt.anchor
                local now = GetGameTimer()

                if settings.replaceTextUI.anchor == 'player' then
                    anchor = promptAnchor()
                elseif #(anchor - GetEntityCoords(cache.ped)) > FOLLOW_DISTANCE then
                    -- Stays where it appeared; only a prompt still shown far away comes back to the player.
                    anchor = promptAnchor()
                    prompt.anchor = anchor
                end

                -- Same as an interaction point: a ring until you look at it, then the prompt.
                local onScreen, sx, sy = GetScreenCoordFromWorldCoord(anchor.x, anchor.y, anchor.z)
                local looking = false

                if onScreen then
                    prompt.offScreenSince = nil
                    local dx, dy = (sx - 0.5) * aspect, sy - 0.5
                    looking = math.sqrt(dx * dx + dy * dy) < (settings.replaceTextUI.hoverRadius or 0.12)
                else
                    -- Behind the camera for a second: bring the ring back in view so it is never lost.
                    prompt.offScreenSince = prompt.offScreenSince or now
                    if now - prompt.offScreenSince > 1000 then
                        prompt.anchor = promptAnchor()
                        prompt.offScreenSince = nil
                    end
                end

                if looking or not settings.replaceTextUI.requireLook then
                    drawKeyRows(anchor, prompt.rows, aspect)
                    worldDebug.state = 'prompt shown'
                else
                    if onScreen then drawDot(anchor, aspect) end
                    worldDebug.state = onScreen and 'ring shown, look at it for the prompt' or 'ring is off-screen, moving it into view'

                    -- The zone script checks E itself; while you are not looking at the ring,
                    -- E (and the other bound E control) is held back so it only works on the prompt.
                    if prompt.usesE then
                        DisableControlAction(0, 38, true)
                        DisableControlAction(0, 51, true)
                    end
                end

                worldDebug.distance = #(anchor - GetEntityCoords(cache.ped))
                if settings.crosshair then drawCrosshair(aspect) end
            end

            Wait(0)
        end
    end)

    return true
end

function hideWorldPrompt()
    if worldPrompt then lastAnchor, lastHidden = worldPrompt.anchor, GetGameTimer() end
    worldPrompt = nil
    worldDebug.state = 'hidden by the script'
end



---------------------------------------------------------------------------------------------------
-- Registry
---------------------------------------------------------------------------------------------------

local points = {}    -- id -> point
local models = {}    -- model hash -> { id -> point }
local globals = { vehicle = {}, ped = {}, player = {} } -- type -> { id -> point }
local nextId = 0
-- enabled = false in interact.lua turns the points off; the functions stay so scripts do not break.
local disabled = not settings.enabled

local function cleanOptions(options)
    if type(options) ~= 'table' then return {} end
    -- A single option table is accepted as well as a list.
    if options.label then return { options } end
    local list = {}
    for _, option in pairs(options) do
        if type(option) == 'table' then list[#list + 1] = option end
    end
    return list
end

local function register(data, fields)
    if type(data) ~= 'table' then return error('interaction data must be a table', 3) end

    local options = cleanOptions(data.options)
    if #options == 0 then return error('an interaction needs at least one option', 3) end

    nextId = nextId + 1

    local point = {
        id = nextId,
        name = data.name,
        options = options,
        distance = tonumber(data.distance) or settings.defaultDistance,
        interactDst = tonumber(data.interactDst) or settings.defaultInteractDst,
        offset = data.offset,
        resource = GetInvokingResource() or cache.resource,
    }

    for k, v in pairs(fields) do point[k] = v end

    points[nextId] = point
    return nextId
end

---@return number id
function lib.addInteraction(data)
    if not data or not data.coords then return error('addInteraction needs coords', 2) end
    local c = data.coords
    return register(data, { coords = vec3(c.x, c.y, c.z) })
end

---@return number id
function lib.addLocalEntityInteraction(data)
    if not data or not data.entity or not DoesEntityExist(data.entity) then
        return error('addLocalEntityInteraction needs an existing entity', 2)
    end
    return register(data, { entity = data.entity })
end

---@return number id
function lib.addEntityInteraction(data)
    local value = data and (data.netId or data.entity)
    if type(value) ~= 'number' then return error('addEntityInteraction needs a netId or entity', 2) end

    -- Accept either a network id or an entity handle; local entities are kept by handle.
    if NetworkDoesNetworkIdExist(value) then
        return register(data, { netId = value })
    elseif DoesEntityExist(value) then
        if NetworkGetEntityIsNetworked(value) then
            return register(data, { netId = NetworkGetNetworkIdFromEntity(value) })
        end
        return register(data, { entity = value })
    end

    return error(('addEntityInteraction: %s is not a network id or entity'):format(value), 2)
end

---@return number id
function lib.addEntityBoneInteraction(data)
    if not data or not data.entity or not data.bone then return error('addEntityBoneInteraction needs entity and bone', 2) end
    return register(data, { entity = data.entity, bone = data.bone })
end

---@return number id
--[[
    A model point is every prop of that model in the world, which is usually
    what you want for a cash machine and never what you want for the till on
    one shop's counter -- the same prop stands in every shop on the map.

    Giving `coords` keeps it to the props standing at those spots. One vec3 or
    a list of them, with `radius` for how far a prop may be from one and still
    count (three metres unless you say otherwise).
]]
--- @return vec3[]|nil
local function nearList(coords)
    if not coords then return end
    if coords.x then return { vec3(coords.x, coords.y, coords.z) } end

    local out = {}
    for _, c in pairs(coords) do
        if c and c.x then out[#out + 1] = vec3(c.x, c.y, c.z) end
    end
    return #out > 0 and out or nil
end

function lib.addModelInteraction(data)
    if not data then return error('addModelInteraction needs data', 2) end

    local list = data.modelData or data.models or { data.model }
    local id = register(data, { model = true })
    local point = points[id]
    points[id] = nil -- model points live in the model table, not in the fixed list
    point.perModel = {}
    point.near = nearList(data.coords)
    point.nearRadius = tonumber(data.radius) or 3.0

    for _, entry in pairs(list) do
        local model = type(entry) == 'table' and entry.model or entry
        local hash = type(model) == 'string' and joaat(model) or model

        if type(hash) == 'number' then
            models[hash] = models[hash] or {}
            models[hash][id] = point
            point.perModel[hash] = type(entry) == 'table' and entry.offset or nil
        end
    end

    return id
end

local function addGlobal(kind, data)
    local id = register(data, { global = kind, bone = data and data.bone })
    globals[kind][id] = points[id]
    points[id] = nil
    return id
end

function lib.addGlobalVehicleInteraction(data) return addGlobal('vehicle', data) end
function lib.addGlobalPedInteraction(data) return addGlobal('ped', data) end
function lib.addGlobalPlayerInteraction(data) return addGlobal('player', data) end

local function findPoint(id)
    if points[id] then return points[id] end
    for _, list in pairs(models) do if list[id] then return list[id] end end
    for _, list in pairs(globals) do if list[id] then return list[id] end end
end

function lib.removeInteraction(id)
    points[id] = nil
    for _, list in pairs(models) do list[id] = nil end
    for _, list in pairs(globals) do list[id] = nil end
end

function lib.removeInteractionByEntity(entity)
    local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)
    for id, point in pairs(points) do
        if point.entity == entity or (netId and point.netId == netId) then points[id] = nil end
    end
end

function lib.removeInteractionOption(id, name)
    local point = findPoint(id)
    if not point then return end
    if not name then return lib.removeInteraction(id) end

    for i = #point.options, 1, -1 do
        if point.options[i].name == name then table.remove(point.options, i) end
    end

    if #point.options == 0 then lib.removeInteraction(id) end
end

function lib.updateInteraction(id, options)
    local point = findPoint(id)
    if point then point.options = cleanOptions(options) end
end

---@param state boolean
function lib.disableInteractions(state)
    disabled = state and true or false
end

AddEventHandler('onClientResourceStop', function(resource)
    for id, point in pairs(points) do
        if point.resource == resource then points[id] = nil end
    end
    for _, list in pairs(models) do
        for id, point in pairs(list) do if point.resource == resource then list[id] = nil end end
    end
    for _, list in pairs(globals) do
        for id, point in pairs(list) do if point.resource == resource then list[id] = nil end end
    end
end)

---------------------------------------------------------------------------------------------------
-- Finding nearby points (slow loop) and drawing them (every frame while any are near)
---------------------------------------------------------------------------------------------------

local GetOffsetFromEntityInWorldCoords, GetEntityCoords, DoesEntityExist = GetOffsetFromEntityInWorldCoords, GetEntityCoords, DoesEntityExist
local GetEntityBoneIndexByName, GetWorldPositionOfEntityBone = GetEntityBoneIndexByName, GetWorldPositionOfEntityBone

-- Where a point is right now (entities move, so this runs every frame for the shown ones).
local function positionOf(anchor)
    if anchor.coords then return anchor.coords end

    local entity = anchor.entity
    if not entity or not DoesEntityExist(entity) then return end

    local offset = anchor.offset

    if anchor.bone then
        local index = GetEntityBoneIndexByName(entity, anchor.bone)
        if index ~= -1 then
            local pos = GetWorldPositionOfEntityBone(entity, index)
            return offset and pos + offset or pos
        end
    end

    if offset then return GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z) end

    return GetEntityCoords(entity)
end

local function visibleRows(option, entity, coords)
    if option.canInteract then
        local ok, result = pcall(option.canInteract, entity, coords, option.args)
        if not ok or not result then return end
    end

    local label = foldText(tostring(option.label or ''))
    if settings.uppercase then label = label:upper() end

    return { option = option, text = label }
end

-- Entities that model and global points attach to, refreshed every second.
local pooled = {}

local function refreshPools(playerCoords)
    table.wipe(pooled)

    local wantVehicles = next(globals.vehicle) ~= nil
    local wantPeds = next(globals.ped) ~= nil or next(globals.player) ~= nil
    local wantModels = next(models) ~= nil

    -- A model point with `coords` only attaches to the props standing there.
    local function standsThere(point, entityCoords)
        if not point.near then return true end

        for _, spot in ipairs(point.near) do
            if #(entityCoords - spot) <= point.nearRadius then return true end
        end

        return false
    end

    local function scan(pool, kind)
        for _, entity in ipairs(GetGamePool(pool)) do
            local entityCoords = GetEntityCoords(entity)

            if #(entityCoords - playerCoords) < 30.0 then
                local list = wantModels and models[GetEntityModel(entity)]

                if list then
                    for _, point in pairs(list) do
                        if standsThere(point, entityCoords) then
                            pooled[#pooled + 1] = { point = point, entity = entity, offset = point.perModel[GetEntityModel(entity)] or point.offset }
                        end
                    end
                end

                if kind == 'vehicle' and wantVehicles then
                    for _, point in pairs(globals.vehicle) do
                        pooled[#pooled + 1] = { point = point, entity = entity, offset = point.offset, bone = point.bone }
                    end
                elseif kind == 'ped' and entity ~= cache.ped then
                    local isPlayer = IsPedAPlayer(entity)
                    for _, point in pairs(isPlayer and globals.player or globals.ped) do
                        pooled[#pooled + 1] = { point = point, entity = entity, offset = point.offset, bone = point.bone }
                    end
                end
            end
        end
    end

    if wantModels then scan('CObject', 'object') end
    if wantVehicles or wantModels then scan('CVehicle', 'vehicle') end
    if wantPeds or wantModels then scan('CPed', 'ped') end
end

local nearby = {} -- { key, anchor, rows }, rebuilt every 250 ms

local function rebuildNearby(playerCoords)
    local found, byKey = {}, {}

    local function consider(point, anchor)
        local coords = positionOf(anchor)
        if not coords then return end

        local distance = #(coords - playerCoords)
        if distance > point.distance then return end

        local rows = {}
        for i = 1, #point.options do
            rows[#rows + 1] = visibleRows(point.options[i], anchor.entity, coords)
        end
        if #rows == 0 then return end

        -- Points on the same spot (e.g. two scripts adding to one vehicle) share one prompt.
        local key = anchor.coords and ('%.1f:%.1f:%.1f'):format(coords.x, coords.y, coords.z)
            or ('%s:%s:%s'):format(anchor.entity, anchor.bone or '', anchor.offset or '')
        local entry = byKey[key]

        if not entry then
            entry = { key = key, anchor = anchor, rows = {}, interactDst = point.interactDst, distance = distance }
            byKey[key] = entry
            found[#found + 1] = entry
        else
            entry.interactDst = math.max(entry.interactDst, point.interactDst)
        end

        for i = 1, #rows do entry.rows[#entry.rows + 1] = rows[i] end
    end

    for _, point in pairs(points) do
        local entity = point.entity
        if point.netId then
            entity = NetworkDoesNetworkIdExist(point.netId) and NetworkGetEntityFromNetworkId(point.netId) or nil
        end

        if point.coords or entity then
            consider(point, { coords = point.coords, entity = entity, bone = point.bone, offset = point.offset })
        end
    end

    for i = 1, #pooled do
        local item = pooled[i]
        if DoesEntityExist(item.entity) then
            consider(item.point, { entity = item.entity, bone = item.bone, offset = item.offset })
        end
    end

    table.sort(found, function(a, b) return a.distance < b.distance end)
    nearby = found
end

local function isBlocked()
    if disabled or LocalPlayer.state.interactionsDisabled or IsPauseMenuActive() then return true end

    local block = settings.disable
    if block.dead and (IsEntityDead(cache.ped) or LocalPlayer.state.isDead or LocalPlayer.state.dead) then return true end
    if block.nuiFocus and IsNuiFocused() then return true end
    if block.inVehicle and cache.vehicle then return true end
    if block.cuffed and IsPedCuffed(cache.ped) then return true end

    return false
end

local function runOption(option, anchor, coords)
    CreateThread(function()
        local entity = anchor.entity
        local ok, err = pcall(function()
            if option.action then
                option.action(entity, coords, option.args)
            elseif option.event then
                TriggerEvent(option.event, { entity = entity, coords = coords, args = option.args, name = option.name })
            elseif option.serverEvent then
                TriggerServerEvent(option.serverEvent, {
                    entity = entity and NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or nil,
                    coords = coords, args = option.args, name = option.name,
                })
            elseif option.command then
                ExecuteCommand(option.command)
            end
        end)

        if not ok then lib.print.error(('interaction option "%s" failed: %s'):format(option.label or '?', err)) end
    end)
end

-- Slow loop: which points are near, which options they show.
CreateThread(function()
    local poolTimer = 0

    while true do
        local playerCoords = GetEntityCoords(cache.ped)

        if GetGameTimer() >= poolTimer then
            refreshPools(playerCoords)
            poolTimer = GetGameTimer() + 1000
        end

        rebuildNearby(playerCoords)
        Wait(250)
    end
end)

-- Fast loop: dots, crosshair, the prompt and the key presses.
CreateThread(function()
    local selectedKey, selection = nil, 1
    local control = settings.control
    local hoverRadius = settings.hoverRadius
    local screen = {}

    while true do
        if #nearby == 0 or isBlocked() then
            selectedKey = nil
            Wait(250)
        else
            local aspect = GetAspectRatio(false)
            local playerCoords = GetEntityCoords(cache.ped)
            local active, activeCoords, best = nil, nil, hoverRadius
            local shown = 0

            for i = 1, #nearby do
                local entry = nearby[i]
                local coords = positionOf(entry.anchor)

                if coords then
                    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)

                    if onScreen then
                        shown = shown + 1
                        screen[shown] = { entry = entry, coords = coords }

                        if #(coords - playerCoords) <= entry.interactDst then
                            local dx, dy = (sx - 0.5) * aspect, sy - 0.5
                            local d = math.sqrt(dx * dx + dy * dy)
                            if d < best then best, active, activeCoords = d, entry, coords end
                        end
                    end
                end
            end

            for i = 1, shown do
                if screen[i].entry ~= active then drawDot(screen[i].coords, aspect) end
            end

            if shown > 0 and settings.crosshair then drawCrosshair(aspect) end

            if active then
                local rows = active.rows

                if active.key ~= selectedKey then selectedKey, selection = active.key, 1 end
                if selection > #rows then selection = #rows end

                if #rows > 1 then
                    -- The wheel changes options here instead of weapons.
                    DisableControlAction(0, 14, true)
                    DisableControlAction(0, 15, true)
                    DisableControlAction(0, 16, true)
                    DisableControlAction(0, 17, true)

                    if selection > 1 and (IsControlJustPressed(0, 172) or IsDisabledControlJustPressed(0, 15)) then
                        selection = selection - 1
                    elseif selection < #rows and (IsControlJustPressed(0, 173) or IsDisabledControlJustPressed(0, 14)) then
                        selection = selection + 1
                    end
                end

                drawPrompt(activeCoords, rows, selection, aspect)

                if IsControlJustPressed(0, control) then
                    runOption(rows[selection].option, active.anchor, activeCoords)
                end
            else
                selectedKey = nil
            end

            Wait(0)
        end
    end
end)

-- /uidebug: shows on screen what the interaction system and the TextUI replacement are doing.
local debugOn = false

RegisterCommand('uidebug', function()
    debugOn = not debugOn
    if not debugOn then return end

    CreateThread(function()
        while debugOn do
            local open, text = lib.isTextUIOpen()
            local lines = {
                ('TextUI open: %s'):format(open and 'yes' or 'no'),
                ('Last text: %s'):format(tostring(worldDebug.text or '-'):gsub('\n', ' | ')),
                ('World prompt: %s'):format(worldPrompt and (worldDebug.state or '?') or (worldDebug.state or 'none')),
                ('Ring distance: %s'):format(worldPrompt and worldDebug.distance and ('%.1f m'):format(worldDebug.distance) or '-'),
                ('NUI focus: %s   pause menu: %s'):format(IsNuiFocused() and 'YES' or 'no', IsPauseMenuActive() and 'yes' or 'no'),
                ('Interaction points near: %d   blocked: %s'):format(#nearby, isBlocked() and 'YES' or 'no'),
            }

            for i = 1, #lines do
                SetTextFont(4)
                SetTextScale(0.0, 0.34)
                SetTextColour(255, 255, 255, 230)
                SetTextOutline()
                BeginTextCommandDisplayText('STRING')
                AddTextComponentSubstringPlayerName(lines[i])
                EndTextCommandDisplayText(0.015, 0.30 + (i - 1) * 0.024)
            end

            Wait(0)
        end
    end)
end)
