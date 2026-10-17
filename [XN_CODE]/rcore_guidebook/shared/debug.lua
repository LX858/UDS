function SPrint(msg, ...)
    return string.format(msg, ...)
end

function IsDebugAllowed(level)
    if Config.Debug then
        if isTable(Config.DebugLevel) and not table.isEmpty(Config.DebugLevel) then
            for _, lev in pairs(Config.DebugLevel) do
                if lev == level then
                    return true
                end
            end
            return false
        else
            if level == Config.DebugLevel then
                return true
            end
            return false
        end
    end
end

function RDebug()
    local self = {}
    self.prefix = 'rcore'

    self.menu = function(type, msg, ...)
        if IsDebugAllowed('MENU') then
            self.prefix = 'rcore_menu'
            self[type](msg, ...)
            self.prefix = 'rcore'
        end
    end

    self.info = function(msg, ...)
        if IsDebugAllowed('INFO') then
            print('^5[' .. self.prefix .. '|info] ^7' .. SPrint(msg, ...))
        end
    end
    self.print = function(msg, ...)
        print('^5[' .. self.prefix .. '|info] ^7' .. SPrint(msg, ...))
    end
    self.success = function(msg, ...)
        if IsDebugAllowed('SUCCESS') then
            print('^5[' .. self.prefix .. '|success] ^7' .. SPrint(msg, ...))
        end
    end
    self.critical = function(msg, ...)
        if IsDebugAllowed('CRITICAL') then
            print('^1[' .. self.prefix .. '|critical] ^7' .. SPrint(msg, ...))
        end
    end
    self.error = function(msg, ...)
        if IsDebugAllowed('ERROR') then
            print('^1[' .. self.prefix .. '|error] ^7' .. SPrint(msg, ...))
        end
    end
    self.warning = function(msg, ...)
        if IsDebugAllowed('WARNING') then
            print('^3[' .. self.prefix .. '|warning] ^7' .. SPrint(msg, ...))
        end
    end
    self.security = function(msg, ...)
        if IsDebugAllowed('SECURITY') then
            print('^3[' .. self.prefix .. '|security] ^7' .. SPrint(msg, ...))
        end
    end
    self.securitySpam = function(msg, ...)
        if IsDebugAllowed('SECURITY_SPAM') then
            print('^3[' .. self.prefix .. '|security] ^7' .. SPrint(msg, ...))
        end
    end
    self.debug = function(msg, ...)
        if IsDebugAllowed('DEBUG') then
            print('^2[' .. self.prefix .. '|debug] ^7' .. SPrint(msg, ...))
        end
    end
    self.setupPrefix = function(prefix)
        self.prefix = prefix
    end
    self.getPrefix = function()
        return self.prefix
    end
    return self
end

exports('rdebug', RDebug)

function DPrint(str, ...)
    local dbg = RDebug()
    dbg.info(str, ...)
end
