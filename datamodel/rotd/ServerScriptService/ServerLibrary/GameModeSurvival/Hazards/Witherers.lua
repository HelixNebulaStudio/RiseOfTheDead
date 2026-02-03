local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

--==
local Hazard = {
	Title = "Witherers";
	Controller = nil;
};
Hazard.__index = Hazard;
--==

function Hazard.new()
	local self = {};
	
	setmetatable(self, Hazard);
	return self;
end

function Hazard:Load()
end

function Hazard:Begin()
	self.Counter = 0;

	self.OnZombieDeathDisconnect = self.Controller.OnNpcDeath:Connect(function(npcClass: NpcClass) 
		if npcClass == nil or npcClass.HumanoidType ~= "Zombie" then return end;
		local rawProperties: anydict = npcClass.Properties.Values;
		local deathPosition = rawProperties.DeathPosition;
		if deathPosition == nil then return end;

		self.Counter = self.Counter+1;

		if self.Counter >= 20 then
			self.Counter = 0;

			shared.modNpcs.spawn2{
				Name = "Witherer";
				CFrame = CFrame.new(deathPosition);
				BindSetup = function(npcClass: NpcClass)
					npcClass.Properties.Level = rawProperties.Level;
				end;
			};
		end
	end)
end

function Hazard:Tick()

end

function Hazard:End()
	if self.OnZombieDeathDisconnect then
		Debugger:Warn("OnZombieDeathDisconnect")
		self.OnZombieDeathDisconnect();
	end
end

return Hazard;
