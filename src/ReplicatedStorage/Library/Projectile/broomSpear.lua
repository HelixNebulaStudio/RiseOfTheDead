local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modWeaponsMechanics = require(game.ReplicatedStorage.Library.WeaponsMechanics);
local Projectile = require(script.Parent.Projectile);

local projectilePrefab = script.spear;
local random = Random.new();

local remotes = game.ReplicatedStorage.Remotes;
local bindIsInDuel = remotes.IsInDuel;

--== Script;

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
		local modTagging = require(game.ServerScriptService.ServerLibrary.Tagging);

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
			local dmgMulti = self.TargetableEntities[damagableObj.Name];
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
			}

			if damagable:CanDamage(self.Owner) then
				modTagging.Tag(model, self.Owner.Character);
				damagable:TakeDamagePackage(newDmgSrc);
			end
		end

		modAudio.Play(random:NextInteger(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", self.Prefab);
		
	end

	function projectile:OnContact(arcPoint)
		if arcPoint.Hit then
			if RunService:IsServer() then
				
				if self.Prefab:CanSetNetworkOwnership() then self.Prefab:SetNetworkOwner(nil) end;
				task.wait()
				if self.ProjectileDamage then self:ProjectileDamage(arcPoint.Hit); end
				
			else
				local targetModel = arcPoint.Hit.Parent;
				local humanoid = targetModel and targetModel:FindFirstChildWhichIsA("Humanoid");
				if humanoid then
					modAudio.Play(random:NextInteger(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", self.Prefab).MaxDistance = 1024;
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
		end
	end
	
	return projectile;
end

return Pool;
