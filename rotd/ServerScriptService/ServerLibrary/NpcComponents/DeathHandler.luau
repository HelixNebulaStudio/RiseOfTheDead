local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Script;
local CollectionService = game:GetService("CollectionService");

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

local modExperience = shared.require(game.ServerScriptService.ServerLibrary.Experience);
local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);
local modMoneyRewardSystem = shared.require(game.ReplicatedStorage.Library.MoneyRewardSystem);

local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;
--==

local lastKillTime = setmetatable({}, {__mode = "k"}); -- [Player] = tick()
local killStreak = setmetatable({}, {__mode = "k"}); -- [Player] = number

function Component.new(npcClass: NpcClass)
	local self = {
		_called = false;
		NpcClass = npcClass;
	};
	
	setmetatable(self, Component);
	return self;
end

function Component:__call(damagedata: DamageData)
	if self._called then return end;
	self._called = true;

	local npcClass: NpcClass = self.NpcClass;
	local healthComp: HealthComp = npcClass.HealthComp;

	local npcPackage: anydict = npcClass.NpcPackage;
	local character: Model = npcClass.Character;
	local rawProperties: anydict = npcClass.Properties.Values;

	CollectionService:RemoveTag(character, "TargetableEntities");
	
	if healthComp.CurHealth > healthComp.KillHealth then return end;

	local humanoidType = npcClass.HumanoidType;
	if humanoidType == "Zombie" then
		if npcPackage.Audio and npcPackage.Audio.Death and npcPackage.Audio.Death ~= false then
			modAudio.Play(npcPackage.Audio.Death, npcClass.RootPart).PlaybackSpeed = math.random(100, 120)/100;
		elseif npcPackage.Audio and npcPackage.Audio.Death == false then
		else
			modAudio.Play("ZombieDeath"..math.random(1, 4), npcClass.RootPart).PlaybackSpeed = math.random(50, 150)/100;
		end

	elseif humanoidType == "Human" then
		modAudio.Play("HumanDeath", self.RootPart);

	end

	
	local playerTags = modDamageTag:Get(character, "Player");

	local deathPosition = rawProperties.DeathPosition;
	local dropRewardComp = npcClass:GetComponent("DropReward");
	if dropRewardComp and #playerTags > 0 then
		dropRewardComp(CFrame.new(deathPosition) 
			* CFrame.Angles(
				math.rad(math.random(0, 360)), 
				math.rad(math.random(0, 360)), 
				math.rad(math.random(0, 360)))
		);
	end

	local playerBonusExp = {};

	local npcLevel = rawProperties.Level;
	local deathTime = workspace:GetServerTimeNow();
	local firstDamageTaken = healthComp.FirstDamageTaken;

	local baseReward = math.clamp(((npcLevel or 1)-1), 1, math.ceil(modGlobalVars.MaxLevels/10));

	if rawProperties.BasicEnemy ~= true and rawProperties.MoneyReward then
		local moneyRang: NumberRange = rawProperties.MoneyReward;
		baseReward = ((npcLevel or 1)-1) + math.random(moneyRang.Min, moneyRang.Max);
	end

	local damageLogComp = npcClass:GetComponent("DamageLog");
	local teamTotalDamage = 0;
	local damageSources = {};
	local damageSourceSet = {};
	if damageLogComp then
		for playerName, logData in pairs(damageLogComp.Log) do
			for sourceId, weaponData in pairs(logData) do
				teamTotalDamage += weaponData.Damage;

				local sourceKey = `{playerName}|{sourceId}`;
				if damageSourceSet[sourceKey] == nil then
					damageSourceSet[sourceKey] = true;
					table.insert(damageSources, sourceKey);
				end
			end
		end
	end

	local killerClass: EntityClass? = damagedata and damagedata.DamageBy or nil;
	local killerTargetPart: BasePart? = damagedata and damagedata.TargetPart or nil;
	local isHeadshotKill = killerTargetPart ~= nil
		and (killerTargetPart.Name == "Head" or killerTargetPart:GetAttribute("IsHead") == true);

	for a=1, #playerTags do
		local playerTag = playerTags[a];
		local player: Player = playerTag.Player;
		if player == nil or not game.Players:IsAncestorOf(player) then continue end;

		local playerClass: PlayerClass = shared.modPlayers.get(player);

		local profile: Profile = shared.modProfile:Get(player);
		local gameSave: GameSave = profile:GetActiveSave();
		if gameSave == nil then continue end;

		gameSave:AddStat("Kills", 1);
		
		local killNotice = {`Killed {npcClass.Name} [{npcLevel or "?"}]`};

		if humanoidType == "Zombie" then
			gameSave:AddStat("ZombieKills", 1);

		elseif humanoidType == "Human"
			or humanoidType == "Rat"
			or humanoidType == "Bandit" then
			gameSave:AddStat("HumanKills", 1);
			
		end

		local playerDamage = 0;
		if damageLogComp and damageLogComp.Log[player.Name] then
			for _, weaponData in pairs(damageLogComp.Log[player.Name]) do
				playerDamage += weaponData.Damage;
			end
		end

		local killDistance = nil;
		if playerClass.RootPart and npcClass.RootPart then
			killDistance = playerClass:DistanceFrom(npcClass.RootPart.Position);
		end

		local isPlayerAirborne = false;
		if playerClass.Humanoid then
			isPlayerAirborne = playerClass.Humanoid.FloorMaterial == Enum.Material.Air;
		end

		local isKiller = killerClass == playerClass;
		local now = tick();
		local timeSinceLastKill = nil;
		local killStreakCount = 0;
		if isKiller then
			local lastKill = lastKillTime[player];
			killStreakCount = 1;
			if lastKill then
				timeSinceLastKill = now - lastKill;
				if timeSinceLastKill <= modMoneyRewardSystem.Config.StreakWindow then
					killStreakCount = (killStreak[player] or 0) + 1;
				end
			end
			lastKillTime[player] = now;
			killStreak[player] = killStreakCount;
		end

		local rewardInfo = modMoneyRewardSystem:Compute{
			BaseReward = baseReward;
			NpcLevel = npcLevel;
			PlayerLevel = gameSave:GetStat("Level");

			PlayerDamage = playerDamage;
			TotalDamage = teamTotalDamage;
			ParticipantCount = #playerTags;

			IsKiller = isKiller;
			IsHeadshot = isHeadshotKill;

			FirstDamageTaken = firstDamageTaken;
			DeathTime = deathTime;
			PlayerLastDamageTaken = playerClass.HealthComp and playerClass.HealthComp.LastDamageTaken or nil;

			KillingBlowDamage = damagedata and damagedata.Damage or 0;
			 
			NpcMaxHealth = healthComp.MaxHealth;
			NpcMaxArmor = healthComp.MaxArmor;

			KillDistance = killDistance;
			IsPlayerAirborne = isPlayerAirborne;
			
			DamageCate = damagedata and damagedata.DamageCate or nil;
			DamageType = damagedata and damagedata.DamageType or nil;
			IsWeakPoint = damagedata and damagedata.IsWeakPoint or nil;
			TimeSinceLastKill = timeSinceLastKill;
			KillStreak = killStreakCount;
			DamageSources = damageSources;

			PlayerProperties = playerClass.Properties;
		};

		if rewardInfo and rewardInfo.Total > 0 then
			local moneyReward = rewardInfo.Total;

			local bonusTextPacket = {};
			local bonusMoney = 0;
			for _, bonus in ipairs(rewardInfo.Bonuses) do
				table.insert(bonusTextPacket, {
					T=bonus.Text; 
					V=bonus.Bonus;
				});
				bonusMoney += bonus.Bonus;
			end

			if gameSave:AddStat("Money", moneyReward) > 0 then
				modAnalyticsService:Source{
					Player = player;
					Currency = modAnalyticsService.Currency.Money;
					Amount = moneyReward;
					EndBalance = gameSave:GetStat("Money");
					ItemSKU = `Kill:{npcClass.Name}`;
				};

				profile:GuiAction("hint_moneyreward", `<b>+${moneyReward-bonusMoney}</b> Kill {npcClass.Name}`, bonusTextPacket);
			end

			table.insert(killNotice, `+${moneyReward}`);
		end

		if humanoidType == "Zombie" and npcLevel then -- Focus levels
			local levelKey = `LevelKills-{npcLevel}`;
			gameSave:AddStat(levelKey, 1);

			local levelKills = gameSave:GetStat(levelKey) or 0;
			local playerLevel = gameSave:GetStat("Level") or 0;
			if levelKills > 0 and math.fmod(levelKills, modGlobalVars.GetFocusLevel(playerLevel, npcLevel)) == 0 then
				playerBonusExp[player.Name] = true;

				if gameSave:AddStat("Perks", 1) > 0 then
					modAnalyticsService:Source{
						Player = player;
						Currency = modAnalyticsService.Currency.Perks;
						Amount = 1;
						EndBalance = gameSave:GetStat("Perks");
						ItemSKU = `FocusKills`;
					};
				end

				table.insert(killNotice, `+1 Perk`);
			end
		end

		if gameSave.Statistics and npcLevel then
			local killKey = `L{npcLevel}-{npcClass.Name}-Kills`;
			gameSave.Statistics:AddStat("KillTracker", killKey, 1);
		end
		profile:AddPlayPoints(2, "Gameplay:Kill:Enemies");

		shared.Notify(player, table.concat(killNotice, " "), "Reward");


		-- Exp
		if damageLogComp and damageLogComp.Log[player.Name] then
			local logData = damageLogComp.Log[player.Name];
			Debugger:StudioLog("LogData:", logData);
			
			local totalDamage = 0;
			for siid, weaponData in pairs(logData) do
				totalDamage = totalDamage + weaponData.Damage;
			end
			
			for siid, weaponData in pairs(logData) do
				local storageItem: StorageItem = weaponData.StorageItem;
				local itemOwner = storageItem.Player;
				local damageRatio = math.clamp(weaponData.Damage/totalDamage, 0, 1);

				local weaponLevel = storageItem:GetValues("L") or 0;
				local baseExp = rawProperties.BaseExperience or 20;

				local expGain = math.clamp((baseExp - weaponLevel) * damageRatio, 1, baseExp);

				if itemOwner and playerBonusExp[itemOwner.Name] then
					expGain += math.clamp(baseExp * damageRatio, 1, baseExp);
				end

				if storageItem.StorageId == "portableautoturret" then
					expGain = math.ceil(expGain * 0.25);
				end

				modExperience.Add(storageItem, expGain);
			end
		end

		task.spawn(function()
			playerClass:FireAllModifiersBind("DeathHandler", npcClass, damagedata);
		end)
	end

end

return Component;
