-- This fixture proves shared factory results are concrete, not unknown.
local application = LR.CreateApplication({})
application:DefinitelyMissingMethod()

local registry = LR.CreateSideModuleRegistry(LR.SharedModules, LR.SharedModules)
registry:DefinitelyMissingRegistryMethod()

-- This proves the inject-field diagnostic is enabled for source-aware checks.
LR.DefinitelyMissingInjectedField = true
