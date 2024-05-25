local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modTouchHandler = require(game.ReplicatedStorage.Library.TouchHandler);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modAoeHighlight = require(game.ReplicatedStorage.Particles.AoeHighlight);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);
local Projectile = require(script.Parent.Projectile);

local projectilePrefab = script.molotov;
local templateFireParticles = script:WaitForChild("Fire2");

--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		LifeTime=30;
		Bounce=0;

		IgnoreEntities=false;
		IgnoreWater=false;
	};
	
	-- projectile.Configurations = {
	-- 	ProjectileLifeTime=30;
	-- 	ProjectileBounce=0;
	-- 	IgnoreEntities=false;
	-- 	IgnoreWater=false;
	-- };
	
	function projectile:Activate()
		Debugger.Expire(self.Prefab, self.ArcTracerConfig.LifeTime);
		modAudio.Play("Fire", self.Prefab, true); 
	end	
	
	function projectile:ProjectileDamage(hitPart)
		local targetModel = hitPart.Parent;
		
		local damagable = modDamagable.NewDamagable(targetModel);
		
		if damagable then
			local player = game.Players:GetPlayerFromCharacter(targetModel);
			if self.Owner and player == self.Owner then
				
			elseif damagable:CanDamage(self.Owner) then
				modDamageTag.Tag(targetModel, self.Owner and self.Owner.Character);
				local damage = self.ArcTracerConfig.Damage or 1;
				
				if damagable.Object.ClassName == "NpcStatus" then
					local healthInfo = damagable:GetHealthInfo();
					
					damage = math.clamp(healthInfo.MaxHealth*0.05, 35, 5000);
					
					local dmgMulti = self.TargetableEntities[damagable.Object.Name];
					damage = damage*dmgMulti;
					
				elseif damagable.Object.ClassName == "PlayerClass" then
					modStatusEffects.Burn(damagable.Object:GetInstance(), 35, 5);
					
				end
				
				local newDmgSrc = modDamagable.NewDamageSource{
					Damage=damage;
					Dealer=self.Owner;
					ToolStorageItem=self.StorageItem;
					TargetPart=hitPart;
					DamageType="FireDamage";
					DamageCate=modDamagable.DamageCategory.AoE;
				}
				damagable:TakeDamagePackage(newDmgSrc);
			end
		end
	end
	
	local tweenInfo = TweenInfo.new(5);
	local impacted = false;
	function projectile:OnContact(arcPoint)
		local hitPart, hitPoint, hitNormal, hitMaterial = arcPoint.Hit, arcPoint.Point, arcPoint.Normal, arcPoint.Material;
		if hitPart.Name == "_Water" and hitPart:IsDescendantOf(workspace.Debris) then Debugger.Expire(self.Prefab, 0); return end;
		if hitMaterial == Enum.Material.Water then Debugger.Expire(self.Prefab, 0); return end;
		
		if impacted then return end;
		impacted = true;
		
		self.Prefab.Transparency = 1;
		modAudio.Play("GlassSmash", self.Prefab); 
		Debugger.Expire(self.Prefab, 2);
		
		if RunService:IsClient() then return end;
		
		local humanoid = hitPart.Parent:FindFirstChildWhichIsA("Humanoid");
		local rootPart = humanoid and humanoid.RootPart;
		
		if rootPart then
			local ray = Ray.new(rootPart.Position, Vector3.new(0, -64, 0));
			hitPart, hitPoint, hitNormal, hitMaterial = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Environment}, true);
		end

		local newZone = modAoeHighlight.newCylinder(16);
		newZone.CFrame = CFrame.new(hitPoint, hitPoint + hitNormal);
		newZone.Size = Vector3.new();
		newZone.Parent = workspace.Entities;
		
		local newFireParticles = templateFireParticles:Clone();
		newFireParticles.Parent = newZone;
		
		
		local hitbox = Instance.new("Part");
		hitbox.Shape = Enum.PartType.Cylinder;
		hitbox.Anchored = true;
		hitbox.CanCollide = false;
		hitbox.Parent = workspace.Entities;
		hitbox.CFrame = newZone.CFrame * CFrame.Angles(0, math.rad(90), 0);
		hitbox.Size = Vector3.new(5, 5, 5);
		hitbox.Transparency = 1;
		hitbox.BottomSurface = Enum.SurfaceType.Smooth;
		hitbox.TopSurface = Enum.SurfaceType.Smooth;
		hitbox.Color = newZone.Color;
		Debugger.Expire(hitbox, 16);
		
		modAudio.Play("Fire", newZone, true); 
		
		local touchHandler = modTouchHandler.new("Molotov"..(self.Owner and self.Owner.Name or ""), 0.5);
		function touchHandler:OnPlayerTouch(player, basePart, part)
			projectile:ProjectileDamage(part)
		end
		function touchHandler:OnHumanoidTouch(humanoid, basePart, part)
			projectile:ProjectileDamage(part)
		end
		function touchHandler:OnPartTouch(basePart, part)
			if CollectionService:HasTag(part, "Flammable") then
				local modFlammable = require(game.ServerScriptService.ServerLibrary.Flammable);
				modFlammable:Ignite(part);
			end
		end
		
		touchHandler:AddObject(hitbox);
		
		TweenService:Create(hitbox, tweenInfo, {Size=Vector3.new(10, 20, 20)}):Play();
		TweenService:Create(newZone, tweenInfo, {Size=Vector3.new(21, 21, 2)}):Play();

		return true;
	end
	
	return projectile;
end

return Pool;