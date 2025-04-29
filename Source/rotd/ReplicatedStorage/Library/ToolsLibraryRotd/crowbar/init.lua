local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="MeleeTool";

	Animations={
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
	
	Configurations={
		Category = "Blunt";
		Type="Tool";
		EquipLoadTime=0.5;
		Damage=200;

		PrimaryAttackSpeed=0.4;
		PrimaryAttackAnimationSpeed=0.2;

		HitRange=8;
		BaseKnockback=100;

		StaminaCost = 10;
		StaminaDeficiencyPenalty = 0.5;
	};
	Properties={};

};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;