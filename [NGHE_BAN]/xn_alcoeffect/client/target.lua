if Config.StomachLavageTarget then
    if Config.StomachLavageTargetType == "ox_target" then
        exports['ox_target']:addGlobalPlayer({
            {
                name = 'NrgScripts:StomachLavage',
                icon = 'fa-solid fa-user-doctor',
                groups = Config.StomachLavageTargetAllow,
                label = _T.ToDoStomachLavage,
                onSelect = function(data)
                    local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                    ToDoStomachLavage(id) 
                end
            },
        })
    elseif Config.StomachLavageTargetType == "qb-target" then
        exports['qb-target']:AddGlobalPlayer({
            options = { 
              { 
              icon = 'fa-solid fa-user-doctor',
              job = Config.StomachLavageTargetAllow,
              label = _T.ToDoStomachLavage,
              action = function(data)
                  local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                  ToDoStomachLavage(id) 
              end      }
            },
            distance = 1.5, 
          })
    else
        print('Nrg:alcoeffect Does not support your target, you can add your target in client/target.lua')
    end

end

