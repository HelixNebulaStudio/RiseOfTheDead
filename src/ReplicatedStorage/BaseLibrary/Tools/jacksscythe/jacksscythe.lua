local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);
--==
return function()
	local Melee = {};
	Melee.Class = "Melee";

	Melee.Holster = {
		RightSwordAttachment={PrefabName="jacksscythe"; Offset=CFrame.new(0.800000012, 0.800000012, 0, -1, 8.74227766e-08, 0, -8.74227766e-08, -1, 0, 0, 0, 1);}; -- Use `Offset` attribute to adjust
	}
	
	Melee.Configurations = {
		Type="Sword";
		EquipLoadTime=1.5;
		BaseDamage=280;

		PrimaryAttackSpeed=0.8;
		PrimaryAttackAnimationSpeed=0.7;

		HeavyAttackMultiplier=2;
		HeavyAttackSpeed=2;
		HitRange=15;
		
		WaistRotation=math.rad(0);

		StaminaCost = 14;
		StaminaDeficiencyPenalty = 0.8;
	};
	
	Melee.Properties = {
		Attacking=false;
	}
	
	return modMeleeProperties.new(Melee);
end;
