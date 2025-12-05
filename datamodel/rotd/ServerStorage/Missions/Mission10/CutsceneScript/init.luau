local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 10;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		if modMission:IsComplete(player, MISSION_ID) then
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
				mission.OnChanged:Disconnect(OnChanged);
				
			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;