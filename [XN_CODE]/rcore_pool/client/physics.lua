
function HandlePoolPhysics(tableAddress, tableData, posData)
    local stepsPerSecond = 180

    if not tableData.simStartedAt then
        tableData.simStartedAt = GetGameTimer() - GetFrameTime() * 1000
        tableData.simulatedSteps = 0
    end

    local currentTime = GetGameTimer()

    while true do
        local dt = 1 / stepsPerSecond

        for step = 1, stepsPerSecond do
            local stillActive = ProcessPhysicsStep(dt, tableData, tableAddress, posData, currentTime)
            currentTime = currentTime + dt * 1000
            tableData.simulatedSteps = tableData.simulatedSteps + 1

            if not stillActive then
                tableData.active = false
                tableData.simStartedAt = nil
                tableData.simulatedSteps = nil
                return
            end
        end

        Wait(0)
    end
end

function ProcessPhysicsStep(dt, tableData, tableAddress, posData, time)
    local anyBallMoving = false
    local ballPositions = {}

    for _, ball in pairs(tableData.balls) do
        if not ball.disabled then
            if #ball.velocity > 0.005 then
                anyBallMoving = true

                local prevPos = ball.position
                local prevVel = ball.velocity
                local pocketed, newPos, newVel = advanceBall(dt, tableData, tableAddress, ball, posData, time)

                if not pocketed then
                    for _, wall in pairs(tableData.cushionColliders) do
                        local intersection = findIntersection(wall[1], wall[2], prevPos, newPos)
                        if intersection then
                            newVel = getReflectionVector(wall[1], wall[2], newVel) * FRICTION_CUSHION
                            newPos = intersection - (prevVel / #prevVel) * 0.001

                            table.insert(posData.events, {
                                t      = time,
                                type   = "cushionCollision",
                                entity = ball.entity,
                                volume = math.min(1.0, math.max(0.3, #newVel / 8.0))
                            })
                        end
                    end

                    for _, otherBall in pairs(tableData.balls) do
                        if ball.entity ~= otherBall.entity and not otherBall.disabled then
                            local overlap = #(newPos - otherBall.position) - BALL_RADIUS * 2
                            if overlap < -1.0E-5 then
                                local newVel2, collisionScale = circleResolution(ball.entity, newPos, newVel, otherBall)
                                newVel = newVel2
                                newPos = prevPos

                                table.insert(posData.events, {
                                    t      = time,
                                    type   = "ballCollision",
                                    entity = ball.entity,
                                    volume = math.min(1.0, math.max(0.005, collisionScale / 150.0))
                                })
                            end
                        end
                    end

                    ball.position = newPos
                    ball.velocity = newVel
                end
            else
                ball.velocity = vector2(0.0, 0.0)
            end

            ballPositions[ball.entity] = ball.position
        end
    end

    table.insert(posData, {t = time, balls = ballPositions})
    return anyBallMoving
end

function advanceBall(dt, tableData, tableAddress, ball, posData, time)
    local speed = #ball.velocity
    if speed == 0 then return false, ball.position, ball.velocity end

    local newPos = ball.position + ball.velocity * dt
    local velDir = ball.velocity / speed

    local pocketed = checkBallInPocket(tableData.pocketColliders, ball, tableAddress, posData, time)

    local newVelocity = vector2(
        ball.velocity.x - velDir.x * FRICTION_BALL_TABLE * dt,
        ball.velocity.y - velDir.y * FRICTION_BALL_TABLE * dt
    )

    return pocketed, newPos, newVelocity
end

function RenderPreviewShotLine(tableEntity, cueBallPos, cueOffsetPos)
    if not Config.DrawShotPreviewLine then return end

    local tableCoords = GetEntityCoords(tableEntity)
    local modelMin, modelMax = GetModelDimensions(GetEntityModel(tableEntity))

    local cornerBottomLeft  = tableCoords.xy + vector2(modelMin.x + 0.08, modelMin.y + 0.25)
    local cornerBottomRight = tableCoords.xy + vector2(modelMax.x - 0.32, modelMin.y + 0.08)
    local cornerTopLeft     = tableCoords.xy + vector2(modelMin.x + 0.35, modelMax.y - 0.08)
    local cornerTopRight    = tableCoords.xy + vector2(modelMax.x - 0.05, modelMax.y - 0.23)

    local tableWalls = {
        {cornerBottomRight, cornerBottomLeft},
        {cornerBottomLeft,  cornerTopLeft},
        {cornerTopLeft,     cornerTopRight},
        {cornerTopRight,    cornerBottomRight},
    }

    local shotDir     = (cueBallPos.xyz - cueOffsetPos.xyz)
    local shotLen     = #shotDir
    local shotDirNorm = shotDir / shotLen * 3
    local zOffset     = vector3(0.0, 0.0, 0.02)

    local rayStart = cueBallPos + shotDirNorm / 3 * 0.04 + zOffset
    local rayEnd   = cueBallPos + shotDirNorm + zOffset

    for _, wall in pairs(tableWalls) do
        local hitPoint = findIntersection(wall[1], wall[2], rayStart, rayEnd)
        if hitPoint then
            DrawLine(rayStart, vector3(hitPoint.x, hitPoint.y, rayStart.z), 255, 255, 255, 255)
        end
    end
end
