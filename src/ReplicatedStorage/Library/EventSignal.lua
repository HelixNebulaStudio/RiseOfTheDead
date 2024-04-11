local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
type EventSignalClass = {
	__index: EventSignalClass;
	ClassName: string;

	new: (name: string) -> EventSignal;
	Fire: (...any) -> nil;
	Wait: (timeout: number) -> ...any;
	Connect: (self: EventSignal, () -> nil) -> (() -> nil);
	Disconnect: (self: EventSignal, () -> nil) -> nil;
	Once: (self: EventSignal, () -> nil) -> (() -> nil);
	Destroy: (self: EventSignal) -> nil;
	DisconnectAll: (self: EventSignal) -> nil;
};

type EventSignalObject = {
	Name: string?;
};

local EventSignal: EventSignalClass = {} :: EventSignalClass;
EventSignal.__index = EventSignal;
EventSignal.ClassName = "EventSignal";

function EventSignal.new(name: string?)
	local self = {
		Name = name;
	};
	
	setmetatable(self :: EventSignalObject, EventSignal);
	return self;
end

function EventSignal:Fire(...)
	for index = #self, 1, -1  do
		if type(self[index]) == "function" then
			task.spawn(self[index], ...);

		elseif self[index] == nil then
			--Debugger:Log(self.Name..":Fire>> function index nil", index, ":", type(self[index]));
		else
			--Debugger:Log(self.Name..":Fire>> Not function index", index, ":", type(self[index]));
		end
	end
end

function EventSignal:Wait(timeOut) : ...any
	local Thread = coroutine.running()
	
	local ran = false;
	local function Yield(...)
		ran = true;
		self:Disconnect(Yield)
		task.spawn(Thread, ...);
	end

	table.insert(self, Yield);
	
	if timeOut then
		task.delay(timeOut, function()
			if ran then return end;
			Yield();
		end);
	end
	return coroutine.yield()
end

function EventSignal:Connect(Function) : () -> nil
	table.insert(self, Function);
	return function()
		self:Disconnect(Function);
	end
end

function EventSignal:Disconnect(Function) : nil
	local Length = #self

	for index = Length, 1, -1 do
		if Function == self[index] then
			table.remove(self, index);
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
	
	table.insert(self, func);
	return function()
		self:Disconnect(func);
		return;
	end
end

function EventSignal:Destroy() : nil
	table.clear(self);
	return;
end

function EventSignal:DisconnectAll() : nil
	for index = 1, #self do
		self[index] = nil;
	end
	return;
end

export type EventSignal = typeof(setmetatable({} :: EventSignalObject, {} :: EventSignalClass));
return EventSignal;