-- Global position/scale/rotation offsets (also used in render_scaleform.lua)
xPosEdit = 0.0; yPosEdit = 0.0; zPosEdit = 0.0
xScale   = 0.0; yScale   = 0.0; zScale   = 0.0
xRot     = 0.0; yRot     = 0.0; zRot     = 0.0

local EditorState = { SELECT_OBJECT = 0, RENDER_TELEVISION = 1 }
local EditMode    = { POS = 0, SCALE = 1, ROT = 2 }

local editorRaycastHit  = false
local editorSelectedEntity = 0
local editorEditSpeed   = 5.0E-4
local editorEditMode    = 0
local editorStateMode   = 0
local editorEditModeName = ""

-- Load editor permissions on resource start
CreateThread(function()
    TriggerServerEvent(TriggerName("loadPerms"))
end)

-- Main editor input thread (uses Citizen.CreateThread to bypass Debug wrapper)
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if not Config.Editor then
            Wait(1000)
            goto continue
        end

        -- SELECT_OBJECT phase: raycast to highlight TV models
        if editorStateMode == EditorState.SELECT_OBJECT then
            local hit, result, _, _, entityHit = CastRayCast(PlayerPedId(), 4294967295, 10.0, true)
            editorRaycastHit = (1 == result)

            if 1 == result and GetEntityType(entityHit) ~= 0 then
                DrawBoundingBox(GetEntityBoundingBox(entityHit), 125, 125, 255, 125)
                editorSelectedEntity = entityHit
            end

            showSubtitle("Select television with raycast then left click mouse to confirm the television")
        end

        -- RENDER_TELEVISION phase: adjust position/scale/rotation with keys
        if editorStateMode == EditorState.RENDER_TELEVISION then
            -- Tab: cycle edit mode (POS → SCALE → ROT → POS)
            if IsControlJustReleased(1, 21) then
                editorEditMode = editorEditMode + 1
                if editorEditMode == 2 then editorEditMode = 0 end

                if editorEditMode == EditMode.POS then
                    ShowHelpNotification(
                        "~INPUT_SPRINT~ will change size/position\n" ..
                        "~INPUT_PHONE~ ~INPUT_CELLPHONE_DOWN~ up/down speed change\n" ..
                        "~INPUT_VEH_SUB_PITCH_UD~ up/down\n" ..
                        "~INPUT_VEH_SUB_TURN_LEFT_ONLY~ ~INPUT_VEH_SUB_TURN_RIGHT_ONLY~ left/right\n" ..
                        "~INPUT_VEH_FLY_SELECT_TARGET_LEFT~ ~INPUT_VEH_FLY_SELECT_TARGET_RIGHT~ backwards/forward",
                        false, false, 9000000)
                end

                if editorEditMode == EditMode.SCALE then
                    ShowHelpNotification(
                        "~INPUT_SPRINT~ will change size/position\n" ..
                        "~INPUT_PHONE~ ~INPUT_CELLPHONE_DOWN~ up/down speed change\n" ..
                        "~INPUT_VEH_SUB_PITCH_UD~ up/down\n" ..
                        "~INPUT_VEH_SUB_TURN_LEFT_ONLY~ ~INPUT_VEH_SUB_TURN_RIGHT_ONLY~ left/right\n",
                        false, false, 9000000)
                end
            end

            -- Speed controls
            if IsControlPressed(1, 27) then editorEditSpeed = editorEditSpeed + 5.0E-6 end
            if IsControlPressed(1, 173) then
                editorEditSpeed = editorEditSpeed - 5.0E-6
                if editorEditSpeed <= 0.0 then editorEditSpeed = 5.0E-6 end
            end

            -- Up (numpad 8 / VEH_SUB_PITCH_UD up)
            if IsControlPressed(1, 127) then
                if editorEditMode == EditMode.POS   then zPosEdit = zPosEdit + editorEditSpeed end
                if editorEditMode == EditMode.SCALE then yScale   = yScale   + editorEditSpeed end
                if editorEditMode == EditMode.ROT   then zRot     = zRot     + editorEditSpeed end
            end
            -- Down
            if IsControlPressed(1, 126) then
                if editorEditMode == EditMode.POS   then zPosEdit = zPosEdit - editorEditSpeed end
                if editorEditMode == EditMode.SCALE then yScale   = yScale   - editorEditSpeed end
                if editorEditMode == EditMode.ROT   then zRot     = zRot     - editorEditSpeed end
            end
            -- Left
            if IsControlPressed(1, 124) then
                if editorEditMode == EditMode.POS   then xPosEdit = xPosEdit - editorEditSpeed end
                if editorEditMode == EditMode.SCALE then xScale   = xScale   + editorEditSpeed end
                if editorEditMode == EditMode.ROT   then xRot     = xRot     - editorEditSpeed end
            end
            -- Right
            if IsControlPressed(1, 125) then
                if editorEditMode == EditMode.POS   then xPosEdit = xPosEdit + editorEditSpeed end
                if editorEditMode == EditMode.SCALE then xScale   = xScale   - editorEditSpeed end
                if editorEditMode == EditMode.ROT   then xRot     = xRot     + editorEditSpeed end
            end
            -- Forward (sub turn left)
            if IsControlPressed(0, 117) then
                if editorEditMode == EditMode.POS then yPosEdit = yPosEdit - editorEditSpeed end
                if editorEditMode == EditMode.ROT then yRot     = yRot     - editorEditSpeed end
            end
            -- Backward
            if IsControlPressed(0, 118) then
                if editorEditMode == EditMode.POS then yPosEdit = yPosEdit + editorEditSpeed end
                if editorEditMode == EditMode.ROT then yRot     = yRot     + editorEditSpeed end
            end

            -- Update mode name for subtitle
            if editorEditMode == EditMode.POS   then editorEditModeName = "positon"  end
            if editorEditMode == EditMode.SCALE then editorEditModeName = "scale"    end
            if editorEditMode == EditMode.ROT   then editorEditModeName = "rotation" end

            showSubtitle("Left click on mouse to save! Atm you're changing: " .. editorEditModeName .. ", edit speed: " .. editorEditSpeed)
        end

        ::continue::
    end
end)

-- NUI callback: user declined the editor save dialog
RegisterNUICallback("declined", function(data, cb)
    SetNuiFocus(false, false)
    if cb then cb("ok") end
end)

-- Command: toggle editor mode
RegisterCommand("tveditor", function(source, args, rawCommand)
    if IsPlayerInGroup(Config.CommandPermissions.tveditor, "command.tveditor") then
        Config.Editor = not Config.Editor

        if not Config.Editor then
            DestroyDuiAndScaleform()
            TriggerServerEvent("rcore_television:fetchCache")
            ShowHelpNotification("  ", false, false, 1)
        end

        -- Reset all editor state
        xPosEdit = 0.0; yPosEdit = 0.0; zPosEdit = 0.0
        xScale   = 0.0; yScale   = 0.0; zScale   = 0.0
        xRot     = 0.0; yRot     = 0.0; zRot     = 0.0
        editorRaycastHit    = false
        editorSelectedEntity = 0
        editorEditSpeed     = 5.0E-4
        editorEditMode      = 0
        editorStateMode     = 0
        editorEditModeName  = ""
    else
        TriggerEvent("chat:addMessage", { args = {
            "^1SYSTEM",
            "Warning you do not have permission to open this command. You did not added the 'add_ace' or you dont have on your character 'add_principal'"
        }})
        TriggerEvent("chat:addMessage", { args = {
            "^1SYSTEM",
            "Second option is: Go to your 'Live Console' and type command /tvgrantpermission [ID]"
        }})
    end
end)

-- Key binding: mouse left click — confirm selected object or save editor config
RegisterKey(function()
    if not Config.Editor then return end

    ClearPedTasksImmediately(PlayerPedId())

    if editorStateMode == EditorState.RENDER_TELEVISION then
        local exportData = {
            Job            = "nil",
            ItemToOpen     = "nil",
            ScreenOffSet   = vector3(xPosEdit, yPosEdit, zPosEdit),
            ScreenSize     = vector3(xScale, yScale, zScale),
            distanceToOpen = Config.DefaultOpenDistance,
            distance       = Config.visibleDistance,
            CameraOffSet   = {
                x = 0.0, y = -3.0, z = 0.35,
                rotationOffset = vector3(0, 0, 0),
            },
        }

        local exportString = Dump(exportData, true)
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "display_for_copy",
            text = "[" .. GetEntityModel(editorSelectedEntity) .. "] = " .. exportString .. ",",
        })
        ExecuteCommand("tveditor")
        return
    end

    if editorStateMode == EditorState.SELECT_OBJECT then
        if editorRaycastHit then
            editorStateMode = EditorState.RENDER_TELEVISION

            local modelHash = GetEntityModel(editorSelectedEntity)
            if not Config.resolution[modelHash] then
                Config.resolution[modelHash] = { fake = true }
            end

            DestroyDuiAndScaleform()
            CreateVirtualTelevision("editor_tv", {
                URL                = "https://rco.re/product/television/ingame/detector_tv.png",
                entity             = editorSelectedEntity,
                ModelHash          = modelHash,
                DisableCountTime   = true,
                DisableInteraction = true,
            })

            ShowHelpNotification(
                "~INPUT_SPRINT~ will change size/position\n" ..
                "~INPUT_PHONE~ ~INPUT_CELLPHONE_DOWN~ up/down speed change\n" ..
                "~INPUT_VEH_SUB_PITCH_UD~ up/down\n" ..
                "~INPUT_VEH_SUB_TURN_LEFT_ONLY~ ~INPUT_VEH_SUB_TURN_RIGHT_ONLY~ left/right\n" ..
                "~INPUT_VEH_FLY_SELECT_TARGET_LEFT~ ~INPUT_VEH_FLY_SELECT_TARGET_RIGHT~ backwards/forward",
                false, false, 9000000)
        end
    end
end, "television_mouse_click", "Mouse left", "MOUSE_LEFT", "MOUSE_BUTTON")

-- Utility: display subtitle text on screen
function showSubtitle(text)
    BeginTextCommandPrint("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandPrint(1000, 1)
end

-- Build a polygon matrix from 8 bounding box corners (12 triangles)
function GetBoundingBoxPolyMatrix(corners)
    return {
        { corners[3], corners[2], corners[1] },
        { corners[4], corners[3], corners[1] },
        { corners[5], corners[6], corners[7] },
        { corners[5], corners[7], corners[8] },
        { corners[3], corners[4], corners[7] },
        { corners[8], corners[7], corners[4] },
        { corners[1], corners[2], corners[5] },
        { corners[6], corners[5], corners[2] },
        { corners[2], corners[3], corners[6] },
        { corners[3], corners[7], corners[6] },
        { corners[5], corners[8], corners[4] },
        { corners[5], corners[4], corners[1] },
    }
end

-- Build an edge matrix from 8 bounding box corners (12 edges)
function GetBoundingBoxEdgeMatrix(corners)
    return {
        { corners[1], corners[2] },
        { corners[2], corners[3] },
        { corners[3], corners[4] },
        { corners[4], corners[1] },
        { corners[5], corners[6] },
        { corners[6], corners[7] },
        { corners[7], corners[8] },
        { corners[8], corners[5] },
        { corners[1], corners[5] },
        { corners[2], corners[6] },
        { corners[3], corners[7] },
        { corners[4], corners[8] },
    }
end

-- Get world-space bounding box corners of an entity (8 corners)
function GetEntityBoundingBox(entity)
    local modelHash = GetEntityModel(entity)
    local minDim, maxDim = GetModelDimensions(modelHash)
    local pad = 0.001
    local corners = {}

    local offsets = {
        { minDim.x - pad, minDim.y - pad, minDim.z - pad },
        { maxDim.x + pad, minDim.y - pad, minDim.z - pad },
        { maxDim.x + pad, maxDim.y + pad, minDim.z - pad },
        { minDim.x - pad, maxDim.y + pad, minDim.z - pad },
        { minDim.x - pad, minDim.y - pad, maxDim.z + pad },
        { maxDim.x + pad, minDim.y - pad, maxDim.z + pad },
        { maxDim.x + pad, maxDim.y + pad, maxDim.z + pad },
        { minDim.x - pad, maxDim.y + pad, maxDim.z + pad },
    }

    for i, offset in ipairs(offsets) do
        corners[i] = GetOffsetFromEntityInWorldCoords(entity, offset[1], offset[2], offset[3])
    end

    return corners
end

-- Draw filled polygons from a poly matrix with RGBA color
function DrawPolyMatrix(polyMatrix, r, g, b, a)
    for _, tri in pairs(polyMatrix) do
        DrawPoly(
            tri[1].x, tri[1].y, tri[1].z,
            tri[2].x, tri[2].y, tri[2].z,
            tri[3].x, tri[3].y, tri[3].z,
            r, g, b, a)
    end
end

-- Draw lines from an edge matrix
function DrawEdgeMatrix(edgeMatrix)
    for _, edge in pairs(edgeMatrix) do
        DrawLine(
            edge[1].x, edge[1].y, edge[1].z,
            edge[2].x, edge[2].y, edge[2].z)
    end
end

-- Draw a filled + outlined bounding box on a set of corners
function DrawBoundingBox(corners, r, g, b, a)
    DrawPolyMatrix(GetBoundingBoxPolyMatrix(corners), r, g, b, a)
    DrawEdgeMatrix(GetBoundingBoxEdgeMatrix(corners))
end

-- Convenience: get corners then draw bounding box
function DrawEntityBoundingBox(entity, r, g, b, a)
    DrawBoundingBox(GetEntityBoundingBox(entity), r, g, b, a)
end
