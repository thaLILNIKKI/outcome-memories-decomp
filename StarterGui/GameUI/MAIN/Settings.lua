local TweenService = game:GetService("TweenService")
local DataUpdate = game:GetService("ReplicatedStorage").Remotes.DataUpdate
local Settings = script.Parent.Parent.Menu.Settings

local isKeybindsVisible = false
local abilityNames = {
	"AB1",
	"AB2",
	"AB3",
	"AB4",
	"Activation/Attack",
	"Run Buttons",
	"Emotes"
}

function updateKeybinds(settingsData)
	local keybindType = if game.Players.LocalPlayer.Device.Value == "pc" or game.Players.LocalPlayer.Device.Value == "mo" then "PCKeyBinds" else "ControllerKeybinds"
	print(settingsData)
	
	for _, child in Settings.ABBinds:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	local currentInputConnection = nil
	local keybinds = settingsData[keybindType] or {}
	
	for index, key in keybinds do
		local abilityName = abilityNames[tonumber(index)] or "IDK"
		local displayText = string.format("%s:%s", abilityName, key)
		
		local button = script.Parent.EX:Clone()
		button.Text = displayText
		button.Parent = Settings.ABBinds
		
		button.MouseButton1Click:Connect(function()
			if not currentInputConnection then
				button.Text = string.format("%s:%s", abilityName, "...")
				script.Parent.MenuBleep:Play()
				task.wait(0.1)
				
				currentInputConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
					if gameProcessed then
						return
					end
					
					if input.KeyCode == Enum.KeyCode.Unknown then
						return
					end
					
					settingsData[keybindType][index] = input.KeyCode.Name
					script.Parent.Sumbit:Play()
					currentInputConnection:Disconnect()
					currentInputConnection = nil
					DataUpdate:InvokeServer("UpdateSettings", { keybindType, settingsData[keybindType] })
					updateKeybinds(settingsData)
				end)
			end
		end)
	end
end

local DraggableObject = require(script.Parent.DraggableObject)
local draggableInstances = {}
local Bar = Settings.Ability.Bar

function updateMobileLayout(settingsData)
	for _, instance in draggableInstances do
		instance:Disable()
		draggableInstances[_] = nil
	end
	
	for _, child in Settings.Ability.Bar:GetChildren() do
		if child.Name ~= "AB0" then
			child:Destroy()
		end
	end
	
	for elementName, positionData in settingsData.MobileLayout do
		if string.find(string.lower(elementName), "ab") then
			local newButton = Bar.AB0:Clone()
			newButton.Name = elementName
			newButton.Visible = true
			newButton.Position = UDim2.new(unpack(positionData))
			newButton.ABName.Text = elementName
			newButton.Parent = Bar
			
			draggableInstances[newButton] = DraggableObject.new(newButton)
			draggableInstances[newButton]:Enable()
		else
			local elementMapping = {
				HPBar = Settings.Game.SurvivorHP,
				Activates = Settings.Game.Attack,
				RunButton = Settings.Game.Sprint,
				EmoteBar = Settings.Game.Emote
			}
			local element = elementMapping[elementName]
			element.Position = UDim2.new(unpack(positionData))
			
			draggableInstances[element] = DraggableObject.new(element)
			draggableInstances[element]:Enable()
		end
	end
end

local isMobileLayoutOpen = false

return {
	{
		"Preferences",
		{
			{
				{ "Keybinds", "Keybinds" },
				"Enterer",
				function(settingsData)
					if game.Players.LocalPlayer.Device.Value == "mo" then
						return
					end
					
					isKeybindsVisible = not isKeybindsVisible
					Settings.ABBinds.Visible = isKeybindsVisible
					
					if not isKeybindsVisible then
						return
					end
					
					Settings.ABBinds.Position = UDim2.new(0.3, 0, 0.274, 0)
					Settings.ABBinds.Size = UDim2.new(0, 0, 0.298, 0)
					
					TweenService:Create(Settings.ABBinds, TweenInfo.new(0.5), {
						Position = UDim2.new(0.34, 0, 0.274, 0),
						Size = UDim2.new(0.154, 0, 0.298, 0)
					}):Play()
					
					updateKeybinds(settingsData)
				end
			},
			{
				{ "MobileLayout", "Mobile Layout" },
				"Enterer",
				function(settingsData)
					if game.Players.LocalPlayer.Device.Value ~= "mo" then
						return
					end
					
					isMobileLayoutOpen = not isMobileLayoutOpen
					Settings.Game.Visible = isMobileLayoutOpen
					
					if not isMobileLayoutOpen then
						return
					end
					
					updateMobileLayout(settingsData)
					isKeybindsVisible = false
					game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 0
					Settings.ABBinds.Visible = isKeybindsVisible
					Settings.SETUI.Visible = false
					Settings.EXIT.Visible = true
					Settings.RESET.Visible = true
					
					local exitConnection = nil
					local resetConnection = nil
					
					exitConnection = Settings.EXIT.Activated:Connect(function()
						if game.Players.LocalPlayer.Device.Value ~= "mo" then
							return
						end
						
						isMobileLayoutOpen = false
						exitConnection:Disconnect()
						resetConnection:Disconnect()
						Settings.SETUI.Visible = true
						Settings.EXIT.Visible = false
						Settings.RESET.Visible = false
						
						for _, instance in draggableInstances do
							instance:Disable()
							draggableInstances[_] = nil
						end
						
						Settings.Game.Visible = isMobileLayoutOpen
						game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
						
						for _, child in Settings.Ability.Bar:GetChildren() do
							if child.Name ~= "AB0" then
								if settingsData.MobileLayout[child.Name] then
									settingsData.MobileLayout[child.Name] = {
										child.Position.X.Scale,
										child.Position.X.Offset,
										child.Position.Y.Scale,
										child.Position.Y.Offset
									}
								end
								child:Destroy()
							end
						end
						
						local elementMapping = {
							HPBar = Settings.Game.SurvivorHP,
							Activates = Settings.Game.Attack,
							RunButton = Settings.Game.Sprint,
							EmoteBar = Settings.Game.Emote
						}
						
						for elementName, element in elementMapping do
							if settingsData.MobileLayout[elementName] then
								settingsData.MobileLayout[elementName] = {
									element.Position.X.Scale,
									element.Position.X.Offset,
									element.Position.Y.Scale,
									element.Position.Y.Offset
								}
							end
						end
						
						print(settingsData.MobileLayout)
						DataUpdate:InvokeServer("UpdateSettings", { "MobileLayout", settingsData.MobileLayout })
					end)
					
					resetConnection = Settings.RESET.Activated:Connect(function()
						settingsData.MobileLayout = {
							AB1 = { 0.26, 0, -1.455, 0 },
							AB2 = { 0.423, 0, -2.455, 0 },
							AB3 = { 0.71, 0, -2.455, 0 },
							AB4 = { 0.879, 0, -1.571, 0 },
							Activates = { 0.722, 0, 0.804, 0 },
							RunButton = { 0.596, 0, 0.661, 0 },
							EmoteBar = { 0.23, 0, 0.64, 0 },
							HPBar = { 0.004, 0, 0.766, 0 }
						}
						updateMobileLayout(settingsData)
					end)
				end
			},
			{
				{ "SprintToggle", "Sprint Toggle" },
				"Enabler",
				false
			},
			{
				{ "DisableTag", "Tag Toggle" },
				"Enabler",
				false
			},
			{
				{ "LowGraphic", "Fast Mode (Experimental ATM)" },
				"Enabler",
				false,
				function(enabled)
					if enabled then
						workspace:AddTag("FastMode")
					else
						workspace:RemoveTag("FastMode")
					end
				end
			},
			{
				{ "Hitsound", "Hit Sound" },
				"Enabler",
				false,
				function(enabled)
					if enabled then
						game.ReplicatedStorage.ClientAssets.Sounds.sfx.Game.HitSFX.PlaybackSpeed = 1
					else
						game.ReplicatedStorage.ClientAssets.Sounds.sfx.Game.HitSFX.PlaybackSpeed = 0
					end
				end
			},
			{
				{ "HitID", "Hit Sound ID" },
				"Stringer",
				"139520673393967",
				function(soundId)
					game.ReplicatedStorage.ClientAssets.Sounds.sfx.Game.HitSFX.SoundId = "rbxassetid://" .. soundId
				end,
				{ "Hitsound", true },
				function(value)
					return tonumber(value) and true or false
				end
			},
			{
				{ "HitVolume", "Hit Sound Volume" },
				"Slider",
				{ 50, 100, 5, 0 },
				function(volume)
					game.ReplicatedStorage.ClientAssets.Sounds.sfx.Game.HitSFX.Volume = 3 * (volume / 100)
				end,
				{ "Hitsound", true }
			},
			{
				"Button",
				"Preview Hit Sound",
				function()
					local sound = game.ReplicatedStorage.ClientAssets.Sounds.sfx.Game.HitSFX:Clone()
					sound.Parent = script.Parent
					sound:Play()
					game:GetService("Debris"):AddItem(sound, 2)
				end,
				{ "Hitsound", true }
			},
			{
				{ "ScoreDisplay", "Score Overlay Toggle" },
				"Enabler",
				true,
				function(enabled)
					if enabled then
						game.Players.LocalPlayer.PlayerGui.InGameUI.Frame.Visible = true
						game.Players.LocalPlayer.PlayerGui.InGameUI.Frame.RankUP.Volume = 0.5
					else
						game.Players.LocalPlayer.PlayerGui.InGameUI.Frame.Visible = false
						game.Players.LocalPlayer.PlayerGui.InGameUI.Frame.RankUP.Volume = 0
					end
				end
			},
			{
				{ "NoEXE", "Disable EXE Chance" },
				"Enabler",
				false
			},
			{
				{ "DebugMode", "Debug Mode" },
				"Enabler",
				false,
				function(enabled)
					if enabled then
						game.Players.LocalPlayer.PlayerGui.Main.Game.Visible = true
					else
						game.Players.LocalPlayer.PlayerGui.Main.Game.Visible = false
					end
				end
			}
		}
	},
	{
		"Sounds",
		{
			{
				{ "MusicVolume", "Music Volume" },
				"Slider",
				{ 50, 100, 5, 0 },
				function(volume)
					game.ReplicatedStorage.ClientAssets.Sounds:WaitForChild("musg").Volume = volume / 100
				end
			}
		}
	},
	{
		"Camera",
		{
			{
				{ "FieldOfView", "Field Of View" },
				"Slider",
				{ 70, 120, 1, 60 }
			},
			{
				{ "CameraShakeIntensity", "Camera Shake Intensity" },
				"Slider",
				{ 50, 100, 5, 0 }
			}
		}
	},
	{
		"Debug",
		{
			{
				{ "ServerGhost", "Server Hitbox" },
				"Enabler",
				false,
				function(enabled)
					if enabled then
						game.Players.LocalPlayer:AddTag("ServerGhost")
					else
						game.Players.LocalPlayer:RemoveTag("ServerGhost")
					end
				end
			}
		}
	}
}
