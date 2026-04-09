local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

--==
local Hazard = {
	Title = "Shiv Shank";
	Description = "Some zombies have knifes!";
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
        if npcClass.Name ~= "Zombie" then return end;
        if npcClass.Properties.BasicEnemy ~= true then return end;

		npcClass.Configurations.AttackSpeed = 1;
		npcClass.WieldComp:Equip{
			ItemId = "survivalknife";
			OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
				local equipmentClass: EquipmentClass? = toolHandler.EquipmentClass;
				if equipmentClass == nil then return end;

				equipmentClass:AddBaseModifier("ZombieMelee", {
					SetValues = {
						Damage = 10;
					};
				});
			end;
		}
    end))
end

function Hazard:Tick()
end

function Hazard:End()
end

return Hazard;
