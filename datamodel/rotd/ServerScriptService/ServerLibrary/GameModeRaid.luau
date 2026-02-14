local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Raid = {};
Raid.__index = Raid;
Raid.Active = nil;

local EnumStatus = {Initialized=-1; Restarting=0; InProgress=1; Completed=2;};
Raid.EnumStatus = EnumStatus;

local RunService: RunService = game:GetService("RunService");
local PathfindingService = game:GetService("PathfindingService");

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modTeamsManager = shared.require(game.ReplicatedStorage.Library.TeamsManager);
local modChunks = shared.require(game.ReplicatedStorage.Library.Chunks);
local modOctree = shared.require(game.ReplicatedStorage.Library.Util.Octree);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local modNpcs = shared.modNpcs;
local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

local ActiveChunks = {};
--==
local platformParam = OverlapParams.new();
platformParam.FilterType = Enum.RaycastFilterType.Include;

function Raid.onRequire()
	serverPrefabs = game.ServerStorage:WaitForChild("Prefabs"):WaitForChild("Objects");
	remoteGameModeHud = modRemotesManager:Get("GameModeHud");
end

function Raid:__newindex(k, v)
	if k == "Objective" then
		for k2, v2 in pairs(v) do
			self.Objective[k2] = v2;
		end

		return;
	end
	
	rawset(self, k, v);
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
		
		SpawnChunkCount = 0;

		Objective = {
			Id = "Eliminate";
			EliminateGoal = 100;
			EnemyCap = 35;

			SpawnsPerChunk = NumberRange.new(1, 2);
			
			HordeWhenEnemiesDropsBelow = 4;
			HordeCycle = 300;
			HordeSpawnRate = 0.5;
			HordeTimerDeduction = NumberRange.new(25, 35);
		};

		HiddenSpawns = modOctree.new();
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

		HeaderText = "";
		StatusText = "";
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

	local worldCore = shared.WorldCore;

	self.SpawnChunks = modChunks.new(shared.gameConfig.SpawnChunkSize or Vector3.new(16, 64, 16));
	self.SpawnChunkOffset = shared.gameConfig.SpawnChunkOffset or Vector3.zero;
	self.SpawnsPerChunk = shared.gameConfig.SpawnsPerChunk or NumberRange.new(1, 2);


	local tilePrototypePackages = worldCore.Script:FindFirstChild("TilePrototypePackages");
	local mapWaveCollapse = worldCore.MapWaveCollapse;
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

	local spawnPlatformFolder = Instance.new("Folder");
	spawnPlatformFolder.Name = "SpawnPlatforms";
	spawnPlatformFolder.Parent = workspace.CurrentCamera;

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
						child.Parent = spawnPlatformFolder;						
						
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
							self.HiddenSpawns:CreateNode(obj.Position, obj);
							
						end
						
					end
				end

				local tilePrototypePackage = tilePrototypePackages:FindFirstChild(tileModel.Name);
				if tilePrototypePackage then
					local tilePackage = shared.require(tilePrototypePackage);

					local tileObj = tilePackage.new(tileModel);
					tileObj:Init(self, mapWaveCollapse);
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
	local spawnsFolder = Instance.new("Folder");
	spawnsFolder.Name = "Spawns";
	spawnsFolder.Parent = workspace.CurrentCamera;

	local debugSpawnPlatforms = shared.gameConfig.DebugSpawnPlatforms == true;

	self.GameDir = workspace.Environment:FindFirstChild("Game");
	local gameDir: Folder = self.GameDir;
	if gameDir then

		for _, object: Instance in pairs(gameDir:GetChildren()) do
			if object.Name == "SpawnPlatforms" then
				for _, child in pairs(object:GetChildren()) do
					child.Parent = spawnPlatformFolder;
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
					self.HiddenSpawns:CreateNode(obj.Position, obj);
					
				end

			elseif object.Name == "StageSpawns" then
				for _, obj in pairs(object:GetChildren()) do
					if not obj:IsA("BasePart") then continue end;
					obj.Transparency = 1;
				end

			end
		end


		--MARK: Spawn Chunks
		local chunkIndex = 0;
		local chunkSize = 16;
		for _, spawnPlatform in ipairs(spawnPlatformFolder:GetDescendants()) do
			if not spawnPlatform:IsA("BasePart") then continue end;

			local center = spawnPlatform.Position;
			local size = spawnPlatform.Size/chunkSize;

			local regionSize = Vector3.new(math.max(math.floor(size.X)-1, 1), 0, math.max(math.floor(size.Z)-1, 1));
			self.SpawnChunks:GetRegion(center, regionSize);
		end
		for point, node in pairs(self.SpawnChunks.Nodes) do
			local chunk = node:GetObject();
			if chunk.init == true then continue end;
			chunk.init = true;
			self.SpawnChunkCount += 1;

			chunkIndex += 1;
			chunk.Index = chunkIndex;
			chunk.LastTouched = tick()-60;
			chunk.Points = {};
			chunk.EnemyList = {};

			if debugSpawnPlatforms == true then
				local dbPart = Debugger:PointPart(point + self.SpawnChunkOffset);
				dbPart.Size = self.SpawnChunks.Size;
				dbPart.CastShadow = false;
				dbPart.Shape = Enum.PartType.Block;
				dbPart.Transparency = 0.95;
				dbPart.Name = `Spawn_{point}`;
				dbPart.Parent = spawnsFolder;
			end

			local avgPos;
			for b=1, 5 do
				local localRandomPoint = Vector3.new(
					math.random(-chunkSize/2, chunkSize/2),
					0,
					math.random(-chunkSize/2, chunkSize/2)
				);

				local rngPoint = point + localRandomPoint + self.SpawnChunkOffset;
				local _, surfacePt = modVector.getSurface(
					{spawnPlatformFolder}, 
					rngPoint + Vector3.yAxis * (self.SpawnChunks.Size.Y/2), 
					-Vector3.yAxis * self.SpawnChunks.Size.Y
				);
				if debugSpawnPlatforms == true then
					local dbPart = Debugger:PointPart(rngPoint + Vector3.yAxis * (self.SpawnChunks.Size.Y/2));
					dbPart.Name = `({rngPoint})_{b}`;
					dbPart.Color = Color3.fromRGB(255, 0, 0);
					dbPart.Size = Vector3.one * 0.5;
					dbPart.Parent = spawnsFolder;
					
					if surfacePt then
						dbPart.CFrame = CFrame.new(surfacePt + Vector3.yAxis);
						dbPart.Color = Color3.fromRGB(0, 255, 0);
					end
				end

				if surfacePt then
					surfacePt = surfacePt + Vector3.yAxis;
					if avgPos == nil then
						avgPos = surfacePt;
					else
						avgPos = avgPos + surfacePt;
					end
					table.insert(chunk.Points, surfacePt);
				end
			end

			if avgPos then avgPos = avgPos/#chunk.Points; end;
			chunk.Position = avgPos;
		end
	end

	spawnPlatformFolder.Parent = script;
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
	if self.Status == EnumStatus.Completed then return end;
	self.Status = EnumStatus.Completed;

	workspace:SetAttribute("GameModeComplete", true);

	local runTimeStr = "";
	if self.StopwatchTick then
		local timeLapse = workspace:GetServerTimeNow()-self.StopwatchTick;
		self.StopwatchFinal = timeLapse;

		runTimeStr = ` Run time: {modSyncTime.FormatMs(timeLapse *1000)}!`;
	end

	shared.Notify(game.Players:GetPlayers(), `Raid Complete!{runTimeStr}`, "Positive");
	self:Hud{
		Status = "Raid Complete!";
		PlayMusic = false;
		EndStageSound = true;
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
	local rewardSpawnPart = workspace.Environment.Game:FindFirstChild("RewardSpawn");
	
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


		local mapWaveCollapse = shared.WorldCore.MapWaveCollapse;
		
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
		
		if rewardSpawnPart then
			spawnCf = rewardSpawnPart.CFrame;
			
		elseif closestExtractDoor then
			spawnCf = closestExtractDoor.PrimaryPart.LootSpawn.WorldCFrame;
			
		else
			Debugger:Warn("No accessible extract door");
			spawnCf = spawnLocation.LootSpawn.WorldCFrame;
			
		end
	end
	
	local rewardDropsList = {self.StageLib.RewardsId;};

	local lootPrefab = modItemDrops.spawn{
		ItemId = rewardDropsList[math.random(1, #rewardDropsList)];
		SpawnCFrame = spawnCf;
		Players = self.Players;
		DespawnDuration = false;
		Anchored = true;
		DisableTouchPickup = true;
	};
	self.LootPrefab = lootPrefab;

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

--MARK: SpawnEnemy
function Raid:SpawnEnemy(npcName, paramPacket)
	paramPacket = paramPacket or {};
	local spawnCf = paramPacket.SpawnCFrame;

	if #self.EnemyClassInstances > self.Objective.EnemyCap then
		local playerPositions = {};

		for _, player in pairs(self.Players) do
			local playerClass: PlayerClass = shared.modPlayers.get(player);
			table.insert(playerPositions, playerClass:GetCFrame().Position);
		end

		local function filterFunc(npcClass: NpcClass)
			local reRespawnThreshold = #self.EnemyClassInstances > 100 and 3 or #self.EnemyClassInstances > 50 and 6 or 9;
			if npcClass.LastRespawnTick and (tick() - npcClass.LastRespawnTick) < reRespawnThreshold then return false; end;
			if modVector.DistanceSqrdXZ(npcClass:GetCFrame().Position, spawnCf.Position) <= 4096 then return false; end;
			return npcClass.Name == npcName;
		end
		local npcClass: NpcClass = shared.modNpcs.Octree:GetFurthestNodeFromPoints(playerPositions, filterFunc) :: NpcClass;
		if npcClass then
			
			for a=#ActiveChunks, 1, -1 do
				local chunk = ActiveChunks[a];
				if chunk.EnemyList == nil or chunk.EnemyList[npcClass] == nil then continue end;

				chunk.EnemyList[npcClass] = nil;

				if next(chunk.EnemyList) == nil then
					table.remove(ActiveChunks, a);
					--Debugger:StudioLog(`Chunk ({chunk.Index}) resetted.`);
				end
				break;
			end
			if paramPacket.Chunk then
				paramPacket.Chunk.EnemyList[npcClass] = true;
			end
			npcClass:Respawn(spawnCf);

			local targetHandlerComp = npcClass:GetComponent("TargetHandler");
			if targetHandlerComp then
				for a=1, #self.Players do
					targetHandlerComp:AddTarget(self.Players[a].Character);
				end
			end
			--Debugger:StudioLog(`Respawned {npcClass.Name} ({npcClass.Id})`);
		end
	end

	if self.Objective.Id == "Eliminate" then
		if self.EliminateCount >= self.EliminateGoal then return end;
	end

	local npcClass: NpcClass = modNpcs.spawn2{
		Name = npcName;
		CFrame = spawnCf;

		BindSetup = function(npcClass: NpcClass)
			npcClass.SpawnCFrame = spawnCf;
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
			if paramPacket.Chunk then
				paramPacket.Chunk.EnemyList[npcClass] = true;
			end

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

						self.StatusText = `Eliminate {remining} enemies`;
						self:Hud({
							Status = self.StatusText;
						});
						
						if self.EliminateCount >= self.EliminateGoal then
							self:CompleteRaid();
						end

					elseif self.Objective.Id == "Objective" then
						
					end
				end

				for a=#ActiveChunks, 1, -1 do
					local chunk = ActiveChunks[a];
					if chunk.EnemyList == nil or chunk.EnemyList[npcClass] == nil then continue end;

					chunk.EnemyList[npcClass] = nil;

					-- if next(chunk.EnemyList) == nil then
					-- 	Debugger:StudioLog(`Chunk ({chunk.Index}) died.`);
					-- end
					break;
				end
			end)
		end
	};

	return npcClass;
end

function Raid:BeginCount()
	if self.Status ~= EnumStatus.InProgress then return end;
	
	if self.StageLib.EnableStopwatch == true then
		if self.StopwatchTick == nil then
			self.StopwatchTick = workspace:GetServerTimeNow();
		end
	end

	self:Hud({
		Status = self.StatusText;
		PlayMusic = true;
	});
end

--MARK: Start()
function Raid:Start()
	Debugger:StudioLog(`Initialize Raid Config`, self.Objective);

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
		
		doorInstance.Values.Raided = nil;
		doorInstance:Toggle(false);


		if doorInstance.Values.SpawnBlockade == false then continue end;
		doorInstance.Values.CanBreakIn = false;
		
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

				for _, node in ipairs(self.HiddenSpawns:GetAllNodes()) do
					local att = node:GetObject();
					if att.Name == addStageSpawn then
						att:SetAttribute("Enabled", true);
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

			for _, node in ipairs(self.HiddenSpawns:GetAllNodes()) do
				local att = node:GetObject();
				if att.Name == addStageSpawn then
					att:SetAttribute("Enabled", true);
				end
			end
		end)

		destructible.OnDestroy:Connect(function()
			local platformName = new:GetAttribute("AddSpawnPlatforms");
			if platformName == nil then return end;
			
			-- for platformPart, platformInfo in pairs(self.SpawnPlatforms) do
			-- 	if platformInfo.PlatformGroup == platformName then
			-- 		platformInfo.Enabled = true;
			-- 	end
			-- end
		end)

		destructible.OnDestroy:Connect(function(reasonData)
			local pivot = destructible.Model:GetPivot();
			local nearbyNpcClasses = shared.modNpcs.listInRange(pivot.Position, 64, 32);

			for a=1, #nearbyNpcClasses do
				local npcClass = nearbyNpcClasses[a];

				local targetHandlerComp = npcClass:GetComponent("TargetHandler");
				if targetHandlerComp == nil then continue end;

				if reasonData and reasonData.DamageBy then
					Debugger:StudioWarn(`Destroy by`, reasonData.DamageBy.Name);
					if reasonData.DamageBy.ClassName == "PlayerClass" then
						local playerClass = reasonData.DamageBy;
						targetHandlerComp:AddTarget(playerClass.Character);
					end
				end
			end

			local hordeTimerDeduction = math.random(
				self.Objective.HordeTimerDeduction.Min, 
				self.Objective.HordeTimerDeduction.Max
			);
			shared.gameConfig.HordeTimer = shared.gameConfig.HordeTimer - hordeTimerDeduction;
		end)
		
		table.insert(destructibleObjs, destructible);
	end

	for _, node in ipairs(self.HiddenSpawns:GetAllNodes()) do
		local att = node:GetObject();
		att:SetAttribute("Enabled", att.Name == "HiddenSpawn");
	end

	shared.gameConfig.HordeTimer = tick() + self.Objective.HordeCycle;

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

	self.EliminateCount = 0;
	local minTotalZombieCount = self.SpawnChunkCount * self.SpawnsPerChunk.Max;
	self.EliminateGoal = math.min(self.Objective.EnemyCap, math.max(1, math.floor(minTotalZombieCount*0.98)));

	if self.Objective.EliminateGoal then
		self.EliminateGoal = self.Objective.EliminateGoal;
	end

	if self.Objective.Id == "Eliminate" then
		self.StatusText = `Eliminate {self.EliminateGoal} enemies`;
		
	elseif self.Objective.Id == "Objective" then

	end
	
	self:Hud({
		Status = self.StatusText;
	});
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

			activeLoop = true;
			while activeLoop do
				if self.Status ~= EnumStatus.InProgress then
					task.wait(1);
					continue;
				end;

				local playerPosition = playerClass:GetCFrame().Position;

				local chunksList = self.SpawnChunks.Octree:RadiusSearch(
					playerPosition, 
					shared.gameConfig.SpawnActivateRadius or 128
				);
				local chunkAccessed = 0;
				local maxChunkAccess = 5;

				local sortedChunks = {};
				for a=1, #chunksList do
					local chunk = chunksList[a];

					chunk.LastTouched = tick();
					if chunk.Position == nil then continue end;
					
					local dist = modVector.DistanceSqrdXZ(playerPosition, chunk.Position);
					local floor = math.abs(playerPosition.Y-chunk.Position.Y)^2 *3;

					table.insert(sortedChunks, {
						Chunk = chunk;
						Dist = dist;
						Floor = floor;
					})
				end
				table.sort(sortedChunks, function(a, b)
					return (a.Dist + a.Floor) < (b.Dist + b.Floor);
				end)
				
				for _, sortData in ipairs(sortedChunks) do
					local chunk = sortData.Chunk;

					if table.find(ActiveChunks, chunk) then continue end;
					table.insert(ActiveChunks, chunk);
					
					chunkAccessed += 1;

					local pickPoints = {};
					local numToSpawn = math.min(
						math.random(self.SpawnsPerChunk.Min, self.SpawnsPerChunk.Max), 
						#chunk.Points
					);
					for a=1, numToSpawn*2 do
						local pickPoint = chunk.Points[math.random(1, #chunk.Points)];
						if pickPoint == nil then break; end;
						if table.find(pickPoints, pickPoint) == nil then
							table.insert(pickPoints, pickPoint);
						end
						if #pickPoints >= numToSpawn then break; end;
					end

					if #pickPoints > 0 then
						for a=1, #pickPoints do
							local spawnPoint: Vector3 = pickPoints[a];
							local newSpawnCf: CFrame = CFrame.new(spawnPoint) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);

							self:SpawnEnemy(self:PickEnemy(), {
								SpawnCFrame = newSpawnCf;
								Chunk = chunk;
							});
						end
					end
				end
				
				task.wait(0.1);
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
		if doorInstance == nil or doorInstance.Values.Raided == true then return end;
		
		doorInstance.Values.Raided = true;
		self.DoorsOpened = self.DoorsOpened +1;
		self:BeginCount();
		
		shared.Notify(
			game.Players:GetPlayers(), 
			`{self.DoorsOpened}/{#self.Doors} Doors Opened!{self.DoorsOpened == 1 and "\nThe more doors open, the more frequent hordes occur." or ""}`, 
			"Inform"
		);
		
		local hordeTimerDeduction = math.random(
			self.Objective.HordeTimerDeduction.Min, 
			self.Objective.HordeTimerDeduction.Max
		);
		shared.gameConfig.HordeTimer = shared.gameConfig.HordeTimer - hordeTimerDeduction;
		if doorInstance.Values.TriggerHorde == true then
			shared.gameConfig.HordeTimer = tick();
		end

		local nearbyNpcClasses = shared.modNpcs.listInRange(doorInstance.Model:GetPivot().Position, 32, 16);
		for a=1, #nearbyNpcClasses do
			local npcClass: NpcClass = nearbyNpcClasses[a];
			if npcClass.HealthComp.IsDead then continue end;
		
			npcClass.Properties.HordeAggression = true;
		end
	end);

	self:Start();
	
	task.spawn(function()
		while true do
			while self.Status ~= EnumStatus.InProgress do task.wait() end;
			repeat
				task.wait(1);

				if self.Objective.HordeWhenEnemiesDropsBelow 
				and #self.EnemyClassInstances <= self.Objective.HordeWhenEnemiesDropsBelow 
				and self.DoorsOpened >= math.floor(#self.Doors * 0.88) then
					shared.gameConfig.HordeTimer = tick();
				end
				
				if RunService:IsStudio() then
					Debugger:Display{
						["Studio HordeTimer"]=math.ceil((shared.gameConfig.HordeTimer -tick()));
						["EliminateGoal"] = self.EliminateGoal or "~";
						["EliminateCount"] = self.EliminateCount or "~";
						["LiveEnemies"] = #self.EnemyClassInstances;
					}
				end
			until tick() >= shared.gameConfig.HordeTimer;
			--
			while self.Status ~= EnumStatus.InProgress do task.wait(1) end;

			modAudio.Play("HordeGrowl", workspace).PlaybackSpeed = math.random(90,110)/100;
			self.Wave = self.Wave +1;

			for a=1, #self.Characters do
				task.spawn(function()
					shared.modNpcs.attractNpcs(self.Characters[a], 128);
				end)
			end
            
			
			local hordeZombieCount = #self.Characters * 25;
			while hordeZombieCount > 0 and self.Status == EnumStatus.InProgress do
				local targetChar = self.Characters[math.random(1, #self.Characters)];
				local characterPosition = targetChar:GetPivot().Position;

				local spawnAttsInRange = self.HiddenSpawns:RadiusSearch(characterPosition, 192);

				local validSpawnAtts = {};
				for a=1, #spawnAttsInRange do
					local spawnAtt = spawnAttsInRange[a];
					if spawnAtt:GetAttribute("Enabled") then
						local dist2 = modVector.DistanceSqrdXZ(spawnAtt.WorldCFrame.Position, characterPosition);
						local floor = math.abs(spawnAtt.WorldCFrame.Position.Y-characterPosition.Y)^2 *3;
						table.insert(validSpawnAtts, {
							Att = spawnAtt;
							Dist2 = dist2 + floor;
						});
					end
				end
				table.sort(validSpawnAtts, function(a, b)
					return a.Dist2 < b.Dist2;
				end)

				if #validSpawnAtts <= 0 then
					task.wait(1);
					continue;
				end

				local pickSpawnAtt = validSpawnAtts[1].Att;
				if #validSpawnAtts > 1 then
					pickSpawnAtt = validSpawnAtts[math.random(1, math.min(#validSpawnAtts, 3))].Att;
				end

				local spawnCf = pickSpawnAtt.WorldCFrame * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
				self:SpawnEnemy(self:PickEnemy({IsHordeWave=true;}), {
					SpawnCFrame = spawnCf;
					InfTargeting = true;
				});
				
				task.wait(self.Objective.HordeSpawnRate or 0.5);
				hordeZombieCount -= 1;
			end

			
			--
			local hordeCycle = math.random(150, 200);
			if self.Objective.HordeCycle then
				hordeCycle = self.Objective.HordeCycle;
			end

			shared.gameConfig.HordeTimer = tick()+hordeCycle;
		end
	end)
end

function Raid:Hud(data)
	if not self.Loaded then return end;
	data = data or {};
	
	if data.HeaderText then
		self.HeaderText = data.HeaderText;
	end
	if data.StatusText then
		self.StatusText = data.StatusText;
	end
	if data.RaidMarker then
		self.RaidMarker = data.RaidMarker;
	end
	if data.HookEntity then
		self.HookEntity = data.HookEntity;
	end

	remoteGameModeHud:FireAllClients({
		Action = "Open";
		Type = self.ModeType;
		Stage = self.ModeStage;
		Header = self.HeaderText or `Elimination`;
		Status = self.StatusText or "";
		IsHard = self.IsHard;
		
		
		LootPrefab = self.LootPrefab;
		PlayMusic = data.PlayMusic;
		EndStageSound = data.EndStageSound;

		StopwatchTick = self.StopwatchTick;
		StopwatchFinal = self.StopwatchFinal;

		HookEntity = self.HookEntity or false;
		RaidMarker = self.RaidMarker or false;
	});
end

return Raid;
