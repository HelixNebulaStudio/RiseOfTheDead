local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
repeat task.wait() until shared.MasterScriptInit == true;

--== Variables;
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
local PhysicsService = game:GetService("PhysicsService");
local MemoryStoreService = game:GetService("MemoryStoreService");

local weaponsLibraryModule = game.ReplicatedStorage.Library.Weapons;

local modWeaponsLibrary = require(weaponsLibraryModule);
local modSyncVariable = require(game.ReplicatedStorage.Library.SyncVariable);
local modAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local modWeaponsMechanics = require(game.ReplicatedStorage.Library.WeaponsMechanics);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modAppearanceLibrary = require(game.ReplicatedStorage.Library.AppearanceLibrary);
local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modPseudoRandom = require(game.ReplicatedStorage.Library.PseudoRandom);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);
local modClothingLibrary = require(game.ReplicatedStorage.Library.ClothingLibrary);
local modItemUnlockablesLibrary = require(game.ReplicatedStorage.Library.ItemUnlockablesLibrary);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);

local toolHandlers = game.ServerScriptService.ServerLibrary.ToolHandlers;

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modPrefabManager = require(game.ServerScriptService.ServerLibrary.PrefabManager);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modRedeemService = require(game.ServerScriptService.ServerLibrary.RedeemService);

local dirRemotes = game.ReplicatedStorage.Remotes;
local bindIsInDuel = dirRemotes.IsInDuel;
local remoteEquipCosmetics = dirRemotes.AppearanceEditor.EquipCosmetics;


local bindPrimaryFire = dirRemotes.Weapons.ServerPrimaryFire;
local remoteCharacterRemote = modRemotesManager:Get("CharacterRemote");
local remotePrimaryFire = modRemotesManager:Get("PrimaryFire");
local remoteReloadWeapon = modRemotesManager:Get("ReloadWeapon");
local remoteDisguiseKitRemote = modRemotesManager:Get("DisguiseKitRemote");
local remoteGpsRemote = modRemotesManager:Get("GpsRemote");
local remoteInstrumentRemote = modRemotesManager:Get("InstrumentRemote");
local remoteReviveInteract = modRemotesManager:Get("ReviveInteract");
local remoteMysteryChest = modRemotesManager:Get("MysteryChest");


local bindUpdateTargetableEntities = script:WaitForChild("UpdateTargetableEntities");
local bindOnProjectileHit = dirRemotes.Weapons.OnProjectileHit;

local activeProjectiles = {};
local TargetableEntities = modConfigurations.TargetableEntities;
local random = Random.new();

--== Script;
function IsInDuel(player, targetName)
	if game.Players:FindFirstChild(targetName) == nil then return end;
	
	local classPlayer = modPlayers.GetByName(targetName);
	if classPlayer.Properties.Pvp and classPlayer.Properties.Pvp.InDuel and classPlayer.Properties.Pvp.InDuel == player.Name then
		return math.clamp(classPlayer.Properties.Pvp.DmgMultiplier or 1, 0.0001, 2);
	end
end
bindIsInDuel.OnInvoke = IsInDuel;

remoteCharacterRemote.OnServerEvent:Connect(function(player, action, paramPacket)
	local classPlayer = modPlayers.GetByName(player.Name);
	local t = tick();
	
	if action == 0 then -- 0 Force reset
		classPlayer:Kill(0);
		
	elseif action == 1 and t-(classPlayer.MotorCooldown or 0) >= 0.4 then -- 1 updatebodymotors
		classPlayer.MotorCooldown = t;
		
		if paramPacket.LowestFps then
			classPlayer.LowestFps = math.clamp(tonumber(paramPacket.LowestFps) :: number, 1, 999);
		end
		if paramPacket.AvgFps then
			classPlayer.AverageFps = math.clamp(paramPacket.AvgFps, 1, 999);
		end


		for _, oPlayer in pairs(game.Players:GetPlayers()) do
			if oPlayer ~= player then
				local distance = modPlayers.GetPlayerToPlayerDistanceCache(player, oPlayer);
				paramPacket.Character = player.Character;
				
				local fireChance = math.clamp(distance/128, 2, 7);
				if distance <= 64 or math.random(1, fireChance) == 1 then
					remoteCharacterRemote:FireClient(oPlayer, action, paramPacket);
				end
			end
		end
		
		local joints = typeof(paramPacket) == "table" and paramPacket or {};
		
		if classPlayer.Mount then
			if classPlayer.Mount.Passenger then
				for passChar, info in pairs(classPlayer.Mount.Passenger) do
					if info.Waist and joints.Waist then
						local motor = info.Waist;
						local data = joints.Waist;
						
						local properties = {};
						if data.Properties.C1 then
							local angX, angY, angZ = data.Properties.C1:ToEulerAnglesXYZ();
							properties.C1 = CFrame.new(motor.C1.Position) * CFrame.Angles(angX+math.rad(-5), 0, 0);
						end
						--if data.Properties.C0 then
						--	local angX, angY, angZ = data.Properties.C1:ToEulerAnglesXYZ();
						--	properties.C0 = CFrame.new(motor.C0.Position) * CFrame.Angles(angX, 0, 0);
						--end
						
						local tween = TweenService:Create(info.Waist, TweenInfo.new(0.6), properties);
						tween:Play();
					end
				end
			end
		end
		
	elseif action == 2 then
		local platformModel, groundPart = unpack(paramPacket);
		local dynamicPlatformModel = typeof(platformModel) == "Instance" and platformModel:IsA("Model") and platformModel or nil;
		
		classPlayer.DynamicPlatform = dynamicPlatformModel;
		classPlayer.GroundPart = groundPart;
		
	elseif action == 3 then
		-- climbing
		classPlayer.IsClimbing = paramPacket == true;
		
	elseif action == 4 then
		classPlayer.IsSwimming = paramPacket == true;

	elseif action == 5 then -- excess velocity;
		local playerVelocity = paramPacket;
		
		if playerVelocity >= 100 and modConfigurations.VelocityTriggerRagdoll == true then
			if classPlayer.Properties.Ragdoll == 0 then
				modStatusEffects.Ragdoll(player, true);
				
				task.wait(2);
				while classPlayer.Properties.Ragdoll ~= 0 do
					local vel = classPlayer.RootPart.Velocity.magnitude;
					
					task.wait(0.25);
					if vel <= 22 then break; end
				end
				
				if classPlayer.Properties.Ragdoll ~= 0 then
					modStatusEffects.Ragdoll(player, false);
				end
			end
			
		end
		
	end
	
end)

remoteReloadWeapon.OnServerEvent:Connect(function(client, weaponId, weaponModel, initial)
	if weaponModel == nil or weaponModel.Parent ~= client.Character then warn("ReloadWeapon>> Invalid weapon prefab."); return end;
	
	local profile = modProfile:Get(client);
	local inventory = profile.ActiveInventory;
	local playerSave = profile:GetActiveSave();
	local storageItem = inventory and inventory:Find(weaponId);
	
	if weaponId == "MockStorageItem" then
		storageItem = profile.MockStorageItem;
	end
	
	if storageItem == nil then
		Debugger:Warn("ReloadWeapon>> Weapon does not exist in inventory.");
		return;
	end
	
	local weaponModule = profile:GetItemClass(weaponId);
	local configurations = weaponModule.Configurations;
	local properties = weaponModule.Properties;
	local cache = weaponModule.Cache[weaponModel.Name];
	if cache == nil then
		weaponModule.Cache[weaponModel.Name] = {};
		cache = weaponModule.Cache[weaponModel.Name]; 
	end;
	
	local infAmmo = profile.InfAmmo;
	
	if initial then
		cache.InitialReloadTick = tick();
		cache.ReloadModel = weaponModel;
		
		modOnGameEvents:Fire("OnToolReload", client, storageItem, initial);
		return;
	end
		
	if weaponModel ~= cache.ReloadModel then
		Debugger:Log("ReloadWeapon>> Reloading cancelled mismatch model.");
		return;
	end
	
	local reloadTimeLapsed = tick()-cache.InitialReloadTick;
	local inValidTimeRange =( reloadTimeLapsed+0.3) >= properties.ReloadSpeed;
	
	if not inValidTimeRange then
		Debugger:Warn("Invalid reload, out of valid time", properties.ReloadSpeed)
		return; 
	end;
	
	
	local defaultAmmoId = storageItem:GetValues("AmmoId") or configurations.AmmoType;

	local activeAmmoId;
	local availableInvAmmo = 0;

	local function loadAmmoId(ammoItemId)
		local ammoItemsList = modStorage.ListItemIdFromStorages(ammoItemId, client, {"ammopouch"; "Inventory";});
		local storageAmmoCount = 0;
		for a=1, #ammoItemsList do
			storageAmmoCount = storageAmmoCount + ammoItemsList[a].Item.Quantity;
		end

		if storageAmmoCount > 0 then
			activeAmmoId = ammoItemId;
			availableInvAmmo = storageAmmoCount;

		end
	end
	
	if configurations.ReloadMode == modAttributes.ReloadModes.Full then
		local ammo = storageItem:GetValues("A") or configurations.AmmoLimit;
		ammo = math.min(ammo, configurations.AmmoLimit);
		
		local maxAmmo = infAmmo == nil and storageItem:GetValues("MA") or configurations.MaxAmmoLimit;
		
		local ammoNeeded = configurations.AmmoLimit - ammo;
		local newMaxAmmo = infAmmo == nil and (maxAmmo - ammoNeeded) or maxAmmo;
		local newAmmo = configurations.AmmoLimit;
		if newMaxAmmo < 0 then newAmmo = maxAmmo+ammo; newMaxAmmo = 0 end;
		
		if configurations.AmmoIds and newAmmo < configurations.AmmoLimit then
			Debugger:Log("Searching for ammo in inventory");
			
			if newAmmo <= 0 then
				for a=1, #configurations.AmmoIds do
					loadAmmoId(configurations.AmmoIds[a]);
					if activeAmmoId then break; end;
				end
				
			else
				loadAmmoId(defaultAmmoId);
			end
			
			
			if activeAmmoId then
				newMaxAmmo = 0;
				
				local addAmmo = math.clamp(availableInvAmmo, 0, configurations.AmmoLimit-ammo);
				newAmmo = ammo+addAmmo;
				
				modStorage.RemoveItemIdFromStorages(activeAmmoId, client, addAmmo, {"ammopouch"; "Inventory";});
				
				storageItem:SetValues("A", newAmmo);
				storageItem:SetValues("MA", newMaxAmmo);
				storageItem:SetValues("AmmoId", activeAmmoId);
			end
		end
		
		storageItem:SetValues("A", newAmmo);
		storageItem:SetValues("MA", newMaxAmmo);
		
		
	elseif configurations.ReloadMode == modAttributes.ReloadModes.Single then
		local ammo = storageItem:GetValues("A") or configurations.AmmoLimit;
		local maxAmmo = infAmmo == nil and storageItem:GetValues("MA") or configurations.MaxAmmoLimit;
		
		if maxAmmo > 1607317596421 then -- fix a bug;
			maxAmmo = math.min(maxAmmo, configurations.MaxAmmoLimit);
		end
		
		local ammoCost = configurations.AmmoCost or 1;
		if configurations.DualShell then
			ammoCost = 2;
		end
		if ammo + ammoCost > configurations.AmmoLimit then
			ammoCost = math.clamp(configurations.AmmoLimit-ammo, 1, ammoCost);
		end
		
		local ammoFromMA = 0;
		if maxAmmo > 0 and ammo < configurations.AmmoLimit then
			ammoFromMA = math.min(ammoCost, maxAmmo);

			ammo = ammo +ammoFromMA;
			maxAmmo = infAmmo == nil and (maxAmmo - ammoFromMA) or maxAmmo;
			
			storageItem:SetValues("MA", maxAmmo);
		end
		
		if configurations.AmmoIds and ammoCost-ammoFromMA > 0 then
			Debugger:Log("Searching for ammo in inventory");

			loadAmmoId(defaultAmmoId);
		end
		
		local ammoFromInv = 0;
		if ammoCost-ammoFromMA > 0 then
			ammoFromInv = math.min(ammoCost-ammoFromMA, availableInvAmmo);
		end
		if ammoFromInv > 0 then
			ammo = ammo + ammoFromInv;
			modStorage.RemoveItemIdFromStorages(activeAmmoId, client, ammoFromInv, {"ammopouch"; "Inventory";});
		end

		storageItem:SetValues("A", ammo);
		storageItem:SetValues("UnixTime", DateTime.now().UnixTimestampMillis);
	end

	--storageItem:Sync({"A"; "MA"});
	modOnGameEvents:Fire("OnToolReload", client, storageItem, initial);
end)

--== NPC Primary Fire;
bindPrimaryFire.Event:Connect(function(character, weaponModule, shotdata, targetable)
	Debugger:Warn("bindPrimaryFire deprecated?", debug.traceback());
	if character == nil then Debugger:Warn("Character missing.") return end;
	local humanoid = character:FindFirstChildWhichIsA("Humanoid") or nil;
	if humanoid and humanoid.Health <= 0 then return end;
	local rootPart = humanoid.RootPart;
	if rootPart == nil then Debugger:Warn("Character missing RootPart.") return end;
	
	if modConfigurations.RemoveForceFieldOnWeaponFire then
		local forcefield = character:FindFirstChildWhichIsA("ForceField") or nil;
		if forcefield then forcefield:Destroy() end;
	end

	if weaponModule then
		local configurations = weaponModule.Configurations;
		
		local ammo = configurations.Ammo or configurations.AmmoLimit;
		if ammo > 0 then
			if configurations.BulletMode == modAttributes.BulletModes.Hitscan then
				local victims, targetPoints = (shotdata.Victims or {}), (shotdata.TargetPoints or {});

				local newDamageSource = modDamagable.NewDamageSource{
					Dealer = character;
				};
				
				for a=1, #victims do
					local targetObject = victims[a].Object;
					local targetModel = targetObject.Parent;
					
					if targetModel then
						local damagable = modDamagable.NewDamagable(targetModel);


						local npcStatusModule = targetModel:FindFirstChild("NpcStatus");

						local humanoid = (npcStatusModule and require(npcStatusModule)) or targetModel:FindFirstChildWhichIsA("Humanoid");
						local targetDamageMultiplier = humanoid and TargetableEntities[humanoid.Name];
						
						local damage = configurations.Damage;
						local distance = nil;
						
						if configurations.DamageDropoff then
							distance = (rootPart.Position-targetObject.Position).Magnitude;
							damage = modWeaponsMechanics.DamageDropoff(weaponModule, damage, distance);
						end

						if humanoid and targetDamageMultiplier then
							damage = damage * targetDamageMultiplier
							
							if damagable:CanDamage(character) then
								modDamageTag.Tag(targetModel, character, (targetObject.Name == "Head" or targetObject:GetAttribute("IsHead") == true) and true or nil);

								task.spawn(function()
									newDamageSource.Damage = damage;
									newDamageSource.DamageType = newDamageSource.DamageType;

									local dir = (targetObject.Position-rootPart.Position).Unit;
									local targetRootPart: BasePart = humanoid.RootPart;

									local killImpulseForce = configurations.KillImpulseForce or 5;
									newDamageSource.DamageForce = dir*killImpulseForce;
									newDamageSource.DamagePosition = targetObject.Position;

									damagable:TakeDamagePackage(newDamageSource);
								end)
							end
							
						elseif damagable and damagable.Object.ClassName == "Destructible" then
							if damagable:CanDamage(character) then
								task.spawn(function()
									newDamageSource.Damage = damage;
									newDamageSource.DamageType = newDamageSource.DamageType;

									damagable:TakeDamagePackage(newDamageSource);
								end)
							else
								Debugger:Warn("Can't damage", targetModel);
							end
						end

					end
				end
				
			elseif weaponModule.Configurations.BulletMode == modAttributes.BulletModes.Projectile then

			end
		else
			Debugger:Warn("Character ("..character.Name..") Attempted to fire without ammo.");
		end
	end
end)


-- !outline: remotePrimaryFire.OnServerEvent(client, weaponId, weaponModel, shotdata)
remotePrimaryFire.OnServerEvent:Connect(function(client, weaponId, weaponModel, shotdata)
	if weaponModel == nil or weaponModel.Parent ~= client.Character then warn("PrimaryFire>> Invalid weapon prefab."); return end;
	if weaponModel.PrimaryPart == nil then warn("PrimaryFire>>  Missing Handle."); return end;

	local shotRandom = Random.new(client.UserId);
	
	local profile = modProfile:Get(client);
	local playerSave = profile:GetActiveSave();
	local inventory = profile.ActiveInventory;
	local storageItem = inventory and inventory:Find(weaponId);
	local classPlayer = modPlayers.Get(client);
	
	local weaponModule = profile:GetItemClass(weaponId);

	if weaponId == "MockStorageItem" then
		storageItem = profile.MockStorageItem;
	end
	
	local casualRandom = profile.Cache.CasualRandom or modPseudoRandom.new();
	
	local clientHumanoid = client.Character and client.Character:FindFirstChildWhichIsA("Humanoid") or nil;
	if clientHumanoid and clientHumanoid.Health <= 0 then return end;
	local clientRootPart = clientHumanoid.RootPart;
	if clientRootPart == nil then Debugger:Warn("Character missing RootPart.") return end;
	
	if modConfigurations.RemoveForceFieldOnWeaponFire then
		local forcefield = client.Character and client.Character:FindFirstChildWhichIsA("ForceField") or nil;
		if forcefield then forcefield:Destroy() end;
	end
	
	if weaponModule == nil then
		Debugger:Warn("Missing weaponModule", client, weaponId);
		return;
	end

	
	local configurations = weaponModule.Configurations;
	local properties = weaponModule.Properties;
	if weaponModule.Cache == nil then weaponModule.Cache = {}; end
	local cache = weaponModule.Cache[weaponModel.Name];
	if cache == nil then weaponModule.Cache[weaponModel.Name] = {}; cache = weaponModule.Cache[weaponModel.Name]; end;

	local itemId = configurations.ItemId;
	
	if profile.InfAmmo then
		configurations.InfiniteAmmo = profile.InfAmmo;
	end
	
	local timeSinceLastShot = (cache.LastShot and tick()-cache.LastShot or 99);
	local baseFirerate = 60/properties.Rpm;
	if cache.LastShot and timeSinceLastShot+0.3 < baseFirerate then --properties.FireRate
		warn("PrimaryFire>> "..client.Name.." fired "..weaponModel.Name.." too soon. Last shot:"..(math.ceil(timeSinceLastShot*10000)/10000).." Firerate:"..properties.FireRate);
		return;
	end
	cache.LastShot = tick();
	
	local realShotId = profile.Cache.ShotIdGen:NextInteger(1, 99);
	if shotdata.ShotId ~= realShotId then 
		warn("PrimaryFire>> "..client.Name.." fired "..weaponModel.Name.." Invalid shot id:"..shotdata.ShotId.." =/= "..realShotId);
		profile:SyncAuthSeed();
		profile.Cache.FailShot = (profile.Cache.FailShot or 0) +1;
		if profile.Cache.FailShot >= 5 then return end;
	end;
	if profile.Cache.FailShot and profile.Cache.FailShot > 0 then
		profile.Cache.FailShot = profile.Cache.FailShot -1;
	end
	
--	-- debug
--	if cache.LastShot then
--		warn("PrimaryFire>> Debug Last shot:"..(math.ceil(timeSinceLastShot*10000)/10000).." Firerate:"..properties.FireRate);
--	end
	
	local ammo = storageItem:GetValues("A") or configurations.AmmoLimit;
	local maxAmmo = storageItem:GetValues("MA") or configurations.MaxAmmoLimit;
	
	if ammo <= 0 then
		storageItem:Sync({"A"; "MA"});
		ammo = 1;
		
		Debugger:WarnClient(client, "Player ammo desync. A");
	end
	
	ammo = math.min(ammo, configurations.AmmoLimit);
	
	local ammoCost = math.min(configurations.AmmoCost or 1, ammo);
	
	if configurations.Triplethreat then
		ammoCost = math.min(ammo, 3);
	end
	if configurations.InfiniteAmmo == 2 then
		ammoCost = 0;
	end
	
	if configurations.Rocketman and shotdata.Rocketman and maxAmmo > 0 and clientHumanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
		maxAmmo = maxAmmo -ammoCost;
		storageItem:SetValues("MA", maxAmmo);
		
	else
		ammo = ammo -ammoCost;
		storageItem:SetValues("A", ammo);
		
	end
	
	local clientAmmoData = shotdata.AmmoData;
	if clientAmmoData == nil then
		Debugger:Warn("Player attempted to fire without ammo data.");
		return;
	end
	if clientAmmoData.Ammo ~= ammo or clientAmmoData.MaxAmmo ~= maxAmmo then
		storageItem:Sync({"A"; "MA"});
		Debugger:WarnClient(client, "Player ammo desync. B");
	end
	
	if ammo <= 0 and maxAmmo <= 0 then
		modMission:Progress(client, 2, function(mission)
			if mission.ProgressionPoint >= 7 and mission.ProgressionPoint <= 9 then
				if mission.SaveData.Kills > 0 then
					modEvents:NewEvent(client, {Id="m2restorepoint"; Point=mission.ProgressionPoint});
					mission.ProgressionPoint = 6;
				end
			end;
		end)
	end
	
	if shotdata.Direction == nil then Debugger:Log("Missing shot direction?!"); return end;
	
	local shotCache = {
		WeaponId = weaponId;
		Ammo = ammo;
		CritProcs = 0;
		CasualRandom = casualRandom;
		FocusCharge = shotdata.FocusCharge;
	};

	local newDamageSource = modDamagable.NewDamageSource{
		Dealer = client;
		DamageId=realShotId;

		ToolStorageItem=storageItem;
		ToolModel=weaponModel;
		ToolModule=weaponModule;
	};
	
	if configurations.BulletMode == modAttributes.BulletModes.Hitscan then
		local playersShot = {};
		local victims, targetPoints = (shotdata.Victims or {}), {};
				
		local targetsPierceable = (properties.Piercing or 0);
		local maxVictims = math.clamp(
			#victims,
			0, 
			(type(properties.Multishot) == "table" and (properties.Multishot.Max + targetsPierceable) or properties.Multishot + targetsPierceable)
		);
		for a=1, maxVictims do
			if shotdata.TargetPoints and shotdata.TargetPoints[a] then
				table.insert(targetPoints, shotdata.TargetPoints[a]);
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
			if targetModel and (targetObject:IsDescendantOf(workspace) or targetObject:IsDescendantOf(game.ReplicatedStorage.Replicated)) then
				local distance = client:DistanceFromCharacter(targetObject.Position);
				if distance >= 512 then return end;
				
				local damagable = modDamagable.NewDamagable(targetModel);

				local npcStatusModule = targetModel:FindFirstChild("NpcStatus");
				
				local humanoid = (npcStatusModule and require(npcStatusModule)) or targetModel:FindFirstChildWhichIsA("Humanoid");
				local targetDamageMultiplier = humanoid and TargetableEntities[humanoid.Name];
				--
				
				local preModDamage = configurations.PreModDamage;
				local basedamage = configurations.BaseDamage; -- configurations.Damage or 1
				local damage = configurations.Damage;
				
				--== Duel
				local duelDmgMulti = IsInDuel(client, targetModel.Name);
				if duelDmgMulti then targetDamageMultiplier = duelDmgMulti end;
				--== Duel
				
				-- Shot verification
				if weaponModel.PrimaryPart == nil then return end;
				local shotOrigin = weaponModel.PrimaryPart.Position;
				local ray = Ray.new(shotOrigin, shotdata.Direction);
				
				local closestDistance = ray:Distance(targetObject.Position);
				local maxDistance = math.max(targetObject.Size.X, targetObject.Size.Y, targetObject.Size.Z, 4)+5;
				
				if humanoid and humanoid.RootPart then
					maxDistance = maxDistance * math.clamp(humanoid.RootPart.Velocity.Magnitude, 1, 100);
				end
				
				if closestDistance >= maxDistance then
					Debugger:Warn("Player ("..client.Name..") did an illegal shot. Distance:",closestDistance.."/"..maxDistance);
					return;
				end;
				-- Shot verification
				
				
				local hasPlayerInstance = humanoid and game.Players:GetPlayerFromCharacter(humanoid.Parent);
				if hasPlayerInstance then
					playersShot[hasPlayerInstance.Name] = hasPlayerInstance;
				end
				
				-- Damage modification processing
				
				shotCache.HitPart = targetObject;
				shotCache.CritOccured = nil;
				shotCache.Index = a;
				damage = modWeaponsMechanics.DamageModification(weaponModule, shotCache, client);

				-- Damage post processing

				if classPlayer and classPlayer.Properties and classPlayer.Properties.FrostivusSpirit then
					damage = damage + math.clamp(classPlayer.Properties.FrostivusSpirit.Amount, 0, 10000);
				end

				if targetIndex and targetIndex >= 2 then
					local piercingDamageReduction = 0.5;
					damage = damage * piercingDamageReduction ^ targetIndex;
				end
				
				if configurations.DamageDropoff then
					damage = modWeaponsMechanics.DamageDropoff(weaponModule, damage, distance);
				end
				
				-- Apply damage;

				newDamageSource.TargetModel=targetModel;
				newDamageSource.TargetPart=targetObject;
				
				if humanoid and targetDamageMultiplier then
					if humanoid.ClassName == "NpcStatus" and not humanoid:CanTakeDamageFrom(client) then
						return;
					end
					
					modDamageTag.Tag(targetModel, client.Character, (targetObject.Name == "Head" or targetObject:GetAttribute("IsHead") == true) and true or nil);
					
					damage = damage * targetDamageMultiplier;
					
					local damageSourceClone = newDamageSource:Clone();
					damageSourceClone.Damage = damage;
					modWeaponsMechanics.ProcessModHooks(damageSourceClone);
					
					if humanoid.ClassName == "NpcStatus" then
						local npcModule = humanoid:GetModule();
						
						if configurations.WeaponType == modAttributes.WeaponType.Pistol then
							
						elseif configurations.WeaponType == modAttributes.WeaponType.Rifle then
							if humanoid.FloorMaterial and npcModule.IsFrozen ~= true then
								if npcModule == nil or npcModule.KnockbackResistant == nil then 
									local dir = (humanoid.RootPart.Position-clientRootPart.Position).Unit;
									humanoid.RootPart.Velocity = humanoid.RootPart.Velocity + dir*50;
								end
							end
							
						elseif configurations.WeaponType == modAttributes.WeaponType.Shotgun then
							newDamageSource.BreakJoint = math.random(1, math.max(maxVictims, 2)) == 1;
			
						end

						if npcModule.WeakPoint then
							npcModule.WeakPoint(targetObject, function()
								local skill = profile.SkillTree:GetSkill(client, "weapoi");
								local level, skillStats = profile.SkillTree:CalStats(skill.Library, skill.Points);
								local wpMulti = (skillStats.Percent.Default + skillStats.Percent.Value)/100;
								
								local add = preModDamage * wpMulti;
								
								damage = damage + add;
								shotCache.CritOccured = "Crit";
							end);
						end
					end
					
					if hasPlayerInstance and damage > 0 then
						modWeaponsMechanics.BulletHitSound{
							BasePart=targetObject;
						}
					end
					
					if damagable:CanDamage(client) then
						task.spawn(function()
							newDamageSource.Damage = damage;
							newDamageSource.DamageType = newDamageSource.DamageType or shotCache.CritOccured;
							newDamageSource.IsCritDamage = shotCache.CritOccured == "Crit";
							
							local targetRootPart: BasePart = humanoid.RootPart;
							local dir = (targetRootPart.Position-clientRootPart.Position).Unit;

							local killImpulseForce = configurations.KillImpulseForce or 5;
							
							if storageItem:GetValues("KillImpulseForce") then
								killImpulseForce = storageItem:GetValues("KillImpulseForce");
								Debugger:Warn("Use KillImpulseForce", killImpulseForce);
							end
							
							newDamageSource.DamageForce = dir*killImpulseForce;
							newDamageSource.DamagePosition = targetObject.Position;
							
							damagable:TakeDamagePackage(newDamageSource);
						end)
					end
					
					
				elseif damagable and damagable.Object.ClassName == "Destructible" then
					if damagable:CanDamage(client) then

						modWeaponsMechanics.ProcessModHooks(newDamageSource);
						
						if damagable.Object.NotifyDamageInfo then
							local shotPrint = "";
							shotPrint = shotPrint.."Damage: ".. modFormatNumber.Beautify(math.round(damage*1000)/1000);
							shotPrint = shotPrint.."\nShot Distance: ".. modFormatNumber.Beautify(math.round(distance*100)/100)
							
							shared.Notify(client, shotPrint, "Inform");
						end
						
						task.spawn(function()
							newDamageSource.Damage = damage;
							newDamageSource.DamageType = shotCache.CritOccured or newDamageSource.DamageType;

							damagable:TakeDamagePackage(newDamageSource);
						end)
					else
						Debugger:Warn("Can't damage", targetModel);
					end
					
				end
			end
		end
		
		local players = game.Players:GetPlayers();
		for a=1, #players do
			if modConfigurations.PvpMode then
				if players[a] ~= client then
					remotePrimaryFire:FireClient(players[a], itemId, weaponModel, shotdata.TargetPoints);
				end
				
			else
				local pCharacter = players[a].Character;
				local pRootPart = pCharacter ~= nil and pCharacter:FindFirstChild("HumanoidRootPart") or nil;
				local cRootPart = clientHumanoid.RootPart;
				
				if playersShot[players[a].Name] then
					remotePrimaryFire:FireClient(players[a], itemId, weaponModel, targetPoints);
					
				elseif pRootPart and cRootPart then
					if players[a] ~= client and pRootPart and client:DistanceFromCharacter(pRootPart.CFrame.p) < 64 then
						remotePrimaryFire:FireClient(players[a], itemId, weaponModel, targetPoints);
					end
					
				end
			end
		end
		
	elseif configurations.BulletMode == modAttributes.BulletModes.Projectile then
		local projectileId = storageItem:GetValues("CustomProj") or configurations.ProjectileId; --inventory:GetValues(weaponId, "CustomProj")
		
		local head = client.Character and client.Character:FindFirstChild("Head") or nil;
		local headOrigin = head.Position or clientRootPart.Position;
		
		local projectiles = shotdata.Projectiles;
		local projectileCount = type(properties.Multishot) == "table" and (properties.Multishot.Max) or properties.Multishot;
		
		if configurations.Triplethreat then
			projectileCount = 3;
		end

		for a=1, math.min(#projectiles, projectileCount) do
			local projectileData = projectiles[a];
			
			local projectileObj = modProjectile.Fire(projectileId, projectileData.Origin, projectileData.Orientation, nil, client, weaponModule);
			projectileObj.StorageItem = storageItem;
			projectileObj.WeaponModel = weaponModel;
			projectileObj.ServerProjNum = projectileData.ProjNum;

			projectileObj.DamageSource = newDamageSource;
			
			local arcConfig = projectileObj.ArcTracerConfig;
			
			if configurations.FocusDuration then
				if shotdata.FocusCharge and shotdata.FocusCharge > 0 then
					local charge = math.clamp(shotdata.FocusCharge, 0, 1);
					projectileObj.Charge = charge;
				end
			end
			
			projectileObj.TargetableEntities = TargetableEntities;
			
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
	
end)



local modDisguiseMechanics = require(game.ReplicatedStorage.Library.DisguiseMechanics);

function remoteDisguiseKitRemote.OnServerInvoke(player, id, action, disguiseId)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local storageItem, storage = modStorage.FindIdFromStorages(id, player);
	
	--local inventory = profile.ActiveInventory;
	--local storageItem = inventory and inventory:Find(id);
	local traderProfile = profile and profile.Trader;
	
	if storageItem == nil then Debugger:Warn("StorageItem(",id,") does not exist."); return end;
	local disguiseLib = modDisguiseMechanics.Library:Find(disguiseId);
	
	if storageItem.ItemId == "disguisekit" then
		if disguiseLib and action == "disguise" then
			if modBranchConfigs.IsWorld("Slaughterfest") then
				Debugger:Warn("Can't manual disguise in Slaughterfest");
				return;
			end
			
			local disguises = storage:GetValues(id, "Disguises") or {};
			
			if disguises[disguiseId] or disguiseLib.Price == nil then
				modDisguiseMechanics:Disguise(player, disguiseId);
			else
				Debugger:Warn("Failed to disguise, not yet unlocked.", disguiseId);
			end
			
		elseif action == "open" then
			local playerKills = activeSave and activeSave.GetStat and activeSave:GetStat("Kills");
			if playerKills then
				local kills = storage:GetValues(id, "InitKills");
				local owner = storage:GetValues(id, "UserId");
				
				if kills == nil then
					storage:SetValues(id, {UserId=player.UserId; InitKills=playerKills});
					
				elseif owner ~= player.UserId then
					storage:SetValues(id, {UserId=player.UserId; InitKills=playerKills});
				
				else -- cap kills
					local kCount = math.clamp(playerKills-kills, 0, 5000);
					storage:SetValues(id, {UserId=player.UserId; InitKills=playerKills-kCount});
					
				end
			end
			return;
		
		elseif disguiseLib and disguiseLib.Price and (action == "purchaseKills" or action == "purchaseGold") then
			local disguises = storage:GetValues(id, "Disguises") or {};
			
			if action == "purchaseKills" then
				local playerKills = activeSave and activeSave.GetStat and activeSave:GetStat("Kills");
				local initKills = storage:GetValues(id, "InitKills")
				
				if initKills and (playerKills-initKills)>= disguiseLib.Price then
					if disguises[disguiseId] == nil then
						disguises[disguiseId] = 1;
						
						initKills = initKills + disguiseLib.Price;
						storage:SetValues(id, {Disguises=disguises; InitKills=initKills});
						return 1;
					else
						return 2;
					end
					
				else
					return 3;
				end
				
			elseif action == "purchaseGold" then
				local playerGold = traderProfile.Gold;

				if playerGold >= disguiseLib.Price then
					if disguises[disguiseId] == nil then
						disguises[disguiseId] = 1;
						storage:SetValues(id, {Disguises=disguises});
						traderProfile:AddGold(-disguiseLib.Price);
						modAnalytics.RecordResource(player.UserId, disguiseLib.Price, "Sink", "Gold", "Usage", "disguisekit");
						return 1;
					else
						return 2;
					end
				else
					return 3;
				end
			end
			
		end
	else
		Debugger:Log("Attempt to disguise without disguise kit.")
	end
end


function remoteEquipCosmetics.OnServerInvoke(player, itemId, packageId)
	local clothingLibrary = modClothingLibrary:Find(itemId);

	local itemUnlockableLib = modItemUnlockablesLibrary:Find(packageId);
	packageId = itemUnlockableLib and itemUnlockableLib.PackageId or itemId;

	local accessoryData = clothingLibrary and clothingLibrary.AccessoryData and clothingLibrary.AccessoryData[packageId];
	if accessoryData == nil then return end;
	
	local prefabGroup = modAppearanceLibrary:GetPrefabGroup(clothingLibrary.GroupName, packageId);
	modPrefabManager:LoadPrefab(prefabGroup, game.ReplicatedStorage.Prefabs.Cosmetics);

	return accessoryData;
end

local modMapLibrary = require(game.ReplicatedStorage.Library.MapLibrary);
modMapLibrary:Initialize();
local modGpsLibrary = require(game.ReplicatedStorage.Library.GpsLibrary);

function remoteGpsRemote.OnServerInvoke(player, id, action, gpsId)
	local classPlayer = modPlayers.Get(player);
	local rootPart = classPlayer.RootPart;
	
	local layerName, layerData = modMapLibrary:GetLayer(rootPart.Position);
	local gpsLib = modGpsLibrary:Find(gpsId);

	local storageItem, storage = modStorage.FindIdFromStorages(id, player);
	local unlock = storage:GetValues(id, "Gps") or {};
	
	local profile = modProfile:Get(player);
	local activeSave = profile and profile:GetActiveSave();
	local traderProfile = profile and profile.Trader;
	
	local function mission49Check()
		if gpsId == "w1office" and modMission:Progress(player, 49) then
			modMission:Progress(player, 49, function(mission)
				if profile.Collectibles.vrm then
					mission.ProgressionPoint = 5;
				else
					mission.ProgressionPoint = 4;
				end
			end)
		end
	end
	
	if action == "setmarker" then
		if gpsId == "w1office" and modMission:Progress(player, 49) then
			modMission:Progress(player, 49, function(mission)
				if mission.ProgressionPoint == 2 then
					mission.ProgressionPoint = 3;
				end;
			end)
		end
		
	elseif action == "unlock" then
		
		if gpsLib and gpsLib.Locations then
			for a=1, #gpsLib.Locations do
				if gpsLib.Locations[a] == layerName then
					if unlock[gpsLib.Id] == nil then
						unlock[gpsLib.Id] = 1;
						storage:SetValues(id, {Gps=unlock});
						shared.Notify(player, "Unlocked "..gpsLib.Name.." on GPS.", "Reward");
						mission49Check();
						
					else
						shared.Notify(player, "Already unlocked "..gpsLib.Name..".", "Negative");
						
					end
					return 0, unlock;
				end
			end
			-- location mismatch;
			shared.Notify(player, "You are not within the area "..gpsLib.Name.." to unlock it, or you can unlock it with Gold.", "Negative");
		end
		
	elseif action == "unlockGold" then
		if unlock[gpsLib.Id] == nil then
			local playerGold = traderProfile.Gold;
			
			if playerGold >= 100 then
				unlock[gpsLib.Id] = 1;
				storage:SetValues(id, {Gps=unlock});
				traderProfile:AddGold(-100);
				shared.Notify(player, "Unlocked "..gpsLib.Name.." on GPS.", "Reward");
				modAnalytics.RecordResource(player.UserId, 100, "Sink", "Gold", "Usage", "gps");
				mission49Check();
				return 1;
				
			else
				return 3;
				
			end
			
		else
			shared.Notify(player, "Already unlocked "..gpsLib.Name..".", "Negative");
			return 2;
		end
		
	elseif action == "travel" then
		local playerMoney = activeSave:GetStat("Money");
		local cost = modGpsLibrary:GetTravelCost(activeSave.LastFastTravel, profile);

		if gpsLib.FreeTravel then
			cost = 0;
		end
		
		local playerMissions = modMission.GetMissions(player.Name);
		if playerMissions then
			for a=1, #playerMissions do
				local mission = playerMissions[a];
				if mission.Type == 1 then
					local library = modMissionLibrary.Get(mission.Id);
					
					local fastTravelDisabled = false;

					if library.CanFastTravelWhenActive == false then
						fastTravelDisabled = true;
					end
					if typeof(library.CanFastTravelWhenActive) == "table" then
						if table.find(library.CanFastTravelWhenActive, tonumber(mission.ProgressionPoint) or 0) then
							fastTravelDisabled = true;
						end
					end
					
					if fastTravelDisabled then
						shared.Notify(player, ("Can not fast travel when mission \"$missionName\" is active."):gsub("$missionName", library.Name), "Negative");
						return 2;
					end
				end
			end
		end
		
		if unlock[gpsLib.Id] or gpsLib.UnlockedByDefault == true then
			mission49Check();
			if playerMoney < cost then return 1 end;
			
			activeSave.Gps = gpsLib.Id
			activeSave.Spawn = gpsLib.SetSpawn;
			
			if gpsLib.FreeTravel then
			else
				activeSave.LastFastTravel = modSyncTime.GetTime();
			end
			
			activeSave:AddStat("Money", -cost);
			activeSave:Sync();
			
			shared.Notify(player, "Traveling to "..gpsLib.Name..".", "Reward");

			if modBranchConfigs.WorldName == gpsLib.WorldName then
				task.delay(0.5, function()
					if gpsLib.Position then
						local newSpawnCFrame = CFrame.new(gpsLib.Position);
						shared.modAntiCheatService:Teleport(player, newSpawnCFrame);
					end
				end)
				return 2;
			else
				task.spawn(function()
					repeat
						modServerManager:Travel(player, gpsLib.WorldName);
						task.wait(5);
					until not player:IsDescendantOf(game.Players)
				end)
				return 0;
			end
		end
	end
end

remoteInstrumentRemote.OnEvent:Connect(function(player, packet)
	packet = modRemotesManager.Uncompress(packet);
	
	local storageItemId = packet.StorageItemID;
	local toolModels = packet.Prefabs;
	
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local storageItem, storage = modStorage.FindIdFromStorages(storageItemId, player);
	
	local character = player.Character;
	if character == nil then Debugger:Warn("Missing Character"); return end;
	for a=1, #toolModels do if not toolModels[a]:IsDescendantOf(character) then Debugger:Warn("Tool does not belong to player."); return end end;
	if storageItem == nil then Debugger:Warn("StorageItem(",storageItemId,") does not exist."); return end;
	local itemId = storageItem.ItemId;
	
	local handler = profile:GetToolHandler(storageItem, modTools[itemId], toolModels);
	if handler and handler.ToolConfig and handler.ToolConfig.Instrument and #toolModels > 0 then
		local prefab = toolModels[1];
		local handle = prefab.PrimaryPart;

		packet.OwnerPlayer = player;
		packet.Instrument = handler.ToolConfig.Instrument;
		
		modOnGameEvents:Fire("OnInstrumentPlay", player, packet.Instrument, packet.Data);
		local players = {};
		for _, oPlayer in pairs(game.Players:GetPlayers()) do
			if oPlayer ~= player and oPlayer:DistanceFromCharacter(handle:GetPivot().Position) <= 128 then
				table.insert(players, oPlayer);
			end
		end
		
		
		remoteInstrumentRemote:Fire(modRemotesManager.Players(players), modRemotesManager.Compress(packet));
		--for _, oPlayer in pairs(game.Players:GetPlayers()) do
		--	if oPlayer ~= player and oPlayer:DistanceFromCharacter(handle:GetPivot().Position) <= 128 then
		--		remoteInstrumentRemote:FireClient(oPlayer, player, handle, handler.ToolConfig.Instrument, ...);
		--	end
		--end
	end
end)
--remoteInstrumentRemote.OnServerEvent:Connect(function(player, storageItemId, toolModels, ...)
--	local profile = modProfile:Get(player);
--	local activeSave = profile:GetActiveSave();
--	local storageItem, storage = modStorage.FindIdFromStorages(storageItemId, player);
	
--	local character = player.Character;
--	if character == nil then Debugger:Warn("Missing Character"); return end;
--	for a=1, #toolModels do if not toolModels[a]:IsDescendantOf(character) then Debugger:Warn("Tool does not belong to player."); return end end;
--	if storageItem == nil then Debugger:Warn("StorageItem(",storageItemId,") does not exist."); return end;
--	local itemId = storageItem.ItemId;
	
--	local handler = profile:GetToolHandler(storageItem, modTools[itemId], toolModels);
--	if handler and handler.ToolConfig and handler.ToolConfig.Instrument and #toolModels > 0 then
--		local prefab = toolModels[1];
--		local handle = prefab.PrimaryPart;

--		modOnGameEvents:Fire("OnInstrumentPlay", player, handler.ToolConfig.Instrument, ...);
--		for _, oPlayer in pairs(game.Players:GetPlayers()) do
--			if oPlayer ~= player and oPlayer:DistanceFromCharacter(handle:GetPivot().Position) <= 128 then
--				remoteInstrumentRemote:FireClient(oPlayer, player, handle, handler.ToolConfig.Instrument, ...);
--			end
--		end
--	end
--end)



remoteReviveInteract.OnServerEvent:Connect(function(player, rawInteractData, startRevive)
	if rawInteractData == nil then return end;
	local interactScript = rawInteractData.Script;
	if interactScript == nil then Debugger:Warn("Missing interact script.") return end;
	
	local interactData = shared.saferequire(player, interactScript);
	if interactData == nil then return "Invalid interact object." end;
	
	local classPlayer = modPlayers.Get(player);
	
	local profile = modProfile:Get(player);
	if profile == nil or profile.EquippedTools.ID == nil then Debugger:Warn("Not equipping any tools.") return end;
	local activeToolId = profile.EquippedTools.ID;
	
	local inventory = profile.ActiveInventory;
	local storageItem = inventory and inventory:Find(activeToolId);
	
	if storageItem == nil then Debugger:Warn("Missing active tool item.") return end;
	local toolLib = modTools[storageItem.ItemId];
	
	if toolLib == nil or toolLib.WoundEquip ~= true then Debugger:Warn("Invalid revive item.") return end;
	
	local revivePlayer = interactData.Player;
	if revivePlayer == nil then
		revivePlayer = player;
		Debugger:Log("Reviving self revivePlayer ", revivePlayer);
	end
	
	if revivePlayer == nil then Debugger:Warn("Missing revivePlayer") return end;
	
	local reviveClassPlayer = modPlayers.Get(revivePlayer);
	local toolConfig = toolLib.NewToolLib();
	
	
	if startRevive then
		reviveClassPlayer.RevivingTick = tick();
		
	else
		if reviveClassPlayer.RevivingTick == nil then Debugger:Log("Revive cancelled") return end;
		
		local timelapsed = (tick()-reviveClassPlayer.RevivingTick);
		if timelapsed+0.5 >= 6 and timelapsed-0.5 <= 6 then
			local healAmount = toolConfig.Configurations.HealAmount;
			
			reviveClassPlayer:TakeDamagePackage(modDamagable.NewDamageSource{
				Damage=healAmount;
				Dealer=player;
				ToolStorageItem=storageItem;
				TargetPart=reviveClassPlayer.RootPart;
				DamageType="Heal";
			})
			
			inventory:Remove(activeToolId, 1);
			
			local itemLib = modItemsLibrary:Find(storageItem.ItemId);
			shared.Notify(player, ("1 $Item removed from your Inventory."):gsub("$Item", itemLib.Name), "Negative");
			shared.Notify(revivePlayer, "You have been healed.", "Positive");
			game.Debris:AddItem(interactScript, 0);
		end
	end
end)

function remoteMysteryChest.OnServerInvoke(player, interactableScript, redeemCode)
	local rPacket = {};
	
	if redeemCode == nil or interactableScript == nil or not interactableScript:IsA("ModuleScript") then rPacket.Error="Error#1"; return rPacket; end;
	
	local interactData = shared.saferequire(player, interactableScript);
	if interactData == nil then rPacket.Error="Error#1" return rPacket; end;
	
	if interactData.InterfaceName ~= "MysteryChestWindow" then rPacket.Error="Error#2"; return rPacket; end;
	redeemCode = redeemCode:sub(1, 100);
	
	local interactObject = interactableScript.Parent.PrimaryPart;
	if interactObject == nil or player:DistanceFromCharacter(interactObject.Position) >= 20 then rPacket.Error="Error#3"; return rPacket; end;
	
	local rewardsLib = modRewardsLibrary:Find(redeemCode);
	if rewardsLib == nil then rPacket.Error="Invalid Code"; return rPacket; end;
	
	
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	
	if activeSave == nil then rPacket.Error="Error#5"; return rPacket; end;
	if activeSave:GetStat("Level") < 20 then rPacket.Error="Requires Mastery Level 20"; return rPacket; end;
	
	local storageName = redeemCode;
	local storageConfig = {Persistent=true; Size=10; Expandable=false; MaxSize=10;};
	
	local storageId = storageName;
	local cacheStorages = profile:GetCacheStorages();
	
	local newStorage = activeSave.Storages[storageId];
	if newStorage == nil then
		
		local availableStock = modRedeemService:GetCodeCount(redeemCode);
		if availableStock == nil then rPacket.Error="Code no longer valid"; return rPacket; end;
		if availableStock <= 0 then rPacket.Error="Sorry, there's no more left to claim. :("; return rPacket; end;
		
		local redeemRPacket = modRedeemService:Redeem(player, redeemCode)
		if redeemRPacket.Claimed then
			activeSave.Storages[storageId] = modStorage.new(storageId, storageName, storageConfig.Size, player);
			newStorage = activeSave.Storages[storageId];
			
			local content = {};
			content = modDropRateCalculator.RollDrop(rewardsLib, player);
			
			for b=1, #content do
				local item = content[b];
				local itemId = item.ItemId;
				local quantity = type(item.Quantity) == "table" and random:NextInteger(item.Quantity.Min, item.Quantity.Max) or item.Quantity;
				local itemLib = modItemsLibrary:Find(itemId);
				newStorage:Add(itemId, {Quantity=quantity;}, function(event, storageItem)
					if event ~= "Success" then Debugger:Warn("Failed to create ("..storageId..") with its contents.", storageItem); return end;
					modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
				end)
			end
			
		elseif redeemRPacket.Skip then
			rPacket.Error="You have already claimed this!";
			return rPacket;
		end
	end
	
	if newStorage == nil then rPacket.Error="Error#6"; return rPacket; end;
	
	newStorage.MaxSize = storageConfig.MaxSize;
	newStorage.Size = storageConfig.MaxSize;
	newStorage.Expandable = storageConfig.Expandable;
	newStorage.Virtual = true;
	
	newStorage.Settings.WithdrawalOnly = true;
	newStorage.Settings.DestroyOnEmpty = true;
	newStorage.Settings.ScaleByContent=true;
	
	rPacket.Storage = newStorage:Shrink();
	
	return rPacket;
end
