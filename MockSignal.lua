--// Author: 8ch99
--// RBXScriptSignal emulation tailored for max performance

--!strict
--!native
--!optimize 2

local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({}, Signal)
	self.__meta = "Signal"
	return self
end

function Signal:Fire(...)
	local Current = self.TopConnection
	while Current do
		task.spawn(Current.Function, ...)
		Current = Current.Next
	end
end

function Signal:Connect(Function)
	local Connection = {}
	Connection.Function = Function
	Connection.Next = self.TopConnection
	self.TopConnection = Connection
	
	function Connection.Disconnect()
		local Current: any? = self.TopConnection
		if Current == Connection then
			self.TopConnection = Current.Next
		else
			while Current do
				local Next = Current.Next
				if Next and Next == Connection then
					Current.Next = Next.Next
					break
				end
				Current = Next
			end
		end
		table.clear(Connection)
	end
	
	return Connection
end

function Signal:Once(Function)
	local Connection = nil
	Connection = self:Connect(function(...)
		Connection:Disconnect()
		return Function(...)
	end)
end

function Signal:Wait()
	local CurrentThread = coroutine.running()
	self:Once(function(...)
		task.spawn(CurrentThread, ...)
	end)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	self.TopConnection = nil
end

function Signal:Destroy()
	self.TopConnection = nil
	setmetatable(self, nil)
end

return Signal
