local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
while shared.MasterScriptInit  ~= true do task.wait() end;
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local modNpc = Debugger:Require(game.ServerScriptService.ServerLibrary.Entity.Npc);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

local spawnerFolder = workspace:WaitForChild("Spawners");

local activeSpawners = {};
local spawnHistory = {};
--== Script;

function PlayerUpdate(player)
	local character = player.Character;
	
	local classPlayer = modPlayers.GetByName(player.Name);
	if classPlayer == nil then return end;
	
	local nightOwlSkill = classPlayer and classPlayer.Properties and classPlayer.Properties.nigowl and 1-((classPlayer.Properties.nigowl.Percent or 100)/100);
	local bunnymanHead = classPlayer and classPlayer.Properties and classPlayer.Properties.bunnyman;
	
	local range = classPlayer.EnemyDetectionRange or 50;
	if nightOwlSkill then range = range * nightOwlSkill end;
	
	local selectedTargets = modNpc.AttractEnemies(character, range, function(modNpcModule)
		if modNpcModule and modNpcModule.OnAttracted then
			return modNpcModule.OnAttracted(character);
		end
		
		if modNpcModule.Humanoid.Name == "Zombie" and bunnymanHead then return false end;
		return modNpcModule.Properties == nil or modNpcModule.Properties.Hostile ~= false;
		-- when return true, add to selected targets;
	end);
	
	if selectedTargets and #selectedTargets > 0 then
		local npcs = modNpc.GetPlayerNpcList(player);
		for a=1, #npcs do
			if npcs[a].Prefab == selectedTargets[1] then continue end;
			npcs[a].Target = selectedTargets[1];
		end
	end

	modOnGameEvents:Fire("OnEnemiesAttract", player, selectedTargets);
end

function OnPlayerAdded(player)
	task.spawn(function()
		task.wait(RunService:IsStudio() and 3 or 10);
		while game.Players:IsAncestorOf(player) do
			PlayerUpdate(player);
			task.wait(0.2 + (0.125*(#game.Players:GetPlayers()-1)) )
		end
	end)
end

local modEngineCore = require(game.ReplicatedStorage.EngineCore);
modEngineCore:ConnectOnPlayerAdded(script, OnPlayerAdded)

task.spawn(function()
	while true do
		task.wait(1);

		for a=1, #activeSpawners do
			activeSpawners[a]:RequestSpawn();
		end
	end
end)

local SpawnTypeSpacing = {
	Zombie=8;
}

function InitializeSpawner(spawnerModule)
	local spawnArea = {};
	
	local spawnPart = spawnerModule.Parent;
	if spawnPart:IsA("BasePart") then
		spawnArea.Name = spawnPart.Name;
		spawnArea.CFrame = spawnPart.CFrame;
		spawnArea.Size = spawnPart.Size;
		spawnArea.Position = spawnPart.Position;
	else
		error("NPCService>> Spawner is not a BasePart");
	end
	local group = spawnArea.Name;
	
	local spawnerObject;
	if spawnerModule:IsA("ModuleScript") then
		spawnerModule = spawnerModule:Clone();
		spawnerModule.Parent = script;
		spawnerObject = require(spawnerModule);
		
	else
		game.Debris:AddItem(spawnPart, 1);
		warn("Spawner (",group,") failed to initialize");
		return;
	end
	
	local defaultMaxAmount = spawnerObject.MaxAmount or 1;
	
	local spaceCheckOverlapParam = OverlapParams.new();
	spaceCheckOverlapParam.FilterType = Enum.RaycastFilterType.Include;
	spaceCheckOverlapParam.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};
	spaceCheckOverlapParam.MaxParts = 1;
	spaceCheckOverlapParam.RespectCanCollide = true;
	
	spawnerObject.Active = {};
	spawnerObject.SpawnSearch = function(self)
		local targetPoint = Vector3.new(
			math.random(self.SpawnRegion.Min.X*10, self.SpawnRegion.Max.X*10)/10,
			self.SpawnRegion.Max.Y,
			math.random(self.SpawnRegion.Min.Z*10, self.SpawnRegion.Max.Z*10)/10
		);

		local groundRay = Ray.new(targetPoint, Vector3.new(0, -(self.SpawnRegion.Max.Y-self.SpawnRegion.Min.Y), 0));
		local groundHit, groundPoint = workspace:FindPartOnRayWithWhitelist(groundRay, {workspace.Environment; workspace.Terrain}, false);

		if groundHit then
			targetPoint = Vector3.new(targetPoint.X, groundPoint.Y+self.HumanoidInfo.HipHeight+0.125, targetPoint.Z);
		end;
		
		local targetCFrame = CFrame.new(targetPoint) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
		--local spawnMin = targetPoint - targetCFrame:vectorToWorldSpace(self.SpawnSize/2) + Vector3.yAxis;
		--local spawnMax = targetPoint + targetCFrame:vectorToWorldSpace(self.SpawnSize/2);
		--local collisions = workspace:FindPartsInRegion3WithWhiteList(Region3.new(spawnMin, spawnMax), {workspace.Environment; workspace.Terrain}, 1);
		local collisions = workspace:GetPartBoundsInBox(targetCFrame + Vector3.new(0, self.SpawnSize.Y/2+0.2, 0), self.SpawnSize, spaceCheckOverlapParam);
		
		if #collisions > 0 then return nil end
		return targetCFrame;
	end
	
	spawnerObject.Spawn = function(self, cframe)
		while script:GetAttribute("DisableSpawning") == true do
			task.wait(1);
		end
		
		local customNpcModule = spawnerObject.ModuleName and modNpc.NpcBaseModules[spawnerObject.ModuleName]; 
		
		local spawnType = self.SpawnType;

		if modConfigurations.SpecialEvent.Halloween then
			if math.random(1, 100) == 1 then
				spawnType = "Wraith";
			end
		end

		modNpc.Spawn(spawnType, cframe, function(npc, npcModule)
			npc:SetAttribute("NaturalSpawn", true);
			table.insert(self.Active, npcModule);
			
			local modMapLibrary = require(game.ReplicatedStorage.Library.MapLibrary);
			local layerName = modMapLibrary:GetLayer(cframe.Position);
			npcModule.MapLayerName = layerName;
			
			if self.OnSpawnConfigure then
				local s, e = pcall(function()
					self.OnSpawnConfigure(npc, npcModule);
				end)
				if not s then
					Debugger:Warn("Spawner", spawnPart:GetFullName());
					error(e);
				end
				
				-- if npcModule and npcModule.Configuration and npcModule.Configuration.Level then
				-- 	enemyLevel = npcModule.Configuration.Level;
				-- end
			end
			
			local humanoid: Humanoid = npcModule.Humanoid;
			humanoid:GetAttributeChangedSignal("IsDead"):Connect(function()
				if humanoid:GetAttribute("IsDead") ~= true then return end;

				npcModule = nil;

				task.wait(self.RespawnTimer or 10);

				for a=#self.Active, 1, -1 do
					local npcModule = self.Active[a];
					if npcModule.IsDead or npcModule.Prefab == nil then
						table.remove(self.Active, a);
					end
				end
			end)
			
			CollectionService:AddTag(npc:WaitForChild("HumanoidRootPart"), "SpawnerRootParts");
		end, customNpcModule);
	end
	
	spawnerObject.Activate = function(self)
		if self.Destroyed then return end;
		local spawnCframe = self:SpawnSearch();
		if spawnCframe == nil then return end;
		
		self:Spawn(spawnCframe);
		
		table.insert(spawnHistory, spawnCframe);
		if #spawnHistory >= 100 then
			table.remove(spawnHistory, 1);
		end
	end;
	
	spawnerObject.Destroy = function(self)
		self.Destroyed = true;
		for a=#self.Active, 1, -1 do
			if self.Active[a] == nil then continue end;
			
			local humanoid = self.Active[a]:FindFirstChildWhichIsA("Humanoid");
			if humanoid and humanoid.Health > 0 then
				self.Active[a]:Destroy();
			end
		end
		task.wait(30);
		self = nil;
	end
	
	spawnerObject.Initialize = function(self)
		local prefab = modNpc.GetNpcPrefab(self.SpawnType);
		if prefab == nil then error("The prefab of "..self.SpawnType.." does not exist."); end;
		
		self.Destroyed = false;
		-- Npc Size
		self.Prefab = prefab;
		self.SpawnSize = prefab:GetExtentsSize();
		self.HumanoidInfo = prefab:FindFirstChildWhichIsA("Humanoid");
		
		local spawnAreaSize = spawnArea.Size;
		local spawnSpace = Vector2.new(spawnAreaSize.X,spawnAreaSize.Z) / Vector2.new(self.SpawnSize.X, self.SpawnSize.Z);

		local spawnTypeSpacing = SpawnTypeSpacing[self.SpawnType] or 32;
		self.MaxSpawnSpaceAmount = math.ceil(math.ceil(spawnSpace.X) * math.ceil(spawnSpace.Y) / math.pow(spawnTypeSpacing,2) );
		
		-- Initialize spawn region
		local worldSpaceSize = spawnArea.CFrame:vectorToWorldSpace(spawnArea.Size);
		worldSpaceSize = Vector3.new(math.abs(worldSpaceSize.X), math.abs(worldSpaceSize.Y), math.abs(worldSpaceSize.Z));
		
		local pointMin = spawnArea.Position - worldSpaceSize/2;
		local pointMax = spawnArea.Position + worldSpaceSize/2;
		self.SpawnRegion = {Min=pointMin; Max=pointMax;};
		
		-- Optimizer
		self.Position = spawnArea.Position;
	end
	

	spawnerObject.IsSpawning = tick()-1;
	spawnerObject.RequestSpawn = function(self)
		if self.IsSpawning > tick() then return end;
		local playerCount = #game.Players:GetPlayers();
		if playerCount <= 0 and spawnerObject.ForceMin ~= true then return end;
		
		self.IsSpawning = tick()+1;
		
		local naturalSpawnLimit = modConfigurations.NaturalSpawnLimit or 999;
		task.spawn(function()
			if workspace:GetAttribute("PlayerCount") then
				playerCount = workspace:GetAttribute("PlayerCount");
			else
				playerCount = math.max(playerCount, 3);
				if modBranchConfigs.CurrentBranch.Name == "Dev" then
					playerCount = game.Players.MaxPlayers;
				end
			end

			local minCount = math.max(self.MinAmount or 1, self.MinAmount == nil and math.floor(defaultMaxAmount/2) or 0);
			local maxCount = math.max(self.MaxSpawnSpaceAmount, defaultMaxAmount, minCount)
			local setCount = math.ceil(playerCount/game.Players.MaxPlayers * (maxCount-minCount));

			self.MaxAmount = math.clamp(setCount, minCount, maxCount);

			local respawnAmt = (self.MaxAmount - #self.Active);

			if #modNpc.ListEntities(self.SpawnType) > naturalSpawnLimit and #self.Active > minCount then
				respawnAmt = 0;
			end

			if respawnAmt > 0 then
				for a=1, respawnAmt do
					self:Activate();
					task.wait();
					self.IsSpawning = tick()+1;
					if #modNpc.NpcModules > naturalSpawnLimit then break; end;
				end
			end;
			
		end)
	end
	
	if spawnPart then spawnPart:Destroy(); end
	spawnerObject:Initialize();
	
	table.insert(activeSpawners, spawnerObject);
end

if game.ServerStorage:FindFirstChild("Spawners") == nil then
	local new = spawnerFolder:Clone();
	new.Parent = game.ServerStorage;
else
	spawnerFolder:ClearAllChildren();
	spawnerFolder = game.ServerStorage.Spawners:Clone();
end

function onDayChanged()
	if modBranchConfigs.NavLinks then
		--== Wanderer Spawn;
		task.spawn(function()
			local day = workspace:GetAttribute("DayOfYear");
			local spawnWorldList = {};
			
			for worldId, worldNav in pairs(modBranchConfigs.NavLinks) do
				table.insert(spawnWorldList, {Id=worldId; Nav=worldNav});
			end
			
			local wandererList = {
				"Icarus";
			};
			
			local spawnWorld = spawnWorldList[math.fmod(day, #spawnWorldList)+1];
			if modBranchConfigs.CurrentBranch.Name == "Dev" or modBranchConfigs.IsWorld("BioXResearch") then
				spawnWorld = {Id=modBranchConfigs.GetWorld(); Nav=modBranchConfigs.NavLinks[modBranchConfigs.GetWorld()]};
			end
			
			if spawnWorld.Nav then
				local spawnWandererName = wandererList[math.fmod(day, #wandererList)+1];
				local spawnNavId = nil;
				
				for navLocation, info in pairs(spawnWorld.Nav) do
					if info.Safehouse == true then
						spawnNavId = navLocation;
						break;
					end
				end
				
				Debugger:Log("Wanderer (",spawnWandererName,") Spawn World:",spawnWorld.Id, " Spawn safehouse:", spawnWorld.Nav[spawnNavId]);
				
				for a=#modNpc.NpcModules, 1, -1 do
					local npcModule = modNpc.NpcModules[a] and modNpc.NpcModules[a].Module;
					if npcModule and npcModule.WanderingTrader then
						if npcModule.Prefab then
							game.Debris:AddItem(npcModule.Prefab, 0);
						end
						npcModule:Destroy();
					end
				end
				
				if modBranchConfigs.IsWorld(spawnWorld.Id) then
					local doorInstance = workspace.Interactables:FindFirstChild(spawnWorld.Nav[spawnNavId].Entrance);
					
					local spawnCFrame = CFrame.new(doorInstance.Destination.WorldPosition + Vector3.new(0, 2.35, 0)) 
						* CFrame.Angles(0, math.rad(doorInstance.Destination.WorldOrientation.Y-90), 0);
					
					modNpc.Spawn(spawnWandererName, spawnCFrame, function(npc, npcModule)
						npcModule.CurrentNav = spawnNavId;
						
					end, modNpc.NpcBaseModules.WanderingTrader);
				end

				modBranchConfigs.Wanderer = {
					Name=spawnWandererName;
					WorldId=spawnWorld.Id;
				};
				
			end
		end)
	end
end


workspace:GetAttributeChangedSignal("DayOfYear"):Connect(onDayChanged);
game.Players.PlayerAdded:Connect(onDayChanged);


local spawnDescendants = spawnerFolder:GetDescendants();
for a=1, #spawnDescendants do
	local spawnerModule = spawnDescendants[a];
	if spawnerModule.ClassName == "ModuleScript" then
		InitializeSpawner(spawnerModule);
	end
end


task.spawn(function()
	Debugger.AwaitShared("modCommandsLibrary");

	shared.modCommandsLibrary:HookChatCommand("npcservice", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
		Description = [[
			/npcservice setnaturallimit [85]
		]];

		RequiredArgs = 0;
		Function = function(speaker, args)
			
			local action = args[1] or 999;
			
			if action == "setnaturallimit" then
				local setlimit = args[2] or 999;
				
				modConfigurations.Set("NaturalSpawnLimit", setlimit);
				shared.Notify(speaker, `Set world natural spawm limit to {modConfigurations.NaturalSpawnLimit}.`, "Inform");

			else
				shared.Notify(speaker, "Unknown action for /npcservice", "Negative");

			end

			return;
		end;
	});

end)
