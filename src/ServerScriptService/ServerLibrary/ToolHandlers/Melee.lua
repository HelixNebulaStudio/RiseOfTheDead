local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local RunService = game:GetService("RunService");

--== Modules;
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);
local modWeaponMechanics = require(game.ReplicatedStorage.Library.WeaponsMechanics);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);

local modVector = require(game.ReplicatedStorage.Library.Util.Vector);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);


local TargetableEntities = modConfigurations.TargetableEntities;

local ToolHandler = {};
ToolHandler.__index = ToolHandler;
ToolHandler.TargetableEntities = TargetableEntities;

local overlapParams = OverlapParams.new();
overlapParams.MaxParts = 16;
--== Script;
function ToolHandler:PrimaryAttack(damagable, hitPart)
	local model = damagable.Model;
	local damagableObj = damagable.Object;
	
	local configurations = self.ToolConfig.Configurations;
	local damage = configurations.Damage;
	
	local wielderName = self.Character and self.Character.Name;
	if wielderName then
		local playerRootPart = self.Character and self.Character.PrimaryPart;
		
		if playerRootPart == nil then return end;

		if self.Player then
			local distance = (playerRootPart.Position - hitPart.Position).Magnitude;
			local maxDist = math.max(configurations.HitRange, hitPart.Size.Magnitude*1.1)+4;
			
			if distance > maxDist then
				Debugger:Warn("Illegal hit, distance("..distance.."/"..maxDist..")"); 
				return
			end
			
			local classPlayer = modPlayers.GetByName(self.Player.Name);
			-- Skill: The Swordsman;
			if classPlayer.Properties.theswo then
				local swoBonus = ((classPlayer.Properties.theswo.Percent/100)+1);
				damage = damage * swoBonus;
			end
		end
	end
	
	if self.AttackType == 2 then
		damage = damage * configurations.HeavyAttackMultiplier;
	end
	
	if damagableObj.ClassName == "NpcStatus" then
		local npcModule = damagableObj:GetModule();
		if npcModule == nil then return end;
		
		local humanoid = npcModule.Humanoid;
		local damageRatio = humanoid and self.TargetableEntities[humanoid.Name];
		
		if damageRatio then 
			damage = damage * damageRatio;
			
			if self.Player then
				if damagableObj:CanTakeDamageFrom(self.Player) then
					if self.ToolConfig.Category == "Blunt" then
						if npcModule and npcModule.KnockbackResistant == nil or npcModule.KnockbackResistant == 0 then
							local knockbackStrength = configurations.Knockback or configurations.BaseKnockback;
							if knockbackStrength and damage > 0 then
								local rootPart = model.PrimaryPart;
								local playerRootPart = self.Character and self.Character.PrimaryPart;
								if rootPart and playerRootPart then
									rootPart.Velocity = (playerRootPart.CFrame.LookVector * knockbackStrength) + Vector3.new(0, 40, 0);
								end
							end
		
							local knockoutDuration = configurations.KnockoutDuration or configurations.BaseKnockoutDuration;
							if knockoutDuration and damage > 0 then
								local healthInfo = damagable:GetHealthInfo();
								if healthInfo.Armor <= 0 then
									npcModule.EntityStatus:GetOrDefault("meleeKnockout", {
										Ragdoll=true;
										Expires=tick()+knockoutDuration;
									});
									
								end
							end
						end

					elseif self.ToolConfig.Category == "Edged" then
						if npcModule and npcModule.BleedResistant == nil or npcModule.BleedResistant == 0 then
							local healthInfo = damagable:GetHealthInfo();
							if healthInfo.Armor <= 0 then
								if npcModule.EntityStatus:GetOrDefault("meleeBleed") == nil then
									task.spawn(function()
										while true do
											task.wait(1);

											local statusData = npcModule.EntityStatus:GetOrDefault("meleeBleed");
											if statusData == nil then break; end;

											if self.Player and damagableObj:CanTakeDamageFrom(self.Player) then
												healthInfo = damagable:GetHealthInfo();

												if healthInfo.Health <= 0 then break; end;

												if self.Player and damagable:CanDamage(self.Player) == false then continue end;
												if self.NpcModule and damagable:CanDamage(self.NpcModule) == false then continue end;
												
												modDamageTag.Tag(model, self.Character, {
													WeaponItemId=(self.StorageItem and self.StorageItem.ItemId or nil);
													IsHeadshot=(hitPart.Name == "Head" or hitPart:GetAttribute("IsHead") == true or nil);
												});
												
												local bleedDamage = math.ceil(damage * (configurations.BleedDamagePercent or 0.05));

												local newDmgSrc = modDamagable.NewDamageSource{
													Damage=bleedDamage;
													DamageType="BleedDamage";
													Dealer=self.Player;
													ToolStorageItem=self.StorageItem;
													TargetPart=hitPart;
													DamageCate=modDamagable.DamageCategory.Melee;
												}
												if self.Player == nil then
													newDmgSrc.Dealer = self.Character;
												end
												damagable:TakeDamagePackage(newDmgSrc);

											end

										end
									end)
								end
								npcModule.EntityStatus:GetOrDefault("meleeBleed", {
									SlowPercent=(configurations.BleedSlowPercent or 0.1);
									Expires=tick()+5;
								});
								
							end

						end

					end
				end

			elseif self.NpcModule then
				if damagableObj:CanTakeDamageFrom(self.NpcModule) then

				else
					damage = 0;
				end
			end
			
		else
			damage = 0;
			
		end;
		
	elseif damagableObj.ClassName == "PlayerClass" then
		local damageRatio = self.TargetableEntities["Humanoid"];

		if damageRatio then 
			damage = damage * damageRatio;
		else
			damage = 0;
		end
		
	end

	if damage ~= 0 then
		if self.Player and damagable:CanDamage(self.Player) == false then return end;
		if self.NpcModule and damagable:CanDamage(self.NpcModule) == false then return end;
		
		modDamageTag.Tag(model, self.Character, {
			WeaponItemId=(self.StorageItem and self.StorageItem.ItemId or nil);
			IsHeadshot=(hitPart.Name == "Head" or hitPart:GetAttribute("IsHead") == true or nil);
		});
		
		local newDmgSrc = modDamagable.NewDamageSource{
			Damage=damage;
			Dealer=self.Player;
			ToolStorageItem=self.StorageItem;
			TargetPart=hitPart;
			DamageCate=modDamagable.DamageCategory.Melee;
		}
		if self.Player == nil then
			newDmgSrc.Dealer = self.Character;
		end
		damagable:TakeDamagePackage(newDmgSrc);
		
		if self.ToolConfig.OnEnemyHit then
			self.ToolConfig.OnEnemyHit(self, model, damage);
		end

		if modConfigurations.PvpMode then
			local playedImpactSound = modWeaponMechanics.ImpactSound{
				Enemy=true;
				BasePart=hitPart;
				Point=hitPart.Position;
				HideMolten=true;
				WeaponType=self.ToolConfig.Category;
			}

			if not playedImpactSound then
				local _, handle = next(self.Prefabs);
				handle = handle.PrimaryPart;
				local audio = self.ToolPackage.Audio;
				
				local hitSoundId = "MeleeEdgedHit";
				if self.ToolConfig.Category == "Edged" then
					hitSoundId = "MeleeEdgedHit";
				elseif self.ToolConfig.Category == "Blunt" then
					hitSoundId = "MeleeBluntHit";
				end

				local snd = modAudio.Play(hitSoundId, handle, nil, audio.PrimarySwing.Pitch, audio.PrimarySwing.Volume);
				snd.PlaybackSpeed = math.random(audio.PrimarySwing.Pitch*10-1, audio.PrimarySwing.Pitch*10+1)/10
			end
		end
	end
end

function ToolHandler:OnToolEquip(toolModule)
	if self.Equipped then return end;
	self.Equipped = true;
	self.MeleeTag = Instance.new("BoolValue");
	self.MeleeTag.Name = "MeleeEquipped";
	self.MeleeTag.Parent = self.Character;
	self.ToolConfig = toolModule;

	local configurations = self.ToolConfig.Configurations;
	local attackTime = configurations.PrimaryAttackSpeed;

	if self.Player then self.Character = self.Player.Character; end
	
	local colliders = {};
	for _, prefab in pairs(self.Prefabs) do
		local meleeParts = prefab:GetDescendants();
		for a=1, #meleeParts do
			if meleeParts[a].Name == "Collider" and meleeParts[a]:IsA("BasePart") then
				table.insert(colliders, meleeParts[a]);
			end
		end
		
		self.Garbage:Destruct();
		for a=1, #colliders do
			self.Garbage:Tag(colliders[a].Touched:Connect(function(hitPart)
				local prefab = hitPart.Parent;
				if prefab and prefab:IsA("Accessory") then
					prefab = prefab.Parent;
				end
				local damagable = modDamagable.NewDamagable(prefab);
				
				if damagable then
					local model = damagable.Model;

					local victim = self.VictimsList[model];
					if victim then
						victim.HitTick=tick();
					else
						self.VictimsList[model] = {Model=model; Damagable=damagable; HitPart=hitPart; HitTick=tick()};
						victim = self.VictimsList[model];
					end

					if (self.Attacking and tick()-self.Attacking <= attackTime) and victim.Hit ~= true then
						victim.Hit = true;
						self:PrimaryAttack(damagable, hitPart);
					end
				end
				
			end));
		end
	end
	
	self.Colliders = colliders;
	return colliders;
end

function ToolHandler:OnToolUnequip()
	table.clear(self.VictimsList);
	if not self.Equipped then return end;
	self.Equipped = false;
	self.Attacking = nil;
	if self.MeleeTag then self.MeleeTag:Destroy() end;
	self.Colliders = nil;
end

function ToolHandler:OnPrimaryFire(...)
	local classPlayer = shared.modPlayers.Get(self.Player);
	local character = self.Character;
	local humanoid = character and character:FindFirstChild("Humanoid");
	local attackType = ...;
	
	local configurations = self.ToolConfig.Configurations;

	local attackTime = configurations.PrimaryAttackSpeed;
	local playerBodyEquipments = classPlayer.Properties and classPlayer.Properties.BodyEquipments;
	
	if playerBodyEquipments and modConfigurations.DisableGearMods ~= true then
		if playerBodyEquipments.MeleeFury then
			local meleeFuryBonus = 5 * playerBodyEquipments.MeleeFury;
			if meleeFuryBonus > 0 then
				attackTime = attackTime * (1-math.clamp(meleeFuryBonus, 0, 1));
			end
		end
	end
	
	attackTime = math.max(attackTime, 0.1);

	self.AttackType = attackType;
	if humanoid and humanoid.Health > 0 and (self.Attacking == nil or tick()-self.Attacking > attackTime) then
		
		if attackType == "Throw" then
			local _, origin, targetPoint, throwCharge = ...;
			if origin == nil or targetPoint == nil or throwCharge == nil then return end;
			
			local _, handle = next(self.Prefabs);
			handle = handle.PrimaryPart;
			
			if humanoid and humanoid.Health > 0 then
				
				if typeof(origin) ~= "Vector3" then Debugger:Warn("Origin is not vector3"); return end;
				if typeof(targetPoint) ~= "Vector3" then Debugger:Warn("targetPoint is not vector3"); return end;
				if typeof(throwCharge) ~= "number" then Debugger:Warn("ThrowCharge is not a number"); return end;
				
				local distanceFromHandle = (handle.Position - origin).Magnitude;
				if distanceFromHandle > 32 then Debugger:Warn("Too far from handle."); return end;
				
				local itemLib = modItemsLibrary:Find(self.StorageItem.ItemId);
				
				local profile = modProfile:Get(self.Player);
				local inventory = profile.ActiveInventory;
				
				if self.StorageItem and self.StorageItem.Quantity <= 0 then return end;
				
				local projectileObject = modProjectile.Fire(configurations.ProjectileId, CFrame.new(origin), Vector3.new(), nil, self.Player, self.ToolConfig);
				projectileObject.TargetableEntities = TargetableEntities;
				projectileObject.StorageItem = self.StorageItem;
				
				throwCharge = math.clamp(throwCharge, 0, 1);
				
				local velocityScalar = (configurations.Velocity + configurations.VelocityBonus * throwCharge);
				local travelTime = (targetPoint-origin).Magnitude/velocityScalar;
				Debugger:StudioWarn("travelTime",travelTime, "velocityScalar", velocityScalar);
				local velocity = projectileObject.ArcTracer:GetVelocityByTime(origin, targetPoint, travelTime);
				
				modProjectile.ServerSimulate(projectileObject, origin, velocity);
				
				if configurations.ConsumeOnThrow then
					if self.StorageItem.MockItem then
						self.StorageItem.Quantity = (self.StorageItem.Quantity or 1) -1;
						shared.EquipmentSystem.ToolHandler(self.Player, "unequip");
						
					else
						inventory:Remove(self.StorageItem.ID, 1);
						shared.Notify(self.Player, ("1 $Item removed from your Inventory."):gsub("$Item", itemLib.Name), "Negative");
						
					end
				end
			end
			
		else
			self.Attacking = tick();
			self.PrimaryFireTick = tick()-0.5;
			
			local function addVictim(hitPart)
				if hitPart:IsDescendantOf(character) then return end;
				
				local damagable = modDamagable.NewDamagable(hitPart.Parent);
				
				if damagable then
					local model = damagable.Model;

					local victim = self.VictimsList[model];
					if victim then
						victim.HitTick=tick();
					else
						self.VictimsList[model] = {Model=model; Damagable=damagable; HitPart=hitPart; HitTick=tick()};
						victim = self.VictimsList[model];
					end
				end
			end
			
			if self.Colliders then
				for a=1, #self.Colliders do
					local hitParts = workspace:GetPartsInPart(self.Colliders[a], overlapParams);
					for b=1, #hitParts do
						addVictim(hitParts[b]);
					end
				end
			end
			
			for hitModel, hitInfo in pairs(self.VictimsList) do
				if hitInfo.HitTick >= self.PrimaryFireTick then
					hitInfo.Hit = true;
					self:PrimaryAttack(hitInfo.Damagable, hitInfo.HitPart);
				end
			end
			
			task.wait(attackTime);

			self.Attacking = nil;
			for hitModel, hitInfo in pairs(self.VictimsList) do
				if hitInfo.Hit ~= true then continue end;
				hitInfo.Hit = nil;
			end
			
		end
	end
end

function ToolHandler:OnInputEvent(inputData)
	if typeof(self.Player) == "Instance" and self.Player:IsA("Player") then
		self.Character = self.Player.Character;
	end

	local character = self.Character;
	local humanoid = character and character:FindFirstChild("Humanoid");

	if humanoid and humanoid.Health > 0 then
		if self.ToolConfig.OnInputEvent then
			self.ToolConfig.OnInputEvent(self, inputData);
		end
	end
end


function ToolHandler.new(player, storageItem, toolPackage, toolModels)
	local self = {
		Player = player;
		NpcModule = nil;
		StorageItem = storageItem;
		ToolPackage = toolPackage;
		
		Prefabs = toolModels;
		VictimsList = {};
		Garbage = modGarbageHandler.new();
		Equipped = false;
	};
	self.ToolConfig = toolPackage.NewToolLib(self);
	
	if typeof(player) == "Instance" and player:IsA("Player") then
		self.Character = player.Character;
	end

	if storageItem and storageItem.MockItem then
		self.MockItem = true;
	end

	setmetatable(self, ToolHandler);
	return self;
end

return ToolHandler;
