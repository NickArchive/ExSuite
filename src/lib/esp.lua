assert(getgenv and Drawing, "Your exploit tastes worse than your mom's cooking.")

-- Definitions
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local Vector2_new = Vector2.new
local Vector3_new = Vector3.new

-- Drawing Math
local function redraw(o, s)
    for k, v in pairs(s) do
        o[k] = v
    end
    return o
end

local function draw(className, s)
    return redraw(Drawing.new(className), s)
end

local esp = {}
local registry, doNotUpdate = {}, {}
esp.Settings = {
    UseBox2d = true,
    Box2d = {
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 2,
    },

    UseTracers = true,
    Tracers = {
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 2,
        From = Vector2_new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y),
    },

    UseSkeleton = true,
    Skeleton = {
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 2,
    },

    UseName = true,
    Name = {
        Color = Color3.fromRGB(255, 255, 255),
        Outline = true,
        Center = true,
        Font = Drawing.Fonts.Monospace
    },
}

function esp.isolate(ply)
    doNotUpdate[ply] = true
    return registry[ply]
end

function esp.link(ply)
    doNotUpdate[ply] = nil
end

function esp.register(ply)
    registry[ply] = esp.init()
end

function esp.dismember(ply)
    esp.cleanup(registry[ply])
    registry[ply] = nil
end

function esp.updateSettings()
    for ply, data in pairs(registry) do
        if doNotUpdate[ply] then continue; end
        redraw(data.Box2d, esp.Settings.Box2d)
        redraw(data.Tracer, esp.Settings.Tracers)
        redraw(data.Name, esp.Settings.Name)
        for _, v in pairs(data.Skeleton) do
            redraw(v, esp.Settings.Skeleton)
        end
    end
end

function esp.init()
    return {
        Box2d = draw("Square", esp.Settings.Box2d),
        Tracer = draw("Line", esp.Settings.Tracers),
        Name = draw("Text", esp.Settings.Name),
        Skeleton = {
            LeftArm = draw("Line", esp.Settings.Skeleton),
            LeftUpperArm = draw("Line", esp.Settings.Skeleton),
            RightArm = draw("Line", esp.Settings.Skeleton),
            RightUpperArm = draw("Line", esp.Settings.Skeleton),
            LeftLeg = draw("Line", esp.Settings.Skeleton),
            LeftUpperLeg = draw("Line", esp.Settings.Skeleton),
            RightLeg = draw("Line", esp.Settings.Skeleton),
            RightUpperLeg = draw("Line", esp.Settings.Skeleton),
            Torso = draw("Line", esp.Settings.Skeleton),
        }
    }
end

function esp.hide(data)
    data.Box2d.Visible = false
    data.Tracer.Visible = false
    data.Name.Visible = false
    for _, v in pairs(data.Skeleton) do
        v.Visible = false
    end
end

function esp.cleanup(data)
    if data._CLEANED then return; end
    data._CLEANED = true
    data.Box2d:Remove()
    data.Tracer:Remove()
    data.Name:Remove()
    for _, v in pairs(data.Skeleton) do
        v:Remove()
    end
end

function esp.stop()
    esp.frameCn:Disconnect()
    for ply in pairs(registry) do
        esp.dismember(ply)
    end
end

function esp.onFrame()
    for ply, data in pairs(registry) do
        local char = ply.Character
        if not char then esp.hide(data); continue; end

        local root = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        if not root then esp.hide(data); continue; end

        local hum = char:FindFirstChildOfClass("Humanoid")
        local head = char:FindFirstChild("Head")
        if not head then esp.hide(data); continue; end

        local rootPoint, rootOnScreen = Camera:WorldToViewportPoint(root.Position)
        local topPoint, topOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3_new(0, 1, 0))
        local bottomPoint, bottomOnScreen = Camera:WorldToViewportPoint(root.Position - Vector3_new(0, 3, 0))

        if rootOnScreen and rootPoint.Z > 0 then
            local box2dSize = Vector2_new((Camera.ViewportSize.Y / rootPoint.Z) * 2.5, bottomPoint.Y - topPoint.Y)
            if esp.Settings.UseBox2d then
                redraw(data.Box2d, {
                    Visible = true,
                    Size = box2dSize,
                    Position = Vector2_new(rootPoint.X - (box2dSize.X / 2), rootPoint.Y - (box2dSize.Y / 2))
                })
            else
                data.Box2d.Visible = false
            end

            if esp.Settings.UseName then
                local text;
                if ply.DisplayName == ply.Name then
                    text = ply.DisplayName
                else
                    text = ("%s (%s)"):format(ply.DisplayName, ply.Name)
                end

                redraw(data.Name, {
                    Visible = true,
                    Text = text,
                    Size = (Camera.ViewportSize.Y / rootPoint.Z) / 2,
                    Position = Vector2_new(bottomPoint.X, rootPoint.Y - (box2dSize.Y / 2))
                })
            else
                data.Name.Visible = false
            end

            if esp.Settings.UseTracers then
                redraw(data.Tracer, {
                    Visible = true,
                    To = Vector2_new(bottomPoint.X, rootPoint.Y + (box2dSize.Y / 2))
                })
            else
                data.Tracer.Visible = false
            end

            if esp.Settings.UseSkeleton and hum then
                local neckPoint, splitPoint = Camera:WorldToViewportPoint(head.Position - Vector3_new(0, 1, 0)), Camera:WorldToViewportPoint(root.Position - Vector3_new(0, 1, 0))
                if hum.RigType == Enum.HumanoidRigType.R15 then
                    local leftHand, leftUpperArm = char:FindFirstChild("LeftHand"), char:FindFirstChild("LeftUpperArm")
                    if leftHand and leftUpperArm then
                        local leftHandPoint = Camera:WorldToViewportPoint(leftHand.Position)
                        local leftUpperArmPoint = Camera:WorldToViewportPoint(leftUpperArm.Position)

                        redraw(data.Skeleton.LeftArm, {
                            Visible = true,
                            From = Vector2_new(leftHandPoint.X, leftHandPoint.Y),
                            To = Vector2_new(leftUpperArmPoint.X, leftUpperArmPoint.Y)
                        })

                        redraw(data.Skeleton.LeftUpperArm, {
                            Visible = true,
                            From = Vector2_new(leftUpperArmPoint.X, leftUpperArmPoint.Y),
                            To = Vector2_new(neckPoint.X, neckPoint.Y)
                        })
                    else
                        data.Skeleton.LeftArm.Visible = false
                        data.Skeleton.LeftUpperArm.Visible = false
                    end

                    local rightHand, rightUpperArm = char:FindFirstChild("RightHand"), char:FindFirstChild("RightUpperArm")
                    if rightHand and rightUpperArm then
                        local rightHandPoint = Camera:WorldToViewportPoint(rightHand.Position)
                        local rightUpperArmPoint = Camera:WorldToViewportPoint(rightUpperArm.Position)

                        redraw(data.Skeleton.RightArm, {
                            Visible = true,
                            From = Vector2_new(rightHandPoint.X, rightHandPoint.Y),
                            To = Vector2_new(rightUpperArmPoint.X, rightUpperArmPoint.Y)
                        })

                        redraw(data.Skeleton.RightUpperArm, {
                            Visible = true,
                            From = Vector2_new(rightUpperArmPoint.X, rightUpperArmPoint.Y),
                            To = Vector2_new(neckPoint.X, neckPoint.Y)
                        })
                    else
                        data.Skeleton.RightArm.Visible = false
                        data.Skeleton.RightUpperArm.Visible = false
                    end

                    local leftFoot, leftUpperLeg = char:FindFirstChild("LeftFoot"), char:FindFirstChild("LeftUpperLeg")
                    if leftFoot and leftUpperLeg then
                        local leftFootPoint = Camera:WorldToViewportPoint(leftFoot.Position)
                        local leftUpperLegPoint = Camera:WorldToViewportPoint(leftUpperLeg.Position)

                        redraw(data.Skeleton.LeftLeg, {
                            Visible = true,
                            From = Vector2_new(leftFootPoint.X, leftFootPoint.Y),
                            To = Vector2_new(leftUpperLegPoint.X, leftUpperLegPoint.Y)
                        })

                        redraw(data.Skeleton.LeftUpperLeg, {
                            Visible = true,
                            From = Vector2_new(leftUpperLegPoint.X, leftUpperLegPoint.Y),
                            To = Vector2_new(splitPoint.X, splitPoint.Y)
                        })
                    else
                        data.Skeleton.LeftLeg.Visible = false
                        data.Skeleton.LeftUpperLeg.Visible = false
                    end

                    local rightFoot, rightUpperLeg = char:FindFirstChild("RightFoot"), char:FindFirstChild("RightUpperLeg")
                    if rightFoot and rightUpperLeg then
                        local rightFootPoint = Camera:WorldToViewportPoint(rightFoot.Position)
                        local rightUpperLegPoint = Camera:WorldToViewportPoint(rightUpperLeg.Position)

                        redraw(data.Skeleton.RightLeg, {
                            Visible = true,
                            From = Vector2_new(rightFootPoint.X, rightFootPoint.Y),
                            To = Vector2_new(rightUpperLegPoint.X, rightUpperLegPoint.Y)
                        })

                        redraw(data.Skeleton.RightUpperLeg, {
                            Visible = true,
                            From = Vector2_new(rightUpperLegPoint.X, rightUpperLegPoint.Y),
                            To = Vector2_new(splitPoint.X, splitPoint.Y)
                        })
                    else
                        data.Skeleton.RightLeg.Visible = false
                        data.Skeleton.RightUpperLeg.Visible = false
                    end
                else
                    local leftArm = char:FindFirstChild("Left Arm")
                    if leftArm then
                        local leftHandPoint = Camera:WorldToViewportPoint((leftArm.CFrame - leftArm.CFrame.UpVector / 2).Position)
                        local leftUpperArmPoint = Camera:WorldToViewportPoint((leftArm.CFrame + leftArm.CFrame.UpVector / 2).Position)

                        redraw(data.Skeleton.LeftArm, {
                            Visible = true,
                            From = Vector2_new(leftHandPoint.X, leftHandPoint.Y),
                            To = Vector2_new(leftUpperArmPoint.X, leftUpperArmPoint.Y)
                        })

                        redraw(data.Skeleton.LeftUpperArm, {
                            Visible = true,
                            From = Vector2_new(leftUpperArmPoint.X, leftUpperArmPoint.Y),
                            To = Vector2_new(neckPoint.X, neckPoint.Y)
                        })
                    else
                        data.Skeleton.LeftArm.Visible = false
                        data.Skeleton.LeftUpperArm.Visible = false
                    end

                    local rightArm = char:FindFirstChild("Right Arm")
                    if rightArm then
                        local rightHandPoint = Camera:WorldToViewportPoint((rightArm.CFrame - rightArm.CFrame.UpVector / 2).Position)
                        local rightUpperArmPoint = Camera:WorldToViewportPoint((rightArm.CFrame + rightArm.CFrame.UpVector / 2).Position)

                        redraw(data.Skeleton.RightArm, {
                            Visible = true,
                            From = Vector2_new(rightHandPoint.X, rightHandPoint.Y),
                            To = Vector2_new(rightUpperArmPoint.X, rightUpperArmPoint.Y)
                        })

                        redraw(data.Skeleton.RightUpperArm, {
                            Visible = true,
                            From = Vector2_new(rightUpperArmPoint.X, rightUpperArmPoint.Y),
                            To = Vector2_new(neckPoint.X, neckPoint.Y)
                        })
                    else
                        data.Skeleton.RightArm.Visible = false
                        data.Skeleton.RightUpperArm.Visible = false
                    end

                    local leftLeg = char:FindFirstChild("Left Leg")
                    if leftLeg then
                        local leftFootPoint = Camera:WorldToViewportPoint((leftLeg.CFrame - leftLeg.CFrame.UpVector / 2).Position)
                        local leftUpperLegPoint = Camera:WorldToViewportPoint((leftLeg.CFrame + leftLeg.CFrame.UpVector / 2).Position)

                        redraw(data.Skeleton.LeftLeg, {
                            Visible = true,
                            From = Vector2_new(leftFootPoint.X, leftFootPoint.Y),
                            To = Vector2_new(leftUpperLegPoint.X, leftUpperLegPoint.Y)
                        })

                        redraw(data.Skeleton.LeftUpperLeg, {
                            Visible = true,
                            From = Vector2_new(leftUpperLegPoint.X, leftUpperLegPoint.Y),
                            To = Vector2_new(splitPoint.X, splitPoint.Y)
                        })
                    else
                        data.Skeleton.LeftLeg.Visible = false
                        data.Skeleton.LeftUpperLeg.Visible = false
                    end

                    local rightLeg = char:FindFirstChild("Right Leg")
                    if rightLeg then
                        local rightLegPoint = Camera:WorldToViewportPoint((rightLeg.CFrame - rightLeg.CFrame.UpVector / 2).Position)
                        local rightUpperLegPoint = Camera:WorldToViewportPoint((rightLeg.CFrame + rightLeg.CFrame.UpVector / 2).Position)

                        redraw(data.Skeleton.RightLeg, {
                            Visible = true,
                            From = Vector2_new(rightLegPoint.X, rightLegPoint.Y),
                            To = Vector2_new(rightUpperLegPoint.X, rightUpperLegPoint.Y)
                        })

                        redraw(data.Skeleton.RightUpperLeg, {
                            Visible = true,
                            From = Vector2_new(rightUpperLegPoint.X, rightUpperLegPoint.Y),
                            To = Vector2_new(splitPoint.X, splitPoint.Y)
                        })
                    else
                        data.Skeleton.RightLeg.Visible = false
                        data.Skeleton.RightUpperLeg.Visible = false
                    end
                end

                redraw(data.Skeleton.Torso, {
                    Visible = true,
                    From = Vector2_new(neckPoint.X, neckPoint.Y),
                    To = Vector2_new(splitPoint.X, splitPoint.Y)
                })
            else
                for _, v in pairs(data.Skeleton) do v.Visible = false; end
            end
        else
            esp.hide(data)
        end
    end
end

esp.frameCn = RunService.RenderStepped:Connect(esp.onFrame)
Players.PlayerRemoving:Connect(function(ply)
    local data = registry[ply]
    if data then
        esp.dismember(ply)
    end
end)

return esp