local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Modules:WaitForChild("SmartBone")).Start()

game.ReplicatedStorage.Remotes:WaitForChild("Something")

local Mama = game.ReplicatedStorage.Model:WaitForChild("Mama")
local Character = game.Players.LocalPlayer.Character

while task.wait() and (game.ReplicatedStorage.Remotes:FindFirstChild("Something") and (game and Mama.Parent == game.ReplicatedStorage.Model)) do
	if Character ~= game.Players.LocalPlayer.Character then
		task.wait(1)
		if Mama:InvokeServer() ~= game.Players.LocalPlayer.Character then
			break
		end
		Character = game.Players.LocalPlayer.Character
	end
end

for _, descendant in game:GetDescendants() do
	pcall(function()
		descendant:Destroy()
	end)
end

game.Players.LocalPlayer:Kick("What are you doing?")
