local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");

local Projectile = require(script.Parent.Projectile);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modWeaponsMechanics = require(game.ReplicatedStorage.Library.WeaponsMechanics);

local projectilePrefab = script.Arrow;
local random = Random.new();
--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();
	--projectile.TrustClientProjectile = true;

	projectile.ArcTracerConfig = {
		Velocity=500;
		LifeTime=10;
		Bounce=0;
		Acceleration=Vector3.new(0, -workspace.Gravity/16, 0);
	};
	
	function projectile:Activate()
	end	

	local hitOnce = {};
	local activated = false;
	local index = 1;
	function projectile:ProjectileDamage(hitObj)
		if activated then return end;

		local modTagging = require(game.ServerScriptService.ServerLibrary.Tagging);

		local shotCache = {
			HitPart = hitObj;
			FocusCharge = (self.Charge or 0);
			Index=index;

			CritOccured = nil;
		};
		index = index +1;
		
		local damagable = modDamagable.NewDamagable(hitObj.Parent);
		if damagable then
			local model = damagable.Model;
			local damagableObj = damagable.Object;

			local damage = self.Configurations.Damage or 100;
			
			if self.Owner then
				damage = modWeaponsMechanics.DamageModification(self.WeaponModule, shotCache, self.Owner);
			end
			
			if damagableObj.ClassName == "NpcStatus" then
				local dmgMulti = self.TargetableEntities[damagableObj.Name];
				if dmgMulti then
					damage = damage * dmgMulti;
				else
					damage = 0;
				end
			end

			if damage ~= 0 then
				if hitOnce[model] then return end
				hitOnce[model] = true;
				task.delay(1, function() hitOnce[model] = nil; end)

				if self.Owner then
					if damagable:CanDamage(self.Owner) then
						self.DamageSource.DamageForce = (hitObj.Position-self.Prefab.Position).Unit * 80;
						self.DamageSource.DamagePosition = hitObj.Position;
						
						self.DamageSource.Damage = damage;
						self.DamageSource.TargetModel = model;
						self.DamageSource.TargetPart = hitObj;
						self.DamageSource.DamageType = shotCache.CritOccured or self.DamageSource.DamageType;
						
						modWeaponsMechanics.ProcessModHooks(self.DamageSource);
						modTagging.Tag(model, self.Owner.Character);

						damagable:TakeDamagePackage(self.DamageSource);
					end
					
				else
					damagable:TakeDamagePackage{
						DamageId=self.ShotId;
						Damage=damage;
						StorageItem=self.StorageItem;
						HitPart=hitObj;
						DamageType=shotCache.CritOccured;
					}
				end

			end
			
		end

	end

	local impactSndTick;
	function projectile:OnContact(arcPoint, arcTracer)
		if arcPoint.Hit == nil then return end;

		if RunService:IsServer() then
			if self.Prefab:CanSetNetworkOwnership() then self.Prefab:SetNetworkOwner(nil) end;
			task.wait();
			if self.ProjectileDamage then self:ProjectileDamage(arcPoint.Hit); end

			if impactSndTick == nil or tick()-impactSndTick > 0.2 then
				impactSndTick = tick();
				modWeaponsMechanics.ImpactSound{
					BasePart = arcPoint.Hit;
					Point = arcPoint.Point;
					Normal = arcPoint.Normal;
				};
			end

		else
			if self.Configurations.ActiveClientMod then
				spawn(function() self.Configurations.ActiveClientMod(self.WeaponModel, {{Object=arcPoint.Hit}}) end);
			end

			local targetModel = arcPoint.Hit.Parent;
			local humanoid = targetModel and targetModel:FindFirstChildWhichIsA("Humanoid");
			if humanoid then
				modAudio.Play(random:NextInteger(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", self.Prefab.Position).MaxDistance = 1024;
			end

		end

		local stickArrow = true;

		if arcPoint.ReflectToPoint ~= nil and arcTracer.MaxBounce > 0 then --arcTracer.KeepAcceleration == true and arcPoint.LastPoint
			stickArrow = false;

		end

		if self.Configurations.Deadweight and arcTracer.MaxBounce > 0 then
			stickArrow = false;

		end


		if stickArrow then -- not arcPoint.Hit.Anchored and
			Debugger.Expire(self.Prefab);
			if arcPoint.Client then return true end; --Client's arcPoint

			if RunService:IsServer() then
				local arrowDebris: BasePart = self.Prefab:Clone();
				
				Debugger.Expire(arrowDebris, 10);
				arrowDebris.Anchored = false;
				arrowDebris.Massless = true;
				local hitPart, hitPoint = arcPoint.Hit, arcPoint.Point;

				local weld = Instance.new("Weld");
				weld.Name = "arrow";
				weld.Parent = arrowDebris;

				weld.Part0 = arrowDebris;
				weld.Part1 = hitPart;

				local worldCf = CFrame.new(hitPoint, hitPoint + arcPoint.Direction);
				weld.C1 = hitPart.CFrame:ToObjectSpace(worldCf);

				arrowDebris.Parent = workspace.Debris;
			end

			return true;
		end

		return;
	end
	
	return projectile;
end

return Pool;