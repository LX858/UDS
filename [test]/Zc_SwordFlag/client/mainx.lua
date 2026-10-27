UIloaded = false
local adminMenuOpen = false
function CreateTeamData(NumBer)
    for i = 1, NumBer do
        TeamData[i] = {
            TeamName = Config.TeamData[i].TeamName,
            PicTeam = Config.TeamData[i].PicTeam,
            CountPeople = 0,
            ColorTeam = Config.TeamData[i].ColorTeam,
            ColorBG = Config.TeamData[i].ColorBG,
            ColorBGSelect = Config.TeamData[i].ColorBGSelect,
            ColorSelect = Config.TeamData[i].ColorSelect,
            TeamFull = Config.MaxPlayersPerTeam
        }
    end
end

function LoadUI()
    SendNUIMessage({
        type = 'FirstLoad',
        InventoryHub = Config.UISETTING.InventoryHud,
        DetailServer = Config.UISETTING.DetailServer,
        ButtonAcceptEvent = Config.UISETTING.ButtonAcceptEvent,
        ButtonDeniedEvent = Config.UISETTING.ButtonDeniedEvent,
        DefaultColorStart = Config.UISETTING.DefaultColorUI,
        WinnerRewards = Config.Rewards.WinnerDefault
    })
end

RegisterNetEvent('zcxSwordflag')
AddEventHandler('zcxSwordflag', function(tk) zcx = tk end)

RegisterNetEvent('yip:cl:openmenuadmin')
AddEventHandler('yip:cl:openmenuadmin', function(data)
    local itemList = {}
    -- if data then
    --     itemList = data
    -- end

    local invData = exports.ox_inventory:Items()
    for k, v in pairs(invData) do
        local item = {
            name = k
        }
        table.insert(itemList, item)
    end
    if next(itemList) == nil then
        itemList = GetItems()
    end

    if next(itemList) == nil then
        print("No items found.")
        return
    end

    SendNUIMessage({ type = 'OpenMenuAdmin', DataItem = itemList })
    adminMenuOpen = true
    SetNuiFocus(true, true)
end)

function GetItems()
    local items = {}
    local inventory = exports.ox_inventory:GetPlayerItems()
    for i = 1, #inventory do
        local item = inventory[i]

        if item_name == item.name and item.count > 0 then
            table.insert(items, item)
        end
    end
    return items
end

RegisterNetEvent('zcSword_End')
AddEventHandler('zcSword_End', function()
    if not MyTeam then
        CancleNojoin()
    else
    end
end)


RegisterNetEvent('zcSword_Cancle')
AddEventHandler('zcSword_Cancle', function()
    if not MyTeam then return end
    if SwordStart then Cancle() end
end)

DataGame = { [1] = 'Select', [2] = 'Random' }
RegisterNUICallback('StarGame', function(data, cb)
    cb("ok")
    if Config.TeamData[data.CountTeamToPlayer] then
        TriggerServerEvent('yip:sv:startevent', DataGame[data.TypeGamePlay],
            data.CountTeamToPlayer, data.TimeEvent, data.DataItemSelect)

        SendNUIMessage({ type = 'CloseMenuAdmin' })
        adminMenuOpen = false
        SetNuiFocus(false, false)
    else
        Notify(
            'Số đội không đúng như bạn cấu hình. Vui lòng kiểm tra Config.TeamData.',
            'error')
        adminMenuOpen = false
        TriggerServerEvent('yip:sv:clear')
        SetNuiFocus(false, false)
    end
end)

RegisterNUICallback('closex', function(data, cb)
    cb("ok")
    if adminMenuOpen then
        adminMenuOpen = false
        TriggerServerEvent('yip:sv:clear')
    end
    closeUI()
end)

RegisterNUICallback('Ready', function(data, cb)
    cb("ok")
    LoadUI()
    UIloaded = true
end)


RegisterNUICallback('SelectTeam', function(data, cb)
    cb("ok")
    if not Register then return end
    if SwordStart then
        Notify('Hoạt động đã bắt đầu.', 'error')
        return
    end
    if TeamData[data.numberTeam].CountPeople >=
        Config.MaxPlayersPerTeam then
        Notify('Đội đã đầy đủ.', 'error')
        return
    end
    closeUI()
    MyTeam = data.numberTeam
    TriggerServerEvent('zcSword_SelectTeam', MyTeam)
end)


RegisterNetEvent('zcSword_AddTeamMember')
AddEventHandler('zcSword_AddTeamMember', function(Team)
    if TeamData[Team].CountPeople >=
        Config.MaxPlayersPerTeam then
        Notify(
            'Đội ngũ đã đầy đủ. Vui lòng chọn lại.',
            'error')
        return
    end
    MyTeam = Team
end)

RegisterNetEvent('zcSword_AddTeamtoUI')
AddEventHandler('zcSword_AddTeamtoUI', function(Team)
    TeamData[Team].CountPeople = TeamData[Team].CountPeople + 1
    if MyTeam == Team then
        SendNUIMessage({
            type = 'UpdateTeamSelect',
            SelectTeamName = TeamData[Team].TeamName,
            SelectTeamColor = TeamData[Team].ColorBGSelect,
            CountPeopleTeamSelect = TeamData[Team].CountPeople,
            DefaultColorTeam = TeamData[Team].ColorSelect
        })
        Wait(100)
        SendNUIMessage({
            type = 'CountPeopleTeam',
            CountPeopleTeamSelect = TeamData[Team].CountPeople
        })
    end

    UpdateUITeam(TeamData)
end)


local savedAppearance

function Changeback()
    if savedAppearance then
        exports['illenium-appearance']:setPedAppearance(PlayerPedId(), savedAppearance)
        savedAppearance = nil
    end
end

function ApplyTeamOutfit(teamCloth)
    local ped = PlayerPedId()
    local cloth = GetEntityModel(ped) == joaat('mp_f_freemode_01') and teamCloth.female or teamCloth.male
    if not cloth then return end

    exports['illenium-appearance']:setPedComponents(ped, {
        { component_id = 11, drawable = cloth.torso_1, texture = cloth.torso_2 or 0 },
        { component_id = 4, drawable = cloth.pants_1, texture = cloth.pants_2 or 0 },
        { component_id = 3, drawable = cloth.arms, texture = cloth.arms_2 or 0 }
    })
end

function SetCloth()
    savedAppearance = exports['illenium-appearance']:getPedAppearance(PlayerPedId())
    local MyCloth = Config.TeamData[MyTeam].Cloth
    ApplyTeamOutfit(MyCloth)
    if Config.LockOutfit then
        Inteam(MyCloth)
    end
end
