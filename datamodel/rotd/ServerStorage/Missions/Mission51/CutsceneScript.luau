local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modAudio = shared.require(game.ReplicatedStorage.Library:WaitForChild("Audio"));

--== Variables;
local MISSION_ID = 51;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	shared.modEventService:OnInvoked("Interactables_OnTrigger", function(eventPacket: EventPacket, interactData, ...)
		local player: Player? = eventPacket.Player;
		if player == nil then return end;

		local triggerTag = interactData.TriggerTag;
		local triggerObj = interactData.Object;

		if triggerTag == "QA1_Radio" then
			local mission = modMission:Progress(player, 51);
			if mission and mission.ProgressionPoint == 1 then
				interactData.CanInteract = false;
				interactData.Label = "Broadcasting... *Static* *Static* Hmmm.. Seems like the radio strength is still not strong enough..";
				interactData:Sync();
				wait(1)
				modMission:Progress(player, 51, function(mission)
					if mission.ProgressionPoint < 2 then mission.ProgressionPoint = 2; end;
				end)
			end
			
		elseif triggerTag == "QA2_Radio" then
			local mission = modMission:Progress(player, 51);
			if mission then
				if mission.ProgressionPoint == 3 then
					interactData.CanInteract = false;
					interactData.Label = "*Broadcasting..*";
					interactData:Sync();
					
					wait(0.5);
					modAudio.Play("RadioChatter", triggerObj);
					local radioMsg = "[Radio] *Static* Yep, ten-four. We copy loud and clear. Please identify yourself. *Static*";
					interactData.Label = radioMsg;
					shared.Notify(player, radioMsg, "Message");
					interactData:Sync();
					
					wait(8.5);
					modMission:Progress(player, 51, function(mission)
						if mission.ProgressionPoint == 3 then mission.ProgressionPoint = 4; end;
					end)
					interactData.CanInteract = true;
					interactData.Label = "*Static* I am "..player.Name..", I am requesting for help. I was sent by Wilson from squad B. He is still alive.";
					interactData:Sync();

				elseif mission.ProgressionPoint == 4 then
					interactData.CanInteract = false;
					interactData.Label = "*Broadcasting..*";
					interactData:Sync();

					wait(0.5);
					modAudio.Play("RadioChatter", triggerObj);
					local radioMsg = "[Radio] Copy. Commander, we have a survivor on the radio. He claims Wilson from squad B is alive and sent him.";
					interactData.Label = radioMsg;
					shared.Notify(player, radioMsg, "Message");
					interactData:Sync();

					wait(12.5);
					modAudio.Play("RadioChatter2", triggerObj);
					
					radioMsg = "[Radio] Commander: Wilson is still alive?! Hello? This is commander Leo. Please state your location.";
					interactData.Label = radioMsg;
					shared.Notify(player, radioMsg, "Message");
					interactData:Sync();

					wait(12.5);
					modMission:Progress(player, 51, function(mission)
						if mission.ProgressionPoint == 4 then mission.ProgressionPoint = 5; end;
					end)
					interactData.CanInteract = true;
					interactData.Label = "*Static* We are located in the Sunday's Convenience Store near the Wrighton Dale Bank..";
					interactData:Sync();

				elseif mission.ProgressionPoint == 5 then
					interactData.CanInteract = false;
					interactData.Label = "*Broadcasting..*";
					interactData:Sync();

					wait(0.5);
					modAudio.Play("RadioChatter", triggerObj);
					local radioMsg = "[Radio] Copy. We will be dispatching an inspection team there.";
					interactData.Label = radioMsg;
					shared.Notify(player, radioMsg, "Message");
					interactData:Sync();
					
					wait(1);
					modMission:Progress(player, 51, function(mission)
						if mission.ProgressionPoint == 5 then mission.ProgressionPoint = 6; end;
					end)
					modAudio.Play("RadioStatic", triggerObj);
				end
			end

		end
	end)


	templateRadioInteractable1 = script.Parent:WaitForChild("militaryRadioInteractable");
	templateRadioInteractable2 = script.Parent:WaitForChild("militaryRadioInteractable2");

else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if modBranchConfigs.IsWorld("TheUnderground") then

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

	elseif modBranchConfigs.IsWorld("TheResidentials") then

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
						
					elseif mission.ProgressionPoint == 4 then
						if newInteractable == nil then
							newInteractable = templateRadioInteractable2:Clone();
							newInteractable.Parent = workspace.Interactables;
							modReplicationManager.ReplicateOut(player, newInteractable);
						end
						
					elseif mission.ProgressionPoint == 5 then
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