local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);
--==
return function()
	local Melee = {};
	Melee.Class = "Melee";
	
	Melee.UseViewmodel = false;
	
	Melee.Configurations = {
		Type="Sword";
		EquipLoadTime=0.5;
		BaseDamage=300;
		
		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=0.5;
		
		HitRange=8;
		--Knockback=100;
		
		WaistRotation=math.rad(0);
		StaminaCost = 25;
		StaminaDeficiencyPenalty = 0.5;
		
		-- Throwable
		Throwable = true;
		DamagePercent = 0.025;
		
		Velocity = 100;
		ChargeDuration = 2;
		VelocityBonus = 50;
		
		ThrowRate = 1;
		ThrowWaistRotation=math.rad(0);
		
		--== Projectile
		ProjectileId = "pickaxe";
		ProjectileBounce = 0;
		ProjectileLifeTime = 10;
		
		ConsumeOnThrow=false;
	};
	
	Melee.OnEnemyHit = function(toolHandler, targetModel, damage)
		if damage <= 0 then return end;
		
	end
	
	Melee.Properties = {
		Attacking=false;
	}
	
	return modMeleeProperties.new(Melee);
end;
