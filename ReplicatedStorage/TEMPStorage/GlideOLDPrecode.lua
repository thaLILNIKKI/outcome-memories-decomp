local LocalPlayer = game.Players.LocalPlayer
local Character = LocalPlayer.Character
local Humanoid = Character:WaitForChild("Humanoid")
local Jump = script.Jump

-- Create BodyVelocity for movement control
local BodyVelocity = Instance.new("BodyVelocity")
BodyVelocity.MaxForce = Vector3.new(1, 1, 1) * (1 / 0)
BodyVelocity.Parent = Character.PrimaryPart

-- Setup touch controls if available
if LocalPlayer.PlayerGui:FindFirstChild("TouchGui") then
    script.Jump.InputBinding.UIButton = LocalPlayer.PlayerGui.TouchGui.TouchControlFrame.JumpButton
end

-- Load animations
local ANIMS = script:WaitForChild("ANIMS")
local animations = {}
for _, animation in ipairs(ANIMS:GetChildren()) do
    if animation:IsA("Animation") then
        animations[animation.Name] = Humanoid:WaitForChild("Animator"):LoadAnimation(animation)
    end
end

-- State variables
local canDoubleJump = false
local isOnCooldown = false
local jumpState = 0
local lastJumpTime = tick()
local isGliding = false
local hasReleasedJump = false

-- Track humanoid state changes
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

-- Handle jump press
script.Jump.Pressed:Connect(function()
    -- Check for double jump
    if Humanoid:GetState() == Enum.HumanoidStateType.Freefall and 
       (jumpState > 0 and (tick() - lastJumpTime > 0.2 and not isGliding)) then
        isGliding = true
        animations.DoubleJump:Play()
        
        -- Apply jump velocity
        local rootPart = Humanoid.RootPart
        rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
        rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + Vector3.new(0, 90, 0)
        
        -- Reset gliding state when landing or running
        task.spawn(function()
            repeat
                task.wait()
            until Humanoid:GetState() == Enum.HumanoidStateType.Landed or 
                  Humanoid:GetState() == Enum.HumanoidStateType.Running
            isGliding = false
        end)
        return
    end
    
    if Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall or not isGliding then
        return
    end
    
    hasReleasedJump = true
end)

-- Handle jump release
script.Jump.Released:Connect(function()
    if not hasReleasedJump or isOnCooldown then
        hasReleasedJump = false
        return
    end
    
    isOnCooldown = true
    task.delay(5, function()
        isOnCooldown = false
    end)
    hasReleasedJump = false
end)

-- Handle movement and gliding
game:GetService("RunService").Heartbeat:Connect(function()
    -- Apply movement velocity
    BodyVelocity.Velocity = Humanoid.MoveDirection * (Humanoid.WalkSpeed * 1.2) - Vector3.new(0, 23, 0)
    
    -- Handle gliding
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
