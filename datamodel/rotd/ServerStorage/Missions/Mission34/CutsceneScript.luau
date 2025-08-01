local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Server Variables;
local MISSION_ID = 34;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	
end

--== Script;
return function(CutsceneSequence)
	if modBranchConfigs.IsWorld("MainMenu") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
		
		if modMission:IsComplete(player, MISSION_ID) then return end;
	
		for a=1, 5 do
			if player.Character ~= nil then break; end;
			wait(1)
		end
		if player.Character == nil then return end;
		
		local strangerModule = modNpcs.getPlayerNpc(player, "Stranger", function(npcModule)
			return npcModule.MissionId == MISSION_ID;
		end);

		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then
					
				elseif mission.ProgressionPoint == 2 then
					if strangerModule == nil then
						local playerCframe = player.Character:GetPrimaryPartCFrame();
						local npc = modNpcs.spawn(
							"Stranger", 
							playerCframe, 
							function(npc, npcModule)
								npcModule.MissionId = 34;
								npcModule.FollowingOwner = true;
								npcModule.Seed = (mission.SaveData.Seed or 1);
								npcModule.Player = player;
								strangerModule = npcModule;
							end
						);
						npc:SetAttribute("Player", player.Name);
					end
					
				elseif mission.ProgressionPoint == 3 then
					if strangerModule and strangerModule.Prefab then
						strangerModule.Immortal = 1;
						wait(1);
						strangerModule.Prefab:Destroy();
						strangerModule = nil;
					end
				end
				
			elseif mission.Type == 3 then -- OnComplete
				mission.Changed:Disconnect(OnChanged);
				if strangerModule and strangerModule.Prefab then
					strangerModule.Prefab:Destroy();
					strangerModule = nil;
				end
				
			elseif mission.Type == 4 then -- OnFail
				if strangerModule and strangerModule.Prefab then
					strangerModule.Prefab:Destroy();
					strangerModule = nil;
				end
				
			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
			
	end)
	
	return CutsceneSequence;
end;