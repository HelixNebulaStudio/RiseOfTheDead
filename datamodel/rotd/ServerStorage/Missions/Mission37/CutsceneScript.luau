local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modZScripting = shared.require(game.ReplicatedStorage.Plugin.ZScript.Scripting);

--== Variables;
local MISSION_ID = 37;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modDialogues = shared.require(game.ServerScriptService.ServerLibrary.DialogueSave);
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);

	if modBranchConfigurations.IsWorld("TheResidentials") then
		shared.modEventService:OnInvoked("Generic_BindTrigger", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;
			if interactable == nil then return end;
				
			local triggerId = interactable.Id;

			if triggerId == "jlLettuce1" or triggerId == "jlLettuce2" or triggerId == "jlLettuce3" then
				local event = modEvents:GetEvent(player, triggerId);
				local lastEventTime = event and event.Time;

				if lastEventTime == nil or modSyncTime.GetTime() >= lastEventTime then
					modEvents:NewEvent(player, {Id=triggerId; Time=modSyncTime.GetTime()+600;});
					shared.Notify(player, "The plants have been watered.", "Reward");
					if modMission:Progress(player, MISSION_ID) then
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ObjectivesCompleted[triggerId] = true;
						end)
					end
				end

			end
		end);
	end

	cutsceneAssets = script.Parent:WaitForChild("CutsceneAssets");
	plantInteractables = cutsceneAssets:WaitForChild("plantInteractables");

else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigurations.IsWorld("TheResidentials") then 
		Debugger:Warn("Invalid place for cutscene ("..script.Name..")");
		return;
	end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
				
		local loaded = false;
		local function loadInteractables()
			if loaded then return end;
			loaded = true;
			local newPlantInteractables = plantInteractables:Clone();

			for _, interactPart in ipairs(newPlantInteractables:GetChildren()) do
				local interactConfig = modInteractables.createInteractable("ButtonRotd");
				interactConfig:SetAttribute("_Id", interactPart.Name);
				interactConfig:SetAttribute("_Label", "Water Lettuce");
				interactConfig:SetAttribute("_Toggle", "IsWatered");
				interactConfig:SetAttribute("_ToggleAtZeroUses", true);
				interactConfig:SetAttribute("_Uses", 1);
				interactConfig:SetAttribute("_InteractDuration", 5);
				interactConfig:SetAttribute("_EquipItemId", "watercan");

				local interactPackageZScript = modZScripting.createZScript(`InteractPackage`, [[
					local interactPackage = {};

					function interactPackage.BindPrompt(interactable: Interactable, interactData: InteractionData)
						if interactable.IsToggled then
							interactable.Label = `You have watered these plants`;
							interactable.CanInteract = false;
							return true;
						end
						
						interactable.Label = `Water Lettuce`;
					end

					return interactPackage;
				]]);
				
				interactPackageZScript.Parent = interactConfig;
				interactConfig.Parent = interactPart;
			end

			modReplicationManager.ReplicateIn(player, newPlantInteractables, workspace.Interactables);
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