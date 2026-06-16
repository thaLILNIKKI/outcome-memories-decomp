local LocalPlayer = game.Players.LocalPlayer

if not LocalPlayer.Character then
	LocalPlayer.CharacterAdded:Wait()
end

local HumanoidRootPart = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")

if HumanoidRootPart:FindFirstChild("Running") then
	HumanoidRootPart:WaitForChild("Running"):Destroy()
end
