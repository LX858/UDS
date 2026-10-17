---@class SVCommandImpl : Impl
local Impl = NewImpl("Command")

function Impl:Init()
  self:LogInfo("initialized")
  self:RegisterCommands()
end

function Impl:OnReady()
  self:LogInfo("ready")
end

function Impl:RegisterCommands()
  RegisterCommand("check_weapon_01", function(source, args, rawCommand)
    local users = MySQL.query.await("SELECT * FROM users")
    local weapons = {}
    for _, user in ipairs(users) do
      if not user.inventory then goto continue end
      local inventory = json.decode(user.inventory)
      if not inventory then
        self:LogError("User %s has no inventory", user.identifier)
        goto continue
      end
      for _, item in ipairs(inventory) do
        if not string.match(item.name, "^WEAPON_") then goto continue end
        if not item.metadata then
          self:LogWarning("Weapon %s from %s has no metadata", item.name, user.identifier)
          goto continue
        end
        local serial = item.metadata.serial
        local registeredBy = item.metadata.registered
        if not serial then
          self:LogWarning("Weapon %s from %s has no serial", item.name, user.identifier)
          goto continue
        end
        if not registeredBy then
          --self:LogWarning("Weapon %s from %s has no registeredBy", item.name, user.identifier)
          goto continue
        end
        self:LogInfo("Weapon %s from %s has serial %s and registered by %s", item.name, user.identifier, serial,
          registeredBy)
        table.insert(weapons, {
          name = item.name,
          serial = serial,
          registeredBy = registeredBy,
          owner = user.identifier
        })
      end
      ::continue::
    end

    local oxInventories = MySQL.query.await("SELECT * FROM ox_inventory")
    for _, inventory in ipairs(oxInventories) do
      if not inventory.data then goto continue end
      local items = json.decode(inventory.data)
      if not items then
        self:LogError("Inventory %s has no items", inventory.id)
        goto continue
      end
      for _, item in ipairs(items) do
        if not string.match(item.name, "^WEAPON_") then goto continue end
        if not item.metadata then
          self:LogWarning("Weapon %s from %s has no metadata", item.name, inventory.id)
          goto continue
        end
        local serial = item.metadata.serial
        local registeredBy = item.metadata.registered
        if not serial then
          self:LogWarning("Weapon %s from %s has no serial", item.name, inventory.id)
          goto continue
        end
        if not registeredBy then
          --self:LogWarning("Weapon %s from %s has no registeredBy", item.name, inventory.id)
          goto continue
        end
        self:LogInfo("Weapon %s from %s has serial %s and registered by %s", item.name, inventory.owner or inventory
          .name, serial,
          registeredBy)
        table.insert(weapons, {
          name = item.name,
          serial = serial,
          registeredBy = registeredBy,
          owner = inventory.owner or inventory.name
        })
      end
      ::continue::
    end
    self:LogInfo("Found %d weapons in database", #weapons)
    local weaponIndexBySerial = {}
    for _, weapon in ipairs(weapons) do
      if not weaponIndexBySerial[weapon.serial] then
        self:LogInfo("%s", weapon.serial)
        weaponIndexBySerial[weapon.serial] = {}
      end
      table.insert(weaponIndexBySerial[weapon.serial], weapon)
    end
    for serial, weapons in pairs(weaponIndexBySerial) do
      if #weapons > 1 then
        self:LogWarning("Found %d weapons with serial %s", #weapons, serial)
        for _, weapon in ipairs(weapons) do
          self:LogInfo("Weapon %s from %s has serial %s and registered by %s", weapon.name, weapon.owner, serial,
            weapon.registeredBy)
        end
      end
    end
  end, true)
end
