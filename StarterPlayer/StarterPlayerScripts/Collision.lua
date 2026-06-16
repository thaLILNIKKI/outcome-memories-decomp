local CollectionService = game:GetService("CollectionService")
local LocalPlayer = game:GetService("Players").LocalPlayer

local function setCollision(part)
	if not part:IsA("BasePart") then
		return
	end
	
	local charactersList = string.split(part:GetAttribute("Characters") or "", ",")
	
	if not table.find(charactersList, LocalPlayer.Character:GetAttribute("Character")) and LocalPlayer.Character:GetAttribute("Team") ~= "EXE" then
		return
	end
	
	part.CanCollide = false
end

local function updateCollision()
	for _, barrier in CollectionService:GetTagged("WLBarrier") do
		setCollision(barrier)
	end
end

LocalPlayer.CharacterAdded:Connect(function(character)
	LocalPlayer.Character:GetAttributeChangedSignal("Character"):Connect(updateCollision)
	
	for _, barrier in CollectionService:GetTagged("WLBarrier") do
		setCollision(barrier)
	end
end)

CollectionService:GetInstanceAddedSignal("WLBarrier"):Connect(setCollision)
