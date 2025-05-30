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

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modEventSignal = shared.require(game.ReplicatedStorage.Library.EventSignal);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);
local modItemLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);

local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modNpcs = shared.modNpcs;
local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);


local remoteGameModeHud = modRemotesManager:Get("GameModeHud");

local StageElements = game.ServerStorage:WaitForChild("StageElements");


-- local Objectives = {};
-- local Hazards = {};
local Modifiers = {};
--==
Survival.OnWaveChanged = shared.EventSignal.new("OnWaveChanged");
Survival.Active = nil;

function Survival.new()
	local self = {
		JobsList = {};
		
		Status = EnumStatus.Initialized;
		StageElements = StageElements;
		
		ObjectivesList = nil;
		HazardsList = nil;
		
		ModeType = nil;
		ModeStage = nil;
		SupplyCratePrefabs = {};
		
		CompletedOnce = false;
		RoomData = nil;
		IsHard = false;
		GameState = "";
		
		Players = {};
		Characters = {};
		
		EnemyModules = {};
		EnemiesSpawned = 0;
		
		Wave = 1;
		LastSupplyWave = 10;
		StatsCount = {};
		
		BasicEnemySpawns = {};
		SupplySpawns = {};
		
		PeekPlayerLevel = 100;
		Modifier = {};
		
		--Cmds;
		SetHazard = nil;
		SetObjective = nil;
		SkipWave = false;
	};
	
	if Survival.Active == nil then
		Survival.Active = self;
	end
	self = Survival.Active;
	
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
	
	modOnGameEvents:ConnectEvent("OnZombieDeath", function(npcModule)
		local playerTags = modDamageTag:Get(npcModule.Prefab, "Player");

		for a=1, #playerTags do
			local playerTag = playerTags[a];
			local player = playerTag.Player;

			local playerName = player.Name;
			self.StatsCount[playerName] = (self.StatsCount[playerName] or 0) + 1;
		end
	end);
	
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
					shared.Notify(game.Players:GetPlayers(), "Next wave set to "..wave..".", "Inform");
					
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

		if self.HazardType == "TicksGalore" then
			return "Ticks";
		end

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
	local level = paramPacket.Level or 1;
	
	if self.OnNpcSpawnHooked == nil then
		self.OnNpcSpawnHooked = modNpcs.OnNpcSpawn:Connect(function(npcModule)
			if modConfigurations.TargetableEntities[npcModule.Humanoid.Name] == nil then return end; -- Not enemy spawn;
			
			table.insert(self.EnemyModules, npcModule);
			
			npcModule.Garbage:Tag(function()
				for a=#self.EnemyModules, 1, -1 do
					if self.EnemyModules[a] == npcModule then
						table.remove(self.EnemyModules, a);
						break;
					end
				end
			end)
			
			npcModule:Died(function()
				self.LastKilled = tick();
				for a=#self.EnemyModules, 1, -1 do
					if self.EnemyModules[a] == npcModule then
						table.remove(self.EnemyModules, a);
						break;
					end
				end

				npcModule.DeathPosition = npcModule.RootPart.CFrame.p;

				self.LastEnemyDeathPos = npcModule.DeathPosition;
			end);
		end)
	end
	
	local hardMode = paramPacket.HardChance and math.random(0, 1000)/1000 <= paramPacket.HardChance or false;
	if paramPacket.HardChance then
		Debugger:StudioWarn("Hardmode chance:",paramPacket.HardChance);
	end

	local currWave = self.Wave;
	local newNpcModule;
	local npcPrefab = modNpcs.spawn(npcName, spawnCf, function(npcPrefab, npcModule)
		task.spawn(function()
			while currWave == self.Wave do
				task.wait(1);
			end
			if npcModule.IsDead then return end;
			npcModule:Destroy();
		end)
		self.EnemiesSpawned = self.EnemiesSpawned + 1;
		newNpcModule = npcModule;
		
		npcModule.SetAggression = 3;
		
		if hardMode then
			--npcModule.HardMode = true;
		end
		
		npcModule.NetworkOwners = game.Players:GetPlayers();
		local levelRng = npcModule.Properties and npcModule.Properties.BasicEnemy == true and math.random(-2, 0) or 0;
		npcModule.Configuration.Level = math.max(npcModule.Configuration.Level + level + levelRng, 1);
		npcModule.ForgetEnemies = false;
		npcModule.AutoSearch = true;
		npcModule.Properties.TargetableDistance = 4096;
		
		if npcName == "Pathoroth" then
			local newHealth = 4000 * math.max(math.ceil(level/2), 1);
			npcModule.Humanoid.MaxHealth = math.clamp(newHealth, 1000, math.huge);
			npcModule.Humanoid.Health = npcModule.Humanoid.MaxHealth;
		end
		
		npcModule.OnTarget(self.Players);

		if self.OnEnemySpawn then
			self:OnEnemySpawn(npcPrefab, npcModule);
		end
	end);
	
	return npcPrefab, newNpcModule;
end

function Survival:CompleteWave()
	self:RespawnDead();
	task.wait(1);
	
	--local wavesLapsedSinceSupply = self.LastSupplyWave-self.Wave; --(math.random(1, 10) == 1 and wavesLapsedSinceSupply > 4) or wavesLapsedSinceSupply >= 15
	if self.Wave == 1 or self.ResupplyEnabled then
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

	self:Hud{
		PlayWaveEnd=true;
	};
end

function Survival:GetNextWaveInfo(wave)
	local random = Random.new(self.Seed);
	local pickObjective, pickHazard;

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
		self.SetHazard = nil;
	end
	
	if self.SetObjective then
		pickObjective = self.SetObjective;
		self.SetObjective = nil;
	end

	return pickObjective, pickHazard;
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

		if modBranchConfigs.CurrentBranch.Name == "Dev" then
			-- Dev branch
			local function printChatCalculator(title, list)
				shared.Notify(game.Players:GetPlayers(), "Dev-branch Info: ".. title .." Table:", "Inform");
				
				for a=1, #list do
					local name = list[a].Type;
					local fmod = (list[a].Fmod or 1);
					local startWave = (list[a].StartWave or 1);
					shared.Notify(game.Players:GetPlayers(), a..": "..name..": Every "..fmod.." wave"..(startWave > 1 and " after ".. startWave.." waves" or ""), "Inform");
				end
				
				shared.Notify(game.Players:GetPlayers(), "- - - - - - - - - - - - -", "Inform");
			end

			printChatCalculator("Objectives", self.ObjectivesList);
			printChatCalculator("Hazards", self.HazardsList);
		end
		
		if self.OnStart then
			self.OnStart(self.Players);
		end
	end

	--===
	self.EnemiesSpawned = 0;
	local pickObjective, pickHazard;
	
	pickObjective, pickHazard = self:GetNextWaveInfo(wave);
	--===
	
	local newObjective = pickObjective.Class.new();
	local newHazard = pickHazard and pickHazard.Class.new() or nil;
	
	local hazardTitle = (newHazard and newHazard.Title or "None");
	shared.Notify(game.Players:GetPlayers(), "Wave ".. self.Wave ..", Objective: ".. newObjective.Title ..", Hazard: ".. hazardTitle, "Defeated");

	self:Hud{
		WaveObjective=newObjective.Title;
		WaveHazard=hazardTitle;
	}
	
	self.ObjectiveType = pickObjective.Type;
	self.HazardType = pickHazard and pickHazard.Type or nil;
	
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
	Debugger:Log("Wave fin");
	
	for a=#self.EnemyModules, 1, -1 do
		game.Debris:AddItem(self.EnemyModules[a].Prefab, 0);
		self.EnemyModules[a]:Destroy();
		table.remove(self.EnemyModules, a);
	end
	
	
	self:Hud{
		WaveObjective=false;
		WaveHazard=false;
	}
	
	if self.Status == EnumStatus.InProgress then
		self:CompleteWave();
		
		if self.IsHard and self.StageLib.HardRewardId then

			local rewardLib = modRewardsLibrary:Find(self.StageLib.HardRewardId);
			if rewardLib and rewardLib.Rewards then
				local rewardsList = rewardLib.Rewards;
				local selectRewardInfo;
				for a=1, #rewardsList do
					local rewardInfo = rewardsList[a];

					if rewardInfo.Wave == self.Wave then
						selectRewardInfo = rewardInfo;
						break;
					end
				end

				if selectRewardInfo then
					local pickRewardId = selectRewardInfo.ItemId;
					
					local itemLib = modItemLibrary:Find(pickRewardId);
					local dropStr = `A {itemLib.Name} has dropped!`;
		
					local spawnCFrame = workspace:FindFirstChildWhichIsA("SpawnLocation");
					if spawnCFrame then
						spawnCFrame = spawnCFrame.CFrame * CFrame.new(0, 2, 0);
					end

					local lootPrefab = modItemDrops.Spawn({Type="Custom"; ItemId=pickRewardId; Quantity=1;}, spawnCFrame, self.Players, false);
					lootPrefab.PrimaryPart.Anchored = true;
					self.LootPrefab = lootPrefab;

					self:Hud{
						Status=dropStr;
					};

					Debugger:Warn("Reward Drop self.Wave", self.Wave, "pickRewardId", pickRewardId);
				end

			end

		elseif self.Wave >= 5 and math.fmod(self.Wave-2, 3) == 0 then
			local rewardDropsList = {self.StageLib.RewardsId};
			
			local spawnCFrame = workspace:FindFirstChildWhichIsA("SpawnLocation");
			if spawnCFrame then
				spawnCFrame = spawnCFrame.CFrame * CFrame.new(0, 2, 0);
			end
			if #self.Characters > 0 then
				local pickChar = self.Characters[math.random(1, #self.Characters)];
				if pickChar and pickChar:IsDescendantOf(workspace) then
					spawnCFrame = pickChar:GetPivot();
				end
			end
			
			if self.StageLib.RewardsIds then
				for a=1, #self.StageLib.RewardsIds do
					if table.find(rewardDropsList, self.StageLib.RewardsIds[a]) == nil then
						table.insert(rewardDropsList, self.StageLib.RewardsIds[a]);
					end
				end
			end
			
			self.DropCycleIndex = (self.DropCycleIndex or -1) +1;
			local pickRewardId = rewardDropsList[math.fmod(self.DropCycleIndex, #rewardDropsList)+1];
			
			local bonusQuantity = math.floor(self.Wave/9);
			local quantity = math.clamp(1 + bonusQuantity, 1, 5);

			local lootPrefab = modItemDrops.Spawn({Type="Tool"; ItemId=pickRewardId; Quantity=quantity;}, spawnCFrame, self.Players, false);
			self.LootPrefab = lootPrefab;
			
			local dropStr = "A reward package has dropped!";
			
			local itemLib = modItemLibrary:Find(pickRewardId);
			if quantity > 1 then
				dropStr = `{quantity} x {itemLib and itemLib.Name or "reward package"} has dropped!`;
			else
				dropStr = `A {itemLib and itemLib.Name or "reward package"} has dropped!`;
			end

			self:Hud{
				Status=dropStr;
			};
			shared.Notify(game.Players:GetPlayers(), dropStr, "Reward");

		end
		
		local breakLength = math.clamp(10 + (self.ActiveSupCrate and 20 or 0), 10, 30);

		self.GameState = "Intermission";

		local nextWave = wave+1;
		local nextObj, nextHaz = self:GetNextWaveInfo(nextWave);
		local nextWaveStr = (nextObj and nextObj.Class.Title or "")..(nextHaz and " ("..nextHaz.Class.Title..")" or " (No Hazards)");
		for a=breakLength, 1, -1 do
			if a == 1 then self:RespawnDead(); end
			task.wait(1);
			self:Hud{
				Status=`Wave {nextWave}: {nextWaveStr} starts in {a}s..`;
			};
			if self.Status ~= EnumStatus.InProgress then break; end
		end

		if self.ActiveSupCrate then
			game.Debris:AddItem(self.ActiveSupCrate, 0);
			self.ActiveSupCrate = nil;
		end;
		
		if self.LootPrefab then
			self.LootPrefab = nil;
		end
		
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
		
		local classPlayer = shared.modPlayers.get(player);
		if classPlayer.IsAlive then continue end;
		
		classPlayer:Spawn();
	end
end

-- MARK: Start
function Survival:Start()
	Debugger:Warn("start game");
	self.Status = EnumStatus.InProgress;
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
			Status="Waiting for ("..#self.Characters.."/"..#self.Players..") characters.."
		};
		
		if #self.Characters >= #self.Players then
			break;
		else
			task.wait(0.5);
		end
	end
	
	for a=5, 1, -1 do
		self:Hud{
			Status="Survival is starting in "..a.."s.."
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

			local classPlayer = shared.modPlayers.get(player);
			classPlayer.OnCharacterSpawn:Connect(function(character: Model)
				Debugger:Warn("OnCharacterSpawn", player, character);
	
				clearCharacter(character);
				table.insert(self.Characters, character);

				classPlayer:OnNotIsAlive(function(character)
					shared.Notify(game.Players:GetPlayers(), character.Name .. " died!", "Negative");
		
					clearCharacter(character);
					Debugger:Warn(character.Name,"died", "Players alive",#self.Characters);
		
					if #self.Characters <= 0 and self.Status == EnumStatus.InProgress then
						self.Status = EnumStatus.Restarting;
						Debugger:Warn("Status set restarting..");
						
						for a=#self.EnemyModules, 1, -1 do
							game.Debris:AddItem(self.EnemyModules[a].Prefab, 0);
							table.remove(self.EnemyModules, a);
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
							LastWave=self.Wave;
							StatsCount=self.StatsCount;
						};
						
						shared.Notify(game.Players:GetPlayers(), "Survival failed at wave ".. self.Wave .."!", "Negative");
						
						for a=30, 1, -1 do
							self:Hud{
								Header="Survival failed!";
								Status="Restarting in "..a.."..";
								SurvivalFailed=a==30;
							};
							
							shared.Notify(game.Players:GetPlayers(), "Restarting in "..a.."..", "Negative", "ModeRestarting");
							task.wait(1);
						end
						
						self:Start();
		
					else
						self:Hud{
							Header="You died!";
							Status="";
						};
		
					end
				end)

				if self.IsHard and self.CorruptVision then
					modStatusEffects.CorruptVision(player, true, self.CorruptVision);
				end
			end)

			if not classPlayer.IsAlive then 
				classPlayer:Spawn();
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
	
	if self.HudValues == nil then
		self.HudValues = {};
	end
	
	if data.WaveObjective ~= nil then
		self.HudValues.WaveObjective = data.WaveObjective;
	end
	if data.WaveHazard ~= nil then
		self.HudValues.WaveHazard = data.WaveHazard;
	end
	
	remoteGameModeHud:FireAllClients({
		Action="Open";
		Type=self.ModeType;
		Stage=self.ModeStage;
		Header=data.Header or modBranchConfigs.GetWorldDisplayName(self.StageLib.WorldId);
		Status=data.Status or "";
		IsHard=self.IsHard;
		Wave=self.Wave;
		GameState=self.GameState;

		WaveObjective=data.WaveObjective or self.HudValues.WaveObjective;
		WaveHazard=data.WaveHazard or self.HudValues.WaveHazard;

		LastWave=data.LastWave;
		StatsCount=data.StatsCount;
		PlayWaveStart=data.PlayWaveStart or false;
		PlayWaveEnd=data.PlayWaveEnd or false;
		SurvivalFailed=data.SurvivalFailed or false;
		BossList=data.BossList or false;
		SupplyStation=self.ActiveSupCrate or false;
		BossKilled=data.BossKilled or false;
		LootPrefab=self.LootPrefab or false;
		
		HookEntity=data.HookEntity or false;
	});
end

return Survival;
