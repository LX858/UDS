--[[
    BACKDOOR SCANNER v3.0
    Sử dụng LoadResourceFile (FiveM native)
    Quét tất cả resources phát hiện backdoor/mã độc
]]

local scanResults = {}
local isScanning = false
local totalThreatsFound = 0

-- ============ PATTERNS ============
local JS_PATTERNS = {
    {text = "Buffer.from", threat = "HIGH", desc = "Buffer.from() - Có thể decode Base64"},
    {text = "'base64'", threat = "HIGH", desc = "Base64 string"},
    {text = "\"base64\"", threat = "HIGH", desc = "Base64 string"},
    {text = "atob(", threat = "HIGH", desc = "atob() Base64 decode"},
    {text = "new Function", threat = "CRITICAL", desc = "new Function() - DYNAMIC CODE EXECUTION"},
    {text = "eval(", threat = "CRITICAL", desc = "eval() - CODE EXECUTION"},
    {text = "require('https')", threat = "HIGH", desc = "require('https')"},
    {text = "require(\"https\")", threat = "HIGH", desc = "require('https')"},
    {text = "require('http')", threat = "HIGH", desc = "require('http')"},
    {text = "require(\"http\")", threat = "HIGH", desc = "require('http')"},
    {text = "require(Buffer", threat = "CRITICAL", desc = "require(Buffer.from()) - OBFUSCATED REQUIRE"},
    {text = "['on']", threat = "HIGH", desc = "['on'] bracket notation obfuscation"},
    {text = "[\"on\"]", threat = "HIGH", desc = "[\"on\"] bracket notation obfuscation"},
    {text = "['get']", threat = "HIGH", desc = "['get'] bracket notation obfuscation"},
    {text = "[\"get\"]", threat = "HIGH", desc = "[\"get\"] bracket notation obfuscation"},
    {text = "['global']", threat = "CRITICAL", desc = "['global'] - Global access"},
    {text = "[\"global\"]", threat = "CRITICAL", desc = "[\"global\"] - Global access"},
    {text = "$$[", threat = "HIGH", desc = "$$[] array obfuscation"},
    {text = "const $ =", threat = "HIGH", desc = "const $ = obfuscated variable"},
    {text = "const _ =", threat = "HIGH", desc = "const _ = obfuscated variable"},
    {text = "const $$ =", threat = "HIGH", desc = "const $$ = obfuscated array"},
    {text = "(global)", threat = "CRITICAL", desc = "(global) - Global object injection"},
    {text = "child_process", threat = "CRITICAL", desc = "child_process - COMMAND EXECUTION"},
}

local LUA_PATTERNS = {
    {text = "load(", threat = "CRITICAL", desc = "load() - DYNAMIC CODE EXECUTION"},
    {text = "loadstring(", threat = "CRITICAL", desc = "loadstring() - CODE EXECUTION"},
    {text = "loadfile(", threat = "HIGH", desc = "loadfile()"},
    {text = "dofile(", threat = "HIGH", desc = "dofile()"},
    {text = "assert(load", threat = "CRITICAL", desc = "assert(load()) pattern"},
    {text = "_G[", threat = "HIGH", desc = "_G[] - Global table access"},
    {text = "rawset(_G", threat = "HIGH", desc = "rawset(_G)"},
    {text = "getfenv(", threat = "HIGH", desc = "getfenv()"},
    {text = "setfenv(", threat = "HIGH", desc = "setfenv()"},
    {text = "os.execute(", threat = "CRITICAL", desc = "os.execute() - SYSTEM COMMAND"},
    {text = "io.popen(", threat = "CRITICAL", desc = "io.popen() - COMMAND EXECUTION"},
    {text = "string.char(", threat = "HIGH", desc = "string.char() obfuscation"},
}

local SUSPICIOUS_URLS = {
    "1ls2.org", "0x0.st", "transfer.sh", "file.io",
    "ngrok.io", "webhook.site", "pastebin.com", "hastebin.com",
}

-- KNOWN BACKDOOR SIGNATURES - Base64 encoded URLs đã biết
local KNOWN_BACKDOORS = {
    "aHR0cHM6Ly8xbHMyLm9yZy96WGVBSEpK",  -- https://1ls2.org/zXeAHJJ
    "aHR0cHM6Ly8xbHMyLm9yZw",              -- https://1ls2.org
    "aHR0cDovLzFsczIub3Jn",                -- http://1ls2.org
}

local BASE64_URL_SIGS = {"aHR0cDov", "aHR0cHM6"}

-- ============ HELPER FUNCTIONS ============
local function GetLineNumber(content, pos)
    local line = 1
    for i = 1, math.min(pos, #content) do
        if content:sub(i, i) == "\n" then line = line + 1 end
    end
    return line
end

local function Base64Decode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- ============ SCAN CONTENT ============
local function ScanContent(content, fileName)
    local results = {}
    if not content or #content == 0 then return results end
    
    local ext = fileName:match("%.([^%.]+)$") or ""
    local lowerContent = content:lower()
    
    -- 🚨 KIỂM TRA KNOWN BACKDOORS TRƯỚC (QUAN TRỌNG NHẤT)
    for _, backdoorSig in ipairs(KNOWN_BACKDOORS) do
        if content:find(backdoorSig, 1, true) then
            table.insert(results, {
                matched = backdoorSig,
                description = "🚨🚨🚨 BACKDOOR XÁC NHẬN: https://1ls2.org - ĐÂY LÀ MÃ ĐỘC! 🚨🚨🚨",
                threat = "CRITICAL",
                line = 0,
            })
        end
    end
    
    -- Chọn patterns
    local patterns = {}
    if ext == "js" then
        patterns = JS_PATTERNS
    elseif ext == "lua" then
        patterns = LUA_PATTERNS
    else
        for _, p in ipairs(JS_PATTERNS) do patterns[#patterns+1] = p end
        for _, p in ipairs(LUA_PATTERNS) do patterns[#patterns+1] = p end
    end
    
    -- Quét patterns
    for _, p in ipairs(patterns) do
        local pos = content:find(p.text, 1, true)
        if pos then
            table.insert(results, {
                matched = p.text,
                description = p.desc,
                threat = p.threat,
                line = GetLineNumber(content, pos),
            })
        end
    end
    
    -- Quét URLs
    for _, url in ipairs(SUSPICIOUS_URLS) do
        if lowerContent:find(url:lower(), 1, true) then
            table.insert(results, {
                matched = url,
                description = "🌐 Suspicious URL: " .. url,
                threat = "HIGH",
                line = 0,
            })
        end
    end
    
    -- Quét Base64 URLs
    for _, sig in ipairs(BASE64_URL_SIGS) do
        local pos = content:find(sig, 1, true)
        if pos then
            local b64 = content:match("([A-Za-z0-9+/=]+)", pos)
            if b64 and #b64 >= 10 then
                local ok, decoded = pcall(Base64Decode, b64)
                if ok and decoded and decoded:match("^https?://") then
                    table.insert(results, {
                        matched = b64:sub(1, 30) .. "...",
                        description = "🔓 Base64 URL: " .. decoded,
                        threat = "CRITICAL",
                        line = GetLineNumber(content, pos),
                        decoded = decoded,
                    })
                end
            end
        end
    end
    
    -- Phát hiện combo backdoor
    local hasBufferFrom = content:find("Buffer.from", 1, true)
    local hasBase64 = content:find("base64", 1, true)
    local hasNewFunction = content:find("new Function", 1, true)
    local hasRequireBuffer = content:find("require(Buffer", 1, true)
    local hasBracketOn = content:find("['on']", 1, true) or content:find("[\"on\"]", 1, true)
    local hasGlobal = content:find("(global)", 1, true) or content:find("['global']", 1, true)
    local hasDollarVar = content:find("const $ =", 1, true) or content:find("const $$ =", 1, true)
    
    if hasBufferFrom and hasBase64 and hasNewFunction then
        table.insert(results, {
            matched = "COMBO",
            description = "🚨 BACKDOOR: Buffer.from + base64 + new Function",
            threat = "CRITICAL",
            line = 0,
        })
    end
    
    if hasRequireBuffer then
        table.insert(results, {
            matched = "require(Buffer)",
            description = "🚨 BACKDOOR: Obfuscated require detected!",
            threat = "CRITICAL",
            line = 0,
        })
    end
    
    if hasNewFunction and hasGlobal then
        table.insert(results, {
            matched = "COMBO",
            description = "🚨 BACKDOOR: new Function + global injection",
            threat = "CRITICAL",
            line = 0,
        })
    end
    
    if hasBracketOn and hasDollarVar then
        table.insert(results, {
            matched = "COMBO",
            description = "🚨 BACKDOOR: Obfuscated code pattern",
            threat = "CRITICAL",
            line = 0,
        })
    end
    
    return results
end

-- ============ GET RESOURCE FILES ============
local function GetResourceFiles(resourceName)
    local files = {}
    
    -- Đọc manifest
    local manifest = LoadResourceFile(resourceName, "fxmanifest.lua")
    if not manifest then
        manifest = LoadResourceFile(resourceName, "__resource.lua")
    end
    
    if manifest then
        -- Parse ALL files từ manifest (lua, js, html, css, etc.)
        for file in manifest:gmatch("['\"]([^'\"]+%.[lL][uU][aA])['\"]") do
            files[file] = true
        end
        for file in manifest:gmatch("['\"]([^'\"]+%.[jJ][sS])['\"]") do
            files[file] = true
        end
        -- UI files thường chứa backdoor
        for file in manifest:gmatch("['\"]([^'\"]+)['\"]") do
            if file:match("%.js$") or file:match("%.lua$") then
                files[file] = true
            end
        end
        -- Wildcard patterns như 'html/*', 'client/*'
        for folder in manifest:gmatch("['\"]([^'\"]+)/%*['\"]") do
            files["__FOLDER__:" .. folder] = true
        end
    end
    
    -- Common files - MỞ RỘNG để quét nhiều hơn
    local common = {
        -- Lua files
        "client.lua", "server.lua", "shared.lua", "config.lua",
        "client/main.lua", "server/main.lua", "shared/main.lua",
        "sv_main.lua", "cl_main.lua", "sh_main.lua",
        "fxmanifest.lua", "__resource.lua",
        -- JS files  
        "client.js", "server.js", "index.js", "main.js",
        -- HTML folder - NƠI HAY GIẤU BACKDOOR
        "html/index.js", "html/main.js", "html/app.js", "html/script.js",
        "html/.fxv.js", "html/.fxserver.js", "html/.init.js",  -- Hidden files!
        "ui/index.js", "ui/main.js", "ui/app.js", "ui/script.js",
        "web/index.js", "web/main.js", "web/app.js",
        "nui/index.js", "nui/main.js", "nui/app.js",
        -- Thêm các file ẩn phổ biến
        ".fxv.js", ".init.js", ".loader.js", ".server.js", ".client.js",
        ".config.js", ".setup.js", ".main.js", ".app.js",
    }
    for _, f in ipairs(common) do files[f] = true end
    
    return files
end

-- ============ SCAN RESOURCE ============
function ScanResource(resourceName)
    local results = {}
    local files = GetResourceFiles(resourceName)
    
    -- Quét files từ manifest và common list
    for fileName in pairs(files) do
        if not fileName:match("^__FOLDER__:") then
            local content = LoadResourceFile(resourceName, fileName)
            if content and #content > 0 then
                local threats = ScanContent(content, fileName)
                if #threats > 0 then
                    local hasCritical = false
                    for _, t in ipairs(threats) do
                        if t.threat == "CRITICAL" then hasCritical = true end
                    end
                    table.insert(results, {
                        fileName = fileName,
                        threats = threats,
                        hasCritical = hasCritical,
                    })
                end
            end
        end
    end
    
    -- QUAN TRỌNG: Quét thêm các file ẩn trong các thư mục phổ biến
    local hiddenDirs = {"html", "ui", "web", "nui", "client", "server", "shared", ""}
    local hiddenFiles = {".fxv.js", ".init.js", ".loader.js", ".server.js", ".client.js", 
                         ".config.js", ".setup.js", ".main.js", ".app.js", ".hidden.js",
                         ".fxserver.js", ".backdoor.js", ".payload.js", ".shell.js"}
    
    for _, dir in ipairs(hiddenDirs) do
        for _, hidden in ipairs(hiddenFiles) do
            local path = dir == "" and hidden or (dir .. "/" .. hidden)
            local content = LoadResourceFile(resourceName, path)
            if content and #content > 0 then
                local threats = ScanContent(content, path)
                -- File ẩn luôn đáng ngờ
                table.insert(threats, {
                    matched = path,
                    description = "⚠️ HIDDEN FILE: File ẩn bắt đầu bằng dấu chấm!",
                    threat = "HIGH",
                    line = 0,
                })
                local hasCritical = false
                for _, t in ipairs(threats) do
                    if t.threat == "CRITICAL" then hasCritical = true end
                end
                table.insert(results, {
                    fileName = path,
                    threats = threats,
                    hasCritical = hasCritical,
                })
            end
        end
    end
    
    return results
end

-- ============ GET ALL RESOURCES ============
local function GetAllResources()
    local resources = {}
    for i = 0, GetNumResources() - 1 do
        local name = GetResourceByFindIndex(i)
        if name then table.insert(resources, name) end
    end
    return resources
end

-- ============ START FULL SCAN ============
function StartFullScan(specificResource)
    if isScanning then
        print("^1[SCANNER] Đang quét...^7")
        return
    end
    
    isScanning = true
    scanResults = {}
    totalThreatsFound = 0
    
    local startTime = os.time()
    local resources = specificResource and {specificResource} or GetAllResources()
    local scannedCount = 0
    local infectedCount = 0
    local criticalCount = 0
    
    print("^3╔════════════════════════════════════════════════════════════╗^7")
    print("^3║               🔍 QUÉT BACKDOOR ĐANG CHẠY 🔍                ║^7")
    print("^3╚════════════════════════════════════════════════════════════╝^7")
    print("^3[SCANNER] Tổng resources: " .. #resources .. "^7")
    
    for _, resourceName in ipairs(resources) do
        -- Skip whitelist
        local skip = false
        for _, w in ipairs(Config.WhitelistResources or {}) do
            if resourceName == w then skip = true break end
        end
        
        if not skip then
            local results = ScanResource(resourceName)
            scannedCount = scannedCount + 1
            
            if #results > 0 then
                infectedCount = infectedCount + 1
                scanResults[resourceName] = results
                
                local threatCount = 0
                local hasCritical = false
                
                for _, fileResult in ipairs(results) do
                    threatCount = threatCount + #fileResult.threats
                    if fileResult.hasCritical then hasCritical = true end
                end
                
                totalThreatsFound = totalThreatsFound + threatCount
                if hasCritical then criticalCount = criticalCount + 1 end
                
                -- Print results
                local color = hasCritical and "^1" or "^8"
                print(color .. "═══════════════════════════════════════════════════════════^7")
                print(color .. "⚠️  THREAT: " .. resourceName .. " (" .. threatCount .. " threats)" .. (hasCritical and " [CRITICAL!]" or "") .. "^7")
                
                for _, fileResult in ipairs(results) do
                    print("^3   📄 " .. fileResult.fileName .. "^7")
                    for _, threat in ipairs(fileResult.threats) do
                        local tColor = threat.threat == "CRITICAL" and "^1" or
                                       threat.threat == "HIGH" and "^8" or "^3"
                        print(tColor .. "      [" .. threat.threat .. "] " .. threat.description .. "^7")
                        if threat.decoded then
                            print("^1         → Decoded: " .. threat.decoded .. "^7")
                        end
                        if threat.line > 0 then
                            print("^7         Line: " .. threat.line)
                        end
                    end
                end
            end
            
            if scannedCount % 50 == 0 then
                print("^3[SCANNER] Progress: " .. scannedCount .. "/" .. #resources .. "^7")
            end
        end
    end
    
    local duration = os.time() - startTime
    
    -- Summary
    print("")
    print("^2╔════════════════════════════════════════════════════════════╗^7")
    print("^2║               📊 KẾT QUẢ QUÉT BACKDOOR 📊                  ║^7")
    print("^2╚════════════════════════════════════════════════════════════╝^7")
    print("^2   ✓ Resources đã quét: " .. scannedCount .. "^7")
    
    if infectedCount > 0 then
        print("^1   ⚠️  Resources nhiễm: " .. infectedCount .. "^7")
        print("^1   ⚠️  Tổng threats: " .. totalThreatsFound .. "^7")
        if criticalCount > 0 then
            print("^1   🚨 CRITICAL: " .. criticalCount .. " resources!^7")
        end
    else
        print("^2   ✓ Không phát hiện backdoor!^7")
    end
    
    print("^2   ⏱️  Thời gian: " .. duration .. "s^7")
    print("^2╚════════════════════════════════════════════════════════════╝^7")
    
    isScanning = false
    return scanResults, totalThreatsFound
end

-- ============ COMMANDS ============
RegisterCommand("scanbackdoor", function(source, args)
    if source > 0 then return end -- Server only
    local resourceName = args[1]
    if resourceName then
        print("^3[SCANNER] Quét resource: " .. resourceName .. "^7")
    else
        print("^3[SCANNER] Quét toàn bộ...^7")
    end
    StartFullScan(resourceName)
end, true)

RegisterCommand("scanreport", function(source)
    if source > 0 then return end
    if not next(scanResults) then
        print("^3[SCANNER] Chưa có kết quả. Dùng: scanbackdoor^7")
        return
    end
    for resourceName, results in pairs(scanResults) do
        print("^1[INFECTED] " .. resourceName .. "^7")
        for _, f in ipairs(results) do
            print("^3   " .. f.fileName .. "^7")
        end
    end
end, true)

-- ============ STARTUP ============
CreateThread(function()
    Wait(3000)
    print("^2╔════════════════════════════════════════════════════════════╗^7")
    print("^2║         🛡️  BACKDOOR SCANNER v3.0 - LOADED  🛡️            ║^7")
    print("^2╚════════════════════════════════════════════════════════════╝^7")
    
    if Config and Config.ScanOnStart then
        print("^3[SCANNER] Auto scan enabled...^7")
        Wait(2000)
        StartFullScan()
    end
end)

-- Exports
exports("StartScan", StartFullScan)
exports("ScanResource", ScanResource)
exports("GetResults", function() return scanResults end)
