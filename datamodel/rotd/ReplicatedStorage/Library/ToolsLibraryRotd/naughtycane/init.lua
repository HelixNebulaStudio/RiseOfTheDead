local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Melee";
	HandlerType="MeleeTool";

	Animations={
		Core={Id=16971651562;};
		PrimaryAttack={Id=102007195486358};
		Load={Id=16971653858;};
		Inspect={Id=16971657001; WaistStrength=0.2;};
		Unequip={Id=16971658803;};
	};
	Audio={
		Load={Id=4601593953; Pitch=1; Volume=2;};
		PrimaryHit={Id=4602930505; Pitch=1; Volume=2;};
		PrimarySwing={Id=4601593953; Pitch=1; Volume=2;};
	};
	
	Configurations={
		Category = "Blunt";
		Type="Sword";

		EquipLoadTime=0.5;
		Damage=520;

		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=0.3;

		HitRange=13;
		BaseKnockback=80;

		WaistRotation=math.rad(75);
		FirstPersonWaistOffset=math.rad(-30);

		StaminaCost = 16;
		StaminaDeficiencyPenalty = 0.65;
		
		DamageBlock = 25;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;