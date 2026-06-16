local require = require
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(script:WaitForChild("Signal"))

local HitboxClassRemote = ReplicatedStorage:WaitForChild("HitboxClassRemote")
local hitboxModule = require(script["HitboxClass Module"].Value)

local hitboxes = {}

HitboxClassRemote.OnClientEvent:Connect(function(command, data)
	if command == "Clr" then
		for key, hitbox in pairs(hitboxes) do
			hitbox:Destroy()
			hitboxes[key] = nil
		end
	else
		if command ~= "New" and not hitboxes[data._Tick] then
			warn("No hitbox found on the client for tick value sent. Don't change the tick value manually, change the ID instead. (HitboxClass)")
			return
		end
		
		if command == "New" then
			hitboxes[data._Tick] = hitboxModule.new(data)
			HitboxClassRemote:FireServer(data._Tick)
		end
		
		if command == "Start" then
			hitboxes[data._Tick]:Start()
		end
		
		if command == "Stop" then
			hitboxes[data._Tick]:Stop()
		end
		
		if command == "ClrTag" then
			hitboxes[data._Tick]:ClearTaggedChars()
		end
		
		if command == "Weld" then
			hitboxes[data._Tick]:WeldTo(data.WeldTo, data.Offset)
		end
		
		if command == "WeldOfs" then
			hitboxes[data._Tick]:ChangeWeldOffset(data.Offset)
		end
		
		if command == "Unweld" then
			hitboxes[data._Tick]:Unweld()
		end
		
		if command == "PosCh" then
			hitboxes[data._Tick]:SetPosition(data.Position)
		end
		
		if command == "Dbg" then
			hitboxes[data._Tick]:SetDebug(data.Debug)
		end
		
		if command ~= "Des" then
			return
		end
		
		hitboxes[data._Tick]:Destroy()
		hitboxes[data._Tick] = nil
	end
end)
