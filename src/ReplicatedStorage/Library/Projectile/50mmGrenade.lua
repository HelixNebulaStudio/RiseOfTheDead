local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");

local Projectile = require(script.Parent.Projectile);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modExplosionHandler = require(game.ReplicatedStorage.Library.ExplosionHandler);

local grenadePrefab = script.Grenade;
--== Script;
function Pool.new()
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = grenadePrefab:Clone();
	
	projectile.ArcTracerConfig = {
		Velocity=150;
		Bounce=0.35;
		MaxBounce=8;
		LifeTime=10;
		Acceleration=Vector3.new(0, -workspace.Gravity/8, 0);
		RayRadius=0.25;
	}
	
	function projectile:Activate()
		Debugger.Expire(self.Prefab, self.ArcTracerConfig.LifeTime);
	end
		
	local activated = false;
	function projectile:OnContact(arcPoint)
		local hitPart = arcPoint.Hit;
		if hitPart == nil then return end;
		
		modAudio.Play("GrenadeBounce", self.Prefab);
		
		local targetModel = hitPart.Parent;
		local damagable = modDamagable.NewDamagable(targetModel);
		
		local timer = damagable and 0 or 1;
		task.delay(timer, function()
			if activated then return end;
			activated = true;
			
			self.Prefab.Transparency = 1;
			Debugger.Expire(self.Prefab, 0.1);
			
			if not RunService:IsServer() then return end;

			local lastPosition = self.Prefab.Position;
			
			local pointAtt = Debugger:Point(lastPosition);
			modAudio.Play(math.random(1,2)==1 and "Explosion" or "Explosion2", pointAtt);
			local ex = Instance.new("Explosion");
			ex.DestroyJointRadiusPercent = 0;
			ex.BlastRadius = self.Configurations.ExplosionRadius or 20;
			ex.BlastPressure = 0;
			ex.Position = lastPosition;
			ex.Parent = workspace;
			Debugger.Expire(pointAtt, 10);
			Debugger.Expire(ex, 10);
			

			local hitLayers = modExplosionHandler:Cast(lastPosition, {
				Radius = self.Configurations.ExplosionRadius or 20;
			});

			local damage = self.Configurations.Damage;
			local explosionStun = self.Configurations.ExplosionStun;
			local damageRatio = self.Configurations.DamageRatio;

			modExplosionHandler:Process(lastPosition, hitLayers, {
				Owner = self.Owner;
				StorageItem = self.StorageItem;
				TargetableEntities = projectile.TargetableEntities;

				Damage = damage;
				ExplosionStun = explosionStun;
				DamageRatio = damageRatio;

				DamageOrigin = lastPosition;
				OnPartHit=modExplosionHandler.GenericOnPartHit;
			});
			
		end)
	end

	return projectile;
end

return Pool;