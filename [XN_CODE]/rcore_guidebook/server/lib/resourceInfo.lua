local DOCS_LINK = "https://documentation.rcore.cz/paid-resources/rcore_guidebook"

function IsResourceOnServer(resourceName)
    if GetResourceState(resourceName) == "started" or GetResourceState(resourceName) == "starting" then
        return true
    end
    return false
end

local function getDBWrapperName()
    local dbWrappers = {
        "oxmysql",
        "mysql-async",
        "ghmattimysql"
    }

    for _, wrapper in ipairs(dbWrappers) do
        if IsResourceOnServer(wrapper) then
            return wrapper
        end
    end

    return "unknown"
end

local function printResourceInfoRow(name, value)
    print(string.format("^7%s: ^3%s", name, value))
end

local function getFrameworkName()
    if Config.Framework == 1 then
        return "ESX"
    elseif Config.Framework == 2 then
        return "QBCore"
    end

    return "Other"
end


function PrintResourceInfo()
    print("^3")
    print(GetCurrentResourceName())
    printResourceInfoRow("version", GetResourceMetadata(GetCurrentResourceName(), "version", 0))
    printResourceInfoRow("database", getDBWrapperName())

    if Config then
        printResourceInfoRow("debug", Config.Debug)
        printResourceInfoRow("locale", Config.Locale)
        printResourceInfoRow("licenseType", Config.LicenseType)
        if not Config.Debug then
            printResourceInfoRow("framework", getFrameworkName())
        end

        if Config.Debug then
            print("Framework:")
            printResourceInfoRow("framework", getFrameworkName())
            printResourceInfoRow("fwTriggerResName", Config.FrameworkTriggers.resourceName)
            printResourceInfoRow("fwTriggerLoad", Config.FrameworkTriggers.load)
            printResourceInfoRow("fwTriggerNotify", Config.FrameworkTriggers.notify)

            print("Experimental:")
            printResourceInfoRow("IFrameInsertIntoPage", Config.Experimental.IFrameInsertIntoPage)
        end
    end

    print("Docs: " .. DOCS_LINK)
    print("^7")

    print("Use ^1/" .. Config.Commands.Help .. "^7 to open the guidebook.")
    print("^7")
end

PrintResourceInfo()
