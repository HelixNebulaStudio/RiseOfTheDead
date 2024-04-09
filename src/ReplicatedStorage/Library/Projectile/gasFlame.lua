local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local Projectile = require(script.Parent.Projectile);

local flamePrefab = script.Flame;
local random = Random.new();

local fireParticle2: ParticleEmitter = game.ReplicatedStorage.Particles.Fire2:Clone();
fireParticle2.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255));
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0));
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255));
});
fireParticle2.Rate = 0;
fireParticle2.Lifetime = NumberRange.new(0.7);
fireParticle2.Parent = flamePrefab;

--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = flamePrefab:Clone();
	
	projectile.ArcTracerConfig = {
		Velocity=50;
		LifeTime=0.5;
		Bounce=0;
		Acceleration=Vector3.new(0, 4, 0);
		KeepAcceleration = true;
		IgnoreEntities = false;
	};
	
	local particles: ParticleEmitter = projectile.Prefab:WaitForChild("Fire2");
		
	function projectile:OnEnemyHit(hitPart, damagable, player, weaponItem)
		local configurations = self.WeaponModule.Configurations;
		local damage = configurations.Damage;
		
		local damagableObj = damagable.Object;

		local itemValues = weaponItem and weaponItem.Values or {};

		local owDmgMulti = itemValues.ImpactMulti;
		local owDurMulti = itemValues.TickMulti;
		
		self.DamageSource.Damage = damage * (owDmgMulti or 4);
		self.DamageSource.DamageType = "FireDamage";
		self.DamageSource.TargetModel = damagable.Model;
		self.DamageSource.TargetPart = hitPart;
		
		if damagableObj.ClassName == "NpcStatus" then
			local dmgMulti = self.TargetableEntities[damagableObj.Name];
			
			if dmgMulti and damagableObj:CanTakeDamageFrom(player) then
				
				local modFlameMod = require(game.ReplicatedStorage.Library.ModsLibrary.FlameMod);
				
				local newFire = Instance.new("Fire");
				newFire.Heat = 10;
				newFire.Size = 8;
				newFire.Parent = hitPart;
				Debugger.Expire(newFire, 0.5);
				
				local newDmgSrc = self.DamageSource:Clone();
				newDmgSrc.ToolModule={
					Configurations={
						PropertiesOfMod={
							UseCurrentHpDmg = false;
							Damage = damage * (owDurMulti or 0.5);
							Duration = 25 + (configurations.EverlastDuration or 0);
						};
					};
				};
				modFlameMod.ActivateMod(newDmgSrc);

				if damage and damage > 0 then
					damagable:TakeDamagePackage(self.DamageSource);
				end
			end
			
		elseif damagableObj.ClassName == "Destructible" and damagableObj.Enabled then
			if damage and damage > 0 then
				damagable:TakeDamagePackage(self.DamageSource);
			end
			
		elseif damagableObj.ClassName == "PlayerClass" then
			local damagablePlayer = damagableObj:GetInstance();
			if damagablePlayer and damagable:CanDamage(player) then
				modStatusEffects.Burn(damagablePlayer, 50, 5);
			end;

			if damage and damage > 0 then
				damagable:TakeDamagePackage(self.DamageSource);
			end
		end
		
	end;

	function projectile:Activate()
		particles.LockedToPart = true;
		task.spawn(function()
			for a=1, 3 do
				particles:Emit(3);
				task.wait();
				task.wait();
			end
		end)
		
	end	

	local touched = {};
	local activated = false;
	function projectile:OnContact(arcPoint)
		if activated then return end;
		local hitPart = arcPoint.Hit;

		local function onFlameTouch(hitPart)
			if hitPart == nil then return end;
			if RunService:IsClient() then return end;
			if hitPart.Name == "_Water" and hitPart:IsDescendantOf(workspace.Debris) then Debugger.Expire(self.Prefab, 0); return end;

			local damagable = modDamagable.NewDamagable(hitPart.Parent);
			if damagable then
				local model = damagable.Model;
				
				if touched[model] ~= nil then
					return;
				end
				touched[model] = true;
				
				if projectile.ProjectileDamage then projectile:ProjectileDamage(damagable, hitPart); end
			end
		end
		
		if CollectionService:HasTag(hitPart, "Flammable") then
			local modFlammable = require(game.ServerScriptService.ServerLibrary.Flammable);
			modFlammable:Ignite(hitPart);
		end
		
		onFlameTouch(hitPart);
		
		if arcPoint.LastPoint then
			activated = true;
			table.clear(touched);
		end
	end
	
	function projectile:ProjectileDamage(damagable, hitPart)
		if self.Owner and hitPart:IsDescendantOf(self.Owner) then return end;
		
		local modTagging = require(game.ServerScriptService.ServerLibrary.Tagging);
		
	 	task.spawn(function()
			if self.Owner then
				if damagable:CanDamage(self.Owner) then
					modTagging.Tag(damagable.Model, self.Owner and self.Owner:IsA("Player") and self.Owner.Character);
					self:OnEnemyHit(hitPart, damagable, self.Owner, self.StorageItem);
				end
			else
				self:OnEnemyHit(hitPart, damagable, nil, self.StorageItem);
			end
		end);
	end
	
	return projectile;
end

return Pool;