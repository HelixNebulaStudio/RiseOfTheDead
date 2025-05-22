local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="MeleeTool";

	Animations={
		Core={Id=16971427992;};
		Load={Id=16971430052;};
		PrimaryAttack={Id=16971425618};
		HeavyAttack={Id=16971437059};
		Inspect={Id=16971433041;};
		Unequip={Id=16971435376; Looped=false;};
	};
	Audio={
		Load={Id=2304904662; Pitch=0.6; Volume=0.5;};
		PrimaryHit={Id=4844105915; Pitch=1.4; Volume=1;};
		PrimarySwing={Id=4601593953; Pitch=1.4; Volume=1;};
		HeavySwing={Id=158037267; Pitch=0.70; Volume=1;};
	};
	
	Configurations={
		Category = "Edged";
		Type="Tool";
		EquipLoadTime=1;
		Damage=460;
		
		PrimaryAttackSpeed=1;
		--PrimaryAttackAnimationSpeed=0.4;

		HeavyAttackMultiplier=2.5;
		HeavyAttackSpeed=2;
		HitRange=15;

		WaistRotation=math.rad(0);

		StaminaCost = 18;
		StaminaDeficiencyPenalty = 0.8;
		
		BleedDamagePercent=0.1;
		BleedSlowPercent=0.2;
	};
	Properties={};
};

function toolPackage.newClass()
	local equipmentClass: EquipmentClass = modEquipmentClass.new(toolPackage);

	equipmentClass:AddModifier("AxeOfFire", {
		SetValues={
			AxeOfFireIgnitionChance = 0.66;
			AxeOfFireDamage = 50;
			AxeOfFireDuration = 5;
			AxeOfFireUseCurrentHpDmg = true;
		};
	});

	return equipmentClass;
end

return toolPackage;