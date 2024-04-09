local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);
--==
return function()
	local Melee = {};
	Melee.Class = "Melee";
	
	Melee.Holster = {
		RightSwordAttachment={PrefabName="inquisitorssword"; Offset=CFrame.new(-0.600000024, -0.200000003, 0.5, -0.256916583, 0.344730973, 0.902859032, -0.383022249, 0.821393788, -0.42261824, -0.887292385, -0.454392731, -0.0789900571);}; -- Use `Offset` attribute to adjust
	}
	
	Melee.Configurations = {
		Type="Sword";
		EquipLoadTime=1.25;
		BaseDamage=640;
		
		PrimaryAttackSpeed=0.8;
		PrimaryAttackAnimationSpeed=0.7;
		
		HeavyAttackMultiplier=2;
		HeavyAttackSpeed=2;
		HitRange=15;
		
		WaistRotation=math.rad(0);
		
		StaminaCost = 10;
		StaminaDeficiencyPenalty = 0.8;
	};
	
	Melee.Properties = {
		Attacking=false;
	}
	
	return modMeleeProperties.new(Melee);
end;