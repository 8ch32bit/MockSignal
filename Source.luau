--// Author: 8ch99
--// RBXScriptSignal emulation tailored for max performance

--[[

MIT License

Copyright (c) 2025 8ch99

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]

--!strict
--!native
--!optimize 2

export type ConnectionNode = {
	Function: (...any) -> (...any),
	Next: ConnectionNode?,
	Connected: boolean,
	Disconnect: (ConnectionNode?) -> (),
}

export type Signal = typeof(setmetatable({}, {})) & {
	--// Properties
	__meta: string,
	TopConnection: ConnectionNode?,
	--// Functions
	Fire: (...any) -> (),
	Connect: ((...any) -> (...any)) -> ConnectionNode,
	Once: ((...any) -> (...any)) -> ConnectionNode,
	Wait: () -> (...any),
	DisconnectAll: () -> (),
	Destroy: () -> (),
}

local Signal = {}
Signal.__index = Signal

function Signal.new(): Signal
	local self = setmetatable({} :: Signal, Signal)
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

function Signal:Connect(Function): ConnectionNode
	local Connection = {}
	Connection.Connected = false
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
	
	return Connection :: ConnectionNode
end

function Signal:Once(Function): ConnectionNode
	local Connection: ConnectionNode = nil
	Connection = self:Connect(function(...)
		Connection:Disconnect()
		return Function(...)
	end)
	return Connection
end

function Signal:Wait(): (...any)
	local CurrentThread = coroutine.running()
	self:Once(function(...)
		if coroutine.status(CurrentThread) == "suspended" then
			task.spawn(CurrentThread, ...)
		end
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
