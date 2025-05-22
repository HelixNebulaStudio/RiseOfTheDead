local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 41;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
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
			
		task.spawn(function()
			local classPlayer = shared.modPlayers.get(player);
			local profile = shared.modProfile:Get(player);
			
			local isOldMission = (os.time()-mission.StartTime) >= (3600*72);
			while player:IsDescendantOf(game.Players) do
				wait(mission.Type ~= 3 and 35 or math.random(600, 900));

				if not player:IsDescendantOf(game.Players) then continue end;
				if isOldMission and math.random(1, 4) >= 2 then continue end;

				if mission.ProgressionPoint <= 2
				or (mission.Type == 1 and mission.ProgressionPoint == 4
				or mission.ProgressionPoint == 5) then
					
					if profile and profile.LastDoorCFrame and classPlayer and classPlayer.IsAlive and classPlayer.Properties.InBossBattle == nil then
						if mission.Type == 3 then
							shared.Notify(player, "You spotted a Cultist doing something suspicious, the Cultist also spots you.", "Important");
						end
						modNpcs.spawn("Cultist", profile.LastDoorCFrame, function(npc, npcModule)
							npcModule.Properties.TargetableDistance = 4096;
							npcModule.OnTarget(player);
						end);
					end
				end
			end
		end)
		
	end)
	
	return CutsceneSequence;
end;