local LocalPlayer = game.Players.LocalPlayer
local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()

repeat
	task.wait()
until not LocalPlayer:HasTag("Loading")

warn("loaded")

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
game:GetService("RunService")
game:GetService("Lighting")
game:GetService("Players")

local Menu = ReplicatedStorage.ClientAssets.Sounds.mus.Menu
local MenuSounds = ReplicatedStorage.ClientAssets.Sounds.sfx.Menu
local Lightings = ReplicatedStorage.ClientAssets.Misc.Lightings
local GameProperties = workspace.GameProperties

game:GetService("ReplicatedStorage").Remotes.DataUpdate:InvokeServer("FetchData", { "setting" })

local CurrentCamera = game.Workspace.CurrentCamera
local Remotes = ReplicatedStorage.Remotes
local DataUpdate = game:GetService("ReplicatedStorage").Remotes.DataUpdate
local settingsData = DataUpdate:InvokeServer("FetchData", { "setting" })

local Settings = script.Parent.Menu.Settings
local SettingsModule = require(script.Settings)
local SettingsFrame = script.SettingsFrame

game.Players.LocalPlayer:WaitForChild("Device")

local SETUI = Settings.SETUI

require(ReplicatedStorage.Modules.SpriteClip2)
local Functions = require(game.ReplicatedFirst.CLIENTHANDLER.Functions)

local Intro = script.Parent.Menu.Intro
local Lobby = script.Parent.Lobby
local MenuContainer = script.Parent.Menu
local Menu1 = MenuContainer.Menu1
local Menu2 = MenuContainer.Menu2
local WhiteFade = MenuContainer.WhiteFade
local CharSelect = script.Parent.CharSelect
local SelectScreen = CharSelect.Select.SelectScreen

local menuParts = {
	Menu2.BottomBar,
	Menu2.TopBar,
	Menu2.ThecoolTop,
	Menu2.thecoolBottom2,
	Menu2.TopZigzag1,
	Menu2.TopZigzag2,
	Menu2.BottomZigzag1,
	Menu2.BottomZigzag2
}

local originalPositions = {}
local rotationX = 0
local rotationY = 0
local selectedButton = 0
local isMenuOpen = false
local isLoading = false
local currentCamRig = nil
local buttonConnections = {}
local menuButtons = { "Play", "Shop", "Gallery", "Settings", "Menu" }
local currentOptionFunc = nil
local buttonFunctions = {}
local isCharSelectOpen = false
local isSelecting = false
local selectedCharacter = ""
local charSelectConnections = nil
local isProcessing = false
local buttonVisibilityConditions = {}
local isClosing = false
local audioVolumeTween = nil
local currentSong = nil
local menuButtonStates = {}

for _, part in pairs(menuParts) do
	originalPositions[part.Name] = part.Position
end

local renderSteppedConnection = nil
local isForceClosing = false

local function showDisclaimer()
	Intro.DISCLAIMER.CONTINUE.Activated:Once(function()
		isForceClosing = true
		DataUpdate:InvokeServer("ViewedDisclaimer")
	end)
	
	Intro.DISCLAIMER.Visible = true
	Menu.Disclaimer10:Play()
	
	repeat
		task.wait()
	until isForceClosing
	
	Menu.Disclaimer10:Stop()
	Intro.Visible = false
	Intro.DISCLAIMER.Visible = false
	script.Parent.Parent.GameUI.Enabled = true
end

local function toggleScripts(parent, enabled, depth, scriptType)
	if depth == 1 then
		for _, child in pairs(parent:GetChildren()) do
			if child:IsA("Script") and scriptType == 1 then
				child.Enabled = enabled
			elseif child:IsA("LocalScript") and scriptType == 2 then
				child.Enabled = enabled
			elseif (child:IsA("Script") or child:IsA("LocalScript")) and scriptType == 3 then
				child.Enabled = enabled
			end
		end
	else
		for _, descendant in pairs(parent:GetDescendants()) do
			if descendant:IsA("Script") and scriptType == 1 then
				descendant.Enabled = enabled
			elseif descendant:IsA("LocalScript") and scriptType == 2 then
				descendant.Enabled = enabled
			elseif (descendant:IsA("Script") or descendant:IsA("LocalScript")) and scriptType == 3 then
				descendant.Enabled = enabled
			end
		end
	end
end

local menuHandler = nil

local function setupMenuButton(button, index, context)
	buttonConnections[menuButtons[index]] = {}
	
	buttonConnections[menuButtons[index]][1] = button.MouseEnter:Connect(function()
		if rotationX == index or (rotationY ~= 0 or selectedButton ~= 2 and selectedButton ~= 3) then
			return
		end
		
		rotationX = index
		MenuSounds.MenuBleep:Play()
		
		if context ~= "Lobby" then
			local targetCFrame = nil
			
			if index == 1 and selectedButton == 2 or index ~= 1 then
				targetCFrame = currentCamRig.Cameras:FindFirstChild(menuButtons[index] .. "Cam").CFrame
			else
				targetCFrame = Menu2.Pos.Value
			end
			
			if CurrentCamera.CFrame ~= targetCFrame then
				if currentCamRig.Cameras:FindFirstChild(menuButtons[index] .. "Cam"):FindFirstChild("Value") then
					CurrentCamera.CFrame = currentCamRig.Cameras:FindFirstChild(menuButtons[index] .. "Cam").Value.Value
				else
					CurrentCamera.CFrame = targetCFrame
				end
				
				TweenService:Create(CurrentCamera, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					CFrame = targetCFrame
				}):Play()
				
				Menu2.Static.ImageTransparency = 0
				MenuSounds.MenuStatic:Play()
				
				TweenService:Create(Menu2.Static, TweenInfo.new(0.5), {
					ImageTransparency = 1
				}):Play()
				
				for _, rig in pairs(currentCamRig.MenuRigs.Model:GetChildren()) do
					if string.match(rig.Name, menuButtons[index]) and rig:FindFirstChild("StartTween") then
						local primaryPart = rig.HumanoidRootPart or rig
						local startTween = rig.StartTween
						primaryPart.CFrame = startTween.Value
						
						TweenService:Create(primaryPart, TweenInfo.new(startTween:GetAttribute("time"), Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							CFrame = rig.EndTween.Value
						}):Play()
					end
				end
			end
		end
		
		if button.Parent == Menu2.ThecoolTop then
			TweenService:Create(button, TweenInfo.new(0.5), {
				Position = UDim2.new(button.Position.X.Scale, -14, button.Position.Y.Scale, -4)
			}):Play()
		else
			TweenService:Create(button, TweenInfo.new(0.5), {
				Position = UDim2.new(button.Position.X.Scale, -14, button.Position.Y.Scale, 6)
			}):Play()
		end
		
		TweenService:Create(button:FindFirstChild("highlight"), TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			AnchorPoint = Vector2.new(0.03, 0.02)
		}):Play()
	end)
	
	buttonConnections[menuButtons[index]][2] = button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.5), {
			Position = UDim2.new(button.Position.X.Scale, 0, button.Position.Y.Scale, 0)
		}):Play()
		
		TweenService:Create(button:FindFirstChild("highlight"), TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			AnchorPoint = Vector2.new(0, 0)
		}):Play()
	end)
	
	buttonConnections[menuButtons[index]][3] = button.Activated:Connect(function()
		if rotationY ~= 0 then
			return
		end
		
		local highlight = button:FindFirstChild("highlight")
		warn("y")
		rotationY = index
		
		if rotationX ~= index then
			rotationX = index
			
			if context ~= "Lobby" then
				local targetCFrame = nil
				
				if index == 1 and selectedButton == 2 or index ~= 1 then
					targetCFrame = currentCamRig.Cameras:FindFirstChild(menuButtons[index] .. "Cam").CFrame
				else
					targetCFrame = Menu2.Pos.Value
				end
				
				if CurrentCamera.CFrame ~= targetCFrame then
					if currentCamRig.Cameras:FindFirstChild(menuButtons[index] .. "Cam"):FindFirstChild("Value") then
						CurrentCamera.CFrame = currentCamRig.Cameras:FindFirstChild(menuButtons[index] .. "Cam").Value.Value
					else
						CurrentCamera.CFrame = targetCFrame
					end
					
					TweenService:Create(CurrentCamera, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						CFrame = targetCFrame
					}):Play()
					
					Menu2.Static.ImageTransparency = 0
					MenuSounds.MenuStatic:Play()
					
					TweenService:Create(Menu2.Static, TweenInfo.new(0.5), {
						ImageTransparency = 1
					}):Play()
					
					for _, rig in pairs(currentCamRig.MenuRigs.Model:GetChildren()) do
						if string.match(rig.Name, menuButtons[index]) and rig:FindFirstChild("StartTween") then
							local primaryPart = rig.HumanoidRootPart or rig
							local startTween = rig.StartTween
							primaryPart.CFrame = startTween.Value
							
							TweenService:Create(primaryPart, TweenInfo.new(startTween:GetAttribute("time"), Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
								CFrame = rig.EndTween.Value
							}):Play()
						end
					end
				end
			end
			
			if button.Parent == Menu2.ThecoolTop then
				TweenService:Create(button, TweenInfo.new(0.5), {
					Position = UDim2.new(button.Position.X.Scale, -14, button.Position.Y.Scale, -4)
				}):Play()
			else
				TweenService:Create(button, TweenInfo.new(0.5), {
					Position = UDim2.new(button.Position.X.Scale, -14, button.Position.Y.Scale, 6)
				}):Play()
			end
			
			TweenService:Create(highlight, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				AnchorPoint = Vector2.new(0.03, 0.02)
			}):Play()
			
			task.wait(0.5)
		end
		
		TweenService:Create(highlight, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			AnchorPoint = Vector2.new(0, 0)
		}):Play()
		
		menuHandler[menuButtons[index]](context)
	end)
end

local openMenu2 = nil
local optionFunc = nil
local isShopOpen = false

openMenu2 = {
	OpenMenu2 = function(context)
		if LocalPlayer:HasTag("OnRESULT") then
			return
		end
		
		selectedButton = 2
		
		if context == "StartMenu" then
			MenuSounds["Synth Whooshes Airy Pass Bys Slightly Phasey (SFX)"]:Play()
			
			Menu2.Position = UDim2.new(-0.8, 0, 0.5, 0)
			Menu2.ThecoolTop.Play.Position = UDim2.new(-1.451, 0, -1.5, 0)
			Menu2.ThecoolTop.Shop.Position = UDim2.new(-1.388, 0, -1.5, 0)
			Menu2.thecoolBottom2.Gallery.Position = UDim2.new(-1.001, 0, 2.8, 0)
			Menu2.thecoolBottom2.Settings.Position = UDim2.new(-1.006, 0, 2.8, 0)
			
			TweenService:Create(Menu1.UIScale, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
				Scale = 5
			}):Play()
			
			TweenService:Create(CurrentCamera, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
				CFrame = CFrame.new(Vector3.new(-41.176, -10.799, -759.254))
			}):Play()
			
			task.wait(1.6)
			
			Menu2.Visible = true
			toggleScripts(Menu2, true, 2, 3)
			Menu2.ZIndex = 1
			Menu1:Destroy()
			
			repeat
				CurrentCamera.CFrame = currentCamRig.Cameras:WaitForChild("PlayCam").CFrame - Vector3.new(10, 0, 0)
				task.wait()
			until CurrentCamera.CFrame == currentCamRig.Cameras:WaitForChild("PlayCam").CFrame - Vector3.new(10, 0, 0)
			
			Menu2.ThecoolTop.blur.Position = UDim2.new(-0.094, 0, -2.5, 0)
			
			TweenService:Create(CurrentCamera, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				CFrame = currentCamRig.Cameras.PlayCam.CFrame
			}):Play()
			
			TweenService:Create(Menu2, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.2, 0, 0.5, 0)
			}):Play()
			
			task.wait(0.3)
			
			TweenService:Create(Menu2.ThecoolTop.blur, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new(-0.094, 0, 0.6, 0)
			}):Play()
			
			task.wait(0.3)
			
			Menu2.ThecoolTop.Zig1B1.Visible = true
			Menu2.ThecoolTop.Zig1B2.Visible = true
			Menu2.ThecoolTop.Zig1R1.Visible = true
			Menu2.ThecoolTop.CoolThing1.Visible = true
			
			task.wait(0.2)
			
			TweenService:Create(Menu2.ThecoolTop.Play, TweenInfo.new(1.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new(-1.451, 0, 0.108, 0)
			}):Play()
			
			TweenService:Create(Menu2.ThecoolTop.Shop, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new(-1.388, 0, 0.267, 0)
			}):Play()
			
			TweenService:Create(Menu2.thecoolBottom2.Settings, TweenInfo.new(1.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new(-1.006, 0, 0.895, 0)
			}):Play()
			
			TweenService:Create(Menu2.thecoolBottom2.Gallery, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new(-1.001, 0, 0.711, 0)
			}):Play()
			
			task.wait(2.5)
			
			setupMenuButton(Menu2.ThecoolTop.Play, 1)
			setupMenuButton(Menu2.ThecoolTop.Shop, 2)
			setupMenuButton(Menu2.thecoolBottom2.Gallery, 3)
			setupMenuButton(Menu2.thecoolBottom2.Settings, 4)
			
			return true
		end
		
		if context ~= "Lobby" then
			return
		end
		
		isShopOpen = CurrentCamera.CameraType == Enum.CameraType.Custom
		Lobby.Visible = false
		Menu.MenuLoop.PlaybackSpeed = 1
		script.Parent.Menu.Visible = true
		Menu.MenuLoop:Resume()
		workspace.Lobby.LobbyMus.Volume = 0
		script.Parent.LobbyStatic.Visible = true
		MenuSounds.MenuStatic2.Volume = 2
		MenuSounds.MenuStatic2:Play()
		
		TweenService:Create(MenuSounds.MenuStatic2, TweenInfo.new(0.5), {
			Volume = 0
		}):Play()
		
		script.Parent.LobbyStatic.ImageTransparency = 0
		character.cam:SetAttribute("stop", true)
		LocalPlayer:AddTag("StartMenu")
		CurrentCamera.FieldOfView = 70
		
		for _, part in pairs(menuParts) do
			part.Position = originalPositions[part.Name]
		end
		
		repeat
			CurrentCamera.CameraType = Enum.CameraType.Scriptable
		until CurrentCamera.CameraType == Enum.CameraType.Scriptable
		
		CurrentCamera.CFrame = workspace.Lobby.Cams:GetChildren()[math.random(1, #workspace.Lobby.Cams:GetChildren())].CFrame
		
		local startTime = tick()
		renderSteppedConnection = game:GetService("RunService").RenderStepped:Connect(function()
			local currentTime = tick()
			workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(
				workspace.CurrentCamera.CFrame * CFrame.Angles(
					math.sin(currentTime - startTime * 1.5) / 10 / 10,
					math.sin(currentTime - startTime * 3) / 15 / 10,
					0
				),
				0.1
			)
		end)
		
		toggleScripts(Menu2, true, 2, 3)
		
		TweenService:Create(script.Parent.LobbyStatic, TweenInfo.new(0.5), {
			ImageTransparency = 1
		}):Play()
		
		MenuSounds["Synth Whooshes Airy Pass Bys Slightly Phasey (SFX)"]:Play()
		Menu2.Black.Visible = false
		Menu2.Position = UDim2.new(-0.2, 0, 0.5, 0)
		Menu2.ThecoolTop.Play.Position = UDim2.new(-1.451, 0, -1.5, 0)
		Menu2.ThecoolTop.Shop.Position = UDim2.new(-1.388, 0, -1.5, 0)
		Menu2.thecoolBottom2.Gallery.Position = UDim2.new(-1.001, 0, 2.8, 0)
		Menu2.thecoolBottom2.Settings.Position = UDim2.new(-1.006, 0, 2.8, 0)
		Menu2.Visible = true
		Menu2.ZIndex = 1
		Menu2.ThecoolTop.blur.Position = UDim2.new(-0.094, 0, -2.5, 0)
		
		TweenService:Create(Menu2, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.2, 0, 0.5, 0)
		}):Play()
		
		TweenService:Create(Menu2.ThecoolTop.blur, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(-0.094, 0, 0.6, 0)
		}):Play()
		
		Menu2.ThecoolTop.Zig1B1.Visible = true
		Menu2.ThecoolTop.Zig1B2.Visible = true
		Menu2.ThecoolTop.Zig1R1.Visible = true
		Menu2.ThecoolTop.CoolThing1.Visible = true
		
		TweenService:Create(Menu2.ThecoolTop.Play, TweenInfo.new(1.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(-1.451, 0, 0.108, 0)
		}):Play()
		
		TweenService:Create(Menu2.ThecoolTop.Shop, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(-1.388, 0, 0.267, 0)
		}):Play()
		
		TweenService:Create(Menu2.thecoolBottom2.Settings, TweenInfo.new(1.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(-1.006, 0, 0.895, 0)
		}):Play()
		
		TweenService:Create(Menu2.thecoolBottom2.Gallery, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(-1.001, 0, 0.711, 0)
		}):Play()
		
		task.wait(1)
		
		rotationX = 0
		rotationY = 0
		
		setupMenuButton(Menu2.ThecoolTop.Play, 1, "Lobby")
		setupMenuButton(Menu2.ThecoolTop.Shop, 2, "Lobby")
		setupMenuButton(Menu2.thecoolBottom2.Gallery, 3, "Lobby")
		setupMenuButton(Menu2.thecoolBottom2.Settings, 4, "Lobby")
	end,
	
	ForceClose = function()
		if renderSteppedConnection then
			renderSteppedConnection:Disconnect()
			renderSteppedConnection = nil
		end
		
		toggleScripts(Menu2, false, 2, 3)
		MenuSounds.MenuStatic2:Play()
		MenuSounds.MenuStatic2.Volume = 2
		LocalPlayer:RemoveTag("StartMenu")
		
		TweenService:Create(MenuSounds.MenuStatic2, TweenInfo.new(0.5), {
			Volume = 0
		}):Play()
		
		if script.Parent:FindFirstChild("shop") or script.Parent:FindFirstChild("Inventory") then
			warn("shop yes")
			
			if script.Parent:FindFirstChild("shop") then
				script.Parent.shop:Destroy()
				warn("shop die")
			end
			
			if script.Parent:FindFirstChild("Inventory") then
				script.Parent.Inventory:Destroy()
			end
			
			if game.Players.LocalPlayer.Character:FindFirstAncestor("Workspace") and not isShopOpen then
				character.cam:SetAttribute("stop", false)
				character.cam.Enabled = true
			end
			
			for _, sound in pairs(Menu.ShopMus:GetChildren()) do
				if sound.IsPlaying then
					local volume = sound.Volume
					TweenService:Create(sound, TweenInfo.new(0.7), {
						Volume = 0
					}):Play()
					
					task.delay(0.7, function()
						sound:Stop()
						sound.Volume = volume
					end)
				end
			end
			
			pcall(function()
				coroutine.close(optionFunc)
				warn("groge")
			end)
			optionFunc = nil
		elseif isShopOpen and not LocalPlayer:HasTag("OnRESULT") then
			repeat
				CurrentCamera.CameraType = Enum.CameraType.Custom
			until CurrentCamera.CameraType == Enum.CameraType.Custom
		elseif Settings.Visible then
			Settings.Visible = false
		else
			character.cam:SetAttribute("stop", false)
			character.cam.Enabled = true
		end
		
		Lobby.Visible = true
		script.Parent.LobbyStatic.Visible = true
		script.Parent.LobbyStatic.ImageTransparency = 0
		
		TweenService:Create(script.Parent.LobbyStatic, TweenInfo.new(0.5), {
			ImageTransparency = 1
		}):Play()
		
		Menu.MenuLoop:Pause()
		Menu2.Visible = false
		
		for _, connections in pairs(buttonConnections) do
			for _, connection in pairs(connections) do
				connection:Disconnect()
			end
		end
		
		selectedButton = 3
	end,
	
	OptionFunc = {
		Play = function(context)
			if context == "Lobby" then
				openMenu2.ForceClose()
				TweenService:Create(workspace.Lobby.LobbyMus, TweenInfo.new(0.5), {
					Volume = 0.7
				}):Play()
				return
			end
			
			toggleScripts(Menu2, false, 2, 3)
			
			local tweens = {
				{
					Menu2.BottomZigzag1,
					{
						Position = UDim2.new(0.25, 0, 1.049, 0)
					},
					TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				},
				{
					Menu2.BottomZigzag2,
					{
						Position = UDim2.new(0.749, 0, 1.049, 0)
					},
					TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				},
				{
					Menu2.TopZigzag1,
					{
						Position = UDim2.new(0.255, 0, -0.078, 0)
					},
					TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				},
				{
					Menu2.TopZigzag2,
					{
						Position = UDim2.new(0.766, 0, -0.078, 0)
					},
					TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				},
				{
					CurrentCamera,
					{
						FieldOfView = 10
					},
					TweenInfo.new(4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				},
				{
					Menu2.ThecoolTop,
					{
						Position = UDim2.new(1.9, 0, 0.464, 0)
					},
					TweenInfo.new(1.7, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				},
				{
					Menu2.thecoolBottom2,
					{
						Position = UDim2.new(1.9, 0, 0.441, 0)
					},
					TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				},
				{
					Menu.MenuLoop,
					{
						Pitch = 0
					},
					TweenInfo.new(4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
				},
				{
					MenuSounds.Laugh,
					{
						Pitch = 0
					},
					TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
				},
				{
					Menu2.TopBar,
					{
						Position = UDim2.new(0, 0, -0.085, 0)
					},
					TweenInfo.new(4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				},
				{
					Menu2.BottomBar,
					{
						Position = UDim2.new(0, 0, 0.533, 0)
					},
					TweenInfo.new(4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				}
			}
			
			TweenService:Create(Menu2.Arrow, TweenInfo.new(0.5), {
				ImageTransparency = 1
			}):Play()
			
			TweenService:Create(Menu2.ThecoolTop.Play, TweenInfo.new(0.5), {
				Position = UDim2.new(Menu2.ThecoolTop.Play.Position.X.Scale, 0, Menu2.ThecoolTop.Play.Position.Y.Scale, 0)
			}):Play()
			
			MenuSounds.MenuAccept2:Play()
			MenuSounds.Laugh:Play()
			
			for _, tweenData in pairs(tweens) do
				TweenService:Create(tweenData[1], tweenData[3], tweenData[2]):Play()
			end
			
			task.wait(4)
			
			for _, connections in pairs(buttonConnections) do
				for _, connection in pairs(connections) do
					connection:Disconnect()
				end
			end
			
			MenuSounds.bassboom:Play()
			MenuSounds.Laugh:Stop()
			Menu2.Black.Visible = true
			Lobby.Fade.Visible = true
			Lobby.Visible = true
			Menu2.Visible = false
			
			task.wait(0.5)
			
			repeat
				CurrentCamera.CameraType = Enum.CameraType.Custom
			until CurrentCamera.CameraType == Enum.CameraType.Custom
			
			Menu.MenuLoop:Pause()
			workspace.MenuAssets:Destroy()
			
			task.wait(2)
			
			character.cam.Enabled = true
			
			TweenService:Create(Lobby.Fade, TweenInfo.new(4, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
				BackgroundTransparency = 1
			}):Play()
			
			TweenService:Create(workspace.CurrentCamera, TweenInfo.new(4, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
				FieldOfView = 70
			}):Play()
			
			selectedButton = 3
			character.cam:SetAttribute("stop", false)
			character.HumanoidRootPart.Anchored = false
		end,
		
		Shop = function(context)
			if context ~= "Lobby" then
				rotationY = 0
				return
			end
			
			TweenService:Create(Menu2.ThecoolTop.Shop, TweenInfo.new(0.5), {
				Position = UDim2.new(Menu2.ThecoolTop.Shop.Position.X.Scale, 0, Menu2.ThecoolTop.Shop.Position.Y.Scale, 0)
			}):Play()
			
			MenuSounds.MenuAccept:Play()
			TweenService:Create(Menu.MenuLoop, TweenInfo.new(3), {
				Volume = 0
			}):Play()
			
			local shopType = "shop"
			local TreeTransition = script.Parent.TreeTransition
			
			if renderSteppedConnection then
				renderSteppedConnection:Disconnect()
				renderSteppedConnection = nil
			end
			
			toggleScripts(Menu2, false, 2, 3)
			Functions.changeLighting(Lightings.Shop)
			game.Players.LocalPlayer:AddTag("Shop")
			
			local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			TreeTransition.Visible = true
			
			TweenService:Create(workspace.Lobby.LobbyMus, TweenInfo.new(1), {
				Volume = 0
			}):Play()
			
			repeat
				CurrentCamera.CameraType = Enum.CameraType.Scriptable
			until CurrentCamera.CameraType == Enum.CameraType.Scriptable
			
			MenuSounds["Synth Whooshes Airy Pass Bys Slightly Phasey (SFX)"]:Play()
			MenuSounds["Foliage Rustle 2 (SFX)"].Volume = 8
			MenuSounds["Foliage Rustle 2 (SFX)"]:Play()
			
			TweenService:Create(MenuSounds["Foliage Rustle 2 (SFX)"], TweenInfo.new(2.5), {
				Volume = 0
			}):Play()
			
			task.wait(0.3)
			
			game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.Default
			workspace.CurrentCamera.FieldOfView = 70
			TreeTransition.Visible = false
			
			script.Parent.swipeTrans.Visible = true
			script.Parent.swipeTrans.Position = UDim2.new(0.5, 0, 0.5, 0)
			
			TweenService:Create(script.Parent.swipeTrans, tweenInfo, {
				Position = UDim2.new(2, 0, 0.5, 0)
			}):Play()
			
			script.Parent.Lobby.Visible = false
			MenuContainer.Menu2.Visible = false
			
			local ShopAssets = workspace.ShopAssets
			local InventoryAssets = workspace.InventoryAssets
			local Camera = ShopAssets.Camera
			local isInShop = false
			local Shopkeeper = ShopAssets.Shopkeeper
			local idleAnim = Shopkeeper.Humanoid.Animator:LoadAnimation(Shopkeeper.Idle)
			local shopConnection = nil
			local ShopMus = ReplicatedStorage.ClientAssets.Sounds.mus.Menu.ShopMus
			local musicTitle = nil
			
			CurrentCamera.CFrame = Camera:WaitForChild("Shopcam3").CFrame
			TweenService:Create(CurrentCamera, tweenInfo, {
				CFrame = Camera.Shopcam1.CFrame
			}):Play()
			
			local shopLoop = nil
			optionFunc = task.spawn(function()
				local playedSongs = {}
				local isSwitching = false
				
				ShopAssets.Radio.ClickDetector.MouseClick:Connect(function()
					if isSwitching ~= false or not shopLoop then
						return
					end
					
					isSwitching = true
					shopLoop:Stop()
					task.wait(4)
					isSwitching = false
				end)
				
				for _, sound in pairs(ShopMus:GetChildren()) do
					local index
					while true do
						if not task.wait() then
							continue
						end
						index = math.random(1, #ShopMus:GetChildren())
						if not playedSongs[index] then
							break
						end
					end
					playedSongs[index] = true
					sound.Name = "Mus" .. index
				end
				
				while task.wait() do
					for i = 1, #ShopMus:GetChildren() do
						script.Parent.Change:Play()
						script.Parent.Change.Ended:Wait()
						
						shopLoop = ShopMus["Mus" .. i]
						shopLoop:GetAttribute("Loops")
						
						if musicTitle and musicTitle:FindFirstChild("MusTitle") then
							musicTitle.MusTitle.Text = "Now Playing -   " .. shopLoop:GetAttribute("Title")
						end
						
						local loopCount = 0
						shopLoop.Volume = 2
						shopLoop:Play()
						
						local loopConnection = shopLoop.DidLoop:Connect(function()
							loopCount = loopCount + 1
							if not (loopCount >= 2) then
								return
							end
							shopLoop:Stop()
						end)
						
						repeat
							task.wait()
						until not shopLoop.IsPlaying
						
						loopConnection:Disconnect()
					end
				end
			end)
			
			idleAnim:Play()
			
			local isShopVisible = true
			task.spawn(function()
				while task.wait() and isShopVisible do
					if script.Parent.Enabled or not isShopVisible then
						continue
					end
					
					print("hey i'm still in shop but im invisible")
					game.Players.LocalPlayer:AddTag("Shop")
					script.Parent.Enabled = true
				end
				print("shop over")
			end)
			
			local function loadShop()
				local shortTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				musicTitle = MenuContainer.shopTemp:Clone()
				print("loaded")
				game.Players.LocalPlayer:AddTag("Shop")
				
				TweenService:Create(game.ReplicatedStorage.ClientAssets.Sounds.mus.Menu.ShopMus, TweenInfo.new(0.5), {
					Volume = 0.5
				}):Play()
				
				musicTitle.Name = "shop"
				print(musicTitle:GetFullName())
				
				if shopLoop then
					musicTitle.MusTitle.Text = "Now Playing -   " .. shopLoop:GetAttribute("Title")
				end
				
				musicTitle.Parent = script.Parent
				musicTitle.display.Position = UDim2.new(1.5, 0, 1, 0)
				musicTitle.selection.Position = UDim2.new(1.5, 0, 0, 0)
				musicTitle.returnborder.Position = UDim2.new(-1, 0, 1, 0)
				musicTitle.top.Position = UDim2.new(0.315, 0, -0.162, 0)
				musicTitle.bottom.Position = UDim2.new(0, 0, 1.1, 0)
				musicTitle.MusTitle.Position = UDim2.new(-0.439, 0, 0.099, 0)
				
				repeat
					task.wait()
					if musicTitle.Visible then
						continue
					end
					musicTitle.Visible = true
				until musicTitle.Visible
				
				musicTitle.Visible = true
				print("shop visiblity:", musicTitle.Visible)
				musicTitle.ShopHandler.Enabled = true
				
				TweenService:Create(musicTitle.selection, shortTweenInfo, {
					Position = UDim2.new(1, 0, 0, 0)
				}):Play()
				
				task.wait(0.1)
				
				TweenService:Create(musicTitle.display, shortTweenInfo, {
					Position = UDim2.new(1, 0, 1, 0)
				}):Play()
				
				TweenService:Create(musicTitle.returnborder, shortTweenInfo, {
					Position = UDim2.new(-0.039, 0, 1, 0)
				}):Play()
				
				task.wait(0.2)
				
				TweenService:Create(musicTitle.top, shortTweenInfo, {
					Position = UDim2.new(0.336, 0, 0.162, 0)
				}):Play()
				
				TweenService:Create(musicTitle.bottom, shortTweenInfo, {
					Position = UDim2.new(0, 0, 0.905, 0)
				}):Play()
				
				TweenService:Create(musicTitle.MusTitle, shortTweenInfo, {
					Position = UDim2.new(0.153, 0, 0.137, 0)
				}):Play()
				
				task.wait(0.5)
				musicTitle.movething.Enabled = true
				
				local inventoryConnection = nil
				inventoryConnection = musicTitle.top.Inventory.InventoryButton.Activated:Connect(function()
					if isInShop ~= "shop" or isProcessing ~= false then
						return
					end
					
					isInShop = "inventory"
					
					if shopConnection then
						shopConnection:Disconnect()
						shopConnection = nil
					end
					
					inventoryConnection:Disconnect()
					inventoryConnection = nil
					isProcessing = true
					
					for _, child in pairs(InventoryAssets.char:GetChildren()) do
						child:Destroy()
					end
					
					local Inventory = MenuContainer.invenTemp:Clone()
					
					TweenService:Create(game.ReplicatedStorage.ClientAssets.Sounds.mus.Menu.ShopMus, TweenInfo.new(0.5), {
						Volume = 0.5
					}):Play()
					
					Inventory.Name = "Inventory"
					Inventory.Parent = script.Parent
					Inventory.bottom.Position = UDim2.new(0.5, 0, 1.2, 0)
					Inventory.top.Position = UDim2.new(0.5, 0, -0.2, 0)
					Inventory.CosmeticDisplay.Position = UDim2.new(-0.5, 0, 0.067, 0)
					Inventory.TextLabel.Position = UDim2.new(1.1, 0, 0.179, 0)
					Inventory.selectedCosm.Position = UDim2.new(1.1, 0, 0.201, 0)
					
					for _, opt in pairs(Inventory.CosmeticDisplay.optSelect:GetChildren()) do
						opt.Size = UDim2.new(0.1, 0, 0.228, 0)
					end
					
					Inventory.Visible = true
					musicTitle.ShopHandler.Enabled = false
					musicTitle.movething.Enabled = false
					
					script.Parent.swipeTrans.Visible = true
					script.Parent.swipeTrans.Position = UDim2.new(-1.1, 0, 0.5, 0)
					
					TweenService:Create(script.Parent.swipeTrans, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
						Position = UDim2.new(0.5, 0, 0.5, 0)
					}):Play()
					
					TweenService:Create(CurrentCamera, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
						CFrame = ShopAssets.Camera.Shopcam2.CFrame
					}):Play()
					
					task.wait(0.5)
					Functions.changeLighting(Lightings.Inventory)
					CurrentCamera.CFrame = InventoryAssets.camStart.CFrame
					
					TweenService:Create(CurrentCamera, shortTweenInfo, {
						CFrame = InventoryAssets.cam.CFrame
					}):Play()
					
					TweenService:Create(script.Parent.swipeTrans, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						Position = UDim2.new(2, 0, 0.5, 0)
					}):Play()
					
					musicTitle:Destroy()
					
					TweenService:Create(Inventory.bottom, shortTweenInfo, {
						Position = UDim2.new(0.5, 0, 1, 0)
					}):Play()
					
					TweenService:Create(Inventory.top, shortTweenInfo, {
						Position = UDim2.new(0.5, 0, 0, 0)
					}):Play()
					
					task.wait(0.15)
					
					TweenService:Create(Inventory.CosmeticDisplay, tweenInfo, {
						Position = UDim2.new(-0.009, 0, 0.067, 0)
					}):Play()
					
					TweenService:Create(Inventory.TextLabel, shortTweenInfo, {
						Position = UDim2.new(0.942, 0, 0.179, 0)
					}):Play()
					
					task.wait(0.05)
					
					TweenService:Create(Inventory.selectedCosm, shortTweenInfo, {
						Position = UDim2.new(0.941, 0, 0.201, 0)
					}):Play()
					
					Inventory.InvenHandler.Enabled = true
					task.wait(0.5)
					
					Inventory.bottom["return"].Activated:Connect(function()
						if isProcessing ~= false then
							return
						end
						
						isProcessing = true
						
						TweenService:Create(CurrentCamera, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
							CFrame = InventoryAssets.camStart.CFrame
						}):Play()
						
						TweenService:Create(script.Parent.swipeTrans, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
							Position = UDim2.new(0.5, 0, 0.5, 0)
						}):Play()
						
						task.wait(0.5)
						Functions.changeLighting(Lightings.Shop)
						CurrentCamera.CFrame = ShopAssets.Camera.Shopcam2.CFrame
						
						TweenService:Create(CurrentCamera, shortTweenInfo, {
							CFrame = ShopAssets.Camera.Shopcam1.CFrame
						}):Play()
						
						TweenService:Create(script.Parent.swipeTrans, shortTweenInfo, {
							Position = UDim2.new(-1, 0, 0.5, 0)
						}):Play()
						
						Inventory:Destroy()
						isInShop = "shop"
						
						task.delay(0.5, function()
							script.Parent.swipeTrans.Position = UDim2.new(2, 0, 0.5, 0)
						end)
						
						loadShop()
					end)
					
					isProcessing = false
					task.wait(1)
					Inventory.movething.Enabled = true
				end)
				
				shopConnection = musicTitle.returnborder.Activated:Connect(function()
					if isProcessing ~= false or isInShop ~= "shop" then
						return
					end
					
					isProcessing = true
					isShopVisible = false
					shopConnection:Disconnect()
					
					pcall(function()
						coroutine.close(optionFunc)
						warn("groge")
					end)
					optionFunc = nil
					shopConnection = nil
					musicTitle.confirm.Value = true
					
					task.wait(1)
					
					local closeTweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
					
					repeat
						task.wait()
						if musicTitle.Visible then
							continue
						end
						musicTitle.Visible = true
					until musicTitle.Visible
					
					musicTitle.Visible = true
					musicTitle.movething.Enabled = false
					musicTitle.gallerytrans.Position = UDim2.new(2, 0, 0, 0)
					musicTitle.gallerytrans.Visible = true
					
					TweenService:Create(musicTitle.gallerytrans, closeTweenInfo, {
						Position = UDim2.new(0, 0, 0, 0)
					}):Play()
					
					TweenService:Create(CurrentCamera, closeTweenInfo, {
						CFrame = Camera.Shopcam3.CFrame
					}):Play()
					
					for _, sound in pairs(game.ReplicatedStorage.ClientAssets.Sounds.mus.Menu.ShopMus:GetChildren()) do
						if sound.IsPlaying then
							local volume = sound.Volume
							TweenService:Create(sound, TweenInfo.new(0.7), {
								Volume = 0
							}):Play()
							
							task.delay(0.7, function()
								sound:Stop()
								sound.Volume = volume
							end)
						end
					end
					
					task.wait(0.7)
					
					script.Parent.swipeTrans.Visible = true
					script.Parent.swipeTrans.Position = UDim2.new(0.5, 0, 0.5, 0)
					
					TweenService:Create(script.Parent.swipeTrans, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
						Position = UDim2.new(-1, 0, 0.5, 0)
					}):Play()
					
					musicTitle.ShopHandler.Enabled = false
					MenuContainer.Menu2.Visible = true
					
					for _, part in pairs(menuParts) do
						part.Position = originalPositions[part.Name]
					end
					
					CurrentCamera.CFrame = workspace.Lobby.Cams:GetChildren()[math.random(1, #workspace.Lobby.Cams:GetChildren())].CFrame
					
					local startTime = tick()
					renderSteppedConnection = game:GetService("RunService").RenderStepped:Connect(function()
						local currentTime = tick()
						workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(
							workspace.CurrentCamera.CFrame * CFrame.Angles(
								math.sin(currentTime - startTime * 1.5) / 10 / 10,
								math.sin(currentTime - startTime * 3) / 15 / 10,
								0
							),
							0.1
						)
					end)
					
					toggleScripts(Menu2, true, 2, 3)
					Functions.changeLighting(Lightings.Lobby)
					isProcessing = false
					musicTitle.Visible = false
					musicTitle:Destroy()
					
					TweenService:Create(Menu.MenuLoop, TweenInfo.new(1), {
						Volume = 1
					}):Play()
					
					game.Players.LocalPlayer:RemoveTag("Shop")
					rotationY = 0
					task.wait(0.7)
					script.Parent.swipeTrans.Visible = false
				end)
				
				isProcessing = false
			end
			
			loadShop()
		end,
		
		Gallery = function()
			TweenService:Create(Menu2.thecoolBottom2.Gallery, TweenInfo.new(0.5), {
				Position = UDim2.new(Menu2.thecoolBottom2.Gallery.Position.X.Scale, 0, Menu2.thecoolBottom2.Gallery.Position.Y.Scale, 0)
			}):Play()
			
			MenuSounds.MenuAccept:Play()
			task.wait(0.5)
			rotationY = 0
		end,
		
		Settings = function()
			TweenService:Create(Menu2.thecoolBottom2.Settings, TweenInfo.new(0.5), {
				Position = UDim2.new(Menu2.thecoolBottom2.Settings.Position.X.Scale, 0, Menu2.thecoolBottom2.Settings.Position.Y.Scale, 0)
			}):Play()
			
			MenuSounds.MenuAccept:Play()
			
			if game.Players.LocalPlayer.Character:GetAttribute("Character") and game.Players.LocalPlayer.Character:FindFirstAncestorOfClass("Workspace") then
				return
			end
			
			isMenuOpen = not isMenuOpen
			
			if isMenuOpen then
				script.gear_shift:Play()
				Settings.SETUI.Position = UDim2.new(-1, 0, 0.078, 0)
				
				TweenService:Create(Settings.SETUI, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Position = UDim2.new(-0, 0, 0.078, 0)
				}):Play()
				
				Settings.Visible = true
				task.wait(0.6)
			else
				isLoading = false
				script.off:Play()
				
				TweenService:Create(Settings.SETUI, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Position = UDim2.new(-1, 0, 0.078, 0)
				}):Play()
				
				Settings.ABBinds.Visible = isLoading
				task.wait(1)
				Settings.Visible = false
			end
		end
	}
}

menuHandler = openMenu2.OptionFunc

local hasPlayedTheme = false
workspace.Assets.Songs.ChildAdded:Connect(function(sound)
	if not sound:IsA("Sound") or (sound.Name ~= "Theme80s" or hasPlayedTheme) then
		return
	end
	
	hasPlayedTheme = true
	local volumes = {}
	
	for _, child in pairs(Menu:GetDescendants()) do
		if child:IsA("Sound") then
			volumes[child.Name] = child.Volume
			child.Volume = 0
		end
	end
	
	sound.Destroying:Once(function()
		for _, child in pairs(Menu:GetDescendants()) do
			if child:IsA("Sound") then
				child.Volume = volumes[child.Name]
			end
		end
	end)
end)

game:GetService("CollectionService"):GetInstanceAddedSignal("OnRESULT"):Connect(function(player)
	if player ~= LocalPlayer or selectedButton ~= 2 then
		return
	end
	
	openMenu2.ForceClose()
	warn("force close")
end)

local TimerText = script.Parent.Lobby.TimerText

local function updateStateText()
	local stateText = nil
	
	if GameProperties.State.Value == "INT" then
		stateText = "INTERMISSION"
	elseif GameProperties.State.Value == "SEC" then
		stateText = "SELECTION"
	elseif GameProperties.State.Value == "ING" then
		stateText = "ROUND"
	end
	
	if stateText then
		TimerText.Text = "< " .. stateText .. " >"
	end
	
	Menu2.TopBar.TimerText1.Text = TimerText.Text
	Menu2.TopBar.TimerText2.Text = TimerText.Text
end

local initialState = nil
if GameProperties.State.Value == "INT" then
	initialState = "INTERMISSION"
elseif GameProperties.State.Value == "SEC" then
	initialState = "SELECTION"
elseif GameProperties.State.Value == "ING" then
	initialState = "ROUND"
end

if initialState then
	TimerText.Text = "< " .. initialState .. " >"
end

Menu2.TopBar.TimerText1.Text = TimerText.Text
Menu2.TopBar.TimerText2.Text = TimerText.Text
GameProperties.State.Changed:Connect(updateStateText)

task.spawn(function()
	while task.wait() do
		local count = 0
		
		for _, player in game.Players:GetPlayers() do
			if not (player:HasTag("Menu") or player:HasTag("AFK")) then
				count = count + 1
			end
		end
		
		if GameProperties.State.Value == "INT" then
			Lobby.Timer.Visible = count >= 2
			Lobby.NeedPlayer.Visible = count < 2
		else
			Lobby.Timer.Visible = true
			Lobby.NeedPlayer.Visible = false
		end
		
		Lobby.Timer.Text = string.format("%d", workspace.GameProperties.Time.Value)
		Menu2.TopBar.Timer.Text = Lobby.Timer.Text
		Menu2.TopBar.Timer.Visible = Lobby.Timer.Visible
		Menu2.TopBar.NeedPlayer.Visible = Lobby.NeedPlayer.Visible
	end
end)

LocalPlayer:HasTag("Menu")

local selectedState = 3
Menu.MenuLoop:Pause()
Menu.MenuLoop.Volume = 1
warn("player in building")

task.delay(4, function()
	script.RemoteEvent:FireServer("Menu")
end)

if workspace.GameProperties.State.Value == "INT" and not workspace.Lobby:WaitForChild("LobbyMus").IsPlaying then
	workspace.Lobby.LobbyMus:Play()
	workspace.Lobby.LobbyMus.Volume = 0.7
	Functions.changeLighting(Lightings.Lobby)
end

local function updateInfo(characterName, playerName)
	script.MenuBleep:Play()
	
	for _, connection in pairs(buttonFunctions) do
		connection:Disconnect()
	end
	
	local alias
	if ReplicatedStorage.ClientAssets.Characters:FindFirstChild(characterName, true) then
		print(characterName)
		alias = ReplicatedStorage.ClientAssets.Characters:FindFirstChild(characterName, true):GetAttribute("Alias")
	else
		alias = nil
	end
	
	SelectScreen.Select.char.Text = alias or characterName
	
	if game.ReplicatedStorage.Taken:FindFirstChild(characterName) then
		SelectScreen.Select.user.Visible = true
		SelectScreen.Select.char.TextTransparency = 0.5
		SelectScreen.Select.user.Text = game.ReplicatedStorage.Taken[characterName]:GetAttribute("Player")
	else
		SelectScreen.Select.char.TextTransparency = 0
		SelectScreen.Select.user.Visible = false
		
		buttonFunctions.taken = game.ReplicatedStorage.Taken.ChildAdded:Connect(function(takenCharacter)
			if takenCharacter.Name ~= characterName then
				return
			end
			
			SelectScreen.Select.user.Visible = true
			SelectScreen.Select.user.Text = game.ReplicatedStorage.Taken[characterName]:GetAttribute("Player")
			SelectScreen.Select.char.TextTransparency = 0.5
			buttonFunctions.ready:Disconnect()
		end)
		
		buttonFunctions.ready = SelectScreen.info.ready.Activated:Connect(function()
			if game.ReplicatedStorage.Taken:FindFirstChild(characterName) and (not isSelecting and workspace.GameProperties.CharacterLOCK.Value) then
				script.SwapFail:Play()
			end
			
			if (isSelecting ~= false or game.ReplicatedStorage.Taken:FindFirstChild(characterName)) and workspace.GameProperties.CharacterLOCK.Value then
				return
			end
			
			isSelecting = true
			script.MenuAccept:Play()
			warn("SELECTED")
			selectedCharacter = characterName
			Remotes.Voted:FireServer(characterName)
			charSelectConnections:Disconnect()
			charSelectConnections = nil
			currentOptionFunc:Disconnect()
			task.wait(0.3)
			isSelecting = false
		end)
	end
end

local mapLoop = nil
local mapLoopConnection = nil

Remotes.ClientUI.OnClientEvent:Connect(function(data)
	local action = data[1]
	
	if action == "CharSelect" and not isCharSelectOpen then
		if selectedState ~= 3 then
			openMenu2.ForceClose()
			isProcessing = true
			task.wait(1)
		end
		
		repeat
			task.wait()
		until workspace.SelectMap:FindFirstChild(data[4])
		
		local map = workspace.SelectMap:FindFirstChild(data[4])
		local characters = data[5]
		
		game.Players.LocalPlayer.Character:FindFirstChild("Humanoid").WalkSpeed = 0
		isCharSelectOpen = true
		CharSelect.Visible = true
		CharSelect.Transition.Visible = true
		
		TweenService:Create(workspace.Lobby.LobbyMus, TweenInfo.new(1), {
			Volume = 0
		}):Play()
		
		TweenService:Create(CharSelect.Transition.ImageLabel, TweenInfo.new(1), {
			BackgroundTransparency = 0
		}):Play()
		
		TweenService:Create(CharSelect.Transition.ImageLabel.UIScale, TweenInfo.new(1), {
			Scale = 0.25
		}):Play()
		
		task.wait(1)
		isProcessing = false
		
		CharSelect.Select.Visible = true
		CharSelect.Select.UIScale.Scale = 3.5
		CharSelect.Select.Map.Text = data[4]
		CharSelect.Select.Map.Position = UDim2.new(0.5, 0, -0.055, 0)
		CharSelect.BackgroundTransparency = 0
		script.Parent.Lobby.Visible = false
		workspace.Lobby.LobbyMus:Stop()
		workspace.Lobby.LobbyMus.Volume = 0.3
		
		if game.Players.LocalPlayer.Character:FindFirstChild("cam") then
			game.Players.LocalPlayer.Character:FindFirstChild("cam"):SetAttribute("stop", true)
		end
		
		workspace.CurrentCamera.CFrame = map:WaitForChild("CamPos").CFrame
		
		local startTime = tick()
		mapLoopConnection = game:GetService("RunService").RenderStepped:Connect(function()
			local currentTime = tick()
			workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(
				workspace.CurrentCamera.CFrame * CFrame.Angles(
					math.sin(currentTime - startTime * 1.5) / 10 / 10,
					math.sin(currentTime - startTime * 3) / 15 / 10,
					0
				),
				0.1
			)
		end)
		
		task.wait(1)
		CharSelect.Transition.Visible = false
		
		TweenService:Create(CharSelect.Select.Map, TweenInfo.new(1), {
			Position = UDim2.new(0.5, 0, 0.075, 0)
		}):Play()
		
		if game.ReplicatedStorage.ClientAssets.Sounds.mus.Game.Selections:FindFirstChild(data[4]) then
			game.ReplicatedStorage.ClientAssets.Sounds.mus.Game.Selections[data[4]]:Play()
		else
			game.ReplicatedStorage.ClientAssets.Sounds.mus.Game.Selections.TestMap:Play()
		end
		
		mapLoop = workspace.GameProperties.Time.Changed:Connect(function()
			CharSelect.Select.time.Text = "- <" .. workspace.GameProperties.Time.Value .. "> -"
		end)
		
		charSelectConnections = game.ReplicatedStorage.Taken.ChildAdded:Connect(function(takenCharacter)
			local teamFolder = if takenCharacter:GetAttribute("Team") == "Survivor" then "survivorsd" else "exesd"
			print(takenCharacter:GetAttribute("Team"))
			print(teamFolder)
			
			local clone = CharSelect.Select[teamFolder].selected:Clone()
			clone.Parent = CharSelect.Select[teamFolder]
			clone.Visible = true
			clone.char.Text = if takenCharacter:GetAttribute("Alias") then takenCharacter:GetAttribute("Alias") else takenCharacter.Name
			clone.user.Text = takenCharacter:GetAttribute("Player")
			
			if CharSelect.Select[teamFolder].joe1.Visible then
				return
			end
			
			CharSelect.Select[teamFolder].joe1.Visible = true
			CharSelect.Select[teamFolder].joe2.Visible = true
		end)
		
		task.wait(1.5)
		
		if data[3] then
			CharSelect.Select.MODELINE.Visible = true
			CharSelect.Select.Mode.TextTransparency = 1
			CharSelect.Select.Mode.Visible = true
			CharSelect.Select.Mode.Text = data[3][1]
			CharSelect.Select.Mode.TextColor3 = data[3][2] or Color3.fromRGB(255, 217, 0)
			
			TweenService:Create(CharSelect.Select.Map, TweenInfo.new(1), {
				Position = UDim2.new(0.5, 0, 0.048, 0)
			}):Play()
			
			task.wait(0.3)
			
			TweenService:Create(CharSelect.Select.MODELINE.UIScale, TweenInfo.new(1), {
				Scale = 1
			}):Play()
			
			task.wait(0.5)
			
			TweenService:Create(CharSelect.Select.Mode, TweenInfo.new(1), {
				TextTransparency = 0
			}):Play()
			
			task.wait(1)
		end
		
		TweenService:Create(CharSelect.Select.UIScale, TweenInfo.new(2), {
			Scale = 1
		}):Play()
		
		TweenService:Create(CharSelect, TweenInfo.new(1), {
			BackgroundTransparency = 1
		}):Play()
		
		local team = data[2]
		local characterList = data[3]
		print(data[3])
		
		local currentIndex = 1
		local isNavigating = false
		
		if data[2] == "EXE" then
			SelectScreen.Select.char.TextColor3 = Color3.new(255/255, 0/255, 0/255)
			SelectScreen.Select.user.TextColor3 = Color3.new(255/255, 0/255, 0/255)
		end
		
		CharSelect.Select.SelectScreen.Visible = true
		updateInfo(characterList[currentIndex])
		warn(characterList)
		
		charSelectConnections = SelectScreen.Select.next.Activated:Connect(function()
			if isNavigating ~= false then
				return
			end
			
			isNavigating = true
			currentIndex = currentIndex + 1
			
			if #characterList < currentIndex then
				currentIndex = 1
			end
			
			print(characterList[currentIndex])
			updateInfo(characterList[currentIndex])
			task.wait(0.3)
			isNavigating = false
		end)
		
		currentOptionFunc = SelectScreen.Select.prev.Activated:Connect(function()
			if isNavigating ~= false then
				return
			end
			
			isNavigating = true
			currentIndex = currentIndex - 1
			
			if currentIndex < 1 then
				currentIndex = #characterList
			end
			
			print(characterList[currentIndex])
			updateInfo(characterList[currentIndex])
			task.wait(0.3)
			isNavigating = false
		end)
		
		buttonFunctions = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed or isNavigating then
				return
			end
			
			if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.DPadLeft then
				isNavigating = true
				currentIndex = currentIndex + 1
				
				if #characterList < currentIndex then
					currentIndex = 1
				end
				
				print(characterList[currentIndex])
				updateInfo(characterList[currentIndex])
				task.wait(0.3)
				isNavigating = false
			elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.DPadRight then
				isNavigating = true
				currentIndex = currentIndex - 1
				
				if currentIndex < 1 then
					currentIndex = #characterList
				end
				
				print(characterList[currentIndex])
				updateInfo(characterList[currentIndex])
				task.wait(0.3)
				isNavigating = false
			else
				if input.KeyCode ~= Enum.KeyCode.Space and input.KeyCode ~= Enum.KeyCode.ButtonB then
					return
				end
				
				local selectedChar = characterList[currentIndex]
				
				if game.ReplicatedStorage.Taken:FindFirstChild(selectedChar) and (not isSelecting and workspace.GameProperties.CharacterLOCK.Value) then
					script.SwapFail:Play()
				end
				
				if (isSelecting ~= false or game.ReplicatedStorage.Taken:FindFirstChild(selectedChar)) and workspace.GameProperties.CharacterLOCK.Value then
					return
				end
				
				isSelecting = true
				script.MenuAccept:Play()
				warn("SELECTED")
				selectedCharacter = selectedChar
				Remotes.Voted:FireServer(selectedChar)
				charSelectConnections:Disconnect()
				currentOptionFunc:Disconnect()
				buttonFunctions:Disconnect()
				task.wait(0.3)
				isSelecting = false
			end
		end)
		
	elseif action == "TitleCard" and isCharSelectOpen then
		isCharSelectOpen = false
		
		local survivors = {}
		for _, taken in pairs(game.ReplicatedStorage.Taken:GetChildren()) do
			if taken:GetAttribute("Team") == "Survivor" then
				table.insert(survivors, taken)
			end
		end
		
		for _, sound in pairs(game.ReplicatedStorage.ClientAssets.Sounds.mus.Game.Selections:GetChildren()) do
			if sound:IsA("Sound") then
				sound:Stop()
			end
		end
		
		if charSelectConnections then
			charSelectConnections:Disconnect()
		end
		
		if mapLoopConnection then
			mapLoopConnection:Disconnect()
		end
		
		if mapLoop then
			mapLoop:Disconnect()
		end
		
		local TitleCard = script.Parent.Parent.TitleCard
		
		for _, survivor in pairs(survivors) do
			if TitleCard.Survivors:FindFirstChild(survivor.Name) then
				TitleCard.Survivors:FindFirstChild(survivor.Name).Visible = true
			end
		end
		
		TitleCard.bg.Visible = true
		TitleCard.BottomBart.Position = UDim2.new(0, 0, 0.1, 0)
		TitleCard.BottomCornerBart.Position = UDim2.new(2, 0, 1.3, 0)
		TitleCard.BottomCornerBart.TheImage.Position = UDim2.new(1, 0, 0, 0)
		TitleCard.Survivors.Position = UDim2.new(0, 0, 1, 0)
		TitleCard.TopCornerBart.Position = UDim2.new(1.703, 0, -0.533, 0)
		TitleCard.TopBart.Position = UDim2.new(0, 0, -0.511, 0)
		TitleCard.preview.ImageTransparency = 1
		TitleCard.bg.BackgroundTransparency = 0
		TitleCard.Vignette.UIScale.Scale = 5
		TitleCard.Enabled = true		
		TweenService:Create(CharSelect, TweenInfo.new(0.5), {
			BackgroundTransparency = 0
		}):Play()
		
		TitleCard.LocalScript.Enabled = true
		
	elseif action == "loadmap" then
		local mapName = data[2]
		
		local function countItems(table)
			local count = 0
			for _ in pairs(table) do
				count = count + 1
			end
			return count
		end
		
		local loadedMap = if game.ReplicatedStorage.ClientAssets.Select_MAP:FindFirstChild(mapName) then game.ReplicatedStorage.ClientAssets.Select_MAP[mapName]:Clone() else game.ReplicatedStorage.ClientAssets.Select_MAP.TestMAP:Clone()
		loadedMap.Parent = workspace.SelectMap
		loadedMap.Name = mapName
		loadedMap:AddTag("MAP")
		
		if loadedMap:FindFirstChild("Loops") then
			local loopParts = loadedMap.Loops:GetChildren()
			local originalPositions = {}
			
			for _, part in loopParts do
				if part:IsA("Model") then
					originalPositions[part] = part:GetPivot()
				end
			end
			
			local loopLength = tonumber(loadedMap.Loops:GetAttribute("Length")) or 5
			local loopTime = 0
			local speed = loadedMap.Loops:GetAttribute("SPD") or 1
			
			menuButtonStates.Loops = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
				if workspace.GameProperties.State.Value ~= "SEC" then
					menuButtonStates.Loops:Disconnect()
					return
				end
				
				loopTime = if loopLength / 2 <= loopTime then 0 else loopTime + deltaTime * speed
				
				for _, part in loopParts do
					if part:IsA("Model") then
						local offsetX = loopTime * loadedMap.Loops:GetAttribute("DIRECTIONS").X
						local offsetY = loopTime * loadedMap.Loops:GetAttribute("DIRECTIONS").Y
						part:PivotTo(originalPositions[part] * CFrame.new(offsetX, offsetY, loopTime * loadedMap.Loops:GetAttribute("DIRECTIONS").Z))
					end
				end
			end)
		end
		
		local characterPositions = {}
		local magnitude = (loadedMap.SurvivorPos.Position - loadedMap.SurvivorPos2.Position).Magnitude
		
		menuButtonStates.CharacterLeft = game:GetService("ReplicatedStorage").Taken.ChildRemoved:Connect(function(takenCharacter)
			local playerName = takenCharacter:GetAttribute("Player")
			if not characterPositions[playerName] then
				return
			end
			
			game:GetService("Debris"):AddItem(characterPositions[playerName][2], 0.5)
			characterPositions[playerName] = nil
		end)
		
		menuButtonStates.CharacterMovement = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
			local count = 0
			for _ in pairs(characterPositions) do
				count = count + 1
			end
			
			local totalOffset = 0
			for _, data in pairs(characterPositions) do
				totalOffset = totalOffset + data[3]
				if data[1] < count then
					totalOffset = totalOffset + 0.25
				end
			end
			
			for playerName, data in pairs(characterPositions) do
				local order = data[1]
				local character = data[2]
				local width = data[3]
				local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
				local height = character:GetExtentsSize().Y / 2
				
				local sumOffset = 0
				for _, otherData in pairs(characterPositions) do
					if otherData[1] < order then
						sumOffset = sumOffset + (otherData[3] + 0.25)
					end
				end
				
				humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(
					loadedMap.SurvivorPos2.CFrame * CFrame.new(-totalOffset / 2 + sumOffset + width / 2, height, 0),
					deltaTime
				)
			end
		end)
		
		menuButtonStates.CharacterSelect = game:GetService("ReplicatedStorage").Taken.ChildAdded:Connect(function(takenCharacter)
			if takenCharacter:GetAttribute("Team") == "Survivor" then
				local characterName = takenCharacter.Name
				local playerName = takenCharacter:GetAttribute("Player")
				
				if selectedCharacter == characterName and (playerName ~= game.Players.LocalPlayer.Name and workspace.GameProperties.CharacterLOCK.Value) then
					isSelecting = false
				end
				
				local characterModel = game.ReplicatedStorage.ClientAssets.Characters.Survivors[characterName].Skins.Default:Clone()
				characterModel.Parent = loadedMap
				
				local rootPart = characterModel:WaitForChild("Humanoid").RootPart
				rootPart.Anchored = true
				
				for _, part in characterModel:GetDescendants() do
					if part:IsA("BasePart") then
						part.LocalTransparencyModifier = 1
						TweenService:Create(part, TweenInfo.new(1), {
							LocalTransparencyModifier = 0
						}):Play()
					end
				end
				
				if not characterPositions[playerName] then
					local count = 0
					for _ in pairs(characterPositions) do
						count = count + 1
					end
					
					local newData = {}
					newData[1] = count + 1
					newData[2] = characterModel
					newData[3] = characterModel:GetExtentsSize().X / 2
					characterPositions[playerName] = newData
				end
				
				rootPart.CFrame = loadedMap.SurvivorPos.CFrame * CFrame.new(0, characterModel:GetExtentsSize().Y / 2 - 0.1, 0)
				
				local runAnim = characterModel.Humanoid.Animator:LoadAnimation(
					game.ReplicatedStorage.ClientAssets.Characters.Survivors[characterName].scriptstuff.Animate.Anims.Default.Run
				)
				runAnim:Play()
				runAnim:AdjustSpeed(1.25)
			else
				local exeSkin = game.ReplicatedStorage.ClientAssets.Characters.EXE[takenCharacter.Name].Skins[takenCharacter:GetAttribute("Skin")]
				local exeModel = exeSkin:Clone()
				
				if exeModel.PrimaryPart.Name ~= "HumanoidRootPart" and exeModel:FindFirstChild("HumanoidRootPart") then
					exeModel.PrimaryPart = exeModel:FindFirstChild("HumanoidRootPart")
				end
				
				exeModel.Parent = loadedMap
				exeModel:PivotTo(loadedMap.EXEPos.CFrame * CFrame.new(0, 0, 5))
				
				TweenService:Create(exeModel.PrimaryPart, TweenInfo.new(0.5), {
					CFrame = loadedMap.EXEPos.CFrame
				}):Play()
				
				exeModel.PrimaryPart.Anchored = true
				
				if not exeSkin.Parent.Parent:FindFirstChild("CustomAnimation") then
					local customAnim = Instance.new("Folder")
					customAnim.Parent = exeSkin.Parent.Parent
					customAnim.Name = "CustomAnimation"
				end
				
				local selectPose = nil
				if exeSkin.Parent.Parent.CustomAnimation:FindFirstChild(takenCharacter:GetAttribute("Skin")) and 
				   exeSkin.Parent.Parent.CustomAnimation[takenCharacter:GetAttribute("Skin")]:FindFirstChild("SelectPose") then
					selectPose = exeSkin.Parent.Parent.CustomAnimation[takenCharacter:GetAttribute("Skin")].SelectPose
				else
					selectPose = exeSkin.Parent.Parent.scriptstuff.Animate.Anims:FindFirstChild("SelectPose")
				end
				
				if not selectPose then
					return
				end
				
				exeModel.Humanoid.Animator:LoadAnimation(selectPose):Play()
			end
		end)
		
	elseif action == "clearmap" then
		for _, connection in pairs(menuButtonStates) do
			connection:Disconnect()
		end
		
		for _, child in workspace.SelectMap:GetChildren() do
			if child:HasTag("MAP") then
				child:Destroy()
			end
		end
	end
end)

for _, sound in pairs(game.ReplicatedStorage.ClientAssets.Sounds.mus.Menu.ShopMus:GetChildren()) do
	sound:Stop()
end

local function lockAnimation(button, text)
	local lockIcon = script.Locked:Clone()
	lockIcon.Parent = button
	lockIcon.Visible = true
	lockIcon.Rotation = Random.new():NextNumber(-15, 15)
	script.door_locked:Play()
	
	for i = 1, 2 do
		task.delay(i * 0.1, function()
			script.nuh:Play()
		end)
	end
	
	local textLabel = script.TextLabel:Clone()
	textLabel.Parent = button
	textLabel.Text = tostring(text or "locked")
	
	task.spawn(function()
		textLabel.Visible = true
		
		TweenService:Create(textLabel, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, 0, 0, 0)
		}):Play()
		
		for i = 1, #text do
			textLabel.MaxVisibleGraphemes = textLabel.MaxVisibleGraphemes + 1
			local character = string.sub(text, textLabel.MaxVisibleGraphemes, textLabel.MaxVisibleGraphemes)
			
			if character ~= "" and character ~= " " then
				script["Papyrus Voice Talk Sound"]:Play()
			end
			
			task.wait(0.035)
		end
		
		task.wait(1)
		game:GetService("Debris"):AddItem(textLabel, 1)
		
		TweenService:Create(textLabel, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			TextStrokeTransparency = 1,
			TextTransparency = 1,
			Position = UDim2.new(1, 0, 1, 0)
		}):Play()
	end)
	
	TweenService:Create(lockIcon, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Rotation = 0
	}):Play()
	
	task.delay(1, function()
		game:GetService("Debris"):AddItem(lockIcon, 0.5)
		TweenService:Create(lockIcon, TweenInfo.new(0.5), {
			ImageTransparency = 1
		}):Play()
	end)
end

local isWindowFocused = false

game:GetService("UserInputService").WindowFocused:Connect(function()
	isWindowFocused = false
end)

game:GetService("UserInputService").WindowFocusReleased:Connect(function()
	isWindowFocused = true
end)

Lobby.AFK.MouseButton1Click:Connect(function()
	if isProcessing ~= false then
		return
	end
	
	isProcessing = true
	script.RemoteEvent:FireServer("afk")
	task.wait(0.5)
	isProcessing = false
end)

Lobby.MenuB.MouseButton1Click:Connect(function()
	if isWindowFocused then
		return
	end
	
	if isProcessing ~= false then
		return
	end
	
	isProcessing = true
	
	if workspace.GameProperties.State.Value == "INT" and workspace.GameProperties.Time.Value < 3 then
		lockAnimation(Lobby.MenuB, "")
	else
		if isWindowFocused then
			return
		end
		
		if game.Players.LocalPlayer:HasTag("OnRESULT") then
			lockAnimation(Lobby.MenuB, "")
		else
			openMenu2.OpenMenu2("Lobby")
		end
	end
	
	task.wait(0.5)
	isProcessing = false
end)

if not settingsData.ViewedDisclaimer then
	Intro.Visible = true
	script.Parent.Parent.GameUI.Enabled = false
	showDisclaimer()
end

local Slider = require(script:WaitForChild("Slider"))
local layoutOrder = 0
local sliderInstances = {}

for _, child in pairs(SETUI:GetChildren()) do
	if not child:IsA("UIListLayout") then
		child:Destroy()
	end
end

for _, categoryData in pairs(SettingsModule) do
	local order = layoutOrder + 1
	local categoryName = categoryData[1]
	local categoryClone = SettingsFrame.Cat:Clone()
	categoryClone.Name = categoryName
	categoryClone.TextLabel.Text = categoryName
	categoryClone.Parent = SETUI
	categoryClone.Visible = true
	categoryClone.LayoutOrder = order
	
	for _, settingData in pairs(categoryData[2]) do
		if settingData[1] == "Button" then
			local buttonClone = SettingsFrame.Setting1:Clone()
			order = order + 1
			buttonClone.Parent = SETUI
			buttonClone.LayoutOrder = order
			buttonClone.Frame.EX.Visible = true
			buttonClone.Frame.EX.Text = "O"
			buttonClone.Frame.EX.TextColor3 = Color3.new(255/255, 0/255, 0/255)
			buttonClone.Setting.Text = settingData[2]
			buttonClone.Name = settingData[2]
			
			buttonClone.Frame.EX.Activated:Connect(function()
				settingData[3](settingsData)
			end)
			
			if typeof(settingData[4]) == "table" then
				local key = settingData[4][1]
				local value = settingData[4][2]
				
				if settingsData[key] ~= nil then
					warn("yes")
					buttonVisibilityConditions[settingData[2]] = settingData[4]
					warn(settingsData[key])
					warn(value)
					
					if settingsData[key] == value then
						buttonClone.Visible = true
						continue
					end
					buttonClone.Visible = false
				end
			end
			continue
		end
		
		local settingKey = settingData[1][1]
		warn(settingData[1])
		
		if not string.match(settingKey, "Mobile") or game.Players.LocalPlayer.Device.Value == "mo" then
			order = order + 1
			local settingClone = nil
			
			if settingData[2] == "Slider" then
				settingClone = SettingsFrame.Slider:Clone()
			elseif settingData[2] == "Stringer" then
				settingClone = SettingsFrame.StringSet:Clone()
			else
				settingClone = SettingsFrame.Setting1:Clone()
			end
			
			settingClone.Setting.Text = settingData[1][2]
			settingClone.Parent = SETUI
			settingClone.LayoutOrder = order
			settingClone.Name = settingKey
			
			if settingData[2] == "Stringer" then
				if typeof(settingsData[settingKey]) == "nil" then
					settingsData[settingKey] = settingData[3]
				end
				
				local textBox = settingClone.TextBox
				textBox.Text = settingsData[settingKey]
				
				if settingData[4] then
					settingData[4](settingsData[settingKey])
				end
				
				textBox.FocusLost:Connect(function()
					if typeof(settingsData[settingKey]) == "nil" then
						settingsData[settingKey] = settingData[3]
					end
					
					settingsData[settingKey] = textBox.Text
					
					if settingData[6] then
						if settingData[6](settingsData[settingKey]) then
							settingsData[settingKey] = textBox.Text
						else
							settingsData[settingKey] = settingData[3]
						end
					end
					
					textBox.Text = settingsData[settingKey]
					DataUpdate:InvokeServer("UpdateSettings", { settingKey, settingsData[settingKey] })
					
					if not settingData[4] then
						return
					end
					settingData[4](settingsData[settingKey])
				end)
				
				settingClone.Frame.Reset.Activated:Connect(function()
					settingsData[settingKey] = settingData[3]
					textBox.Text = settingData[3]
					DataUpdate:InvokeServer("UpdateSettings", { settingKey, settingsData[settingKey] })
					
					if not settingData[4] then
						return
					end
					settingData[4](settingsData[settingKey])
				end)
				
			elseif settingData[2] == "Enabler" then
				settingClone.Frame.Enabler.Visible = true
				
				if typeof(settingsData[settingKey]) == "nil" then
					settingsData[settingKey] = settingData[3]
				end
				
				settingClone.Frame.Enabler.Image = if settingsData[settingKey] then "rbxassetid://11986879049" else "rbxassetid://264596040"
				
				if settingData[4] then
					settingData[4](settingsData[settingKey])
				end
				
				settingClone.Frame.Enabler.MouseButton1Click:Connect(function()
					if typeof(settingsData[settingKey]) == "nil" then
						settingsData[settingKey] = settingData[3]
					end
					
					settingsData[settingKey] = not settingsData[settingKey]
					DataUpdate:InvokeServer("UpdateSettings", { settingKey, settingsData[settingKey] })
					
					if settingData[4] then
						settingData[4](settingsData[settingKey])
					end
					
					settingClone.Frame.Enabler.Image = if settingsData[settingKey] then "rbxassetid://11986879049" else "rbxassetid://264596040"
					
					for name, conditions in pairs(buttonVisibilityConditions) do
						warn(name)
						local setting = SETUI:FindFirstChild(name)
						
						if setting and conditions[1] == settingKey then
							if settingsData[settingKey] == conditions[2] then
								setting.Visible = true
								continue
							end
							setting.Visible = false
						end
					end
				end)
				
			elseif settingData[2] == "Enterer" then
				settingClone.Frame.EX.Visible = true
				settingClone.Frame.EX.Text = ">"
				settingClone.Frame.EX.TextColor3 = Color3.new(255/255, 255/255, 0/255)
				
				local isEntered = false
				settingClone.Frame.EX.MouseButton1Click:Connect(function()
					isEntered = not isEntered
					settingData[if isEntered and settingData[4] then 4 else 3](settingsData)
				end)
				
			elseif settingData[2] == "Slider" then
				settingClone.slider:SetAttribute("DefaultValue", settingData[3][1])
				settingClone.slider:SetAttribute("End", settingData[3][2])
				settingClone.slider:SetAttribute("Increment", settingData[3][3])
				settingClone.slider:SetAttribute("Start", settingData[3][4])
				
				if not sliderInstances[settingClone.slider] then
					local settingLabel = settingClone.Setting
					
					if settingData[4] then
						settingData[4](settingsData[settingKey])
					end
					
					settingLabel.Text = settingData[1][2] .. " >> " .. settingsData[settingKey]
					
					local sliderConfig = {}
					sliderConfig.Start = tonumber(settingClone.slider:GetAttribute("Start")) or 0
					
					local currentValue = tonumber(settingsData[settingKey])
					if not currentValue then
						currentValue = tonumber(settingClone.slider:GetAttribute("DefaultValue")) or 0.5
					end
					
					sliderConfig.DefaultValue = currentValue
					sliderConfig.End = tonumber(settingClone.slider:GetAttribute("End")) or 1
					sliderConfig.Increment = tonumber(settingClone.slider:GetAttribute("Increment")) or 0.1
					
					sliderInstances[settingClone.slider] = Slider.new(settingClone.slider, {
						Axis = "X",
						SliderData = sliderConfig
					})
					
					sliderInstances[settingClone.slider]:Track()
					
					sliderInstances[settingClone.slider].Released:Connect(function(value)
						print(settingKey, value)
						
						if settingKey then
							settingsData[settingKey] = value
							DataUpdate:InvokeServer("UpdateSettings", { settingKey, value })
							
							if settingData[4] then
								settingData[4](settingsData[settingKey])
							end
							
							settingLabel.Text = settingData[1][2] .. " >> " .. value
						end
						
						print(settingsData)
					end)
				end
			end
			
			if typeof(settingData[5]) == "table" then
				local key = settingData[5][1]
				local value = settingData[5][2]
				
				if settingsData[key] ~= nil then
					warn("yes")
					buttonVisibilityConditions[settingKey] = settingData[5]
					warn(settingsData[key])
					warn(value)
					
					if settingsData[key] == value then
						settingClone.Visible = true
						continue
					end
					settingClone.Visible = false
				end
			end
		end
	end
	
	layoutOrder = order + 1
	local spacer = SettingsFrame.space:Clone()
	spacer.Visible = true
	spacer.Parent = SETUI
	spacer.LayoutOrder = layoutOrder
end

Settings.EXITset.MouseButton1Click:Connect(function()
	if isClosing then
		return
	end
	
	isMenuOpen = not isMenuOpen
	
	if isMenuOpen then
		return
	end
	
	isLoading = false
	isClosing = true
	rotationY = 0
	script.off:Play()
	
	TweenService:Create(Settings.SETUI, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(-1, 0, 0.078, 0)
	}):Play()
	
	Settings.ABBinds.Visible = isLoading
	task.wait(1)
	Settings.Visible = false
	isClosing = false
end)

print(settingsData)

-- Note: There are two unreferenced functions at the end that appear to be unused
-- They have been preserved but not called anywhere in the original code
