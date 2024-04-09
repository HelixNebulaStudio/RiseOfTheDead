local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

--==

local function sort(a, b)
	if a == nil or b == nil then return true; end;
	if a.T == nil or b.T == nil then return true; end;
	return a.T < b.T;
end

--==
local Scheduler = {};
Scheduler.__index = Scheduler;

-- !outline: Scheduler.new
function Scheduler.new(name)
	local self = {
		Name = name;
		Queue = {};
		Rate = 1/60;
	};
	
	
	setmetatable(self, Scheduler);

	task.spawn(function()
		while true do
			task.wait(self.Rate);
			self:Stepped(); --schedulerStepped();
		end
	end)
	
	return self;
end

-- !outline: Scheduler:Stepped()
function Scheduler:Stepped()
	local overdue = self:GetOverdueTasks(tick(), true);

	for _, job in ipairs(overdue) do
		self:Resume(job);
	end
end

-- !outline: Scheduler:GetOverdueTasks(t, remove)
function Scheduler:GetOverdueTasks(t, remove)
	local t = t or tick();
	local overdue = {};

	for _, job in ipairs(self.Queue) do
		if job.T > t then break end;
		table.insert(overdue, job);
	end

	if remove then
		for i = 1, #overdue do
			table.remove(self.Queue, 1);
		end
	end

	return overdue;
end

-- !outline: Scheduler:Resume(job, remove)
function Scheduler:Resume(job, remove)
	if job == nil then return end;
	if remove then self:Unschedule(job) end

	if typeof(job.Routine) ~= "thread" then return end;

	local status = coroutine.status(job.Routine);
	if status ~= "suspended" then return end;

	local t = tick();
	local results = table.pack(coroutine.resume(job.Routine, table.unpack(job.Arguments, 1, job.Arguments.n)));
	
	if not results[1] then
		task.spawn(function()
			error("Scheduler("..self.Name..") Error: "..tostring(results[2]));
		end)
	end

	return table.unpack(results, 1, results.n)
end

-- !outline: Scheduler:Unschedule(job)
function Scheduler:Unschedule(job)
	local a = table.find(self.Queue, job);
	if a then table.remove(self.Queue, a) end

	return a ~= nil;
end

-- !outline: Scheduler:ScheduleFunction(func, t, ...)
function Scheduler:ScheduleFunction(func, t, ...)
	return self:Schedule(coroutine.create(func), t, ...);
end

-- !outline: Scheduler:SortSchedule()
function Scheduler:SortSchedule()
	local s, e = pcall(function()
		table.sort(self.Queue, sort);
	end)
	if not s then
		Debugger:Warn(e);
		Debugger:L(self.Queue);
	end
end

-- !outline: Scheduler:Schedule(routine, t, ...)
function Scheduler:Schedule(routine, t, ...)
	local job = {
		Routine=routine;
		T=t;
		Arguments=table.pack(...);
	}

	table.insert(self.Queue, job);
	self:SortSchedule();

	return job;
end

-- !outline: Scheduler:Wait(t, ...)
function Scheduler:Wait(t, ...)
	return coroutine.yield(self:Schedule(coroutine.running(), tick() + (t or 0), ...));
end

-- !outline: Scheduler:GetGlobal()
function Scheduler:GetGlobal()
	return Scheduler.new("Global");
end

return Scheduler;



--local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
----==
--local Scheduler = {};
--Scheduler.__index = Scheduler;
--Scheduler.Script = script;

----==
--local RunService = game:GetService("RunService");

--local random = Random.new();

--Scheduler.Queue = {};
--Scheduler.Stats = {};
--Scheduler.Rng = random:NextNumber();
----==
--local function sort(a, b)
--	if a == nil or b == nil then return true; end;
--	if a.T == nil or b.T == nil then return true; end;
--	return a.T < b.T;
--end

--function Scheduler:SortSchedule()
--	local s, e = pcall(function()
--		table.sort(self.Queue, sort);
--	end)
--	if not s then
--		Debugger:Warn(e);
--		Debugger:L(self.Queue);
--	end
--end

--function Scheduler:Schedule(routine, t, ...)
--	local job = {
--		Routine=routine;
--		T=t;
--		Arguments=table.pack(...);
--	}

--	table.insert(self.Queue, job);
--	self:SortSchedule();
	
--	script:SetAttribute("ScheduleQueue", #Scheduler.Queue);
	
--	return job;
--end

--function Scheduler:ScheduleFunction(func, t, ...)
--	return self:Schedule(coroutine.create(func), t, ...);
--end

--function Scheduler:Unschedule(job)
--	local i = table.find(self.Queue, job);
--	if i then table.remove(self.Queue, i) end

--	script:SetAttribute("ScheduleQueue", #Scheduler.Queue);
--	return i ~= nil;
--end

--function Scheduler:Resume(job, remove)
--	if job == nil then return end;
--	if remove then self:Unschedule(job) end
	
--	if typeof(job.Routine) ~= "thread" then return end;
	
--	local status = coroutine.status(job.Routine);
--	if status ~= "suspended" then return end;
	
--	local t = tick();
--	local results = table.pack(coroutine.resume(job.Routine, table.unpack(job.Arguments, 1, job.Arguments.n)));
	
	
	
--	if job.StatKey then
--		local timelapsed = (tick()-t)*1000;
--		self.Stats[job.StatKey] = ((self.Stats[job.StatKey] or timelapsed) + timelapsed)/2;
--		script:SetAttribute(job.StatKey, self.Stats[job.StatKey]);
--	end
	
--	if not results[1] then
--		task.spawn(function()
--			error("Task Error: "..tostring(results[2]));
--		end)
--	end

--	return table.unpack(results, 1, results.n)
--end

--function Scheduler:GetOverdueTasks(t, remove)
--	local t = t or tick();
--	local overdue = {};
	
--	for _, job in ipairs(self.Queue) do
--		if job.T > t then break end;
--		table.insert(overdue, job);
--	end
	
--	if remove then
--		for i = 1, #overdue do
--			table.remove(self.Queue, 1);
--		end
--	end

--	return overdue;
--end


--function Scheduler:Wait(t, ...)
--	return coroutine.yield(self:Schedule(coroutine.running(), tick() + (t or 0), ...));
--end

--local function schedulerStepped()
--	local overdue = Scheduler:GetOverdueTasks(tick(), true);
	
--	for _, job in ipairs(overdue) do
--		Scheduler:Resume(job);
--	end
--end

--task.spawn(function()
--	while true do
--		task.wait(1/60);
--		Scheduler.Rng = random:NextNumber();
--		schedulerStepped();
--	end
--end)

--return Scheduler;