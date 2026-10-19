-- Server-authoritative crafting. Dependencies are injected so the transaction
-- and security rules can be tested without a running FiveM server.
XnCrafting = {}
function XnCrafting.Create(deps)
    local service = { sessions = {}, locks = {}, refunds = {} }
    local function integer(value, maximum)
        return type(value) == 'number' and value >= 1 and value <= maximum and value % 1 == 0
    end
    function service:Resolve(source, key, requested, quantity)
        if type(key) ~= 'string' or not integer(quantity, deps.config.CraftingSettings.maxQuantityPerCraft) then
            return nil, 'Số lượng chế tạo không hợp lệ'
        end
        local name = type(requested) == 'table' and requested.name or requested
        if type(name) ~= 'string' then return nil, 'Công thức không hợp lệ' end
        local cfg = deps.config.Crafting[key]
        local player = deps.player(source)
        local job = player and player.PlayerData.job
        local grade = job and (type(job.grade) == 'table' and job.grade.level or job.grade) or -1
        if not cfg or not job or job.name ~= cfg.job or job.onduty ~= true
            or (tonumber(grade) or -1) < (cfg.minGrade or 0) then
            return nil, 'Bạn không có quyền hoặc chưa vào ca'
        end
        local coords = deps.coords(source)
        if not coords or not cfg.coords then return nil, 'Không xác định được vị trí' end
        local dx, dy, dz = coords.x - cfg.coords.x, coords.y - cfg.coords.y, coords.z - cfg.coords.z
        if dx * dx + dy * dy + dz * dz > ((cfg.target_radius or 1.5) + 1.0) ^ 2 then
            return nil, 'Bạn đang ở quá xa bàn chế biến'
        end
        local stash
        for id, shop in pairs(deps.config.Shops) do if shop.job == cfg.job then stash = id break end end
        if not stash then return nil, 'Kho không hợp lệ' end
        for _, recipe in ipairs(cfg.recipes or {}) do
            if recipe.name == name then
                if not integer(recipe.count or 1, 10000) or not integer(recipe.duration or 5000, 600000) then break end
                return { stash = stash, recipe = recipe, quantity = quantity, key = key }
            end
        end
        return nil, 'Công thức không hợp lệ'
    end
    function service:Plan(craft)
        local items = deps.items(craft.stash)
        if type(items) ~= 'table' then return nil end
        local needs, removals = {}, {}
        for _, ingredient in ipairs(craft.recipe.ingredients or {}) do
            if type(ingredient.name) ~= 'string' or not integer(ingredient.count, 10000) then return nil end
            needs[ingredient.name] = (needs[ingredient.name] or 0) + ingredient.count * craft.quantity
        end
        if next(needs) == nil then return nil end
        for name, needed in pairs(needs) do
            for _, item in pairs(items) do
                if needed > 0 and item.name == name and item.count > 0 then
                    local count = math.min(item.count, needed)
                    removals[#removals + 1] = { name = name, count = count, metadata = item.metadata, slot = item.slot }
                    needed = needed - count
                end
            end
            if needed > 0 then return nil end
        end
        return removals
    end
    function service:Begin(source, key, requested, quantity)
        local craft, reason = self:Resolve(source, key, requested, quantity)
        if not craft then return false, reason end
        if self.locks[craft.stash] then return false, 'Kho đang xử lý, vui lòng thử lại' end
        if not self:Plan(craft) then return false, 'Kho không đủ nguyên liệu chế biến' end
        self.sessions[source] = {
            key = key, name = craft.recipe.name, quantity = quantity, started = deps.now(),
            duration = (craft.recipe.duration or 5000) * quantity,
        }
        return true
    end
    function service:IsLocked(stash)
        return self.locks[stash] == true or self.locks[tostring(stash):gsub('_sell$', '')] == true
    end
    function service:RetryRefund(stash)
        local removed = self.refunds[stash]
        if not removed then return true end
        for index = #removed, 1, -1 do
            local item = removed[index]
            local ok, added = pcall(deps.add, stash, item.name, item.count, item.metadata, item.slot)
            if not ok or added ~= true then
                deps.log('Craft rollback pending for stash ' .. stash)
                return false
            end
            table.remove(removed, index)
        end
        self.refunds[stash], self.locks[stash] = nil, nil
        return true
    end
    function service:Complete(source, key, requested, quantity)
        local craft, reason = self:Resolve(source, key, requested, quantity)
        if not craft then return false, reason end
        local session = self.sessions[source]
        local elapsed = session and deps.now() - session.started or -1
        if not session or session.key ~= key or session.name ~= craft.recipe.name or session.quantity ~= quantity
            or elapsed < session.duration or elapsed > session.duration + 30000 then
            return false, 'Phiên chế tạo không hợp lệ hoặc chưa đủ thời gian'
        end
        self.sessions[source] = nil -- one completion per server-issued session
        if self.locks[craft.stash] then return false, 'Kho đang xử lý, vui lòng thử lại' end
        self.locks[craft.stash] = true
        local removed = {}
        local ok, result = pcall(function()
            local plan = self:Plan(craft)
            if not plan then return false end
            local count = (craft.recipe.count or 1) * quantity
            if deps.canCarry(craft.stash .. '_sell', craft.recipe.name, count) ~= true then return false end
            for _, item in ipairs(plan) do
                if deps.remove(craft.stash, item.name, item.count, item.metadata, item.slot) ~= true then return false end
                removed[#removed + 1] = item
            end
            return deps.add(craft.stash .. '_sell', craft.recipe.name, count) == true
        end)
        if not ok or not result then
            self.refunds[craft.stash] = removed
            self:RetryRefund(craft.stash)
            return false, 'Chế tạo thất bại; nguyên liệu đã trừ được hoàn lại (nếu kho gián đoạn sẽ tự thử lại)'
        end
        self.locks[craft.stash] = nil
        return true, craft
    end
    return service
end
