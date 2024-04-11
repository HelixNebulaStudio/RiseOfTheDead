--!strict
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local EventSignal = {};
EventSignal.__index = EventSignal;
EventSignal.ClassName = "EventSignal";

type EventSignalObject = {
	Name: string?;
	Functions: {[number]: (...any)->(...any)};
}
export type EventSignal = typeof(setmetatable({} :: EventSignalObject, EventSignal));

--
function EventSignal.new(name: string?) : EventSignal
	local self = {
		Name = name;
		Functions = {};
	};

	setmetatable(self, EventSignal);
	return self;
end

function EventSignal:Fire(...) : nil
	for index = #self.Functions, 1, -1  do
		if typeof(self.Functions[index]) ~= "function" then continue end;
		task.spawn(self.Functions[index], ...);
	end
	return;
end

function EventSignal:Wait(timeOut) : ...any
	local Thread = coroutine.running()
	
	local ran = false;
	local function Yield(...)
		ran = true;
		self:Disconnect(Yield)
		task.spawn(Thread, ...);
	end

	table.insert(self.Functions, Yield);
	
	if timeOut then
		task.delay(timeOut, function()
			if ran then return end;
			Yield();
		end);
	end
	return coroutine.yield()
end

function EventSignal:Connect(func: (...any) -> ...any) : () -> nil
	table.insert(self.Functions, func);
	return function()
		self:Disconnect(func);
	end
end

function EventSignal:Disconnect(Function) : nil
	local Length = #self.Functions

	for index = Length, 1, -1 do
		if Function == self.Functions[index] then
			table.remove(self.Functions, index);
			break;
		end
	end

	return;
end

function EventSignal:Once(Function) : () -> nil
	local func;
	
	func = function(...)
		Function(...)
		self:Disconnect(func);
	end
	
	table.insert(self.Functions, func);
	return function()
		self:Disconnect(func);
		return;
	end
end

function EventSignal:Destroy() : nil
	table.clear(self.Functions);
	return;
end

function EventSignal:DisconnectAll() : nil
	for index = 1, #self.Functions do
		self.Functions[index] = nil;
	end
	return;
end

return EventSignal;