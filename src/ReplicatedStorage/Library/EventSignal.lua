--local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local EventSignal = {};
EventSignal.__index = EventSignal
EventSignal.ClassName = "EventSignal"

function EventSignal.new(name)
	local self = {
		Name = name;
	};
	
	setmetatable(self, EventSignal);
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

function EventSignal:Wait(timeOut)
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

function EventSignal:Connect(Function)
	table.insert(self, Function);
	return function()
		self:Disconnect(Function);
	end
end

function EventSignal:Disconnect(Function)
	local Length = #self

	for index = Length, 1, -1 do
		if Function == self[index] then
			table.remove(self, index);
			break;
		end
	end
end

function EventSignal:Once(Function)
	local func;
	
	func = function(...)
		Function(...)
		self:Disconnect(func);
	end
	
	table.insert(self, func);
	return function()
		self:Disconnect(func);
	end
end

function EventSignal:Destroy()
	table.clear(self);
end

function EventSignal:DisconnectAll()
	for index = 1, #self do
		self[index] = nil;
	end
end

return EventSignal;