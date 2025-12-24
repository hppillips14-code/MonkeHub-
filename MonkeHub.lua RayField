--// SERVICES
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

--// RAYFIELD
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--// WINDOW
local Window = Rayfield:CreateWindow({
	Name = "🐵 Monke Hub",
	LoadingTitle = "Monke Hub",
	LoadingSubtitle = "Advanced Follow System",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "MonkeHub",
		FileName = "Settings"
	}
})

--// THEME TAB
local ThemeTab = Window:CreateTab("🎨 Theme")
ThemeTab:CreateDropdown({
	Name = "Select Theme",
	Options = {"Default","Ocean","Dark","Light","Serenity","Amber Glow"},
	CurrentOption = "Default",
	Callback = function(theme)
		Rayfield:SetTheme(theme)
	end
})

--// FOLLOW TAB
local FollowTab = Window:CreateTab("🐾 Follow")

--// STATE
local targetName = ""
local targetPlayer
local following = false
local speedMult = 0.5

--// CONFIG
local FOLLOW_DISTANCE = 6
local PREDICTION_TIME = 0.35
local BLEND_ALPHA = 0.3
local DIRECT_DISTANCE = 45
local PATH_COOLDOWN = 0.8

--// PATH ESP
local SHOW_PATH_ESP = true
local pathVisuals = {}

--// CHARACTER
local function getChar()
	local char = LocalPlayer.Character
	if not char then return end
	return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChild("Humanoid")
end

--// PLAYER FIND
local function findPlayer(name)
	for _,p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#name) == name:lower() then
			return p
		end
	end
end

--// VELOCITY PREDICTION
local function predictedPos(hrp)
	return hrp.Position + hrp.Velocity * PREDICTION_TIME
end

--// OBSTACLE CHECK
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist

local function canDirectMove(from, to, char)
	rayParams.FilterDescendantsInstances = {char}
	return not Workspace:Raycast(from, to - from, rayParams)
end

--// PATH ESP
local function clearPathESP()
	for _,v in ipairs(pathVisuals) do
		if v and v.Parent then
			v:Destroy()
		end
	end
	table.clear(pathVisuals)
end

local function drawPathESP(points)
	clearPathESP()
	if not SHOW_PATH_ESP then return end

	for i = 1, #points - 1 do
		local a = points[i].Position
		local b = points[i+1].Position

		local beam = Instance.new("Part")
		beam.Anchored = true
		beam.CanCollide = false
		beam.Material = Enum.Material.Neon
		beam.Color = Color3.fromRGB(0,170,255)
		beam.Size = Vector3.new(0.25,0.25,(a-b).Magnitude)
		beam.CFrame = CFrame.lookAt((a+b)/2, b)
		beam.Parent = Workspace

		table.insert(pathVisuals, beam)
	end
end

--// TELEPORT
local function teleportToTarget()
	local char, hrp = getChar()
	if not hrp or not targetPlayer then return end

	local tHRP = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if tHRP then
		hrp.CFrame = tHRP.CFrame * CFrame.new(0,0,-3)
	end
end

--// FOLLOW LOGIC
local lastPath = 0

local function startFollow()
	if following then return end
	following = true

	task.spawn(function()
		while following do
			local char, hrp, hum = getChar()
			if not char or not hrp or not hum then break end

			targetPlayer = findPlayer(targetName)
			if not targetPlayer or not targetPlayer.Character then break end

			local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not targetHRP then break end

			hum.WalkSpeed = 16 + 84 * speedMult
			local goal = predictedPos(targetHRP)
			local dist = (hrp.Position - goal).Magnitude

			-- DIRECT MOVE
			if dist <= DIRECT_DISTANCE and canDirectMove(hrp.Position, goal, char) then
				hum:MoveTo(goal)
				task.wait(0.12)
				continue
			end

			-- PATHFINDING
			if os.clock() - lastPath < PATH_COOLDOWN then
				task.wait(0.1)
				continue
			end
			lastPath = os.clock()

			local path = PathfindingService:CreatePath({
				AgentRadius = 2,
				AgentHeight = 5,
				AgentCanJump = true,
				WaypointSpacing = 4
			})

			path:ComputeAsync(hrp.Position, goal)

			if path.Status == Enum.PathStatus.Success then
				local waypoints = path:GetWaypoints()
				drawPathESP(waypoints)

				for _,wp in ipairs(waypoints) do
					if not following then break end

					local blended = wp.Position:Lerp(goal, BLEND_ALPHA)
					hum:MoveTo(blended)
					hum.MoveToFinished:Wait()

					if (hrp.Position - goal).Magnitude <= FOLLOW_DISTANCE then
						break
					end
				end
			else
				Rayfield:Notify({
					Title = "Monke Hub",
					Content = "Path blocked — teleport recommended",
					Duration = 2
				})
			end

			task.wait(0.05)
		end

		following = false
		clearPathESP()
	end)
end

--// UI CONTROLS
FollowTab:CreateInput({
	Name = "Target Player",
	PlaceholderText = "Username",
	Callback = function(text)
		targetName = text
	end
})

FollowTab:CreateSlider({
	Name = "Move Speed",
	Range = {0,100},
	CurrentValue = 50,
	Increment = 1,
	Callback = function(v)
		speedMult = v / 100
	end
})

FollowTab:CreateToggle({
	Name = "Show Path ESP",
	CurrentValue = true,
	Callback = function(v)
		SHOW_PATH_ESP = v
		if not v then clearPathESP() end
	end
})

FollowTab:CreateButton({
	Name = "▶ Start Follow",
	Callback = startFollow
})

FollowTab:CreateButton({
	Name = "⏹ Stop Follow",
	Callback = function()
		following = false
		clearPathESP()
	end
})

FollowTab:CreateButton({
	Name = "⚡ Teleport To Player",
	Callback = teleportToTarget
})

FollowTab:CreateButton({
	Name = "🛠 Load Infinite Yield",
	Callback = function()
		loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"
		))()
	end
})

Rayfield:Notify({
	Title = "Monke Hub Loaded",
	Content = "Rayfield Edition Ready 🐵",
	Duration = 4
})
