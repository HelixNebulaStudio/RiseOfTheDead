local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

--== Variables;
local MISSION_ID = 44;

if RunService:IsServer() then
	modProfile = shared.require(game.ServerScriptService.ServerLibrary.Profile);
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
	modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);

	if modBranchConfigs.IsWorld("TheWarehouse") then
		shared.modEventService:OnInvoked("Interactables_OnTrigger", function(eventPacket: EventPacket, interactData, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;
			
			local triggerTag = interactData.TriggerTag;
			local triggerObj = interactData.Object;

			if triggerTag == "MB2 Note" then
				if not modMission:IsComplete(player, MISSION_ID) then
					modMission:StartMission(player, MISSION_ID);
					game.Debris:AddItem(triggerObj, 0);
				end
			end
		end)
		
	elseif modBranchConfigs.IsWorld("TheResidentials") then
		modOnGameEvents:ConnectEvent("OnDoorEnter", function(player, interactData)
			local doorName = interactData.Name;

			if doorName == "Office2BasementRoom" then
				if not modMission:IsComplete(player, MISSION_ID) then
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 1 then
							mission.ProgressionPoint = 2;
						end
					end)
				end
			end
		end)

		shared.modEventService:OnInvoked("Interactables_OnTrigger", function(eventPacket: EventPacket, interactData, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;
			
			local triggerTag = interactData.TriggerTag;
			local triggerObj = interactData.Object;

			if triggerTag == "MB2 Trap Door" then
				if not modMission:IsComplete(player, MISSION_ID) then
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 2 then
							mission.ProgressionPoint = 3;
							
						end
					end)
				end
				
			elseif triggerTag == "MB2_TakeScythe" then
				if modEvents:GetEvent(player, "mb2_scythepickup") == nil then

					local profile = modProfile:Get(player);
					local activeInventory = profile.ActiveInventory;
					local hasSpace = activeInventory:SpaceCheck{{ItemId="jacksscythe"}};
					if not hasSpace then
						shared.Notify(player, "Inventory is full!", "Negative");
						
					else
						local list = modStorage.ListItemIdFromStorages("jacksscythe", player);
						if #list > 0 then
							shared.Notify(player, "You already have Jack's Scythe.", "Inform");

						else
							activeInventory:Add("jacksscythe");
							shared.Notify(player, "You picked up Jack's Scythe!", "Reward");

						end
						modEvents:NewEvent(player, {Id="mb2_scythepickup"});
						game.Debris:AddItem(triggerObj, 0);
					
					end
				end
				
			end
		end)
	end

	noteTrigger = script.Parent:WaitForChild("noteTrigger");
	footSteps = script.Parent:WaitForChild("warehouseFootprints");

	residentialsFootprints = script.Parent:WaitForChild("residentialsFootprints");
	jacksPhonePrefab = script.Parent:WaitForChild("jacksPhone");
	phoneTriggerPrefab = script.Parent:WaitForChild("phoneTrigger");
	trapTriggerPrefab = script.Parent:WaitForChild("trapTrigger");
	trapDoorPrefab = script.Parent:WaitForChild("trapDoor");
	freeScythePrefab = script.Parent:WaitForChild("freeScythe");
	basementDoorPrefab = script.Parent:WaitForChild("basementSecondDoor");

else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	
	if modBranchConfigs.IsWorld("TheWarehouse") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			if modMission:IsComplete(player, MISSION_ID) then return end;

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					local newNoteTrigger = noteTrigger:Clone();
					newNoteTrigger.Parent = workspace.Interactables;
					modReplicationManager.ReplicateOut(player, newNoteTrigger);

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						local newFootsteps = footSteps:Clone();
						newFootsteps.Parent = workspace.Environment;
						modReplicationManager.ReplicateOut(player, newFootsteps);

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
				
			if not modMission:IsComplete(player, MISSION_ID) then

				local function OnChanged(firstRun)
					if mission.Type == 2 then -- OnAvailable

					elseif mission.Type == 1 then -- OnActive
						if mission.ProgressionPoint == 1 then
							local footsteps = residentialsFootprints:Clone();
							footsteps.Parent = workspace.Environment;
							modReplicationManager.ReplicateOut(player, footsteps);

							local jacksPhone = jacksPhonePrefab:Clone();
							jacksPhone.Parent = workspace.Interactables;
							modReplicationManager.ReplicateOut(player, jacksPhone);

							local phoneTouchTrigger = phoneTriggerPrefab:Clone();
							phoneTouchTrigger.Parent = workspace.Interactables;
							
							phoneTouchTrigger.Touched:Connect(function(hit)
								local player = game.Players:FindFirstChild(hit.Parent.Name);
								if player == nil then Debugger:Log("Unknown touch source."); return end;

								modAudio.Play("PhoneRinging", jacksPhone, true);
								phoneTouchTrigger:Destroy();
							end)
							
						elseif mission.ProgressionPoint == 2 then
							local trapTrigger = trapTriggerPrefab:Clone();
							trapTrigger.Parent = workspace.Interactables;
							modReplicationManager.ReplicateOut(player, trapTrigger);
							
						elseif mission.ProgressionPoint == 3 then
							local trapDoor = trapDoorPrefab:Clone();
							trapDoor.Parent = workspace.Environment;
							modReplicationManager.ReplicateOut(player, trapDoor);
							modStatusEffects.SetWalkspeed(player, 10);
							
							modMission:Progress(player, 44, function(mission)
								mission.ProgressionPoint = 4;
							end)
							delay(5, function()
								modServerManager:Travel(player, "HalloweenBasement");
							end)
							CutsceneSequence:NextScene("poisonTrap");
							wait(5)
							modStatusEffects.Dizzy(player, 5);
							
						elseif mission.ProgressionPoint == 4 and firstRun then
							modMission:Progress(player, 44, function(mission)
								mission.ProgressionPoint = 2;
							end)
							
						end
					elseif mission.Type == 3 then -- OnComplete

						mission.OnChanged:Disconnect(OnChanged);
					end
				end
				mission.OnChanged:Connect(OnChanged);
				OnChanged(true);
				
			else -- Loading Completed
				if modEvents:GetEvent(player, "mb2_scythepickup") == nil then
					local freeScythe = freeScythePrefab:Clone();
					freeScythe.Parent = workspace.Interactables;
					modReplicationManager.ReplicateOut(player, freeScythe);
				end
				
				local basementDoor = basementDoorPrefab:Clone();
				basementDoor.Parent = workspace.Interactables;
				modReplicationManager.ReplicateOut(player, basementDoor);
				
			end
		end)
		
		CutsceneSequence:NewScene("poisonTrap", function()
			spawn(function()
				local poisonVent = workspace.Environment:WaitForChild("poisonVent");
				poisonVent.Attachment.Smoke.Enabled = true;
				wait(5)
				local modInterface = modData:GetInterfaceModule();
				modInterface:ToggleGameBlinds(false, 10);
			end)
		end)

	end

	return CutsceneSequence;
end;