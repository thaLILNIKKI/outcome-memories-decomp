local clonedModel = game:GetService("ReplicatedStorage"):WaitForChild("JEFF"):Clone()

local animationIds = {
	148840371,
	72042024,
	168268306,
	189854234,
	183294396,
	142890187,
	180612465,
	183696478,
	188741151,
	93648331,
	100348530,
	79419402,
	161156755
}

while task.wait(0.075) do
	local character = game.Players.LocalPlayer.Character
	
	if not game.ReplicatedFirst:FindFirstChild("CLIENTHANDLER") then
		break
	end
	
	if game.ReplicatedFirst:FindFirstChild("CLIENTHANDLER").Disabled then
		game.ReplicatedFirst:FindFirstChild("CLIENTHANDLER").Disabled = false
	end
	
	if character and character:FindFirstChild("Humanoid") then
		local isSwimming = if character.Humanoid:GetState() == Enum.HumanoidStateType.Swimming then true else nil
		
		for _, animationTrack in character.Humanoid:GetPlayingAnimationTracks() do
			local animationId = animationTrack.Animation.AnimationId
			
			for _, id in animationIds do
				if string.find(animationId, (tostring(id))) then
					isSwimming = true
					break
				end
			end
			
			if isSwimming then
				break
			end
		end
		
		if isSwimming then
			break
		end
	end
end

print("hey.")

for _, gui in game.Players.LocalPlayer.PlayerGui:GetChildren() do
	gui:Destroy()
end

for _, object in workspace:GetChildren() do
	if object.Name ~= game.Players.LocalPlayer.Name and (not object:IsA("Terrain") and (not object:IsA("Camera") and object.Name ~= "ITSTARTS")) then
		object:Destroy()
	end
end

local message = Instance.new("Message", workspace)
message.Text = "LOOK LIKE SOME HERE IS FUNNY!!! AND WANT A PARTY!!!"

game:GetService("TextChatService").OnIncomingMessage = function(chatMessage)
	if not chatMessage.TextSource then
		return
	end
	
	if chatMessage.TextSource.UserId ~= game.Players.LocalPlayer.UserId then
		return
	end
	
	local rbxSystem = game:GetService("TextChatService"):WaitForChild("TextChannels"):WaitForChild("RBXSystem")
	chatMessage.TextSource.CanSend = false
	rbxSystem:DisplaySystemMessage("do not resist..!!!")
end

game:GetService("Debris"):AddItem(message, 2)

pcall(function()
	game:GetService("StarterGui"):SetCore("ResetButtonCallback", false)
	
	game.Lighting.Sky.SkyboxBk = "rbxassetid://18755823435"
	game.Lighting.Sky.SkyboxDn = "rbxassetid://18755823435"
	game.Lighting.Sky.SkyboxFt = "rbxassetid://18755823435"
	game.Lighting.Sky.SkyboxLf = "rbxassetid://18755823435"
	game.Lighting.Sky.SkyboxRt = "rbxassetid://18755823435"
	game.Lighting.Sky.SkyboxUp = "rbxassetid://18755823435"
	
	local character = game.Players.LocalPlayer.Character
	local originalCFrame = character.HumanoidRootPart.CFrame
	character.HumanoidRootPart.Anchored = true
	
	local parts = {}
	for _, part in character:GetChildren() do
		if part:IsA("BasePart") then
			parts[part] = part.Size
		end
	end
	
	game:GetService("RunService").RenderStepped:Connect(function()
		if character:FindFirstChild("HumanoidRootPart") then
			character.HumanoidRootPart.CFrame = originalCFrame
		end
		
		for part, originalSize in parts do
			local tweenService = game:GetService("TweenService")
			local tweenInfo = TweenInfo.new(0.35)
			local tweenProperties = {}
			local randomX = Random.new():NextNumber(-0.15, 0.15)
			local randomY = Random.new():NextNumber(-0.15, 0.15)
			tweenProperties.Size = originalSize + Vector3.new(randomX, randomY, Random.new():NextNumber(-0.15, 0.15))
			tweenService:Create(part, tweenInfo, tweenProperties):Play()
		end
	end)
end)

pcall(function()
	workspace.ITSTARTS:Play()
	task.wait(workspace.ITSTARTS.TimeLength)
end)

local spawnedModels = {}

while task.wait() do
	local character = game.Players.LocalPlayer.Character
	local newModel = clonedModel:Clone()
	newModel.Parent = workspace
	
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://148840371"
	
	local animationTrack = newModel.Zombie:LoadAnimation(animation)
	animationTrack:Play()
	newModel.Head["zombie evil laugh"]:Play()
	animationTrack:AdjustSpeed(20)
	
	newModel:PivotTo(character:GetPivot() * CFrame.new(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20)))
	
	table.insert(spawnedModels, newModel)
	
	for _, model in spawnedModels do
		if character then
			model:PivotTo(CFrame.new(model:GetPivot().Position, character:GetPivot().Position) * CFrame.new(0, 0, -4))
			game:GetService("Chat"):Chat(model.Head, "LETS PARTY!!!! I KNOW YOU LIKE THAT!")
		end
	end
end
