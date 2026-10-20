---@class Percentage:Class
Percentage = class()

---@param name string
---@param total table
function Percentage:Init(name, total, items)
    self.name = name
    self.total = total
    self.items = items
    self.processing = false
    self.queues = {}

    -- Cấu hình penalty cho vật phẩm hiếm (có thể tùy chỉnh)
    self.penaltyConfig = {
        { threshold = 5, penalty = 0.2 },  -- <= 5 item: giảm 80%
        { threshold = 10, penalty = 0.3 }, -- <= 10 item: giảm 70%
        { threshold = 20, penalty = 0.5 }, -- <= 20 item: giảm 50%
        { threshold = 35, penalty = 0.7 }, -- <= 35 item: giảm 30%
        { threshold = 50, penalty = 0.85 } -- <= 50 item: giảm 15%
    }

    local rates = LoadResourceFile(GetCurrentResourceName(), ("percentage/%s.json"):format(name))

    if rates then
        self.rates = json.decode(rates)
        local totalRate = 0
        for k, v in pairs(self.rates) do
            totalRate = totalRate + v
        end
        print(("Loaded percentage %s with total rate %d"):format(name, totalRate))
    else
        self:CreateRates()
    end
end

function Percentage:CreateRates()
    self.rates = {}
    local totalRate = 0
    for _, reward in pairs(self.items) do
        totalRate = totalRate + (reward.rate or 0)
    end
    for _, reward in pairs(self.items) do
        local qty = (reward.rate / totalRate) * self.total
        self.rates[tostring(reward.id)] = math.floor(qty)
    end

    SaveResourceFile(GetCurrentResourceName(), ("percentage/%s.json"):format(self.name),
        json.encode(self.rates, { indent = true }), -1)
end

function Percentage:RemoveRate(itemId)
    if self.rates[tostring(itemId)] then
        self.rates[tostring(itemId)] = self.rates[tostring(itemId)] - 1
        SaveResourceFile(GetCurrentResourceName(), ("percentage/%s.json"):format(self.name),
            json.encode(self.rates, { indent = true }), -1)
    end
end

function Percentage:GetRates()
    local rates = {}
    for i = 1, #self.items do
        local item = self.items[i]
        local itemId = tostring(item.id)
        if item and itemId and self.rates[itemId] and self.rates[itemId] > 0 then
            table.insert(rates, { item = item, rate = self.rates[itemId] })
        end
    end
    return rates
end

function Percentage:GetDebugInfo()
    local rates = self:GetRates()
    print(("=== Debug Info for %s ==="):format(self.name))
    print("Penalty Configuration:")
    for i = 1, #self.penaltyConfig do
        local config = self.penaltyConfig[i]
        print(("  <= %d items: %.0f%% chance"):format(config.threshold, config.penalty * 100))
    end
    print("Current Item Rates:")
    for i = 1, #rates do
        local rate = rates[i]
        if rate then
            local penalty = 1.0
            for j = 1, #self.penaltyConfig do
                local config = self.penaltyConfig[j]
                if rate.rate <= config.threshold then
                    penalty = config.penalty
                    break
                end
            end
            local adjustedRate = math.max(1, math.floor(rate.rate * penalty))
            print(("  Item %s: Original=%d, Penalty=%.2f, Adjusted=%d"):format(
                rate.item.id, rate.rate, penalty, adjustedRate))
        end
    end
    print("=== End Debug Info ===")
end

function Percentage:GetSum(rates)
    local items = {}
    local sum = 0

    for i = 1, #rates do
        local rate = rates[i]
        if rate then
            -- Áp dụng hệ số penalty dựa trên cấu hình: vật phẩm còn ít càng khó ra
            local penalty = 1.0
            for j = 1, #self.penaltyConfig do
                local config = self.penaltyConfig[j]
                if rate.rate <= config.threshold then
                    penalty = config.penalty
                    break
                end
            end

            -- Đảm bảo tỉ lệ tối thiểu là 1
            local adjustedRate = math.max(1, math.floor(rate.rate * penalty))

            for k = 1, adjustedRate do
                table.insert(items, rate.item)
            end
            sum = sum + adjustedRate
        end
    end

    -- Shuffle items để random
    for i = #items, 2, -1 do
        local j = math.random(1, i)
        items[i], items[j] = items[j], items[i]
    end
    return items, sum
end

function Percentage:GetReward(multiplier, callback)
    table.insert(self.queues, {
        multiplier = multiplier,
        callback = callback
    })
    self:ProcessQueue()
end

function Percentage:ProcessQueue()
    if self.processing then return end
    self.processing = true
    Citizen.CreateThread(function()
        while #self.queues > 0 do
            math.randomseed(os.time() * os.microtime() * #self.queues)
            local rewards = {}
            for i = 1, (self.queues[1].multiplier or 1) do
                ::checkagain::
                local rates = self:GetRates()
                local items, sum = self:GetSum(rates)
                if sum > 0 then
                    math.randomseed(os.time() * os.microtime() * #self.queues * i)
                    local ranId = math.random(1, sum)
                    if items[ranId] then
                        table.insert(rewards, items[ranId])
                    end
                else
                    self:CreateRates()
                    goto checkagain
                end
            end
            local cb = table.remove(self.queues, 1)
            if cb and type(cb.callback) == "function" then
                cb.callback(rewards)
            end
            Wait(25)
        end
        self.processing = false
    end)
end
