local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local missionId = 29;

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule"));
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheUnderground") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;

	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, missionId);
		if mission == nil then return end;
			
		if not modMission:IsComplete(player, missionId) then
			local hilbertModule = modNpc.GetPlayerNpc(player, "Hilbert");
			if hilbertModule == nil then
				local npc = modNpc.Spawn("Hilbert", nil, function(npc, npcModule)
					npcModule.Owner = player;
					hilbertModule = npcModule;
				end);
				modReplicationManager.ReplicateOut(player, npc);
			end

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- Available

				elseif mission.Type == 1 then -- Active
					if mission.ProgressionPoint == 1 then

					elseif mission.ProgressionPoint == 2 then

					end
				elseif mission.Type == 3 then
					mission.Changed:Disconnect(OnChanged);
					hilbertModule.Prefab:Destroy();
				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true, mission);
		end
	end)
	
	return CutsceneSequence;
end;