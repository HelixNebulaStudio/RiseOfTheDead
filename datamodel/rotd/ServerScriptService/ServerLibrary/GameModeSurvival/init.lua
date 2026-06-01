local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Players = game:GetService("Players");
local RunService = game:GetService("RunService");

--==
local Survival = {};
Survival.__index = Survival;
Survival.Seed = nil;

local EnumStatus = {Initialized=-1; Restarting=0; InProgress=1; Completed=2;};
Survival.EnumStatus = EnumStatus;

local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modDropRateCalculator = shared.require(game.ReplicatedStorage.Library.DropRateCalculator);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modGarbageHandler = shared.require(game.ReplicatedStorage.Library.GarbageHandler);

local modNpcs = shared.modNpcs;

local remoteGameModeHud = modRemotesManager:Get("GameModeHud");

local StageElements = game.ServerStorage:WaitForChild("StageElements");
local cratePallet = game.ServerStorage.Prefabs.Objects.Crates.CratePallet;

local Modifiers = {};

local STORAGE_ID = "survivalrewards";
--==
Survival.OnWaveChanged = shared.EventSignal.new("OnWaveChanged");
Survival.OnSurvivalNpcSpawn = shared.EventSignal.new("OnSurvivalNpcSpawn");
Survival.OnSurvivalNpcDeath = shared.EventSignal.new("OnSurvivalNpcDeath");
Survival.Active = nil;

function Survival.onRequire()
	shared.modEventService:OnInvoked("Storage_OnOpen", function(event: EventPacket, ...)
		local player: Player? = event.Player;
		if player == nil then return end;

		local storage: Storage = ...;
		if storage == nil then return end

		task.spawn(function()
			Debugger:Warn("Survival rewards opened", player.Name, "storage.Id", storage.Id);
			if storage.Id ~= "survivalrewards" then return end;

			for config, interactable: InteractableInstance in pairs(modInteractables.InstanceList) do
				if interactable.Name ~= "GameModeExit" then continue end;

				modReplicationManager:SetClientAttribute(player, config, "ClaimedRewards", true);
			end
		end)
	end)

	shared.modEventService:OnInvoked("Npcs_BindDeath", function(eventPacket: EventPacket, ...)
		local npcClass: NpcClass = ...;
		if npcClass == nil then return end;
	
	end)

	remoteGameModeHud.OnServerEvent:Connect(function(player: Player, action, ...)
		local gameController = Survival.Active;
		local userId = tostring(player.UserId);

		local waveSelect = gameController and gameController.WaveSelectPacket or nil;

		if action == "selectoption" then
			if gameController == nil then return end;

			local optionPick = ...;

			if waveSelect == nil or waveSelect.Active ~= true then return end;
			if waveSelect.Players[userId] == nil or waveSelect.Players[userId].OptionPick == optionPick then return end;
			if typeof(optionPick) ~= "number" then return end;

			local profile = shared.modProfile:Get(player);
			local gameSave = profile and profile:GetActiveSave();
			local playerLevel = gameSave and gameSave:GetStat("Level") or 1;

			if waveSelect.Options[optionPick].Level and playerLevel < waveSelect.Options[optionPick].Level then return end;

			local noOfOptions = #waveSelect.Options;
			local optionIndex = math.clamp(optionPick, 1, noOfOptions);
			
			waveSelect.Players[userId].OptionPick = optionIndex;
			gameController:Hud();
			Debugger:Warn(`OptionSelect`, waveSelect.Players[userId]);

		elseif action == "vote" then
			if gameController == nil then return end;

			local votePick = ...;

			if waveSelect == nil or waveSelect.Active ~= true then return end;
			if waveSelect.Players[userId] == nil then return end;
			if typeof(votePick) ~= "number" then return end;

			local voteIndex = math.clamp(votePick, 1, 2);
			waveSelect.Players[userId].VotePick = voteIndex;
			waveSelect.Players[userId].HasVoted = true;
			gameController:Hud();

		end
	end)
end

function Survival.new()
	local self = {
		Rng = 0.123456;
		JobsList = {};
		
		Status = EnumStatus.Initialized;
		StageElements = StageElements;
		
		ObjectivesList = nil;
		HazardsList = nil;
		
		ModeType = nil;
		ModeStage = nil;
		SupplyCratePrefabs = {};
		StageGarbage = modGarbageHandler.new();
		
		CompletedOnce = false;
		RoomData = nil;
		Seed = nil;
		IsHard = false;
		GameState = "";
		
		Players = {};
		Characters = {};
		
		EnemyNpcClasses = {};
		EnemiesSpawned = 0;
		
		Wave = 1;
		LastSupplyWave = 10;
		StatsCount = {};
		
		BasicEnemySpawns = {};
		SupplySpawns = {};
		
		PeekPlayerLevel = 100;
		Modifier = {};
		RewardItemIdDebounce = {};
		
		--Cmds;
		SetHazard = nil;
		SetObjective = nil;
		SkipWave = false;

		--Shared
		NextWaveSelect = 1;
		WaveSelectPacket = {
			Active = false;
			Options = {};
			Players = {};
			TimeLeft = 30;
		};
		SelectedOption = nil;

		Storages = {};
	};
	
	if Survival.Active == nil then
		Survival.Active = self;
	end
	
	setmetatable(self, Survival);
	return self;
end

function Survival:Load()	
	self.NormalEndWave = math.min(5, #self.ObjectivesList);

	self.GameLib = modGameModeLibrary.GetGameMode(self.ModeType);
	self.StageLib = self.GameLib and modGameModeLibrary.GetStage(self.ModeType, self.ModeStage);
	
	for a=1, #self.ObjectivesList do
		local module = script.Objectives:FindFirstChild(self.ObjectivesList[a].Type);
		
		if self[self.ObjectivesList[a].Type .."Config"] == nil then
			self[self.ObjectivesList[a].Type .."Config"] = {};
		end
		
		self.ObjectivesList[a].Class = shared.require(module);
		self.ObjectivesList[a].Class.Controller = self;
		self.ObjectivesList[a].Class:Load();
	end
	for a=1, #self.HazardsList do
		local module = script.Hazards:FindFirstChild(self.HazardsList[a].Type);
		
		if self[self.HazardsList[a].Type .."Config"] == nil then
			self[self.HazardsList[a].Type .."Config"] = {};
		end
		
		self.HazardsList[a].Class = shared.require(module);
		self.HazardsList[a].Class.Controller = self;
		self.HazardsList[a].Class:Load();
	end

	for _, obj in pairs(StageElements:WaitForChild("Spawns"):GetChildren()) do
		table.insert(self.BasicEnemySpawns, obj);
		obj.Transparency = 1;
	end
	for _, obj in pairs(StageElements:WaitForChild("SupplySpawns"):GetChildren()) do
		table.insert(self.SupplySpawns, obj);
		obj.Transparency = 1;
	end
	
	shared.modEventService:OnInvoked("Npcs_BindDeath", function(eventPacket: EventPacket, ...)
		local npcClass: NpcClass = ...;
		if npcClass == nil or npcClass.HumanoidType ~= "Zombie" then return end;
	
		local playerTags = modDamageTag:Get(npcClass.Character, "Player");
		for a=1, #playerTags do
			local playerTag = playerTags[a];
			local player: Player = playerTag.Player;
			if player == nil or not game.Players:IsAncestorOf(player) then continue end;

			local playerName = player.Name;
			self.StatsCount[playerName] = (self.StatsCount[playerName] or 0) + 1;
		end
	end)
	
	-- MARK: /survival
	task.spawn(function()
		Debugger.AwaitShared("modCommandsLibrary");
		shared.modCommandsLibrary:HookChatCommand("survival", {
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
			Description = [[Survival commands.
		/survival skip
		/survival setwave wave
		/survival sethazard hazardId
		/survival setobj objectiveId
		/survival resupply
		/survival listwaves [startWave]
		]];

			RequiredArgs = 0;
			UsageInfo = "/survival action";
			Function = function(player, args)
				local action = args[1];
				
				if action == "skip" then
					self.SkipWave = true;
					
				elseif action == "setwave" then
					local wave = math.clamp((tonumber(args[2]) or 1)-1, 1, 999);
					
					self.Wave = wave;
					if self.Status == EnumStatus.InProgress then
						self.SkipWave = true;
						shared.Notify(game.Players:GetPlayers(), "Next wave set to "..wave.." and skipping current.", "Inform");
					else
						shared.Notify(game.Players:GetPlayers(), "Next wave set to "..wave..".", "Inform");
					end
					
				elseif action == "sethazard" then
					local hazardId = tostring(args[2]);
					
					local foundHazard;
					for a=1, #self.HazardsList do
						if self.HazardsList[a].Type == hazardId then
							foundHazard = self.HazardsList[a];
							break;
						end
					end
					
					if foundHazard then
						self.SetHazard = foundHazard;
						shared.Notify(game.Players:GetPlayers(), "Next wave hazard set: ".. hazardId , "Inform");
					else
						shared.Notify(game.Players:GetPlayers(), "Could not find hazard: ".. hazardId , "Negative");
					end

				elseif action == "setobj" then
					local objectiveId = tostring(args[2]);

					local found;
					for a=1, #self.ObjectivesList do
						if self.ObjectivesList[a].Type == objectiveId then
							found = self.ObjectivesList[a];
							break;
						end
					end

					if found then
						self.SetObjective = found;
						shared.Notify(game.Players:GetPlayers(), "Next wave objective set: ".. objectiveId , "Inform");
					else
						shared.Notify(game.Players:GetPlayers(), "Could not find objective: ".. objectiveId , "Negative");
					end
					
				elseif action == "resupply" then
					self.ResupplyEnabled = true;
					shared.Notify(game.Players:GetPlayers(), "Resupply crate will spawn at the end of the wave.", "Inform");

				elseif action == "listwaves" then
					local startWave = tonumber(args[2]) or self.Wave;
					
					local waveStr = {};
					for w=startWave, startWave+10 do
						local pickObjective, pickHazard = self:GetNextWaveInfo(w);
						
						table.insert(waveStr, `[{w}] Obj:{pickObjective and pickObjective.Type or "~"} Haz:{pickHazard and pickHazard.Type or "~"}`);
					end

					shared.Notify(player, "Next 10 waves:\n"..table.concat(waveStr, "\n"), "Inform");

				end
				
				return true;
			end;
		});
	end)
end

-- MARK: GetWaveLevel
function Survival:GetWaveLevel()
	local level = self.Wave;
	if self.IsHard then
		level = math.round(math.pow(2, (self.Wave+2)/2));
	end
	
	return level;
end

function Survival:PickEnemy()
	if self.CurrentWaveEnemyPool == nil or self.CurrentWaveEnemyPool.Wave ~= self.Wave then
		-- Generate a enemy pool table per wave.
		local validList = {};

		for a=1, #self.EnemiesList do
			local enemyOption = self.EnemiesList[a];
			local fmod = enemyOption.Fmod or 1;
			local startWave = enemyOption.StartWave or 1;
			
			local spawnConditionFunc = enemyOption.CanSpawnFunc;
			local isSpawnable = false;
			
			if spawnConditionFunc then
				isSpawnable = spawnConditionFunc(self, enemyOption);
			end
			
			if isSpawnable == true or (math.fmod(self.Wave, fmod) == 0 and self.Wave >= startWave) then
				table.insert(validList, enemyOption);
			end
		end

		local pickTable = {};
		local totalChance = 0;
		for a=1, #validList do
			local enemyOption = validList[a];
			
			totalChance = totalChance + enemyOption.Chance;
			table.insert(pickTable, {Total=totalChance; Data=enemyOption});
		end
		
		self.CurrentWaveEnemyPool = {
			Wave = self.Wave;
			TotalChance = totalChance;
			PickTable = pickTable;
		};
	end

	if self.CurrentWaveEnemyPool then
		local pickTable = self.CurrentWaveEnemyPool.PickTable;
		local roll = math.random(0, self.CurrentWaveEnemyPool.TotalChance);
		for a=1, #pickTable do
			if roll <= pickTable[a].Total then
				return pickTable[a].Data.Name;
			end
		end
	end
	
	return "Zombie";
end

function Survival:SpawnEnemy(npcName, paramPacket)
	paramPacket = paramPacket or {};
	
	local spawnCf = paramPacket.SpawnCFrame or self.BasicEnemySpawns[math.random(1, #self.BasicEnemySpawns)].CFrame;
	local level = math.max((paramPacket.Level or 1) + math.random(-2, 0), 1);
	
	local currWave = self.Wave;
	local _hardMode = paramPacket.HardChance and math.random(0, 1000)/1000 <= paramPacket.HardChance or false;
	if paramPacket.HardChance then
		Debugger:StudioWarn("Hardmode chance:",paramPacket.HardChance);
	end

	local newNpcClass: NpcClass = modNpcs.spawn2{
		Name = npcName;
		CFrame = spawnCf;
		NetworkOwners = game.Players:GetPlayers();
		Properties = {
			Level = level;
			HordeAggression = true;
			TargetableDistance = 4096;
		};
		BindSetup = function(npcClass: NpcClass)
			task.spawn(function()
				while currWave == self.Wave do
					task.wait(1);
				end
				if npcClass.HealthComp.IsDead then return end;
				npcClass:Destroy();
			end)
			table.insert(self.EnemyNpcClasses, npcClass);

			self.EnemiesSpawned = self.EnemiesSpawned + 1;

			npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
				if not isDead then return end;
				
				self.LastKilled = tick();
				for a=#self.EnemyNpcClasses, 1, -1 do
					if self.EnemyNpcClasses[a] == npcClass then
						table.remove(self.EnemyNpcClasses, a);
						break;
					end
				end
				
				self.LastEnemyDeathPos = npcClass:GetCFrame().Position;
				Survival.OnSurvivalNpcDeath:Fire(npcClass);
			end)
			
			local targetHandlerComp = npcClass:GetComponent("TargetHandler");
			if targetHandlerComp then
				for _, player in pairs(self.Players) do
					targetHandlerComp:AddTarget(player.Character);
				end
			end
			
			if self.OnEnemySpawn then
				self:OnEnemySpawn(npcClass);
			end
			if self.BindWorldCoreEnemySpawn then
				self:BindWorldCoreEnemySpawn(npcClass);
			end
			
			Survival.OnSurvivalNpcSpawn:Fire(npcClass);
		end
	};
	
	return newNpcClass;
end

function Survival:CompleteWave()
	self.StageGarbage:Destruct();
	self:RespawnDead();

	self:Hud{
		PlayWaveEnd = true;
	};

	shared.modEventService:ServerInvoke(
		"Survival_BindWaveReached", 
		{ReplicateTo=game.Players:GetPlayers()},
		self
	);

	task.wait(1);
end

--MARK: GetNextWaveInfo
function Survival:GetNextWaveInfo(wave)
	local random = Random.new(self.Rng + wave);
	local pickObjective, pickHazard;

	if self.SelectedOption then
		local selectedOption = self.SelectedOption;
		local objectivesList = selectedOption.Objectives;
		local hazardsList = selectedOption.Hazards;
		Debugger:StudioLog("selected option GetNextWaveInfo", objectivesList, hazardsList);

		local objPick = objectivesList[random:NextInteger(1, #objectivesList)];
		if objPick == nil then
			objPick = self.ObjectivesList[1];
		end
		local hazPick = hazardsList[random:NextInteger(1, #hazardsList)];

		for a=1, #self.ObjectivesList do
			if self.ObjectivesList[a].Type ~= objPick.Type then continue end;
			
			pickObjective = self.ObjectivesList[a];
			break;
		end

		for a=1, #self.HazardsList do
			if self.HazardsList[a].Type ~= hazPick.Type then continue end;
			
			pickHazard = self.HazardsList[a];
			break;
		end

		return pickObjective, pickHazard;
	end

	if wave < #self.ObjectivesList then
		pickObjective = self.ObjectivesList[math.fmod(wave-1, #self.ObjectivesList)+1];
		if math.fmod(wave, 2) == 0 then
			pickHazard = self.HazardsList[math.round(math.fmod(wave/2, #self.HazardsList)) +1];
			
		end
		
	else
		
		local function roll(list)
			local optionsList = {};
			local largestFmod = 0;
			
			for a=1, #list do
				if math.fmod(wave, (list[a].Fmod or 1)) == 0 then
					if list[a].Fmod > largestFmod then
						largestFmod = list[a].Fmod;
					end
					
					table.insert(optionsList, list[a]);
				end
			end
			
			table.sort(optionsList, function(a, b) return a.Fmod > b.Fmod end);

			for a=#optionsList, 1, -1 do
				if optionsList[a].Fmod < largestFmod then
					table.remove(optionsList, a);
				end
			end
			
			if #optionsList <= 0 then return nil end;
			return optionsList[random:NextInteger(1, #optionsList)], largestFmod;
		end
		
		pickObjective = roll(self.ObjectivesList);
		
		if wave > 5 then
			local rngMax = wave > 20 and 1 or wave > 15 and 2 or wave > 10 and 3 or 4;

			if random:NextInteger(1, rngMax) == 1 then
				pickHazard = roll(self.HazardsList);
			end
		end;
		
	end

	for a=1, #self.ObjectivesList do
		if self.ObjectivesList[a].Test == true then
			pickObjective = self.ObjectivesList[a];
			break;
		end
	end
	for a=1, #self.HazardsList do
		if self.HazardsList[a].Test == true then
			pickHazard = self.HazardsList[a];
			break;
		end
	end
	
	if self.SetHazard then
		pickHazard = self.SetHazard;
	end
	
	if self.SetObjective then
		pickObjective = self.SetObjective;
	end

	if pickObjective == nil then
		pickObjective = self.ObjectivesList[1];
	end

	return pickObjective, pickHazard;
end

-- MARK: NewWaveSelect
function Survival:NewWaveSelect()
	self.WaveSelectPacket.Active = true;

	local lowestPlayerLevel = math.huge;
	for _, player in ipairs(self.Players) do
		local profile = shared.modProfile:Get(player);
		local gameSave = profile and profile:GetActiveSave();
		local playerLevel = gameSave and gameSave:GetStat("Level") or 1;
		if playerLevel < lowestPlayerLevel then
			lowestPlayerLevel = playerLevel;
		end
	end

	self.DropCycleIndex = (self.DropCycleIndex or -1) +1;
	local dropTableIdsList = {self.StageLib.RewardsId};

	local stageRewardIds = self.StageLib.RewardsIds;
	local dropsFmod = 0;
	if stageRewardIds then
		dropsFmod = math.fmod(self.DropCycleIndex, #stageRewardIds);
		for a=1, #stageRewardIds do
			if (dropsFmod+1) < a then break; end;
			if table.find(dropTableIdsList, stageRewardIds[a]) == nil then
				table.insert(dropTableIdsList, stageRewardIds[a]);
			end
		end
	end
	if self.IsHard and self.StageLib.HardRewardId then
		dropTableIdsList = {self.StageLib.HardRewardId};
	end

	local customRewardsTable = {};
	for a=1, #dropTableIdsList do
		local dropTableId = dropTableIdsList[a];
		local rewardLib = modRewardsLibrary:Find(dropTableId);

		if rewardLib.WaveBased then
			local highestWaveReward = nil;
			for a=1, #rewardLib.Rewards do
				local rewardInfo = rewardLib.Rewards[a];

				if highestWaveReward == nil or rewardInfo.Wave > highestWaveReward then
					highestWaveReward = rewardInfo.Wave;
				end
				if rewardInfo.Wave ~= self.Wave then continue end;

				local cloneRewardInfo = table.clone(rewardInfo);
				cloneRewardInfo.Chance = 2;
				cloneRewardInfo.DropTableId = dropTableId;
				table.insert(customRewardsTable, cloneRewardInfo);
			end
			if self.Wave > highestWaveReward then
				-- Drop random components if no more wave based rewards;
				local compRewardLib = modRewardsLibrary:Find("components");
            	local compReward = modDropRateCalculator.RollDrop(compRewardLib);
				if compReward then
					local cloneRewardInfo = table.clone(compReward[1]);
					cloneRewardInfo.Chance = 2;
					cloneRewardInfo.DropTableId = dropTableId;
					table.insert(customRewardsTable, cloneRewardInfo);
				end
			end

		elseif rewardLib and rewardLib.Rewards then
			for b=1, #rewardLib.Rewards do
				local cloneRewardInfo = table.clone(rewardLib.Rewards[b]);
				if cloneRewardInfo.Level == nil then
					cloneRewardInfo.Level = rewardLib.Level;
				end
				cloneRewardInfo.DropTableId = dropTableId;
				table.insert(customRewardsTable, cloneRewardInfo);
			end

		end
	end

	local waveBonusChance = math.clamp(math.floor(self.Wave/5)/12, 0, 1)/2;
	for a=1, #customRewardsTable do
		local rewardInfo = customRewardsTable[a];
		if #customRewardsTable > 1 and (rewardInfo.Chance + waveBonusChance) > 1 then
			rewardInfo.BonusChance = -waveBonusChance/2; -- reduce chance of common items
			rewardInfo.Chance = 1 +rewardInfo.BonusChance;
		else
			rewardInfo.BonusChance = waveBonusChance; -- increase chance of rare items
			rewardInfo.Chance = rewardInfo.Chance + waveBonusChance;
		end
	end

	local rewardPicksList = {};
	if #customRewardsTable > 0 then
		Debugger:StudioLog(self.Wave, "customRewardsTable", customRewardsTable);
		local loopkill = 0;
		local rewardOptions = self.IsHard and 3 or 2;
		if self.Wave > 10 then
			rewardOptions = 3;
		elseif self.Wave > 25 then
			rewardOptions = 4;
		end
		repeat
			local rewardInfo = modDropRateCalculator.roll(customRewardsTable);

			-- skip reward if there's already one.
			-- skip reward if exist last round.
			if rewardInfo and self.RewardItemIdDebounce[rewardInfo.ItemId] ~= nil then continue; end

			-- skip reward if list is empty and reward is not in player required level
			if rewardInfo and #rewardPicksList <= 0 and (rewardInfo.Level or 0) > lowestPlayerLevel then
				continue;
			end
			
			if rewardInfo == nil then continue end;

			self.RewardItemIdDebounce[rewardInfo.ItemId] = self.Wave;
			table.insert(rewardPicksList, rewardInfo);
			loopkill += 1;
			if loopkill > 64 then
				Debugger:Warn(`Breaking reward choose loop.`);
				break;
			end;
		until #rewardPicksList >= math.min(rewardOptions, #customRewardsTable);

	else
		self.WaveSelectPacket.Active = false;
		Debugger:Warn(`No rewards in customRewardsTable this wave. Wave=`,self.Wave);
	end

	-- clear debounce from past reward
	for k, w in pairs(self.RewardItemIdDebounce) do
		if w == self.Wave then continue end;
		self.RewardItemIdDebounce[k] = nil;
	end

	if self.WaveSelectPacket.Active == false then return end;

	table.sort(rewardPicksList, function(rInfoA, rInfoB)
		return rInfoA.Chance > rInfoB.Chance;
	end)

	local wavesToComplete = 5;
	if not self.IsHard then
		for a=1, #rewardPicksList do
			local rInfo = rewardPicksList[a];
			local rChance = (1/5) * (a/5) * (1-rInfo.WinChance);

			local objPicksDict = {};
			local customObjDrawList = {};
			local uniqueObjTypes = {};
			local defaultObj = nil;
			for _, objData in ipairs(self.ObjectivesList) do
				local oChance = objData.Chance or 1/objData.Fmod;
				local newObj = {
					Type = objData.Type;
					Title = objData.Class.Title;
					Chance = math.clamp(oChance + rChance, 0, 1);
				}
				if objData.Chance >= 1 then
					defaultObj = newObj;
				end
				table.insert(customObjDrawList, newObj);
			end
			for b=1, wavesToComplete do
				local oInfo = modDropRateCalculator.roll(customObjDrawList);
				local objType = oInfo and oInfo.Type or "Eliminate";
				if table.find(uniqueObjTypes, objType) == nil then
					table.insert(uniqueObjTypes, objType);
				end

				local objData = objPicksDict[objType] or {};
				objData.Type = objType;
				objData.Title = oInfo.Title;
				objData.Amount = (objData.Amount or 0) + 1;
				objData.WinChance = math.max(objData.WinChance or 0, oInfo.WinChance);
				objPicksDict[objType] = objData;

				if #uniqueObjTypes >= 3 then
					local noOfElimToFill = wavesToComplete-b;
					if noOfElimToFill > 0 then
						local defaultType = defaultObj.Type;
						local defaultObjData = objPicksDict[defaultType] or {};
						defaultObjData.Type = defaultType;
						defaultObjData.Title = defaultObj.Title;
						defaultObjData.Amount = (defaultObjData.Amount or 0) + noOfElimToFill;
						defaultObjData.WinChance = defaultObj.WinChance or 1;
						objPicksDict[defaultType] = defaultObjData;
					end
					break;
				end
			end

			
			local hazPicksDict = {};
			local customHazDrawList = {};
			for _, hazData in ipairs(self.HazardsList) do
				local hChance = hazData.Chance or 1/hazData.Fmod;
				table.insert(customHazDrawList, {
					Type = hazData.Type;
					Title = hazData.Class.Title;
					Chance = math.clamp(hChance + rChance, 0, 1);
				});
			end
			local minHazNeed = math.floor(self.Wave/20);
			if math.random(1, 10) == 1 then minHazNeed +=1 end;
			if math.random(1, 100) == 1 then minHazNeed +=1 end;
			local hazardsNeed = math.clamp(math.random(minHazNeed, minHazNeed+1), 1, 5);
			for b=1, hazardsNeed do
				local hInfo = modDropRateCalculator.roll(customHazDrawList);
				if hInfo == nil then continue; end
				
				local hazType = hInfo.Type;
				local hazData = hazPicksDict[hazType] or {};
				hazData.Type = hazType;
				hazData.Title = hInfo.Title;
				hazData.Amount = (hazData.Amount or 0) + 1;
				hazData.WinChance = math.max(hazData.WinChance or 0, hInfo.WinChance);
				hazPicksDict[hazType] = hazData;
			end

			rInfo.Objectives = modTables.DictToList(objPicksDict);
			table.sort(rInfo.Objectives, function(a, b) return a.WinChance > b.WinChance; end);
			rInfo.Hazards = modTables.DictToList(hazPicksDict);
			table.sort(rInfo.Hazards, function(a, b) return a.WinChance > b.WinChance; end);
			rInfo.OpChance = rChance;
		end
	end

	self.WaveSelectPacket.Options = rewardPicksList;
	self.WaveSelectPacket.TimeLeft = 30;

	if self.Wave <= 5 then
	elseif #self.WaveSelectPacket.Options <= 1 then
		self.WaveSelectPacket.TimeLeft = 10;
	elseif self.Wave > 20 then
		self.WaveSelectPacket.TimeLeft = 15;
	end

	self.WaveSelectPacket.Players = {};
	for _, player in ipairs(self.Players) do
		self.WaveSelectPacket.Players[tostring(player.UserId)] = {
			HasVoted = false;
			VotePick = 1; -- continue
			OptionPick = 1; -- default choice
		};
	end

	self:Hud{
		Status = `Time for wave select!`;
	};
end


-- MARK: SpawnCrate
function Survival:SpawnCrate()
	local rewardSpawnAtt = StageElements:WaitForChild("RewardSpawn");

	local cratePrefab = cratePallet:Clone();
	cratePrefab.Name = "WavePassCrate";
	cratePrefab:PivotTo(rewardSpawnAtt.WorldCFrame);

	local interactConfig = modInteractables.createInteractable("Storage");
	interactConfig:SetAttribute("StorageId", "survivalrewards");
	interactConfig:SetAttribute("StorageName", "Survival Rewards");
	interactConfig:SetAttribute("StoragePresetId", "rewardcrate");
	interactConfig.Parent = cratePrefab;
	
	local interactable: InteractableInstance = modInteractables.getOrNew(interactConfig);
	for _, player in ipairs(self.Players) do
		interactable:SetUserPermissions(player.Name, "CanInteract", true);
	end

	cratePrefab.Parent = workspace.Interactables;
	self.LootPrefab = cratePrefab;
end


function Survival:BreakTime()
	local nextWave = self.Wave+1;
	local nextObj, nextHaz = self:GetNextWaveInfo(nextWave);

	local statusStr = "";

	local breakLength = 10;
	if self.Wave == 1 or self.ResupplyEnabled then
		breakLength += 10;
		statusStr = `{statusStr} [Resupply Available]`;

		--MARK: Supply Station
		self.ResupplyEnabled = false;
		self.LastSupplyWave = self.Wave;
		
		local rngSupCrate = game.ServerStorage.Prefabs.Objects.SurvivalSupplyCrate;
		if self.SupplyCratePrefabs and #self.SupplyCratePrefabs > 0 then
			rngSupCrate = self.SupplyCratePrefabs[math.random(1, #self.SupplyCratePrefabs)];
		end
		
		self.ActiveSupCrate = rngSupCrate:Clone();
		self.ActiveSupCrate.Parent = workspace.Interactables;
		
		local stationCf = self.SupplySpawns[math.random(1, #self.SupplySpawns)].CFrame;
		self.ActiveSupCrate:PivotTo(stationCf);
		
		shared.Notify(game.Players:GetPlayers(), "A supply station has been discovered!", "Reward");
	end;

	if not self.IsHard and self.Wave%15 == 0 then
		breakLength += 15;
		statusStr = `{statusStr} [Loot Available]`;

		--MARK: Claim Stakes
		self:SpawnCrate();
		shared.Notify(game.Players:GetPlayers(), "A Stake Crate has been discovered!", "Reward");
	end

	for a=breakLength, 0, -1 do
		self:RespawnDead();
		task.wait(1);
		self:Hud{
			HeaderText = `Wave {nextWave}`;
			Status = `Next wave starts in {a}s..{statusStr}`;
			WaveObjective = (self.WaveSelectPacket.Active and "") or nextObj and nextObj.Class.Title or "";
			ObjectiveDesc = (self.WaveSelectPacket.Active and "") or nextObj and nextObj.Class.Description or "";
			WaveHazard = (self.WaveSelectPacket.Active and "") or nextHaz and nextHaz.Class.Title or "";
			HazardDesc = (self.WaveSelectPacket.Active and "") or nextHaz and nextHaz.Class.Description or "";
		};
		if self.Status ~= EnumStatus.InProgress then break; end
	end

	if self.ActiveSupCrate then
		game.Debris:AddItem(self.ActiveSupCrate, 0);
		self.ActiveSupCrate = nil;
	end;
	if self.LootPrefab then
		self.LootPrefab:Destroy();
		self.LootPrefab = nil;
	end
end


-- MARK: StartWave
function Survival:StartWave(wave)
	self.GameState = "Active";
	self.Status = EnumStatus.InProgress;

	self:Hud{
		PlayWaveStart=true;
		StatsCount=false;
	}
	
	if wave == 1 then
		if self.IntroMessage then
			shared.Notify(game.Players:GetPlayers(), self.IntroMessage, "Positive");
		end

		if self.OnStart then
			self.OnStart(self.Players);
		end
	end

	--===
	self.EnemiesSpawned = 0;
	local pickObjectivePackage, pickHazardPackage;
	
	pickObjectivePackage, pickHazardPackage = self:GetNextWaveInfo(wave);
	
	self.SetHazard = nil;
	self.SetObjective = nil;
	--===
	
	self.StageGarbage:Destruct();
	local newObjective = pickObjectivePackage.Class.new();
	local newHazard = pickHazardPackage and pickHazardPackage.Class.new() or nil;

	if self.SelectedOption then
		local selectedOption = self.SelectedOption;
		local objList = selectedOption.Objectives;
		local hazList = selectedOption.Hazards;

		for a=#objList, 1, -1 do
			if objList[a].Type ~= pickObjectivePackage.Type then continue end;
			objList[a].Amount -= 1;
			if objList[a].Amount <= 0 then
				Debugger:StudioLog(`removing object pick`, objList[a]);
				table.remove(objList, a);
			end
			break;
		end
		if pickHazardPackage then
			for a=#hazList, 1, -1 do
				if hazList[a].Type ~= pickHazardPackage.Type then continue end;
				hazList[a].Amount -= 1;
				if hazList[a].Amount <= 0 then
					Debugger:StudioLog(`removing hazard pick`, hazList[a]);
					table.remove(hazList, a);
				end
				break;
			end
		end
		if #objList <= 0 and #hazList <= 0 then
			Debugger:StudioLog(`clear self.SelectedOption`);
			self.SelectedOption = nil;
		end
	end

	local hazardTitle = (newHazard and newHazard.Title or "None");
	shared.Notify(game.Players:GetPlayers(), `Wave {self.Wave}, Objective: {newObjective.Title}, Hazard: {hazardTitle}`, "Important");

	self:Hud{
		HeaderText = `Wave {self.Wave}`;
		Status = false;
		WaveObjective = newObjective.Title;
		ObjectiveDesc = newObjective.Description;
		WaveHazard = hazardTitle;
		HazardDesc = hazardTitle ~= "None" and newHazard.Description or "";
	}
	
	self.ObjectiveType = pickObjectivePackage.Type;
	self.HazardType = pickHazardPackage and pickHazardPackage.Type or nil;
	
	if newHazard then
		newHazard:Begin();
	end
	newObjective:Begin();
	

	for id, modifierInfo in pairs(self.Modifier) do
		if Modifiers[id] == nil then
			local module = script.Modifiers:FindFirstChild(id);
			Modifiers[id] = shared.require(module);
		end

		local modifierObject = Modifiers[id];

		if modifierObject then
			modifierObject:Set(modifierInfo):Begin(self);
		end
	end
	
	--MARK: Wave Tick
	local waveStartTick = tick();
	repeat
		task.wait();
		if newObjective:Tick() then break; end
		
		task.spawn(function()
			if newHazard then
				newHazard:Tick();
			end
		end)
		
		task.spawn(function()
			for id, modifierInfo in pairs(self.Modifier) do
				
				if Modifiers[id] == nil then
					local module = script.Modifiers:FindFirstChild(id);
					Modifiers[id] = shared.require(module);
				end
				
				local modifierObject = Modifiers[id];
				
				if modifierObject then
					modifierObject:Set(modifierInfo):Tick(self);
				end
			end
		end)
		
		if tick()-waveStartTick >= 120 and #modNpcs.ActiveNpcClasses <= 0 then break; end;
		if self.SkipWave then Debugger:Warn("Skip Wave"); break; end;
	until self.Status ~= EnumStatus.InProgress;
	
	self.SkipWave = false;
	
	newObjective:End();
	if newHazard then
		newHazard:End();
	end
	
	for id, modifierInfo in pairs(self.Modifier) do
		if Modifiers[id] == nil then
			local module = script.Modifiers:FindFirstChild(id);
			Modifiers[id] = shared.require(module);
		end

		local modifierObject = Modifiers[id];

		if modifierObject then
			modifierObject:Set(modifierInfo):End(self);
		end
	end
	
	pcall(function()
		if self.OnWaveEnd then
			self.OnWaveEnd(game.Players:GetPlayers(), wave);
		end
	end)
	--MARK: Wave Tick End
	Debugger:Log("Wave fin");
	
	for a=#self.EnemyNpcClasses, 1, -1 do
		game.Debris:AddItem(self.EnemyNpcClasses[a].Character, 0);
		self.EnemyNpcClasses[a]:Destroy();
		table.remove(self.EnemyNpcClasses, a);
	end
	
	
	self:Hud{
		Status = `Wave {self.Wave} complete!`;
		WaveObjective = false;
		WaveHazard = false;
	}
	
	if self.Status == EnumStatus.InProgress then
		self:CompleteWave();
		
		if self.IsHard or self.Wave == 1 or math.fmod(self.Wave, 5) == 0 then
			if self.SelectedOption then
				--MARK: Reward players
				local rewardOption = self.SelectedOption;
				Debugger:StudioLog(`Add reward`, rewardOption);
				for _, player in ipairs(self.Players) do
					task.spawn(function() 
						if rewardOption == nil then return end;

						local STORAGE_ID = "survivalrewards";

						local profile = shared.modProfile:Get(player);
						local storages = profile:GetCacheStorages();
						
						local storage: Storage = storages[STORAGE_ID] or self.Storages[player];
						if storage == nil then
							storage = shared.modStorage.new(STORAGE_ID, "rewardcrate", player, "Survival Rewards");
							storage.Properties.ItemSpawn = true;

							storage:SetPermissions("CanRemove", false);
							self.Storages[player] = storage;
						end
						storages[STORAGE_ID] = storage;

						storage:Add(rewardOption.ItemId, {Quantity=rewardOption.DropQuantity;});
						storage:Sync(player);
						Debugger:Warn(`Added {rewardOption.ItemId} x {rewardOption.DropQuantity} to ({player.Name}) {storage.Id}`);
					end)
				end
				self.SelectedOption = nil;

			end

			self:NewWaveSelect();
		end

		self.GameState = "Intermission";

		local waveSelect;
		if self.WaveSelectPacket.Active == true then
			local waveSelectTimeLeft = self.WaveSelectPacket.TimeLeft;

			local skipTimeLeft;
			for a=waveSelectTimeLeft, 0, -1 do
				self:RespawnDead();
				task.wait(1);
				
				if self.WaveSelectPacket.Active == true then
					waveSelect = self.WaveSelectPacket;

					--Skip if all continue;
					local voteSkipping = true;
					for uId, pData in pairs(waveSelect.Players) do
						if pData.HasVoted == false then
							voteSkipping = false;
						end
					end
					if voteSkipping == true then
						if skipTimeLeft == nil then
							skipTimeLeft = 3;
						else
							skipTimeLeft -= 1;
						end
					else
						skipTimeLeft = nil;
					end
				end


				self.WaveSelectPacket.TimeLeft = skipTimeLeft or a;
				self:Hud{
					HeaderText =`Choose your {self.IsHard and "rewards" or "waves"}!`;
					Status = `Lock in {a}s..`;
					WaveObjective = "";
					ObjectiveDesc = "";
					WaveHazard = "";
					HazardDesc = "";
				};

				if self.Status ~= EnumStatus.InProgress then break; end
				if skipTimeLeft and skipTimeLeft <= 0 then break; end;
			end
		end

		if self.WaveSelectPacket.Active == true then
			waveSelect = self.WaveSelectPacket;
		end

		if waveSelect then
			waveSelect.Active = false;
			waveSelect.TimeLeft = 0;
			self:Hud{
				Status = false;
			};
			task.wait(1);

			local endCount, continueCount = 0, 0;
			for _, playerInfo in pairs(waveSelect.Players) do
				if playerInfo.VotePick == 1 then
					continueCount = continueCount +1;
				else
					endCount = endCount +1;
				end
			end
			Debugger:Warn(`WavePass Vote EndCount: {endCount} ContinueCount: {continueCount}`);

			if self.IsHard then
				for _, player in ipairs(self.Players) do
					local playerWaveSelect = waveSelect.Players[tostring(player.UserId)];
					if playerWaveSelect == nil then continue end;

					local optionIndex = math.clamp(playerWaveSelect.OptionPick, 1, #waveSelect.Options);
					local rewardInfo = waveSelect.Options[optionIndex];
					
					task.spawn(function() 
						if rewardInfo == nil then return end;

						local profile = shared.modProfile:Get(player);
						local storages = profile:GetCacheStorages();
						
						local storage: Storage = storages[player] or self.Storages[player];
						if storage == nil then
							storage = shared.modStorage.new(STORAGE_ID, "rewardcrate", player, "Survival Rewards");
							storage.Properties.ItemSpawn = true;

							storage:SetPermissions("CanRemove", false);
							self.Storages[player] = storage;
						end
						storages[STORAGE_ID] = storage;

						storage:Add(rewardInfo.ItemId, {Quantity=rewardInfo.DropQuantity;});
						storage:Sync(player);
						Debugger:Warn(`WaveSelect OptionPick ({player.Name}) picked {rewardInfo.ItemId} x {rewardInfo.DropQuantity}`);
					end)
				end
			end

			if endCount >= continueCount then
				self.Status = EnumStatus.Completed;

				--MARK: WaveSelect End Game
				Debugger:Warn("WaveSelect End");

				self:Hud{
					LastWave = self.Wave;
					StatsCount = self.StatsCount;
					SurvivalEnded = true;
					HeaderText = "Survival Complete!";
					Status = `Survived until wave {self.Wave}!`;
					WaveObjective = false;
					WaveHazard = false;
				};
				
				shared.Notify(game.Players:GetPlayers(), `Survived until wave {self.Wave}!`, "Positive");
				for _, storage: Storage in pairs(self.Storages) do
					storage:SetPermissions("CanRemove", true);
					storage:Sync(storage.Player);
				end

				self:SpawnCrate();
				shared.Notify(game.Players:GetPlayers(), "A Stake Crate has been discovered!", "Reward");

				workspace:SetAttribute("GameModeComplete", true);
				return;

			else
				--MARK: WaveSelect Continue
				if not self.IsHard then
					for _, player in ipairs(self.Players) do
						local playerWaveSelect = waveSelect.Players[tostring(player.UserId)];
						if playerWaveSelect == nil then continue end;

						local optionIndex = math.clamp(playerWaveSelect.OptionPick, 1, #waveSelect.Options);
						local rewardInfo = waveSelect.Options[optionIndex];
						
						rewardInfo.Votes = (rewardInfo.Votes or 0) +1;
					end
					table.sort(waveSelect.Options, function(a, b) return (a.Votes or 0) > (b.Votes or 0); end);

					self.SelectedOption = waveSelect.Options[1];
					local selectedOption = self.SelectedOption;

					local hazardsCount = 0;
					for a=1, #selectedOption.Hazards do
						hazardsCount += selectedOption.Hazards[a].Amount;
					end
					local nonHazards = 5-hazardsCount;
					if nonHazards > 0 then
						table.insert(selectedOption.Hazards, {
							Type = "None";
							Amount = nonHazards;
						});
					end

					Debugger:StudioLog("WaveSelect Continue. self.SelectedOption=", self.SelectedOption);
				end

			end
		end

		self:BreakTime();
		
		if self.Status == EnumStatus.InProgress then
			Debugger:Log("Wave continue");
			self.Wave = self.Wave +1;
			workspace:SetAttribute("SurvivalWave", self.Wave);
		end
		
	else
		Debugger:Log("discontinue wave..");
		
	end
end

function Survival:RespawnDead()
	for _, player in pairs(self.Players) do
		if player == nil or not player:IsDescendantOf(game.Players) then continue end;
		
		local playerClass: PlayerClass = shared.modPlayers.get(player);
		if playerClass.Character and not playerClass.HealthComp.IsDead then continue end;
		
		playerClass:Spawn();
	end
end

-- MARK: Start
function Survival:Start()
	Debugger:Warn("start game");
	self.SelectedOption = nil;
	
	self.Status = EnumStatus.InProgress;	
	shared.modEventService:ServerInvoke("GameModeManager_BindGameModeStart", {ReplicateTo=self.Players}, {
		Room = self.RoomData;
	});

	self.Wave = 1;
	self.CompletedOnce = false;
	workspace:SetAttribute("SurvivalWave", self.Wave);
	
	self:Hud{
		StatsCount=false;
	};

	for _, player in pairs(self.Players) do
		local playerProfile = shared.modProfile:Get(player);
		if playerProfile then
			local playerSave = playerProfile:GetActiveSave();
			local playerLevel = playerSave and playerSave:GetStat("Level") or 1;
			if playerLevel > self.PeekPlayerLevel then
				self.PeekPlayerLevel = playerLevel;
			end
		end
		
		self.StatsCount[player.Name] = 0;
		modStatusEffects.FullHeal(player);
	end

	Debugger:Warn("Respawn all!");
	self:RespawnDead();
	for a=1, 20, 0.5 do
		self:Hud{
			HeaderText = `{self.ModeType}: {self.ModeStage}`;
			Status = "Waiting for ("..#self.Characters.."/"..#self.Players..") characters.."
		};
		
		if #self.Characters >= #self.Players then
			break;
		else
			task.wait(0.5);
		end
	end
	
	for a=5, 1, -1 do
		self:Hud{
			WaveObjective = false;
			WaveHazard = false;
			Status = "Survival is starting in "..a.."s.."
		};
		task.wait(1);
	end

	if self.Status == EnumStatus.InProgress then
		repeat
			self:StartWave(self.Wave);
			
			Debugger:Log("self.JobsList", self.JobsList, self.Wave, " self.Modifier", self.Modifier);
			for a=#self.JobsList, 1, -1 do
				local job = self.JobsList[a];
				
				if job.Modifier then
					local modifierId = job.Modifier.Id;
					self.Modifier[modifierId] = job.Modifier;
				end
				
				if job.Tick then
					job.Tick(job);
				end
				if self.Wave >= job.EndWave then
					if job.Modifier then
						local modifierId = job.Modifier.Id;
						self.Modifier[modifierId] = nil;
					end
					task.spawn(function()
						job.Task(job);
					end);
					table.remove(self.JobsList, a);
				end
			end
			
			task.wait();
		until self.Status ~= EnumStatus.InProgress;
	end
end

-- MARK: Initialize
function Survival:Initialize(roomData)
	self.RoomData = roomData;
	self.Players = {};
	self.IsHard = roomData.IsHard == true;
	self.Seed = math.random(1111, 9999);
	
	if self.IsHard then
		local hardDecor = game.ServerStorage:FindFirstChild("HardDecor");
		if hardDecor then
			hardDecor.Parent = workspace.Environment;
		end
	end

	local function clearCharacter(character: Model?)
		for a=#self.Characters, 1, -1 do
			local char = self.Characters[a];
			local player = Players:GetPlayerFromCharacter(char);

			if player == nil or char == character then
				table.remove(self.Characters, a);
			end
		end
	end

	for a=1, #self.RoomData.Players do
		local roomPlayerInfo = self.RoomData.Players[a];
		Debugger:Warn("roomPlayerInfo", roomPlayerInfo);
		
		task.delay(0.1, function()
			local player;
			while player == nil do
				player = game.Players:FindFirstChild(roomPlayerInfo.Name);
				if player == nil then
					task.wait(1);
				end
			end
			
			table.insert(self.Players, player);

			local playerClass: PlayerClass = shared.modPlayers.get(player);
			playerClass.OnCharacterSpawn:Connect(function(character: Model)
				Debugger:Warn("OnCharacterSpawn", player, character);
	
				clearCharacter(character);
				table.insert(self.Characters, character);

				playerClass.OnIsDeadChanged:Connect(function(isDead, ov, reason)
					if not isDead then return end
					shared.Notify(game.Players:GetPlayers(), `{character.Name} died!`, "Negative");
		
					clearCharacter(character);
					Debugger:Warn(character.Name, "died", "Players alive", #self.Characters);
		
					if #self.Characters <= 0 and self.Status == EnumStatus.InProgress then
						self.Status = EnumStatus.Restarting;
						Debugger:Warn("Status set restarting..");
						
						for a=#self.EnemyNpcClasses, 1, -1 do
							game.Debris:AddItem(self.EnemyNpcClasses[a].Character, 0);
							table.remove(self.EnemyNpcClasses, a);
						end
						table.clear(self.Modifier);
						
						for a=#self.JobsList, 1, -1 do
							local job = self.JobsList[a];
		
							task.spawn(function()
								job.Task(job);
							end);
						end
						table.clear(self.JobsList);
						
						self:Hud{
							LastWave = self.Wave;
							StatsCount = self.StatsCount;
							SurvivalEnded = true;
						};
						
						for _, storage: Storage in pairs(self.Storages) do
							storage:Wipe();
							storage:Sync(storage.Player);
						end
						shared.Notify(game.Players:GetPlayers(), "Survival failed at wave ".. self.Wave .."!", "Negative");
						
						for a=30, 1, -1 do
							self:Hud{
								Header = "Survival failed!";
								Status = `Restarting in {a}..`;
							};
							
							shared.Notify(game.Players:GetPlayers(), `Restarting in {a}..`, "Negative", "ModeRestarting");
							task.wait(1);
						end
						
						self:Start();
		
					else
						self:Hud{
							Status="You died!";
						};
		
					end
				end)

				if self.IsHard and self.CorruptVision then
					modStatusEffects.CorruptVision(player, true, self.CorruptVision);
				end
			end)

			if playerClass.HealthComp.IsDead then
				playerClass:Spawn();
			end;
		end)
	end
	
	game.Players.PlayerRemoving:Connect(function(player)
		for a=#self.Players, 1, -1 do
			if not self.Players[a]:IsDescendantOf(game.Players) then
				table.remove(self.Players, a);
			end
		end
		clearCharacter();
	end)

	for a=1, 30 do
		local waitMsg = ("Waiting for ("..#self.Players.."/"..#roomData.Players..") players.. ($t)"):gsub("$t", tostring(10-a));
		shared.Notify(game.Players:GetPlayers(), waitMsg, "Inform", "waitForPlayers");

		if #self.Players >= #self.RoomData.Players then
			break;
		else
			task.wait(1);
		end

		if RunService:IsStudio() then
			Debugger:Warn("Waiting for players (",a,")\nPlayers:", self.Players, "\nRoomPlayers:", roomData.Players);
		end
	end
	
	modInteractables:SyncAll();
	
	if self.FirstStart ~= true then
		self.FirstStart = true;

		for a=#self.ObjectivesList, 1, -1 do
			local classObjective = self.ObjectivesList[a].Class;
			local diffModes = classObjective.DifficultyModes or {};
			if self.IsHard and diffModes.Hard == false then
				table.remove(self.ObjectivesList, a);

			elseif self.IsHard == false and diffModes.Easy == false then
				table.remove(self.ObjectivesList, a);

			end
		end
		
		self:Start();
	end
end

function Survival:Schedule(paramPacket)
	paramPacket.EndWave = paramPacket.EndWave + 1;
	
	local job = paramPacket;
	local exist = false;
	
	for a=1, #self.JobsList do
		if self.JobsList[a].Id == job then
			job = self.JobsList[a];
			exist = true;
			break;
		end
	end
	
	if not exist then
		table.insert(self.JobsList, job);
		
	else
		job.EndWave = paramPacket.EndWave;
		
	end
end

function Survival:Hud(data)
	data = data or {};
	
	if data.WaveObjective ~= nil then
		self.WaveObjective = data.WaveObjective;
		self.ObjectiveDesc = data.ObjectiveDesc or "";
	end
	if data.WaveHazard ~= nil then
		self.WaveHazard = data.WaveHazard;
		self.HazardDesc = data.HazardDesc or "";
	end
	if data.HeaderText ~= nil then
		self.HeaderText = data.HeaderText;
	end
	if data.Status ~= nil then
		self.StatusText = data.Status;
	end

	remoteGameModeHud:FireAllClients({
		Action = "Open";
		Type = self.ModeType;
		Stage = self.ModeStage;
		Header = self.HeaderText;
		Status = self.StatusText;
		IsHard = self.IsHard;
		Wave = self.Wave;
		GameState = self.GameState;

		WaveObjective = self.WaveObjective;
		WaveHazard = self.WaveHazard;
		ObjectiveDesc = self.ObjectiveDesc;
		HazardDesc = self.HazardDesc;

		LastWave = data.LastWave;
		StatsCount = data.StatsCount;
		PlayWaveStart = data.PlayWaveStart or false;
		PlayWaveEnd = data.PlayWaveEnd or false;
		SurvivalEnded = data.SurvivalEnded or false;
		SupplyStation = self.ActiveSupCrate or false;
		BossKilled = data.BossKilled or false;
		LootPrefab = self.LootPrefab or false;
		
		HookEntity = data.HookEntity or false;
		WaveSelectPacket = self.WaveSelectPacket.Active == true and self.WaveSelectPacket or false;
	});
end

return Survival;
