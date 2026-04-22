local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

--==
local Hazard = {
	Title = "Contagious Ticks";
	Description = "Dying enemies will cause a Tick Combustion.";
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
	local controller = self.Controller;
	controller.StageGarbage:Tag(controller.OnSurvivalNpcSpawn:Connect(function(npcClass: NpcClass)
        if npcClass.HumanoidType ~= "Zombie" then return end;
        if npcClass.Properties.BasicEnemy ~= true then return end;
		if npcClass.Name == "Ticks" then return end;

		local tickCombustionComp = npcClass:AddComponent("TickCombustion");
		if tickCombustionComp == nil then return end;

    end))
end

function Hazard:Tick()

end

function Hazard:End()
	
end

return Hazard;
