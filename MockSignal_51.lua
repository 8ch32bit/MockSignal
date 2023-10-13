--[[-----------------------------------------------------------------
	--* This was written by 8ch_32bit on 13/10/2023
	--* MockSignal.lua: A standard lua version of MockSignal
-------------------------------------------------------------------]]

--[[-----------------------------------------------------------------
	--* Pre-define some builtin functions that are used
-------------------------------------------------------------------]]

local typeof = typeof or type;

local Coroutine_yield   = coroutine.yield
local Coroutine_resume  = coroutine.resume;
local Coroutine_create  = coroutine.create;
local Coroutine_running = coroutine.running;

local Table_pack   = function(...) return { ... } end;
local Table_unpack = unpack;

--[[-----------------------------------------------------------------
	--* Main module library
-------------------------------------------------------------------]]

local MockSignal = {};

MockSignal.__index = MockSignal;
MockSignal.__type  = "MockSignal";

--[[-----------------------------------------------------------------
	--* TODO: Returns a new Signal instance
	--* returns: Signal
-------------------------------------------------------------------]]
function MockSignal.new()
	return setmetatable({}, MockSignal);
end;

--[[-----------------------------------------------------------------
	--* TODO: Call all of the connected functions, and resume
		any yielded threads
-------------------------------------------------------------------]]
function MockSignal:Fire(...)
	local Iterations = #self;
	
	for Idx = 1, Iterations do
		local Obj = self[Idx];
		
		if typeof(Obj) == "thread" then -- Resuming threads are loop priority
			Coroutine_resume(Obj, ...);
		else
			Coroutine_resume(Coroutine_create(Obj.Listener), ...);
		end;
	end;
end;

--[[-----------------------------------------------------------------
	--* TODO: Makes a new signal connection using the given
		function, This function will be called when the parenting
		signal is fired using the Signal:Fire() method
	--* returns: The created connection object
-------------------------------------------------------------------]]
function MockSignal:Connect(Func)
	local Self = self; -- So it can be used in a different scope
	local I    = #self + 1;

	local Connection = { Listener = Func };
	
	--[[-----------------------------------------------------------------
		--* TODO: Disconnect the connection from the parenting signal
	-------------------------------------------------------------------]]
	function Connection:Disconnect()
		Self[I] = nil;
	end;
	
	self[I] = Connection;
	
	return Connection;
end;

--[[-----------------------------------------------------------------
	--* TODO: Yield the thread that this function is called in
		until the parenting signal is fired using Signal:Fire()
	--* returns: Any parameters passed through Signal:Fire()
	--* NOTE: This function uses a similar method to
		@Xan_TheDragon's signal implementation from FastCastRedux
-------------------------------------------------------------------]]
function MockSignal:Wait()
	local I = #self + 1;
	
	self[I] = Coroutine_running();
	
	local A = Table_pack(Coroutine_yield());
	
	self[I] = nil;
	
	return Table_unpack(A);
end;

--[[-----------------------------------------------------------------
	--* Return the library
-------------------------------------------------------------------]]

return MockSignal;
