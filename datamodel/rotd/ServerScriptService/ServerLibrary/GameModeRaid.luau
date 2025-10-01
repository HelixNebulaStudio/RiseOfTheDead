local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Config = {
	EnemyCap=300;
	
	SpawnPlatformRadius=128;
	MinSpawnCount=2;
	MaxSpawnCount=3;

	HordeTimerDeduction = NumberRange.new(10, 30);

	HordeCycle=nil;
	HordeSpawnRate=nil;
	HordeWhenEnemiesDropsBelow=nil;
}

local Raid = {};
Raid.__index = Raid;
Raid.Active = nil;

local EnumStatus = {Initialized=-1; Restarting=0; InProgress=1; Completed=2;};
Raid.EnumStatus = EnumStatus;

local RunService: RunService = game:GetService("RunService");
local PathfindingService = game:GetService("PathfindingService");

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDoors = shared.require(game.ReplicatedStorage.Library.Doors);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modTeamsManager = shared.require(game.ReplicatedStorage.Library.TeamsManager);

local modNpcs = shared.modNpcs;
local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);
--==
local platformParam = OverlapParams.new();
platformParam.FilterType = Enum.RaycastFilterType.Include;

function Raid.onRequire()
	serverPrefabs = game.ServerStorage:WaitForChild("Prefabs"):WaitForChild("Objects");
	remoteGameModeHud = modRemotesManager:Get("GameModeHud");
end

function Raid.new()
	local self = {
		Status = EnumStatus.Initialized;
		
		Difficulty = 1;
		Wave = 1;
		DoorsOpened = 0;
		EnemiesSpawned = 0;
		
		EliminateGoal=0;
		EliminateCount=0;
		
		SpawnPlatforms = {};

		HiddenSpawns = {};
		SpecialSpawns = {};
		
		EnemiesList = {
			{Name="Zombie"; Chance=100;};
			{Name="Leaper"; Chance=15; Fmod=15;};
			{Name="Ticks"; Chance=10; Fmod=10;};
			{Name="Heavy"; Chance=0.1; Fmod=10;};
		};
		
		Doors = {};
		Blockades = {};
		ExtractDoors = {};
		
		Characters = {};
		EnemyClassInstances = {};
		
		StopwatchTick = nil;
		Path = PathfindingService:CreatePath();

		ObjectiveStatusText = "";
	};

	if Raid.Active == nil then
		Raid.Active = self;
	end
	
	setmetatable(self, Raid);
	return self;
end

function Raid:Load()
	self.GameLib = modGameModeLibrary.GetGameMode(self.ModeType);
	self.StageLib = self.GameLib and modGameModeLibrary.GetStage(self.ModeType, self.ModeStage);

	local mapWaveCollapse = shared.WorldCore.RaidMapWc;
	if mapWaveCollapse then
		-- GenerateDynamicMap;
		self.DynamicMap = {};
		
		local mapFolder = Instance.new("Folder");
		mapFolder.Name = "DynamicMap";
		
		local partTemplate = Instance.new("Part");
		partTemplate.Name = "Part";
		partTemplate.Color = Color3.fromRGB(90, 90, 90);
		partTemplate.Anchored = true;
		partTemplate.Size = Vector3.new(mapWaveCollapse.GridSize, mapWaveCollapse.GridSize, mapWaveCollapse.GridSize);
		
		local layerModels = {};
		local spChecklist = {};
		
		local edgeDataList = mapWaveCollapse:GetEdgePoints();
		for a=1, #edgeDataList do
			
			local axisVec = edgeDataList[a].AxisVec;
			local position = edgeDataList[a].Position;
			local superposition = edgeDataList[a].Superposition;

			local layerLevel = superposition.LayerLevel;
			local layerModel = layerModels[layerLevel];
			
			if layerModel == nil then
				layerModel = Instance.new("Model");
				layerModel.Name = "Layer "..layerLevel;
				layerModel.Parent = mapFolder;

				layerModels[layerLevel] = layerModel;
			end
			
			if superposition.Value and superposition.Value ~= "nil" and spChecklist[superposition] == nil then
				spChecklist[superposition] = true;

				local newPart = partTemplate:Clone();
				newPart.Name = "Tile";
				newPart.Position = superposition.Position * mapWaveCollapse.GridSize - Vector3.new(0, mapWaveCollapse.GridSize/2, 0);
				newPart.Size = Vector3.new(mapWaveCollapse.GridSize, 1, mapWaveCollapse.GridSize);
				newPart.Parent = layerModel;
			end
			
			if 1-math.abs(axisVec.Y) ~= 0 then -- is wall;
				local wallMinThickness = 5;
				
				local newPart = partTemplate:Clone();
				newPart.Name = "Wall";
				newPart.Color = Color3.fromRGB(110, 110, 110);
				
				local wallSize = Vector3.new(mapWaveCollapse.GridSize, mapWaveCollapse.GridSize, mapWaveCollapse.GridSize) 
					* Vector3.new(1-math.abs(axisVec.X), 1-math.abs(axisVec.Y), 1-math.abs(axisVec.Z));
				newPart.Size = Vector3.new(math.max(wallSize.X, wallMinThickness), math.max(wallSize.Y, wallMinThickness), math.max(wallSize.Z, wallMinThickness));
				
				newPart.Position = position * mapWaveCollapse.GridSize;
				newPart.Parent = layerModel;
			end;
		end
		
		mapFolder.Parent = game.ReplicatedStorage;
		
	end

	if workspace.Environment:FindFirstChild("CollapseMap") then
		local collapseMap = workspace.Environment.CollapseMap;

		local extractDoors = {};
		local mapTotalVec = nil;
		local totalVecs = 0;
		
		for _, tileModel in pairs(collapseMap:GetChildren()) do
			if tileModel:FindFirstChild("Layout") then
				for _, child in pairs(tileModel.Layout:GetChildren()) do
					if child:FindFirstChild("Door") and child.Door:IsA("Configuration") then
						local doorInstance: DoorInstance = modDoors.getOrNew(child.Door);
						table.insert(self.Doors, doorInstance);
						
					elseif child.Name == "SpawnPlatform" then
						self.SpawnPlatforms[child] = {
							Name=tileModel.Name;
							Part=child;
							Index=(child:GetAttribute("Index") or 999);
							Spawns={};
							Enabled=true;
						};
						
						if mapTotalVec == nil then
							mapTotalVec = child.Position;
						else
							mapTotalVec = mapTotalVec + child.Position;
						end
						totalVecs = totalVecs +1;
						
					elseif child.Name == "ExtractDoor" then
						table.insert(extractDoors, {Prefab=child;});
						
					elseif child.Name == "HiddenSpawns" then
						for _, obj in pairs(child:GetDescendants()) do
							if not obj:IsA("Attachment") then continue end;

							obj:SetAttribute("Enabled", obj.Name == "HiddenSpawn");
							table.insert(self.HiddenSpawns, obj);
							
						end
						
					elseif child.Name == "TileModule" then
						local tileObj = shared.require(child);
						tileObj:Init(self, mapWaveCollapse);
						
					end
				end
			end
		end
		
		local mapCenterPos = mapTotalVec/totalVecs;
		
		--local debugCenterPart = Debugger:PointPart(mapCenterPos);
		--debugCenterPart.Name = "MapCenter";
		
		for a=1, #extractDoors do
			local distFromCenter = (extractDoors[a].Prefab:GetPivot().Position-mapCenterPos).Magnitude;
			extractDoors[a].DistFromCenter = distFromCenter;
		end
		table.sort(extractDoors, function(a, b) return a.DistFromCenter > b.DistFromCenter end);
		
		for a=1, #extractDoors do
			table.insert(self.ExtractDoors, extractDoors[a].Prefab);
			
			local newInteractable = modInteractables.createInteractable("GameModeExit");
			newInteractable:SetAttribute("Mode", self.ModeType);
			newInteractable:SetAttribute("Stage", self.ModeStage);
			newInteractable:SetAttribute("Label", "Extract");
			newInteractable.Parent = extractDoors[a].Prefab;
		end
		
	end

	-- MARK: Load Static Game Elements
	self.GameDir = workspace.Environment:FindFirstChild("Game");
	if workspace.Environment:FindFirstChild("Game") then
		local gameDir: Folder = self.GameDir;

		for _, object: Instance in pairs(gameDir:GetChildren()) do
			if object.Name == "SpawnPlatforms" then
				object.Parent = workspace.CurrentCamera;
				
				local spCount = 0;
				for _, child in pairs(object:GetChildren()) do

					if child:IsA("Folder") then
						for _, plat in pairs(child:GetChildren()) do
							spCount = spCount +1;
							self.SpawnPlatforms[plat] = {
								Name="SpawnPlatform"..spCount;
								Part=plat;
								Index=(plat:GetAttribute("Index") or 999);
								Spawns={};

								PlatformGroup=child.Name;
								Enabled=false;
							};
						end

					else
						spCount = spCount +1;
						self.SpawnPlatforms[child] = {
							Name="SpawnPlatform"..spCount;
							Part=child;
							Index=(child:GetAttribute("Index") or 999);
							Spawns={};
							Enabled=true;
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
			
			elseif object.Name == "HiddenSpawns" then
				for _, obj in pairs(object:GetChildren()) do
					if not obj:IsA("Attachment") then continue end;
					
					obj:SetAttribute("Enabled", obj.Name == "HiddenSpawn");
					table.insert(self.HiddenSpawns, obj);
					
				end

			elseif object.Name == "StageSpawns" then
				for _, obj in pairs(object:GetChildren()) do
					if not obj:IsA("BasePart") then continue end;
					obj.Transparency = 1;
				end

			end
		end
	end

	self.Loaded = true;

	task.spawn(function()
		Debugger.AwaitShared("modCommandsLibrary");
		shared.modCommandsLibrary:HookChatCommand("raid", {
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
			Description = [[Raid commands.
			/raid drawexitpath
			/raid complete
		]];

			RequiredArgs = 0;
			UsageInfo = "/raid action";
			Function = function(player, args)
				local action = args[1];

				--local classPlayer = shared.modPlayers.get(player);
				
				if action == "drawexitpath" then

					local spawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation");
					
					local playerNode = {
						Position = mapWaveCollapse.VoxelSpace:GetVoxelPosition(spawnLocation.Position, mapWaveCollapse.GridSize);
					}
					for a=1, #self.ExtractDoors do
						local extractDoorPrefab = self.ExtractDoors[a];
						local doorNode = {
							Position = mapWaveCollapse.VoxelSpace:GetVoxelPosition(extractDoorPrefab:GetPivot().Position, mapWaveCollapse.GridSize);
						}
						

						local waypointsVoxels = mapWaveCollapse.VoxelSpace:SolvePath(doorNode, playerNode);
						
						if waypointsVoxels then
							for a=1, #waypointsVoxels do
								local superposition = waypointsVoxels[a].Value;
								superposition:DebugPart( Color3.fromRGB(114, 255, 123), 0.8);
							end
						end
					end
					
				elseif action == "complete" then
					self:CompleteRaid();
					
				end

				return true;
			end;
		});
	end)
end


function Raid:CompleteRaid()
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

function Raid:RespawnDead()
	for _, player in pairs(self.Players) do
		if player == nil or not player:IsDescendantOf(game.Players) then continue end;
		
		local playerClass: PlayerClass = shared.modPlayers.get(player);
		if player.Character == nil or playerClass.HealthComp.IsDead then
			playerClass:Spawn();
		end;
	end
end

function Raid:DropReward(spawnCf)
	local spawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation");
	
	if spawnCf == nil then
		local playersCenterPos = nil;
		
		for a=1, #self.Characters do
			local char = self.Characters[a];
			if playersCenterPos == nil then
				playersCenterPos = char:GetPivot().Position;
			else
				playersCenterPos = playersCenterPos + char:GetPivot().Position;
			end
		end
		
		playersCenterPos = playersCenterPos / #self.Characters;


		local mapWaveCollapse = shared.WorldCore.RaidMapWc;
		
		local closestExtractDoor = nil
		local closestDist = math.huge;
		
		for a=1, #self.ExtractDoors do
			local prefab = self.ExtractDoors[a];
			
			if mapWaveCollapse then
				local playerNode = {
					Position = mapWaveCollapse.VoxelSpace:GetVoxelPosition(spawnLocation.Position, mapWaveCollapse.GridSize);
				}
				local doorNode = {
					Position = mapWaveCollapse.VoxelSpace:GetVoxelPosition(prefab:GetPivot().Position, mapWaveCollapse.GridSize);
				}

				local waypointsVoxels = mapWaveCollapse.VoxelSpace:SolvePath(doorNode, playerNode);
				if waypointsVoxels == nil then
					Debugger:Warn("Can't path to extract door at ", prefab:GetPivot().Position);
					
					continue;
				end
			end
			
			local dist = (prefab:GetPivot().Position - playersCenterPos).Magnitude;
			
			if dist < closestDist then
				closestExtractDoor = prefab;
				closestDist = dist;
			end
		end
		
		if closestExtractDoor then
			spawnCf = closestExtractDoor.PrimaryPart.LootSpawn.WorldCFrame;
			
		else
			Debugger:Warn("No accessible extract door");
			spawnCf = spawnLocation.LootSpawn.WorldCFrame;
			
		end
	end
	
	local rewardDropsList = {self.StageLib.RewardsId;};

	self.LootPrefab = modItemDrops.Spawn({Type="Tool"; ItemId=rewardDropsList[math.random(1, #rewardDropsList)]}, spawnCf, self.Players, false);

	self:Hud{
		Status="A reward package has dropped!";
	};
end

function Raid:PickEnemy(paramPacket)
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
			
			if paramPacket then
				if paramPacket.IsHordeWave == true and enemyOption.HordeWave == false then
					isSpawnable = false;
				end
			end
			
			if isSpawnable == true then
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


function Raid:SpawnEnemy(npcName, paramPacket)
	if self.EliminateCount >= self.EliminateGoal then return end;
	paramPacket = paramPacket or {};

	local spawnCf = paramPacket.SpawnCFrame;
	
	-- if self.OnNpcSpawnHooked == nil then
	-- 	self.OnNpcSpawnHooked = modNpcs.OnNpcSpawn:Connect(function(npcModule)
	-- 		if modConfigurations.TargetableEntities[npcModule.Humanoid.Name] == nil then return end; -- Not enemy spawn;

	-- 		table.insert(self.EnemyClassInstances, npcModule);

	-- 		npcModule.Garbage:Tag(function()
	-- 			for a=#self.EnemyClassInstances, 1, -1 do
	-- 				if self.EnemyClassInstances[a] == npcModule then
	-- 					table.remove(self.EnemyClassInstances, a);
	-- 					break;
	-- 				end
	-- 			end
	-- 		end)

	-- 		npcModule.Humanoid.Died:Connect(function()
	-- 			self:BeginCount();

	-- 			self.LastKilled = tick();
	-- 			for a=#self.EnemyClassInstances, 1, -1 do
	-- 				if self.EnemyClassInstances[a] == npcModule then
	-- 					table.remove(self.EnemyClassInstances, a);
	-- 					break;
	-- 				end
	-- 			end

	-- 			npcModule.DeathPosition = npcModule.RootPart.CFrame.p;

	-- 			self.LastEnemyDeathPos = npcModule.DeathPosition;
				
	-- 			self.EliminateCount = self.EliminateCount +1;
				
	-- 			if self.Status == EnumStatus.InProgress then
					
	-- 				if self.Objective.Id == "Eliminate" then
	-- 					local remining = math.max(0, self.EliminateGoal - self.EliminateCount);

	-- 					self.ObjectiveStatusText = `Eliminate {remining} enemies`;
	-- 					self:Hud({
	-- 						Status=self.ObjectiveStatusText;
	-- 					});
						
	-- 					if self.EliminateCount >= self.EliminateGoal then
	-- 						self:CompleteRaid();
	-- 					end
	-- 				end
					
	-- 			end
	-- 		end);
	-- 	end)
	-- end

	local npcClass: NpcClass = modNpcs.spawn2{
		Name = npcName;
		CFrame = spawnCf;

		BindSetup = function(npcClass: NpcClass)
			self.EnemiesSpawned = self.EnemiesSpawned + 1;

			local properties: PropertiesVariable<{}> = npcClass.Properties;
			properties.Level = math.max(npcClass.Properties.Level + (self.Difficulty + (self.Wave-1)) + math.random(-2, 0), 1);
			properties.TargetableDistance = 256;
			properties.NetworkOwners = self.Players;
			properties.CanForgetTargets = false;
			properties.HordeAggression = paramPacket.HordeAggression == true;

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

				self:BeginCount();

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
					if self.Objective.Id == "Eliminate" then
						local remining = math.max(0, self.EliminateGoal - self.EliminateCount);

						self.ObjectiveStatusText = `Eliminate {remining} enemies`;
						self:Hud({
							Status=self.ObjectiveStatusText;
						});
						
						if self.EliminateCount >= self.EliminateGoal then
							self:CompleteRaid();
						end
					end
					
				end
			end)
		end
	};

	return npcClass;

	-- local newNpcModule;
	-- local npcPrefab = modNpcs.spawn(npcName, spawnCf, function(npcPrefab, npcModule)
	-- 	self.EnemiesSpawned = self.EnemiesSpawned + 1;
		
	-- 	newNpcModule = npcModule;

	-- 	npcModule.Configuration.Level = math.max(npcModule.Configuration.Level + (self.Difficulty + (self.Wave-1)) + math.random(-2, 0), 1);
	-- 	npcModule.Properties.TargetableDistance = 256;
	-- 	npcModule.NetworkOwners = game.Players:GetPlayers();
		
	-- 	if paramPacket.InfTargeting then
	-- 		npcModule.SetAggression = 3;
	-- 		npcModule.InfTargeting = true;
	-- 		npcModule.AutoSearch = true;
	-- 		npcModule.ForgetEnemies = false;
	-- 		npcModule.Properties.TargetableDistance = 4096;

	-- 		npcModule.OnTarget(self.Players);
	-- 	end
		
		
	-- 	if npcName == "Pathoroth" then
	-- 		local newHealth = 4000 * math.max(math.ceil(self.Difficulty/2) + math.ceil(self.Wave/2), 1);
	-- 		npcModule.Humanoid.MaxHealth = math.clamp(newHealth, 1000, math.huge);
	-- 		npcModule.Humanoid.Health = npcModule.Humanoid.MaxHealth;
	-- 	end

	-- 	if self.OnEnemySpawn then self:OnEnemySpawn(npcPrefab, npcModule); end
	-- end);

	-- return npcPrefab, newNpcModule;
end

function Raid:BeginCount()
	if self.Status ~= EnumStatus.InProgress then return end;
	
	if self.StageLib.EnableStopwatch == true then
		if self.StopwatchTick == nil then
			self.StopwatchTick = workspace:GetServerTimeNow();
		end
	end

	self:Hud({
		Status=self.ObjectiveStatusText;
		PlayMusic=true;
	});
end

function Raid:Start()
	self.StopwatchTick = nil;
	Debugger:Warn("Raid:Start");

	self:Hud({Action="Open"});
	
	self.DoorsOpened = 0;
	self.Wave = 1;
	
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
	--
	
	if self.DynamicMap then
		for a=1, #self.DynamicMap do
			local dynamicMapPart = self.DynamicMap[a];
			dynamicMapPart.Color = Color3.fromRGB(90, 90, 90);
		end

	end
	
	--
	local destructibleObjs = {};
	
	for a=1, #self.Doors do
		local doorInstance: DoorInstance = self.Doors[a];
		local doorModel = doorInstance.Model;
		
		doorInstance.Raided = nil;
		doorInstance:Toggle(false);


		if doorInstance.SpawnBlockade == false then continue end;
		doorInstance.CanBreakIn = false;
		
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
			
			local destructibleModule = new:WaitForChild("Destructible");
			local destructible: DestructibleInstance = modDestructibles.getOrNew(destructibleModule);

			destructible.OnDestroy:Connect(function()
				self:BeginCount();
			end)

			destructible.OnDestroy:Connect(function()
				local addStageSpawn = doorModel:GetAttribute("AddStageSpawn");
				if addStageSpawn == nil then return end;

				for _, att in pairs(self.HiddenSpawns) do
					if att.Name == addStageSpawn then
						att:SetAttribute("Enabled", true);
					end
				end
			end)

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
	
	
	--MARK: Destructible Blockades;
	for a=1, #self.Blockades do
		local destructibleModel = self.Blockades[a];

		local new = destructibleModel:Clone();
		new.Parent = workspace.Environment.Game;

		local destructibleConfig = new:WaitForChild("Destructible");
		local destructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);

		destructible.OnDestroy:Connect(function()
			self:BeginCount();
		end)

		destructible.OnDestroy:Connect(function()
			local addStageSpawn = new:GetAttribute("AddStageSpawn");
			if addStageSpawn == nil then return end;

			for _, att in pairs(self.HiddenSpawns) do
				if att.Name == addStageSpawn then
					att:SetAttribute("Enabled", true);
				end
			end
		end)

		destructible.OnDestroy:Connect(function()
			local platformName = new:GetAttribute("AddSpawnPlatforms");
			if platformName == nil then return end;
			
			for platformPart, platformInfo in pairs(self.SpawnPlatforms) do
				if platformInfo.PlatformGroup == platformName then
					platformInfo.Enabled = true;
				end
			end
		end)

		destructible.OnDestroy:Connect(function(reasonData)
			local pivot = destructible.Model:GetPivot();
			local nearbyNpcClasses = shared.modNpcs.listInRange(pivot.Position, 64, 32);

			for a=1, #nearbyNpcClasses do
				local npcModule = nearbyNpcClasses[a];

				if npcModule.OnTarget == nil then continue end;

				if reasonData and reasonData.DamageBy then
					Debugger:StudioWarn(`Destroy by`, reasonData.DamageBy.Name);
					if reasonData.DamageBy.ClassName == "PlayerClass" then
						local player = reasonData.DamageBy:GetInstance();
						npcModule.OnTarget(player);
					end
				end
			end

			local hordeTimerDeduction = math.random(Config.HordeTimerDeduction.Min, Config.HordeTimerDeduction.Max);
			shared.WorldCore.HordeTimer = shared.WorldCore.HordeTimer - hordeTimerDeduction;
		end)
		
		table.insert(destructibleObjs, destructible);
	end


	for _, att in pairs(self.HiddenSpawns) do
		att:SetAttribute("Enabled", att.Name == "HiddenSpawn");
	end

	local spawnPlatformCount = 0;
	for spawnPart, spawnInfo in pairs(self.SpawnPlatforms) do
		spawnInfo.SpawnedAmbientZombies = nil;
		spawnPlatformCount = spawnPlatformCount +1;
		
		if spawnInfo.PlatformGroup then
			spawnInfo.Enabled = false;
		end
	end
	
	-- MARK: Initializing Config;
	Debugger:StudioLog(`Initialize Raid Config`, self.Objective);
	if self.Objective.MaxSpawnCount then
		Config.MaxSpawnCount = self.Objective.MaxSpawnCount;
	end
	if self.Objective.MinSpawnCount then
		Config.MinSpawnCount = self.Objective.MinSpawnCount;
	end
	if self.Objective.EnemyCap then
		Config.EnemyCap = self.Objective.EnemyCap;
	end
	if self.Objective.SpawnPlatformRadius then
		Config.SpawnPlatformRadius = self.Objective.SpawnPlatformRadius
	end
	if self.Objective.HordeCycle then
		Config.HordeCycle = self.Objective.HordeCycle;
	end
	if self.Objective.HordeSpawnRate then
		Config.HordeSpawnRate = self.Objective.HordeSpawnRate;
	end
	if self.Objective.HordeWhenEnemiesDropsBelow then
		Config.HordeWhenEnemiesDropsBelow = self.Objective.HordeWhenEnemiesDropsBelow;
	end
	if self.Objective.HordeTimerDeduction then
		Config.HordeTimerDeduction = self.Objective.HordeTimerDeduction;
	end

	local minTotalZombieCount = spawnPlatformCount * Config.MinSpawnCount;
	
	self.EliminateCount = 0;
	self.EliminateGoal = math.min(Config.EnemyCap, math.max(1, math.floor(minTotalZombieCount*0.98)));

	if self.Objective.EliminateGoal then
		self.EliminateGoal = self.Objective.EliminateGoal;
	end

	if self.Objective.Id == "Eliminate" then
		
	end

	shared.WorldCore.HordeTimer = tick()+Config.HordeCycle;

	for a=5, 1, -1 do
		self:Hud({
			Status = `Raid is starting in {a}s..`;
		})
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
end

local spawnCfCaches = {};
function Raid:LoadSpawnPlatform(spawnPart)
	local spawnPlatformInfo = self.SpawnPlatforms[spawnPart];
	
	if spawnPlatformInfo == nil and spawnPlatformInfo.Enabled ~= true then return end;

	if spawnPlatformInfo.Load ~= nil then return end;
	spawnPlatformInfo.Load = 1;
	
	task.spawn(function()
		local platformTopCf = spawnPart.CFrame * CFrame.new(0, (spawnPart.Size.Y/2) +0.3, 0);

		local worldSpaceSize = spawnPart.CFrame:vectorToWorldSpace(spawnPart.Size * Vector3.new(0.9, 1, 0.9));
		worldSpaceSize = Vector3.new(math.abs(worldSpaceSize.X), math.abs(worldSpaceSize.Y), math.abs(worldSpaceSize.Z));

		local protoTypeId = spawnPlatformInfo.Name;
		local cacheSpawns = spawnCfCaches[protoTypeId];

		if cacheSpawns == nil then
			local loopCount = 0;
			local newSpawnCFrame;

			local maxSpawns = math.ceil((worldSpaceSize.X * worldSpaceSize.Z)/512)+4; --16;
			if RunService:IsStudio() then
				Debugger:Warn("[Studio] LoadSpawnPlatform maxSpawns", maxSpawns);
			end

			while newSpawnCFrame == nil do
				newSpawnCFrame = platformTopCf * CFrame.new(
					math.random((-worldSpaceSize.X/2) *100, (worldSpaceSize.X/2) *100)/100, 
					0, 
					math.random((-worldSpaceSize.Z/2) *100, (worldSpaceSize.Z/2) *100)/100
				);

				--self.Path:ComputeAsync(newSpawnCFrame.Position, platformTopCf.Position);
				--if self.Path.Status == Enum.PathStatus.Success then
				--end
				table.insert(spawnPlatformInfo.Spawns, newSpawnCFrame);
				
				newSpawnCFrame = nil;

				if #spawnPlatformInfo.Spawns >= maxSpawns then
					break;
				end
				loopCount = loopCount + 1;
				--Debugger:Warn(protoTypeId,"loopCount", loopCount, math.round((tick()-loadTimelapsed) * 1000)/1000);
				if loopCount > maxSpawns+4 then break end;
			end

			cacheSpawns = {};
			for a=1, #spawnPlatformInfo.Spawns do
				table.insert(cacheSpawns, platformTopCf:ToObjectSpace(spawnPlatformInfo.Spawns[a]));
			end
			spawnCfCaches[protoTypeId] = cacheSpawns;

		else
			for a=1, #cacheSpawns do
				table.insert(spawnPlatformInfo.Spawns, platformTopCf * cacheSpawns[a]);
			end

		end
		
		spawnPlatformInfo.Load = 2;
	end)
end

function Raid:Restart()
	for a=#self.EnemyClassInstances, 1, -1 do
		game.Debris:AddItem(self.EnemyClassInstances[a].Character, 0);
		table.remove(self.EnemyClassInstances, a);
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

--MARK: Initialize
function Raid:Initialize(roomData)
	repeat task.wait() until self.Loaded == true;
	
	modConfigurations.Set("InfTargeting", false);
	modConfigurations.Set("NpcThinkCycle", 1);
	
	self.RoomData = roomData;
	self.Players = {};
	self.IsHard = roomData.IsHard == true;
	
	local function clearCharacter(character)
		for a=#self.Characters, 1, -1 do
			local char = self.Characters[a];
			local player = game.Players:GetPlayerFromCharacter(char);
			if player == nil or (character and char.Name == character.Name) then
				table.remove(self.Characters, a);
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
		
			clearCharacter(character);
			table.insert(self.Characters, character);

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

				local hitList = workspace:GetPartBoundsInRadius(
					rootPart.Position, 
					Config.SpawnPlatformRadius, 
					platformParam
				);
				
				for a=1, #hitList do
					local spawnPlatformPart = hitList[a];

					self:LoadSpawnPlatform(spawnPlatformPart);

					local spawnPlatformInfo = self.SpawnPlatforms[spawnPlatformPart];
					if spawnPlatformInfo == nil or spawnPlatformInfo.Enabled ~= true then continue end;

					if spawnPlatformInfo.Load ~= 2 or spawnPlatformInfo.SpawnedAmbientZombies == true then continue end;
					spawnPlatformInfo.SpawnedAmbientZombies = true;

					local numToSpawn = math.min(
						math.random(Config.MinSpawnCount, Config.MaxSpawnCount), 
						#spawnPlatformInfo.Spawns
					);
					for a=1, numToSpawn do
						local spawnCf = spawnPlatformInfo.Spawns[a] * CFrame.new(0, 1, 0) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
						
						if #self.EnemyClassInstances <= Config.EnemyCap then
							--MARK: Platform spawn
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

			clearCharacter(playerClass.Character);
			Debugger:Warn(playerName,"died", "Players alive", #self.Characters);

			if #self.Characters <= 0 and self.Status == EnumStatus.InProgress then
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
		clearCharacter();
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
	
	shared.modEventService:OnInvoked("Doors_BindDoorToggle", function(eventPacket: EventPacket, ...)
		local doorInstance: DoorInstance = ...;
		if doorInstance == nil or doorInstance.Raided == true then return end;
		
		doorInstance.Raided = true;
		self.DoorsOpened = self.DoorsOpened +1;
		self:BeginCount();
		
		shared.Notify(
			game.Players:GetPlayers(), 
			`{self.DoorsOpened}/{#self.Doors} Doors Opened!{self.DoorsOpened == 1 and "\nThe more doors open, the more frequent hordes occur." or ""}`, 
			"Inform"
		);
		
		local hordeTimerDeduction = math.random(Config.HordeTimerDeduction.Min, Config.HordeTimerDeduction.Max);
		shared.WorldCore.HordeTimer = shared.WorldCore.HordeTimer - hordeTimerDeduction;
		if doorInstance.TriggerHorde == true then
			shared.WorldCore.HordeTimer = tick();
		end

		local nearbyNpcClasses = shared.modNpcs.listInRange(doorInstance.Model:GetPivot().Position, 32, 16);
		for a=1, #nearbyNpcClasses do
			local npcClass: NpcClass = nearbyNpcClasses[a];
			if npcClass.HealthComp.IsDead then continue end;
		
			npcClass.Properties.HordeAggression = true;
		end
	end);

	self:Start();
	
	local lastHordeScream = tick();
	task.spawn(function()
		while true do
			while self.Status ~= EnumStatus.InProgress do task.wait() end;
			repeat
				wait(1);

				if Config.HordeWhenEnemiesDropsBelow and #self.EnemyClassInstances <= Config.HordeWhenEnemiesDropsBelow and self.DoorsOpened >= math.floor(#self.Doors * 0.88) then
					shared.WorldCore.HordeTimer = tick();
				end
				
				if RunService:IsStudio() then
					Debugger:Display{
						["Studio HordeTimer"]=math.ceil((shared.WorldCore.HordeTimer -tick()));
					}
				end
			until tick() >= shared.WorldCore.HordeTimer;
			--
			while self.Status ~= EnumStatus.InProgress do task.wait(1) end;

			if tick()-lastHordeScream > 180 then
				lastHordeScream = tick();
				modAudio.Play("HordeGrowl", workspace).PlaybackSpeed = math.random(90,110)/100;
			end
			self.Wave = self.Wave +1;
			
			local hordeZombieCount = #self.Characters * 25;
			hordeZombieCount = math.max(math.min(hordeZombieCount, Config.EnemyCap-#self.EnemyClassInstances), 0);
			

			if hordeZombieCount > 0 and self.EliminateCount < self.EliminateGoal then
				for a=1, hordeZombieCount do
					
					local validSpawns = {};
					for c=1, #self.HiddenSpawns do
						if self.HiddenSpawns[c]:GetAttribute("Enabled") then
							table.insert(validSpawns, self.HiddenSpawns[c]);
						end
					end

					if #validSpawns <= 0 then break; end;
					if self.EliminateCount > self.EliminateGoal then break end;

					local closestAtt, closestDist = nil, math.huge;
					if #self.Characters > 0 then
						local targetChar = self.Characters[math.random(1, #self.Characters)];
						local charCFrame = targetChar:GetPivot();
						local player = game.Players:GetPlayerFromCharacter(targetChar);
						
	
						for b=1, 5 do
							if #validSpawns <= 0 then break end;
	
							local spawnAtt = table.remove(validSpawns, math.random(1, #validSpawns));
							local dist = player:DistanceFromCharacter(spawnAtt.WorldCFrame.Position);
	
							if charCFrame.Y > spawnAtt.WorldCFrame.Y+8 then
								dist = dist + 50;
							end
	
							if dist < closestDist then
								closestAtt = spawnAtt;
								closestDist = dist;
							end
						end

					else
						closestAtt = table.remove(validSpawns, math.random(1, #validSpawns));

					end

					if closestAtt then
						--MARK: Horde spawn
						self:SpawnEnemy(self:PickEnemy({IsHordeWave=true;}), {
							SpawnCFrame = closestAtt.WorldCFrame * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
							InfTargeting = true;
							HordeAggression = true;
						});
						
						task.wait(Config.HordeSpawnRate or 0.5);
					end
					
				end
				
			end
			
			--
			local hordeCycle = math.random(150, 200);
			if Config.HordeCycle then
				hordeCycle = Config.HordeCycle;
			end

			shared.WorldCore.HordeTimer = tick()+hordeCycle;
		end
	end)
end

function Raid:Hud(data)
	if not self.Loaded then return end;
	data = data or {};
	
	if self.HudValues == nil then
		self.HudValues = {};
	end
	
	remoteGameModeHud:FireAllClients({
		Action="Open";
		Type=self.ModeType;
		Stage=self.ModeStage;
		Header=data.Header or `Elimination`; --modBranchConfigs.GetWorldDisplayName(self.StageLib.WorldId)
		Status=data.Status or "";
		IsHard=self.IsHard;
		
		HookEntity=data.HookEntity or false;
		
		LootPrefab=self.LootPrefab;
		PlayMusic=data.PlayMusic;

		StopwatchTick = self.StopwatchTick;
		StopwatchFinal = self.StopwatchFinal;
	});
end

return Raid;
