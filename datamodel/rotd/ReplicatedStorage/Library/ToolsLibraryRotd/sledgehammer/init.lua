local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Melee";
	HandlerType="MeleeTool";

	Animations={
		Core={Id=16971466256;};
		Load={Id=16971470417;};
		PrimaryAttack={Id=77333142865939};
		ComboAttack3={Id=16971481755};
		Inspect={Id=16971479063;};
		Unequip={Id=16971484030};
	};
	Audio={
		Load={Id=4601593953; Pitch=1; Volume=2;};
		PrimaryHit={Id=4844105915; Pitch=1; Volume=2;};
		PrimarySwing={Id=4601593953; Pitch=1.4; Volume=2;};
	};
	
	Configurations={
		Category = "Blunt";
		Type="Sword";

		EquipLoadTime=1.4;
		Damage=800;

		PrimaryAttackSpeed=1;
		PrimaryAttackAnimationSpeed=0.43;

		HitRange=15;
		BaseKnockback=70;

		Combos = {
			[3]={TimeSlot=3; ResetCombo=true; AnimationSpeed=1.38;}; -- Every third attack within 3 seconds
		};

		StaminaCost = 35;
		StaminaDeficiencyPenalty = 0.65;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;