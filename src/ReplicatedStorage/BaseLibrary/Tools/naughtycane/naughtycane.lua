local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);
--==
return function()
	local Melee = {};
	Melee.Class = "Melee";
	
	Melee.Configurations = {
		Type="Sword";
		EquipLoadTime=0.5;
		BaseDamage=520;
		
		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=0.3;
		
		HitRange=13;
		BaseKnockback=80;
		
		WaistRotation=math.rad(75);
		
		StaminaCost = 16;
		StaminaDeficiencyPenalty = 0.65;
	};
	
	Melee.OnEnemyHit = function(toolHandler, targetModel, damage)
		if damage <= 0 then return end;
		
	end
	
	Melee.Properties = {
		Attacking=false;
	}
	
	return modMeleeProperties.new(Melee);
end;