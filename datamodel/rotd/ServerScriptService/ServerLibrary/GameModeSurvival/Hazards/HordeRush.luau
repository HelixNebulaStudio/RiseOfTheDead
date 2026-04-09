local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

--==
local Hazard = {
	Title = "Horde Rush";
	Description = "Zombies sprint when they spawn!";
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

		local targetHandlerComp = npcClass:GetComponent("TargetHandler");
		if targetHandlerComp == nil then return end;

		targetHandlerComp.OnTargetUpdate:Once(function()
			npcClass.Move:SetMoveSpeed("set", "sprint", 50, npcClass.Move.MoveSpeedPriority.Action, 5);
		end)
    end))
end

function Hazard:Tick()
end

function Hazard:End()
end

return Hazard;
