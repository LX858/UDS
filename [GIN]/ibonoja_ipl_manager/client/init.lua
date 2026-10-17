-- IBONOJA IPL Manager - Client Entry Point
-- Initializes configs and keybind to open the IPL Manager menu

ClientConfig, Count = Setup.defaultConfigs()

lib.addKeybind({
    name = "ibonoja_ipl_manager_kb",
    description = "Open Ibonoja IPL manager",
    onPressed = function()
        if Count == 0 then
            lib.notify({
                id = "ibonoja_ipl_manager_no_resources",
                title = "Ibonoja IPL Manager",
                description = "No IPLs are available to manage",
                type = "error"
            })
            return
        end

        local hasAccess = lib.callback.await("ibonoja_ipl_manager:checkRestrictions")
        if not hasAccess then
            lib.notify({
                id = "ibonoja_ipl_manager_no_access",
                title = "Ibonoja IPL Manager",
                description = "You do not have access to manage any IPL",
                type = "error"
            })
            return
        end

        lib.showMenu("new_ipl_manager_main_menu")
    end
})
