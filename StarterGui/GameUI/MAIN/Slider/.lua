local SliderModule = {
	Sliders = {}
}

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

assert(RunService:IsClient(), "Slider module can only be used on the Client!")

local Utils = script.Utils
local Signal = require(Utils.Signal)
local SliderFuncs = require(Utils.SliderFuncs)

function SliderModule.__index(table, key)
	for _, deprecatedInfo in ipairs({
		{ ".OnChange", ".Changed", (rawget(table, "Changed")) }
	}) do
		if string.sub(deprecatedInfo[1], 2) == key then
			warn(string.format("%s is deprecated, please use %s instead", deprecatedInfo[1], deprecatedInfo[2]))
			return deprecatedInfo[3]
		end
	end
	return SliderModule[key]
end

function SliderModule.new(holder, config)
	assert(pcall(function()
		return holder.AbsoluteSize, holder.AbsolutePosition
	end), "Holder argument does not have an AbsoluteSize/AbsolutePosition")
	
	local hasExistingSlider = false
	for _, existingSlider in ipairs(SliderModule.Sliders) do
		if existingSlider._holder == holder then
			hasExistingSlider = true
			break
		end
	end
	assert(not hasExistingSlider, "Cannot set two sliders with same frame!")
	
	assert(if config.SliderData.Increment == nil then false else true, "Failed to find Increment in SliderData table")
	assert(if config.SliderData.Start == nil then false else true, "Failed to find Start in SliderData table")
	assert(if config.SliderData.End == nil then false else true, "Failed to find End in SliderData table")
	assert(if config.SliderData.Increment > 0 then true else false, "SliderData.Increment must be greater than 0")
	assert(if config.SliderData.End > config.SliderData.Start then true else false, 
		string.format("Slider end value must be greater than its start value! (%.1f <= %.1f)", config.SliderData.End, config.SliderData.Start))
	
	local self = setmetatable({}, SliderModule)
	self._holder = holder
	
	local data = {
		Button = nil,
		HolderButton = nil,
		_clickOverride = false,
		_mainConnection = nil,
		_inputPos = nil,
		_percent = 0,
		_value = 0,
		_scaleIncrement = 0,
		_currentTween = nil,
		_clickConnections = {},
		_otherConnections = {}
	}
	
	data._allowBackgroundClick = config.AllowBackgroundClick ~= false
	self._data = data
	self._config = config
	self._config.Axis = string.upper(config.Axis or "X")
	self._config.Padding = config.Padding or 5
	self._config.MoveInfo = config.MoveInfo or TweenInfo.new(0.2)
	self._config.MoveType = config.MoveType or "Tween"
	self.IsHeld = false
	
	local sliderButton = holder:FindFirstChild("Slider")
	assert(sliderButton ~= nil, "Failed to find slider button.")
	assert(sliderButton:IsA("GuiButton"), "Slider is not a GuiButton")
	
	self._data.Button = sliderButton
	
	if self._data._allowBackgroundClick then
		local holderClickButton = Instance.new("TextButton")
		holderClickButton.BackgroundTransparency = 1
		holderClickButton.Text = ""
		holderClickButton.Name = "HolderClickButton"
		holderClickButton.Size = UDim2.fromScale(1, 1)
		holderClickButton.ZIndex = -1
		holderClickButton.Parent = self._holder
		self._data.HolderButton = holderClickButton
	end
	
	self._data._percent = 0
	
	if config.SliderData.DefaultValue then
		config.SliderData.DefaultValue = math.clamp(config.SliderData.DefaultValue, config.SliderData.Start, config.SliderData.End)
		self._data._percent = SliderFuncs.getAlphaBetween(config.SliderData.Start, config.SliderData.End, config.SliderData.DefaultValue)
	end
	
	self._data._percent = math.clamp(self._data._percent, 0, 1)
	self._data._value = SliderFuncs.getNewValue(self)
	self._data._increment = config.SliderData.Increment
	self._data._scaleIncrement = SliderFuncs.getScaleIncrement(self)
	
	self.Changed = Signal.new()
	self.Dragged = Signal.new()
	self.Released = Signal.new()
	self.HeldStarted = Signal.new()
	
	self._data._percent = SliderFuncs.snapToScale(self._data._percent, self._data._scaleIncrement)
	self:Move()
	
	table.insert(self._data._otherConnections, sliderButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:Move("Instant")
	end))
	
	table.insert(SliderModule.Sliders, self)
	return self
end

function SliderModule.Track(self)
	for _, connection in ipairs(self._data._clickConnections) do
		connection:Disconnect()
	end
	
	table.insert(self._data._clickConnections, self._data.Button.MouseButton1Down:Connect(function()
		self.IsHeld = true
		self.HeldStarted:Fire(self._data._value)
	end))
	
	table.insert(self._data._clickConnections, self._data.Button.MouseButton1Up:Connect(function()
		if self.IsHeld then
			self.Released:Fire(self._data._value)
		end
		self.IsHeld = false
	end))
	
	if self._data._allowBackgroundClick then
		table.insert(self._data._clickConnections, self._data.HolderButton.Activated:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			
			self._data._inputPos = input.Position
			self._data._clickOverride = true
			self:Update()
			self._data._clickOverride = false
		end))
	end
	
	if self.Changed then
		self.Changed:Fire(self._data._value)
	end
	
	if self._data._mainConnection then
		self._data._mainConnection:Disconnect()
	end
	
	self._data._mainConnection = UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		
		self._data._inputPos = input.Position
		self:Update()
	end)
end

function SliderModule.Update(self)
	if not (self.IsHeld or self._data._clickOverride) then
		return
	end
	
	if not self._data._inputPos then
		return
	end
	
	local axisValue = self._data._inputPos[self._config.Axis]
	if not axisValue then
		return
	end
	
	self._data._percent = math.clamp(
		SliderFuncs.snapToScale(
			(axisValue - self._holder.AbsolutePosition[self._config.Axis]) / 
			self._holder.AbsoluteSize[self._config.Axis],
			self._data._scaleIncrement
		),
		0, 1
	)
	
	self.Dragged:Fire(self._data._value)
	self:Move()
end

function SliderModule.Untrack(self)
	for _, connection in ipairs(self._data._clickConnections) do
		connection:Disconnect()
	end
	
	if self._data._mainConnection then
		self._data._mainConnection:Disconnect()
	end
	
	self.IsHeld = false
end

function SliderModule.Reset(self)
	for _, connection in ipairs(self._data._clickConnections) do
		connection:Disconnect()
	end
	
	if self._data._mainConnection then
		self._data._mainConnection:Disconnect()
	end
	
	self.IsHeld = false
	self._data._percent = 0
	
	if self._config.SliderData.DefaultValue then
		self._data._percent = SliderFuncs.getAlphaBetween(
			self._config.SliderData.Start,
			self._config.SliderData.End,
			self._config.SliderData.DefaultValue
		)
	end
	
	self._data._percent = math.clamp(self._data._percent, 0, 1)
	self:Move()
end

function SliderModule.OverrideValue(self, value)
	self.IsHeld = false
	self._data._percent = SliderFuncs.getAlphaBetween(
		self._config.SliderData.Start,
		self._config.SliderData.End,
		value
	)
	self._data._percent = math.clamp(self._data._percent, 0, 1)
	self._data._percent = SliderFuncs.snapToScale(self._data._percent, self._data._scaleIncrement)
	self:Move()
end

function SliderModule.Move(self, moveType)
	self._data._value = SliderFuncs.getNewValue(self)
	
	local moveTypeFinal = if moveType == nil then self._config.MoveType else moveType
	
	if moveTypeFinal == "Tween" or moveTypeFinal == nil then
		if self._data._currentTween then
			self._data._currentTween:Cancel()
		end
		
		self._data._currentTween = TweenService:Create(self._data.Button, self._config.MoveInfo, {
			Position = SliderFuncs.getNewPosition(self)
		})
		self._data._currentTween:Play()
	elseif moveTypeFinal == "Instant" then
		self._data.Button.Position = SliderFuncs.getNewPosition(self)
	end
	
	self.Changed:Fire(self._data._value)
end

function SliderModule.OverrideIncrement(self, increment)
	self._config.SliderData.Increment = increment
	self._data._increment = increment
	self._data._scaleIncrement = SliderFuncs.getScaleIncrement(self)
	self._data._percent = math.clamp(self._data._percent, 0, 1)
	self._data._percent = SliderFuncs.snapToScale(self._data._percent, self._data._scaleIncrement)
	self:Move()
end

function SliderModule.GetValue(self)
	return self._data._value
end

function SliderModule.GetIncrement(self)
	return self._data._increment
end

function SliderModule.Destroy(self)
	for _, connection in ipairs(self._data._clickConnections) do
		connection:Disconnect()
	end
	
	for _, connection in ipairs(self._data._otherConnections) do
		connection:Disconnect()
	end
	
	if self._data._mainConnection then
		self._data._mainConnection:Disconnect()
	end
	
	if self._data.HolderButton then
		self._data.HolderButton:Destroy()
		self._data.HolderButton = nil
	end
	
	self.Changed:Destroy()
	self.Dragged:Destroy()
	self.Released:Destroy()
	
	for i = 1, #SliderModule.Sliders do
		if SliderModule.Sliders[i] == self then
			table.remove(SliderModule.Sliders, i)
		end
	end
	
	setmetatable(self, nil)
end

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	
	for _, slider in ipairs(SliderModule.Sliders) do
		if slider.IsHeld then
			slider.Released:Fire(slider._data._value)
		end
		slider.IsHeld = false
	end
end)

return SliderModule
