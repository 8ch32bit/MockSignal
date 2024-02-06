--[[-----------------------------------------------------------------
	--* Written by 8ch_32bit on 9/10/2023
	--* MockSignal.luau: A Luau module that emulates RBXScriptSignal instances
	--* Patch notes (v1.0.1, 2/6/2024):
		--* Replaced table.pack with raw table packing
		--* Renamed and reorganzied things for readability
		--* Added some config stuff (Includes firing mode and pcall mode)
-------------------------------------------------------------------]]

if _VERSION ~= "Luau" then
	return print("Make sure you are using LuaU, not Lua 5.x");
end;

-- Config

local SIGNAL_FIRE_METHOD = "DEFERRED"; -- Can be either "DEFERRED" (Utilizes task.defer), "IMMEDIATE" (Utilizes task.spawn) or "DEFAULT" (Utilizes coroutine.resume). This is a MockSignal LuaU only feature
local USES_PCALL = false; -- Set to true if you wish for signal fires to be pcall()'ed

-- Localize libraries/functions

local task = task;
local coroutine = coroutine;
local table = table;
local setmetatable = setmetatable;

-- Pre-define library functions for speed + tidyness

local coroutine_yield = coroutine.yield;
local coroutine_running = coroutine.running;

local table_unpack = table.unpack;

local NoYieldCall;

if SIGNAL_FIRE_METHOD == "IMMEDIATE" then
	NoYieldCall = task.spawn;
elseif SIGNAL_FIRE_METHOD == "DEFERRED" then
	NoYieldCall = task.defer;
elseif SIGNAL_FIRE_METHOD == "STANDARD" then
	local coroutine_create = coroutine.create;
	local coroutine_resume = coroutine.resume;
	
	NoYieldCall = function(FunctionOrThread, ...)
		-- Identical functionality to task.spawn, just with coroutines
		local PassedType = typeof(FunctionOrThread);
		local IsThread = PassedType == "thread";
		local IsFunction = PassedType == "function";

		if not (IsThread or IsFunction) then
			return;
		end;

		if IsFunction then
			FunctionOrThread = coroutine_create(FunctionOrThread)
		end;
		
		coroutine_resume(FunctionOrThread, ...);

		return FunctionOrThread;
	end;
end;

if USES_PCALL then
	local Localized = NoYieldCall;
	
	NoYieldCall = function(...)
		local Results = { pcall(Localized, ...) };

		return table_unpack(Results, 2, #Results);
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
