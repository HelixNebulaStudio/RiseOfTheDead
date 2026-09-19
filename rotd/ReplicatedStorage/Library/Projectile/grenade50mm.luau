local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 150;
		Bounce = 0.35;
		MaxBounce = 8;
		LifeTime = 10;
		Acceleration = Vector3.new(0, -workspace.Gravity/8, 0);
		RayRadius = 0.25;
	};

	Properties = {
		DetonateTimer = 2;
		ExplosionRadius = 35;
		Damage = 100;
		MinDamage = 100;
		ExplosionStun = 1;
		DamageRatio = 0.05;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("Grenade"):Clone();
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
	local hitPart = arcPoint.Hit;

	modAudio.Play("GrenadeBounce", projectile.Part);

	local targetModel = hitPart.Parent;
	local healthComp: HealthComp? = modHealthComponent.getByModel(targetModel);

	local properties = projectile.Properties;
	local projectilePart = projectile.Part;

	local timer = healthComp and 0 or 1;
	task.delay(timer, function()
		if properties.Activated then return end;
		properties.Activated = true;
		
		projectilePart.Transparency = 1;
		Debugger.Expire(projectilePart, 0.1);
		
		if not RunService:IsServer() then return end;

		local lastPosition = projectilePart.Position;
		
		local pointAtt = Debugger:Point(lastPosition);
		modAudio.Play(math.random(1,2)==1 and "Explosion" or "Explosion2", pointAtt);
		local ex = Instance.new("Explosion");
		ex.DestroyJointRadiusPercent = 0;
		ex.BlastRadius = properties.ExplosionRadius or 20;
		ex.BlastPressure = 0;
		ex.Position = lastPosition;
		ex.Parent = workspace;
		Debugger.Expire(pointAtt, 10);
		Debugger.Expire(ex, 10);
		

		local hitLayers = modExplosionHandler:Cast(lastPosition, {
			Radius = properties.ExplosionRadius or 20;
		});

		local damage = properties.Damage;
		local explosionStun = properties.ExplosionStun;
		local damageRatio = properties.DamageRatio;

		modExplosionHandler:Process(lastPosition, hitLayers, {
			ExplosionBy = projectile.CharacterClass;
			StorageItem = projectile.StorageItem;

			Damage = damage;
			SplitDamageMode = "PerLayer";
			ExplosionStun = explosionStun;
			DamageRatio = damageRatio;

			DamageOrigin = lastPosition;
			OnPartHit = modExplosionHandler.GenericOnPartHit;

			BindDamageDataNew = function(dmgData: DamageData)
				projectile:PreTakeDamageDamageData(dmgData);
			end;
		});
		
	end)

end

return projectilePackage;