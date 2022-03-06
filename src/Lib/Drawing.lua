local Drawing = setmetatable({}, { __index = Drawing })

-- Header
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.Camera
local WorldToViewportPoint = Camera.WorldToViewportPoint

local rad = math.rad
local Drawing_new = Drawing.new
local Color3_fromRGB = Color3.fromRGB
local CFrame_new = CFrame.new
local CFrame_Angles = CFrame.Angles
local Vector3_new = Vector3.new
local Vector2_new = Vector2.new

-- Math
local function ToViewport(world)
    local pos, onScreen = WorldToViewportPoint(Camera, world)
    return Vector2_new(pos.X, pos.Y), pos.Z, onScreen -- point, depth, onScreen
end

function Drawing.purge(cache)
    for i = #cache, 1, -1 do
        cache[i]:Remove()
        cache[i] = nil
    end
end

function Drawing.update(o, props)
    for k, v in pairs(props) do
        o[k] = v
    end
end

Drawing.base = {
    Visible = false,
    ZIndex = 0,
    Transparency = 1,
    Color = Color3_fromRGB(0, 0, 0)
}

function Drawing.getBase()
    return setmetatable({
        Ticket = string.format("drawObject-%s", HttpService:GenerateGUID(false))
    }, { __index = Drawing.base })
end

function Drawing.newPlane()
    local self = Drawing.getBase() do
        self.Thickness = 1
        self.Filled = true
        self.Position = Vector3_new()
        self.Size = Vector2_new()
        self.Orientation = Vector3_new()

        self._Quad = Drawing_new("Quad")
        self._Vertices = table.create(4)
    end

    function self:Remove()
        RunService:UnbindFromRenderStep(self.Ticket)
        self._Quad:Remove()
    end

    RunService:BindToRenderStep(self.Ticket, 1, function()
        if not self.Visible then
            self._Quad.Visible = false
            return;
        end

        self._Quad.ZIndex = self.ZIndex
        self._Quad.Transparency = self.Transparency
        self._Quad.Color = self.Color
        self._Quad.Thickness = self.Thickness
        self._Quad.Filled = self.Filled

        local origin = CFrame_new(self.Position)
        self._Vertices[1] = origin * Vector3_new(-self.Size.X, 0, self.Size.Y)
        self._Vertices[2] = origin * Vector3_new(self.Size.X, 0, self.Size.Y)
        self._Vertices[3] = origin * Vector3_new(self.Size.X, 0, -self.Size.Y)
        self._Vertices[4] = origin * Vector3_new(-self.Size.X, 0, -self.Size.Y)

        local skip;
        for i = 1, 4 do
            local depth, onScreen;
            self._Vertices[i], depth, onScreen = ToViewport(self._Vertices[i])

            if not onScreen and depth < 0 then
                skip = true
                break;
            end
        end

        if skip then
            self._Quad.Visible = false
            return;
        end

        self._Quad.Visible = true
        self._Quad.PointA = self._Vertices[1]
        self._Quad.PointB = self._Vertices[2]
        self._Quad.PointC = self._Vertices[3]
        self._Quad.PointD = self._Vertices[4]
    end)

    return self
end

function Drawing.newCube()
    local self = Drawing.getBase() do
        self.Thickness = 1
        self.Filled = true
        self.Position = Vector3_new()
        self.Size = Vector3_new()
        self.Orientation = Vector3_new()

        self._Quad1 = Drawing_new("Quad") -- Top
        self._Quad2 = Drawing_new("Quad") -- Bottom
        self._Quad3 = Drawing_new("Quad") -- Side A
        self._Quad4 = Drawing_new("Quad") -- Side B
        self._Quad5 = Drawing_new("Quad") -- Side C
        self._Quad6 = Drawing_new("Quad") -- Side D
        self._Vertices = table.create(4)
    end

    function self:Remove()
        RunService:UnbindFromRenderStep(self.Ticket)
        self._Quad1:Remove()
        self._Quad2:Remove()
        self._Quad3:Remove()
        self._Quad4:Remove()
        self._Quad5:Remove()
        self._Quad6:Remove()
    end

    RunService:BindToRenderStep(self.Ticket, 1, function()
        if not self.Visible then
            for i = 1, 6 do
                self["_Quad"..i].Visible = false
            end
            return;
        end

        for i = 1, 6 do
            local q = self["_Quad"..i]
            q.ZIndex = self.ZIndex
            q.Transparency = self.Transparency
            q.Color = self.Color
            q.Thickness = self.Thickness
            q.Filled = self.Filled
        end

        local origin = CFrame_new(self.Position) * CFrame_Angles(rad(self.Orientation.X), rad(self.Orientation.Y), rad(self.Orientation.Z))
        self._Vertices[1] = origin * Vector3_new(-self.Size.X, self.Size.Y, self.Size.Z)
        self._Vertices[2] = origin * Vector3_new(self.Size.X, self.Size.Y, self.Size.Z)
        self._Vertices[3] = origin * Vector3_new(self.Size.X, self.Size.Y, -self.Size.Z)
        self._Vertices[4] = origin * Vector3_new(-self.Size.X, self.Size.Y, -self.Size.Z)
        self._Vertices[5] = origin * Vector3_new(-self.Size.X, -self.Size.Y, self.Size.Z)
        self._Vertices[6] = origin * Vector3_new(self.Size.X, -self.Size.Y, self.Size.Z)
        self._Vertices[7] = origin * Vector3_new(self.Size.X, -self.Size.Y, -self.Size.Z)
        self._Vertices[8] = origin * Vector3_new(-self.Size.X, -self.Size.Y, -self.Size.Z)

        local skip;
        for i = 1, 8 do
            local depth, onScreen;
            self._Vertices[i], depth, onScreen = ToViewport(self._Vertices[i])

            if not onScreen and depth < 0 then
                skip = true
                break;
            end
        end

        if skip then
            for i = 1, 6 do
                self["_Quad"..i].Visible = false
            end
            return;
        end

        for i = 1, 6 do
            self["_Quad"..i].Visible = true
        end

        -- Reference: https://media.discordapp.net/attachments/929570959688613918/934967163909971988/unknown.png
        self._Quad1.PointA = self._Vertices[1]
        self._Quad1.PointB = self._Vertices[2]
        self._Quad1.PointC = self._Vertices[3]
        self._Quad1.PointD = self._Vertices[4]

        self._Quad2.PointA = self._Vertices[5]
        self._Quad2.PointB = self._Vertices[6]
        self._Quad2.PointC = self._Vertices[7]
        self._Quad2.PointD = self._Vertices[8]

        self._Quad3.PointA = self._Vertices[5]
        self._Quad3.PointB = self._Vertices[6]
        self._Quad3.PointC = self._Vertices[2]
        self._Quad3.PointD = self._Vertices[1]

        self._Quad4.PointA = self._Vertices[6]
        self._Quad4.PointB = self._Vertices[7]
        self._Quad4.PointC = self._Vertices[3]
        self._Quad4.PointD = self._Vertices[2]

        self._Quad5.PointA = self._Vertices[7]
        self._Quad5.PointB = self._Vertices[8]
        self._Quad5.PointC = self._Vertices[4]
        self._Quad5.PointD = self._Vertices[3]

        self._Quad6.PointA = self._Vertices[5]
        self._Quad6.PointB = self._Vertices[1]
        self._Quad6.PointC = self._Vertices[4]
        self._Quad6.PointD = self._Vertices[8]
    end)

    return self
end

Drawing.new = newcclosure(function(ClassName)
    if ClassName == "Plane" then
        return Drawing.newPlane()
    elseif ClassName == "Cube" then
        return Drawing.newCube()
    end
    return Drawing_new(ClassName)
end)

--[[
local cube = Drawing.newCube()
cube.Visible = true
cube.Size = Vector3.new(5, 5, 5)
cube.Position = Vector3.new(0, 10, 0)

local i = 0
game:GetService("RunService").RenderStepped:Connect(function()
    i += 1
    if i == 360 then i = 0; end
    cube.Orientation = Vector3.new(i, 0, -i)
end)]]

return Drawing
