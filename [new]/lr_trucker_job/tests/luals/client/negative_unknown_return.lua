-- This fixture proves the client factory result is concrete, not unknown.
local application = LR.CreateClientApplication({})
application:DefinitelyMissingMethod()

local nui = LR.CreateClientNui({})
nui:DefinitelyMissingNuiMethod()

local net = LR.CreateClientNet({})
net:DefinitelyMissingNetMethod()

local public = LR.CreateClientPublic({})
public:DefinitelyMissingPublicMethod()

-- This proves the inject-field diagnostic is enabled for source-aware checks.
LR.DefinitelyMissingInjectedField = true
