local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity=100;
		Bounce=0.6;
		LifeTime=20;
		MaxBounce=8;
		Delta=1/60;
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

function projectilePackage.BindFire(projectile: ProjectileInstance)
	local toolHandler: ToolHandlerInstance? = projectile.ToolHandler;

	local properties: PropertiesVariable<{
		DetonateTimer: number;
		ExplosionRadius: number;
		Damage: number;
		MinDamage: number;
		ExplosionStun: number;
		DamageRatio: number;
	}> = projectile.Properties;

	local detonateTimer = properties.DetonateTimer;
	local explosionRadius = properties.ExplosionRadius;
	local damage = properties.Damage;
	local minDamage = properties.MinDamage;
	local explosionStun = properties.ExplosionStun;
	local damageRatio = properties.DamageRatio;
	
	local part = projectile.Part;
	task.delay(detonateTimer, function()
		modAudio.Play(math.random(1,2)==1 and "Explosion" or "Explosion2", part);
		part.Transparency = 1;
		projectile.Properties.IsExploded = true;

		if not RunService:IsServer() then return end;
		local lastPosition = part.Position;
		
		local ex = Instance.new("Explosion");
		ex.DestroyJointRadiusPercent = 0;
		ex.BlastRadius = 35;
		ex.BlastPressure = 0;
		ex.Position = lastPosition;
		ex.Parent = workspace;
		Debugger.Expire(ex, 1);
		part.Transparency = 1;
		
		
		local hitLayers = modExplosionHandler:Cast(lastPosition, {
			Radius = explosionRadius;
		});

		modExplosionHandler:Process(lastPosition, hitLayers, {
			ExplosionBy = projectile.CharacterClass;
			StorageItem = projectile.StorageItem;

			Damage = damage;
			MinDamage = minDamage;
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

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
	if arcPoint.Hit == nil or projectile.Properties.IsExploded then return end;
	modAudio.Play("GrenadeBounce", projectile.Part);
end

return projectilePackage;