local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);
local modWeaponsMechanics = require(game.ReplicatedStorage.Library.WeaponsMechanics);
local modProjectileRicochet = require(game.ReplicatedStorage.Library.Projectile.Mechanics.Ricochet);

local Projectile = require(script.Parent.Projectile);

local projectilePrefab = script.boomerang;
--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();
	
	projectile.ArcTracerConfig = {
		Velocity=10;
		LifeTime=10;
		AirSpin=math.rad(24);
		RayRadius=0.5;

		Bounce=1;
		MaxBounce=9;
		KeepAcceleration = true;
		
		Delta=1/60;
	}

	function projectile.ArcTracerConfig.OnStepped(projectile, arcPoint)
		modProjectileRicochet.OnStepped(projectile, arcPoint, 32);
	end

	local hitCache = {};
	function projectile:OnContact(arcPoint, arcTracer)
		if arcPoint.Hit == nil then return end;
		arcTracer.Bounce = arcTracer.Bounce -0.1;
		if RunService:IsServer() then
			local damagable = modDamagable.NewDamagable(arcPoint.Hit.Parent);
			if damagable and hitCache[arcPoint.Hit.Parent] == nil then
				hitCache[arcPoint.Hit.Parent] = true;
				task.delay(5, function()
					table.clear(hitCache);
				end)

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
						TargetPart=arcPoint.Hit;
						DamageCate=modDamagable.DamageCategory.Projectile;
					};
					arcTracer.Bounce = arcTracer.Bounce -0.2;
		
					if damagable:CanDamage(self.Owner) then
						modDamageTag.Tag(model, self.Owner.Character, {
							WeaponItemId=(self.StorageItem and self.StorageItem.ItemId or nil);
							IsHeadshot=arcPoint.Hit.Name == "Head" and true or nil;
						});
						damagable:TakeDamagePackage(newDmgSrc);
					end
				end
		
				modAudio.Play(math.random(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", self.Prefab.Position).RollOffMaxDistance = 1024;
			end;
	
			modWeaponsMechanics.ImpactSound{
				BasePart = arcPoint.Hit;
				Point = arcPoint.Point;
				Normal = arcPoint.Normal;
			};

		end
		
		if arcTracer.MaxBounce > 0 and arcTracer.Bounce > 0 then return end;

		Debugger.Expire(self.Prefab);
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

		return true;

	end
	
	return projectile;
end

return Pool;