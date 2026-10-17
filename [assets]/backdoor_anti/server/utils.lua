--[[
    UTILITIES - Các hàm tiện ích cho FiveM
]]

Utils = {}

-- Đọc nội dung file (sử dụng LoadResourceFile)
function Utils.ReadFile(path)
    -- Thử đọc bằng io.open trước
    local file = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        return content
    end
    return nil
end

-- Đọc file từ resource
function Utils.ReadResourceFile(resourceName, filePath)
    return LoadResourceFile(resourceName, filePath)
end

-- Ghi file
function Utils.WriteFile(path, content, mode)
    mode = mode or "w"
    local file = io.open(path, mode)
    if not file then return false end
    file:write(content)
    file:close()
    return true
end

-- Append vào file
function Utils.AppendFile(path, content)
    return Utils.WriteFile(path, content, "a")
end

-- Kiểm tra file tồn tại
function Utils.FileExists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

-- Scan thư mục đệ quy (cho Windows)
local function ScanDirectory(path, extension, results)
    results = results or {}
    
    -- Dùng os.execute để tạo file list tạm (workaround cho FiveM)
    local tempFile = path .. "\\_filelist.tmp"
    os.execute('dir "' .. path .. '" /b /s > "' .. tempFile .. '" 2>nul')
    
    local file = io.open(tempFile, "r")
    if file then
        for line in file:lines() do
            if extension then
                if line:lower():match("%." .. extension:lower() .. "$") then
                    table.insert(results, line)
                end
            else
                table.insert(results, line)
            end
        end
        file:close()
        os.remove(tempFile)
    end
    
    return results
end

-- Lấy danh sách files trong thư mục
function Utils.GetFilesInDirectory(path, extension)
    return ScanDirectory(path, extension, {})
end

-- Lấy extension của file
function Utils.GetFileExtension(filename)
    return filename:match("^.+%.(.+)$")
end

-- Lấy tên file từ path
function Utils.GetFileName(path)
    return path:match("([^/\\]+)$")
end

-- Lấy thư mục từ path
function Utils.GetDirectory(path)
    return path:match("(.+)[/\\][^/\\]+$")
end

-- Kiểm tra string có trong whitelist
function Utils.IsWhitelisted(name, whitelist)
    for _, item in ipairs(whitelist) do
        if name == item or name:find(item, 1, true) then
            return true
        end
    end
    return false
end

-- Escape pattern characters
function Utils.EscapePattern(str)
    return str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

-- Lấy số dòng từ position
function Utils.GetLineNumber(content, position)
    local line = 1
    for i = 1, position do
        if content:sub(i, i) == "\n" then
            line = line + 1
        end
    end
    return line
end

-- Lấy context (các dòng xung quanh)
function Utils.GetContext(content, position, contextLines)
    contextLines = contextLines or 2
    local lines = {}
    local currentLine = 1
    local lineStart = 1
    
    for i = 1, #content do
        if content:sub(i, i) == "\n" then
            table.insert(lines, {
                num = currentLine,
                text = content:sub(lineStart, i - 1),
                start = lineStart,
                finish = i - 1
            })
            currentLine = currentLine + 1
            lineStart = i + 1
        end
    end
    -- Last line
    if lineStart <= #content then
        table.insert(lines, {
            num = currentLine,
            text = content:sub(lineStart),
            start = lineStart,
            finish = #content
        })
    end
    
    -- Find which line contains the position
    local targetLine = 1
    for i, line in ipairs(lines) do
        if position >= line.start and position <= line.finish then
            targetLine = i
            break
        end
    end
    
    -- Get context lines
    local context = {}
    local startLine = math.max(1, targetLine - contextLines)
    local endLine = math.min(#lines, targetLine + contextLines)
    
    for i = startLine, endLine do
        local prefix = i == targetLine and ">>> " or "    "
        table.insert(context, prefix .. lines[i].num .. ": " .. lines[i].text)
    end
    
    return table.concat(context, "\n")
end

-- Format thời gian
function Utils.FormatTime(timestamp)
    return os.date("%Y-%m-%d %H:%M:%S", timestamp or os.time())
end

-- Tạo UUID đơn giản
function Utils.GenerateID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

-- Decode Base64
function Utils.Base64Decode(data)
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

-- Kiểm tra có phải Base64 hợp lệ
function Utils.IsBase64(str)
    if not str or #str < 4 then return false end
    if #str % 4 ~= 0 then return false end
    return str:match("^[A-Za-z0-9+/]*=?=?$") ~= nil
end

-- Try decode Base64 và kiểm tra có chứa URL
function Utils.TryDecodeBase64URL(str)
    if not Utils.IsBase64(str) then return nil end
    local success, decoded = pcall(Utils.Base64Decode, str)
    if success and decoded then
        if decoded:match("^https?://") or decoded:match("^wss?://") or decoded:match("^ftp://") then
            return decoded
        end
    end
    return nil
end

-- Truncate string
function Utils.Truncate(str, maxLen)
    maxLen = maxLen or 100
    if #str > maxLen then
        return str:sub(1, maxLen) .. "..."
    end
    return str
end

-- Strip color codes
function Utils.StripColors(str)
    return str:gsub("%^%d", ""):gsub("~%w+~", "")
end

-- Print với màu
function Utils.ColorPrint(color, message)
    local colors = {
        red = "^1",
        green = "^2", 
        yellow = "^3",
        blue = "^4",
        cyan = "^5",
        purple = "^6",
        white = "^7",
        orange = "^8"
    }
    print((colors[color] or "^7") .. message .. "^7")
end

-- Gửi Discord webhook
function Utils.SendDiscordWebhook(webhookUrl, title, description, color, fields)
    if not webhookUrl or webhookUrl == "" then return end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or 16711680, -- Red default
            ["fields"] = fields or {},
            ["footer"] = {
                ["text"] = "Backdoor Anti Scanner | " .. Utils.FormatTime()
            }
        }
    }
    
    PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST', json.encode({
        username = "🛡️ Backdoor Scanner",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Lấy resource path
function Utils.GetResourcePath(resourceName)
    return GetResourcePath(resourceName)
end

-- Lấy tất cả resources
function Utils.GetAllResources()
    local resources = {}
    local numResources = GetNumResources()
    
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            table.insert(resources, resourceName)
        end
    end
    
    return resources
end

-- Kiểm tra resource state
function Utils.GetResourceState(resourceName)
    return GetResourceState(resourceName)
end

return Utils
