local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

local random = Random.new();
--== Server Variables;
if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	
	
end

--== Script;
return function(CutsceneSequence)
	if modBranchConfigs.IsWorld("MainMenu") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		local mission = modMission:GetMission(player, 34);
		if mission == nil then return end;
		
		if not modMission:IsComplete(player, 34) then
			for a=1, 5 do
				if player.Character ~= nil then break; end;
				wait(1)
			end
			if player.Character == nil then return end;
			
			local strangerModule = modNpc.GetPlayerNpc(player, "Stranger", function(npcModule)
				return npcModule.MissionId == 34;
			end);

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						
					elseif mission.ProgressionPoint == 2 then
						if strangerModule == nil then
							local playerCframe = player.Character:GetPrimaryPartCFrame();
							local npc = modNpc.Spawn("Stranger", playerCframe, function(npc, npcModule)
								npcModule.MissionId = 34;
								npcModule.FollowingOwner = true;
								npcModule.Seed = (mission.SaveData.Seed or 1);
								npcModule.Owner = player;
								strangerModule = npcModule;
							end);
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
			mission.Changed:Connect(OnChanged);
			OnChanged(true, mission);
		else -- Loading Completed
			
		end
	end)
	
	return CutsceneSequence;
end;