local Connection = {}
Connection.__index = Connection

function Connection.new(callback)
	return setmetatable({
		Connected = true,
		_callback = callback
	}, Connection)
end

function Connection.Disconnect(connection)
	connection.Connected = false
end

setmetatable(Connection, {
	__index = function(table, key)
		error(string.format("Attempt to get connection::%s (not a valid member)", (tostring(key))))
	end,
	__newIndex = function(table, key)
		error(string.format("Attempt to set connection::%s (not a valid member)", (tostring(key))))
	end
})

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({
		_listeners = {}
	}, Signal)
end

function Signal.Is(object)
	return getmetatable(object) == Signal
end

function Signal.Connect(signal, callback)
	local isValid = if typeof(callback) == "function" then true else false
	local format = string.format
	assert(isValid, format("Invalid argument #1 (function expected got %s)", (typeof(callback))))
	
	local connection = Connection.new(callback)
	table.insert(signal._listeners, connection)
	return connection
end

function Signal.ConnectParallel(signal, callback)
	local isValid = if typeof(callback) == "function" then true else false
	local format = string.format
	assert(isValid, format("Invalid argument #1 (function expected got %s)", (typeof(callback))))
	
	task.desynchronize()
	signal:Connect(callback)
	task.synchronize()
end

function Signal.Once(signal, callback)
	local connection = nil
	connection = signal:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)
	return connection
end

function Signal.Wait(signal)
	local currentThread = coroutine.running()
	
	signal:Once(function(...)
		task.spawn(currentThread, ...)
	end)
	
	return coroutine.yield()
end

function Signal.Fire(signal, ...)
	for i, connection in ipairs(signal._listeners) do
		if connection.Connected then
			task.spawn(function(...)
				connection._callback(...)
			end, ...)
		else
			table.remove(signal._listeners, i)
		end
	end
end

function Signal.FireParallel(signal, ...)
	task.desynchronize()
	signal:Fire(...)
	task.synchronize()
end

function Signal.Destroy(signal)
	for _, connection in ipairs(signal._listeners) do
		connection:Disconnect()
	end
	table.clear(signal._listeners)
end

Signal.Destroy = Signal.DisconnectAll

setmetatable(Signal, {
	__index = function(table, key)
		error(string.format("Attempt to get signal::%s (not a valid member)", (tostring(key))))
	end,
	__newIndex = function(table, key)
		error(string.format("Attempt to set signal::%s (not a valid member)", (tostring(key))))
	end
})

return Signal
