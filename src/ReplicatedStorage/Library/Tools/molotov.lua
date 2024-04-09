return function()
	local Tool = {};
	
	Tool.Configurations = {
		Damage = 5;
		
		Velocity = 140;
		ChargeDuration = 1;
		VelocityBonus = 60;
		
		--== Projectile
		ProjectileId = "molotov";
		ProjectileLifeTime = 30;
		ProjectileBounce = 0;
		IgnoreWater=false;
		
		ConsumeOnThrow=true;
	};
	
	return Tool;
end;