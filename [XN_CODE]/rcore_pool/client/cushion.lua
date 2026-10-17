
function sqr(x)
    return x * x
end

function dist2(a, b)
    return sqr(a.x - b.x) + sqr(a.y - b.y)
end

function distToSegmentSquared(point, segA, segB)
    local segLenSq = dist2(segA, segB)
    if segLenSq == 0 then
        return dist2(point, segA)
    end

    local t = ((point.x - segA.x) * (segB.x - segA.x) + (point.y - segA.y) * (segB.y - segA.y)) / segLenSq
    t = math.max(0, math.min(1, t))

    return dist2(point, vector2(
        segA.x + t * (segB.x - segA.x),
        segA.y + t * (segB.y - segA.y)
    ))
end

function isPositionCollidingWithWall(walls, position)
    for _, wall in pairs(walls) do
        if distToSegmentSquared(position, wall[1], wall[2]) - BALL_RADIUS * BALL_RADIUS < 0.0 then
            return true
        end
    end
    return false
end

function getReflectionVector(wallA, wallB, velocity)
    local dx = wallA.x - wallB.x
    local dy = wallB.y - wallA.y
    local len = math.sqrt(dy * dy + dx * dx)
    local normalX = dx / len
    local normalY = dy / len

    local dot = velocity.x * normalY + velocity.y * normalX
    return vector2(
        velocity.x - 2 * dot * normalY,
        velocity.y - 2 * dot * normalX
    )
end

-- Returns 0 = collinear, 1 = clockwise, 2 = counterclockwise
function GetTripletOrientation(p, q, r)
    local val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
    if val == 0 then return 0 end
    return val > 0 and 1 or 2
end

-- Checks if point q lies within the bounding box of segment p→r
function IsPointOnSegment(p, q, r)
    return q.x <= math.max(p.x, r.x) and q.x >= math.min(p.x, r.x)
       and q.y <= math.max(p.y, r.y) and q.y >= math.min(p.y, r.y)
end

function DoSegmentsIntersect(p1, p2, p3, p4)
    local o1 = GetTripletOrientation(p1, p2, p3)
    local o2 = GetTripletOrientation(p1, p2, p4)
    local o3 = GetTripletOrientation(p3, p4, p1)
    local o4 = GetTripletOrientation(p3, p4, p2)

    if o1 ~= o2 and o3 ~= o4 then return true end

    if o1 == 0 and IsPointOnSegment(p1, p3, p2) then return true end
    if o2 == 0 and IsPointOnSegment(p1, p4, p2) then return true end
    if o3 == 0 and IsPointOnSegment(p3, p1, p4) then return true end
    if o4 == 0 and IsPointOnSegment(p3, p2, p4) then return true end

    return false
end

function findIntersection(p1, p2, p3, p4)
    if not DoSegmentsIntersect(p1, p2, p3, p4) then
        return nil
    end

    local d1 = p1.x * p2.y - p1.y * p2.x
    local d2 = p3.x * p4.y - p3.y * p4.x
    local denom = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x)

    local x = (d1 * (p3.x - p4.x) - (p1.x - p2.x) * d2) / denom
    local y = (d1 * (p3.y - p4.y) - (p1.y - p2.y) * d2) / denom

    return vector2(x, y)
end

-- Helper: builds a wall segment as a pair of world-space offsets from the table entity
function BuildTableWallSegment(tableEntity, x1, y1, x2, y2, z)
    return {
        GetOffsetFromEntityInWorldCoords(tableEntity, x1, y1, z),
        GetOffsetFromEntityInWorldCoords(tableEntity, x2, y2, z)
    }
end

function computeTableCushionColliders(tableEntity, model)
    local z           = 0.89
    local r           = BALL_RADIUS
    local tableOffset = TABLE_OFFSET[model]
    local minX        = -0.84283
    local minY        = -1.225585
    local maxX        =  0.697048
    local maxY        =  1.482726

    local colliders = {}

    -- ── prop_pooltable_02 cushion segments ──────────────────────────────────
    local seg02 = {
        BuildTableWallSegment(tableEntity, minX + 0.11,          minY + 0.0105 + r,   maxX - 0.11,          minY + 0.0105 + r,   z),
        BuildTableWallSegment(tableEntity, maxX - 0.11,          minY + 0.0105 + r,   maxX + 0.0,           minY - 0.07,          z),
        BuildTableWallSegment(tableEntity, minX + 0.0,           minY - 0.07,         minX + 0.11,          minY + 0.0105 + r,   z),
        BuildTableWallSegment(tableEntity, maxX - 0.013 - r,     minY + 0.112,        maxX - 0.013 - r,     0.013,               z),
        BuildTableWallSegment(tableEntity, maxX + 0.07,          minY + 0.0,          maxX - 0.013 - r,     minY + 0.112,         z),
        BuildTableWallSegment(tableEntity, maxX - 0.013 - r,     0.013,               maxX + 0.08,          0.08,                z),
        BuildTableWallSegment(tableEntity, maxX - 0.013 - r,     minY + 0.112 + 1.3599, maxX - 0.013 - r,  1.3729,              z),
        BuildTableWallSegment(tableEntity, maxX + 0.09,          minY + 1.4,          maxX - 0.013 - r,     minY + 0.112 + 1.3599, z),
        BuildTableWallSegment(tableEntity, maxX - 0.013 - r,     1.3729,              maxX + 0.07,          1.47,                z),
        BuildTableWallSegment(tableEntity, minX + 0.113,         maxY - 0.009 - r,    maxX - 0.1139,        maxY - 0.009 - r,    z),
        BuildTableWallSegment(tableEntity, minX + 0.0,           maxY + 0.07,         minX + 0.113,         maxY - 0.009 - r,    z),
        BuildTableWallSegment(tableEntity, maxX - 0.1139,        maxY - 0.009 - r,    maxX - 0.01,          maxY + 0.07,         z),
        BuildTableWallSegment(tableEntity, minX + 0.011 + r,     minY + 0.1111 + 1.3599, minX + 0.011 + r,  1.3729,             z),
        BuildTableWallSegment(tableEntity, minX - 0.12,          minY + 0.025 + 1.3599, minX + 0.011 + r,   minY + 0.1111 + 1.3599, z),
        BuildTableWallSegment(tableEntity, minX + 0.011 + r,     1.3729,              minX - 0.085,         1.4899,              z),
        BuildTableWallSegment(tableEntity, minX + 0.011 + r,     minY + 0.1111,       minX + 0.011 + r,     0.0133,             z),
        BuildTableWallSegment(tableEntity, minX - 0.07,          minY + 0.0,          minX + 0.011 + r,     minY + 0.1111,       z),
        BuildTableWallSegment(tableEntity, minX + 0.011 + r,     0.0133,              minX - 0.1,           0.09,               z),
    }
    colliders[GetHashKey("prop_pooltable_02")] = seg02

    -- ── prop_pooltable_3b cushion segments (same geometry + tableOffset) ────
    local ox = tableOffset.x
    local oy = tableOffset.y

    local seg3b = {
        BuildTableWallSegment(tableEntity, ox + minX + 0.11,          oy + minY + 0.0105 + r,   ox + maxX - 0.11,          oy + minY + 0.0105 + r,   z),
        BuildTableWallSegment(tableEntity, ox + maxX - 0.11,          oy + minY + 0.0105 + r,   ox + maxX + 0.0,           oy + minY - 0.07,          z),
        BuildTableWallSegment(tableEntity, ox + minX + 0.0,           oy + minY - 0.07,         ox + minX + 0.11,          oy + minY + 0.0105 + r,   z),
        BuildTableWallSegment(tableEntity, ox + maxX - 0.013 - r,     oy + minY + 0.112,        ox + maxX - 0.013 - r,     oy + 0.013,               z),
        BuildTableWallSegment(tableEntity, ox + maxX + 0.07,          oy + minY + 0.0,          ox + maxX - 0.013 - r,     oy + minY + 0.112,         z),
        BuildTableWallSegment(tableEntity, ox + maxX - 0.013 - r,     oy + 0.013,               ox + maxX + 0.08,          oy + 0.08,                z),
        BuildTableWallSegment(tableEntity, ox + maxX - 0.013 - r,     oy + minY + 0.112 + 1.3599, ox + maxX - 0.013 - r,  oy + 0.013 + 1.3599,      z),
        BuildTableWallSegment(tableEntity, ox + maxX + 0.09,          oy + minY + 1.4,          ox + maxX - 0.013 - r,     oy + minY + 0.112 + 1.3599, z),
        BuildTableWallSegment(tableEntity, ox + maxX - 0.013 - r,     oy + 0.013 + 1.3599,      ox + maxX + 0.07,          oy + 1.47,                z),
        BuildTableWallSegment(tableEntity, ox + minX + 0.113,         oy + maxY - 0.009 - r,    ox + maxX - 0.1139,        oy + maxY - 0.009 - r,    z),
        BuildTableWallSegment(tableEntity, ox + minX + 0.0,           oy + maxY + 0.07,         ox + minX + 0.113,         oy + maxY - 0.009 - r,    z),
        BuildTableWallSegment(tableEntity, ox + maxX - 0.1139,        oy + maxY - 0.009 - r,    ox + maxX - 0.01,          oy + maxY + 0.07,         z),
        BuildTableWallSegment(tableEntity, ox + minX + 0.011 + r,     oy + minY + 0.1111 + 1.3599, ox + minX + 0.011 + r,  oy + 0.013 + 1.3599,     z),
        BuildTableWallSegment(tableEntity, ox + minX - 0.12,          oy + minY + 0.025 + 1.3599, ox + minX + 0.011 + r,   oy + minY + 0.1111 + 1.3599, z),
        BuildTableWallSegment(tableEntity, ox + minX + 0.011 + r,     oy + 0.013 + 1.3599,      ox + minX - 0.085,         oy + 0.13 + 1.3599,       z),
        BuildTableWallSegment(tableEntity, ox + minX + 0.011 + r,     oy + minY + 0.1111,       ox + minX + 0.011 + r,     oy + 0.0133,              z),
        BuildTableWallSegment(tableEntity, ox + minX - 0.07,          oy + minY + 0.0,          ox + minX + 0.011 + r,     oy + minY + 0.1111,       z),
        BuildTableWallSegment(tableEntity, ox + minX + 0.011 + r,     oy + 0.0133,              ox + minX - 0.1,           oy + 0.09,                z),
    }
    colliders[GetHashKey("prop_pooltable_3b")] = seg3b

    local resolvedModel = model
    if MODEL_ALIAS[model] then
        resolvedModel = MODEL_ALIAS[model]
    end

    return colliders[resolvedModel]
end
