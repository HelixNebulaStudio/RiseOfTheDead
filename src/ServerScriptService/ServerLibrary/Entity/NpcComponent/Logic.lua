local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local RunService = game:GetService("RunService");
local modScheduler = require(game.ReplicatedStorage.Library.Scheduler);
local globalScheduler = modScheduler:GetGlobal();

--== Script;
local Logic = {};
Logic.__index = Logic;

function Logic:Resume(...)
	if #self.Tasks > 0 then
		globalScheduler:Resume(table.remove(self.Tasks, 1), true);
		--table.remove(self.Tasks, 1);
	end
	
end

function Logic:Wait(timeout) -- returns value after yield
	if self.Npc.IsDead then return end;
	
	local job = globalScheduler:Schedule(coroutine.running(), tick() + (timeout or 0));
	table.insert(self.Tasks, job);
	
	coroutine.yield(job);

	local a = table.find(self.Tasks, job);
	if a then table.remove(self.Tasks, a) end;
	
	return;
end

function Logic:AddAction(name, begin, cancel)
	self.Actions[name] = {
		Begin=begin;
		Cancel=cancel;
	};
end

function Logic:ClearAll()
	if self.Npc.Movement and self.Npc.Movement.MovementStatus and self.Npc.Movement.MovementStatus.Destroy then
		self.Npc.Movement.MovementStatus:Destroy();
	end
	for a=1, #self.Tasks do
		local job = self.Tasks[a];
		if job then
			globalScheduler:Resume(job, true);
		end
		self.Tasks[a] = nil;
	end
	
end

function Logic:Action(name, ...)
	if self.Npc.IsDead then return end;
	local action = name and self.Actions[name]
	if action then
		action.Begin(...);
	end
end

function Logic:SetState(state)
	if state == self.State then return end;
	
	self.State = state or "None";
	self:ClearAll();
end

function Logic:Timeout(state, timeout, func)
	if self.Npc.IsDead then return; end;
	if self.State ~= state then return end;
	
	self:Wait(timeout);
	
	if self.Npc.IsDead then return; end;
	if self.State ~= state then return end;
	
	if func then func(); end
end

function Logic.new(Npc)
	local self = {
		Npc = Npc;
		Tasks={};
		Actions={};
		State="None";
	};
	
	setmetatable(self, Logic);
	return self;
end

return Logic;