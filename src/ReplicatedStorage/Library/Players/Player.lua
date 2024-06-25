local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Player = {};
local PlayerService = {
	Players = nil;
	SkillTree = nil;
	OnPlayerSpawn = nil;
	OnPlayerDied = nil;
};

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modGlobalVars = require(game.ReplicatedStorage.GlobalVariables);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modStatusLibrary = require(game.ReplicatedStorage.Library.StatusLibrary);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modCustomizeAppearance = require(game.ReplicatedStorage.Library.CustomizeAppearance);
local modMapLibrary = require(game.ReplicatedStorage.Library.MapLibrary);
local modLayeredVariable = require(game.ReplicatedStorage.Library.LayeredVariable);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);

local modMath = require(game.ReplicatedStorage.Library.Util.Math);

local remotePlayerProperties = modRemotesManager:Get("PlayerProperties");
local remoteDamagePacket = modRemotesManager:Get("DamagePacket");

local BaseHealth = 100;
local BaseMaxArmor = 0;
local BaseArmorRate = 0.1;


if RunService:IsClient() then
	localPlayer = game.Players.LocalPlayer;
	
else
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
end

function Player.new(playerInstance: Player)
	local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

	local modModEngineService = require(game.ReplicatedStorage.Library.ModEngineService);
	local moddedSelf = modModEngineService:GetModule(script.Name);
	
	local meta = {};
	local classPlayer = setmetatable({}, meta);
	
	meta.ClassName = "PlayerClass";
	meta.OnHealthChanged = modEventSignal.new("OnHealthChanged");
	meta.OnIsAliveChanged = modEventSignal.new("OnIsAliveChanged");
	meta.OnCharacterSpawn = modEventSignal.new("OnCharacterSpawn");
	meta.Died = modEventSignal.new("PlayerClassOnDied");
	meta.OnDamageTaken = modEventSignal.new("OnDamageTaken");
	meta.Garbage = modGarbageHandler.new();
	
	classPlayer.Name = playerInstance.Name;
	classPlayer.IsAlive = false;
	classPlayer.ClothingPropertiesCache = {};
	classPlayer.Properties = {
		BaseHealth = BaseHealth;
		BaseMaxArmor = BaseMaxArmor;
		BaseArmorRate = BaseArmorRate;
		
		Ragdoll = 0; -- 1 server ragdoll, 2 client ragdoll.
		
		OverHeal = 0;
		OverHealLimit = 35;
		
		HealthOverchargeSources = {};
		
		HealRate = 0;
		HealSources = {};
		
		Armor = 0;
		MaxArmor = BaseMaxArmor;
		
		ArmorOverchargeSources = {};
		
		ArmorRate = BaseArmorRate;
		ArmorRegenDelay = 1;
		ArmorSources = {};
		
		Oxygen = 100;
		
		TemperatureOffset = modLayeredVariable.new(0);
	};
	
	classPlayer.LastDamageTaken = tick()-15;
	classPlayer.LastDamageDealt = tick()-15;
	classPlayer.IsUnderWater = false;

	classPlayer.LowestFps = 999;
	classPlayer.AverageFps = 999;
	--==
	
	function meta:Spawn()
		if self.IsTryingToSpawn then return end;
		self.IsTryingToSpawn = true;
		
		local crTick = tick();
		while self.ClientReady ~= true do
			task.wait();
			if (tick()-crTick) >= 5 then
				Debugger:Warn(":Spawn() still waiting for ClientReady. (",playerInstance,").");
				crTick = tick();
			end
		end
		
		while playerInstance:GetAttribute("Ignited") ~= true do
			--Debugger:WarnClient(playerInstance, "Waiting for ignition..");
			task.wait();
			if (tick()-crTick) >= 5 then
				Debugger:Warn(":Spawn() still waiting for Ignited. (",playerInstance,").");
				crTick = tick();
			end
		end
		
		self.IsTryingToSpawn = nil;
		
		if not game.Players:IsAncestorOf(playerInstance) then 
			Debugger:Warn(":Spawn() canceled, playerInstance no longer in game.Players.")
			return 
		end;
		playerInstance:LoadCharacter();
	end
	
	function meta:Despawn()
		if not playerInstance:IsDescendantOf(game.Players) then return end;
		
		classPlayer.IsAlive = false;
		
		classPlayer:RefreshHealRate();
		if classPlayer.StatusCycle then
			classPlayer.StatusCycle:Disconnect();
		end
		
		if playerInstance.Character then
			playerInstance.Character:Destroy();
		end
	end
	
	function meta:Kill(killReason)
		if classPlayer.DeathDebounce then return end;
		classPlayer.DeathDebounce = true;
		
		if RunService:IsServer() then
			remotePlayerProperties:FireAllClients(classPlayer.Name, "Kill");

			local face = classPlayer.Head:FindFirstChild("face");
			if face then
				face.Texture = "rbxassetid://4644356184";
			end
			
			if classPlayer.IsAlive then
				classPlayer.IsAlive = false; -- Set only by server because it auto sync for client
			end;
		end
		
		classPlayer.Humanoid.Health = -1;
		classPlayer.Humanoid:ChangeState(Enum.HumanoidStateType.Dead);
		
		classPlayer:RefreshHealRate();

		if RunService:IsClient() and classPlayer.Character then
			classPlayer.IsAlive = classPlayer.Character:GetAttribute("IsAlive");
		end
		
		self.Died:Fire(classPlayer.Character, killReason);
		
		if RunService:IsStudio() then
			Debugger:Warn("[Studio] ClassPlayer:Kill");
		end
	end
	

	function meta:SetProperties(key, v)
		if playerInstance.Parent == nil then return end;
		local statusId = key;

		if typeof(v) == "table" and v.UniqueId then
			statusId = string.gsub(key, v.UniqueId, "");
		end
		
		if RunService:IsServer() then
			if v then
				local statusLib = modStatusLibrary:Find(statusId);
				local statusResistance = classPlayer.Properties.StatusResistance;
				
				if statusResistance and statusLib and statusLib.Buff == false and v.Duration and v.Expires and statusLib.Tags then
					if modGlobalVars.TableContains(statusLib.Tags, modStatusLibrary.DebuffTags) then
						local newDuration = v.Duration * (1-(statusResistance.Percent/100));
						local durDiff = v.Duration - newDuration;
						
						v.Duration = v.Duration - durDiff;
						v.Expires = v.Expires - durDiff;
					end
				end
			end
			if key == "Ragdoll" then
				classPlayer.Character:SetAttribute("Ragdoll", v);
			end
		end
		
		local oldPropertyValue = classPlayer.Properties[key];
		classPlayer.Properties[key] = v;
		
		if RunService:IsServer() then
			remotePlayerProperties:FireAllClients(classPlayer.Name, "SetProperties", key, v);
			
			if typeof(v) == "table" and v.PresistUntilExpire and v.Expires then
				local profile = shared.modProfile:Get(playerInstance);
				local activeSave = profile:GetActiveSave();
				local statusSave = activeSave.StatusSave;
				
				statusSave:Save(classPlayer.Properties);
			end
		end
		
		local lib = modStatusLibrary:Find(statusId);
		local statusClass = lib and lib.Module and require(lib.Module);
		
		if statusClass then
			if oldPropertyValue == nil and v ~= nil and statusClass.OnApply then
				statusClass.OnApply(classPlayer, classPlayer.Properties[key])
				
			elseif oldPropertyValue ~= nil and v == nil and statusClass.OnExpire then
				statusClass.OnExpire(classPlayer, oldPropertyValue);
			end
		end
	end
	

	function meta:SyncProperty(k)
		if playerInstance.Parent == nil then return end;
		if RunService:IsServer() then
			remotePlayerProperties:FireAllClients(classPlayer.Name, "SetProperties", k, classPlayer.Properties[k]);
		end
	end
	
	function meta:GetProperties(k)
		return classPlayer.Properties[k];
	end
	
	function meta:GetBodyEquipment(key)
		return self.Properties and self.Properties.BodyEquipments and self.Properties.BodyEquipments[key];
	end
	
	function meta:SyncIsAlive()
		if classPlayer.Character == nil then return end;
		
		if RunService:IsServer() then
			classPlayer.Character:SetAttribute("IsAlive", self.IsAlive);
			
		else
			self.IsAlive = classPlayer.Character:GetAttribute("IsAlive");
			
		end;
		
	end
	
	function meta:GetHealthInfo()
		local info = {
			Health=self.Humanoid.Health;
			MaxHealth=self.Humanoid.MaxHealth;
			Armor=classPlayer.Properties.Armor;
			MaxArmor=classPlayer.Properties.MaxArmor;
		}
		return info;
	end
	
	function meta:GetCFrame()
		return classPlayer and classPlayer.RootPart and classPlayer.RootPart.CFrame or nil;
	end
	
	function meta:TakeDamagePackage(damageSource)
		local damage = damageSource.Damage;
		local dealer = damageSource.Dealer;
		--local storageItem = damageSource.ToolStorageItem;
		local hitPart = damageSource.TargetPart;
		local damageType = damageSource.DamageType;
		local damageCategory = damageSource.DamageCate or modDamagable.DamageCategory.Generic;
		
		if damage == nil then return end;
		if self.Humanoid == nil then return end;

		if damageType == "Heal" and damage > 0 then
			damage = -damage;
		end
		
		if damage > 0 then
			if damageCategory == modDamagable.DamageCategory.Melee then
				local hasTireArmor = classPlayer.Properties.TireArmor;
				if hasTireArmor and hasTireArmor.Visible and math.random(1, 100) <= 73 then -- pseudo random
					damage = math.max(1, damage-40);
					modAudio.Play("TireArmorBlock", classPlayer.RootPart);
				end

			elseif damageCategory == modDamagable.DamageCategory.FumesGas then
				local gasProtection = classPlayer:GetBodyEquipment("GasProtection");
				local labCoatValue = classPlayer:GetBodyEquipment("LabCoat");

				if gasProtection then
					gasProtection = labCoatValue and gasProtection + labCoatValue or gasProtection;
					damage = damage * (1-gasProtection);
					
					if labCoatValue then
						self:SetProperties("LabCoat", {
							Expires=modSyncTime.GetTime() + 2;
						});
					end
				end
			end
		end
		
		--==
		local initDamage = damage;
		local armorDamage = damage;

		if damage > 0 then
			task.spawn(function()
				if dealer then
					if typeof(dealer) == "table" then

					elseif dealer:IsA("Player") then
						modDamageTag.Tag(classPlayer.Character, dealer.Character, hitPart and hitPart.Name == "Head");

					elseif dealer:IsA("Model") then
						local enemyPrefab = dealer;
						modDamageTag.Tag(classPlayer.Character, enemyPrefab, hitPart and hitPart.Name == "Head");

					end
				end
			end)
			
			if initDamage > 0 and (classPlayer.Properties.ThornCooldown == nil or tick()-classPlayer.Properties.ThornCooldown >= 0.1) and classPlayer.Properties.Armor > 0 and damageType ~= "Thorn" then
				local damageReflection = self:GetBodyEquipment("DamageReflection");
				if modConfigurations.DisableGearMods then
					damageReflection = nil;
				end
				if damageReflection and damageReflection > 0 and dealer then

					local damagable = modDamagable.NewDamagable(dealer);
					if damagable and damagable.Object.ClassName == "NpcStatus" then
						local npcStatus = damagable.Object;
						local npcModule = npcStatus:GetModule();
						
						local healthInfo = damagable:GetHealthInfo();
						
						
						if damageCategory == modDamagable.DamageCategory.Melee and npcModule and npcModule.Properties and npcModule.Properties.BasicEnemy then
							local reflectedDmg = math.max(healthInfo.Health * damageReflection, 10);
							
							local newDmgSrc = modDamagable.NewDamageSource{
								Damage=reflectedDmg;
								Dealer=playerInstance;
								TargetModel = npcModule.Prefab;
								TargetPart = npcModule.RootPart;
								DamageType = "Thorn";
							}
							damagable:TakeDamagePackage(newDmgSrc);

							classPlayer.Properties.ThornCooldown = tick();
						end
						
					end
				end
			end
			
			if damageType ~= "IgnoreArmor" then
				if classPlayer.Properties.Armor > 0 then
					damage = math.max(1, damage);
					armorDamage = damage > classPlayer.Properties.Armor and classPlayer.Properties.Armor or damage;

					classPlayer.Properties.Armor = classPlayer.Properties.Armor - damage;
					
					if classPlayer.RootPart then
						modAudio.Play("ArmorHit"..math.random(1,4), classPlayer.RootPart).PlaybackSpeed = math.random(60, 80)/100;
					end

					damageType = "Armor";
					if classPlayer.Properties.Armor <= 0 then
						damage = math.floor(damage*10)/10;

						local newRegenDelay = math.abs(classPlayer.Properties.Armor)/(self.Humanoid.MaxHealth/50);
						newRegenDelay = math.clamp(math.floor(newRegenDelay*10)/10, 5, 60);
						classPlayer.Properties.ArmorRegenDelay = newRegenDelay;

						local statusTable = {
							Delay=newRegenDelay;
							Duration=newRegenDelay;
							Expires=modSyncTime.GetTime() + newRegenDelay;
							Damage=damage;
						};
						function statusTable:OnExpire()
							classPlayer.Properties.ArmorRegenDelay = 1;
						end
						
						self:SetProperties("ArmorBreak", statusTable);
						
						
						if classPlayer.RootPart then
							modAudio.Play("ArmorBreak", classPlayer.RootPart).PlaybackSpeed = math.random(90, 110)/100;
						end
						classPlayer.LastDamageTaken = tick();
						damageType = "ArmorBreak";
						
					end
					damage = 0;

				elseif classPlayer.Properties.ArmorBreak then
					local statusTable = classPlayer.Properties.ArmorBreak;
					local newTime = modSyncTime.GetTime() + 5;
					
					if newTime > statusTable.Expires then
						statusTable.Expires=newTime;
						statusTable.Delay = 5;

						classPlayer:SyncProperty("ArmorBreak");
					end
				end
				
				classPlayer.Properties.Armor = math.clamp(classPlayer.Properties.Armor, 0, classPlayer.Properties.MaxArmor);
			else
				damageType = nil;
			end
			
			if damageType == "ArmorOnly" then
				return;
			end

			local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects :: DataModel);
			if classPlayer.Properties.Freezing == nil and classPlayer.Properties.Burn == nil then
				if classPlayer.Properties.TooHot and math.random(1, 2) == 1 then
					modStatusEffects.Burn(playerInstance, math.clamp(classPlayer.Properties.TooHot.Amount-40, 0, 10), 5);

				elseif classPlayer.Properties.TooCold and math.random(1, 2) == 1 then
					modStatusEffects.Freezing(playerInstance, 5);

				end
			end

			if classPlayer.Properties.HealSources.FoodHeal then
				classPlayer.Properties.HealSources.FoodHeal = nil;
			end

			if classPlayer.Character:FindFirstChildWhichIsA("ForceField") then
				damage = 0;
			end

			local borrowedTimeEnabled = modConfigurations.PvpMode == false;
			local isLethal = self.Humanoid.Health - damage <= 0;
			if borrowedTimeEnabled and self.BorrowedTime and tick()-self.BorrowedTime <= 0.5 then

			elseif borrowedTimeEnabled and isLethal and (self.BorrowedTime == nil or tick()-self.BorrowedTime >= 60) and math.random(0, 10) >= 4 then
				self.BorrowedTime = tick();
				self.Humanoid.Health = math.min(self.Humanoid.Health, math.random(1, 9));
				
				if RunService:IsStudio() then
					Debugger:Warn(playerInstance, "[Studio] BorrowedTime strikes!");
				end

			else

				classPlayer.Properties.Oxygen = classPlayer.Properties.Oxygen - damage;
				self.Humanoid.Health = self.Humanoid.Health - damage;

				if isLethal then
					local woundedDuration = modConfigurations.BaseWoundedDuration;

					if moddedSelf and moddedSelf.OnLethalDamageTaken then
						moddedSelf:OnLethalDamageTaken(classPlayer);

					elseif woundedDuration > 0 then
						if classPlayer.Properties.Wounded == nil and classPlayer.Properties.KnockedOut == nil then 
							local statusTable = {
								ExpiresOnDeath=true;
								Duration=woundedDuration;
								Expires=modSyncTime.GetTime() + woundedDuration;
							};
							classPlayer:SetProperties("Wounded", statusTable);

						end

					else
						classPlayer:Kill();

					end
					
					classPlayer:UnequipTools();
				end

				self:SyncIsAlive();
			end
			classPlayer.LastDamageTaken = tick();


		elseif damage < 0 then
			local healAmount = -damage;

			local hoSrcs = classPlayer.Properties.HealthOverchargeSources;
			local newHealth = classPlayer.Humanoid.Health + healAmount;
			if newHealth > classPlayer.Humanoid.MaxHealth then
				local amount = newHealth - classPlayer.Humanoid.MaxHealth;
				
				local profile = shared.modProfile:Get(playerInstance);
				local skill = profile.SkillTree:GetSkill(playerInstance, "ovehea");

				local level, stats = profile.SkillTree:CalStats(skill.Library, skill.Points);
				local maxOverheal = stats.Amount.Default + (level > 0 and stats.Amount.Value or 0);

				local overhealDuration = 10;
				local overHealStatus = {
					Expires=modSyncTime.GetTime()+overhealDuration;
					Duration=overhealDuration;
					HealAmount=amount;
				};
				function overHealStatus.OnTick()
					if overHealStatus.HealAmount == nil then return end;
					if classPlayer.Humanoid.Health >= classPlayer.Humanoid.MaxHealth then return end;
					
					classPlayer.Humanoid.Health = classPlayer.Humanoid.Health +overHealStatus.HealAmount;
					overHealStatus.HealAmount = nil;
				end;
				function overHealStatus.OnExpire()
					hoSrcs.OverHeal = nil;
				end;
				
				classPlayer:SetProperties("ovehea", overHealStatus);
				
				hoSrcs.OverHeal = math.clamp((hoSrcs.OverHeal or 0) + amount, 0, maxOverheal);
			end
			
			
			self.Humanoid.Health = self.Humanoid.Health +healAmount;
			classPlayer.LastHealed = tick();

		end

		if hitPart then
			if damageType == "ArmorBreak" then
				damageSource.DamageType="Armor";
				modInfoBubbles.Create{
					Players={dealer; playerInstance};
					Position=hitPart.Position;
					Type="AntiShield";
				};

			elseif damageType == "Armor" then
				damageSource.DamageType="Armor";
				modInfoBubbles.Create{
					Players={dealer; playerInstance};
					Position=hitPart.Position;
					Type="Armor";
					Value=armorDamage;
				};


			elseif damage > 0 then
				local killSnd;
				if self.Humanoid.Health <= 0 then
					killSnd = (hitPart.Name == "Head" or hitPart:GetAttribute("IsHead") == true) and "KillHead" or "KillFlesh";
				end

				modInfoBubbles.Create{
					Players={dealer; playerInstance};
					Position=hitPart.Position;
					Type=(damageType or "Damage");
					Value=math.ceil(damage);
					KillSnd=killSnd;
				};


			elseif damage < 0 then
				modInfoBubbles.Create{
					Players={dealer; playerInstance};
					Position=hitPart.Position;
					Type="Heal";
					Value=math.abs(damage);
				};

			else
				modInfoBubbles.Create{
					Players={dealer; playerInstance};
					Position=hitPart.Position;
					Type="Immune";
				};

			end
		end
		
		remoteDamagePacket:FireClient(classPlayer:GetInstance(), damageSource);
		classPlayer.OnDamageTaken:Fire(damage);
		
		modOnGameEvents:Fire("OnPlayerDamaged", playerInstance, damageSource, damage);
	end
	
	function meta:TakeDamage(damage, playerAttacker, storageItem, bodyPart, damageType)
		Debugger:Warn("deprecated implementation of TakeDamage.", debug.traceback());
		local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
		local newDmgSrc = modDamagable.NewDamageSource{
			Damage=damage;
			Dealer=playerAttacker;
			ToolStorageItem=storageItem;
			TargetPart=bodyPart;
			DamageType=damageType;
		}
		
		self:TakeDamagePackage(newDmgSrc);
	end
	
	function meta:GetMass()
		if self.Character == nil then return end;
		
		local mass = 0;
		for _, child in pairs(self.Character:GetDescendants()) do
			if child:IsA("BasePart") and child.Parent.ClassName ~= "Accessory" then
				mass = mass + child:GetMass();
			end
		end
		return mass;
	end
	
	function meta:RefreshHealRate()
		local oldHealRate = classPlayer.Properties.HealRate;
		local healRate = 0;
		
		local isDead = not classPlayer.IsAlive;
		
		for k, healdata in pairs(classPlayer.Properties.HealSources) do
			if classPlayer.Properties.Wounded then
				classPlayer.Properties.HealSources[k] = nil;
				
			elseif isDead and healdata.ExpiresOnDeath then
				classPlayer.Properties.HealSources[k] = nil;
				
			elseif healdata.Expires == nil or modSyncTime.GetTime() <= healdata.Expires then
				healRate = healRate + (healdata.Amount or 0);
				
			else
				classPlayer.Properties.HealSources[k] = nil;
			end
		end
		classPlayer.Properties.HealRate = healRate;
		if oldHealRate ~= healRate and RunService:IsServer() then
			remotePlayerProperties:FireAllClients(classPlayer.Name, "SetProperties", "HealSources", classPlayer.Properties.HealSources);
			remotePlayerProperties:FireAllClients(classPlayer.Name, "SetProperties", "HealRate", classPlayer.Properties.HealRate);
		end
		
		-- Armor;
		local armorRate = BaseArmorRate;
		for k, srcdata in pairs(classPlayer.Properties.ArmorSources) do
			if isDead and srcdata.ExpiresOnDeath then
				classPlayer.Properties.ArmorSources[k] = nil;
			elseif srcdata.Expires == nil or modSyncTime.GetTime() <= srcdata.Expires then
				armorRate = armorRate + (srcdata.Amount or 0);
			else
				classPlayer.Properties.ArmorSources[k] = nil;
			end
		end
		classPlayer.Properties.ArmorRate = armorRate;
		
	end
	
	function meta:SetHealSource(id, src)
		classPlayer.Properties.HealSources[id] = src;
		remotePlayerProperties:FireAllClients(classPlayer.Name, "SetProperties", "HealSources", classPlayer.Properties.HealSources);
		self:RefreshHealRate();
	end
	
	function meta:SetArmorSource(id, src)
		classPlayer.Properties.ArmorSources[id] = src;
		remotePlayerProperties:FireAllClients(classPlayer.Name, "SetProperties", "ArmorSources", classPlayer.Properties.ArmorSources);
		self:RefreshHealRate();
	end
	
	function meta:GetInstance()
		return playerInstance;
	end
	
	function meta.OnCharacterAdded(character: Model)
		if character == nil then return end;
		Debugger:Log("Character", playerInstance.Name,"spawned. ", character:GetFullName());

		local cache = {
			ColdBreathParticles = nil;
			WaterBubblesParticles = nil;
		};
		
		character:SetAttribute("PlayerCharacter", playerInstance.Name);
		
		classPlayer.Character = character;
		classPlayer.Humanoid = character:WaitForChild("Humanoid");
		classPlayer.RootPart = character:WaitForChild("HumanoidRootPart", 20);
		classPlayer.Head = character:WaitForChild("Head");
		classPlayer.CharacterModule = require(character:WaitForChild("CharacterModule"));

		classPlayer.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false);
		classPlayer.DeathDebounce = false;
		
		local ragdollActive = false;
		local function onStateChanged(oldState: Enum.HumanoidStateType, newState: Enum.HumanoidStateType)
			classPlayer.CurrentState = newState;
			
			if RunService:IsClient() and playerInstance ~= localPlayer then 
				return;
			end
			
			classPlayer.CharacterModule.UpdateBodyObjects();
			if not classPlayer.IsAlive then return end;

			if cache.ColdBreathParticles == nil then
				cache.ColdBreathParticles = classPlayer.Head:WaitForChild("MouthAttachment"):WaitForChild("ColdBreath");
			end
			
			if cache.WaterBubblesParticles == nil then
				cache.WaterBubblesParticles = classPlayer.Head:WaitForChild("MouthAttachment"):WaitForChild("WaterBubbles");
			end
			
		end
		
		meta.Garbage:Tag(character:GetAttributeChangedSignal("Ragdoll"):Connect(function()
			classPlayer.CharacterModule.UpdateBodyObjects();
		end))
		
		meta.Garbage:Tag(classPlayer.Humanoid.StateChanged:Connect(onStateChanged));
		onStateChanged(Enum.HumanoidStateType.Running, Enum.HumanoidStateType.Running);
		PlayerService.OnPlayerSpawn:Fire(classPlayer);
		
		if RunService:IsClient() then
			classPlayer:SyncIsAlive();
			meta.Garbage:Tag(classPlayer.Character:GetAttributeChangedSignal("IsAlive"):Connect(function()
				classPlayer:SyncIsAlive();
			end))
			
			if playerInstance == localPlayer then
				-- Is local client;

			end

			if playerInstance ~= localPlayer then
				-- Is other player client;

				return 
			end;
		end

		function classPlayer.OnDeathServer()
			table.clear(cache);
			if RunService:IsClient() then return end;
			Debugger:Log(playerInstance," died.");

			classPlayer:SetProperties("Ragdoll", 1);
			classPlayer.Humanoid.PlatformStand = true;
			
			classPlayer.IsAlive = false;
			
			classPlayer.OnIsAliveChanged:Fire(classPlayer.IsAlive);
			classPlayer:RefreshHealRate();
			
			character:SetAttribute("IsAlive", classPlayer.IsAlive);
			
			local deathTime = tick();
			task.spawn(function()
				while tick()-deathTime <= game.Players.RespawnTime do
					task.wait(0.1);
				end
				
				while game.Players:GetAttribute("AutoRespawn") ~= true do
					task.wait(0.1);
				end
				if classPlayer.CancelAutoRespawn == true then
					Debugger:Warn("AutoRespawn cancelled.");
					return;
				end
				
				classPlayer:Spawn();
			end)
			
			PlayerService.OnPlayerDied:Fire(classPlayer);
			
			classPlayer.Properties.MaxArmor = 0;
			
			classPlayer:SetProperties("InBossBattle", nil);

			modOnGameEvents:Fire("OnPlayerDied", playerInstance);
			
			if classPlayer.Properties.Pvp then
				local targetName = classPlayer.Properties.Pvp.InDuel;
				local targetPlayer = targetName and PlayerService.Players[targetName];
				if targetPlayer then
					shared.Notify(game.Players:GetPlayers(), targetName.." has won a duel against "..classPlayer.Name.."!", "Defeated");
					targetPlayer.Properties.Pvp = nil;
				end;
				classPlayer.Properties.Pvp = nil;
			end;
		end

		local function onHealthChangedServer()
			if not game.Players:IsAncestorOf(playerInstance) then return end;
			
			classPlayer.Health = classPlayer.Humanoid.Health;
			classPlayer.MaxHealth = classPlayer.Humanoid.MaxHealth;
			classPlayer.OnHealthChanged:Fire(classPlayer.Health, classPlayer.MaxHealth);
			classPlayer.OnIsAliveChanged:Fire(classPlayer.IsAlive);
			
			if RunService:IsServer() then
				if PlayerService.SkillTree and classPlayer.Health > 1 then
					PlayerService.SkillTree:TriggerSkills(playerInstance, "OnHealthChange");
				end
			end

			classPlayer:SyncIsAlive();
		end
		
		local function cycleUpdateHealth(currentTick, tickPack)
			if tickPack.ms100 ~= true then return end;
			
			local modHealthPoints = (classPlayer:GetBodyEquipment("ModHealthPoints") or 0);
			local overchargeHealth = 0;

			if modConfigurations.DisableGearMods then
				modHealthPoints = 0;
			end
			for _, v in pairs(classPlayer.Properties.HealthOverchargeSources) do
				overchargeHealth = overchargeHealth + v;
			end
			
			local baseHealth = classPlayer.Properties.BaseHealth;
			
			if overchargeHealth > 0 then
				classPlayer.Humanoid.MaxHealth = baseHealth + modHealthPoints + overchargeHealth;

			elseif classPlayer.Humanoid.MaxHealth > baseHealth + (modHealthPoints or 0) then
				classPlayer.Humanoid.MaxHealth = classPlayer.Humanoid.MaxHealth - 0.1;

			else
				classPlayer.Humanoid.MaxHealth = (baseHealth + modHealthPoints + overchargeHealth);
				
			end

			if classPlayer.Properties.HealRate > 0 then
				classPlayer.Humanoid.Health = classPlayer.Humanoid.Health + classPlayer.Properties.HealRate;
			end
			classPlayer.Humanoid.Health = math.clamp(classPlayer.Humanoid.Health, 0, math.max(classPlayer.Humanoid.MaxHealth, baseHealth));
		end
		
		local function cycleUpdateArmor(currentTick, ms100, ms1000)
			if ms100 then
				local armorRate = classPlayer.Properties.ArmorRate;
				
				if classPlayer.IsAlive then
					if classPlayer.LastDamageTaken == nil or currentTick-classPlayer.LastDamageTaken >= math.max(classPlayer.Properties.ArmorRegenDelay, 1) then
						armorRate = classPlayer.Properties.ArmorRate;
						
						if classPlayer.Properties.ArmorBreak then
							armorRate = 0;
						end
						
						classPlayer.Properties.Armor = classPlayer.Properties.Armor + armorRate;
						classPlayer.Properties.ArmorRegenDelay = 1;
					end
				end

				local modArmorPoints = (classPlayer:GetBodyEquipment("ModArmorPoints") or 0);
				local overchargeArmor = 0;
				
				if modConfigurations.DisableGearMods then
					modArmorPoints = 0;
					
				else
					for _, v in pairs(classPlayer.Properties.ArmorOverchargeSources) do
						overchargeArmor = overchargeArmor + v;
					end
					
				end
				
				if overchargeArmor > 0 then
					if classPlayer.Properties.MaxArmor >= BaseMaxArmor + modArmorPoints + overchargeArmor then
						classPlayer.Properties.MaxArmor = BaseMaxArmor + modArmorPoints + overchargeArmor;

					else
						classPlayer.Properties.MaxArmor = classPlayer.Properties.MaxArmor + armorRate;

					end

				elseif modArmorPoints > 0 and classPlayer.Properties.MaxArmor > BaseMaxArmor + modArmorPoints then
					classPlayer.Properties.MaxArmor = math.clamp(classPlayer.Properties.MaxArmor - 1, BaseMaxArmor, BaseMaxArmor + modArmorPoints);
					
				elseif classPlayer.Properties.MaxArmor > BaseMaxArmor + modArmorPoints then
					classPlayer.Properties.MaxArmor = classPlayer.Properties.MaxArmor - 1;
					
				else
					classPlayer.Properties.MaxArmor = (BaseMaxArmor + modArmorPoints + overchargeArmor);
					
				end

				classPlayer.Properties.Armor = math.clamp(classPlayer.Properties.Armor, 0, math.max(classPlayer.Properties.MaxArmor, 0));
			end
			
			classPlayer.Humanoid:SetAttribute("Armor", classPlayer.Properties.Armor);
			classPlayer.Humanoid:SetAttribute("MaxArmor", classPlayer.Properties.MaxArmor);
		end
		
		
		-- Init Variables OnCharAdd;
		classPlayer.CurrentState = Enum.HumanoidStateType.None;
		classPlayer.IsAlive = true;
		classPlayer.Invisible = false;
		classPlayer.BorrowedTime = nil;
		
		-- Connect signals;
		meta.Garbage:Tag(classPlayer.Humanoid.HealthChanged:Connect(onHealthChangedServer));
		meta.Garbage:Tag(classPlayer.Humanoid.Seated:Connect(function(active, seatPart)
			if seatPart then
				local weld = seatPart:FindFirstChild("SeatWeld");
				if weld then
					weld.C0 = CFrame.new(0, -1.1, 0) * CFrame.Angles(math.rad(-90), 0, 0);
				end
			end
		end))
		
		-- Fire events;
		onHealthChangedServer();
		classPlayer.OnIsAliveChanged:Fire(classPlayer.IsAlive);
		classPlayer.OnCharacterSpawn:Fire(classPlayer.Character :: Model);
		
		local function processStatusLoop(id, status, tickPack)
			if type(status) ~= "table" then return end;
			local lib = modStatusLibrary:Find(id);
			local statusClass = lib and lib.Module and require(lib.Module);
			
			local sync = false;
			if statusClass and statusClass.OnTick then
				sync = statusClass.OnTick(classPlayer, status, tickPack);
				
			elseif status.OnTick then
				sync = status.OnTick(classPlayer, status, tickPack);
				
			end
			
			if (not classPlayer.IsAlive and status.ExpiresOnDeath) or (status.Expires and modSyncTime.GetTime() >= status.Expires) then
				if status.OnExpire then
					status:OnExpire();
				end
				
				if statusClass and statusClass.OnExpire then
					statusClass.OnExpire(classPlayer, status);
				end;

				classPlayer.Properties[id] = nil;

			end

			return sync;
		end

		if RunService:IsServer() then
			--playerInstance.ReplicationFocus = classPlayer.RootPart;
			CollectionService:AddTag(classPlayer.RootPart, "PlayerRootParts");
			character:AddTag("PlayerCharacters");
			modOnGameEvents:Fire("OnPlayerSpawn", playerInstance, character);
			
			meta.Garbage:Tag(character.ChildRemoved:Connect(function(child)
				if child.Name ~= "HumanoidRootPart" then return end;
				classPlayer:Kill("FallenIntoVoid");
			end))

			if cache.DivingMouthpiece == nil then
				cache.DivingMouthpiece = game.ReplicatedStorage.Prefabs.Objects.DivingSuitMouthpiece:Clone();
				cache.DivingMouthpiece.Parent = character;
				cache.ShowDivingMouthpiece = 1;
			end
			
			local globalTemperature = workspace:GetAttribute("GlobalTemperature");
			
			--== Status Cycle;
			local currentTick = tick();
			local tick10s = currentTick-10;
			local tick5s = currentTick-5;
			local tick1s = currentTick-1;
			local tick500ms = currentTick-0.5;
			local tick100ms = currentTick-0.1;
			
			--== cycleUpdates;
			cycleUpdateHealth(currentTick, {ms100=true;});
			cycleUpdateArmor(currentTick, true);

			classPlayer.Properties.Armor = math.max(classPlayer.Properties.MaxArmor-1, 0);
			
			--
			local lastSafeTp = tick();
			
			if classPlayer.StatusCycle then classPlayer.StatusCycle:Disconnect(); end
			classPlayer.StatusCycle = RunService.Heartbeat:Connect(function(delta)
				if not game.Players:IsAncestorOf(playerInstance) then classPlayer.StatusCycle:Disconnect(); return end;
				
				local tickPack = {};
				
				currentTick = tick();
				classPlayer:SyncIsAlive();
				
				local currentState = classPlayer.CurrentState;

				classPlayer.IsSwimming = currentState == Enum.HumanoidStateType.Swimming;
				
				if currentState == Enum.HumanoidStateType.Running then --classPlayer.Humanoid.Jump
					classPlayer.SafeCFrame = classPlayer.RootPart.CFrame + Vector3.new(0, 1, 0);
					
				elseif classPlayer.RootPart.Position.Y < -500 then
					if tick()-lastSafeTp <= 5 then
						classPlayer.SafeCFrame = nil;
					end
					
					if classPlayer.SafeCFrame == nil then
						classPlayer.SafeCFrame = classPlayer.SpawnCFrame;
					end
					lastSafeTp = tick();
					
					if classPlayer.SafeCFrame then
						shared.modAntiCheatService:Teleport(playerInstance, classPlayer.SafeCFrame);
					end
				end
				
				
				local ms1000, ms500, ms100 = false, false, false;
				local s10, s5 = false, false;
				if currentTick-tick100ms >= 0.1 then
					tick100ms = currentTick;
					ms100 = true;

					if currentTick-tick500ms >= 0.5 then
						tick500ms = currentTick;
						ms500 = true;

						if currentTick-tick1s >= 1 then
							tick1s = currentTick;
							ms1000 = true;
							
							if currentTick-tick5s >= 5 then
								tick5s = currentTick;
								s5 = true;
								
								if currentTick-tick10s >= 10 then
									tick10s = currentTick;
									s10 = true;
								end
							end
						end
					end
				end
				
				tickPack.Delta = delta;
				tickPack.ms1000 = ms1000;
				tickPack.ms500 = ms500;
				tickPack.ms100 = ms100;
				tickPack.s10 = s10;
				tickPack.s5 = s5;
				
				if ms1000 then
					-- Healing
					classPlayer:RefreshHealRate();
					
					if classPlayer.Properties.BodyEquipments then
						if classPlayer.DoInitHealth then
							classPlayer.Humanoid.Health = classPlayer.DoInitHealth;
							classPlayer.DoInitHealth = nil;
						end
					end
					
					local playerWarmth = globalTemperature + (classPlayer:GetBodyEquipment("Warmth") or 0);

					if cache.LastWarmthOffset == nil then cache.LastWarmthOffset = 0 end;
					local newTempOffset = classPlayer.Properties.TemperatureOffset:Get();
					if math.abs(newTempOffset-cache.LastWarmthOffset) <=0.1 then
						cache.LastWarmthOffset = newTempOffset;
					else
						cache.LastWarmthOffset = modMath.Lerp(cache.LastWarmthOffset, classPlayer.Properties.TemperatureOffset:Get(), 0.4);
					end
					playerWarmth = playerWarmth + cache.LastWarmthOffset;

					if classPlayer.IsSwimming then
						playerWarmth = playerWarmth -10;
					end
					
					playerWarmth = math.floor(playerWarmth*10)/10
					classPlayer.Humanoid:SetAttribute("Warmth", playerWarmth);
					
					if playerWarmth <= 10 then
						if classPlayer.Properties.TooCold == nil or classPlayer.Properties.TooCold.Amount ~= playerWarmth then
							classPlayer:SetProperties("TooCold", {Amount=playerWarmth});
						end
						
						if playerWarmth < 0 then
							classPlayer:TakeDamagePackage(modDamagable.NewDamageSource{
								Damage=classPlayer.Humanoid.MaxHealth*0.025;
								TargetPart=classPlayer.RootPart;
								DamageType="IgnoreArmor";
							});
						end
						
					elseif playerWarmth > 40 then
						if classPlayer.Properties.TooHot == nil or classPlayer.Properties.TooHot.Amount ~= playerWarmth then
							classPlayer:SetProperties("TooHot", {Amount=playerWarmth});
						end
						
						if playerWarmth > 50 then
							classPlayer:TakeDamagePackage(modDamagable.NewDamageSource{
								Damage=classPlayer.Humanoid.MaxHealth*0.025;
								TargetPart=classPlayer.RootPart;
								DamageType="IgnoreArmor";
							});
						end
						
					else
						if classPlayer.Properties.TooCold then
							classPlayer:SetProperties("TooCold", nil);
						end
						if classPlayer.Properties.TooHot then
							classPlayer:SetProperties("TooHot", nil);
						end
					end

					if classPlayer.Properties.Freezing then
						if cache.ColdBreathParticles then
							cache.ColdBreathParticles:Emit(math.random(8, 12));
						end
					end
					
					classPlayer.Humanoid:SetAttribute("IsSwimming", classPlayer.IsSwimming);
					
					local layerName, _layerData = modMapLibrary:GetLayer(classPlayer.RootPart.Position);
					playerInstance:SetAttribute("Location", layerName);
					
				end
				
				if ms500 then
					local headInMaterial = nil;
					if classPlayer.IsSwimming then
						local headpos = classPlayer.Head.Position + Vector3.new(0, 1, 0);
						local headRegion = Region3.new(headpos, headpos):ExpandToGrid(4);
						local mats, _occs = workspace.Terrain:ReadVoxels(headRegion, 4);
						headInMaterial = mats and mats[1][1][1] or nil;
					end

					classPlayer.IsUnderWater = headInMaterial and headInMaterial == Enum.Material.Water or false;
					classPlayer.Humanoid:SetAttribute("IsUnderWater", classPlayer.IsUnderWater);
				end
				
				cycleUpdateHealth(currentTick, tickPack);
				cycleUpdateArmor(currentTick, ms100, ms1000);
				
				if ms100 then
					if character:FindFirstChild("SpawnProtection") == nil then
						classPlayer.MaxOxygen = classPlayer.Humanoid.Health;
						
						local odr = classPlayer:GetBodyEquipment("OxygenDrainReduction");
						if cache.DivingMouthpiece and cache.DivingMouthpiece:FindFirstChild("Handle") then
							local handle = cache.DivingMouthpiece.Handle;

							if odr then
								cache.ShowDivingMouthpiece = classPlayer.IsUnderWater and 0 or 1;
							else
								cache.ShowDivingMouthpiece = 1; -- set transparency;
							end
							if cache.ShowDivingMouthpiece ~= handle.Transparency then
								handle.Transparency = cache.ShowDivingMouthpiece;
								
								local oLinkL = handle.OLinkL;
								local oLinkR = handle.OLinkR;
								local ropeL = handle.RopeL;
								local ropeR = handle.RopeR;

								ropeL.Attachment0 = oLinkL
								ropeR.Attachment0 = oLinkR;

								local suitLinkL = character:FindFirstChild("OxygenLinkL", true);
								if suitLinkL then
									ropeL.Attachment1 = suitLinkL;
								end
								local suitLinkR = character:FindFirstChild("OxygenLinkR", true);
								if suitLinkR then
									ropeR.Attachment1 = suitLinkR;
								end

								ropeL.Visible = handle.Transparency == 0;
								ropeR.Visible = handle.Transparency == 0;
							end
						end
						
						if classPlayer.IsUnderWater then
							local oxygenDrainReduction = math.clamp(1 - (odr or 0), 0.01, 1);
							
							local amt = (0.5 * oxygenDrainReduction);
							
							if cache.WaterBubblesParticles and ms1000 then
								cache.WaterBubblesParticles:Emit(math.ceil(amt*math.random(12, 14)));
							end
							
							if classPlayer.MaxOxygen > 0 then
								classPlayer.Properties.Oxygen = math.clamp(classPlayer.Properties.Oxygen - amt, 0, classPlayer.MaxOxygen);
							end

							if classPlayer.Properties.Oxygen <= 0 then
								classPlayer:TakeDamagePackage(modDamagable.NewDamageSource{
									Damage=classPlayer.Humanoid.MaxHealth;
									DamageType="IgnoreArmor";
								})
								
							end

							if classPlayer.Properties.Wounded and classPlayer.Properties.Ragdoll ~= 1 then
								local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects :: ModuleScript);
								
								modStatusEffects.Ragdoll(playerInstance, true);
							end
							
						else
							local oxygenRecoveryIncrease = 1+(classPlayer:GetBodyEquipment("OxygenRecoveryIncrease") or 0);
							classPlayer.Properties.Oxygen = math.clamp(classPlayer.Properties.Oxygen + (2 * oxygenRecoveryIncrease), 0, math.max(classPlayer.MaxOxygen, 1));
						end
						
					else
						classPlayer.MaxOxygen = 100;
						classPlayer.Properties.Oxygen = classPlayer.MaxOxygen;
						
					end
				end
				
				classPlayer.Humanoid:SetAttribute("Oxygen", classPlayer.Properties.Oxygen);
				
				local isPlayerInvisible = false;
				for id, status in pairs(classPlayer.Properties) do
					if type(status) ~= "table" then continue end;
					-- MARK: Server Status loop
					local sync = false;

					sync = processStatusLoop(id, status, tickPack);

					if sync then
						classPlayer:SyncProperty(id);
					end;

					--
					if status.Invisible then isPlayerInvisible = true; end
				end
				
				if classPlayer.Properties.IsInvisible ~= isPlayerInvisible and playerInstance.Character then
					classPlayer:SetProperties("IsInvisible", isPlayerInvisible);
					playerInstance.Character:SetAttribute("IsInvisible", classPlayer.Properties.IsInvisible);
					
					for _, obj in pairs(playerInstance.Character:GetDescendants()) do
						if (obj:IsA("BasePart") or obj:IsA("Decal")) then
							local isInATool = obj.Parent:IsA("Model") and obj.Parent.PrimaryPart and obj.Parent.PrimaryPart.Name == "Handle"
								or obj.Parent.Parent:IsA("Model") and obj.Parent.Parent.PrimaryPart and obj.Parent.Parent.PrimaryPart.Name == "Handle";
							
							if not isInATool and obj.Parent.Name ~= "DisguiseModel" and obj.Parent.Parent.Name ~= "DisguiseModel" 
								and obj.Name ~= "HumanoidRootPart" and obj.Name ~= "CollisionRootPart" and obj:GetAttribute("CustomTransparency") ~= true then
								
								local invisValue = obj:GetAttribute("InvisibleValue") or 1;
								
								if obj:GetAttribute("ToggleClothing") ~= false then
									obj.Transparency = classPlayer.Properties.IsInvisible and invisValue or 0;
								else
									obj.Transparency = 1;
								end
								
								if obj:IsA("BasePart") and not classPlayer.Properties.IsInvisible then
									obj.Material = Enum.Material.Plastic;
								end
							end
						elseif obj.Name == "NameDisplay" then
							obj.Enabled = not classPlayer.Properties.IsInvisible;
							
						end
					end
					
					if not classPlayer.Properties.IsInvisible then
						modCustomizeAppearance.RefreshIndex(playerInstance.Character);
					end
				end

				if classPlayer.Properties.Ragdoll ~= 0 then
					if ragdollActive == false then
						ragdollActive = true;
					end

				else
					if ragdollActive == true then
						ragdollActive = false;
					end

				end

				if moddedSelf and moddedSelf.StatusCycle then 
					moddedSelf:StatusCycle(classPlayer, {
						Tick=currentTick;
						
						s10=s10;
						s5=s5;
						ms1000=ms1000;
						ms500=ms500;
						ms100=ms100;
						
						Cache=cache;
					}); 
				end
			end)
			
			while shared.modProfile == nil do task.wait(0.1); end
			
			local modProfile = shared.modProfile;
			local profile = modProfile:Get(playerInstance);
			local activeSave = profile and profile:GetActiveSave();
			
			if activeSave then
				local statusSave = activeSave.StatusSave;
				statusSave:ApplyEffects();
			end
			
			
		else
			--==  Client side character added;

			local currentTick = tick();
			local tick10s = currentTick-10;
			local tick5s = currentTick-5;
			local tick1s = currentTick-1;
			local tick500ms = currentTick-0.5;
			local tick100ms = currentTick-0.1;
			
			if classPlayer.StatusCycle then classPlayer.StatusCycle:Disconnect(); end
			classPlayer.StatusCycle = RunService.Heartbeat:Connect(function(delta)
				currentTick = tick();
				
				local tickPack = {};
				
				local ms1000, ms500, ms100 = false, false, false;
				local s10, s5 = false, false;
				if currentTick-tick100ms >= 0.1 then
					tick100ms = currentTick;
					ms100 = true;

					if currentTick-tick500ms >= 0.5 then
						tick500ms = currentTick;
						ms500 = true;

						if currentTick-tick1s >= 1 then
							tick1s = currentTick;
							ms1000 = true;

							if currentTick-tick5s >= 5 then
								tick5s = currentTick;
								s5 = true;

								if currentTick-tick10s >= 10 then
									tick10s = currentTick;
									s10 = true;
								end
							end
						end
					end
				end

				tickPack.Delta = delta;
				tickPack.ms1000 = ms1000;
				tickPack.ms500 = ms500;
				tickPack.ms100 = ms100;
				tickPack.s10 = s10;
				tickPack.s5 = s5;
				
				for id, status in pairs(classPlayer.Properties) do
					if type(status) ~= "table" then continue end;
					-- MARK: Client Status loop
					processStatusLoop(id, status, tickPack);
				end
				
			end)
			
		end

		classPlayer:SetProperties("Ragdoll", 0);
		
		if moddedSelf and moddedSelf.OnCharacterAdded then 
			moddedSelf:OnCharacterAdded(classPlayer);
		end
		-- OnCharacterAdded End
	end
	
	function meta:OnNotIsAlive(func)
		if playerInstance.Character == nil then return end
		local character = playerInstance.Character;
		
		meta.Garbage:Tag(character:GetAttributeChangedSignal("IsAlive"):Connect(function()
			if character:GetAttribute("IsAlive") == false then
				func(character);
			end
		end));
	end
	
	function meta.OnPlayerTeleport(teleportState, placeId, spawnName)
		Debugger:Log("Player (",classPlayer.Name,") is teleporting to: ", modBranchConfigs.GetWorldName(placeId));
		classPlayer.IsTeleporting = true;
		classPlayer.TeleportPlaceId = placeId;
	end
	
	function meta:GetCharacter()
		return playerInstance.Character;
	end
	
	function meta:GetCharacterChild(name)
		local char = self:GetCharacter();
		local obj = char and char:FindFirstChild(name) or nil;
		if obj then
			if name == "HumanoidRootPart" then
				self.RootPart = obj;
			elseif name == "Humanoid" or name == "Head" then
				self[name] = obj;
			end
			return obj;
		end
		return;
	end
	
	function meta:SyncProperties(keys)
		if RunService:IsClient() then return end;
		
		for a=1, #keys do
			local k = keys[a];
			
			Debugger:Log("SetProperties", k, self.Properties[k], debug.traceback());
			remotePlayerProperties:FireClient(playerInstance, playerInstance.Name, "SetProperties", k, self.Properties[k]);
		end
	end
	
	function meta:UnequipTools(paramPacket)
		shared.EquipmentSystem.ToolHandler(playerInstance, "unequip", paramPacket);
	end
	
	function meta:GetEquippedTools()
		return shared.EquipmentSystem.ToolHandler(playerInstance, "get");
	end
	
	function meta:Destroy()
		if PlayerService.Players[self.Name] == nil then return end;
		if self.StatusCycle then self.StatusCycle:Disconnect(); end
		
		self.OnHealthChanged:Destroy();
		self.OnIsAliveChanged:Destroy();
		self.OnCharacterSpawn:Destroy();
		self.Died:Destroy();
		self.OnDamageTaken:Destroy();
		
		self.Properties.TemperatureOffset:Destroy();
		meta.Garbage:Destruct();

		self.Character = nil;
		self.Humanoid = nil;
		self.RootPart = nil;
		self.Head = nil;
		self.CharacterModule = nil;

		PlayerService.Players[self.Name] = nil;
		table.clear(self);
		table.clear(meta);
	end
	
	function meta:CastGroundRay(distance)
		if self.RootPart == nil then
			return nil, Vector3.zero, Vector3.zero, nil;
		end
		
		distance = distance or 16;
		
		local raycastParams = RaycastParams.new();
		raycastParams.FilterType = Enum.RaycastFilterType.Include;
		raycastParams.IgnoreWater = true;
		raycastParams.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};
		raycastParams.CollisionGroup = "Raycast";
		
		local newOrigin = self.RootPart.Position;
		local direction = Vector3.new(0, -1, 0);
		
		local raycastResult = workspace:Raycast(newOrigin, direction*distance, raycastParams);

		local rayBasePart, rayPoint, rayNormal, rayMaterial;
		if raycastResult then
			rayBasePart = raycastResult.Instance;
			rayPoint = raycastResult.Position;
			rayNormal = raycastResult.Normal;
			rayMaterial = raycastResult.Material;
			
		else
			rayPoint = newOrigin + direction*distance;
			
		end
		
		return rayBasePart, rayPoint, rayNormal, rayMaterial;
	end
	
	meta.__index = meta;
	
	--== Connections;
	classPlayer.Died:Connect(function(character)
		if classPlayer.OnDeathServer then
			classPlayer:OnDeathServer();
		end
	end);
	
	meta.Garbage:Tag(playerInstance.OnTeleport:Connect(classPlayer.OnPlayerTeleport));
	
	if playerInstance.Character then 
		task.spawn(function()
			classPlayer.OnCharacterAdded(playerInstance.Character);
		end)
	end;
	meta.Garbage:Tag(playerInstance.CharacterAdded:Connect(classPlayer.OnCharacterAdded));

	if moddedSelf then moddedSelf:Init(classPlayer); end
	
	return classPlayer;
end

return function(playerService)
	PlayerService = playerService;
	return Player;
end