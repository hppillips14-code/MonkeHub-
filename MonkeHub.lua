-- Monke Hub | Stable Async Pathfinding + Move Speed + Auto-Teleport
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local LocalPlayer = Players.LocalPlayer

-- CONFIG
local FOLLOW_DISTANCE = 6
local GUI_KEY = Enum.KeyCode.K

-- STATE
local targetPlayer = nil
local following = false
local character, hrp, humanoid
local lastTargetPos

-- CHARACTER SETUP
local function setupCharacter(char)
    character = char
    hrp = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
end
if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

-- GUI
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MonkeHubGui"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.fromOffset(420,540)
MainFrame.Position = UDim2.fromScale(0.5,0.5)
MainFrame.AnchorPoint = Vector2.new(0.5,0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,14)

-- HEADER
local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1,0,0,55)
Header.Position = UDim2.new(0,0,0,0)
Header.BackgroundColor3 = Color3.fromRGB(45,45,45)
Header.Text = "Monke Hub"
Header.TextColor3 = Color3.fromRGB(255,255,255)
Header.Font = Enum.Font.GothamBold
Header.TextSize = 28
Header.Parent = MainFrame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0,14)

-- PLAYER INPUT
local NameBox = Instance.new("TextBox")
NameBox.Size = UDim2.new(0.9,0,0,38)
NameBox.Position = UDim2.new(0.05,0,0.12,0)
NameBox.PlaceholderText = "Enter player name"
NameBox.TextColor3 = Color3.fromRGB(255,255,255)
NameBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
NameBox.Font = Enum.Font.Gotham
NameBox.TextSize = 16
NameBox.Parent = MainFrame
Instance.new("UICorner", NameBox).CornerRadius = UDim.new(0,8)

-- BUTTONS
local function makeButton(text,posY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9,0,0,42)
    btn.Position = UDim2.new(0.05,0,posY,0)
    btn.BackgroundColor3 = Color3.fromRGB(55,55,55)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 18
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
    return btn
end

local FollowButton = makeButton("FOLLOW",0.26)
local StopButton = makeButton("STOP",0.37)
local TeleportButton = makeButton("TELEPORT TO PLAYER",0.48)

-- SLIDERS
local function createSlider(parent,posY,labelText,defaultValue,color)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.9,0,0,35)
    frame.Position = UDim2.new(0.05,0,posY,0)
    frame.BackgroundColor3 = Color3.fromRGB(55,55,55)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.Text = labelText .. math.floor(defaultValue*100) .. "%"
    label.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(defaultValue,0,1,0)
    bar.BackgroundColor3 = color
    bar.Parent = frame
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,8)

    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0,12,1,0)
    handle.AnchorPoint = Vector2.new(1,0)
    handle.Position = UDim2.new(1,0,0,0)
    handle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    handle.Parent = bar
    Instance.new("UICorner", handle).CornerRadius = UDim.new(0,6)

    local dragging = false
    local value = defaultValue

    local function updateValue(mouseX)
        local frameX = frame.AbsolutePosition.X
        local frameW = frame.AbsoluteSize.X
        value = math.clamp((mouseX-frameX)/frameW,0,1)
        bar.Size = UDim2.new(value,0,1,0)
        handle.Position = UDim2.new(1,0,0,0)
        label.Text = labelText .. math.floor(value*100) .. "%"
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    frame.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            updateValue(input.Position.X)
            dragging=true
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
            updateValue(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)

    return function() return value end
end

local getMoveSpeed = createSlider(MainFrame,0.75,"Move Speed: ",0.5,Color3.fromRGB(70,180,200))

-- FIND PLAYER
local function getPlayerByName(name)
    for _,p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1,#name) == name:lower() then return p end
    end
    return nil
end

-- FOLLOW LOGIC WITH AUTO-TELEPORT
local function followPlayer()
    spawn(function()
        local path = nil
        local currentWaypoint = 1

        while following and targetPlayer and targetPlayer.Character and hrp and humanoid do
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then break end

            local dist = (hrp.Position - targetHRP.Position).Magnitude
            humanoid.WalkSpeed = 16 + 84*getMoveSpeed()

            if dist > FOLLOW_DISTANCE then
                local shouldRecompute = not path or (lastTargetPos and (targetHRP.Position - lastTargetPos).Magnitude > 5)
                
                if shouldRecompute then
                    local newPath = PathfindingService:CreatePath({
                        AgentRadius = 2,
                        AgentHeight = 5,
                        AgentCanJump = true,
                        AgentJumpHeight = 10,
                        AgentMaxSlope = 45,
                    })
                    newPath:ComputeAsync(hrp.Position, targetHRP.Position)

                    if newPath.Status == Enum.PathStatus.Success then
                        path = newPath:GetWaypoints()
                        currentWaypoint = 1
                        lastTargetPos = targetHRP.Position
                    else
                        hrp.CFrame = targetHRP.CFrame + Vector3.new(0,3,0)
                        path = nil
                        wait(0.5)
                    end
                end

                if path then
                    while currentWaypoint <= #path and following do
                        local waypoint = path[currentWaypoint]
                        humanoid:MoveTo(waypoint.Position)
                        humanoid.MoveToFinished:Wait()
                        currentWaypoint = currentWaypoint + 1
                    end
                end
            else
                wait(0.2)
            end
            wait(0.05)
        end
    end)
end

-- BUTTON LOGIC
FollowButton.MouseButton1Click:Connect(function()
    targetPlayer = getPlayerByName(NameBox.Text)
    if targetPlayer then
        following = true
        followPlayer()
    end
end)

StopButton.MouseButton1Click:Connect(function() following=false end)

TeleportButton.MouseButton1Click:Connect(function()
    if targetPlayer and targetPlayer.Character and hrp then
        local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP then
            hrp.CFrame = targetHRP.CFrame + Vector3.new(0,3,0)
        end
    end
end)

-- GUI TOGGLE
UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode==GUI_KEY then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)
