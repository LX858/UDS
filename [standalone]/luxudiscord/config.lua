if type(Config) ~= 'table' then
      Config = {}
end

Config.Locale = 'en' -- Language of the bot | Locales folder

--[[ Check if user has discord and is connected to your server ]]
Config.DiscordChecker = {
      enable = false, -- If true, the bot will kick the player if he is not in your discord server
      whitelisted_identifiers = { 'license:3522526646363', 'license:44242432323', }
}

Config.Logs = {
      enable = true,             -- Enable Logs
      user_bypass = {            -- Will not log the user
            -- "956184571139997726" -- Discord ID of the user
            -- , "1053256556467431", '1051508533503467520'

      }
}

Config.Whitelist = {
      enable = false,
      user_bypass = {
            "license:2414141",
            "discord:1051508533503467520",
            "fivem:131321313",
            "steam:13213131313",

      }
}

Config.Permissions = {
      {
            name = "Admin",
            role_id = "1071449479544311943", -- right click on the role and copy id
            fullpermission = true,
            tickets = true,                  -- Can access player reports
            commands = {}
      },
      {
            name = "Moderator",
            role_id = "1071449479544311940",
            tickets = true,
            fullpermission = false,
            commands = {
                  'playerlist',
                  'player',
                  'ban',
                  'tp',
                  'kick',
                  'revive',
            }
      },

}

--[[ Experimental -- DISABLED AT THE MOMENT ]]
--[[ ⚠️ This might crash your server ⚠️ ]]
--[[ ⚠️ Don't Make the interval too low or the frames to high ⚠️ ]]
--[[ Config.Video = {
      frames = 30,     -- How many frames the video will have
      interaval = 100, -- ms | Interaval beteween screenshots
}
 ]]
