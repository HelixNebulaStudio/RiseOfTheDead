return function()
	local Tool = {};
	
	Tool.Configurations = {
		ExplosionRadius = 35;
		DamageRatio = 0.05;
		MinDamage = 100;
		
		Velocity = 160;
		ProjectileBounce = 0;
		ChargeDuration = 0.7;
		VelocityBonus = 40;
		
		--== Projectile
		ProjectileId = "stickyGrenade";
		ProjectileLifeTime = 20;
		DetonateTimer = 3;
		
		ConsumeOnThrow=true;
	};
	
	return Tool;
end;
