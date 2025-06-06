local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 22;

if RunService:IsServer() then
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheUnderground") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		if modMission:IsComplete(player, MISSION_ID) then return end;

		local spawned = false;
		local function Spawn()
			if spawned then return end;
			local item = modStorage.FindItemIdFromStorages("sewerskey1", player);
			if item == nil then
				local prefab = script.Parent:WaitForChild("sewersKey"):Clone();
				modReplicationManager.ReplicateIn(player, prefab, workspace.Interactables);
				spawned = true;
			end
		end
		local storageId = "thebackupplan";
		local storage = modStorage.Get(storageId, player);
		
		local function OnChanged(firstRun)
			if mission.Type == 1 then
				if mission.ProgressionPoint == 1 or mission.ProgressionPoint == 2 then
					Spawn();
					
				elseif mission.ProgressionPoint == 3 then
					local item, keystorage = modStorage.FindItemIdFromStorages("sewerskey1", player);
					if item then
						keystorage:Remove(item.ID, 1, function()
							shared.Notify(player, "The sewers maintenance key is used to unlock the maintenance room.", "Inform");
						end);
						
					end
					
					storage = modStorage.Get(storageId, player);
					Debugger:Log("Storage exist "..storageId..":", storage ~= nil);
					if storage == nil then
						Debugger:Log("Generating storage",storageId);
						local profile = shared.modProfile:Get(player);
						local activeSave = profile:GetActiveSave();
						
						if activeSave and activeSave.Storages[storageId] == nil then
							activeSave.Storages[storageId] = modStorage.new(storageId, storageId, player);
							storage = activeSave.Storages[storageId];
							storage:Sync();
						end
					end
					if storage and modEvents:GetEvent(player, "backupplanPoint4") == nil then
						storage:Add("metal", {Quantity=1000;}, function(event, remains)
							if event ~= "Success" then
								Debugger:Warn("Failed to spawn (thebackupplancrates) with its contents.", remains);
							end;
						end)
						modEvents:NewEvent(player, {Id="backupplanPoint4"});
					end
					
				end
				
			elseif mission.Type == 3 then
				mission.OnChanged:Disconnect(OnChanged);
			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;