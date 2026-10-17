-- Multilingual support integrated
-- Based on glitchdetector's multilingual system
local DEBUG = false
local function debugLog() end
if DEBUG then debugLog = function(...)
    print(...)
end end

local LANG_ENUM = {
    [0] = "american",
    [1] = "french",
    [2] = "german",
    [3] = "italian",
    [4] = "spanish",
    [5] = "portuguese",
    [6] = "polish",
    [7] = "russian",
    [8] = "korean",
    [9] = "chinesetraditional",
    [10] = "japanese",
    [11] = "mexican",
    [12] = "chinesesimplified",
    [13] = "vietnamese",
}

local function LoadLanguageFile(resource, file)
    -- Force Vietnamese language
    local lang = 13 -- Vietnamese
    local json_data = LoadResourceFile(resource, file)
    if json_data then
        local lang_data = json.decode(json_data)
        if lang_data and type(lang_data) == 'table' then
            -- Always load american labels as base
            local american_entries = lang_data["american"]
            if american_entries then
                for _, entry_data in next, american_entries do
                    if entry_data["LABEL"] and entry_data["TRANSLATION"] then
                        AddTextEntry(entry_data["LABEL"], entry_data["TRANSLATION"])
                    end
                end
            else
                debugLog("failed to load", file, "from", resource, "(missing base translation)")
            end
            
            -- Load client language on top if not american
            if lang ~= 0 then
                local lang_name = LANG_ENUM[lang] or "american"
                local lang_entries = lang_data[lang_name]
                if lang_entries then
                    for _, entry_data in next, lang_entries do
                        if entry_data["LABEL"] and entry_data["TRANSLATION"] then
                            AddTextEntry(entry_data["LABEL"], entry_data["TRANSLATION"])
                        end
                    end
                else
                    debugLog("failed to load", file, "from", resource, "(missing language " .. lang_name .. ")")
                end
            end
        else
            debugLog("failed to load", file, "from", resource, "(invalid data)")
        end
    else
        debugLog("failed to load", file, "from", resource)
    end
end

-- Auto-load lang.json
CreateThread(function()
    Wait(100) -- Small delay to ensure resource is fully loaded
    LoadLanguageFile(GetCurrentResourceName(), 'lang.json')
end)
