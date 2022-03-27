local Drawing = loadLibrary("drawing")
local AIService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")

local player = game:GetService("Players").LocalPlayer

local function newDelegate(f, ...)
    local params = {...}
    return function(...) return f(unpack(params), ...) end
end

local Pathfinder = {}
function Pathfinder.calc(a, b, s)
    local Path = AIService:CreatePath(s); Path:ComputeAsync(a, b)
    return (Path.Status == Enum.PathStatus.Success) and Path:GetWaypoints() or false
end

function Pathfinder.draw(points)
    local boxes = table.create(#points)
    for i = 1, #points do
        boxes[i] = Drawing.newCube()
        Drawing.update(boxes[i], {
            Visible = true,
            Transparency = 0.2,
            Color = Color3.fromRGB(121, 68, 150),
            Size = Vector3.new(0.5, 0.5, 0.5),
            Position = points[i].Position + Vector3.new(0, 2, 0)
        })
    end
    return newDelegate(Drawing.purge, boxes)
end

function Pathfinder.go(points, debug)
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return false; end

    local doPurge;
    if debug then doPurge = Pathfinder.draw(points); end

    local i = 0
    local fin, moveCn = false, nil
    local function Next()
        i = i + 1
        local point = points[i]
        if point.Action == Enum.PathWaypointAction.Jump then
            hum.Jump = true
        end
        hum:MoveTo(point.Position)
        if i == #points then moveCn:Disconnect(); fin = true; end
    end
    moveCn = hum.MoveToFinished:Connect(Next)

    Next()
    repeat task.wait(0.3) until fin
    if debug then doPurge(); end
end

function Pathfinder.goTween(points, velocity, debug)
    local root = player.Character.PrimaryPart
    if not root then return false; end

    local doPurge;
    if debug then doPurge = Pathfinder.draw(points); end

    for _, point in ipairs(points) do
        -- Good thing I took physics...
        local duration = (root.Position - point.Position).Magnitude / velocity -- v=d/t...t=d/v
        local info = TweenInfo.new(
            duration,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.Out
        )

        TweenService:Create(root, info, {
            CFrame = CFrame.new(point.Position + Vector3.new(0, 2, 0))
        }):Play()
        task.wait(duration)
    end

    if debug then doPurge(); end
end

return Pathfinder