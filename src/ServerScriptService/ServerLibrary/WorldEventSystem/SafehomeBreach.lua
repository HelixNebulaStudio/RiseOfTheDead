local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local WorldEventSystem;
local WorldEvent = {
	LastBreach = nil;
};

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modSyncTime = Debugger:Require(game.ReplicatedStorage.Library.SyncTime);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);

local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

local remoteHudNotification = modRemotesManager:Get("HudNotification");

--==
function WorldEvent.Initialize(worldEventsService)
	local breachFolder = workspace:FindFirstChild("SafehouseBreach");
	if breachFolder == nil then return false; end;
	
	WorldEventSystem = worldEventsService;
	
	WorldEvent.SpawnPrefabs = breachFolder:GetChildren();
	
	for _, prefab in pairs(WorldEvent.SpawnPrefabs) do
		prefab.Parent = nil;
	end

	modMission.OnPlayerMission:Connect(function(player, mission, context)
		if context ~= "complete" then return; end
		if mission.Id ~= 2 then return end
		if WorldEvent.LastBreach and tick()-WorldEvent.LastBreach <= 300 then return end;
		
		WorldEventSystem.NextWorldEvent = script.Name;
		WorldEventSystem.NextEventTick = modSyncTime.GetTime()+6;
	end)
	
	modOnGameEvents:ConnectEvent("OnTrigger", function(player, interactData, ...)
		local triggerTag = interactData.TriggerTag;
		if triggerTag ~= "RepairSafehouseWall" then return end;
		
		local model : Model = interactData.Object and interactData.Object.Parent;

		if model.Name ~= "SpawnHoleModel" then return end;

		local b = 0;
		for _, obj in pairs(model:GetChildren()) do
			if obj.Name == "Barricade" then
				b = b+1;
			end
		end
		
		modMission:Progress(player, 74, function(mission)
			mission.ProgressionPoint = 2;
		end)
		
		if b >= 3 then return end;

		local origin = model:GetPivot() * CFrame.new(0, math.random(-30, 30)/10, 0);

		assert(model.PrimaryPart, `Missing primary part: {model:GetFullName()}`);
		local newPart = Instance.new("Part");
		newPart.Name = "Barricade";
		newPart.Color = Color3.fromRGB(108, 88, 75);
		newPart.Material = Enum.Material.WoodPlanks;
		newPart.Anchored = true;
		newPart.Size = Vector3.new(math.random(700, 800)/100, math.random(90, 105)/100, 0.5 + (model.PrimaryPart.Size.Z-0.071));

		newPart.Parent = model;
		newPart:PivotTo(origin * CFrame.Angles(0, 0, math.rad(math.random(-20, 20)) ))
		
		local function tryDmg()
			if not workspace:IsAncestorOf(model) then return end;

			modAudio.Play("StorageWoodDrop", newPart);
			if math.random(1, 3) > 1 then
				task.delay(math.random(60,120)/10, tryDmg);
				return;
			end;

			newPart.Anchored = false;
			newPart.Color = Color3.fromRGB(62, 50, 43);
			
			game.Debris:AddItem(newPart, 20);
		end
		task.delay(math.random(380,650)/10, tryDmg)
	end)

	modOnGameEvents:ConnectEvent("OnZombieDeath", function(npcModule)
		if npcModule.SafehomeBreach == nil then return end;
		
		local playerTags = modDamageTag:Get(npcModule.Prefab, "Player");

		for a=1, #playerTags do
			local playerTag = playerTags[a];
			local player = playerTag.Player;

			modMission:Progress(player, 74, function(mission)
				mission.ProgressionPoint = 2;
			end)
		end
	end);
	
	return true;
end

function WorldEvent.Start()
	WorldEventSystem.NextEventTick = modSyncTime.GetTime() + math.random(600, 900);
	WorldEvent.LastBreach = tick();
	
	local duration = 240;
	local startTime = modSyncTime.GetTime();
	local endTime = startTime + duration;
	
	remoteHudNotification:FireAllClients("Breach", {});
	shared.Notify(game.Players:GetPlayers(), "A safehouse got breached! Quicky barricade the walls and kill the horde.", "Defeated");


	local function announceTimeLeft()
		if modSyncTime.GetTime() > endTime then return end;
		
		local timeLeft = endTime - modSyncTime.GetTime();
		if timeLeft > 60 then
			shared.Notify(game.Players:GetPlayers(), "The breach will end in "..math.ceil(timeLeft/60).." minutes!", "Defeated");
		else
			shared.Notify(game.Players:GetPlayers(), "The breach will end in "..math.floor(timeLeft).." seconds!", "Defeated");
		end
	end
	delay(duration-180, announceTimeLeft);
	delay(duration-120, announceTimeLeft);
	delay(duration-60, announceTimeLeft);

	WorldEvent.Enemies = {};
	WorldEvent.SpawnHoles = {};
	
	task.delay(duration, function()
		shared.Notify(game.Players:GetPlayers(), "The safehouse breach is now over, walls and fences are patched up.", "Defeated");
		
		for _, player in pairs(game.Players:GetPlayers()) do
			local mission = modMission:GetMission(player, 74);
			if mission and mission.ProgressionPoint == 2 then
				modMission:CompleteMission(player, 74);
			end
		end
		
		for _, spawnModel in pairs(WorldEvent.SpawnHoles) do
			spawnModel:Destroy();
		end

		table.clear(WorldEvent.Enemies)
		table.clear(WorldEvent.SpawnHoles);
	end)
	

	local spawnCount = #WorldEvent.SpawnPrefabs;
	for _, spawnHoles in pairs(WorldEvent.SpawnPrefabs) do
		local new : Model = spawnHoles:Clone();
		new.Parent=workspace.Interactables;
		table.insert(WorldEvent.SpawnHoles, new);

		task.spawn(function()
			while modSyncTime.GetTime() < endTime do
				task.wait(math.random(10, 32));
				if not workspace:IsAncestorOf(new) then return end;
				
				new.Parent=workspace.Interactables;
				
				local b = 0;
				for _, obj in pairs(new:GetChildren()) do
					if obj.Name == "Barricade" then
						b=b+1;
					end
				end
				
				if b > 0 then
					modAudio.Play("ZombieAngry"..math.random(1,2), new.PrimaryPart);
					task.wait(math.random(2, 4));
					continue;
				end
				
				local spawnPointAtt = new:FindFirstChild("SpawnPoint", true);
				
				local lowestLevel = math.huge;
				local closestPlayerDist = math.huge;
				local closestPlayer = nil;
				
				for _, player in pairs(game.Players:GetPlayers()) do
					local playerProfile = shared.modProfile:Get(player);
					if playerProfile then
						local playerSave = playerProfile:GetActiveSave();
						local playerLevel = playerSave and playerSave:GetStat("Level") or 1;
						local focusLevel = modGlobalVars.GetLevelToFocus(playerLevel);
						if focusLevel <= lowestLevel then
							lowestLevel = focusLevel;
						end
					end
					
					local distFromSpawn = player:DistanceFromCharacter(spawnPointAtt.WorldPosition);
					if distFromSpawn < closestPlayerDist then
						closestPlayerDist = distFromSpawn;
						closestPlayer = player;
					end
				end
				
				if closestPlayerDist >= 200 then continue end;
				if #WorldEvent.Enemies > spawnCount*4 then continue end;
				
				
				modNpc.Spawn("Zombie", spawnPointAtt.WorldCFrame * CFrame.new(0, 1.3, 0), function(npc, npcModule)
					npcModule.SafehomeBreach = true;
					npcModule.Properties.TargetableDistance = 320;
					npcModule.OnTarget(closestPlayer);
					
					table.insert(WorldEvent.Enemies, npcModule);
					npcModule.Configuration.Level = math.max(lowestLevel, 1);

					npcModule.Humanoid.Died:Connect(function()
						for a=#WorldEvent.Enemies, 1, -1 do
							if WorldEvent.Enemies[a] == npcModule then
								table.remove(WorldEvent.Enemies, a);
							end
						end
						npcModule.DeathPosition = npcModule.RootPart.CFrame.p;

						task.wait(5);
						game.Debris:AddItem(npc, 5);
					end);
				end);
				
			end
		end)
	end
	
end

return WorldEvent;
