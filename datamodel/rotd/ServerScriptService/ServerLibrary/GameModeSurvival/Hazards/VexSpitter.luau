local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local Hazard = {
	Title = "Vex Spitters";
	Description = "They spit volatile blob at you!";
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

	local controller = self.Controller;
	controller.StageGarbage:Tag(controller.OnSurvivalNpcDeath:Connect(function(npcClass: NpcClass) 
		if npcClass == nil or npcClass.HumanoidType ~= "Zombie" then return end;
		local rawProperties: anydict = npcClass.Properties.Values;
		local deathPosition = rawProperties.DeathPosition;
		if deathPosition == nil then return end;

		self.Counter = self.Counter+1;

		if self.Counter >= 10 then
			self.Counter = 0;
			if math.random(1, 2) ~= 1 then return end;

			shared.modNpcs.spawn2{
				Name = "Vex Spitter";
				CFrame = CFrame.new(deathPosition);
				Properties = {
					Level = rawProperties.Level;
				};
				BindSetup = function(npcClass: NpcClass)
				end;
			};
		end
	end))
end

function Hazard:Tick()

end

function Hazard:End()
end

return Hazard;
