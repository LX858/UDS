
function checkBallInPocket(pocketColliders, ball, tableAddress, posData, time)
    for _, pocketPos in pairs(pocketColliders) do
        local distToPocket = #(ball.position - pocketPos.xy)

        if distToPocket < BALL_RADIUS + POCKET_RADIUS then
            ball.velocity = vector2(0.0, 0.0)
            ball.position = pocketPos.xy
            ball.disabled = true

            table.insert(posData.events, {
                t         = time,
                type      = "pocketed",
                pocket    = pocketPos,
                ball      = ball,
                tableName = tableAddress,
            })

            return true
        end
    end
end

function computePocketColliders(tableEntity, model)
    local tableZ      = 0.89
    local tableOffset = TABLE_OFFSET[model]
    local minX        = -0.84283
    local minY        = -1.225585
    local maxX        =  0.697048
    local maxY        =  1.482726

    local ox = tableOffset.x
    local oy = tableOffset.y

    return {
        GetOffsetFromEntityInWorldCoords(tableEntity, ox + minX - 0.03,  oy + minY - 0.03,  tableZ),
        GetOffsetFromEntityInWorldCoords(tableEntity, ox + maxX + 0.03,  oy + minY - 0.03,  tableZ),
        GetOffsetFromEntityInWorldCoords(tableEntity, ox + maxX + 0.03,  oy + maxY + 0.03,  tableZ),
        GetOffsetFromEntityInWorldCoords(tableEntity, ox + minX - 0.03,  oy + maxY + 0.03,  tableZ),
        GetOffsetFromEntityInWorldCoords(tableEntity, ox + -0.92,        0.125 + oy,        tableZ),
        GetOffsetFromEntityInWorldCoords(tableEntity, ox + 0.77,         0.13  + oy,        tableZ),
    }
end
