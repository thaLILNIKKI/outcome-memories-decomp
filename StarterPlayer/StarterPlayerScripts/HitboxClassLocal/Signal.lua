local currentRunnerThread = nil

local function acquireRunnerThreadAndCallEventHandler(handler, ...)
	local previousThread = currentRunnerThread
	currentRunnerThread = nil
	handler(...)
	currentRunnerThread = previousThread
end

local function runEventHandlerInFreeThread(...)
	acquireRunnerThreadAndCallEventHandler(...)
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

local Connection = {}
Connection.__index = Connection

function Connection.Disconnect(connection)
	if not connection.Connected then
		return
	end
	
	connection.Connected = false
	
	if connection._signal._handlerListHead == connection then
		connection._signal._handlerListHead = connection._next
		return
	end
	
	local handlerListHead = connection._signal._handlerListHead
	while handlerListHead and handlerListHead._next ~= connection do
		handlerListHead = handlerListHead._next
	end
	
	if not handlerListHead then
		return
	end
	
	handlerListHead._next = connection._next
end

Connection.Destroy = Connection.Disconnect

setmetatable(Connection, {
	__index = function(table, key)
		error(("Attempt to get Connection::%s (not a valid member)"):format((tostring(key))), 2)
	end,
	__newindex = function(table, key, value)
		error(("Attempt to set Connection::%s (not a valid member)"):format((tostring(key))), 2)
	end
})

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({
		_handlerListHead = false,
		_proxyHandler = nil,
		_yieldedThreads = nil
	}, Signal)
end

function Signal.Wrap(rbxScriptSignal)
	local isValid = typeof(rbxScriptSignal) == "RBXScriptSignal"
	assert(isValid, "Argument #1 to Signal.Wrap must be a RBXScriptSignal; got " .. typeof(rbxScriptSignal))
	
	local signal = Signal.new()
	signal._proxyHandler = rbxScriptSignal:Connect(function(...)
		signal:Fire(...)
	end)
	
	return signal
end

function Signal.Is(object)
	return if type(object) == "table" then getmetatable(object) == Signal else false
end

function Signal.Connect(signal, handler)
	local connection = setmetatable({
		Connected = true,
		_next = false,
		_signal = signal,
		_fn = handler
	}, Connection)
	
	if signal._handlerListHead then
		connection._next = signal._handlerListHead
	end
	
	signal._handlerListHead = connection
	return connection
end

function Signal.ConnectOnce(signal, handler)
	return signal:Once(handler)
end

function Signal.Once(signal, handler)
	local connection = nil
	local hasFired = false
	
	connection = signal:Connect(function(...)
		if not hasFired then
			hasFired = true
			connection:Disconnect()
			handler(...)
		end
	end)
	
	return connection
end

function Signal.GetConnections(signal)
	local handlerListHead = signal._handlerListHead
	local connections = {}
	
	while handlerListHead do
		table.insert(connections, handlerListHead)
		handlerListHead = handlerListHead._next
	end
	
	return connections
end

function Signal.DisconnectAll(signal)
	local handlerListHead = signal._handlerListHead
	
	while handlerListHead do
		handlerListHead.Connected = false
		handlerListHead = handlerListHead._next
	end
	
	signal._handlerListHead = false
	
	local yieldedThreads = rawget(signal, "_yieldedThreads")
	if not yieldedThreads then
		return
	end
	
	for thread in yieldedThreads do
		if coroutine.status(thread) == "suspended" then
			warn(debug.traceback(thread, "signal disconnected; yielded thread cancelled", 2))
			task.cancel(thread)
		end
	end
	
	table.clear(signal._yieldedThreads)
end

function Signal.Fire(signal, ...)
	local handlerListHead = signal._handlerListHead
	
	while handlerListHead do
		if handlerListHead.Connected then
			if not currentRunnerThread then
				currentRunnerThread = coroutine.create(runEventHandlerInFreeThread)
			end
			task.spawn(currentRunnerThread, handlerListHead._fn, ...)
		end
		handlerListHead = handlerListHead._next
	end
end

function Signal.FireDeferred(signal, ...)
	local handlerListHead = signal._handlerListHead
	
	while handlerListHead do
		local connection = handlerListHead
		task.defer(function(...)
			if not connection.Connected then
				return
			end
			connection._fn(...)
		end, ...)
		handlerListHead = handlerListHead._next
	end
end

function Signal.Wait(signal)
	local yieldedThreads = rawget(signal, "_yieldedThreads")
	
	if not yieldedThreads then
		yieldedThreads = {}
		rawset(signal, "_yieldedThreads", yieldedThreads)
	end
	
	local currentThread = coroutine.running()
	yieldedThreads[currentThread] = true
	
	signal:Once(function(...)
		yieldedThreads[currentThread] = nil
		task.spawn(currentThread, ...)
	end)
	
	return coroutine.yield()
end

function Signal.Destroy(signal)
	signal:DisconnectAll()
	
	local proxyHandler = rawget(signal, "_proxyHandler")
	if not proxyHandler then
		return
	end
	
	proxyHandler:Disconnect()
end

setmetatable(Signal, {
	__index = function(table, key)
		error(("Attempt to get Signal::%s (not a valid member)"):format((tostring(key))), 2)
	end,
	__newindex = function(table, key, value)
		error(("Attempt to set Signal::%s (not a valid member)"):format((tostring(key))), 2)
	end
})

return table.freeze({
	new = Signal.new,
	Wrap = Signal.Wrap,
	Is = Signal.Is
})
