local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);
--==
return function()
	local Melee = {};
	Melee.Class = "Melee";
	
	Melee.Configurations = {
		Type="Spear";
		EquipLoadTime=0.5;
		BaseDamage=240;
		
		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=0.3;
		
		HitRange=16;
		WaistRotation=math.rad(80);
		StaminaCost = 6;
		StaminaDeficiencyPenalty = 0.6;
		
		-- Throwable
		Throwable = true;
		DamagePercent = 0.02;
		
		Velocity = 200;
		ProjectileBounce = 0;
		ChargeDuration = 2;
		VelocityBonus = 100;
		
		ThrowRate = 1;
		ThrowWaistRotation=math.rad(35);
		
		--== Projectile
		ProjectileId = "broomSpear";
		ProjectileLifeTime = 30;
		
		ConsumeOnThrow=false;
	};
	
	Melee.Properties = {
		Attacking=false;
	}
	
	return modMeleeProperties.new(Melee);
end;
