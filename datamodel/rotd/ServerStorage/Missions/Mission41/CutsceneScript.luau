local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 41;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);
	
	shared.modEventService:OnInvoked("Npcs_BindDeath", function(eventPacket: EventPacket, ...)
		local npcClass: NpcClass = ...;
		if npcClass == nil or npcClass.Name ~= "Cultist" then return end;
		
		local playerTags = modDamageTag:Get(npcClass.Character, "Player");
		for a=1, #playerTags do
			local playerTag = playerTags[a];
			local player: Player = playerTag.Player;
			if player == nil or not game.Players:IsAncestorOf(player) then continue end;

			local mission = modMission:GetMission(player, MISSION_ID);
			if mission.Type == 2 then
				modMission:StartMission(player, MISSION_ID);
				
			elseif mission.Type == 1 and mission.ProgressionPoint <= 2 then
				local function spawnCultistNote()
					local dropPrefab = modItemDrops.spawn{
						ItemId = "cultistnote1";
						SpawnCFrame = CFrame.new(npcClass.Properties.DeathPosition);
					};
					modReplicationManager.ReplicateIn(player, dropPrefab, workspace.Interactables);
				end
				
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 1 then
						mission.SaveData.Kills = mission.SaveData.Kills -1;
						if mission.SaveData.Kills <= 0 then
							mission.ProgressionPoint = 2;
							spawnCultistNote();	
						end
					elseif mission.ProgressionPoint == 2 then
						spawnCultistNote();	
					end;
				end)
				
			elseif mission.Type == 1 and (mission.ProgressionPoint == 4 or mission.ProgressionPoint == 5) then
				local function spawnCultistHood()
					local dropPrefab = modItemDrops.spawn{
						ItemId = "cultisthood";
						SpawnCFrame = CFrame.new(npcClass.Properties.DeathPosition);
					};
					modReplicationManager.ReplicateIn(player, dropPrefab, workspace.Interactables);
				end
				
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 4 then
						mission.ProgressionPoint = 5;
					end;
				end)
				spawnCultistHood();	
				
			end

		end
	end)

	shared.modEventService:OnInvoked("Generic_BindItemPickup", function(eventPacket: EventPacket, ...)
		local player: Player? = eventPacket.Player;
		if player == nil then return end;

		local interactable: InteractableInstance = ...;
		local itemId = interactable.Values.ItemId;

		if itemId == "cultistnote1" then
			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint < 3 then
					mission.ProgressionPoint = 3;
				end;
			end)

		elseif itemId == "cultisthood" then
			modMission:CompleteMission(player, MISSION_ID);
			
		end
	end)

else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if modBranchConfigs.WorldInfo.Type ~= modBranchConfigs.WorldTypes.General then return end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		local playerClass: PlayerClass = shared.modPlayers.get(player);

		task.spawn(function()
			local isOldMission = (os.time()-mission.StartTime) >= (3600*72);
			while player:IsDescendantOf(game.Players) do
				task.wait(mission.Type ~= 3 and 35 or math.random(600, 900));

				if not player:IsDescendantOf(game.Players) then continue end;
				if isOldMission and math.random(1, 4) >= 2 then continue end;

				if mission.ProgressionPoint <= 2
				or (mission.Type == 1 and mission.ProgressionPoint == 4
				or mission.ProgressionPoint == 5) then
					
					if playerClass.Properties.LastDoorCFrame 
					and not playerClass.HealthComp.IsDead 
					and playerClass.Properties.InBossBattle == nil then
						if mission.Type == 3 then
							shared.Notify(player, "You spotted a Cultist doing something suspicious, the Cultist also spots you.", "Important");
						end
						
						shared.modNpcs.spawn2{
							Name = "Cultist";
							CFrame = playerClass.Properties.LastDoorCFrame;
						};
					end
				end
			end
		end)
		
	end)
	
	return CutsceneSequence;
end;