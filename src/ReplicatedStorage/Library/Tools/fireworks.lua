return function()
	local Tool = {};
	
	Tool.Configurations = {
		Damage = 50;
		
		Velocity = 100;
		ProjectileBounce = 0;
		VelocityBonus = 40;
		
		--== Projectile
		ProjectileId = "firework";
		ProjectileLifeTime = 10;
		ProjectileAcceleration = Vector3.new(0, 296.2, 0);
		ProjectileKeepAcceleration = true;

		ThrowingMode="Directional";
		
		--ShowFocusTraj=false;
		ConsumeOnThrow=true;
	};
	
	return Tool;
end;