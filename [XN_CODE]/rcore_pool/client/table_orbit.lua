
function GetTableBorderPosition(tableEntity, cueBallEntity, heading)
    local model       = GetEntityModel(tableEntity)
    local modelMin, modelMax = GetModelDimensions(model)
    local tableOffset = TABLE_OFFSET[model]

    local ox = tableOffset.x
    local oy = tableOffset.y

    local edgeTopRight    = GetOffsetFromEntityInWorldCoords(tableEntity,  1.1 + ox, modelMax.y + oy + 0.3,  1.0)
    local edgeTopLeft     = GetOffsetFromEntityInWorldCoords(tableEntity, -1.1 + ox, modelMax.y + oy + 0.3,  1.0)
    local edgeBottomLeft  = GetOffsetFromEntityInWorldCoords(tableEntity, -1.1 + ox, modelMin.y + oy - 0.3,  1.0)
    local edgeBottomRight = GetOffsetFromEntityInWorldCoords(tableEntity,  1.1 + ox, modelMin.y + oy - 0.3,  1.0)

    local cueBallCoords = GetEntityCoords(cueBallEntity)
    local rayDir = vector3(
        math.cos(math.rad(heading - 10.0)),
        math.sin(math.rad(heading - 10.0)),
        0.0
    )

    local rayEnd    = (cueBallCoords + rayDir).xy
    local rayOrigin = cueBallCoords.xy

    local borderSegments = {
        {edgeTopRight.xy,    edgeBottomRight.xy},
        {edgeBottomRight.xy, edgeBottomLeft.xy},
        {edgeBottomLeft.xy,  edgeTopLeft.xy},
        {edgeTopRight.xy,    edgeTopLeft.xy},
    }

    local borderPos2D = closestIntersection(rayEnd, rayOrigin, borderSegments)

    return vector3(borderPos2D.x, borderPos2D.y, edgeBottomRight.z)
end

function closestIntersection(point, origin, segments)
    local closestDist = 9.9999999E7
    local closestPoint = nil

    for _, seg in pairs(segments) do
        local ix, iy = intersection(point, origin, seg[1].xy, seg[2].xy)
        local candidate = vector2(ix, iy)
        local dist = #(candidate - point)

        if dist < closestDist then
            closestDist = dist
            closestPoint = candidate
        end
    end

    return closestPoint, closestDist
end

-- Returns the raw intersection x, y of lines (p1→p2) and (p3→p4)
-- Note: unlike findIntersection in cushion.lua, this does NOT check if segments actually cross
function intersection(p1, p2, p3, p4)
    local denom = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x)
    local d1    = p1.x * p2.y - p1.y * p2.x
    local d2    = p3.x * p4.y - p3.y * p4.x

    local x = (d1 * (p3.x - p4.x) - (p1.x - p2.x) * d2) / denom
    local y = (d1 * (p3.y - p4.y) - (p1.y - p2.y) * d2) / denom

    return x, y
end
