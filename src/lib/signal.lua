-- signal.lua
-- Thread-based signaling for Lua.

local Connection = {}
Connection.MT = {
	__index = Connection,
	__type = "LuaScriptConnection"
}

function Connection.new(s, f)
	local self = {}
	self._Container = s._Connections
	self._Callback = f
	self.Connected = true
	return setmetatable(self, Connection.MT)
end

function Connection:Disconnect()
	table.remove(self._Container, table.find(self._Container, self))
	self.Connected = false
end

local Signal = {}
Signal.MT = {
	__index = Signal,
	__type = "LuaScriptSignal"
}

function Signal.new()
	local self = {}
	self._Connections = {}
	return setmetatable(self, Signal.MT)
end

function Signal:Connect(f)
	local cn = Connection.new(self, f)
	self._Connections[#self._Connections + 1] = cn
	return cn
end

function Signal:DisconnectAll()
	for i = 1, #self._Connections do
		self._Connections[i]:Disconnect()
	end
end

function Signal:Fire(...)
	for i = 1, #self._Connections do
		task.spawn(self._Connections[i]._Callback, ...)
	end
end

function Signal:Wait()
	local thread, cn = coroutine.running(), nil
	cn = self:Connect(function(...)
		cn:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield(thread)
end

return Signal
