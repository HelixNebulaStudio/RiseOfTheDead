local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService: RunService = game:GetService("RunService");
local PathfindingService = game:GetService("PathfindingService");

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
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

local Config = {
    EnemyCap = 20;
    SpawnPlatformRadius = 64;

    MinSpawnCount = 2;
    MaxSpawnCount = 4;
};

local Stronghold = {
    Active = nil;
};
Stronghold.__index = Stronghold;

local EnumStatus = {Initialized=-1; Restarting=0; InProgress=1; Completed=2;};
Stronghold.EnumStatus = EnumStatus;

local platformParam = OverlapParams.new();
platformParam.FilterType = Enum.RaycastFilterType.Include;
--==

function Stronghold.onRequire()
    modNpcs = shared.modNpcs;

	serverPrefabs = game.ServerStorage:WaitForChild("Prefabs"):WaitForChild("Objects");
    remoteGameModeHud = modRemotesManager:Get("GameModeHud");
end

--MARK: new()
function Stronghold.new()
	local self = {
		Status = EnumStatus.Initialized;

		SpawnPlatforms = ({} :: {[Part] : {
            Name: string; 
            Part: Part; 
            Index: number; 
            Spawns: {}; 
            Enabled: boolean;
        }});

        Players = {};
        AlivePlayers = ({} :: {PlayerClass});
        
        Doors = {};
        ExtractDoors = {};
        EnemyClassInstances = {};

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
        EliminateGoal = 0;
	};

	if Stronghold.Active == nil then
		Stronghold.Active = self;
	end
	
	setmetatable(self, Stronghold);
	return self;
end

function Stronghold:Load()
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

	self.Loaded = true;
end

--MARK: Initialize
function Stronghold:Initialize(roomData)
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
        
			activeLoop = true;
			while activeLoop do
				if self.Status ~= EnumStatus.InProgress then
					task.wait(3);
					continue;
				end;

				if #wlInstances <= 0 then
					for part, _ in pairs(self.SpawnPlatforms) do
						table.insert(wlInstances, part);
					end
					
					platformParam.FilterDescendantsInstances = wlInstances;
				end

                --MARK: Scan spawn platforms
				local hitList = workspace:GetPartBoundsInRadius(
					rootPart.Position, 
					Config.SpawnPlatformRadius, 
					platformParam
				);
				
				for a=1, #hitList do
					local spawnPlatformPart = hitList[a];
					local spawnPlatformInfo = self.SpawnPlatforms[spawnPlatformPart];
					if spawnPlatformInfo == nil or spawnPlatformInfo.Enabled ~= true then continue end;

					if spawnPlatformInfo.LoadState ~= 2 or spawnPlatformInfo.SpawnedAmbientEntity == true then continue end;
					spawnPlatformInfo.SpawnedAmbientEntity = true;

                    local numToSpawn = spawnPlatformInfo.SpawnAmount;
					for a=1, numToSpawn do
						local spawnCf = spawnPlatformInfo.SpawnCFrames[a] 
                                        * CFrame.new(0, 1, 0) 
                                        * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
						
						if #self.EnemyClassInstances <= Config.EnemyCap then
							self:SpawnEnemy(self:PickEnemy(), {
								SpawnCFrame = spawnCf;
							});
							continue;
						end

						for a=1, 4 do
							local chosenNpcModule;
							
							for b=1, 3 do
								chosenNpcModule = self.EnemyClassInstances[math.random(1, #self.EnemyClassInstances)]
								if chosenNpcModule.BasicEnemy == true then break; end;
							end
							
							if chosenNpcModule.BasicEnemy ~= true then continue end;
							if chosenNpcModule.RootPart == nil then continue end;

							local tooClose = false;
							for _, player in pairs(game.Players:GetPlayers()) do
								if player:DistanceFromCharacter(chosenNpcModule.RootPart.Position) <= 128 then
									tooClose = true;
									break;
								end
							end
							
							if not tooClose then
								chosenNpcModule.Target = nil;
								chosenNpcModule.RootPart.CFrame = spawnCf;
							end
						end
					end
                end

				task.wait(1);
			end
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
end

function Stronghold:PickEnemy(paramPacket)
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
function Stronghold:SpawnEnemy(npcName, paramPacket)
	if self.EliminateCount >= self.EliminateGoal then return end;
	paramPacket = paramPacket or {};

	local spawnCf = paramPacket.SpawnCFrame;

	return modNpcs.spawn2{
		Name = npcName;
		CFrame = spawnCf;

		BindSetup = function(npcClass: NpcClass)
			self.EnemiesSpawned = self.EnemiesSpawned + 1;

			local properties: PropertiesVariable<{}> = npcClass.Properties;
			properties.Level = math.max(npcClass.Properties.Level + (self.Difficulty + (self.Wave-1)) + math.random(-2, 0), 1);
			properties.CanForgetTargets = false;
			properties.IsHostile = true;

			if paramPacket.InfTargeting then
				local targetHandlerComp = npcClass:GetComponent("TargetHandler");
				if targetHandlerComp then
					for a=1, #self.Players do
						targetHandlerComp:AddTarget(self.Players[a].Character);
					end
				end
			end

			table.insert(self.EnemyClassInstances, npcClass);

			local healthComp: HealthComp = npcClass.HealthComp;
			healthComp.OnIsDeadChanged:Connect(function()
				if not healthComp.IsDead then return end;

				self.LastKilled = tick();
				for a=#self.EnemyClassInstances, 1, -1 do
					if self.EnemyClassInstances[a] == npcClass then
						table.remove(self.EnemyClassInstances, a);
						break;
					end
				end

				self.EliminateCount = self.EliminateCount +1;
				self.LastEnemyDeathPos = npcClass.RootPart.CFrame.Position;
				
				if self.Status == EnumStatus.InProgress then
					local remining = math.max(0, self.EliminateGoal - self.EliminateCount);

					self.ObjectiveStatusText = `Eliminate {remining} enemies`;
					self:Hud({
						Status=self.ObjectiveStatusText;
					});
					
					if self.EliminateCount >= self.EliminateGoal then
						self:CompleteRaid();
					end
					
				end
			end)
		end
	};
end

function Stronghold:CompleteRaid()
	workspace:SetAttribute("GameModeComplete", true);

	local runTimeStr = "";
	if self.StopwatchTick then
		local timeLapse = workspace:GetServerTimeNow()-self.StopwatchTick;
		self.StopwatchFinal = timeLapse;

		runTimeStr = ` Run time: {modSyncTime.FormatMs(timeLapse *1000)}!`;
	end

	self.Status = EnumStatus.Completed;
	shared.Notify(game.Players:GetPlayers(), `Raid Complete!{runTimeStr}`, "Positive");
	self:Hud{
		Status="Raid Complete!";
		PlayMusic=false;
	};

	self:RespawnDead();
	task.wait(1);

	self:DropReward();
	
	if self.OnComplete then
		self.OnComplete(self.Players);
	end
end

function Stronghold:DropReward()
	local spawnLocPart = workspace:FindFirstChildWhichIsA("SpawnLocation");
	local rewardSpawnPart = workspace.Environment.Game:FindFirstChild("RewardSpawn");
	
	
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
	if rewardSpawnPart then
		spawnCf = rewardSpawnPart.CFrame;

	elseif closestExtractDoorModel then
		spawnCf = closestExtractDoorModel.PrimaryPart.LootSpawn.WorldCFrame;

	end
	
	
	local rewardDropsList = {self.StageLib.RewardsId;};
	self.LootPrefab = modItemDrops.Spawn({
		Type="Tool"; 
		ItemId=rewardDropsList[math.random(1, #rewardDropsList)]
	}, spawnCf, self.Players, false);

	self:Hud{
		Status="A reward package has dropped!";
	};
end

function Stronghold:Start()
	self.StopwatchTick = nil;
	Debugger:Warn("Stronghold:Start");

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
    for spawnPart, spawnInfo in pairs(self.SpawnPlatforms) do
		self:LoadSpawnPlatform(spawnPart);
        self.EliminateGoal = self.EliminateGoal + spawnInfo.SpawnAmount;
	end
    
	for a=5, 1, -1 do
		self:Hud({
			Status = `Stronhold is starting in {a}s..`;
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

	self.ObjectiveStatusText = `Eliminate {self.EliminateGoal} enemies`;
	self:Hud({
		Status=self.ObjectiveStatusText;
	})
    Debugger:StudioLog(`Stronghold:Start self=`, self);
end

function Stronghold:RespawnDead()
	for _, player in pairs(self.Players) do
		if player == nil or not player:IsDescendantOf(game.Players) then continue end;
		
		local playerClass: PlayerClass = shared.modPlayers.get(player);
		if player.Character == nil or playerClass.HealthComp.IsDead then
			playerClass:Spawn();
		end;
	end
end

function Stronghold:Restart()
	for a=#self.EnemyClassInstances, 1, -1 do
		game.Debris:AddItem(self.EnemyClassInstances[a].Character, 0);
		table.remove(self.EnemyClassInstances, a);
	end

    for spawnPart, spawnInfo in pairs(self.SpawnPlatforms) do
        spawnInfo.SpawnedAmbientEntity = nil;
    end
	
	shared.Notify(game.Players:GetPlayers(), "Raid failed!", "Negative");
	
	for a=5, 1, -1 do
		self:Hud{
			Header = `Raid failed!`;
			Status = `Restarting in {a}s..`;
			PlayMusic=false;
		};
		
		shared.Notify(game.Players:GetPlayers(), `Restarting in {a}s..`, "Negative", "ModeRestarting");
		task.wait(1);
	end
	
	self:RespawnDead();
	self:Start();
end

function Stronghold:Hud(data)
	if not self.Loaded then return end;
	data = data or {};
	
	if self.HudValues == nil then
		self.HudValues = {};
	end
	
	remoteGameModeHud:FireAllClients({
		Action="Open";
		Type=self.ModeType;
		Stage=self.ModeStage;
		Header=data.Header or `Elimination`;
		Status=data.Status or "";
		IsHard=self.IsHard;
		
		HookEntity=data.HookEntity or false;
		
		LootPrefab=self.LootPrefab;
		PlayMusic=data.PlayMusic;

		StopwatchTick = self.StopwatchTick;
		StopwatchFinal = self.StopwatchFinal;
	});
end

local spawnCfCaches = {};
function Stronghold:LoadSpawnPlatform(spawnPart: BasePart)
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
return Stronghold;