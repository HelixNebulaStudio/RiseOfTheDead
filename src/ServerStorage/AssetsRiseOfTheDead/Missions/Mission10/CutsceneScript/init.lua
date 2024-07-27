local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local missionId = 10;

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule"));
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, missionId);
		if mission == nil then return end;
			
		if modMission:IsComplete(player, missionId) then
			modReplicationManager.SetClientParent(player, workspace.Entity.Jefferson, nil);
			return;
		end
		
		local spawned = false;
		local function Spawn()
			if spawned then return end;
			local item = modStorage.FindItemIdFromStorages("antibiotics", player);
			if item == nil then
				local prefab = script:WaitForChild("antibioticsBottle"):Clone();
				modReplicationManager.ReplicateIn(player, prefab, workspace.Interactables);
				spawned = true;
			end
		end
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				Spawn();
				
			elseif mission.Type == 3 then -- OnComplete
				task.delay(30, function()
					modReplicationManager.SetClientParent(player, workspace.Entity.Jefferson, nil);
				end)
				mission.Changed:Disconnect(OnChanged);
				
			end
		end
		mission.Changed:Connect(OnChanged);
		OnChanged(true, mission);
	end)
	
	return CutsceneSequence;
end;