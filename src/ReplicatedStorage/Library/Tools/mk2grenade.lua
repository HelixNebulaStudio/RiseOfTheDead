return function()
	local Tool = {};
	
	Tool.Configurations = {
		ExplosionRadius = 35;
		DamageRatio = 0.05;
		MinDamage = 100;
		
		Velocity = 160;
		ProjectileBounce = 0.6;
		ChargeDuration = 0.65;
		VelocityBonus = 40;
		
		--== Projectile
		ProjectileId = "mk2Grenade";
		ProjectileLifeTime = 20;
		DetonateTimer = 2;
		
		ConsumeOnThrow=true;
	};
	
	return Tool;
end;