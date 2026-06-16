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
local animations = {}
local isOnCooldown = false

for _, animation in ipairs(ANIMS:GetChildren()) do
    if animation:IsA("Animation") then
        animations[animation.Name] = Humanoid:WaitForChild("Animator"):LoadAnimation(animation)
    end
end

local hasReleasedJump = false
local isGliding = false
local jumpState = 0
local lastJumpTime = tick()

Humanoid.StateChanged:Connect(function(oldState, newState)
    if newState == Enum.HumanoidStateType.Landed then
        if not hasReleasedJump then
            jumpState = 0
            return
        end
        hasReleasedJump = false
        if isOnCooldown then
            jumpState = 0
            return
        end
        isOnCooldown = true
        task.delay(5, function()
            isOnCooldown = false
        end)
        jumpState = 0
    else
        if newState ~= Enum.HumanoidStateType.Jumping then
            return
        end
        jumpState = 1
        lastJumpTime = tick()
        hasReleasedJump = false
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed and input.KeyCode ~= Enum.KeyCode.ButtonA then
        return
    end
    if input.KeyCode ~= Enum.KeyCode.Space and input.KeyCode ~= Enum.KeyCode.ButtonA then
        return
    end
    if Humanoid:GetState() == Enum.HumanoidStateType.Freefall and (jumpState > 0 and (tick() - lastJumpTime > 0.2 and not isGliding)) then
        isGliding = true
        animations.DoubleJump:Play()
        local rootPart = Humanoid.RootPart
        rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
        rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + Vector3.new(0, 90, 0)
        task.spawn(function()
            repeat
                task.wait()
            until Humanoid:GetState() == Enum.HumanoidStateType.Landed or Humanoid:GetState() == Enum.HumanoidStateType.Running
            isGliding = false
        end)
        return
    end
    if Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall or not isGliding then
        return
    end
    hasReleasedJump = true
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode ~= Enum.KeyCode.Space and input.KeyCode ~= Enum.KeyCode.ButtonA then
        return
    end
    if hasReleasedJump and not isOnCooldown then
        isOnCooldown = true
        task.delay(5, function()
            isOnCooldown = false
        end)
    end
    hasReleasedJump = false
end)

game:GetService("RunService").Heartbeat:Connect(function()
    BodyVelocity.Velocity = Humanoid.MoveDirection * (Humanoid.WalkSpeed * 1.5) - Vector3.new(0, 23, 0)
    if hasReleasedJump and (Humanoid:GetState() == Enum.HumanoidStateType.Freefall and not isOnCooldown) then
        BodyVelocity.Parent = Character.PrimaryPart
        if not animations.Glide.IsPlaying then
            animations.Glide:Play()
        end
    else
        BodyVelocity.Parent = script
        if animations.Glide.IsPlaying then
            animations.Glide:Stop()
        end
    end
end)
