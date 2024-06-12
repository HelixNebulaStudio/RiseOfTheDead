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
		Velocity=20;
		LifeTime=30;
		Bounce=0;
		RayRadius=0.5;
		Delta=1/60;
	};
	
	-- projectile.Configurations = {
	-- 	ProjectileVelocity=200;
	-- 	ProjectileLifeTime=30;
	-- 	ProjectileBounce=0;
	-- };
	
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
			(self.Configurations.ThrowDamagePercent or 0.01) * healthInfo.MaxHealth, 
			math.ceil(self.Configurations.Damage * 0.5), 
			Projectile.MaxDamage);
		

		if damagableObj.ClassName == "NpcStatus" then
			local npcModule = damagableObj:GetModule();
			local humanoid = npcModule.Humanoid;
			local dmgMulti = self.TargetableEntities[humanoid.Name];
			
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
			if self.ProjectileDamage then self:ProjectileDamage(arcPoint.Hit); end
			
		else
			local targetModel = arcPoint.Hit.Parent;
			local humanoid = targetModel and targetModel:FindFirstChildWhichIsA("Humanoid");
			if humanoid then
				modAudio.Play(math.random(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", self.Prefab).RollOffMaxDistance = 1024;
			end

		end

		Debugger.Expire(self.Prefab);
		if arcPoint.Client then return true end; --Client's arcPoint

		if RunService:IsServer() then
			local debriProjectile: BasePart = self.Prefab:Clone();
			
			Debugger.Expire(debriProjectile, 30);
			debriProjectile.Anchored = false;
			debriProjectile.Massless = true;
			local hitPart, hitPoint = arcPoint.Hit, arcPoint.Point;

			local weld = Instance.new("Weld");
			weld.Name = "projectileDebrisWeld";
			weld.Parent = debriProjectile;

			weld.Part0 = debriProjectile;
			weld.Part1 = hitPart;

			local worldCf = CFrame.new(hitPoint, hitPoint + arcPoint.Direction);
			weld.C1 = hitPart.CFrame:ToObjectSpace(worldCf);

			debriProjectile.Parent = workspace.Debris;
		end

		return true;
	end
	
	return projectile;
end

return Pool;