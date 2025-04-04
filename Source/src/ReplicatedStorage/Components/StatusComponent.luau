
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modScheduler = require(game.ReplicatedStorage.Library.Scheduler);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local modStatusLibrary = require(game.ReplicatedStorage.Library.StatusLibrary);
local modEntityComponentSystem = require(game.ReplicatedStorage.Library.EntityComponentSystem);

--==
local StatusComponent = {};
StatusComponent.__index = StatusComponent;
StatusComponent.ClassName = "StatusComponent";

StatusComponent.Scheduler = modScheduler.new("StatusComponent");
StatusComponent.Scheduler.Rate = 1/15;

local statusTickSystem = modEntityComponentSystem.newSystem(1/15);
statusTickSystem:Update(function(tickData: TickData, statusClass: StatusClassInstance)
	if statusClass.IsExpired then return end;
	
	statusClass:OnTick(tickData);
end)


function StatusComponent.new(ownerClass)
	local self = {
        OwnerClass = ownerClass;
		
		List = {};
		ActiveJob = nil;
		Disabled = false;

		OnProcess = modEventSignal.new("OnEntityStatusProcess");
	};
		
	setmetatable(self, StatusComponent);
	return self;
end

function StatusComponent:GetOrDefault(k, v)
	if self.Disabled then return end;
	if self.List[k] then return self.List[k] end;
	if v == nil then return end;
	
	self:Apply(k, v);
	return v;
end

function StatusComponent:Apply(key, value)
	if self.Disabled then return end;
	local oldValue = self.List[key];
	
	local statusLib = modStatusLibrary:Find(key);
	if statusLib then
		local statusClass: StatusClassInstance = self.List[key];
		
		if value == nil then
			self.List[key] = nil;

			if oldValue ~= nil then
				if statusClass.OnExpire then
					statusClass:OnExpire();
				end
				statusClass.Garbage:Destruct();
			end

			return;
		end

		-- Set
		if statusClass == nil then
			if statusLib.init then
				statusLib.init();
				statusLib.init = nil;
			end
			statusClass = statusLib:Instance(value, self);
		end
		self.List[key] = statusClass;

		statusClass.Duration = value.Duration or statusClass.Duration;
		statusClass.Expires = value.Expires or statusClass.Expires;

		if oldValue == nil and statusClass.OnApply then
			statusClass:OnApply();
		end
		if statusClass.OnTick then
			statusTickSystem:Add(statusClass);
		end

	else
		self.List[key] = value;
		
	end

	self:Process(true);
	return value;
end

function StatusComponent:Process(fireOnProcess)
	local earliestExpireTime = nil;
	local processed = false;

	for k, statusClass: StatusClassInstance in pairs(self.List) do
		if typeof(statusClass) ~= "table" then continue end;
		if statusClass.ClassName ~= "StatusClass" then return end;
	
        local isDead = false;

        local healthComp: HealthComp? = self.OwnerClass.HealthComp;
        if healthComp then
            isDead = healthComp.IsDead;
        end
        
        if (statusClass.ExpiresOnDeath and isDead) 
        or (statusClass.Expires and workspace:GetServerTimeNow() >= statusClass.Expires) then
            statusClass.IsExpired = true;

            if statusClass.OnTick then
                statusTickSystem:Remove(statusClass);
            end
            if statusClass.OnExpire then
                statusClass:OnExpire();
            end

            statusClass.Garbage:Destruct();
            self.List[k] = nil;
            processed = true;
        
        elseif statusClass.Expires and (earliestExpireTime == nil or statusClass.Expires < earliestExpireTime) then
            earliestExpireTime = statusClass.Expires;

        end
	end
	
	if earliestExpireTime and (self.ActiveJob == nil or self.ActiveJob.T > earliestExpireTime) then
		if self.ActiveJob then
			self.Scheduler:Unschedule(self.ActiveJob);
		end
		
		local nextScheduleTimeInTick = tick() + (earliestExpireTime - workspace:GetServerTimeNow());
		self.ActiveJob = self.Scheduler:ScheduleFunction(function()
			self.ActiveJob = nil;
			self:Process();
		end, nextScheduleTimeInTick);
	end

	if processed or fireOnProcess == true then
		self.OnProcess:Fire();
	end
end

function StatusComponent:Destroy()
	if self.ActiveJob then
		self.Scheduler:Unschedule(self.ActiveJob);
		self.ActiveJob = nil;
	end;
	if self.OnProcess then
		self.OnProcess:Destroy();
		self.OnProcess = nil;
	end
end

return StatusComponent;