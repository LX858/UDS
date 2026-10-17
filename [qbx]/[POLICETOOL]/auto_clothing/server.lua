-- Kiểm tra xem job có trong config không
local function IsConfiguredJob(jobName)
    for _, job in ipairs(Config.Jobs) do
        if job == jobName then
            return true
        end
    end
    return false
end

-- Log khi player thay đổi duty status
AddEventHandler('QBCore:Server:SetDuty', function(src, duty)
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then return end
    
    if IsConfiguredJob(Player.PlayerData.job.name) then
        if duty then
            if Config.Debug then
                print(('[Auto Clothing] %s (%s) [%s] đã on duty - Đồng phục sẽ được áp dụng'):format(
                    Player.PlayerData.name,
                    Player.PlayerData.citizenid,
                    Player.PlayerData.job.name
                ))
            end
        else
            if Config.Debug then
                print(('[Auto Clothing] %s (%s) [%s] đã off duty - Quần áo thường sẽ được khôi phục'):format(
                    Player.PlayerData.name,
                    Player.PlayerData.citizenid,
                    Player.PlayerData.job.name
                ))
            end
            exports.XNClothes:ForceUnequipBag(src)
        end
    end
end)

-- Command để reload config (admin only)
lib.addCommand('reloaduniforms', {
    help = 'Reload auto clothing config (Admin Only)',
    restricted = 'admin'
}, function(source)
    local src = source
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div class="chat-message system"><b>SYSTEM:</b> Auto clothing config đã được reload!</div>',
    })
end)

print('^2[Auto Clothing]^7 Resource đã khởi động thành công!')
print('^2[Auto Clothing]^7 Jobs được cấu hình:')
for _, job in ipairs(Config.Jobs) do
    print('^3  - ' .. job .. '^7')
end
