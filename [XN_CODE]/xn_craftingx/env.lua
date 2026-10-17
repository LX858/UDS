QBCore = exports['qb-core']:GetCoreObject()
Env = {}

--> @type
--> limit (1.1)
--> weight (canCarryItem) (1.2)
Env.InventoryType = 'weight'

--> @path
--> path image of items in inventory
Env.ImagePath = 'nui://ox_inventory/web/images/'

--> @notify
--> notify callback
-- Env.Notify = function(type, message)
--     QBCore.Functions.Notify(message, type, 4000)
-- end

--> @multiply
--> multiply time of crafting each amount
Env.TimeCalculator = 0.3


Env.Debug = false