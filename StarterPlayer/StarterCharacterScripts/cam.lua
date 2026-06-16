local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService_2 = game:GetService("UserInputService")

-- Clean up lighting effects
for _, object in pairs(game.Lighting:GetChildren()) do
	if object:IsA("ColorCorrectionEffect") then
		if object.Name ~= "The cool" and (object.Name ~= "Invisible" and (object.Name ~= "wa" and object.Name ~= "LOBCORRECTION")) then
			object:Destroy()
		end
	elseif object:IsA("BlurEffect") then
		object.Enabled = false
	end
	if string.match(object.Name, "NMI") then
		object:Destroy()
	end
end

-- Camera settings
local cameraSettings = {
	snap = 1.4835298641951802,
	offset = Vector3.new(2, 3, 10),
	clipCorrection = 0.2
}

cameraSettings.sensitivity = if UserInputService_2.TouchEnabled then 2 else 0.5 * UserSettings().GameSettings.MouseSensitivity
cameraSettings.controllerBaseSensitivity = 14 * UserSettings().GameSettings.MouseSensitivity
UserSettings().GameSettings.RotationType = Enum.RotationType.MovementRelative

-- Rotation variables
local rotationX = 0
local rotationY = 0
local controllerRotationX = 0
local controllerRotationY = 0

local LocalPlayer = game.Players.LocalPlayer
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local currentCamera = workspace.CurrentCamera
local humanoid = character:FindFirstChild("Humanoid")
character:FindFirstChild("RootPart")

-- Fetch settings from server
local settingsData = ReplicatedStorage.Remotes:WaitForChild("DataUpdate"):InvokeServer("FetchData", { "setting" })
repeat
	task.wait()
until settingsData

print(settingsData)

local fieldOfView = settingsData.FieldOfView or 70
local isWindowFocused = false

if LocalPlayer.PlayerGui:FindFirstChild("Round") then
	game.ReplicatedStorage.Remotes.testuidie:FireServer()
end

LocalPlayer.PlayerGui.Main.char.Value = ""

repeat
	task.wait()
until fieldOfView > 1

currentCamera.FieldOfView = fieldOfView or 70

if game:GetService("RunService"):IsClient() then
	print("les go")
	print("activate")
	require(game.Players.LocalPlayer.PlayerScripts.PlayerModule):GetControls():Enable(true)
end

local function Lerp(startValue, endValue, alpha)
	return startValue + (endValue - startValue) * alpha
end

local function SetCharacterLocalTransparency(transparency)
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			local currentTransparency = part.LocalTransparencyModifier
			part.LocalTransparencyModifier = currentTransparency + (transparency - currentTransparency) * 0.3
		end
	end
end

-- Set camera to scriptable
repeat
	currentCamera.CameraType = Enum.CameraType.Scriptable
until currentCamera.CameraType == Enum.CameraType.Scriptable

currentCamera.CameraType = Enum.CameraType.Scriptable

UserInputService.WindowFocused:Connect(function()
	if UserInputService.TouchEnabled or not (UserInputService.MouseEnabled and isWindowFocused) then
		return
	end
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Thumbstick2 then
		local magnitude = input.Position.magnitude
		controllerRotationX = -input.Position.X * cameraSettings.controllerBaseSensitivity * magnitude
		controllerRotationY = input.Position.Y * cameraSettings.controllerBaseSensitivity * magnitude
	elseif input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch and not gameProcessed then
		rotationX = rotationX + -input.Delta.X * cameraSettings.sensitivity / 100
		rotationY = rotationY + -input.Delta.Y * cameraSettings.sensitivity / 100
		rotationY = math.clamp(rotationY, -cameraSettings.snap, cameraSettings.snap)
	end
	isWindowFocused = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
end)

local isLeftPressed = false
local isRightPressed = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	
	if input.UserInputType == Enum.UserInputType.MouseButton2 and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
		if game.Players.LocalPlayer:HasTag("OnRESULT") then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		end
	else
		if input.KeyCode == Enum.KeyCode.Left then
			isLeftPressed = true
			task.spawn(function()
				while isLeftPressed do
					rotationX = rotationX + 0.05
					rotationY = math.clamp(rotationY, -cameraSettings.snap, cameraSettings.snap)
					task.wait()
				end
			end)
			return
		end
		
		if input.KeyCode ~= Enum.KeyCode.Right then
			return
		end
		
		isRightPressed = true
		task.spawn(function()
			while isRightPressed do
				rotationX = rotationX + -0.05
				rotationY = math.clamp(rotationY, -cameraSettings.snap, cameraSettings.snap)
				task.wait()
			end
		end)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	
	if input.UserInputType == Enum.UserInputType.MouseButton2 and isWindowFocused == false then
		warn("burp")
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		return
	end
	
	if input.KeyCode == Enum.KeyCode.Left then
		isLeftPressed = false
		return
	end
	
	if input.KeyCode ~= Enum.KeyCode.Right then
		return
	end
	
	isRightPressed = false
end)

RunService.RenderStepped:Connect(function()
	if not (humanoidRootPart and humanoid) then
		return
	end
	
	-- Update controller sensitivity if changed
	if 14 * UserSettings().GameSettings.MouseSensitivity ~= cameraSettings.controllerBaseSensitivity then
		cameraSettings.controllerBaseSensitivity = 14 * UserSettings().GameSettings.MouseSensitivity
	end
	
	-- Apply rotations
	rotationX = rotationX + controllerRotationX * cameraSettings.sensitivity / 100
	rotationY = rotationY + controllerRotationY * cameraSettings.sensitivity / 100
	rotationY = math.clamp(rotationY, -cameraSettings.snap, cameraSettings.snap)
	
	-- Check if controller thumbstick is active
	local isControllerActive = false
	for _, state in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
		if state.KeyCode == Enum.KeyCode.Thumbstick2 and state.UserInputState == Enum.UserInputState.Change then
			isControllerActive = true
		end
	end
	
	if not isControllerActive then
		controllerRotationX = 0
		controllerRotationY = 0
	end
	
	if script:GetAttribute("stop") or LocalPlayer:HasTag("OnRESULT") then
		return
	end
	
	currentCamera.CameraType = Enum.CameraType.Scriptable
	
	-- Update camera offset
	humanoid.CameraOffset = humanoid.CameraOffset:Lerp(
		(humanoidRootPart.CFrame + Vector3.new(0, 1.5, 0)):PointToObjectSpace(character.Head.CFrame.p),
		0.5
	)
	
	SetCharacterLocalTransparency(0)
	
	-- Update camera position and rotation
	currentCamera.CFrame = currentCamera.CFrame:Lerp(
		CFrame.new(humanoidRootPart.Position) * 
		CFrame.Angles(0, rotationX, 0) * 
		CFrame.Angles(rotationY, 0, 0) * 
		CFrame.new(humanoid.CameraOffset) * 
		CFrame.new(cameraSettings.offset),
		0.5
	)
	
	-- Clip correction
	local rayOrigin = humanoidRootPart.Position + Vector3.new(0, cameraSettings.offset.Y, 0)
	local rayDirection = currentCamera.CFrame * CFrame.new(0, 0, cameraSettings.clipCorrection).Position - rayOrigin
	local hitPart, hitPosition = workspace:FindPartOnRay(Ray.new(rayOrigin, rayDirection), character)
	
	if not (hitPart and hitPart.CanCollide) then
		return
	end
	
	currentCamera.CFrame = CFrame.new(hitPosition) * 
		(currentCamera.CFrame - currentCamera.CFrame.p) * 
		CFrame.new(0, 0, -cameraSettings.clipCorrection)
end)

if workspace:FindFirstChild("NormalChase") then
	workspace.NormalChase:Destroy()
end

if not workspace:FindFirstChild("LastLifeChase") then
	return
end

workspace.LastLifeChase:Destroy()
