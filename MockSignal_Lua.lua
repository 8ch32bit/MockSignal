--[[-----------------------------------------------------------------
	--* Written by 8ch_32bit on 9/10/2023
	--* MockSignal.luau: A Lua module that emulates RBXScriptSignal instances
	--* Patch notes (v1.0.1, 2/6/2024):
		--* Replaced table.pack with raw table packing
		--* Renamed and reorganzied things for readability
		--* Added some config stuff (Includes pcall mode)
-------------------------------------------------------------------]]

-- Config

local USES_PCALL = false; -- Set to true if you wish for signal fires to be pcall()'ed

-- Localize libraries/functions

local pcall = pcall;
local coroutine = coroutine;
local table = table;
local setmetatable = setmetatable;
local type = type;

-- Pre-define library functions for speed + tidyness

local coroutine_create = coroutine.create;
local coroutine_resume = coroutine.resume;
local coroutine_yield = coroutine.yield;
local coroutine_running = coroutine.running;
local table_unpack = table.unpack or unpack;

local function NoYieldCall(FunctionOrThread, ...)
	local PassedType = type(FunctionOrThread);
	local IsThread = PassedType == "thread";
	local IsFunction = PassedType == "function";

	if not (IsThread or IsFunction) then
		return;
	end;

	if IsFunction then
		FunctionOrThread = coroutine_create(FunctionOrThread);
	end;
		
	coroutine_resume(FunctionOrThread, ...);

	return FunctionOrThread;
end;

if USES_PCALL then
	NoYieldCall = function(FunctionOrThread, ...)
		local PassedType = type(FunctionOrThread);
		local IsThread = PassedType == "thread";
		local IsFunction = PassedType == "function";

		if not (IsThread or IsFunction) then
			return;
		end;

		if IsFunction then
			FunctionOrThread = coroutine_create(FunctionOrThread);
		end;
		
		pcall(coroutine_resume, FunctionOrThread, ...);

		return FunctionOrThread;
	end;
end;

local MockSignal = {};
MockSignal.__index = MockSignal;

function MockSignal.new()
	return setmetatable({}, MockSignal);
end;

function MockSignal:Fire(...)
	local Iterations = #self;
	
	for Idx = 1, Iterations do
		NoYieldCall(self[Idx].Listener, ...);
	end;
end;

function MockSignal:Wait()
	local Index = #self + 1;
	local RunningThread = coroutine_running();
	
	self[Index] = RunningThread;
	
	local Returns = { coroutine_yield() };
	
	self[Index] = nil;
	
	return table_unpack(Returns);
end;

function MockSignal:Connect(ListenerFunction)
	local Index = #self + 1;
	local Signals = self; -- For readability and lower-stack access
	
	local Connection = { Listener = ListenerFunction };
	
	function Connection:Disconnect()
		Signals[I] = nil;
	end;
	
	self[I] = Connection;
	
	return Connection;
end;

function MockSignal:Once(ListenerFunction)
	local Index = #self + 1;
	local Signals = self; -- For readability and lower-stack access
	
	local Connection = { Listener = function()
		Signals[Index] = nil;
		return ListenerFunction();
	end};
	
	function Connection:Disconnect()
		Signals[Index] = nil;
	end;
	
	self[Index] = Connection;
	
	return Connection;
end;

return MockSignal;
