
IsAudioAllowedThisFrame = true

function PlayBallCollisionAudio(entity, volume)
    PlayPoolSound(GetEntityCoords(entity), volume, {"hit_1", "hit_2"})
end

function PlayCueAudio(entity, volume)
    PlayPoolSound(GetEntityCoords(entity), volume, {"cue_hit"})
end

function PlayCushionCollisionSound(entity, volume)
    PlayPoolSound(GetEntityCoords(entity), volume, {"cushion_hit"})
end

function PlayPocketSound(position)
    PlayPoolSound(position, 0.5, {"pocket_1", "pocket_2"})
end

function PlayPoolSound(position, volume, sounds)
    if not IsAudioAllowedThisFrame then return end

    if volume < 0.0 or volume > 1.0 then
        print("INVALID STRENGTH! Must be between 0.0 and 1.0")
        return
    end

    if not LastPedPosition then return end

    if #(LastPedPosition - position) >= 9.5 then return end

    IsAudioAllowedThisFrame = false
    SendNUIMessage({
        transactionType = "playSound",
        position = position,
        volume = volume,
        sounds = sounds
    })

    Citizen.CreateThread(function()
        Wait(0)
        IsAudioAllowedThisFrame = true
    end)
end

Citizen.CreateThread(function()
    while true do
        if IsCloseToAnyTable then
            Wait(200)
        else
            Wait(2000)
        end

        if CurrentState ~= STATE_NONE then
            local camRot = GetGameplayCamRot()
            local camPos = GetGameplayCamCoord()

            SendNUIMessage({
                transactionType = "setOrientation",
                fwd = RotationToDirection(camRot),
                up = vector3(0.0, 0.0, 1.0),
                coord = camPos
            })
        end
    end
end)

function RotationToDirection(rotation)
    local radX = math.pi / 180 * rotation.x
    local radY = math.pi / 180 * rotation.y
    local radZ = math.pi / 180 * rotation.z

    return vector3(
        -math.sin(radZ) * math.abs(math.cos(radX)),
         math.cos(radZ) * math.abs(math.cos(radX)),
         math.sin(radX)
    )
end
