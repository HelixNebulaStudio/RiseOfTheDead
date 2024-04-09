local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local random = Random.new();
--== Server Variables;
if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
end

--== Script;
local triggerPrefab = script:WaitForChild("summonTrigger");
local npcPrefabs = game.ServerStorage.PrefabStorage.Npc;
local jackReapPrefab = npcPrefabs:WaitForChild("Jack Reap");

return function(CutsceneSequence)
	if modBranchConfigs.IsWorld("TheWarehouse") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, 43);
			if mission == nil then return end;

			if not modMission:IsComplete(player, 43) and mission.ProgressionPoint < 4 then
				local jackreap = modNpc.GetPlayerNpc(player, "Jack Reap");
				if jackreap == nil then
					local npc = modNpc.Spawn("Jack Reap", nil, function(npc, npcModule)
						npcModule.Owner = player;
						jackreap = npcModule;
					end);
					modReplicationManager.ReplicateOut(player, npc);
				end
			end
		end)
		
	elseif modBranchConfigs.IsWorld("TheMall") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, 43);
			if mission == nil then return end;
			
			if not modMission:IsComplete(player, 43) then

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
							--460.647, 103.721, -701.656
							local zombieModule;
							local npc = modNpc.Spawn("Zombie", CFrame.new(440.02, 103.431, -651.14), function(npc, npcModule)
								npcModule.NetworkOwners = {player};
								npcModule.Owner = player;
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

						mission.Changed:Disconnect(OnChanged);
					end
				end
				mission.Changed:Connect(OnChanged);
				OnChanged(true, mission);
			else -- Loading Completed
				
			end
		end)
		
	end;
	return CutsceneSequence;
end;