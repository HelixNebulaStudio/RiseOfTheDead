return function()
	local Tool = {};
	
	Tool.Configurations = {
		Velocity = 200;
		ChargeDuration = 0.2;
		VelocityBonus = 50;
		
		--== Projectile
		ProjectileId = "snowball";
		ProjectileBounce = 0;
		ProjectileLifeTime = 20;
		ProjectileKeepAcceleration=true;
		IgnoreWater=false;
		
		ConsumeOnThrow=false;
	};
	
	return Tool;
end;
