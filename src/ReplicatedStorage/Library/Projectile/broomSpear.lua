local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);
local Projectile = require(script.Parent.Projectile);

local projectilePrefab = script.spear;

local Pool = {};
Pool.__index = Pool;
--==

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();
	projectile.TrustClientProjectile = true;

	projectile.ArcTracerConfig = {
		Velocity=200;
		LifeTime=30;
		Bounce=0;
		RayRadius=0.2;
	};
	
	projectile.Configurations = {
		ProjectileVelocity=200;
		ProjectileLifeTime=30;
		ProjectileBounce=0;
	};
	
	function projectile:Activate()
	end	

	local activated = false;
	function projectile:ProjectileDamage(hitObj)
		if activated then return end;

		local damagable = modDamagable.NewDamagable(hitObj.Parent);
		if damagable == nil then return end;
		
		local model = damagable.Model;
		local damagableObj = damagable.Object;
		
		local healthInfo = damagable:GetHealthInfo();

		local damage = math.clamp(
			(self.Configurations.DamagePercent or 0.01) * healthInfo.MaxHealth, 
			math.ceil(self.Configurations.Damage * 1.5), 
			Projectile.MaxDamage);
		

		if damagableObj.ClassName == "NpcStatus" then
			local dmgMulti = self.TargetableEntities[damagable.HealthObj.Name];
			if dmgMulti then
				damage = damage * dmgMulti;
			else
				damage = 0;
			end
		end

		if damage > 0 then
			local newDmgSrc = modDamagable.NewDamageSource{
				Damage=damage;
				Dealer=self.Owner;
				ToolStorageItem=self.StorageItem;
				TargetModel = model;
				TargetPart=hitObj;
				DamageCate=modDamagable.DamageCategory.Projectile;
			}

			if damagable:CanDamage(self.Owner) then
				modDamageTag.Tag(model, self.Owner.Character);
				damagable:TakeDamagePackage(newDmgSrc);
			end
		end

		modAudio.Play(math.random(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", self.Prefab);
		
	end

	function projectile:OnContact(arcPoint)
		if arcPoint.Hit == nil then return end;
		
		if RunService:IsServer() then
			if self.Prefab:CanSetNetworkOwnership() then self.Prefab:SetNetworkOwner(nil) end;
			task.wait()
			if self.ProjectileDamage then self:ProjectileDamage(arcPoint.Hit); end
			
		else
			local targetModel = arcPoint.Hit.Parent;
			local humanoid = targetModel and targetModel:FindFirstChildWhichIsA("Humanoid");
			if humanoid then
				modAudio.Play(math.random(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", self.Prefab).RollOffMaxDistance = 1024;
			end

		end

		if not arcPoint.Hit.Anchored then
			if arcPoint.Client then return true end;
			
			self.Prefab.Anchored = false;
			self.Prefab.Massless = true;
			local hitPart, hitPoint = arcPoint.Hit, arcPoint.Point;

			local weld = Instance.new("Motor6D");
			weld.Name = "arrow";
			weld.Parent = self.Prefab;

			weld.Part0 = self.Prefab;
			weld.Part1 = hitPart;

			local worldCf = CFrame.new(hitPoint, hitPoint + arcPoint.Direction);
			weld.C1 = hitPart.CFrame:ToObjectSpace(worldCf);

			return true;
		end

		return;
	end
	
	return projectile;
end

return Pool;