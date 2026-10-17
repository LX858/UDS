local Config = require 'config.config'

RegisterNetEvent("1307_logout:client:showlog", function(id, Playerpid, crds, name, icname, cid, reason)
    Display(id, Playerpid, crds, name, icname, cid, reason)
end)

function Display(id, Playerpid, crds, name, icname, cid, reason)
    -- Kiểm tra player có phải police onduty không
    local playerData = QBX.PlayerData
    if not playerData or not playerData.job then return end
    if playerData.job.name ~= 'police' or not playerData.job.onduty then return end
    
    local displaying = true

    CreateThread(function()
        Wait(Config.DrawingTime)
        displaying = false
    end)

    print(Playerpid)
	
    CreateThread(function()
        while displaying do
            Wait(5)
            local pcoords = GetEntityCoords(PlayerPedId())
            if #(pcoords - crds) < 15.0 then
                DrawText3DSecond(crds.x, crds.y, crds.z+0.15, "~b~UNDER STAR")
                DrawText3D(crds.x, crds.y, crds.z, "ID: ~r~"..Playerpid.."~w~ \nTên IC: ~r~"..icname.."~w~\nLý do: ~r~"..reason.."~w~")
                DrawMarker(32, crds.x, crds.y, crds.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 235, 127, 0, 255, false, false, false, true, false, false, false)
            else
                Wait(2000)
            end
        end
    end)
end

function DrawText3D(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    SetTextScale(0.40, 0.40)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(Config.TextColor.r, Config.TextColor.g, Config.TextColor.b, 215)
    SetTextEntry("STRING")
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextDropShadow()
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextOutline()
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
end

function DrawText3DSecond(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    SetTextScale(0.45, 0.45)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(Config.TextColor.r, Config.TextColor.g, Config.TextColor.b, 215)
    SetTextEntry("STRING")
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextDropShadow()
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextOutline()
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
end