-- Author: 8ch_32bit
-- RBXScriptSignal emulation tailored for max performance

local MockSignal = {};

MockSignal.__index = MockSignal;
MockSignal.__type = "MockSignal"; -- if you ever do checks

-- TODO: Create a new MockSignal instance
-- the Name arg doesn't actually alter any behavior, but is just there for when you need it
function MockSignal.new(Name)
	local self = {};
	
	if Name then
		self.Name = `{Name}`;
	end;
	
	return setmetatable(self, MockSignal);
end;

-- TODO: Fire all connections and release all yielding threads
function MockSignal:Fire(...)
	-- Free yielding threads
	task.spawn(function(...)
		local YieldingThreads = self.YieldingThreads;
		
		for Index, Thread in ipairs(YieldingThreads) do
			task.spawn(Thread, ...);
			-- remove thread
			YieldingThreads[Index] = nil;
		end;
	end, ...);
	
	-- Fire connection functions
	task.spawn(function(...)
		local Connections = self.Connections;
		
		for Index, Connection in ipairs(Connections) do
			task.spawn(Connection.Listener, ...);
			
			-- remove the signal if it can only be fired once
			if Connection.FiresOnce then
				Connections[Index] = nil;
			end;
		end;
	end, ...);
end;

function MockSignal:Connect(ListenerFunction)
	local Connections = self.Connections;
	local Index = #Connections + 1;

	local Connection = {};

	Connection.FiresOnce = false;
	Connection.Listener = ListenerFunction;

	function Connection.Disconnect()
		Connections[Index] = nil;
	end;

	-- Connection.disconnect = Connection.Disconnect;

	Connections[Index] = Connection;

	return Connection;
end;

function MockSignal:Once(ListenerFunction)
	local Connections = self.Connections;
	local Index = #Connections + 1;

	local Connection = {};

	Connection.FiresOnce = true;
	Connection.Listener = ListenerFunction;

	function Connection.Disconnect()
		Connections[Index] = nil;
	end;

	-- Connection.disconnect = Connection.Disconnect;

	Connections[Index] = Connection;

	return Connection;
end;

function MockSignal:Wait()
	local YieldingThreads = self.YieldingThreads;
	local Index = #YieldingThreads + 1;
	
	local Thread = coroutine.running();

	YieldingThreads[Index] = { Listener = Thread };

	local Returns = { coroutine.yield() };

	self[Index] = nil;

	return table.unpack(Returns);
end;

function MockSignal:DisconnectAll()
	local Connections = self.Connections;

	for Idx in ipairs(Connections) do
		Connections[Idx] = nil;
	end;
end;

function MockSignal:Destroy()
	self:DisconnectAll();
	
	table.clear(self);
	setmetatable(self, nil);
end;

-- MockSignal.connect = MockSignal.Connect;
-- MockSignal.wait = MockSignal.Wait;

return MockSignal;
