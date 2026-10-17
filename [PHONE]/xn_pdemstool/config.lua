Config = {}

Config.Debug = false

-- QBox / QB-Core Framework Name
-- Normally QBox uses qb-core bridge, but we can access it using exports['qb-core'] or exports['qbox'] or just standard QBCore.
-- Since the server uses QBox, we will use the standard QB-Core object.
Config.CoreName = "qb-core"

-- Permission configurations for posting announcements.
-- Minimum grade level required to post to each tab.
Config.Permissions = {
    ["police"] = {
        tab = "police",
        minGrade = 8
    },
    ["ambulance"] = {
        tab = "ems",
        minGrade = 8
    }
}

Config.TableName = "dep_announcements"

-- App information for LB Phone registration
Config.App = {
    identifier = "dep_announcements",
    name = "Thông báo ban ngành",
    description = "Thông báo ban ngành Công an & Y tế",
    developer = "UnderStar",
    defaultApp = true,
    size = 125,
    icon = "https://cdn-icons-png.flaticon.com/512/2645/2645897.png"
}
