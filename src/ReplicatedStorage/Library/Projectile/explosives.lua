local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modExplosionHandler = require(game.ReplicatedStorage.Library.ExplosionHandler);

local Projectile = require(script.Parent.Projectile);

local projectilePrefab = script.Grenade;
local random = Random.new();

--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		Velocity=300;
		LifeTime=20;
		Bounce=0;
		Delta=1/60;
	};

	function projectile:Activate()
	end	
		
	local triggerOnce = false;
	function projectile:OnContact(arcPoint)
		if triggerOnce then return end;
		triggerOnce = true;
		
		modAudio.Play(random:NextInteger(1,2)==1 and "Explosion" or "Explosion2", self.Prefab);
		self.Prefab.Transparency = 1;
		
		if not RunService:IsServer() then return end;

		local damage = self.Configurations.Damage;
		local minDamage = self.Configurations.MinDamage or 50;
		local damageRatio = self.Configurations.DamageRatio or 0.1;
		local explosionRadius = self.Configurations.ExplosionRadius or 25;
		local explosionStun = self.Configurations.ExplosionStun;
		
		
		local lastPosition = arcPoint.Point;
		
		local ex = Instance.new("Explosion");
		ex.DestroyJointRadiusPercent = 0;
		ex.BlastRadius = explosionRadius;
		ex.BlastPressure = 0;
		ex.Position = lastPosition;
		ex.Parent = workspace;
		Debugger.Expire(ex, 1);
		self.Prefab.Transparency = 1;
		
		
		local hitLayers = modExplosionHandler:Cast(lastPosition, {
			Radius = explosionRadius;
		});
		
		modExplosionHandler:Process(lastPosition, hitLayers, {
			Owner = self.Owner;
			StorageItem = self.StorageItem;
			TargetableEntities = projectile.TargetableEntities;

			Damage = damage;
			MinDamage = minDamage;
			ExplosionStun = explosionStun;
			DamageRatio = damageRatio;

			DamageOrigin = lastPosition;
			OnPartHit=modExplosionHandler.GenericOnPartHit;
		});
		
	end
	
	return projectile;
end

return Pool;