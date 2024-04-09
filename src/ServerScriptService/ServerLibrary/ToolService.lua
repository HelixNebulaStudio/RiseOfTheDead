local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local CollectionService = game:GetService("CollectionService");

local modPseudoRandom = require(game.ReplicatedStorage.Library.PseudoRandom);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modWeaponsMechanics = require(game.ReplicatedStorage.Library.WeaponsMechanics);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local modMath = require(game.ReplicatedStorage.Library.Util.Math);

local modTagging = require(game.ServerScriptService.ServerLibrary.Tagging);

local remotePrimaryFire = modRemotesManager:Get("PrimaryFire");
--==
local ToolService = {};

-- !outline: ToolService.CancelPrimaryFire(packet)
function ToolService.CancelPrimaryFire(packet)
	packet.ToolModule = packet.ToolModule;
	--
	
	local toolModule = packet.ToolModule;
	
	if toolModule.Cache.AudioPrimaryFire then
		toolModule.Cache.AudioPrimaryFire:Destroy();
		toolModule.Cache.AudioPrimaryFire = nil;
	end
end

-- !outline: ToolService.PriamryFireWeapon(firePacket)
function ToolService.PrimaryFireWeapon(firePacket)
	firePacket.StorageItem = firePacket.StorageItem;
	firePacket.ToolModel = firePacket.ToolModel;
	firePacket.ToolModule = firePacket.ToolModule;
	firePacket.Player = firePacket.Player;
	
	firePacket.ShotOrigin = firePacket.ShotOrigin; -- Vector3
	firePacket.ShotDirection = firePacket.ShotDirection; -- Vector3
	
	firePacket.Targetable = firePacket.Targetable;
	
	firePacket.ReplicateToShotOwner = firePacket.ReplicateToShotOwner;
	
	firePacket.FocusCharge = firePacket.FocusCharge;
	--
	local shotPacket = {
		StorageItem = firePacket.StorageItem;
		ToolModel = firePacket.ToolModel;
		ToolModule = firePacket.ToolModule;
		
		Player = firePacket.Player;
		ReplicateToShotOwner = firePacket.ReplicateToShotOwner;
		FocusCharge = firePacket.FocusCharge;
	};
	
	
	local storageItem = firePacket.StorageItem;
	local storageItemID = storageItem.ID;
	
	local profile, toolModule;

	local toolModel = firePacket.ToolModel;
	local toolHandle: BasePart = toolModel.PrimaryPart;

	local infType = toolModel:GetAttribute("InfAmmo") == true;
	
	if firePacket.ToolModule then
		toolModule = firePacket.ToolModule;
		
	elseif firePacket.Player then
		profile = shared.modProfile:Get(firePacket.Player);
		toolModule = profile:GetItemClass(storageItemID);
		
	end
	
	if toolModule == nil then return end;
	
	local configurations = toolModule.Configurations;
	local properties = toolModule.Properties;
	local audio = toolModule.Audio;

	local ammo = storageItem:GetValues("A") or configurations.AmmoLimit;
	local maxAmmo = storageItem:GetValues("MA") or configurations.MaxAmmoLimit;

	if ammo <= 0 then 
		modAudio.Play(audio.Empty.Id, toolHandle);
		return; 
	end
	
	if properties.IsPrimaryFiring then return end
	properties.IsPrimaryFiring = true;
	local onShotTick = tick();

	task.spawn(function()
		local shotTick = tick();
		local ammoCost = math.min(configurations.AmmoCost or 1, properties.Ammo);

		if configurations.Triplethreat then
			ammoCost = infType == 2 and 3 or math.min(properties.Ammo, 3);
		end
		
		properties.Ammo = properties.Ammo - (configurations.InfiniteAmmo == 2 and 0 or ammoCost);
		
		if audio.PrimaryFire.Looped then
			if toolModule.Cache.AudioPrimaryFire == nil or not workspace:IsAncestorOf(toolModule.Cache.AudioPrimaryFire) then
				local primaryFireSound = modAudio.Play(audio.PrimaryFire.Id, toolHandle);
				primaryFireSound.Name = "PrimaryFireSound";
				primaryFireSound.Looped = true;
				primaryFireSound.Volume = 2;
				toolModule.Cache.AudioPrimaryFire = primaryFireSound;
			end
			
		else
			local primaryFireSound = modAudio.Play(audio.PrimaryFire.Id, toolHandle, false);
			if configurations.PrimaryFireAudio ~= nil then configurations.PrimaryFireAudio(primaryFireSound, 1); end
			
		end
		
		
		local multishot = type(properties.Multishot) == "table" and math.random(properties.Multishot.Min, properties.Multishot.Max) or properties.Multishot;

		if configurations.Triplethreat then
			multishot = ammoCost;
		end
		
		shotPacket.ShotOrigin = toolHandle.BulletOrigin;

		if configurations.BulletMode == modAttributes.BulletModes.Hitscan then
			shotPacket.TargetPoints = {};
			shotPacket.Victims = {};
		elseif configurations.BulletMode == modAttributes.BulletModes.Projectile then
			shotPacket.Projectiles = {};
		end
		
		local direction = firePacket.ShotDirection;
		shotPacket.Direction = direction;
		
		local accRatio, accRate;
		for multiIndex=1, multishot do

			local newInaccuracy = configurations.BaseInaccuracy;
			
			if firePacket.IsPAT then
				if accRatio == nil then
					accRatio = math.clamp(modMath.MapNum(newInaccuracy, 2, 20, 0, 1), 0, 1);
					accRate = 1-math.pow(accRatio, 1/2);
				end
				local imulti = (1.5+(2*accRate));
				
				imulti = imulti * firePacket.MaistPercent;
				
				local nI = newInaccuracy * imulti;
				
				newInaccuracy = nI;
			end
			
			local spreadedDirection = modMath.CFrameSpread(direction, math.max(newInaccuracy, 0));

			if configurations.BulletMode == modAttributes.BulletModes.Hitscan then
				
				local function onCast(basePart, position, normal, material, index, distance)
					if basePart == nil then return end;

					local humanoid = basePart.Parent:FindFirstChildWhichIsA("Humanoid");
					local targetRootPart = basePart.Parent:FindFirstChild("HumanoidRootPart");

					if humanoid then
						if humanoid.Health > 0 then
							if targetRootPart then
								if (basePart.Name == "Head" or basePart:GetAttribute("IsHead") == true) then
									local hitSoundRoll = math.random(0, 1) == 1 and "BulletHeadImpact" or "BulletHeadImpact2";
									modAudio.Play(hitSoundRoll, basePart);
								else
									local hitSoundRoll = math.random(0, 1) == 1 and "BulletBodyImpact" or "BulletBodyImpact2";
									modAudio.Play(hitSoundRoll, basePart);
								end
								table.insert(shotPacket.Victims, {Object=((basePart.Name == "Head" or basePart:GetAttribute("IsHead") == true) and basePart or targetRootPart); Index=index;});
							end
							return basePart.Parent;
						end
					else
						if basePart.Parent:FindFirstChild("Destructible") and basePart.Parent.Destructible.ClassName == "ModuleScript" then
							table.insert(shotPacket.Victims, {Object=basePart; Index=index;});
						end
					end
				end

				local whitelist = {workspace.Environment; workspace.Terrain};
				if firePacket.Targetable then
					if firePacket.Targetable.Zombie then
						whitelist = CollectionService:GetTagged("Zombies");
						table.insert(whitelist, workspace.Environment);
					end
					if firePacket.Targetable.Human then
						local humanoidList = CollectionService:GetTagged("Humans");
						for a=1, #humanoidList do
							table.insert(whitelist, humanoidList[a]);
						end
						table.insert(whitelist, workspace.Environment);
					end

					if firePacket.Targetable.Bandit then
						local humanoidList = CollectionService:GetTagged("Bandits");
						for a=1, #humanoidList do
							table.insert(whitelist, humanoidList[a]);
						end
						table.insert(whitelist, workspace.Environment);
					end

					if firePacket.Targetable.Cultist then
						local humanoidList = CollectionService:GetTagged("Cultists");
						for a=1, #humanoidList do
							table.insert(whitelist, humanoidList[a]);
						end
						table.insert(whitelist, workspace.Environment);
					end

					if firePacket.Targetable.Rat then
						local humanoidList = CollectionService:GetTagged("Rats");
						for a=1, #humanoidList do
							table.insert(whitelist, humanoidList[a]);
						end
						table.insert(whitelist, workspace.Environment);
					end

					if firePacket.Targetable.Humanoid then
						local humanoidList = CollectionService:GetTagged("PlayerCharacters");
						for a=1, #humanoidList do
							table.insert(whitelist, humanoidList[a]);
						end
						table.insert(whitelist, workspace.Environment);
					end
				end

				local bulletEnd = modWeaponsMechanics.CastHitscanRay{
					Origin = firePacket.ShotOrigin;
					Direction = spreadedDirection;
					IncludeList = whitelist;
					Range = 256;
					OnCastFunc = onCast;
					MaxPierce = properties.Piercing;
					PenTable = configurations.Penetration;
				};

				table.insert(shotPacket.TargetPoints, bulletEnd);
				
			elseif configurations.BulletMode == modAttributes.BulletModes.Projectile then

				local projData = {};
				projData.Origin = CFrame.new(firePacket.ShotOrigin);
				projData.Orientation = toolHandle.Orientation;
				projData.Direction = firePacket.ShotDirection;

				if multiIndex > 1 then
					local leftRight = multiIndex%2 == 0 and 1 or -1;
					local radMultiplier = math.floor(multiIndex/2);

					local deg = 3;
					projData.Direction = CFrame.Angles(0, math.rad(deg * leftRight * radMultiplier), 0):VectorToWorldSpace(firePacket.ShotDirection);
				end

				table.insert(shotPacket.Projectiles, projData);
				
			end
		end
		
		ToolService.ProcessWeaponShot(shotPacket);
		
		task.wait(properties.FireRate);
		properties.IsPrimaryFiring = false;
	end)
	
	return true;
end

-- !outline ToolService.ProcessWeaponShot(shotPacket)
function ToolService.ProcessWeaponShot(shotPacket)
	shotPacket.StorageItem = shotPacket.StorageItem;
	shotPacket.ToolModel = shotPacket.ToolModel;
	shotPacket.ToolModule = shotPacket.ToolModule;
	shotPacket.Player = shotPacket.Player;
	-- BulletMode: Hitscan
	shotPacket.Victims = shotPacket.Victims;
	shotPacket.TargetPoints = shotPacket.TargetPoints;
	-- BulletMode: Projectile
	shotPacket.Projectiles = shotPacket.Projectiles;
	shotPacket.FocusCharge = shotPacket.FocusCharge;
	--
	
	local storageItem = shotPacket.StorageItem;
	local toolModel: Model = shotPacket.ToolModel;
	local toolHandle: BasePart = toolModel.PrimaryPart;
	
	local storageItemID = storageItem.ID;
	local itemId = storageItem.ItemId;
	
	local profile, toolModule;
	local realShotId = math.random(1, 99)
	
	if shotPacket.ToolModule then
		toolModule = shotPacket.ToolModule;

	elseif shotPacket.Player then
		profile = shared.modProfile:Get(shotPacket.Player);
		toolModule = profile:GetItemClass(storageItemID);
		
	end
	
	local configurations = toolModule.Configurations;
	local properties = toolModule.Properties;
	
	if toolModule.Cache == nil then toolModule.Cache = {}; end
	local cache = toolModule.Cache;
	
	if profile and profile.InfAmmo then
		configurations.InfiniteAmmo = profile.InfAmmo;
	end

	local baseFirerate = 60/properties.Rpm;
	

	local ammo = storageItem:GetValues("A") or configurations.AmmoLimit;
	local maxAmmo = storageItem:GetValues("MA") or configurations.MaxAmmoLimit;

	if ammo <= 0 then return; end
	ammo = math.min(ammo, configurations.AmmoLimit);

	local ammoCost = math.min(configurations.AmmoCost or 1, ammo);

	if configurations.Triplethreat then
		ammoCost = math.min(ammo, 3);
	end
	if configurations.InfiniteAmmo == 2 then
		ammoCost = 0;
	end
	
	ammo = ammo -ammoCost;
	storageItem:SetValues("A", ammo);
	

	local shotCache = {
		WeaponId = storageItemID;
		Ammo = ammo;
		CritProcs = 0;
		FocusCharge = shotPacket.FocusCharge or 0;
	};

	local newDamageSource = modDamagable.NewDamageSource{
		Dealer = shotPacket.Player;
		DamageId = realShotId;

		ToolStorageItem = storageItem;
		ToolModel = toolModel;
		ToolModule = toolModule;
	};
	

	if configurations.BulletMode == modAttributes.BulletModes.Hitscan then
		local playersShot = {};
		local victims, targetPoints = (shotPacket.Victims or {}), {};

		local targetsPierceable = (properties.Piercing or 0);
		local maxVictims = math.clamp(#victims, 0, (type(properties.Multishot) == "table" and (properties.Multishot.Max + targetsPierceable) or properties.Multishot + targetsPierceable));
		for a=1, maxVictims do
			if shotPacket.TargetPoints and shotPacket.TargetPoints[a] then
				table.insert(targetPoints, shotPacket.TargetPoints[a]);
			end
		end
		for a=1, maxVictims do
			local targetObject = victims[a].Object;
			local targetIndex = victims[a].Index;
			local targetModel = targetObject and targetObject.Parent;

			if targetModel and targetModel:IsA("Accessory") then
				targetModel = targetModel.Parent;
			end

			-- shot handler;
			local validDirectory = workspace:IsAncestorOf(targetObject) or game.ReplicatedStorage.Replicated:IsAncestorOf(targetObject)
			if targetModel == nil or not validDirectory then continue end;
			
			local distance = (targetObject.Position-toolHandle.Position).Magnitude;
			local direction = (targetObject.Position-toolHandle.Position).Unit;
			if distance >= game.Lighting.FogEnd then continue end;

			local damagable = modDamagable.NewDamagable(targetModel);
			if damagable == nil or not damagable:CanDamage(shotPacket.Player) then continue end;
			
			if shotPacket.Player then
				modTagging.Tag(targetModel, shotPacket.Player.Character, (targetObject.Name == "Head" or targetObject:GetAttribute("IsHead") == true) and true or nil);
			end

			local preModDamage = configurations.PreModDamage;
			local basedamage = configurations.BaseDamage;
			local damage = configurations.Damage;
				
			if damagable.Object.ClassName == "Destructible" then
				modWeaponsMechanics.ProcessModHooks(newDamageSource);

				if damagable.Object.NotifyDamageInfo and shotPacket.Player then
					local shotPrint = "";
					shotPrint = shotPrint.."Damage: ".. modFormatNumber.Beautify(math.round(damage*1000)/1000);
					shotPrint = shotPrint.."\nShot Distance: ".. modFormatNumber.Beautify(math.round(distance*100)/100)

					shared.Notify(shotPacket.Player, shotPrint, "Inform");
				end

				task.spawn(function()
					newDamageSource.Damage = damage;
					newDamageSource.DamageType = shotCache.CritOccured or newDamageSource.DamageType;

					damagable:TakeDamagePackage(newDamageSource);
				end)
				
			else
				
				local humanoid, npcModule;
				
				if damagable.Object.ClassName == "NpcStatus" then
					local npcStatus = damagable.Object;
					npcModule = npcStatus:GetModule();

					humanoid = npcModule.Humanoid;
					if npcModule.IsDead then continue end;
					
					
				elseif damagable.Object.ClassName == "PlayerClass" then
					humanoid = damagable.Object.Humanoid;

					local targetPlayer = damagable.Object:GetInstance();
					playersShot[targetPlayer.Name] = targetPlayer;

					modWeaponsMechanics.BulletHitSound{
						BasePart=targetObject;
					}
				end

				local globalDmgMulti = modConfigurations.TargetableEntities[humanoid.Name];
				if globalDmgMulti == nil then continue end;
				-- duel dmg multi removed;

				-- Shot verification
				--if weaponModel.PrimaryPart == nil then return end;
				--local shotOrigin = weaponModel.PrimaryPart.Position;
				--local ray = Ray.new(shotOrigin, shotdata.Direction);

				--local closestDistance = ray:Distance(targetObject.Position);
				--local maxDistance = math.max(targetObject.Size.X, targetObject.Size.Y, targetObject.Size.Z, 4)+5;

				--if humanoid and humanoid.RootPart then
				--	maxDistance = maxDistance * math.clamp(humanoid.RootPart.Velocity.Magnitude, 1, 100);
				--end

				--if closestDistance >= maxDistance then
				--	Debugger:Warn("Player ("..client.Name..") did an illegal shot. Distance:",closestDistance.."/"..maxDistance);
				--	return;
				--end;
				-- Shot verification


				-- Damage modification processing ===================================================================================================
				shotCache.HitPart = targetObject;
				shotCache.CritOccured = nil;
				shotCache.Index = a;
				damage = modWeaponsMechanics.DamageModification(toolModule, shotCache, shotPacket.Player);


				-- Damage post processing ===================================================================================================
				if targetIndex and targetIndex >= 2 then
					local piercingDamageReduction = 0.5;
					damage = damage * piercingDamageReduction ^ targetIndex;
				end

				if configurations.DamageDropoff then
					damage = modWeaponsMechanics.DamageDropoff(toolModule, damage, distance);
				end

				damage = damage * globalDmgMulti;

				-- Apply damage ===================================================================================================

				newDamageSource.TargetModel=targetModel;
				newDamageSource.TargetPart=targetObject;

				local damageSourceClone = newDamageSource:Clone();
				damageSourceClone.Damage = damage;
				modWeaponsMechanics.ProcessModHooks(damageSourceClone);

				if damagable.Object.ClassName == "NpcStatus" then
					
					if configurations.WeaponType == modAttributes.WeaponType.Pistol then
						---
					elseif configurations.WeaponType == modAttributes.WeaponType.Rifle then
						
						if humanoid.FloorMaterial and npcModule.StunFlag ~= true and npcModule.KnockbackResistant == nil then
							humanoid.RootPart.Velocity = humanoid.RootPart.Velocity + direction*50;
						end

					elseif configurations.WeaponType == modAttributes.WeaponType.Shotgun then
						if damage < humanoid.Health then
							local motor = targetObject and targetObject:FindFirstChildWhichIsA("Motor6D") or nil;

							local exludeList = {
								Root=true;
								Waist=true;
								Neck=true;
								LeftHip=true;
								RightHip=true;
								ToolGrip = true;
							};

							local leftWieldJoints = {
								LeftShoulder=true;
								LeftElbow=true;
								LeftWrist=true;
							};
							local rightWieldJoints = {
								RightShoulder=true;
								RightElbow=true;
								RightWrist=true;
							};

							if npcModule.Wield then
								if npcModule.Wield.Instances.LeftWeld then
									exludeList.LeftShoulder = math.random(1, 16) ~= 1;
									exludeList.LeftElbow = math.random(1, 16) ~= 1;
									exludeList.LeftWrist = math.random(1, 16) ~= 1;
								end
								if npcModule.Wield.Instances.RightWeld then
									exludeList.RightShoulder = math.random(1, 16) ~= 1;
									exludeList.RightElbow = math.random(1, 16) ~= 1;
									exludeList.RightWrist = math.random(1, 16) ~= 1;
								end
							end

							if npcModule.JointsStrength then
								for key, value in pairs(npcModule.JointsStrength) do
									exludeList[key] = math.random(1, value) ~= 1;
								end
							end

							if npcModule.Properties.BasicEnemy and motor 
								and exludeList[motor.Name] == nil then
								if npcModule.Wield then
									if (leftWieldJoints[motor.Name] and npcModule.Wield.Instances.LeftWeld)
										or (rightWieldJoints[motor.Name] and npcModule.Wield.Instances.RightWeld) then

										npcModule.Wield.Unequip();
									end
								end
								if npcModule.JointsDestroyed then
									npcModule.JointsDestroyed[motor.Name] = true;
								end
								local activeDmg = (npcModule.Properties.AttackDamage or 0) - (npcModule.DamageReduction or 0);
								npcModule.DamageReduction = (npcModule.DamageReduction or 0) + activeDmg*0.05;
								local part1 = motor.Part1;
								motor:Destroy();
								if part1 then
									local jointPart = Instance.new("Part");
									if jointPart:CanSetNetworkOwnership() then jointPart:SetNetworkOwner(nil) end;
									game.Debris:AddItem(jointPart, 5);
									local weld = Instance.new("Motor6D");
									jointPart.Parent = workspace.Debris;
									jointPart.Size = Vector3.new(2, 2, 2);
									jointPart.Transparency = 1;
									jointPart.CFrame = part1.CFrame;
									weld.Parent = jointPart;
									weld.Part0 = part1;
									weld.Part1 = jointPart;
									jointPart.Velocity = jointPart.Velocity + direction*40;
								end;
							end
						end
					end

					if npcModule.WeakPoint and shotPacket.Player and profile then
						npcModule.WeakPoint(targetObject, function()
							local skill = profile.SkillTree:GetSkill(shotPacket.Player, "weapoi");
							local level, skillStats = profile.SkillTree:CalStats(skill.Library, skill.Points);
							local wpMulti = (skillStats.Percent.Default + skillStats.Percent.Value)/100;

							local add = preModDamage * wpMulti;

							damage = damage + add;
							shotCache.CritOccured = "Crit";
						end);
					end
				end

				task.spawn(function()
					newDamageSource.Damage = damage;
					newDamageSource.DamageType = newDamageSource.DamageType or shotCache.CritOccured;
					newDamageSource.IsCritDamage = shotCache.CritOccured == "Crit";

					local killImpulseForce = configurations.KillImpulseForce or 5;
					newDamageSource.DamageForce = direction*killImpulseForce;
					newDamageSource.DamagePosition = targetObject.Position;

					damagable:TakeDamagePackage(newDamageSource);
				end)
			end
		end
		
		
		local players = game.Players:GetPlayers();
		for a=1, #players do
			if modConfigurations.PvpMode then
				if players[a] == shotPacket.Player and shotPacket.ReplicateToShotOwner ~= true then
					continue;
				end
				
				remotePrimaryFire:FireClient(players[a], itemId, toolModel, shotPacket.TargetPoints);

			else
				local pCharacter = players[a].Character;
				local pRootPart = pCharacter ~= nil and pCharacter:FindFirstChild("HumanoidRootPart") or nil;

				if playersShot[players[a].Name] then
					remotePrimaryFire:FireClient(players[a], itemId, toolModel, targetPoints);

				elseif pRootPart then
					
					if players[a] == shotPacket.Player and shotPacket.ReplicateToShotOwner ~= true then
						continue;
					end
					
					if pRootPart and (pRootPart.Position-toolHandle.Position).Magnitude < 64 then
						remotePrimaryFire:FireClient(players[a], itemId, toolModel, targetPoints);
					end

				end
			end
		end
		
	elseif configurations.BulletMode == modAttributes.BulletModes.Projectile then
		local projectileId = storageItem:GetValues("CustomProj") or configurations.ProjectileId;

		local projectiles = shotPacket.Projectiles;
		local projectileCount = type(properties.Multishot) == "table" and (properties.Multishot.Max) or properties.Multishot;

		if configurations.Triplethreat then
			projectileCount = 3;
		end

		for a=1, math.min(#projectiles, projectileCount) do
			local projectileData = projectiles[a];

			local projectileObj = modProjectile.Fire(projectileId, projectileData.Origin, projectileData.Orientation, nil, shotPacket.Player, toolModule);
			projectileObj.StorageItem = storageItem;
			projectileObj.WeaponModel = toolModel;
			projectileObj.ServerProjNum = projectileData.ProjNum;

			projectileObj.DamageSource = newDamageSource;

			local arcConfig = projectileObj.ArcTracerConfig;

			if configurations.FocusDuration then
				if shotPacket.FocusCharge and shotPacket.FocusCharge > 0 then
					local charge = math.clamp(shotPacket.FocusCharge, 0, 1);
					projectileObj.Charge = charge;
				end
			end

			projectileObj.TargetableEntities = modConfigurations.TargetableEntities;

			if projectileObj.Prefab:CanSetNetworkOwnership() then projectileObj.Prefab:SetNetworkOwner(nil); end

			projectileData.Direction = projectileData.Direction.Unit;
			local velocity = projectileData.Direction * arcConfig.Velocity;
			local projectileOrigin = projectileData.Origin.Position;

			local arcTracer = projectileObj.ArcTracer;

			if modConfigurations.AutoAdjustProjectileAim == true then
				local timelapse = projectileData.Dist/arcConfig.Velocity;
				velocity = arcTracer:GetVelocityByTime(
					projectileOrigin,
					projectileData.RayEndPoint, timelapse);

			end

			arcTracer.AddIncludeTags = arcConfig.AddIncludeTags;

			modProjectile.ServerSimulate(projectileObj, projectileOrigin, velocity);
		end
		
	end
	
end

-- !outline ToolService.ReloadWeapon(packet)
function ToolService.ReloadWeapon(packet)
	packet.StorageItem = packet.StorageItem;
	packet.ToolModel = packet.ToolModel;
	packet.ToolModule = packet.ToolModule;
	
	local storageItem = packet.StorageItem;
	local toolHandle = packet.ToolModel.PrimaryPart;
	
	local toolModule;
	
	if packet.ToolModule then
		toolModule = packet.ToolModule;
	end
	
	local configurations, properties, audio = toolModule.Configurations, toolModule.Properties, toolModule.Audio;

	local ammo = storageItem:GetValues("A") or configurations.AmmoLimit;
	local maxAmmo = storageItem:GetValues("MA") or configurations.MaxAmmoLimit;
	
	properties.Ammo = ammo;
	properties.MaxAmmo = maxAmmo;
	
	if properties.Reloading then return false; end;
	if properties.Ammo == configurations.AmmoLimit then return false; end;
	if maxAmmo <= 0 then return false; end;
	properties.Reloading = true;
	
	local magazinePart = packet.ToolModel:FindFirstChild("Magazine");
	
	local reloadTime = math.clamp(properties.ReloadSpeed-0.2, 0.05, 40);
	if packet.IsPAT then
		reloadTime = reloadTime * 3;
		
		if magazinePart then
			local oldPar = magazinePart.Parent;
			task.spawn(function()
				magazinePart.Parent = nil;
				task.wait(reloadTime);
				magazinePart.Parent = oldPar;
			end)
		end
	end
		
	if configurations.ReloadMode == modAttributes.ReloadModes.Full then

		local reloadSound;
		if audio.Reload then
			reloadSound = modAudio.Play(audio.Reload.Id, toolHandle);
			reloadSound.PlaybackSpeed = reloadSound.TimeLength/properties.ReloadSpeed;
		end

		task.wait(reloadTime);

		if not workspace:IsAncestorOf(packet.ToolModel) then
			return false;
		end
		
		local ammoNeeded = configurations.AmmoLimit - ammo;
		local newMaxAmmo = maxAmmo - ammoNeeded;
		local newAmmo = configurations.AmmoLimit;
		if newMaxAmmo < 0 then newAmmo = maxAmmo+ammo; newMaxAmmo = 0 end;
		properties.Ammo = newAmmo;
		properties.MaxAmmo = configurations.InfiniteAmmo == nil and newMaxAmmo or configurations.MaxAmmoLimit;
		
		storageItem:SetValues("A", properties.Ammo);
		storageItem:SetValues("MA", properties.MaxAmmo);
		
	elseif configurations.ReloadMode == modAttributes.ReloadModes.Single and ammo < configurations.AmmoLimit then
		local ammoCost = configurations.AmmoCost or 1;

		if configurations.DualShell then
			ammoCost = 2;
		end
		if ammo + ammoCost > configurations.AmmoLimit then
			ammoCost = math.clamp(configurations.AmmoLimit-ammo, 1, ammoCost);
		end

		if audio.Reload then
			modAudio.Play(audio.Reload.Id, toolHandle);
		end
		task.wait(reloadTime);

		if not workspace:IsAncestorOf(packet.ToolModel) then
			return false;
		end

		local ammoFromMA = 0;
		if maxAmmo > 0 and ammo < configurations.AmmoLimit then
			ammoFromMA = math.min(ammoCost, maxAmmo);

			ammo = ammo +ammoFromMA;
			maxAmmo = configurations.InfiniteAmmo == nil and (maxAmmo - ammoFromMA) or configurations.MaxAmmoLimit;

			storageItem:SetValues("A", ammo);
			storageItem:SetValues("MA", maxAmmo);
		end
		
	end
	
	properties.Reloading = false;
	return true;
end

return ToolService;
