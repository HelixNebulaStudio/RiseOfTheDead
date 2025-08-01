local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Melee";
	HandlerType="MeleeTool";

	Animations={
		Core={Id=16904172089;};
		Load={Id=16904173371;};
		PrimaryAttack={Id={85153211105334; 136133793967029}};
		HeavyAttack={Id=4473902088};
		Inspect={Id=16904175486; WaistStrength=0.2;};
		Unequip={Id=16904176888};
	};
	Audio={
		Load={Id=2304904662; Pitch=0.6; Volume=0.5;};
		PrimaryHit={Id=8814671013; Pitch=1; Volume=1;};
		PrimarySwing={Id=158037267; Pitch=0.75; Volume=1;};
	};
	
	Configurations={
		Category = "Blunt";
		Type="Tool";

		EquipLoadTime=0.5;
		Damage=400;

		PrimaryAttackSpeed=0.3;
		PrimaryAttackAnimationSpeed=0.3;

		HitRange=12.5;
		BaseKnockback=50;

		WaistRotation=math.rad(0);

		StaminaCost = 13;
		StaminaDeficiencyPenalty = 0.6;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;