local LocalPlayer = game.Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()
local Main = LocalPlayer.PlayerGui:WaitForChild("Main")
local UserInputService = game:GetService("UserInputService")
local GamepadService = game:GetService("GamepadService")

local isCursorHidden = false
local isLocked = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode ~= Enum.KeyCode.LeftControl then
		return
	end
	
	if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		isLocked = false
		return
	end
	
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	isLocked = true
end)

if game.Players.LocalPlayer:WaitForChild("Device").Value ~= "con" then
	mouse.Icon = "http://www.roblox.com/asset/?id=80896616817489"
end

if UserInputService.TouchEnabled or not (UserInputService.KeyboardEnabled and UserInputService.MouseEnabled) then
	Main.Frame.cursortest.Visible = false
	Main.ScreenInsets = Enum.ScreenInsets.None
	Main.Frame.crosshair.Visible = true
else
	Main.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	
	game:GetService("RunService").RenderStepped:Connect(function()
		if not LocalPlayer:FindFirstChild("Device") then
			return
		end
		
		if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default and LocalPlayer:HasTag("OnRESULT") then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
		
		Main.Frame.cursortest.Position = Main.Frame.cursortest.Position:Lerp(UDim2.new(0, mouse.X, 0, mouse.Y), 0.5)
		Main.Frame.crosshair.Position = Main.Frame.crosshair.Position:Lerp(UDim2.new(0, mouse.X, 0, mouse.Y), 0.5)
		
		if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter and not isCursorHidden or game.Players.LocalPlayer.Device.Value == "con" and not GamepadService.GamepadCursorEnabled then
			isCursorHidden = true
			Main.Frame.crosshair.Visible = true
			Main.Frame.cursortest.Visible = false
			Main.Frame.crosshair.ImageTransparency = 1
			
			game:GetService("TweenService"):Create(Main.Frame.crosshair, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Rotation = -180,
				ImageTransparency = 0
			}):Play()
			return
		end
		
		if (UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default or not isCursorHidden) and (game.Players.LocalPlayer.Device.Value ~= "con" or not GamepadService.GamepadCursorEnabled) then
			return
		end
		
		isCursorHidden = false
		Main.Frame.cursortest.Visible = true
		
		game:GetService("TweenService"):Create(Main.Frame.crosshair, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Rotation = 0,
			ImageTransparency = 1
		}):Play()
	end)
end
