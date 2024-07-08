--// Author: 8ch_32bit
--// RBXScriptSignal emulation tailored for max performance

local MockSignal = {};

MockSignal.__index = MockSignal;
MockSignal.__type = "MockSignal";

function MockSignal.new(Name)
	local self = {};

	self.Connections = {};
	self.YieldingThreads = {};

	if Name then
		self.Name = `{Name}`;
	end;

	return setmetatable(self, MockSignal);
end;

function MockSignal:Fire(...)
	task.spawn(function(...)
		local YieldingThreads = self.YieldingThreads;

		for Index, Thread in ipairs(YieldingThreads) do
			coroutine.resume(Thread, ...);
			YieldingThreads[Index] = nil;
		end;
	end, ...);
	
	task.spawn(function(...)
		local Connections = self.Connections;

		for Index, Connection in ipairs(Connections) do
			task.spawn(Connection.Listener, ...);

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

	Connections[Index] = Connection;

	return Connection;
end;

function MockSignal:Wait()
	local YieldingThreads = self.YieldingThreads;
	local Index = #YieldingThreads + 1;

	local Thread = coroutine.running();

	YieldingThreads[Index] = Thread;

	local Returns = { coroutine.yield() };

	YieldingThreads[Index] = nil;

	return table.unpack(Returns);
end;

function MockSignal:DisconnectAll()
	table.clear(self.Connections);
end;

function MockSignal:Destroy()
	local YieldingThreads = self.YieldingThreads;
	
	for Index, Thread in YieldingThreads do
		coroutine.resume(Thread);
		YieldingThreads[Index] = nil;
	end
	
	table.clear(self.Connections);

	table.clear(self);
	setmetatable(self, nil);
end;

return MockSignal;
