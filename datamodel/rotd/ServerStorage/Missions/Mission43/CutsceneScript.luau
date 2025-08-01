local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

--== Variables;
local MISSION_ID = 43;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if modBranchConfigs.IsWorld("TheWarehouse") then

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			if not modMission:IsComplete(player, MISSION_ID) and mission.ProgressionPoint < 4 then
				local jackreap = modNpcs.getPlayerNpc(player, "Jack Reap");
				if jackreap == nil then
					local npc = modNpcs.spawn("Jack Reap", nil, function(npc, npcModule)
						npcModule.Player = player;
						jackreap = npcModule;
					end);
					modReplicationManager.ReplicateOut(player, npc);
				end
			end
		end)


	elseif modBranchConfigs.IsWorld("TheMall") then

		local npcPrefabs = game.ServerStorage.Prefabs.Npc;
		local triggerPrefab = script.Parent:WaitForChild("summonTrigger");
		local jackReapPrefab = npcPrefabs:WaitForChild("Jack Reap");
		
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			if modMission:IsComplete(player, MISSION_ID) then return end
		
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then

					elseif mission.ProgressionPoint == 2 then
						
					elseif mission.ProgressionPoint == 3 then
						modMission:Progress(player, 30, function(mission)
							mission.ProgressionPoint = 4;
						end)
						
					elseif mission.ProgressionPoint == 4 then
						local newSummon = triggerPrefab:Clone();
						newSummon.Parent = workspace.Interactables;
						modReplicationManager.ReplicateOut(player, newSummon);
						
					elseif mission.ProgressionPoint == 5 then
						
						local zombieModule;
						local npc = modNpcs.spawn("Zombie", CFrame.new(440.02, 103.431, -651.14), function(npc, npcModule)
							npcModule.NetworkOwners = {player};
							npcModule.Player = player;
							npcModule.FullNekron = true;
							npcModule.NekronAppearance = jackReapPrefab;
							npcModule.JackReapZombie = true;
							npcModule.ForgetEnemies = false;
							npcModule.Properties.TargetableDistance = 4096;
							npcModule.OnTarget(player);
							modAudio.Play("Creepy3", npcModule.RootPart);
							zombieModule = npcModule;
						end);
						modReplicationManager.ReplicateOut(player, npc);
						zombieModule.Movement:Move(Vector3.new(440.52, 97.691, -673.23));
						
					end
				elseif mission.Type == 3 then -- OnComplete

					mission.OnChanged:Disconnect(OnChanged);
				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);

				
		end)


	end

	
	return CutsceneSequence;
end;