--// Author: 8ch_32bit
--// RBXScriptSignal emulation tailored for max performance

--!strict
--!native
--!optimize 2

export type MockConnection = {
	__type: string,
	FiresOnce: boolean,
	Listener: (...any) -> (),
	Disconnect: (MockConnection, string) -> (),
}

export type MockSignal = {
	__type: string,
	Name: string?,
	Connections: { MockConnection },
	YieldingThreads: { thread },
}

local MockSignal = {}
MockSignal.__index = MockSignal

function MockSignal.new(Name: string?): MockSignal
	local self = {
		__type = "MockSignal",
		Connections = {},
		YieldingThreads = {},
		Name = `{Name}`,
	}

	return setmetatable(self, MockSignal)
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ IGNORE THIS WARNING
end

--// TODO: Fires the signal with the given arguments, resuming all yielding threads and firing all connection listeners
function MockSignal:Fire(...: any)
	local Connections = self.Connections
	local YieldingThreads = self.YieldingThreads
	
	task.spawn(function(...: any)
		for Index, Thread in ipairs(YieldingThreads) do
			YieldingThreads[Index] = nil
			coroutine.resume(Thread, ...)
		end
	end, ...)
	
	task.spawn(function(...: any)
		for Index, Connection in ipairs(Connections) do
			local Listener: (...any) -> () = Connection.Listener
			if Connection.FiresOnce then
				Connections[Index] = nil
			end
			task.spawn(Listener, ...)
		end
	end, ...)
end

--// TODO: Creates a MockConnection, that can be fired any given amount of times. Only gets disposed when the parent signal gets destroyed. 
function MockSignal:Connect(ListenerFunction: (...any) -> ()): MockConnection
	local Connections = self.Connections
	local Index = #Connections + 1

	local MockConnection = {
		__type = "MockConnection",
		FiresOnce = false,
		Listener = ListenerFunction,
	}

	function MockConnection.Disconnect()
		Connections[Index] = nil
	end

	Connections[Index] = MockConnection

	return MockConnection :: MockConnection
end

--// TODO: Creates a MockConnection that only fires once, and gets disposed after being fired
function MockSignal:Once(ListenerFunction: (...any) -> ()): MockConnection
	local Connections = self.Connections
	local Index = #Connections + 1

	local MockConnection = {
		__type = "MockConnection",
		FiresOnce = true,
		Listener = ListenerFunction,
	}

	function MockConnection.Disconnect()
		Connections[Index] = nil
	end

	Connections[Index] = MockConnection

	return MockConnection :: MockConnection
end

--// TODO: Yields the current thread until the signal is fired, also returning any fed results from what fired the signal.
function MockSignal:Wait()
	local YieldingThreads = self.YieldingThreads
	local Index = #YieldingThreads + 1

	local Thread: thread = coroutine.running()

	YieldingThreads[Index] = Thread

	local Returns: { any } = { coroutine.yield() }

	YieldingThreads[Index] = nil

	return table.unpack(Returns)
end

--// TODO: Disconnects every connection
function MockSignal:DisconnectAll()
	table.clear(self.Connections)
end

--// TODO: Completely dispose the MockSignal
function MockSignal:Destroy()
	self:DisconnectAll()
	
	table.clear(self.YieldingThreads)
	table.clear(self)
	
	setmetatable(self, nil)
end

return MockSignal :: typeof(MockSignal)
