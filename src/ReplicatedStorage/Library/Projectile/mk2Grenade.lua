local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modExplosionHandler = require(game.ReplicatedStorage.Library.ExplosionHandler);

local Projectile = require(script.Parent.Projectile);

local projectilePrefab = script.Grenade;
--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		Velocity=100;
		Bounce=0.6;
		LifeTime=20;
		MaxBounce=8;
	}
	
	function projectile:Activate()
		task.delay(self.Configurations.DetonateTimer, function()
			modAudio.Play(math.random(1,2)==1 and "Explosion" or "Explosion2", self.Prefab);
			self.Prefab.Transparency = 1;

			if not RunService:IsServer() then return end;
			local lastPosition = self.Prefab.Position;
			
			local ex = Instance.new("Explosion");
			ex.DestroyJointRadiusPercent = 0;
			ex.BlastRadius = 35;
			ex.BlastPressure = 0;
			ex.Position = lastPosition;
			ex.Parent = workspace;
			Debugger.Expire(ex, 1);
			self.Prefab.Transparency = 1;
			
			
			local hitLayers = modExplosionHandler:Cast(lastPosition, {
				Radius = self.Configurations.ExplosionRadius;
			});

			local damage = self.Configurations.Damage;
			local minDamage = self.Configurations.MinDamage;
			local explosionStun = self.Configurations.ExplosionStun;
			local damageRatio = self.Configurations.DamageRatio;

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
			
		end)
	end	
	
	function projectile:OnContact(arcPoint)
		local _hitPart = arcPoint.Hit;
		modAudio.Play("GrenadeBounce", self.Prefab);
	end
	
	return projectile;
end

return Pool;