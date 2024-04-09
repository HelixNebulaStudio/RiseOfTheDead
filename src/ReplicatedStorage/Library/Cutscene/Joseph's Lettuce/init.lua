local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local plantInteractables = script:WaitForChild("plantInteractables");

local random = Random.new();
--== Server Variables;
if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modDialogues = require(game.ServerScriptService.ServerLibrary.DialogueSave);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	modEvents = require(game.ServerScriptService.ServerLibrary.Events);

	modOnGameEvents:ConnectEvent("OnTrigger", function(player, interactData)
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
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheResidentials") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		local mission = modMission:GetMission(player, 37);
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
				mission.Changed:Disconnect(OnChanged);
			end
		end
		mission.Changed:Connect(OnChanged);
		OnChanged(true, mission);
	end)
	
	return CutsceneSequence;
end;