local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

--== Variables;
local missionId = 44;

if RunService:IsServer() then
	modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modEvents = require(game.ServerScriptService.ServerLibrary.Events);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);

	if modBranchConfigs.IsWorld("TheWarehouse") then
		modOnGameEvents:ConnectEvent("OnTrigger", function(player, interactData)
			local triggerTag = interactData.TriggerTag;
			local triggerObj = interactData.Object;

			if triggerTag == "MB2 Note" then
				if not modMission:IsComplete(player, missionId) then
					modMission:StartMission(player, missionId);
					game.Debris:AddItem(triggerObj, 0);
				end
			end
		end)
		
	elseif modBranchConfigs.IsWorld("TheResidentials") then
		modOnGameEvents:ConnectEvent("OnDoorEnter", function(player, interactData)
			local doorName = interactData.Name;

			if doorName == "Office2BasementRoom" then
				if not modMission:IsComplete(player, missionId) then
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint == 1 then
							mission.ProgressionPoint = 2;
						end
					end)
				end
			end
		end)

		modOnGameEvents:ConnectEvent("OnTrigger", function(player, interactData)
			local triggerTag = interactData.TriggerTag;
			local triggerObj = interactData.Object;

			if triggerTag == "MB2 Trap Door" then
				if not modMission:IsComplete(player, missionId) then
					modMission:Progress(player, missionId, function(mission)
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

	noteTrigger = script:WaitForChild("noteTrigger");
	footSteps = script:WaitForChild("warehouseFootprints");

	residentialsFootprints = script.Parent:WaitForChild("residentialsFootprints");
	jacksPhonePrefab = script.Parent:WaitForChild("jacksPhone");
	phoneTriggerPrefab = script.Parent:WaitForChild("phoneTrigger");
	trapTriggerPrefab = script.Parent:WaitForChild("trapTrigger");
	trapDoorPrefab = script.Parent:WaitForChild("trapDoor");
	freeScythePrefab = script.Parent:WaitForChild("freeScythe");
	basementDoorPrefab = script.Parent:WaitForChild("basementSecondDoor");

else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	
	if modBranchConfigs.IsWorld("TheWarehouse") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then return end;
				
			if modMission:IsComplete(player, missionId) then return end;

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

					mission.Changed:Disconnect(OnChanged);
				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true);
		end)


	elseif modBranchConfigs.IsWorld("TheResidentials") then


		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then return end;
				
			if not modMission:IsComplete(player, missionId) then

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

						mission.Changed:Disconnect(OnChanged);
					end
				end
				mission.Changed:Connect(OnChanged);
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