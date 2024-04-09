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
	if not modBranchConfigs.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		local mission = modMission:GetMission(player, 16);
		if mission == nil then return end;
			
		local jesseModule = modNpc.GetPlayerNpc(player, "Jesse");
		if jesseModule == nil then
			local npc = modNpc.Spawn("Jesse", nil, function(npc, npcModule)
				npcModule.Owner = player;
				jesseModule = npcModule;
			end);
			modReplicationManager.ReplicateOut(player, npc);
		end
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then

				elseif mission.ProgressionPoint == 2 then

				end
			elseif mission.Type == 3 then -- OnComplete


			end
		end
		mission.Changed:Connect(OnChanged);
		OnChanged(true, mission);
	end)
	
	return CutsceneSequence;
end;