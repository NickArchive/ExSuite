-- yeah youll need an exploit capable of supporting luau syntax to execute this
local Debug = loadstring(game:HttpGet("https://github.com/LegitH3x0R/Roblox/raw/main/src/Lib/Debugger.lua"))()

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera

local function GetClosestHead(From) -- Get the closest head to the player's mouse (With wallcheck)
    local Closest, ClosestDist = nil, math.huge
    for _, v in pairs(Players:GetPlayers()) do
        if v == Player or not v.Character then continue; end

        local Head = v.Character:FindFirstChild("Head")
        if not Head then continue; end

        local Pos, OnScreen = Camera:WorldToViewportPoint(Head.Position)
        if not OnScreen or Pos.Z < 0 then continue; end -- Is the head on screen and not behind us?

        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Blacklist
        Params.FilterDescendantsInstances = { Player.Character }

        local Raycast = workspace:Raycast(From, (Head.Position - From).Unit * 0x7FFFFFFF, Params)
        local Dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(Pos.X, Pos.Y)).Magnitude
        if Raycast and Raycast.Instance:IsDescendantOf(v.Character) and ClosestDist > Dist then -- Is anything in the way of the players head? If so, is it closer than the closest head?
            ClosestDist = Dist
            Closest = Head
        end
    end

    return Closest
end

Debug(game:GetService("ReplicatedStorage").ShootEvent, {
    Caller = "Client",
    Callback = function(Args)
        local Tool = Args[2]
        local Head = GetClosestHead(Tool.Muzzle.Position)

        if Head then
            for i, v in ipairs(Args[1]) do
                Args[1][i] = { -- Spoof the bullet data.
                    RayObject = Ray.new(Tool.Muzzle.Position, Head.Position),
                    Distance = (Head.Position - Tool.Muzzle.Position).Magnitude,
                    Cframe = Head.CFrame,
                    Hit = Head
                }
            end
        end
    end
})