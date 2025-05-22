local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);

--== Variables;
local MISSION_ID = 37;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modDialogues = shared.require(game.ServerScriptService.ServerLibrary.DialogueSave);
	modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);

	shared.modEventService:OnInvoked("Interactables_OnTrigger", function(eventPacket: EventPacket, interactData, ...)
		local player: Player? = eventPacket.Player;
		if player == nil then return end;

		local triggerId = interactData.TriggerTag;

		if triggerId == "jlLettuce1" or triggerId == "jlLettuce2" or triggerId == "jlLettuce3" then
			local event = modEvents:GetEvent(player, triggerId);
			local lastEventTime = event and event.Time;

			if lastEventTime == nil or modSyncTime.GetTime() >= lastEventTime then
				modEvents:NewEvent(player, {Id=triggerId; Time=modSyncTime.GetTime()+600;});
				shared.Notify(player, "The plants have been watered.", "Reward");
				if modMission:Progress(player, 37) then
					modMission:Progress(player, 37, function(mission)
						mission.ObjectivesCompleted[triggerId] = true;
					end)
				end
			end

		end
	end);

	cutsceneAssets = script.Parent:WaitForChild("CutsceneAssets");
	plantInteractables = cutsceneAssets:WaitForChild("plantInteractables");

else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheResidentials") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
				
		local loaded = false;
		local function loadInteractables()
			if loaded then return end;
			loaded = true;
			local clone = plantInteractables:Clone();
			modReplicationManager.ReplicateIn(player, clone, workspace.Interactables);
		end
		
		local function OnChanged(firstRun)
			if mission.Type ~= 2 then
				loadInteractables();
			end
			if mission.Type == 3 then
				mission.OnChanged:Disconnect(OnChanged);
			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;