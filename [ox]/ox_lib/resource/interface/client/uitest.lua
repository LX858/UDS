--[[
    Test commands to preview every ox_lib UI in game.

    /uitest              list all test commands
    /uitest_notify       the four notification types
    /uitest_progress     progress bar (press X to cancel)
    /uitest_circle       progress circle (press X to cancel)
    /uitest_context      context menu with a sub menu
    /uitest_menu         list menu (arrow keys, Enter, Esc)
    /uitest_input        input dialog with every field type
    /uitest_amount       small "how many items" input dialog
    /uitest_alert        confirm / cancel alert
    /uitest_radial       radial menu
    /uitest_textui       [E] prompt on / off
    /uitest_interact     world [E] interaction points on / off
    /uitest_skillcheck   skill check (press E in the cyan zone)
    /uitest_all          quick tour of the HUD parts
    /uifix               cursor stuck? frees it without restarting

    Turn them off on a live server with:  setr ox:uiTestCommands 0
]]

if GetConvarInt('ox:uiTestCommands', 1) ~= 1 then return end

local function notify(description, type)
    lib.notify({ description = description, type = type or 'inform' })
end

local commands = {}

-- Gives the cursor back and closes every ox_lib window.
local function freeCursor()
    if lib.getOpenContextMenu() then lib.hideContext() end
    if lib.getOpenMenu() then lib.hideMenu() end
    lib.hideRadial()
    lib.closeInputDialog()
    lib.closeAlertDialog()
    lib.resetNuiFocus()
end

local function command(name, help, fn)
    commands[#commands + 1] = ('/%s  %s'):format(name, help)
    RegisterCommand(name, function()
        CreateThread(function()
            -- A failing test must never leave the cursor stuck on screen.
            local ok, err = pcall(fn)
            if not ok then
                freeCursor()
                lib.print.error(('%s failed: %s'):format(name, err))
            end
        end)
    end)
end

-- Rescue: frees the mouse cursor without restarting ox_lib.
RegisterCommand('uifix', function() pcall(freeCursor); lib.resetNuiFocus() end)

command('uitest_notify', 'notifications', function()
    lib.notify({ description = 'Grabbed 7 items off the shelf', type = 'inform', duration = 8000 })
    Wait(300)
    lib.notify({ description = "You don't have enough room in your inventory to pick this up", type = 'error', duration = 8000 })
    Wait(300)
    lib.notify({ title = 'Vehicle stored', description = 'Your **Karin Kuruma** is in the garage', type = 'success', duration = 8000 })
    Wait(300)
    lib.notify({ title = 'Low fuel', description = 'Find a gas station soon', type = 'warning', duration = 8000 })
end)

command('uitest_progress', 'progress bar', function()
    local done = lib.progressBar({
        label = 'Grabbing item...',
        duration = 6000,
        canCancel = true,
        disable = { combat = true },
        anim = { dict = 'mp_common', clip = 'givetake1_a', flag = 49 },
    })
    notify(done and 'Progress finished' or 'Progress cancelled', done and 'success' or 'error')
end)

command('uitest_circle', 'progress circle', function()
    local done = lib.progressCircle({ label = 'Using Armour', duration = 6000, position = 'bottom', canCancel = true })
    notify(done and 'Progress finished' or 'Progress cancelled', done and 'success' or 'error')
end)

command('uitest_context', 'context menu', function()
    local recipes = {}

    for i = 1, 9 do
        recipes[i] = {
            title = ('x%d'):format(i),
            icon = 'burger',
            onSelect = function() notify(('Dropped %d bun%s'):format(i, i > 1 and 's' or ''), 'success') end,
        }
    end

    recipes[#recipes + 1] = {
        title = 'Special order',
        description = 'Opens another menu',
        icon = 'clipboard-list',
        menu = 'uitest_context_sub',
        metadata = { { label = 'Stock', value = '12 left', progress = 40 } },
    }
    recipes[#recipes + 1] = { title = 'Out of buns', icon = 'ban', disabled = true }

    lib.registerContext({
        id = 'uitest_context_sub',
        title = 'Special Order',
        subtitle = 'Pick a size',
        menu = 'uitest_context',
        options = {
            { title = 'Small', icon = 'mug-hot', description = 'One patty', onSelect = function() notify('Small order placed', 'success') end },
            { title = 'Large', icon = 'burger', description = 'Double patty, extra cheese', onSelect = function() notify('Large order placed', 'success') end },
            { title = 'Kitchen stock', icon = 'box', progress = 65, readOnly = true },
        },
    })

    lib.registerContext({ id = 'uitest_context', title = 'Drop Bun', subtitle = 'Select Recipe', options = recipes })
    lib.showContext('uitest_context')
end)

command('uitest_menu', 'list menu', function()
    lib.registerMenu({
        id = 'uitest_menu',
        title = 'Vehicle Menu',
        position = 'top-left',
        options = {
            { label = 'Engine', icon = 'car-battery', description = 'Turn the engine on or off' },
            { label = 'Doors', icon = 'door-open', values = { 'Front left', 'Front right', 'Trunk' }, description = 'Left / right to change door' },
            { label = 'Neon lights', icon = 'lightbulb', checked = true },
            { label = 'Fuel', icon = 'gas-pump', progress = 64 },
            { label = 'Windows', icon = 'window-maximize', close = false },
        },
    }, function(selected, scrollIndex)
        notify(('Picked option %d%s'):format(selected, scrollIndex and (' (value %d)'):format(scrollIndex) or ''), 'success')
    end)

    lib.showMenu('uitest_menu')
end)

command('uitest_input', 'input dialog (all fields)', function()
    local input = lib.inputDialog('Police Locker', {
        { type = 'input', label = 'Locker number', placeholder = '420', description = 'The number on the locker door', icon = 'hashtag', required = true },
        { type = 'input', label = 'PIN', password = true, icon = 'lock', max = 4 },
        { type = 'select', label = 'Locker type', options = { { value = 'evidence', label = 'Evidence' }, { value = 'personal', label = 'Personal' } }, default = 'evidence' },
        { type = 'number', label = 'Amount', default = 3, min = 1, max = 10, icon = 'receipt' },
        { type = 'checkbox', label = 'Lock after closing', checked = true },
        { type = 'slider', label = 'Volume', min = 0, max = 100, default = 40 },
        { type = 'date', label = 'Date', icon = 'calendar', default = true, format = 'DD/MM/YYYY' },
        { type = 'textarea', label = 'Notes', placeholder = 'Write something...' },
    }, { size = 'sm' })

    notify(input and ('Locker %s saved'):format(input[1]) or 'Dialog closed', input and 'success' or 'inform')
end)

command('uitest_amount', 'small amount dialog', function()
    local input = lib.inputDialog('', {
        { type = 'input', label = 'How many items would you like to grab? (MAX: 6)', default = '1', max = 1 },
    })

    if input then notify(('Grabbed %s items off the shelf'):format(input[1])) end
end)

command('uitest_alert', 'alert dialog', function()
    local answer = lib.alertDialog({
        header = 'Sell vehicle?',
        content = 'You will get **$12,500** for your Karin Kuruma. This cannot be undone.',
        centered = true,
        cancel = true,
    })

    notify(('You pressed: %s'):format(answer), answer == 'confirm' and 'success' or 'error')
end)

command('uitest_radial', 'radial menu', function()
    lib.registerRadial({
        id = 'uitest_radial_interact',
        items = {
            { label = 'Give ID', icon = 'id-card', onSelect = function() notify('Showed your ID') end },
            { label = 'Search', icon = 'magnifying-glass', onSelect = function() notify('Searching...') end },
            { label = 'Escort', icon = 'people-arrows', onSelect = function() notify('Escorting') end },
        },
    })

    lib.addRadialItem({
        { id = 'uitest_health', label = 'Inspect Health', icon = 'pump-medical', onSelect = function() notify('You look healthy', 'success') end },
        { id = 'uitest_emotes', label = 'Emotes', icon = 'hand-sparkles', onSelect = function() notify('Emote menu') end },
        { id = 'uitest_interact', label = 'Player Interact', icon = 'user-gear', menu = 'uitest_radial_interact' },
    })

    -- Open it like pressing the radial key, once the chat box has let go of the cursor.
    Wait(200)
    ExecuteCommand('+ox_lib-radial')
    ExecuteCommand('-ox_lib-radial')

    -- Take the test slices out again once the radial menu is closed.
    Wait(500)
    while IsNuiFocused() do Wait(250) end

    lib.removeRadialItem('uitest_health')
    lib.removeRadialItem('uitest_emotes')
    lib.removeRadialItem('uitest_interact')
end)

local interactIds

command('uitest_interact', 'world [E] interaction points on / off', function()
    if interactIds then
        for i = 1, #interactIds do lib.removeInteraction(interactIds[i]) end
        interactIds = nil
        return notify('Test interaction points removed')
    end

    -- A point 1.5 m in front of you at shelf height.
    local coords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 1.5, 0.3)
    local grabbed = 0

    interactIds = {
        lib.addInteraction({
            coords = coords,
            distance = 1.5,
            interactDst = 0.7,
            options = {
                { label = 'Grab Cereals - 35$', action = function() grabbed += 1; notify(('Grabbed %d cereals'):format(grabbed)) end },
                { label = 'Inspect Shelf', action = function() notify('Fully stocked') end },
                { label = 'Hidden option', canInteract = function() return false end },
                { label = 'Return Item', canInteract = function() return grabbed > 0 end, action = function() grabbed -= 1; notify('Item returned') end },
            },
        }),
        lib.addGlobalVehicleInteraction({
            bone = 'wheel_lf',
            distance = 4.0,
            interactDst = 1.5,
            options = { { label = 'Check Tyres', action = function() notify('Tyre pressure is fine', 'success') end } },
        }),
    }

    notify('Look at the ring in front of you and walk up to it. Scroll to change option, E to use.')
end)

local textUiShown = false

command('uitest_textui', '[E] prompt on / off', function()
    textUiShown = not textUiShown

    if textUiShown then
        lib.showTextUI('[E] Grab Cereals - 35$', { position = 'left-center' })
    else
        lib.hideTextUI()
    end
end)

command('uitest_skillcheck', 'skill check', function()
    local success = lib.skillCheck({ 'easy', 'medium', 'hard' }, { 'e' })
    notify(success and 'Skill check passed' or 'Skill check failed', success and 'success' or 'error')
end)

command('uitest_all', 'quick tour', function()
    ExecuteCommand('uitest_notify')
    lib.showTextUI('[E] Grab Cereals - 35$', { position = 'left-center' })
    lib.progressBar({ label = 'Grabbing item...', duration = 5000, canCancel = true })
    lib.hideTextUI()
    textUiShown = false
    lib.progressCircle({ label = 'Using Armour', duration = 4000, position = 'bottom' })
    ExecuteCommand('uitest_context')
end)

command('uitest', 'this list', function()
    lib.notify({
        title = 'ox_lib UI tests',
        description = table.concat(commands, '  \n'),
        duration = 15000,
    })
end)
