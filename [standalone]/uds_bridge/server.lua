local resourceName = GetCurrentResourceName()
local startedAt = os.time()

local function jsonResponse(status, payload)
  return {
    status = status,
    headers = {
      ['Content-Type'] = 'application/json; charset=utf-8',
      ['Cache-Control'] = 'no-store'
    },
    data = json.encode(payload)
  }
end

local function sendResponse(res, response)
  res.writeHead(response.status, response.headers)
  res.send(response.data)
end

local function ok(data)
  return jsonResponse(200, { ok = true, data = data })
end

local function fail(status, message)
  return jsonResponse(status, { ok = false, error = message })
end

local function headerValue(headers, key)
  if not headers then return nil end
  local direct = headers[key]
  if direct then return direct end
  local lowered = string.lower(key)
  for name, value in pairs(headers) do
    if string.lower(name) == lowered then return value end
  end
  return nil
end

local function authorized(req)
  local token = GetConvar('uds_bridge_token', 'ef23539ca187f75f6cd52c654546af4e')
  if token == '' then return false, 'Bridge token chưa được cấu hình' end
  local auth = headerValue(req.headers, 'authorization') or ''
  local bearer = auth:match('^Bearer%s+(.+)$')
  if bearer ~= token then return false, 'Token không hợp lệ' end
  return true
end

local function parsePath(path)
  local clean = (path or '/'):gsub('%?.*$', '')
  local parts = {}
  for part in clean:gmatch('[^/]+') do
    parts[#parts + 1] = part
  end
  if parts[1] == resourceName then
    table.remove(parts, 1)
  end
  return parts
end

local function nowIso()
  return os.date('!%Y-%m-%dT%H:%M:%SZ')
end

local function uptimeText()
  local seconds = os.time() - startedAt
  local days = math.floor(seconds / 86400)
  seconds = seconds % 86400
  local hours = math.floor(seconds / 3600)
  seconds = seconds % 3600
  local minutes = math.floor(seconds / 60)
  return string.format('%dd %dh %dm', days, hours, minutes)
end

local function identifiersFor(source)
  local result = {}
  for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
    local prefix, value = identifier:match('([^:]+):(.+)')
    if prefix and value then
      result[prefix] = identifier
    end
  end
  return result
end

local function initialsFor(name)
  local first = name:match('^%s*(%w)')
  local second = name:match('%s+(%w)')
  local value = ((first or 'P') .. (second or 'L')):upper()
  return value:sub(1, 2)
end

local function safeCall(fn)
  local success, result = pcall(fn)
  if success then return result end
  return nil
end

local function getEsx()
  return safeCall(function()
    if GetResourceState('es_extended') ~= 'started' then return nil end
    if exports and exports['es_extended'] and exports['es_extended'].getSharedObject then
      return exports['es_extended']:getSharedObject()
    end
    local shared = nil
    TriggerEvent('esx:getSharedObject', function(obj) shared = obj end)
    return shared
  end)
end

local function getQbCore()
  return safeCall(function()
    if GetResourceState('qb-core') ~= 'started' then return nil end
    if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
      return exports['qb-core']:GetCoreObject()
    end
    return nil
  end)
end

local function coordsFor(source)
  return safeCall(function()
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    local coords = GetEntityCoords(ped)
    if not coords then return nil end
    return string.format('%.2f, %.2f, %.2f', coords.x, coords.y, coords.z)
  end)
end

local function routingBucketFor(source)
  return safeCall(function()
    return GetPlayerRoutingBucket(source)
  end)
end

local function normalizeMoney(value)
  local number = tonumber(value)
  if number then return math.floor(number) end
  return 0
end

local function applyEsxPlayer(dto, source)
  local ESX = getEsx()
  if not ESX or not ESX.GetPlayerFromId then return false end
  local xPlayer = safeCall(function() return ESX.GetPlayerFromId(source) end)
  if not xPlayer then return false end

  dto.name = safeCall(function()
    if xPlayer.getName then return xPlayer.getName() end
    return nil
  end) or dto.name
  dto.initials = initialsFor(dto.name)

  local job = safeCall(function()
    if xPlayer.getJob then return xPlayer.getJob() end
    return xPlayer.job
  end)
  if type(job) == 'table' then
    dto.job = job.label or job.name or dto.job
    dto.jobGrade = job.grade_label or job.grade_name or tostring(job.grade or dto.jobGrade)
  end

  dto.cash = normalizeMoney(safeCall(function()
    if xPlayer.getMoney then return xPlayer.getMoney() end
    return xPlayer.money
  end))
  dto.bank = normalizeMoney(safeCall(function()
    if xPlayer.getAccount then
      local account = xPlayer.getAccount('bank')
      if account then return account.money end
    end
    return nil
  end))
  dto.account.identifier = safeCall(function() return xPlayer.identifier end) or dto.identifiers.license
  dto.bridge.framework = 'ESX'
  dto.bridge.group = safeCall(function()
    if xPlayer.getGroup then return xPlayer.getGroup() end
    return xPlayer.group
  end)
  return true
end

local function applyQbPlayer(dto, source)
  local QBCore = getQbCore()
  if not QBCore or not QBCore.Functions or not QBCore.Functions.GetPlayer then return false end
  local player = safeCall(function() return QBCore.Functions.GetPlayer(source) end)
  if not player or not player.PlayerData then return false end

  local data = player.PlayerData
  if type(data.charinfo) == 'table' then
    local fullName = ((data.charinfo.firstname or '') .. ' ' .. (data.charinfo.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
    if fullName ~= '' then dto.name = fullName end
    dto.phone = data.charinfo.phone or dto.phone
  end
  dto.initials = initialsFor(dto.name)
  if type(data.job) == 'table' then
    dto.job = (type(data.job.label) == 'string' and data.job.label) or data.job.name or dto.job
    if type(data.job.grade) == 'table' then
      dto.jobGrade = data.job.grade.name or tostring(data.job.grade.level or dto.jobGrade)
    else
      dto.jobGrade = tostring(data.job.grade or dto.jobGrade)
    end
  end
  if type(data.money) == 'table' then
    dto.cash = normalizeMoney(data.money.cash)
    dto.bank = normalizeMoney(data.money.bank)
  end
  dto.account.citizenId = data.citizenid
  dto.account.identifier = data.license or dto.identifiers.license
  dto.bridge.framework = 'QBCore'
  return true
end

local function playerDto(source)
  local name = GetPlayerName(source) or ('ID ' .. tostring(source))
  local identifiers = identifiersFor(source)
  local id = tonumber(source) or source
  local dto = {
    id = tonumber(source) or source,
    characterId = tonumber(source) or 0,
    name = name,
    initials = initialsFor(name),
    job = 'Unknown',
    jobGrade = 'Unknown',
    cash = 0,
    bank = 0,
    status = 'online',
    lastSeen = 'Hiện tại',
    playTime = 'Không rõ',
    phone = 'Không rõ',
    location = coordsFor(id) or 'Không rõ',
    identifiers = {
      license = identifiers.license,
      discord = identifiers.discord,
      steam = identifiers.steam,
      fivem = identifiers.fivem,
      license2 = identifiers.license2,
      ip = identifiers.ip
    },
    bridge = {
      framework = GetConvar('uds_bridge_framework', 'qbx'),
      ping = GetPlayerPing(id),
      endpoint = GetPlayerEndpoint(id),
      routingBucket = routingBucketFor(id),
      collectedAt = nowIso()
    },
    account = {
      identifier = identifiers.license
    }
  }
  if not applyQbPlayer(dto, id) then applyEsxPlayer(dto, id) end
  return dto
end

local function players()
  local list = {}
  for _, source in ipairs(GetPlayers()) do
    list[#list + 1] = playerDto(source)
  end
  return list
end

local function resourceDto(index)
  local name = GetResourceByFindIndex(index)
  if not name then return nil end
  local state = GetResourceState(name)
  local mappedState = state == 'started' and 'started' or state == 'stopped' and 'stopped' or 'warning'
  return {
    name = name,
    state = mappedState,
    cpu = 'Không có',
    memory = 'Không có',
    updatedAt = nowIso()
  }
end

local function resources()
  local list = {}
  local count = GetNumResources()
  for index = 0, count - 1 do
    local item = resourceDto(index)
    if item then list[#list + 1] = item end
  end
  return list
end

local function snapshot()
  local playerList = players()
  local resourceList = resources()
  local started = 0
  local stopped = 0
  for _, item in ipairs(resourceList) do
    if item.state == 'started' then started = started + 1 else stopped = stopped + 1 end
  end
  return {
    server = {
      agent = 'connected',
      cpu = 'Không có',
      tickP95 = 'Không có',
      memory = 'Không có',
      build = GetConvar('version', 'Không rõ'),
      framework = GetConvar('uds_bridge_framework', 'qbx'),
      onesync = GetConvar('onesync', 'Không rõ'),
      uptime = uptimeText(),
      endpoint = GetConvar('endpoint_add_tcp', '30120'),
      simulated = false
    },
    players = playerList,
    resources = resourceList,
    counts = {
      onlinePlayers = #playerList,
      resourcesStarted = started,
      resourcesStopped = stopped
    },
    generatedAt = nowIso()
  }
end

local function writeAllowed()
  local value = GetConvar('uds_bridge_allow_write', 'true')
  return value == 'true' or value == '1'
end

local function resourceAction(action, target)
  if not writeAllowed() then return fail(403, 'Bridge chưa bật quyền ghi') end
  if not target or target == resourceName then return fail(400, 'Resource không hợp lệ') end
  if action == 'start' then
    StartResource(target)
  elseif action == 'stop' then
    StopResource(target)
  elseif action == 'restart' then
    StopResource(target)
    Wait(500)
    StartResource(target)
  else
    return fail(404, 'Action không tồn tại')
  end
  return ok({ name = target, action = action, state = GetResourceState(target) })
end

local function playerAction(action, source, body)
  if not writeAllowed() then return fail(403, 'Bridge chưa bật quyền ghi') end
  local id = tonumber(source)
  if not id or not GetPlayerName(id) then return fail(404, 'Không tìm thấy người chơi') end
  if action == 'kick' then
    DropPlayer(id, body.reason or 'Bạn đã bị kick khỏi máy chủ')
    return ok({ id = id, action = 'kick' })
  elseif action == 'message' then
    TriggerClientEvent('chat:addMessage', id, { args = { 'UDS', body.message or '' } })
    return ok({ id = id, action = 'message' })
  elseif action == 'ban' then
    TriggerEvent('uds_bridge:playerBanRequested', id, body.reason or 'Bạn đã bị ban khỏi máy chủ', body)
    DropPlayer(id, body.reason or 'Bạn đã bị ban khỏi máy chủ')
    return ok({ id = id, action = 'ban' })
  end
  return fail(404, 'Action không tồn tại')
end

local function serverAction(action, body)
  if not writeAllowed() then return fail(403, 'Bridge chưa bật quyền ghi') end
  if action ~= 'restart' then return fail(404, 'Action không tồn tại') end
  local command = body.command or GetConvar('uds_bridge_restart_command', '')
  if command == '' then return fail(400, 'Chưa cấu hình uds_bridge_restart_command') end
  ExecuteCommand(command)
  return ok({ action = 'restart', commandConfigured = true })
end

local function parseBody(req)
  if not req.body or req.body == '' then return {} end
  local success, decoded = pcall(json.decode, req.body)
  if success and type(decoded) == 'table' then return decoded end
  return {}
end

SetHttpHandler(function(req, res)
  local isAuthorized, authError = authorized(req)
  if not isAuthorized then
    sendResponse(res, fail(401, authError))
    return
  end

  local method = req.method or 'GET'
  local parts = parsePath(req.path)
  local body = parseBody(req)

  if method == 'GET' and parts[1] == 'health' then
    sendResponse(res, ok({ resource = resourceName, status = 'connected', generatedAt = nowIso(), writeEnabled = writeAllowed() }))
    return
  end

  if method == 'GET' and parts[1] == 'snapshot' then
    sendResponse(res, ok(snapshot()))
    return
  end

  if method == 'GET' and parts[1] == 'players' then
    if parts[2] then
      local id = tonumber(parts[2])
      if id and GetPlayerName(id) then sendResponse(res, ok(playerDto(id))) else sendResponse(res, fail(404, 'Không tìm thấy người chơi')) end
      return
    end
    sendResponse(res, ok(players()))
    return
  end

  if method == 'GET' and parts[1] == 'resources' then
    sendResponse(res, ok(resources()))
    return
  end

  if method == 'POST' and parts[1] == 'resources' and parts[2] and parts[3] then
    sendResponse(res, resourceAction(parts[3], parts[2]))
    return
  end

  if method == 'POST' and parts[1] == 'players' and parts[2] and parts[3] then
    sendResponse(res, playerAction(parts[3], parts[2], body))
    return
  end

  if method == 'POST' and parts[1] == 'server' and parts[2] then
    sendResponse(res, serverAction(parts[2], body))
    return
  end

  sendResponse(res, fail(404, 'Endpoint không tồn tại'))
end)
