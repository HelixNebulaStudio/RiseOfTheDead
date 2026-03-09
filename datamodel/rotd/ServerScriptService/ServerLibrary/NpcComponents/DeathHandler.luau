local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Script;
local CollectionService = game:GetService("CollectionService");

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

local modExperience = shared.require(game.ServerScriptService.ServerLibrary.Experience);
local modAnalytics = shared.require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;
--==

function Component.new(npcClass: NpcClass)
	local self = {
		_called = false;
		NpcClass = npcClass;
	};
	
	setmetatable(self, Component);
	return self;
end

function Component:__call()
	if self._called then return end;
	self._called = true;

	local npcClass: NpcClass = self.NpcClass;

	local npcPackage: anydict = npcClass.NpcPackage;
	local character: Model = npcClass.Character;
	local rawProperties: anydict = npcClass.Properties.Values;

	CollectionService:RemoveTag(character, "TargetableEntities");

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
			math.rad(math.random(0, 360))
		));
	end

	local npcLevel = rawProperties.Level;
	for a=1, #playerTags do
		local playerTag = playerTags[a];
		local player: Player = playerTag.Player;
		if player == nil or not game.Players:IsAncestorOf(player) then continue end;

		local playerClass: PlayerClass = shared.modPlayers.get(player);

		local profile: Profile = shared.modProfile:Get(player);
		local gameSave: GameSave = profile:GetActiveSave();
		if gameSave == nil then continue end;

		gameSave:AddStat("Kills", 1);
		
		local killNotice = {`Killed {npcClass.Name} [{npcLevel}]`};

		if humanoidType == "Zombie" then
			gameSave:AddStat("ZombieKills", 1);

		elseif humanoidType == "Human"
			or humanoidType == "Rat"
			or humanoidType == "Bandit" then
			gameSave:AddStat("HumanKills", 1);
			
		end

		if rawProperties.MoneyReward then -- Money Reward
			local moneyRang: NumberRange = rawProperties.MoneyReward;
			local moneyReward = math.random(moneyRang.Min, moneyRang.Max) + (npcLevel-1);

			if gameSave:AddStat("Money", moneyReward) > 0 then
				modAnalyticsService:Source{
					Player=player;
					Currency=modAnalyticsService.Currency.Money;
					Amount=moneyReward;
					EndBalance=gameSave:GetStat("Money");
					ItemSKU=`Kill:{npcClass.Name}`;
				};
			end

			table.insert(killNotice, `+${moneyReward}`);
		end

		if humanoidType == "Zombie" then -- Focus levels
			local levelKey = `LevelKills-{npcLevel}`;
			gameSave:AddStat(levelKey, 1);

			local levelKills = gameSave:GetStat(levelKey) or 0;
			local playerLevel = gameSave:GetStat("Level") or 0;
			if levelKills > 0 and math.fmod(levelKills, modGlobalVars.GetFocusLevel(playerLevel, npcLevel)) == 0 then
				if gameSave:AddStat("Perks", 1) > 0 then
					modAnalytics.RecordResource(player.UserId, 1, "Source", "Perks", "Gameplay", "FocusKills");
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

		if gameSave.Statistics then
			local killKey = `L{npcLevel}-{npcClass.Name}-Kills`;
			gameSave.Statistics:AddStat("KillTracker", killKey, 1);
		end
		profile:AddPlayPoints(3, "Gameplay:Kill:Enemies");

		shared.Notify(player, table.concat(killNotice, " "), "Reward");


		-- Exp
		local damageLogComp = npcClass:GetComponent("DamageLog");
		if damageLogComp and damageLogComp.Log[player.Name] then
			local logData = damageLogComp.Log[player.Name];
			Debugger:StudioLog("LogData:", logData);
			
			local totalDamage = 0;
			for siid, weaponData in pairs(logData) do
				totalDamage = totalDamage + weaponData.Damage;
			end
			
			for siid, weaponData in pairs(logData) do
				local storageItem: StorageItem = weaponData.StorageItem;
				local damageRatio = math.clamp(weaponData.Damage/totalDamage, 0, 1);

				local weaponLevel = storageItem:GetValues("L") or 0;
				local expPool = rawProperties.ExperiencePool or 20;
				local expGain = math.clamp(expPool - weaponLevel, 1, expPool);

				if storageItem.StorageId == "portableautoturret" then
					expGain = math.ceil(expGain * 0.1);
				end

				modExperience.Add(storageItem, expGain, npcClass.Name);

				storageItem:Sync({"L"; "E"; "EG"});
			end
		end

		task.spawn(function()
			playerClass:FireAllModifiersBind("DeathHandler", npcClass);
		end)
	end

end

return Component;