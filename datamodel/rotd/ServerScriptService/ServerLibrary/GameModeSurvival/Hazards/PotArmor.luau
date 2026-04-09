local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

--==
local Hazard = {
	Title = "Pot Armor";
	Description = "They are wearing armor!";
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
        if math.random(1, 2) ~= 1 then return end;
        if npcClass.HumanoidType ~= "Zombie" then return end;
        if npcClass.Properties.BasicEnemy ~= true then return end;

        npcClass:AddComponent("PotArmor")(npcClass);
    end))
end

function Hazard:Tick()
end

function Hazard:End()
end

return Hazard;
