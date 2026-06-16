local startTime = tick()
local frameCount = 0
local currentFPS = 60

game:GetService("RunService").RenderStepped:Connect(function()
	frameCount = frameCount + 1
	
	if not (tick() - startTime >= 1) then
		return
	end
	
	currentFPS = frameCount
	frameCount = 0
	startTime = tick()
	
	if currentFPS >= 50 then
		script.Parent.TextColor3 = Color3.fromRGB(0, 255, 0)
	end
	
	if currentFPS < 50 then
		script.Parent.TextColor3 = Color3.fromRGB(255, 173, 51)
	end
	
	if currentFPS < 30 then
		script.Parent.TextColor3 = Color3.fromRGB(255, 0, 0)
	end
	
	script.Parent.Text = "FPS: " .. currentFPS
end)
