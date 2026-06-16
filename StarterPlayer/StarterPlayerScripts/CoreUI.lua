local LocalPlayer = game:GetService("Players").LocalPlayer
local StarterGui = game:GetService("StarterGui")

local success = nil

while not success do
	task.wait()
	local result, _ = pcall(function()
		return StarterGui:SetCore("ResetButtonCallback", false)
	end)
	success = result
end

LocalPlayer.CharacterAdded:Connect(function(character)
	if character.Parent.Name == "Players" then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	else
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
	end
end)
