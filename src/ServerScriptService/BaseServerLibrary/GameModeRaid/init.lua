local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Config = {
	EnemyCap=300;
	
	SpawnRadius=128;
	MinSpawnCount=2;
	MaxSpawnCount=3;
}

local Raid = {};
Raid.__index = Raid;
Raid.Active = nil;

local EnumStatus = {Initialized=-1; Restarting=0; InProgress=1; Completed=2;};
Raid.EnumStatus = EnumStatus;

local PathfindingService = game:GetService("PathfindingService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modInteractables = require(game.ReplicatedStorage.Library.Interactables);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGameModeLibrary = require(game.ReplicatedStorage.Library.GameModeLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modDoors = require(game.ReplicatedStorage.Library.Doors);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);

local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
local modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);

local remoteGameModeHud = modRemotesManager:Get("GameModeHud");
local remoteDoorInteraction = modRemotesManager:Get("DoorInteraction");

local environmentFolder = workspace:WaitForChild("Environment");
local extractInteractable = script:WaitForChild("ExtractInteractable");

local random = Random.new();
--==
-- modEventSignal.new("OnWaveChanged");

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
		
		Doors = {};
		ExtractDoors = {};
		
		Characters = {};
		EnemyModules = {};
		
		Path = PathfindingService:CreatePath();
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

	local mapWaveCollapse = shared.RaidMapWC;
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
		
		for _, model in pairs(collapseMap:GetChildren()) do
			if model:FindFirstChild("Layout") then
				for _, child in pairs(model.Layout:GetChildren()) do
					if child:FindFirstChild("Door") and child.Door:IsA("ModuleScript") then

						local doorObject = modDoors:GetDoor(child);
						table.insert(self.Doors, doorObject);
						
					elseif child.Name == "SpawnPlatform" then
						self.SpawnPlatforms[child] = {
							Name=model.Name;
							Part=child;
							Index=(child:GetAttribute("Index") or 999);
							Spawns={};
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
							if obj.Name == "HiddenSpawn" and obj:IsA("Attachment") then
								table.insert(self.HiddenSpawns, obj);
							end
						end
						
					elseif child.Name == "TileModule" then
						local tileObj = require(child);
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
			
			local newInteractable = extractInteractable:Clone();
			newInteractable.Name = "Interactable";
			newInteractable.Parent = extractDoors[a].Prefab;
			
		end
		
	end
	self.Loaded = true;

	task.spawn(function()
		local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);

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

				local classPlayer = shared.modPlayers.Get(player);
				
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
	self.Status = EnumStatus.Completed;
	shared.Notify(game.Players:GetPlayers(), "Raid Complete!", "Positive");
	self:Hud{
		Status="Raid Complete!";
		PlayMusic=false;
	};

	self:RespawnDead();
	task.wait(1);

	self:DropReward();

end

function Raid:RespawnDead()
	for _, player in pairs(self.Players) do
		if player == nil or not player:IsDescendantOf(game.Players) then continue end;
		
		local classPlayer = shared.modPlayers.Get(player);
		if classPlayer.IsAlive then continue end;
		
		classPlayer:Spawn();
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


		local mapWaveCollapse = shared.RaidMapWC;
		
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
	paramPacket = paramPacket or {};

	local spawnCf = paramPacket.SpawnCFrame;
	
	if self.OnNpcSpawnHooked == nil then
		self.OnNpcSpawnHooked = modNpc.OnNpcSpawn:Connect(function(npcModule)
			if modConfigurations.TargetableEntities[npcModule.Humanoid.Name] == nil then return end; -- Not enemy spawn;

			local npcPrefab = npcModule.Prefab;
			table.insert(self.EnemyModules, npcModule);

			npcModule.Garbage:Tag(function()
				for a=#self.EnemyModules, 1, -1 do
					if self.EnemyModules[a] == npcModule then
						table.remove(self.EnemyModules, a);
						break;
					end
				end
			end)

			npcModule.Humanoid.Died:Connect(function()
				self.LastKilled = tick();
				for a=#self.EnemyModules, 1, -1 do
					if self.EnemyModules[a] == npcModule then
						table.remove(self.EnemyModules, a);
						break;
					end
				end

				npcModule.DeathPosition = npcModule.RootPart.CFrame.p;

				self.LastEnemyDeathPos = npcModule.DeathPosition;
				
				self.EliminateCount = self.EliminateCount +1;
				
				if self.Status == EnumStatus.InProgress then
					
					if self.Objective.Id == "Eliminate" then
						local remining = math.max(0, self.EliminateGoal - self.EliminateCount);
						self:Hud({
							Status="Eliminate "..remining.." enemies.";
						});
						
						if self.EliminateCount >= self.EliminateGoal then
							self:CompleteRaid();
						end
					end
					
				end
			end);
		end)
	end

	local newNpcModule;
	local npcPrefab = modNpc.Spawn(npcName, spawnCf, function(npcPrefab, npcModule)
		self.EnemiesSpawned = self.EnemiesSpawned + 1;
		
		Debugger:Warn("self.EnemyModules", #self.EnemyModules, "self.EnemiesSpawned", self.EnemiesSpawned);
		newNpcModule = npcModule;

		npcModule.Configuration.Level = math.max(npcModule.Configuration.Level + (self.Difficulty + (self.Wave-1)) + math.random(-2, 0), 1);
		npcModule.Properties.TargetableDistance = 256;
		npcModule.NetworkOwners = game.Players:GetPlayers();
		
		if paramPacket.InfTargeting then
			npcModule.SetAggression = 3;
			npcModule.InfTargeting = true;
			npcModule.AutoSearch = true;
			npcModule.ForgetEnemies = false;
			npcModule.Properties.TargetableDistance = 4096;

			npcModule.OnTarget(self.Players);
		end
		
		
		if npcName == "Pathoroth" then
			local newHealth = 4000 * math.max(math.ceil(self.Difficulty/2) + math.ceil(self.Wave/2), 1);
			npcModule.Humanoid.MaxHealth = math.clamp(newHealth, 1000, math.huge);
			npcModule.Humanoid.Health = npcModule.Humanoid.MaxHealth;
		end

		if self.OnEnemySpawn then self:OnEnemySpawn(npcPrefab, npcModule); end
	end);

	return npcPrefab, newNpcModule;
end


local blockadeFolder = game.ReplicatedStorage.DefaultBlockades;
function Raid:Start()
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

	self.Difficulty = math.clamp(highestLevel, 1, math.huge);
	--
	
	for a=1, #self.DynamicMap do
		local dynamicMapPart = self.DynamicMap[a];
		dynamicMapPart.Color = Color3.fromRGB(90, 90, 90);
	end

	--
	local destructibleObjs = {};
	
	for a=1, #self.Doors do
		local doorObject = self.Doors[a];
		
		doorObject.Raided = nil;
		doorObject.CanBreakIn = false;
		doorObject:Toggle(false);
		
		local blockadeId = "BlockadeSingle";
		if doorObject.WidthType == "Double" then
			blockadeId = "BlockadeDouble";
		end
		
		for _, obj in pairs(doorObject.Prefab:GetChildren()) do
			if obj.Name == "Blockade" then
				game.Debris:AddItem(obj, 0);
			end
		end
		
		local new = blockadeFolder[blockadeId]:Clone();
		new.Name = "Blockade";
		new:PivotTo(doorObject.Prefab:GetPivot());
		new.Parent = doorObject.Prefab;
		
		local destructibleObj = require(new:WaitForChild("Destructible"));
		destructibleObj.Enabled = false;
		table.insert(destructibleObjs, destructibleObj);
	end
	
	local spawnPlatformCount = 0;
	for spawnPart, spawnInfo in pairs(self.SpawnPlatforms) do
		spawnInfo.SpawnedAmbientZombies = nil;
		spawnPlatformCount = spawnPlatformCount +1;
	end
	
	local minTotalZombieCount = spawnPlatformCount * Config.MinSpawnCount;
	
	self.EliminateCount = 0;
	self.EliminateGoal = math.min(Config.EnemyCap, math.max(1, math.floor(minTotalZombieCount*0.98)));
	
	if self.Objective.Id == "Eliminate" then
	end

	for a=5, 1, -1 do
		self:Hud({
			Status="Raid is starting in "..a.."s.."
		})
		task.wait(1);
	end
	
	for a=1, #destructibleObjs do
		local destructibleObj = destructibleObjs[a];
		destructibleObj.Enabled = true;
	end

	shared.HordeTimer = tick()+300;
	self.Status = EnumStatus.InProgress;

	self:Hud({
		Status="Eliminate "..self.EliminateGoal.." enemies.";
		PlayMusic=true;
	})
end

local spawnCfCaches = {};
function Raid:LoadSpawnPlatform(spawnPart)
	local spawnPlatformInfo = self.SpawnPlatforms[spawnPart];
	
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
			
			local loadTimelapsed = tick();
			while newSpawnCFrame == nil do
				newSpawnCFrame = platformTopCf * CFrame.new(
					random:NextNumber(-worldSpaceSize.X/2, worldSpaceSize.X/2), 
					0, 
					random:NextNumber(-worldSpaceSize.Z/2, worldSpaceSize.Z/2));

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

function Raid:Initialize(roomData)
	repeat task.wait() until self.Loaded == true;
	
	modConfigurations.Set("InfTargeting", false);
	
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

	local function onCharacterAdded(player, character)
		clearCharacter(character);
		table.insert(self.Characters, character);

		local activeLoop = true;
		local classPlayer = shared.modPlayers.Get(player);

		local humanoid = character:WaitForChild("Humanoid");
		classPlayer:OnNotIsAlive(function(character)
			activeLoop = false;
			
			Debugger:Log(character.Name,"died");
			shared.Notify(game.Players:GetPlayers(), character.Name .. " died!", "Negative");

			clearCharacter(character);
			Debugger:Log("Players alive",#self.Characters);

			if #self.Characters <= 0 and self.Status == EnumStatus.InProgress then

				self.Status = EnumStatus.Restarting;
				
				for a=#self.EnemyModules, 1, -1 do
					game.Debris:AddItem(self.EnemyModules[a].Prefab, 0);
					table.remove(self.EnemyModules, a);
				end
				
				shared.Notify(game.Players:GetPlayers(), "Raid failed!", "Negative");
				
				for a=5, 1, -1 do
					self:Hud{
						Header="Raid failed!";
						Status="Restarting in "..a.."..";
						PlayMusic=false;
					};
					
					shared.Notify(game.Players:GetPlayers(), "Restarting in "..a.."..", "Negative", "ModeRestarting");
					task.wait(1);
				end
				
				self:RespawnDead();
				self:Start();

			else
				self:Hud{
					Header="You died!";
					Status="";
				};

			end
		end)
		
		local wlInstances = {};
		for part, _ in pairs(self.SpawnPlatforms) do
			table.insert(wlInstances, part);
		end
		
		local platformParam = OverlapParams.new();
		platformParam.FilterDescendantsInstances = wlInstances;
		platformParam.FilterType = Enum.RaycastFilterType.Include;

		local rootPart = character:WaitForChild("HumanoidRootPart");
		task.spawn(function()
			while activeLoop do
				
				if self.Status == EnumStatus.InProgress then
					local hitList = workspace:GetPartBoundsInRadius(rootPart.Position, Config.SpawnRadius, platformParam);
					
					for a=1, #hitList do
						local spawnPlatformPart = hitList[a];

						self:LoadSpawnPlatform(spawnPlatformPart);

						local spawnPlatformInfo = self.SpawnPlatforms[spawnPlatformPart];
						if spawnPlatformInfo.Load == 2 and spawnPlatformInfo.SpawnedAmbientZombies ~= true then
							spawnPlatformInfo.SpawnedAmbientZombies = true;

							for a=1, math.min(math.random(Config.MinSpawnCount, Config.MaxSpawnCount), #spawnPlatformInfo.Spawns) do
								local spawnCf = spawnPlatformInfo.Spawns[a] * CFrame.Angles(0, math.rad(0, 360, 0), 0);
								
								if #self.EnemyModules > Config.EnemyCap then
									for a=1, 4 do
										local chosenNpcModule;
										
										for b=1, 3 do
											chosenNpcModule = self.EnemyModules[math.random(1, #self.EnemyModules)]
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
									
									
								else
									self:SpawnEnemy(self:PickEnemy(), {SpawnCFrame=spawnCf;});
									
								end
							end
						end
					end
					
				end
				
				task.wait(1);
			end
		end)
	end
	
	for a=1, #self.RoomData.Players do
		task.delay(0.1, function()
			local player;
			repeat
				player = game.Players:FindFirstChild(self.RoomData.Players[a].Name);
				task.wait(1);
			until player ~= nil;

			player.CharacterAdded:Connect(function(character) onCharacterAdded(player, character) end);
			
			local classPlayer = shared.modPlayers.Get(player);
			if not classPlayer.IsAlive then 
				classPlayer:Spawn();
			end;

			table.insert(self.Players, player);
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

	for a=1, 10 do
		local waitMsg = ("Waiting for ("..#self.Players.."/"..#roomData.Players..") players.. ($t)"):gsub("$t", 10-a);
		shared.Notify(game.Players:GetPlayers(), waitMsg, "Inform", "waitForPlayers");

		if #self.Players >= #self.RoomData.Players then
			break;
		else
			task.wait(1);
		end
	end
	
	modInteractables:SyncAll();

	remoteDoorInteraction.OnServerEvent:Connect(function(player, prefab)
		local doorObject = modDoors:GetDoor(prefab);
		if doorObject == nil or doorObject.Raided == true then return end;
		
		doorObject.Raided = true;
		self.DoorsOpened = self.DoorsOpened +1;
		
		Debugger:Warn("#self.Doors Opened (".. self.DoorsOpened .."/".. #self.Doors ..")");
		--shared.Notify(game.Players:GetPlayers(), "Doors opened: ".. (self.DoorsOpened.."/"..#self.Doors) , "Inform");
		
		shared.HordeTimer = shared.HordeTimer - math.random(20, 40);
		
		local nearbyNpcModules = modNpc.EntityScan(doorObject.Prefab:GetPivot().Position, 64, 32);
		for a=1, #nearbyNpcModules do
			local npcModule = nearbyNpcModules[a];

			npcModule.OnTarget(player);
		end
	end);

	self:Start();
	
	task.spawn(function()
		while true do
			while self.Status ~= EnumStatus.InProgress do task.wait() end;
			repeat
				wait(1);
				
				--Debugger:Display{
				--	HordeTimer=math.ceil((shared.HordeTimer -tick()));
				--}
			until tick() >= shared.HordeTimer;
			--
			while self.Status ~= EnumStatus.InProgress do task.wait(1) end;

			modAudio.Play("HordeGrowl", workspace);
			self.Wave = self.Wave +1;
			
			local hordeZombieCount = #self.Characters * 25;
			hordeZombieCount = math.max(math.min(hordeZombieCount, Config.EnemyCap-#self.EnemyModules), 0);
			
			if hordeZombieCount > 0 then
				for a=1, hordeZombieCount do
					local targetChar = self.Characters[math.random(1, #self.Characters)];
					local player = game.Players:GetPlayerFromCharacter(targetChar);
					
					for b=1, 4 do
						local spawnAtt = self.HiddenSpawns[math.random(1, #self.HiddenSpawns)];
						
						if player:DistanceFromCharacter(spawnAtt.WorldCFrame.Position) <= 128 then
							self:SpawnEnemy(self:PickEnemy({IsHordeWave=true;}), {
								SpawnCFrame=spawnAtt.WorldCFrame * CFrame.Angles(0, math.rad(0, 360), 0);
								InfTargeting=true;
							});
							
							task.wait(0.5);
							break;
						end
					end
				end
				
			end
			
			--
			shared.HordeTimer = tick()+ math.random(150, 200);
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
		Header=data.Header or modBranchConfigs.GetWorldDisplayName(self.StageLib.WorldId);
		Status=data.Status or "";
		IsHard=self.IsHard;
		
		HookEntity=data.HookEntity or false;
		
		LootPrefab=self.LootPrefab;
		PlayMusic=data.PlayMusic;
	});
end

return Raid;
