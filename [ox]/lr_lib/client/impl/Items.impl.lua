local Impl = NewImpl("Items")
function Impl:OnReady()
  main:LogInfo("%s ready", self:GetName())
  self.isBusy = false
  self:ExportItems()
end

function Impl:ExportItems()
  exports('useItem', function(data, slot)
    if not Config.Items[data.name] then
      return Framework.ShowNotification("Lỗi Hệ Thống", "error")
    end
    local itemData = Config.Items[data.name]

    if self.isBusy then
      return
    end
    self.isBusy = true
    local success = lib.progressBar({
      duration = itemData.duration,
      label = itemData.label,
      useWhileDead = false,
      canCancel = true,
      disable = itemData.disable or {},
      anim = not cache.vehicle and itemData.anim or nil,
      prop = not cache.vehicle and itemData.prop or nil,
      image = data.name
    })
    if success then
      self.isBusy = false
      if itemData.type == 'hunger' or itemData.type == 'thirst' then
        TriggerServerEvent("lr_lib:sv:addStat", data.name, data.slot)
      end
    else
      self.isBusy = false
    end
  end)
end
