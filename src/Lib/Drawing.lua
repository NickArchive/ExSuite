local Drawing = setmetatable({}, { __index = Drawing })

-- Header
local RunService = game:GetService("RunService")
local Camera = workspace.Camera
local WorldToViewportPoint = Camera.WorldToViewportPoint

local rad = math.rad
local Drawing_new = Drawing.new
local Color3_fromRGB = Color3.fromRGB
local CFrame_new = CFrame.new
local CFrame_Angles = CFrame.Angles
local Vector3_new = Vector3.new
local Vector2_new = Vector2.new

-- String Generation
local Ascii = {}
for i = 65, 90 do Ascii[#Ascii + 1] = string.char(i); end
for i = 97, 122 do Ascii[#Ascii + 1] = string.char(i); end

local function RandomString(Size)
    local t = table.create(Size)
    for i = 1, Size do
        t[i] = Ascii[math.random(1, 50)]
    end
    return table.concat(t)
end

-- Math
local function ToViewport(World)
    local Pos, OnScreen = WorldToViewportPoint(Camera, World)
    return Vector2_new(Pos.X, Pos.Y), Pos.Z, OnScreen -- Point, Depth, OnScreen
end

function Drawing.purge(Cache)
    for i = #Cache, 1, -1 do
        Cache[i]:Remove()
        Cache[i] = nil
    end
end

function Drawing.update(o, Props)
    for k, v in pairs(Props) do
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
        Ticket = string.format("RID-%s", RandomString(15))
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

        local Origin = CFrame_new(self.Position)
        self._Vertices[1] = Origin * Vector3_new(-self.Size.X, 0, self.Size.Y)
        self._Vertices[2] = Origin * Vector3_new(self.Size.X, 0, self.Size.Y)
        self._Vertices[3] = Origin * Vector3_new(self.Size.X, 0, -self.Size.Y)
        self._Vertices[4] = Origin * Vector3_new(-self.Size.X, 0, -self.Size.Y)

        local SkipCalculations;
        for i = 1, 4 do
            local Depth, OnScreen;
            self._Vertices[i], Depth, OnScreen = ToViewport(self._Vertices[i])

            if not OnScreen and Depth < 0 then
                SkipCalculations = true
                break;
            end
        end

        if SkipCalculations then
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

        local Origin = CFrame_new(self.Position) * CFrame_Angles(rad(self.Orientation.X), rad(self.Orientation.Y), rad(self.Orientation.Z))
        self._Vertices[1] = Origin * Vector3_new(-self.Size.X, self.Size.Y, self.Size.Z)
        self._Vertices[2] = Origin * Vector3_new(self.Size.X, self.Size.Y, self.Size.Z)
        self._Vertices[3] = Origin * Vector3_new(self.Size.X, self.Size.Y, -self.Size.Z)
        self._Vertices[4] = Origin * Vector3_new(-self.Size.X, self.Size.Y, -self.Size.Z)
        self._Vertices[5] = Origin * Vector3_new(-self.Size.X, -self.Size.Y, self.Size.Z)
        self._Vertices[6] = Origin * Vector3_new(self.Size.X, -self.Size.Y, self.Size.Z)
        self._Vertices[7] = Origin * Vector3_new(self.Size.X, -self.Size.Y, -self.Size.Z)
        self._Vertices[8] = Origin * Vector3_new(-self.Size.X, -self.Size.Y, -self.Size.Z)

        local SkipCalculations;
        for i = 1, 8 do
            local Depth, OnScreen;
            self._Vertices[i], Depth, OnScreen = ToViewport(self._Vertices[i])

            if not OnScreen and Depth < 0 then
                SkipCalculations = true
                break;
            end
        end

        if SkipCalculations then
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
local Cyoob = Drawing.newCube()
Cyoob.Visible = true
Cyoob.Size = Vector3.new(5, 5, 5)
Cyoob.Position = Vector3.new(0, 10, 0)

local i = 0
RunService.RenderStepped:Connect(function()
    i += 1
    if i == 360 then i = 0; end
    Cyoob.Orientation = Vector3.new(i, 0, -i)
end)]]

return Drawing
