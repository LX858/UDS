
-- https://coxdocs.dev/ox_lib/Modules/Logger/Server

--- Send a structured log entry via ox_lib's logger.
--- @param  src     number          Player server ID (0 for server-side actions)
--- @param  action  string          Short action identifier
--- @param  message string          Description of the event
--- @param  tags    table           Key-value metadata attached to the log entry
--- @return nil
function CreateLog(src, action, message, tags)
    --print(string.format("[LOG] Action: %s | Message: %s | Tags: %s", action, message, json.encode(tags)))
    lib.logger(src, action, message, tags)
end