local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

local random = Random.new();
--== Server Variables;
if RunService:IsServer() then
	modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modEvents = require(game.ServerScriptService.ServerLibrary.Events);
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheUnderground") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		local mission = modMission:GetMission(player, 22);
		if mission == nil then return end;
		
		if not modMission:IsComplete(player, 22) then
			local spawned = false;
			local function Spawn()
				if spawned then return end;
				local item = modStorage.FindItemIdFromStorages("sewerskey1", player);
				if item == nil then
					local prefab = script:WaitForChild("sewersKey"):Clone();
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
							local profile = modProfile:Get(player);
							local activeSave = profile:GetActiveSave();
							
							if activeSave and activeSave.Storages[storageId] == nil then
								activeSave.Storages[storageId] = modStorage.new(storageId, "Wooden Crate", 5, player);
								activeSave.Storages[storageId].MaxSize = 5;
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
					mission.Changed:Disconnect(OnChanged);
				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true, mission);
		end
	end)
	
	return CutsceneSequence;
end;