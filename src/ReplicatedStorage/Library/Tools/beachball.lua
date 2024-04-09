return function()
	local Tool = {};
	
	Tool.Configurations = {
		Damage = 100;
		
		Velocity = 50;
		ProjectileBounce = 0.9;
		ChargeDuration = 1;
		VelocityBonus = 100;
		
		WaistRotation = math.rad(0);
		ThrowRate = 2;
		
		--== Projectile
		ProjectileId = "beachball";
		ProjectileLifeTime = 10;
		
		ConsumeOnThrow=false;
	};
	
	return Tool;
end;