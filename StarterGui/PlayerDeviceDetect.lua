task.wait(0.5)

local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")

local isGamepadEnabled = userInputService.GamepadEnabled
local isKeyboardEnabled = userInputService.KeyboardEnabled
local isTouchEnabled = userInputService.TouchEnabled

if isKeyboardEnabled and not isTouchEnabled then
	print("pc")
	game.ReplicatedStorage.Remotes.device:FireServer("pc")
elseif isTouchEnabled then
	print("mobile")
	game.ReplicatedStorage.Remotes.device:FireServer("mo")
elseif isGamepadEnabled then
	print("pc")
	game.ReplicatedStorage.Remotes.device:FireServer("co")
end

game:GetService("UserInputService").LastInputTypeChanged:Connect(function()
	isGamepadEnabled = userInputService.GamepadEnabled
	isKeyboardEnabled = userInputService.KeyboardEnabled
	isTouchEnabled = userInputService.TouchEnabled
	
	if isKeyboardEnabled and not isTouchEnabled then
		game.ReplicatedStorage.Remotes.device:FireServer("pc")
	elseif isTouchEnabled and not isKeyboardEnabled then
		game.ReplicatedStorage.Remotes.device:FireServer("mo")
	end
	
	if isGamepadEnabled then
		game.ReplicatedStorage.Remotes.device:FireServer("co")
	end
	
	if not (isKeyboardEnabled and isTouchEnabled) then
		return
	end
	
	game.ReplicatedStorage.Remotes.device:FireServer("pc")
end)

while task.wait() do
	if not player.PlayerGui:FindFirstChild("TouchGui") then
		continue
	end
	
	local jumpButton = player.PlayerGui.TouchGui.TouchControlFrame.JumpButton
	
	if jumpButton.Visible then
		continue
	end
	
	jumpButton.Visible = true
end
