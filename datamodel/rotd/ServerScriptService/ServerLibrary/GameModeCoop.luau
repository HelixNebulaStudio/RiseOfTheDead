local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService: RunService = game:GetService("RunService");
local PathfindingService = game:GetService("PathfindingService");
local CollectionService = game:GetService("CollectionService");

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDoors = shared.require(game.ReplicatedStorage.Library.Doors);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modTeamsManager = shared.require(game.ReplicatedStorage.Library.TeamsManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modCutscene = shared.require(game.ReplicatedStorage.Library.Cutscene);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);
local modOctree = shared.require(game.ReplicatedStorage.Library.Util.Octree);

local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

local Config = {
	SpawnRadius = 256;
	HordeTimerEnabled = true;

    EnemyCap = 20;
    SpawnPlatformRadius = 64;

    MinSpawnCount = 2;
    MaxSpawnCount = 4;
};

local Coop = {
    Active = nil;
};
Coop.__index = Coop;

local EnumStatus = {Initialized=-1; Restarting=0; InProgress=1; Completed=2;};
Coop.EnumStatus = EnumStatus;

local platformParam = OverlapParams.new();
platformParam.FilterType = Enum.RaycastFilterType.Include;

local spawnCounter = 0;
--==

function Coop.onRequire()
    modNpcs = shared.modNpcs;

	serverPrefabs = game.ServerStorage:WaitForChild("Prefabs"):WaitForChild("Objects");
    remoteGameModeHud = modRemotesManager:Get("GameModeHud");

	gameObjects = workspace.Environment:WaitForChild("Game");

	shared.modCommandsLibrary.bind{
		["coop"]={
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
			Description = [[Coop commands.
			
			/coop resetinteractables
			]];

			RequiredArgs = 0;
			UsageInfo = "/coop";
			Function = function(speaker, args)
				local action = args[1];

				local gameController = shared.GameController;
				if gameController == nil then
					Debugger:Warn(`GameController not found.`);
					return;
				end

				if action == "resetinteractables" then
					for _, interactable: InteractableInstance in pairs(gameController.Interactables) do
						interactable:Reset();
					end
				end
			end
		};
	};
end

--MARK: new()
function Coop.new()
	local self = {
		Index = 1;
		Status = EnumStatus.Initialized;

		SpawnPlatforms = ({} :: {[Part] : {
            Name: string; 
            Part: Part; 
            Index: number; 
            Spawns: {}; 
            Enabled: boolean;
        }});
		AmbientSpawns = modOctree.new();

        Players = {};
        AlivePlayers = ({} :: {PlayerClass});
        
        Doors = {};
        ExtractDoors = {};

		Interactables = {};

		HordeEnemyClasses = {};
		AmbientEnemyClasses = {};

        ModeType = nil;
        ModeStage = nil;
        GameLib = nil;
        StageLib = nil;
        RoomData = nil;

        StopwatchTick = nil;

		Wave = 1;
        Difficulty = 1;
		EnemiesSpawned = 0;
        EliminateCount = 0;

		HordeTimer = tick()+300;

		OnPlayersLocationChanged = shared.EventSignal.new("OnPlayersLocationChanged");
	};

	if Coop.Active == nil then
		Coop.Active = self;
	end
	
	setmetatable(self, Coop);
	return self;
end

function Coop:Load()
    self.GameLib = modGameModeLibrary.GetGameMode(self.ModeType);
	self.StageLib = self.GameLib and modGameModeLibrary.GetStage(self.ModeType, self.ModeStage);

    local gameDir: Folder = workspace.Environment:FindFirstChild("Game");
    self.GameDir = gameDir

    if gameDir then
		for _, object: Instance in pairs(gameDir:GetChildren()) do
			if object.Name == "SpawnPlatforms" then
				object.Parent = workspace.CurrentCamera;
				
                local spCount = 0;
				for _, child in pairs(object:GetChildren()) do

					if child:IsA("Folder") then
						for _, plat in pairs(child:GetChildren()) do
							spCount = spCount +1;
							self.SpawnPlatforms[plat] = {
								Name = "SpawnPlatform"..spCount;
								Part = plat;
								Index = (plat:GetAttribute("Index") or 999);
								SpawnCFrames = {};

								PlatformGroup = child.Name;
								Enabled = false;
							};
						end

					else
						spCount = spCount +1;
						self.SpawnPlatforms[child] = {
							Name = "SpawnPlatform"..spCount;
							Part = child;
							Index = (child:GetAttribute("Index") or 999);
							SpawnCFrames = {};
							Enabled = true;
						};

					end

				end

			elseif object.Name == "Doors" then
				for _, child in pairs(object:GetChildren()) do
					
					if child:FindFirstChild("Door") and child.Door:IsA("Configuration") then
						local doorInstance: DoorInstance = modDoors.getOrNew(child.Door);
						table.insert(self.Doors, doorInstance);

					elseif child.Name == "ExtractDoor" then
						table.insert(self.ExtractDoors, child);
						
						local newInteractable = modInteractables.createInteractable("GameModeExit");
						newInteractable:SetAttribute("Mode", self.ModeType);
						newInteractable:SetAttribute("Stage", self.ModeStage);
						newInteractable:SetAttribute("Label", "Extract");
						newInteractable.Parent = child;

					elseif child:FindFirstChild("Destructible") and child.Destructible:IsA("Configuration") then
						child.Parent = script;
						table.insert(self.Blockades, child);

					end
				end

            end
        end

    end

	for _, config in pairs(CollectionService:GetTagged("Interactable")) do
		local interactable: InteractableInstance = modInteractables.getOrNew(config);
		table.insert(self.Interactables, interactable);
	end

	self.Loaded = true;
end

--MARK: Initialize
function Coop:Initialize(roomData)
	repeat task.wait() until self.Loaded == true;
	
	modConfigurations.Set("InfTargeting", false);
	modConfigurations.Set("NpcThinkCycle", 1);
	
	Debugger:StudioLog(`Initialize gameController`, self);
	self.RoomData = roomData;
	self.Players = {};

	local function clearAlive(playerClass: PlayerClass?)
		for a=#self.AlivePlayers, 1, -1 do
            local alivePlayerClass: PlayerClass = self.AlivePlayers[a];

            if not game.Players:IsAncestorOf(alivePlayerClass:GetInstance())
            or (playerClass and alivePlayerClass == playerClass) then
                table.remove(self.AlivePlayers, a);
            end
		end
	end

	local raidTeam: TeamClass = modTeamsManager.newTeam(nil, "RaidTeam");
	raidTeam.Type = "Game";

	local wlInstances = {};
    shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
		local playerName = player.Name;

		local isInLobby = false;
		for a=1, #self.RoomData.Players do
			if self.RoomData.Players[a].Name == playerName then
				isInLobby = true;
				break;
			end
		end
		if not isInLobby then return end;
		

		raidTeam:SetMember(playerName, true);
		table.insert(self.Players, player);

		local playerClass: PlayerClass = shared.modPlayers.get(player);
		playerClass.Properties.ActiveTeamType = raidTeam.Type;
		raidTeam:Sync();

		local activeLoop = true;
		playerClass.OnCharacterSpawn:Connect(function(character: Model)
			Debugger:Warn("OnCharacterSpawn", player, character);

			clearAlive(playerClass);
			table.insert(self.AlivePlayers, playerClass);

			local rootPart = playerClass.RootPart;
        
			task.spawn(function()
				while activeLoop do
					local rootPart = playerClass.RootPart;
					if rootPart == nil then
						task.wait(1);
						continue;
					end
					
					local ambientSpawns = self.AmbientSpawns:RadiusSearch(rootPart.Position, 160);

					for a=1, #ambientSpawns do
						local spawnPart = ambientSpawns[a];
						spawnPart:SetAttribute("ScanTick", tick());

						task.spawn(function()
							local spawnId = spawnPart:GetAttribute("SpawnId");
							if spawnId == nil then
								spawnCounter = spawnCounter+1;
								spawnId = tostring(spawnCounter);

								spawnPart:SetAttribute("SpawnId", spawnId);
							end

							--MARK: Spawn ambient 
							if self.AmbientEnemyClasses[spawnId] == nil then
								local spawnCf = (spawnPart.CFrame + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, math.rad(math.random(1, 360)), 0);
								
								local npcName = self:PickEnemy();
								if spawnPart:GetAttribute("EntityName") then
									npcName = spawnPart:GetAttribute("EntityName");
								end

								local npcClass: NpcClass = self:SpawnEnemy(npcName, {
									SpawnCFrame = spawnCf;
									SpawnId = spawnId;
								});

								self.AmbientEnemyClasses[spawnId] = npcClass;
								npcClass.Character:SetAttribute("SpawnId", spawnId);

								npcClass.HealthComp.OnIsDeadChanged:Connect(function()
									if not npcClass.HealthComp.IsDead then return end;
									self.AmbientEnemyClasses[spawnId] = false;
								end)
							end
						end)
					end

					for spawnId, npcClass in pairs(self.AmbientEnemyClasses) do
						if typeof(npcClass) ~= "table" then continue end;
						if npcClass.HealthComp.IsDead then
							self.AmbientEnemyClasses[spawnId] = false;
							continue;
						end

						local closestPlayerDist = math.huge;
						for a=1, #self.AlivePlayers do
							local alivePlayerClass: PlayerClass = self.AlivePlayers[a];

							local dist = npcClass:DistanceFromCharacter(alivePlayerClass:GetCFrame().Position);
							if dist < closestPlayerDist then
								closestPlayerDist = dist;
							end
						end
						if closestPlayerDist <= 200 then continue end;
						-- despawn far away zombies;

						npcClass:Destroy();
						task.spawn(function()
							task.wait(1);
							self.AmbientEnemyClasses[spawnId] = nil;
						end)
					end

					task.wait(1);
				end
			end)
        end)

		playerClass.OnIsDeadChanged:Connect(function(isDead: boolean)
			if not isDead then return end;
			activeLoop = false;
			
			shared.Notify(game.Players:GetPlayers(), `{playerName} died!`, "Negative");

			clearAlive(playerClass);
			Debugger:Warn(playerName,"died", "Players alive", #self.AlivePlayers);

			if #self.AlivePlayers <= 0 and self.Status == EnumStatus.InProgress then
				self.Status = EnumStatus.Restarting;
				
				self:Restart();

			else
				self:Hud{
					Header="You died!";
					Status="";
				};
			end
		end)

		player:GetAttributeChangedSignal("Location"):Connect(function()
			local data = {
				Players = {};
				PlayersCount = 0;
			};
			for a=#self.Players, 1, -1 do
				local player = self.Players[a];
				
				data.Players[player] = player:GetAttribute("Location");
				data.PlayersCount = data.PlayersCount +1;
			end

			self.OnPlayersLocationChanged:Fire(data);
		end)
    end)


	game.Players.PlayerRemoving:Connect(function(player)
		for a=#self.Players, 1, -1 do
			if not self.Players[a]:IsDescendantOf(game.Players) then
				table.remove(self.Players, a);
			end
		end
		clearAlive();
	end)

	while #self.Players <= 0 do
		task.wait();
	end

	for a=1, 10 do
		local waitMsg = `Waiting for ({#self.Players}/{#roomData.Players}) players.. ({10-a})`;
		shared.Notify(game.Players:GetPlayers(), waitMsg, "Inform", "waitForPlayers");

		self:RespawnDead();

		if #self.Players >= #self.RoomData.Players then
			break;
		else
			task.wait(1);
		end
	end

	self:Start();

	local hordeSpawns = gameObjects.HordeSpawns:GetChildren();
	task.spawn(function()
		self.HordeTimer = tick()+300;
		while true do
			repeat
				wait(1);
			until tick() >= self.HordeTimer;
			if Config.HordeTimerEnabled ~= true then
				self.HordeTimer = tick()+60;
				continue;
			end
			
			local totalPos;
			local playersCount = 0;
			for _, player in pairs(game.Players:GetPlayers()) do
				if player and player.Character and player.Character.PrimaryPart then
					if totalPos == nil then
						totalPos = player.Character.PrimaryPart.Position;
					else
						totalPos = totalPos + player.Character.PrimaryPart.Position;
					end
					playersCount = playersCount+1;
				end
			end
			
			local avgPos = (totalPos or Vector3.zero)/playersCount;
			
			local tLapsed = math.ceil(workspace:GetServerTimeNow()-self.StartTime);
			
			local hordeAmt = math.random(math.clamp(tLapsed, 10, 40), math.clamp(tLapsed, 11, 70));
			if not self.IsHard then
				hordeAmt = math.ceil(hordeAmt * 0.5);
			end
			Debugger:Log("Spawning horde of ",hordeAmt);
			
			local removedHorde = 0;
			for _, npcClass: NpcClass in pairs(self.HordeEnemyClasses) do
				if npcClass:DistanceFromCharacter(avgPos) <= (Config.SpawnRadius+100) then continue end;

				npcClass:Destroy();
				removedHorde = removedHorde +1;
				if removedHorde >= hordeAmt then
					break;
				end
			end
			

			for a=1, hordeAmt do
				local spawnPart;
				
				repeat
					local pickSpawn = hordeSpawns[math.random(1,#hordeSpawns)];
					local path = PathfindingService:FindPathAsync(pickSpawn.CFrame.p, avgPos);
					if path.Status == Enum.PathStatus.Success then
						spawnPart = pickSpawn;
					end
				until spawnPart;
				
				local spawnCf = (spawnPart.CFrame + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, math.rad(math.random(1, 360)), 0);
				
				--MARK: Spawn horde
				local npcClass: NpcClass = self:SpawnEnemy("Zombie", {
					SpawnCFrame = spawnCf;
				});
				if npcClass then
					npcClass.Properties.HordeAggression = true;

					table.insert(self.HordeEnemyClasses, npcClass);
					npcClass.HealthComp.OnIsDeadChanged:Connect(function()
						if not npcClass.HealthComp.IsDead then return end;
						
						for a=#self.HordeEnemyClasses, 1, -1 do
							if self.HordeEnemyClasses[a] == npcClass then
								table.remove(self.HordeEnemyClasses, a);
								break;
							end
						end
					end)
					
					local targetHandlerComp = npcClass:GetComponent("TargetHandler");
					if targetHandlerComp then
						for _, player in pairs(self.Players) do
							targetHandlerComp:AddTarget(player.Character);
						end
					end
				end
				
				if self.IsHard then
					task.wait(0.5);
					if #self.HordeEnemyClasses >= 80 then break; end;
				else
					task.wait(3);
					if #self.HordeEnemyClasses >= 40 then break; end;
				end
			end

			if self.IsHard then
				self.HordeTimer = tick()+ math.random(90, 180);
			else
				self.HordeTimer = tick()+ math.random(120, 240);
			end
		end
		
	end)
end

--MARK: PickEnemy
function Coop:PickEnemy(paramPacket)
	if self.CurrentWaveEnemyPool == nil or self.CurrentWaveEnemyPool.Wave ~= self.Wave then
		local validList = {};

		for a=1, #self.EnemiesList do
			local enemyOption = self.EnemiesList[a];
			local fmod = enemyOption.Fmod or 1;
			local startWave = enemyOption.StartWave or 1;

			local spawnConditionFunc = enemyOption.CanSpawnFunc;
			local isSpawnable = false;

			if (math.fmod(self.EnemiesSpawned, fmod) == 0 and self.Wave >= startWave) then
				isSpawnable = true;
			end
			
			if spawnConditionFunc then
				isSpawnable = spawnConditionFunc(self, enemyOption, paramPacket);
			end
			
			if isSpawnable == true then
				table.insert(validList, enemyOption);
			end
		end

		if #validList <= 0 then
			Debugger:Warn(`No valid enemies to pick from to spawn.`);
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

		if #pickTable <= 0 then
			Debugger:Warn(`No valid pickTable to pick from to spawn.`);
		end

		for a=1, #pickTable do
			if roll <= pickTable[a].Total then
				return pickTable[a].Data.Name;
			end
		end
	end

    return self.EnemiesList[1].Name;
end

--MARK: SpawnEnemy
function Coop:SpawnEnemy(npcName, paramPacket)
	paramPacket = paramPacket or {};

	local spawnCf = paramPacket.SpawnCFrame;

	return modNpcs.spawn2{
		Name = npcName;
		CFrame = spawnCf;

		BindSetup = function(npcClass: NpcClass)
			self.EnemiesSpawned = self.EnemiesSpawned + 1;

			local properties = npcClass.Properties;
			properties.TargetableDistance = 4096;
			properties.CanForgetTargets = false;
			properties.IsHostile = true;

			properties.Level = properties.Level + self.Difficulty + math.random(-1,1);

			npcClass.HealthComp.OnIsDeadChanged:Connect(function()
				if not npcClass.HealthComp.IsDead then return end;
			end)
		end
	};
end

--MARK: BeginCoop
function Coop:BeginCoop()
	if self.Status ~= EnumStatus.InProgress then return end;
	
	if self.StageLib.EnableStopwatch == true then
		if self.StopwatchTick == nil then
			self.StopwatchTick = workspace:GetServerTimeNow();
		end
	end

	self:Hud({});
end

--MARK: CompleteCoop
function Coop:CompleteCoop()
	workspace:SetAttribute("GameModeComplete", true);

	local runTimeStr = "";
	if self.StopwatchTick then
		local timeLapse = workspace:GetServerTimeNow()-self.StopwatchTick;
		self.StopwatchFinal = timeLapse;

		runTimeStr = ` Run time: {modSyncTime.FormatMs(timeLapse *1000)}!`;
	end

	self.Status = EnumStatus.Completed;
	shared.Notify(game.Players:GetPlayers(), `Coop Complete!{runTimeStr}`, "Positive");
	self:Hud{
		Status="Coop Complete!";
		PlayMusic=false;
	};

	self:RespawnDead();
	task.wait(1);

	self:DropReward();
	
	if self.OnComplete then
		self.OnComplete(self.Players);
	end
end

--MARK: DropReward
function Coop:DropReward()
	local spawnLocPart = workspace:FindFirstChildWhichIsA("SpawnLocation");

	local playersCenterPos = nil;
	for a=1, #self.AlivePlayers do
		local cf = self.AlivePlayers[a]:GetCFrame();
		if playersCenterPos == nil then
			playersCenterPos = cf.Position;
		else
			playersCenterPos = playersCenterPos + cf.Position;
		end
	end
	playersCenterPos = playersCenterPos / #self.AlivePlayers;


	local closestExtractDoorModel = nil;
	local cloestExtractDoorDist = math.huge;
	
	for a=1, #self.ExtractDoors do
		local prefab = self.ExtractDoors[a];
					
		local dist = (prefab:GetPivot().Position - playersCenterPos).Magnitude;
		
		if dist < cloestExtractDoorDist then
			closestExtractDoorModel = prefab;
			cloestExtractDoorDist = dist;
		end
	end
	
	local spawnCf = spawnLocPart.CFrame + Vector3.new(0, 2, 0);

	local rewardSpawnPart = workspace.Environment.Game:FindFirstChild("RewardSpawn");
	if rewardSpawnPart then
		spawnCf = rewardSpawnPart.CFrame;

	elseif closestExtractDoorModel then
		spawnCf = closestExtractDoorModel.PrimaryPart.LootSpawn.WorldCFrame;

	end
	

	local rewardDropsList = {self.StageLib.RewardsId;};
	if self.IsHard then
		rewardDropsList = {self.StageLib.HardRewardId;};
	end
	
	self.LootPrefab = modItemDrops.Spawn({
		Type = "Tool"; 
		ItemId = rewardDropsList[math.random(1, #rewardDropsList)]
	}, spawnCf, self.Players, false);

	self:Hud{
		Status="A reward package has dropped!";
	};
end

--MARK: Start
function Coop:Start()
	self.StopwatchTick = nil;
	Debugger:Warn("Coop:Start");

	self:Hud({Action="Open"});

	-- Difficulty
	local highestLevel = 0;
	for _, player in pairs(self.Players) do
		local playerProfile = shared.modProfile:Get(player);
		if playerProfile == nil then continue end;
		
		local playerSave = playerProfile:GetActiveSave();
		local playerLevel = playerSave and playerSave:GetStat("Level") or 1;
		local focusLevel = modGlobalVars.GetLevelToFocus(playerLevel);
		if focusLevel > highestLevel then
			highestLevel = focusLevel;
		end
		
		modStatusEffects.FullHeal(player);
	end
	if self.OnStart then
		self.OnStart(self.Players);
	end

	self.Difficulty = math.clamp(highestLevel, 1, math.huge);
	Debugger:Warn("Difficulty", self.Difficulty);


    --MARK: Doors
	local destructibleObjs = {};
	
	for a=1, #self.Doors do
		local doorInstance: DoorInstance = self.Doors[a];
		local doorModel = doorInstance.Model;
		
		doorInstance:Toggle(false);

        if doorModel:GetAttribute("ShouldBarricade") == false then continue end;
		
		local blockadeId = "BlockadeSingle";
		if doorInstance.WidthType == "Double" then
			blockadeId = "BlockadeDouble";
		end
		
		for _, obj in pairs(doorModel:GetChildren()) do
			if obj.Name == "Blockade" then
				game.Debris:AddItem(obj, 0);
			end
		end
		

		local blockadeFolder = serverPrefabs:FindFirstChild("DefaultBlockades");
		if blockadeFolder and doorModel:GetAttribute("ShouldBarricade") ~= false then
			local new = blockadeFolder[blockadeId]:Clone();
			new.Name = "Blockade";
			new:PivotTo(doorModel:GetPivot());
			new.Parent = doorModel;
			
			local destructibleConfiguration: Configuration = new:WaitForChild("Destructible");
			local destructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfiguration);

			destructible.OnDestroy:Connect(function()
				local platformName = doorModel:GetAttribute("AddSpawnPlatforms");
				if platformName == nil then return end;
				
				for platformPart, platformInfo in pairs(self.SpawnPlatforms) do
					if platformInfo.PlatformGroup == platformName then
						platformInfo.Enabled = true;
					end
				end
			end)
			
			destructible:SetEnabled(false);
			table.insert(destructibleObjs, destructible);
		end
	end

    --MARK: LoadSpawns
	local function loadSpawn(obj: BasePart)
		obj.Transparency = 1;
		obj.Position = obj.Position - Vector3.new(0, obj.Size.Y/2, 0);
		obj.Size = Vector3.new(0,0,0);
		obj.CollisionGroup = "IgnoreRaycast";
	end

	for _, obj in pairs(gameObjects.AmbientSpawns:GetChildren()) do
		loadSpawn(obj);
	
		self.AmbientSpawns:CreateNode(obj.Position, obj);
	end
	for _, obj in pairs(gameObjects.HordeSpawns:GetChildren()) do
		loadSpawn(obj);
	end
	for _, obj in pairs(gameObjects.BossSpawns:GetChildren()) do
		loadSpawn(obj);
	end
    
	for a=5, 1, -1 do
		self:Hud({
			Status = `{self.ModeStage} is starting in {a}s..`;
		});
		task.wait(1);
	end
	
	for a=1, #destructibleObjs do
		local destructible: DestructibleInstance = destructibleObjs[a];
		local maxHealth = self.Difficulty *100;

		destructible.HealthComp:SetMaxHealth(maxHealth);
		destructible.HealthComp:SetHealth(maxHealth);
		destructible:SetEnabled(true);
	end

	self.Status = EnumStatus.InProgress;
	self.StartTime = workspace:GetServerTimeNow();

	self.ObjectiveStatusText = ``;
	self:Hud({
		Status=self.ObjectiveStatusText;
	})	
	
	if self.Soundtrack then
		self.Soundtrack:Destroy();
	end	
	self.Soundtrack = modAudio.Play(self.StageLib.Soundtrack, workspace);
	modCutscene:PlayCutscene(game.Players:GetPlayers(), self.ModeStage);
end

--MARK: RespawnDead
function Coop:RespawnDead()
	for _, player in pairs(self.Players) do
		if player == nil or not player:IsDescendantOf(game.Players) then continue end;
		
		local playerClass: PlayerClass = shared.modPlayers.get(player);
		if player.Character == nil or playerClass.HealthComp.IsDead then
			playerClass:Spawn();
		end;
	end
end

--MARK: Restart
function Coop:Restart()
	self.Index = self.Index +1;
	
	for a=#self.EnemyClassInstances, 1, -1 do
		game.Debris:AddItem(self.EnemyClassInstances[a].Character, 0);
		table.remove(self.EnemyClassInstances, a);
	end
	for a=#self.HordeEnemyClasses, 1, -1 do
		game.Debris:AddItem(self.HordeEnemyClasses[a].Character, 0);
		table.remove(self.HordeEnemyClasses, a);
	end
	for spawnId, npcClass in pairs(self.AmbientEnemyClasses) do
		if typeof(npcClass) == "table" then 
			npcClass:Destroy();
		end;
		self.AmbientEnemyClasses[spawnId] = nil;
	end

    for spawnPart, spawnInfo in pairs(self.SpawnPlatforms) do
        spawnInfo.SpawnedAmbientEntity = nil;
    end
	
	shared.Notify(game.Players:GetPlayers(), "Coop failed!", "Negative");
	
	for a=5, 1, -1 do
		self:Hud{
			Header = `Coop failed!`;
			Status = `Restarting in {a}s..`;
			PlayMusic=false;
		};
		
		shared.Notify(game.Players:GetPlayers(), `Restarting in {a}s..`, "Negative", "ModeRestarting");
		task.wait(1);
	end
	
	self:RespawnDead();
	self:Start();
end

function Coop:SetHeader(str)
	self.HeaderLabel = str or self.HeaderLabel;
	self:Hud{
		Header = self.HeaderLabel;
	};
end

function Coop:SetStatus(str)
	self.StatusLabel = str or self.StatusLabel;
	self:Hud{
		Status = self.StatusLabel;
	};
end

--MARK: Hud
function Coop:Hud(data)
	if not self.Loaded then return end;
	data = data or {};
	
	if self.HudValues == nil then
		self.HudValues = {};
	end
	
	remoteGameModeHud:FireAllClients({
		Action = "Open";
		Type = self.ModeType;
		Stage = self.ModeStage;
		Header = data.Header or self.HeaderLabel or "";
		Status = data.Status or self.StatusLabel or "";
		IsHard = self.IsHard;
		
		HookEntity = data.HookEntity or false;
		
		LootPrefab = self.LootPrefab;
		PlayMusic = data.PlayMusic;

		StopwatchTick = self.StopwatchTick;
		StopwatchFinal = self.StopwatchFinal;
	});
end

local spawnCfCaches = {};
function Coop:LoadSpawnPlatform(spawnPart: BasePart)
	local spawnPlatformInfo = self.SpawnPlatforms[spawnPart];
	if spawnPlatformInfo == nil and spawnPlatformInfo.Enabled ~= true then return end;

	if spawnPlatformInfo.LoadState ~= nil then return end;
	spawnPlatformInfo.LoadState = 1;

    spawnPart.Transparency = 1;
	
    local platformTopCf = spawnPart.CFrame * CFrame.new(0, (spawnPart.Size.Y/2) +0.3, 0);

    local worldSpaceSize = spawnPart.CFrame:VectorToWorldSpace(spawnPart.Size * Vector3.new(0.9, 1, 0.9));
    worldSpaceSize = Vector3.new(math.abs(worldSpaceSize.X), math.abs(worldSpaceSize.Y), math.abs(worldSpaceSize.Z));

    local protoTypeId = spawnPlatformInfo.Name;
    local cacheSpawns = spawnCfCaches[protoTypeId];

    local maxSpawns = 1;
	local debugSpawnFlag = (spawnPart.Parent :: Folder):GetAttribute("Debug") == true;

    if cacheSpawns == nil then
        local loopCount = 0;
        local newSpawnCFrame;

        maxSpawns = math.ceil((worldSpaceSize.X * worldSpaceSize.Z)/512)+8;

		local forceBreak = 0;
        while newSpawnCFrame == nil do
            newSpawnCFrame = platformTopCf * CFrame.new(
                math.random((-worldSpaceSize.X/2) *100, (worldSpaceSize.X/2) *100)/100, 
                3, 
                math.random((-worldSpaceSize.Z/2) *100, (worldSpaceSize.Z/2) *100)/100
            );
			
    		local isFreeSpace = modVector.IsFreeSpace(
							newSpawnCFrame, 
							Vector3.new(3, 6, 3)
						);
			if debugSpawnFlag then
				local debugSpawnFolder = workspace.CurrentCamera:FindFirstChild("DebugSpawns");
				if debugSpawnFolder == nil then
					debugSpawnFolder = Instance.new("Folder");
					debugSpawnFolder.Name = "DebugSpawns";
					debugSpawnFolder.Parent = workspace.CurrentCamera;
				end
				
				local debugSpawnPart = Instance.new("Part");
				debugSpawnPart.Name = `Spawn_{#debugSpawnFolder:GetChildren() +1}`;
				debugSpawnPart.Anchored = true;
				debugSpawnPart.CanCollide = false;
				debugSpawnPart.Size = Vector3.new(3, 6, 3);
				debugSpawnPart.Color = isFreeSpace and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0);
				debugSpawnPart.CFrame = newSpawnCFrame;
				debugSpawnPart.Parent = debugSpawnFolder;
			end
			if not isFreeSpace then
				forceBreak = forceBreak +1;
				if forceBreak > 32 then
					Debugger:Warn(`Could not create spawn location for {spawnPart:GetFullName()} at ({newSpawnCFrame.Position})`);
					break;
				end
				continue;
			end

            table.insert(spawnPlatformInfo.SpawnCFrames, newSpawnCFrame);
            
            newSpawnCFrame = nil;

            if #spawnPlatformInfo.SpawnCFrames >= maxSpawns then
                break;
            end
            loopCount = loopCount + 1;
            if loopCount > maxSpawns+4 then break end;
        end

        cacheSpawns = {};
        for a=1, #spawnPlatformInfo.SpawnCFrames do
            table.insert(cacheSpawns, platformTopCf:ToObjectSpace(spawnPlatformInfo.SpawnCFrames[a]));
        end
        spawnCfCaches[protoTypeId] = cacheSpawns;

    else
        for a=1, #cacheSpawns do
            table.insert(spawnPlatformInfo.SpawnCFrames, platformTopCf * cacheSpawns[a]);
        end

    end
    
    local numToSpawn = math.min(
        math.random(Config.MinSpawnCount, Config.MaxSpawnCount), 
        #spawnPlatformInfo.SpawnCFrames
    );
    spawnPlatformInfo.SpawnAmount = numToSpawn;

    spawnPart:SetAttribute("MaxSpawns", maxSpawns);
    spawnPart:SetAttribute("SpawnAmount", numToSpawn);

    spawnPlatformInfo.LoadState = 2;
end

return Coop;