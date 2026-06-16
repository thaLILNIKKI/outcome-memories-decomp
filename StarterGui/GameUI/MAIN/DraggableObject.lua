local UDim2_new = UDim2.new
local UserInputService = game:GetService("UserInputService")

local Draggable = {}
Draggable.__index = Draggable

function Draggable.new(object)
	local self = {
		Object = object,
		DragStarted = nil,
		DragEnded = nil,
		Dragged = nil,
		Dragging = false
	}
	setmetatable(self, Draggable)
	return self
end

function Draggable.Enable(self)
	local Object = self.Object
	local currentInput = nil
	local startPosition = nil
	local startObjectPosition = nil
	local isDragging = false
	
	local function update(input)
		local delta = input.Position - startPosition
		local newPosition = UDim2_new(
			startObjectPosition.X.Scale,
			startObjectPosition.X.Offset + delta.X,
			startObjectPosition.Y.Scale,
			startObjectPosition.Y.Offset + delta.Y
		)
		Object.Position = newPosition
		return newPosition
	end
	
	self.InputBegan = Object.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		
		isDragging = true
		
		local connection = nil
		connection = input.Changed:Connect(function()
			if input.UserInputState ~= Enum.UserInputState.End or not (self.Dragging or isDragging) then
				return
			end
			
			self.Dragging = false
			connection:Disconnect()
			
			if self.DragEnded and not isDragging then
				self.DragEnded()
			end
			
			isDragging = false
		end)
	end)
	
	self.InputChanged = Object.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		currentInput = input
	end)
	
	self.InputChanged2 = UserInputService.InputChanged:Connect(function(input)
		if Object.Parent == nil then
			self:Disable()
			return
		end
		
		if isDragging then
			isDragging = false
			
			if self.DragStarted then
				self.DragStarted()
			end
			
			self.Dragging = true
			startPosition = input.Position
			startObjectPosition = Object.Position
		end
		
		if input ~= currentInput or not self.Dragging then
			return
		end
		
		local delta = input.Position - startPosition
		local newPosition = UDim2_new(
			startObjectPosition.X.Scale,
			startObjectPosition.X.Offset + delta.X,
			startObjectPosition.Y.Scale,
			startObjectPosition.Y.Offset + delta.Y
		)
		Object.Position = newPosition
		
		if not self.Dragged then
			return
		end
		
		self.Dragged(newPosition)
	end)
end

function Draggable.Disable(self)
	self.InputBegan:Disconnect()
	self.InputChanged:Disconnect()
	self.InputChanged2:Disconnect()
	
	if not self.Dragging then
		return
	end
	
	self.Dragging = false
	
	if not self.DragEnded then
		return
	end
	
	self.DragEnded()
end

return Draggable
