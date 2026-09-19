local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

--== Variables;
local MISSION_ID = 22;
local BACKUPPLAN_STORAGE_ID = "thebackupplan";

if RunService:IsServer() then
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
	
	if shared.WorldName == "TheUnderground" or shared.WorldName == "BioXResearch" then
		shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;
			if interactable.Id == "sewersMaintenanceRoom" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 2 then
						mission.ProgressionPoint = 3;
					end
				end)
			end
		end)

		shared.modEventService:OnInvoked("Generic_BindItemPickup", function(event: EventPacket, ...)
			local interactable: InteractableInstance = ...;
			local player: Player? = event.Player;
			if player == nil then return end;
			
			task.spawn(function()
				local itemId = interactable.Values.ItemId;
				if itemId ~= "sewerskey1" then return end;

				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 1 then
						mission.ProgressionPoint = 2;
					end
				end)
			end)
		end);

		shared.modEventService:OnInvoked("Storage_OnOpen", function(event: EventPacket, ...)
			local storage: Storage, player: Player = ...;
			if storage == nil then return end;
			if storage.Id ~= BACKUPPLAN_STORAGE_ID then return end;

			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint == 3 then
					mission.ProgressionPoint = 4;
				end
			end)
		end)
	end

else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigurations.IsWorld("TheUnderground") then
		Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); 
		return;
	end;
	
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

				local pickupableConfig = modInteractables.createInteractable("PickupableRotd");
				pickupableConfig:SetAttribute("ItemId", "sewerskey1");
				pickupableConfig.Parent = prefab;

				modReplicationManager.ReplicateIn(player, prefab, workspace.Interactables);
				spawned = true;
			end

		end
		local storage = modStorage.Get(BACKUPPLAN_STORAGE_ID, player);
		
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
					
					storage = modStorage.Get(BACKUPPLAN_STORAGE_ID, player);
					Debugger:StudioLog(`Storage exist {BACKUPPLAN_STORAGE_ID}: {storage ~= nil}`);
					if storage == nil then
						Debugger:Log("Generating storage",BACKUPPLAN_STORAGE_ID);
						local profile = shared.modProfile:Get(player);
						local activeSave = profile:GetActiveSave();
						
						if activeSave and activeSave.Storages[BACKUPPLAN_STORAGE_ID] == nil then
							activeSave.Storages[BACKUPPLAN_STORAGE_ID] = modStorage.new(
								BACKUPPLAN_STORAGE_ID, 
								BACKUPPLAN_STORAGE_ID, 
								player
							);
							storage = activeSave.Storages[BACKUPPLAN_STORAGE_ID];
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