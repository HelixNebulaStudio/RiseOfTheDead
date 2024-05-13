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
		LifeTime=20;
		Bounce=0;
	
		IgnoreEntities=true;
		AddIncludeTags={"TargetableEntities"};
	};
	
	function projectile:Activate()
		task.delay(self.Configurations.DetonateTimer, function()
			modAudio.Play(math.random(1, 2) == 1 and "Explosion" or "Explosion2", self.Prefab);
			
			self.Prefab.Transparency = 1;
			Debugger.Expire(self.Prefab:FindFirstChild("stick"), 0);
			
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
		if arcPoint.Hit and not arcPoint.Hit.Anchored then
			modAudio.Play("GrenadeBounce", self.Prefab);

			self.Prefab.Anchored = false;
			if RunService:IsServer() then
				if self.Prefab:CanSetNetworkOwnership() then self.Prefab:SetNetworkOwner(nil) end;
			end
			
			local hitPart, hitPoint = arcPoint.Hit, arcPoint.Point;
			local weld = Instance.new("Motor6D");
			weld.Name = "stick";
			weld.Parent = self.Prefab;
			
			weld.Part0 = self.Prefab;
			weld.Part1 = hitPart;
			
			local worldCf = CFrame.new(hitPoint, hitPoint - arcPoint.Direction);
			weld.C1 = hitPart.CFrame:ToObjectSpace(worldCf);

			return true;
		end

		return;
	end
	
	return projectile;
end

return Pool;