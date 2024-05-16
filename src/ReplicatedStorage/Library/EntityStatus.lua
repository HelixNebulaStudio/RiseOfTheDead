local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modScheduler = require(game.ReplicatedStorage.Library.Scheduler);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);

--==
local EntityStatus = {};
EntityStatus.__index = EntityStatus;
EntityStatus.ClassName = "EntityStatus";
export type EntityStatus = typeof(EntityStatus);

EntityStatus.Scheduler = modScheduler.new("EntityStatus");
EntityStatus.Scheduler.Rate = 1/15;

function EntityStatus.new(preData)
	local self = {
		List = {};
		ActiveJob = nil;
		OnProcess = modEventSignal.new("OnEntityStatusProcess");
	};
	
	if preData then
		for k, v in pairs(preData) do
			self[k] = v;
		end
	end
	
	setmetatable(self, EntityStatus);
	return self;
end

function EntityStatus:GetOrDefault(k, v)
	if self.List[k] then return self.List[k] end;
	if v == nil then return end;
	
	self:Apply(k, v);
	return v;
end

function EntityStatus:Apply(k, v)
	self.List[k] = v;
	
	self:Process();
	return v;
end

function EntityStatus:Process()
	local currTick = tick();
	local earliestExpireTime = nil;
	local processed = false;

	for k, v in pairs(self.List) do
		if typeof(v) ~= "table" then continue end;
		
		local status = v;
		if status.Expires then
			if currTick > status.Expires then
				if status.OnExpire then
					status.OnExpire();
				end
				self.List[k] = nil;
				processed = true;
				
			elseif (earliestExpireTime == nil or v.Expires < earliestExpireTime) then
				earliestExpireTime = v.Expires;
				
			end
		end
	end
	
	if earliestExpireTime and (self.ActiveJob == nil or self.ActiveJob.T > earliestExpireTime) then
		if self.ActiveJob then
			self.Scheduler:Unschedule(self.ActiveJob);
		end
		
		self.ActiveJob = self.Scheduler:ScheduleFunction(function()
			self.ActiveJob = nil;
			self:Process();
		end, earliestExpireTime);
		
	end
	if processed then
		self.OnProcess:Fire();
	end
end

function EntityStatus:Destroy()
	if self.ActiveJob then
		self.Scheduler:Unschedule(self.ActiveJob);
		self.ActiveJob = nil;
	end;
	if self.OnProcess then
		self.OnProcess:Destroy();
		self.OnProcess = nil;
	end
end

return EntityStatus;