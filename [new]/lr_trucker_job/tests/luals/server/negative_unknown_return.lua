-- This fixture proves server factory results are concrete, not unknown.
local application = LR.CreateServerApplication({})
application:DefinitelyMissingMethod()

local net = LR.CreateServerNet({})
net:DefinitelyMissingNetMethod()

local public = LR.CreateServerPublic({})
public:DefinitelyMissingPublicMethod()

-- This proves the inject-field diagnostic is enabled for source-aware checks.
LR.DefinitelyMissingInjectedField = true
