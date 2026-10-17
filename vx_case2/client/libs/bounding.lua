---@class Bounding:Class
Bounding = class({name = "BoundingBox"})

-- Helper: Rotate 1 vector theo rotation XYZ
local function RotateVector(vec, rot)
    local radX = math.rad(rot.x)
    local radY = math.rad(rot.y)
    local radZ = math.rad(rot.z)

    local cosX = math.cos(radX)
    local sinX = math.sin(radX)
    local cosY = math.cos(radY)
    local sinY = math.sin(radY)
    local cosZ = math.cos(radZ)
    local sinZ = math.sin(radZ)

    local x = vec.x
    local y = vec.y
    local z = vec.z

    -- X Axis
    local y1 = y * cosX - z * sinX
    local z1 = y * sinX + z * cosX
    y = y1
    z = z1

    -- Y Axis
    local z2 = z * cosY - x * sinY
    local x2 = z * sinY + x * cosY
    x = x2
    z = z2

    -- Z Axis
    local x3 = x * cosZ - y * sinZ
    local y3 = x * sinZ + y * cosZ
    x = x3
    y = y3

    return vector3(x, y, z)
end

-- Helper: Convert local vector to world vector
function Bounding:GetWorldPoint(localVec)
    local rotated = RotateVector(localVec, self.rotation)
    return vector3(
        self.coords.x + rotated.x,
        self.coords.y + rotated.y,
        self.coords.z + rotated.z
    )
end

-- Khởi tạo bounding box
function Bounding:Init(object)
    self.object = object
    self.coords = GetEntityCoords(object)
    self.model = GetEntityModel(object)
    self.rotation = GetEntityRotation(object, 2) -- rotation world (type 2)
    self.min, self.max = GetModelDimensions(self.model)

    self.faceCenters = {
        top = self:GetFaceCenter("top"),
        bottom = self:GetFaceCenter("bottom"),
        left = self:GetFaceCenter("left"),
        right = self:GetFaceCenter("right")
    }

    self.faceCorners = {
        top = self:GetFaceCorners("top"),
        bottom = self:GetFaceCorners("bottom"),
        left = self:GetFaceCorners("left"),
        right = self:GetFaceCorners("right")
    }
end

---@param axis "top"|"bottom"|"left"|"right"
---@return vector3
function Bounding:GetFaceCenter(axis)
    local x = (self.min.x + self.max.x) / 2
    local y = (self.min.y + self.max.y) / 2
    local z = (self.min.z + self.max.z) / 2

    if axis == "top" then
        z = self.max.z
    elseif axis == "bottom" then
        z = self.min.z
    elseif axis == "left" then
        x = self.min.x
    elseif axis == "right" then
        x = self.max.x
    end

    return self:GetWorldPoint(vector3(x, y, z))
end

---@param axis "top"|"bottom"|"left"|"right"
---@return table<string, vector3>
function Bounding:GetFaceCorners(axis)
    local corners = {}

    if axis == "top" then
        corners.frontLeft = self:GetWorldPoint(vector3(self.min.x, self.min.y, self.max.z))
        corners.frontRight = self:GetWorldPoint(vector3(self.max.x, self.min.y, self.max.z))
        corners.backLeft = self:GetWorldPoint(vector3(self.min.x, self.max.y, self.max.z))
        corners.backRight = self:GetWorldPoint(vector3(self.max.x, self.max.y, self.max.z))

    elseif axis == "bottom" then
        corners.frontLeft = self:GetWorldPoint(vector3(self.min.x, self.min.y, self.min.z))
        corners.frontRight = self:GetWorldPoint(vector3(self.max.x, self.min.y, self.min.z))
        corners.backLeft = self:GetWorldPoint(vector3(self.min.x, self.max.y, self.min.z))
        corners.backRight = self:GetWorldPoint(vector3(self.max.x, self.max.y, self.min.z))

    elseif axis == "left" then
        corners.topFront = self:GetWorldPoint(vector3(self.min.x, self.min.y, self.max.z))
        corners.topBack = self:GetWorldPoint(vector3(self.min.x, self.max.y, self.max.z))
        corners.bottomFront = self:GetWorldPoint(vector3(self.min.x, self.min.y, self.min.z))
        corners.bottomBack = self:GetWorldPoint(vector3(self.min.x, self.max.y, self.min.z))

    elseif axis == "right" then
        corners.topFront = self:GetWorldPoint(vector3(self.max.x, self.min.y, self.max.z))
        corners.topBack = self:GetWorldPoint(vector3(self.max.x, self.max.y, self.max.z))
        corners.bottomFront = self:GetWorldPoint(vector3(self.max.x, self.min.y, self.min.z))
        corners.bottomBack = self:GetWorldPoint(vector3(self.max.x, self.max.y, self.min.z))
    end

    return corners
end

---@param axis "top"|"bottom"|"left"|"right"
---@param color table {r:0-255, g:0-255, b:0-255, a?:0-255}
function Bounding:DebugDrawFace(axis, color)
    color = color or {r = 255, g = 0, b = 0, a = 255}
    local c = self:GetFaceCorners(axis)

    if axis == "top" or axis == "bottom" then
        DrawLine(c.frontLeft.x, c.frontLeft.y, c.frontLeft.z, c.frontRight.x, c.frontRight.y, c.frontRight.z, color.r, color.g, color.b, color.a)
        DrawLine(c.frontRight.x, c.frontRight.y, c.frontRight.z, c.backRight.x, c.backRight.y, c.backRight.z, color.r, color.g, color.b, color.a)
        DrawLine(c.backRight.x, c.backRight.y, c.backRight.z, c.backLeft.x, c.backLeft.y, c.backLeft.z, color.r, color.g, color.b, color.a)
        DrawLine(c.backLeft.x, c.backLeft.y, c.backLeft.z, c.frontLeft.x, c.frontLeft.y, c.frontLeft.z, color.r, color.g, color.b, color.a)
    elseif axis == "left" or axis == "right" then
        DrawLine(c.topFront.x, c.topFront.y, c.topFront.z, c.topBack.x, c.topBack.y, c.topBack.z, color.r, color.g, color.b, color.a)
        DrawLine(c.topBack.x, c.topBack.y, c.topBack.z, c.bottomBack.x, c.bottomBack.y, c.bottomBack.z, color.r, color.g, color.b, color.a)
        DrawLine(c.bottomBack.x, c.bottomBack.y, c.bottomBack.z, c.bottomFront.x, c.bottomFront.y, c.bottomFront.z, color.r, color.g, color.b, color.a)
        DrawLine(c.bottomFront.x, c.bottomFront.y, c.bottomFront.z, c.topFront.x, c.topFront.y, c.topFront.z, color.r, color.g, color.b, color.a)
    end
end

-- Vẽ full Bounding Box (12 cạnh)
---@param color table {r:0-255, g:0-255, b:0-255, a?:0-255}
function Bounding:DebugDrawBoundingBox(color)
    color = color or {r = 255, g = 255, b = 255, a = 255}

    -- 8 đỉnh
    local v = {
        self:GetWorldPoint(vector3(self.min.x, self.min.y, self.min.z)), -- 1
        self:GetWorldPoint(vector3(self.max.x, self.min.y, self.min.z)), -- 2
        self:GetWorldPoint(vector3(self.min.x, self.max.y, self.min.z)), -- 3
        self:GetWorldPoint(vector3(self.max.x, self.max.y, self.min.z)), -- 4
        self:GetWorldPoint(vector3(self.min.x, self.min.y, self.max.z)), -- 5
        self:GetWorldPoint(vector3(self.max.x, self.min.y, self.max.z)), -- 6
        self:GetWorldPoint(vector3(self.min.x, self.max.y, self.max.z)), -- 7
        self:GetWorldPoint(vector3(self.max.x, self.max.y, self.max.z))  -- 8
    }

    -- 12 cạnh
    local edges = {
        {1,2}, {2,4}, {4,3}, {3,1}, -- bottom face
        {5,6}, {6,8}, {8,7}, {7,5}, -- top face
        {1,5}, {2,6}, {3,7}, {4,8}  -- vertical edges
    }

    for _, e in ipairs(edges) do
        local p1 = v[e[1]]
        local p2 = v[e[2]]
        DrawLine(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, color.r, color.g, color.b, color.a)
    end
end

function Bounding:GetSize()
  return vector3(
      math.abs(self.max.x - self.min.x),
      math.abs(self.max.y - self.min.y),
      math.abs(self.max.z - self.min.z)
  )
end