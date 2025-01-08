local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations=workspace:GetAttribute("IsDev") and {
		Core={Id=16893811326;};
		PrimaryAttack={Id=133825074697678};
		Inspect={Id=16893818098;};
		Load={Id=16893815376;};
		Unequip={Id=16893819869};
		
	} or {
		Core={Id=16893811326;};
		PrimaryAttack={Id=133825074697678};
		Inspect={Id=16893818098;};
		Load={Id=16893815376;};
		Unequip={Id=16893819869};
		
	};
	Audio={
		Load={Id=4601593953; Pitch=1; Volume=2;};
		PrimaryHit={Id=4844105915; Pitch=1; Volume=2;};
		PrimarySwing={Id=4601593953; Pitch=1.4; Volume=2;};
	};
};

--==
local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);

function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.Class = "Melee";
	Tool.Category = "Blunt";

	Tool.Configurations = {
		Type="Sword";
		EquipLoadTime=0.5;
		BaseDamage=200;

		PrimaryAttackSpeed=0.4;
		PrimaryAttackAnimationSpeed=0.2;

		HitRange=8;
		BaseKnockback=100;

		StaminaCost = 10;
		StaminaDeficiencyPenalty = 0.5;
	};

	Tool.OnEnemyHit = function(toolHandler, targetModel, damage)
		if damage <= 0 then return end;

	end

	Tool.Properties = {
		Attacking=false;
	}
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return modMeleeProperties.new(Tool);
end

return toolPackage;