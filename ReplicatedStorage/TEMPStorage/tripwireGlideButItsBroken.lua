local LocalPlayer = game.Players.LocalPlayer
local Character = LocalPlayer.Character
local Humanoid = Character:WaitForChild("Humanoid")
script:WaitForChild("InputAction")
local UserInputService = game:GetService("UserInputService")
local BodyVelocity = Instance.new("BodyVelocity")
BodyVelocity.MaxForce = Vector3.new(1, 1, 1) * (1 / 0)
BodyVelocity.Parent = Character.PrimaryPart
if LocalPlayer.PlayerGui:FindFirstChild("TouchGui") then
	script.Jump.InputBinding.UIButton = LocalPlayer.PlayerGui.TouchGui.TouchControlFrame.JumpButton
end
local ANIMS = script:WaitForChild("ANIMS")
local t = {}
local v1 = false
for i, v in ipairs(ANIMS:GetChildren()) do
	if v:IsA("Animation") then
		t[v.Name] = Humanoid:WaitForChild("Animator"):LoadAnimation(v)
	end
end
local v2 = false
local v3 = false
local v4 = 0
local v5 = tick()
Humanoid.StateChanged:Connect(function(p1, p2) --[[ Line: 26 | Upvalues: v2 (ref), v1 (ref), v4 (ref), v5 (ref) ]]
	if p2 == Enum.HumanoidStateType.Landed then
		if not v2 then
			v4 = 0
			return
		end
		v2 = false
		if v1 then
			v4 = 0
			return
		end
		v1 = true
		task.delay(5, function() --[[ Line: 39 | Upvalues: v1 (ref) ]]
			v1 = false
		end)
		v4 = 0
	else
		if p2 ~= Enum.HumanoidStateType.Jumping then
			return
		end
		v4 = 1
		v5 = tick()
		v2 = false
	end
end)
UserInputService.InputBegan:Connect(function(p1, p2) --[[ Line: 53 | Upvalues: Humanoid (copy), v4 (ref), v5 (ref), v3 (ref), t (copy), v2 (ref) ]]
	if p2 and p1.KeyCode ~= Enum.KeyCode.ButtonA then
		return
	end
	if p1.KeyCode ~= Enum.KeyCode.Space and p1.KeyCode ~= Enum.KeyCode.ButtonA then
		return
	end
	if Humanoid:GetState() == Enum.HumanoidStateType.Freefall and (v4 > 0 and (tick() - v5 > 0.2 and not v3)) then
		v3 = true
		t.DoubleJump:Play()
		local RootPart = Humanoid.RootPart
		RootPart.AssemblyLinearVelocity = RootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
		local RootPart_2 = Humanoid.RootPart
		RootPart_2.AssemblyLinearVelocity = RootPart_2.AssemblyLinearVelocity + Vector3.new(0, 90, 0)
		task.spawn(function() --[[ Line: 69 | Upvalues: Humanoid (ref), v3 (ref) ]]
			repeat
				task.wait()
			until Humanoid:GetState() == Enum.HumanoidStateType.Landed or Humanoid:GetState() == Enum.HumanoidStateType.Running
			v3 = false
		end)
		return
	end
	if Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall or not v3 then
		return
	end
	v2 = true
end)
UserInputService.InputEnded:Connect(function(p1, p2) --[[ Line: 83 | Upvalues: v2 (ref), v1 (ref) ]]
	if p1.KeyCode ~= Enum.KeyCode.Space and p1.KeyCode ~= Enum.KeyCode.ButtonA then
		return
	end
	if v2 and not v1 then
		v1 = true
		task.delay(5, function() --[[ Line: 89 | Upvalues: v1 (ref) ]]
			v1 = false
		end)
	end
	v2 = false
end)
game:GetService("RunService").Heartbeat:Connect(function() --[[ Line: 100 | Upvalues: BodyVelocity (copy), Humanoid (copy), v2 (ref), v1 (ref), Character (copy), t (copy) ]]
	BodyVelocity.Velocity = Humanoid.MoveDirection * (Humanoid.WalkSpeed * 1.5) - Vector3.new(0, 23, 0)
	if v2 and (Humanoid:GetState() == Enum.HumanoidStateType.Freefall and not v1) then
		BodyVelocity.Parent = Character.PrimaryPart
		if not t.Glide.IsPlaying then
			t.Glide:Play()
		end
	else
		BodyVelocity.Parent = script
		if not t.Glide.IsPlaying then
			return
		end
		t.Glide:Stop()
	end
end)
