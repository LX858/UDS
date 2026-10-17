
-- Ball rack layout: each sub-table is one row in the rack (front to back)
BALL_SETUP_STRAIGHT_POOL = {
    {1},
    {10, 3},
    {6, 8, 13},
    {9, 4, 15, 2},
    {14, 11, 5, 12, 7},
}

BALL_SETUP_9_BALL = {
    {1},
    {2, 3},
    {4, 9, 5},
    {6, 7},
    {8},
}

function setupBalls(tableEntity, ballLayout)
    local tableZ      = 0.89
    local tableOffset = TABLE_OFFSET[GetEntityModel(tableEntity)]
    local ballSpacingGap = 0.003

    local balls = {}

    -- Place cue ball first so cueBallIdx = 1
    local cueBallWorldPos = GetOffsetFromEntityInWorldCoords(
        tableEntity,
        -0.043 + tableOffset.x,
        0.825  + tableOffset.y,
        tableZ
    )
    table.insert(balls, {
        entity   = nil,
        velocity = vector2(0.0, 0.0),
        position = cueBallWorldPos.xy,
        ballNum  = -1,
    })

    local cueBallIdx = #balls  -- always 1

    -- Place rack balls row by row
    for rowIdx, rowBalls in pairs(ballLayout) do
        for colIdx, ballNum in pairs(rowBalls) do
            local spacing     = BALL_RADIUS * 2 + ballSpacingGap
            local rowWidth    = spacing * #ballLayout[rowIdx]
            local xOffset     = colIdx * spacing - rowWidth / 2

            local ballWorldPos = GetOffsetFromEntityInWorldCoords(
                tableEntity,
                -0.0025 - xOffset + tableOffset.x,
                -0.41   + tableOffset.y - (rowIdx - 1) * (0.0693 + ballSpacingGap),
                tableZ
            )

            table.insert(balls, {
                entity   = nil,
                velocity = vector2(0.0, 0.0),
                position = ballWorldPos.xy,
                ballNum  = ballNum,
            })
        end
    end

    return {cueBallIdx = cueBallIdx, balls = balls}
end

-- ⚠️ WARNING: This function references `balls`, `cueBallIdx`, `TableEntity`, and `tableOffset`
-- as bare globals. These are NOT defined anywhere in the visible codebase and may be
-- artifacts of an older version. This function appears to be unused / unreachable.
function ResetCueBallWithBallInHand()
    balls[cueBallIdx].disabled = nil

    local cueBallZ      = 0.89 + BALL_RADIUS
    local surfaceCenter = GetOffsetFromEntityInWorldCoords(TableEntity, 0.0, 0.0, cueBallZ)
    local tableHeading  = GetEntityHeading(TableEntity)

    SetEntityCoordsNoOffset(
        balls[cueBallIdx].entity,
        balls[cueBallIdx].position.x,
        balls[cueBallIdx].position.y,
        surfaceCenter.z,
        false, false, false
    )

    for radiusStep = 0.0, 0.5, 0.1 do
        for direction = -1, 1, 2 do
            local candidatePos = GetOffsetFromEntityInWorldCoords(
                TableEntity,
                tableOffset.x - 0.1 + radiusStep * direction,
                0.825 + tableOffset.y,
                cueBallZ
            ).xy

            if not isPositionCollidingWithAnyBall(balls[cueBallIdx].entity, candidatePos) then
                balls[cueBallIdx].position = candidatePos
                CurrentState = STATE_BALL_IN_HAND
                SetupBallInHand(tableHeading + 180.0)
                return
            end

            Wait(0)
        end
    end
end

-- Debug thread: builds a hardcoded table state payload (never dispatched — likely leftover test code)
Citizen.CreateThread(function()
    local debugPayload = {
        serverIds     = {3},
        tablePosition = vec3(-573.989014, 289.086731, 78.176399),
        data = {
            cueBallIdx = 1,
            balls = {
                {position = vec2(-573.945557, 289.911713), ballNum = -1, velocity = vec2(0.0, 0.0)},
                {position = vec2(-574.076599, 288.683685), ballNum =  1, velocity = vec2(0.0, 0.0)},
                {position = vec2(-574.042114, 288.605347), ballNum = 10, velocity = vec2(0.0, 0.0)},
                {position = vec2(-574.126648, 288.614227), ballNum =  3, velocity = vec2(0.0, 0.0)},
                {position = vec2(-574.007629, 288.527008), ballNum =  6, velocity = vec2(0.0, 0.0)},
                {position = vec2(-574.092163, 288.535889), ballNum =  8, velocity = vec2(0.0, 0.0)},
                {position = vec2(-574.176697, 288.544769), ballNum = 13, velocity = vec2(0.0, 0.0)},
                {position = vec2(-573.973145, 288.448669), ballNum =  9, velocity = vec2(0.0, 0.0)},
                {position = vec2(-574.057678, 288.457550), ballNum =  4, velocity = vec2(0.0, 0.0)},
                {position = vec2(-574.142212, 288.466431), ballNum = 15, velocity = vec2(0.0, 0.0)},
                {position = vec2(-574.226746, 288.475342), ballNum =  2, velocity = vec2(0.0, 0.0)},
                {position = vec2(-573.938599, 288.370331), ballNum = 14, velocity = vec2(0.0, 0.0)},
                {position = vec2(-574.023132, 288.379211), ballNum = 11, velocity = vec2(0.0, 0.0)},
                {position = vec2(-574.107666, 288.388123), ballNum =  5, velocity = vec2(0.0, 0.0)},
                {position = vec2(-574.192200, 288.397003), ballNum = 12, velocity = vec2(0.0, 0.0)},
                {position = vec2(-574.276733, 288.405884), ballNum =  7, velocity = vec2(0.0, 0.0)},
            }
        }
    }
end)
