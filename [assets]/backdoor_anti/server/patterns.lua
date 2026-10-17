--[[
    PATTERNS DATABASE - Cơ sở dữ liệu các mẫu backdoor
    Bao gồm patterns cho cả Lua và JavaScript
]]

Patterns = {}

-- ==================== JAVASCRIPT PATTERNS ====================
Patterns.JavaScript = {
    -- Base64 Encoding/Decoding (rất phổ biến trong backdoor)
    {
        pattern = "Buffer%.from%s*%(%s*['\"].-['\"]%s*,%s*['\"]base64['\"]%s*%)",
        description = "Buffer.from với Base64 decoding",
        threat = "CRITICAL",
        example = "Buffer.from('aHR0cHM=', 'base64')"
    },
    {
        pattern = "atob%s*%(",
        description = "atob() Base64 decoding",
        threat = "HIGH",
        example = "atob('encoded_string')"
    },
    {
        pattern = "btoa%s*%(",
        description = "btoa() Base64 encoding", 
        threat = "MEDIUM",
        example = "btoa('string')"
    },
    
    -- Dynamic Code Execution
    {
        pattern = "new%s+Function%s*%(",
        description = "new Function() - Dynamic code execution",
        threat = "CRITICAL",
        example = "new Function('code')()"
    },
    {
        pattern = "eval%s*%(",
        description = "eval() - Thực thi code động",
        threat = "CRITICAL",
        example = "eval('malicious code')"
    },
    {
        pattern = "Function%s*%(%s*['\"].-['\"]%s*%)",
        description = "Function constructor với string",
        threat = "CRITICAL",
        example = "Function('return this')()"
    },
    
    -- HTTP Requests (suspicious contexts)
    {
        pattern = "require%s*%(%s*['\"]https?['\"]%s*%)",
        description = "Require HTTP/HTTPS module",
        threat = "HIGH",
        example = "require('https')"
    },
    {
        pattern = "require%s*%(%s*Buffer%.from",
        description = "Require với Buffer.from (obfuscated)",
        threat = "CRITICAL",
        example = "require(Buffer.from('aHR0cHM=','base64').toString())"
    },
    {
        pattern = "%.get%s*%(%s*[_$%w]+%s*,",
        description = "HTTP GET request pattern",
        threat = "MEDIUM",
        example = "$.get(url, callback)"
    },
    {
        pattern = "%.request%s*%(",
        description = "HTTP request method",
        threat = "MEDIUM",
        example = "http.request(options)"
    },
    
    -- Obfuscation Patterns
    {
        pattern = "%[%s*['\"]on['\"]%s*%]%s*%(",
        description = "Bracket notation for 'on' event",
        threat = "HIGH",
        example = "r['on']('data', callback)"
    },
    {
        pattern = "%$%$%s*%[%s*%d+%s*%]",
        description = "Array index obfuscation",
        threat = "HIGH",
        example = "$$[0], $$[1]"
    },
    {
        pattern = "_%s*=%s*Buffer%.from",
        description = "Underscore variable với Buffer",
        threat = "CRITICAL",
        example = "_ = Buffer.from('url', 'base64')"
    },
    {
        pattern = "%$%s*=%s*require",
        description = "Dollar sign variable cho require",
        threat = "HIGH",
        example = "$ = require('module')"
    },
    
    -- Suspicious String Patterns
    {
        pattern = "aHR0c[%w%+/=]+",
        description = "Base64 encoded URL (starts with http)",
        threat = "CRITICAL",
        example = "aHR0cHM6Ly8... (https://...)"
    },
    {
        pattern = "statusCode.*200",
        description = "HTTP status code check",
        threat = "MEDIUM",
        example = "r.statusCode === 200"
    },
    
    -- WebSocket/Network
    {
        pattern = "new%s+WebSocket%s*%(",
        description = "WebSocket connection",
        threat = "MEDIUM",
        example = "new WebSocket('ws://...')"
    },
    {
        pattern = "require%s*%(%s*['\"]net['\"]%s*%)",
        description = "Node.js net module",
        threat = "HIGH",
        example = "require('net')"
    },
    {
        pattern = "require%s*%(%s*['\"]child_process['\"]%s*%)",
        description = "Child process module (command execution)",
        threat = "CRITICAL",
        example = "require('child_process')"
    },
    {
        pattern = "require%s*%(%s*['\"]fs['\"]%s*%)",
        description = "File system module",
        threat = "MEDIUM",
        example = "require('fs')"
    },
    
    -- IIFE (Immediately Invoked Function Expression)
    {
        pattern = "%(%s*function%s*%(%s*%)%s*{.-}%s*%)%s*%(%s*%)",
        description = "IIFE pattern (self-executing function)",
        threat = "MEDIUM",
        example = "(function(){...})()"
    },
    {
        pattern = "%(%s*%(%s*%)%s*=>%s*{.-}%s*%)%s*%(%s*%)",
        description = "Arrow function IIFE",
        threat = "MEDIUM",
        example = "(() => {...})()"
    },
}

-- ==================== LUA PATTERNS ====================
Patterns.Lua = {
    -- Dynamic Code Execution
    {
        pattern = "load%s*%(",
        description = "load() - Load và thực thi Lua code",
        threat = "CRITICAL",
        example = "load('code')()"
    },
    {
        pattern = "loadstring%s*%(",
        description = "loadstring() - Thực thi string code",
        threat = "CRITICAL",
        example = "loadstring('malicious code')()"
    },
    {
        pattern = "loadfile%s*%(",
        description = "loadfile() - Load file và thực thi",
        threat = "HIGH",
        example = "loadfile('script.lua')()"
    },
    {
        pattern = "dofile%s*%(",
        description = "dofile() - Thực thi file Lua",
        threat = "HIGH",
        example = "dofile('script.lua')"
    },
    {
        pattern = "assert%s*%(%s*load",
        description = "assert(load()) pattern",
        threat = "CRITICAL",
        example = "assert(load(code))()"
    },
    
    -- HTTP Requests
    {
        pattern = "PerformHttpRequest%s*%(",
        description = "PerformHttpRequest - HTTP request",
        threat = "MEDIUM",
        example = "PerformHttpRequest(url, callback)"
    },
    {
        pattern = "PerformHttpRequest%s*%([^,]*base64",
        description = "PerformHttpRequest với Base64",
        threat = "CRITICAL",
        example = "PerformHttpRequest(decode(base64_url))"
    },
    
    -- Base64 Patterns
    {
        pattern = "base64[_%w]*decode",
        description = "Base64 decode function",
        threat = "HIGH",
        example = "base64_decode(), base64decode()"
    },
    {
        pattern = "from_base64",
        description = "from_base64 decode",
        threat = "HIGH",
        example = "from_base64('encoded')"
    },
    {
        pattern = "aHR0c[%w%+/=]+",
        description = "Base64 encoded URL",
        threat = "CRITICAL",
        example = "aHR0cHM6Ly8... (https://...)"
    },
    
    -- String Manipulation (obfuscation)
    {
        pattern = "string%.char%s*%(.-%d+.-%d+.-%d+",
        description = "string.char() obfuscation",
        threat = "HIGH",
        example = "string.char(104,116,116,112)"
    },
    {
        pattern = "string%.byte%s*%(",
        description = "string.byte() conversion",
        threat = "LOW",
        example = "string.byte('a')"
    },
    {
        pattern = "string%.reverse%s*%(",
        description = "string.reverse() - Có thể dùng để obfuscate",
        threat = "LOW",
        example = "string.reverse('dlrow')"
    },
    {
        pattern = "table%.concat%s*%(.+string%.char",
        description = "table.concat với string.char (obfuscation)",
        threat = "HIGH",
        example = "table.concat({string.char(...)...})"
    },
    
    -- Suspicious Function Calls
    {
        pattern = "_G%s*%[",
        description = "_G[] - Global table access",
        threat = "MEDIUM",
        example = "_G['function_name']()"
    },
    {
        pattern = "rawset%s*%(%s*_G",
        description = "rawset(_G) - Modify global table",
        threat = "HIGH",
        example = "rawset(_G, 'var', value)"
    },
    {
        pattern = "rawget%s*%(%s*_G",
        description = "rawget(_G) - Access global table",
        threat = "MEDIUM",
        example = "rawget(_G, 'var')"
    },
    {
        pattern = "getfenv%s*%(",
        description = "getfenv() - Get function environment",
        threat = "HIGH",
        example = "getfenv(func)"
    },
    {
        pattern = "setfenv%s*%(",
        description = "setfenv() - Set function environment",
        threat = "HIGH",
        example = "setfenv(func, env)"
    },
    {
        pattern = "debug%.getinfo",
        description = "debug.getinfo - Get debug info",
        threat = "MEDIUM",
        example = "debug.getinfo(func)"
    },
    {
        pattern = "debug%.setlocal",
        description = "debug.setlocal - Modify local variables",
        threat = "HIGH",
        example = "debug.setlocal(level, index, value)"
    },
    {
        pattern = "debug%.setupvalue",
        description = "debug.setupvalue - Modify upvalues",
        threat = "HIGH",
        example = "debug.setupvalue(func, index, value)"
    },
    
    -- File Operations
    {
        pattern = "io%.open%s*%(",
        description = "io.open - File operations",
        threat = "MEDIUM",
        example = "io.open('file', 'r')"
    },
    {
        pattern = "io%.popen%s*%(",
        description = "io.popen - Execute command",
        threat = "CRITICAL",
        example = "io.popen('command')"
    },
    {
        pattern = "os%.execute%s*%(",
        description = "os.execute - System command execution",
        threat = "CRITICAL",
        example = "os.execute('rm -rf /')"
    },
    {
        pattern = "os%.remove%s*%(",
        description = "os.remove - Delete file",
        threat = "HIGH",
        example = "os.remove('file')"
    },
    {
        pattern = "os%.rename%s*%(",
        description = "os.rename - Rename/Move file",
        threat = "MEDIUM",
        example = "os.rename('old', 'new')"
    },
    
    -- FiveM Specific
    {
        pattern = "RegisterCommand%s*%([^,]*['\"].*eval",
        description = "RegisterCommand với eval trong tên",
        threat = "CRITICAL",
        example = "RegisterCommand('eval', ...)"
    },
    {
        pattern = "RegisterNetEvent%s*%([^)]*backdoor",
        description = "Event với tên chứa 'backdoor'",
        threat = "CRITICAL",
        example = "RegisterNetEvent('backdoor_event')"
    },
    {
        pattern = "TriggerServerEvent%s*%([^)]*exec",
        description = "Server event với 'exec' trong tên",
        threat = "HIGH",
        example = "TriggerServerEvent('exec_code')"
    },
    {
        pattern = "TriggerClientEvent%s*%([^)]*%-1",
        description = "TriggerClientEvent to all players",
        threat = "LOW",
        example = "TriggerClientEvent('event', -1)"
    },
    {
        pattern = "ExecuteCommand%s*%(",
        description = "ExecuteCommand - Run server command",
        threat = "MEDIUM",
        example = "ExecuteCommand('sv_maxclients 32')"
    },
    
    -- Obfuscated Code Patterns
    {
        pattern = "local%s+[_]+%s*=%s*",
        description = "Underscore variable names (obfuscation)",
        threat = "MEDIUM",
        example = "local __ = value"
    },
    {
        pattern = "local%s+[Il1|]+%s*=",
        description = "I/l/1 obfuscation pattern",
        threat = "HIGH",
        example = "local IlIlI = value"
    },
    {
        pattern = "local%s+[oO0]+%s*=",
        description = "O/o/0 obfuscation pattern",
        threat = "HIGH",
        example = "local OoOoO = value"
    },
    {
        pattern = "%[%s*['\"][%w_]+['\"]%s*%]%s*%(",
        description = "Bracket function call (obfuscation)",
        threat = "MEDIUM",
        example = "_G['function']()"
    },
    
    -- Network/Discord Webhooks
    {
        pattern = "discord%.com/api/webhooks",
        description = "Discord webhook URL",
        threat = "MEDIUM",
        example = "https://discord.com/api/webhooks/..."
    },
    {
        pattern = "discordapp%.com/api/webhooks",
        description = "Discord webhook URL (old)",
        threat = "MEDIUM",
        example = "https://discordapp.com/api/webhooks/..."
    },
    {
        pattern = "webhook%.site",
        description = "Webhook.site URL",
        threat = "HIGH",
        example = "https://webhook.site/..."
    },
    {
        pattern = "pastebin%.com",
        description = "Pastebin URL (có thể chứa code độc)",
        threat = "HIGH",
        example = "https://pastebin.com/raw/..."
    },
    {
        pattern = "hastebin%.com",
        description = "Hastebin URL",
        threat = "HIGH",
        example = "https://hastebin.com/raw/..."
    },
    {
        pattern = "githubusercontent%.com",
        description = "GitHub raw content URL",
        threat = "MEDIUM",
        example = "https://raw.githubusercontent.com/..."
    },
    
    -- Hex Encoded Strings
    {
        pattern = "\\x[0-9a-fA-F][0-9a-fA-F]\\x[0-9a-fA-F][0-9a-fA-F]",
        description = "Hex encoded string",
        threat = "HIGH",
        example = "\\x68\\x74\\x74\\x70"
    },
    
    -- Citizen/CFX Specific
    {
        pattern = "Citizen%.Await%s*%(%s*Citizen%.InvokeNative",
        description = "Direct native invocation",
        threat = "MEDIUM",
        example = "Citizen.Await(Citizen.InvokeNative(...))"
    },
}

-- ==================== SUSPICIOUS URLS ====================
Patterns.SuspiciousURLs = {
    "1ls2%.org",
    "0x0%.st",
    "transfer%.sh",
    "file%.io",
    "anonfiles%.com",
    "gofile%.io",
    "mega%.nz",
    "mediafire%.com",
    "zippyshare%.com",
    "uploadfiles%.io",
    "tempfile%.io",
    "filebin%.net",
    "sendspace%.com",
    "wetransfer%.com",
    "dropbox%.com/s/",
    "drive%.google%.com/uc",
    "ngrok%.io",
    "localhost%.run",
    "serveo%.net",
    "portmap%.io",
}

-- ==================== SUSPICIOUS FILE NAMES ====================
Patterns.SuspiciousFileNames = {
    "backdoor",
    "shell",
    "exploit",
    "hack",
    "inject",
    "payload",
    "trojan",
    "malware",
    "keylog",
    "stealer",
    "rat",
    "botnet",
    "crypter",
    "obfuscate",
    "bypass",
    "crack",
}

-- ==================== BASE64 URL PATTERNS ====================
-- Các chuỗi Base64 phổ biến cho URLs
Patterns.Base64Signatures = {
    "aHR0cDov", -- http://
    "aHR0cHM6", -- https://
    "d3d3Lg",   -- www.
    "ZnRwOi8v", -- ftp://
    "d3NzOi8v", -- wss://
    "d3M6Ly8",  -- ws://
}

return Patterns
