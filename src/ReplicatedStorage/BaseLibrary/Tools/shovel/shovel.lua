local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);
--==
return function()
	local Melee = {};
	Melee.Class = "Melee";
	
	Melee.Configurations = {
		Type="Sword";
		EquipLoadTime=0.5;
		BaseDamage=400;
		
		PrimaryAttackSpeed=0.3;
		PrimaryAttackAnimationSpeed=0.3;
		
		HitRange=12.5;
		BaseKnockback=50;
		
		WaistRotation=math.rad(0);
		
		StaminaCost = 13;
		StaminaDeficiencyPenalty = 0.6;
	};
	
	Melee.Properties = {
		Attacking=false;
	}
	
	return modMeleeProperties.new(Melee);
end;