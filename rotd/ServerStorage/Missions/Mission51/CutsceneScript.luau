local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modAudio = shared.require(game.ReplicatedStorage.Library:WaitForChild("Audio"));
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

--== Variables;
local MISSION_ID = 51;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
		local player: Player? = event.Player;
		if player == nil then return end;

		local triggerId: string, interactable: InteractableInstance = ...;
		if triggerId == nil or interactable == nil then return end;

		local mission = modMission:Progress(player, MISSION_ID);
		if mission == nil then return end

		if triggerId == "QA1_Radio" then
			if mission.ProgressionPoint == 1 then
				interactable.CanInteract = false;
				interactable.Label = "Broadcasting... *Static* *Static* Hmmm.. Seems like the radio strength is still not strong enough..";
				interactable:Sync();
				modAudio.Play("RadioStatic", interactable.Part);
				task.wait(1);

				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint < 2 then
						mission.ProgressionPoint = 2;
					end;
				end)
			end

		elseif triggerId == "QA2_Radio" then
			if mission.ProgressionPoint == 3 then
				interactable.Label = "*Broadcasting..*";
				interactable:Sync();
			end
			
		end

	end)

	if modBranchConfigurations.IsWorld("TheResidentials") then
		shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(event: EventPacket, ...) 
			local player: Player? = event.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;
			if interactable.Id ~= "RadioRoofDoor" then return end;

			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint == 2 then mission.ProgressionPoint = 3; end;
			end)
		end)
	end

	
	templateRadioInteractable1 = script.Parent:WaitForChild("militaryRadioInteractable");
	local interactConfig = modInteractables.createInteractable("ButtonRotd");
	interactConfig:SetAttribute("_Id", "QA1_Radio");
	interactConfig:SetAttribute("_Label", "Interact With Radio");
	interactConfig:SetAttribute("_InteractDuration", 1);
	interactConfig.Parent = templateRadioInteractable1;

	templateRadioInteractable2 = script.Parent:WaitForChild("militaryRadioInteractable2");
	local interactConfig2 = modInteractables.createInteractable("Dialogue");
	interactConfig2:SetAttribute("_Id", "QA2_Radio");
	interactConfig2:SetAttribute("_Label", `Broadcast`);
	interactConfig2:SetAttribute("_InteractDuration", 1);
	interactConfig2:SetAttribute("DialogueName", "Military Radio");
	interactConfig2.Parent = templateRadioInteractable2;

else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if modBranchConfigurations.IsWorld("TheUnderground") then

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			if modMission:IsComplete(player, MISSION_ID) then return end;

			local newInteractable;
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						newInteractable = templateRadioInteractable1:Clone();
						newInteractable.Parent = workspace.Interactables;
						modReplicationManager.ReplicateOut(player, newInteractable);
						
					elseif mission.ProgressionPoint == 2 then
						
					end
				elseif mission.Type == 3 then -- OnComplete
					mission.OnChanged:Disconnect(OnChanged);
				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);

		end)

	elseif modBranchConfigurations.IsWorld("TheResidentials") then

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			if modMission:IsComplete(player, MISSION_ID) then return end;

			local newInteractable;
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
					elseif mission.ProgressionPoint == 2 then
						newInteractable = templateRadioInteractable2:Clone();
						newInteractable.Parent = workspace.Interactables;
						modReplicationManager.ReplicateOut(player, newInteractable);
						
					elseif mission.ProgressionPoint == 3 then
						if newInteractable == nil then
							newInteractable = templateRadioInteractable2:Clone();
							newInteractable.Parent = workspace.Interactables;
							modReplicationManager.ReplicateOut(player, newInteractable);
						end
						
					end
				elseif mission.Type == 3 then -- OnComplete
					mission.OnChanged:Disconnect(OnChanged);

				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);

		end)

	end


	
	return CutsceneSequence;
end;