local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);
--==
return function()
	local Melee = {};
	Melee.Class = "Melee";
	
	Melee.Configurations = {
		Type="Sword";
		EquipLoadTime=0.5;
		BaseDamage=200;
		
		PrimaryAttackSpeed=0.4;
		PrimaryAttackAnimationSpeed=0.2;
		
		HitRange=8;
		BaseKnockback=100;
		
		--WaistRotation=math.rad(75);
		StaminaCost = 10;
		StaminaDeficiencyPenalty = 0.5;
	};
	
	Melee.OnEnemyHit = function(toolHandler, targetModel, damage)
		if damage <= 0 then return end;
		
	end
	
	Melee.Properties = {
		Attacking=false;
	}
	
	return modMeleeProperties.new(Melee);
end;