local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");
local Projectile = require(script.Parent.Projectile);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modExplosionHandler = require(game.ReplicatedStorage.Library.ExplosionHandler);

local projectilePrefab = script.Rocket;

--== Script;
function Pool.new()
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		LifeTime=5;
		Velocity=30;
		Bounce=0;
		Acceleration=Vector3.new(0, -150, 0);
		IgnoreEntities=true;
	};
	
	function projectile:Activate()
		Debugger.Expire(self.Prefab, self.ArcTracerConfig.LifeTime);
		modAudio.Play("RocketLoop", self.Prefab);
	end
	
	local activated = false;
	function projectile:OnContact(arcPoint)
		if activated then return end;
		activated = true;

		self.Prefab.Transparency = 1;
		if RunService:IsServer() then
			local lastPosition = arcPoint.Point;
			
			local pointAtt = Debugger:Point(lastPosition);
			modAudio.Play(math.random(1, 2)==1 and "Explosion" or "Explosion2", pointAtt);

			local ex = Instance.new("Explosion");
			ex.DestroyJointRadiusPercent = 0;
			ex.BlastRadius = self.ExplosionRadius or 16;
			ex.BlastPressure = 0;
			ex.Position = lastPosition;
			ex.Parent = workspace;
			
			Debugger.Expire(pointAtt, 6);
			Debugger.Expire(ex, 6);
			
			local hitLayers = modExplosionHandler:Cast(lastPosition, {
				Radius = self.ExplosionRadius;
			});

			local damage = self.Damage;

			modExplosionHandler:Process(lastPosition, hitLayers, {
				Damage = damage;
				ExplosionForce = 0;

				DamageOrigin = lastPosition;
				OnPartHit=modExplosionHandler.GenericOnPartHit;
			});
			
		else
			task.wait();
		end
		Debugger.Expire(self.Prefab, 0);
	end

	return projectile;
end

return Pool;