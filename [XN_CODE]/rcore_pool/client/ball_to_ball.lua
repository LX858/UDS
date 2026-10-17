
function GetMoveBakOnVelVector(ball1, ball2, angle)
    local distCm = #(ball1.position - ball2.position) * 100
    local diameterCm = BALL_RADIUS * 2 * 100

    local deflectionAngle = 180.0 - angle - math.deg(math.asin(math.sin(math.rad(angle)) * distCm / diameterCm))
    return math.sin(math.rad(deflectionAngle)) * BALL_RADIUS * 2 / math.sin(math.rad(angle))
end

function makeBallsNotTouch(ball1, ball2)
    if #ball1.velocity <= 0 then return end

    local overlap = #(ball1.position - ball2.position) - BALL_RADIUS * 2
    if overlap >= -0.004 then return end

    local dist = #(ball1.position - ball2.position)
    if dist == 0.0 then return end

    local velDir = ball1.velocity / #ball1.velocity
    local collisionDir = (ball1.position - ball2.position) / dist
    local angleDeg = math.deg(math.atan2(velDir.y - collisionDir.y, velDir.x - collisionDir.x))

    local moveBack
    if angleDeg == 0.0 then
        moveBack = BALL_RADIUS * 2 - dist
    else
        local moveBack1 = GetMoveBakOnVelVector(ball1, ball2, 180.0 - angleDeg)
        local moveBack2 = GetMoveBakOnVelVector(ball1, ball2, angleDeg)
        moveBack = (moveBack1 < moveBack2) and moveBack1 or moveBack2
    end

    if moveBack > 0 then
        ball1.position = ball1.position - velDir * moveBack
    end
end

function isPositionCollidingWithAnyBall(excludeEntity, newPosition, balls)
    for _, ball in pairs(balls) do
        if ball.entity ~= excludeEntity then
            if #(newPosition - ball.position) - BALL_RADIUS * 2 < -1.0E-4 then
                return true
            end
        end
    end
    return false
end

function circleResolution(entity, newPos, newVel, otherBall)
    local dx = newPos.x - otherBall.position.x
    local dy = newPos.y - otherBall.position.y
    local dvx = otherBall.velocity.x - newVel.x
    local dvy = otherBall.velocity.y - newVel.y

    local distSq = dx * dx + dy * dy
    local scalar = (dx * dvx + dy * dvy) / distSq
    local impulseX = dx * scalar
    local impulseY = dy * scalar

    otherBall.velocity = (otherBall.velocity - vector2(impulseX, impulseY)) * FRICTION_BALL_TO_BALL

    local reflectedVel = (newVel + vector2(impulseX, impulseY)) * FRICTION_BALL_TO_BALL
    return reflectedVel, scalar
end
