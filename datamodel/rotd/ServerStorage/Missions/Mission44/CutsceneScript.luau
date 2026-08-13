local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
local modUnlockPack = shared.require(game.ReplicatedStorage.Library.UsableItemsRotd.Generics.UnlockPack);

--== Variables;
local MISSION_ID = 44;

if RunService:IsServer() then
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
	modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
	cutsceneAssets = script.Parent:WaitForChild("CutsceneAssets");


	if shared.WorldName == "TheWarehouse" then
		shared.modEventService:OnInvoked("Generic_BindTrigger", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;
				
			local triggerId: string, interactable: InteractableInstance = ...;
			
			if triggerId == "MB2 Note" then
				task.spawn(function()
					if not modMission:IsComplete(player, MISSION_ID) then
						modMission:StartMission(player, MISSION_ID);
						game.Debris:AddItem(interactable.Config.Parent, 0);
					end
				end)
			end
		end)
		
	elseif shared.WorldName == "TheResidentials" then
		shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(event: EventPacket, ...) 
			local player: Player? = event.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;
			if interactable == nil or interactable.Id ~= "Office2BasementRoom" then return end;

			if not modMission:IsComplete(player, MISSION_ID) then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 1 then
						mission.ProgressionPoint = 2;
					end
				end)
			end
		end);

		shared.modEventService:OnInvoked("Generic_BindTrigger", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;
				
			local triggerId: string, interactable: InteractableInstance = ...;
			
			if triggerId == "MB2 Trap Door" then
				task.spawn(function()
					if not modMission:IsComplete(player, MISSION_ID) then
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint == 2 then
								mission.ProgressionPoint = 3;
								
							end
						end)
					end
				end)
				
			elseif triggerId == "MB2_TakeScythe" then
				task.spawn(function()
					if modEvents:GetEvent(player, "mb2_scythepickup") then return end;

					local profile = shared.modProfile:Get(player);
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
						game.Debris:AddItem(interactable.Config.Parent, 0);
					
					end
				end)
				
			end
		end)
		
	elseif shared.WorldName == "WitherweenBasement" then
		cabinetKey = workspace.Environment:WaitForChild("PuzzleElements"):WaitForChild("moveableToolCabinet"):WaitForChild("key");
		brokenDoor = workspace.Environment:WaitForChild("PuzzleElements"):WaitForChild("brokenDoor");

		shared.modEventService:OnInvoked("Generic_BindTrigger", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;
				
			local triggerId: string, interactable: InteractableInstance = ...;
			
			if triggerId == "MB2 key1" then
				task.spawn(function()
					interactable.Part:Destroy();
					shared.Notify(player, "A door key acquired.", "Inform");
					local doorInteractable: InteractableInstance = modInteractables.getById("MB2 door1");
					doorInteractable.Config:SetAttribute("Locked", false);
				end)

			elseif triggerId == "MB2 door1" then
				task.spawn(function()
					if interactable.Values.Locked then
						Debugger:Warn(`Door is locked.`);
						return;
					end
					Debugger.Expire(interactable.Config.Parent);
				end)

			elseif triggerId == "MB2 door2" then
				task.spawn(function()
					if interactable.Values.Locked then
						Debugger:Warn(`Door is locked.`);
						return;
					end
					Debugger.Expire(interactable.Config.Parent);
				end)

			elseif triggerId == "CabinetRope" then
				task.spawn(function()
					if cabinetKey.Transparency == 1 then
						shared.Notify(player, "I should probably knock over the key before I pull this..", "Inform");
						return;
					end

					shared.Notify(player, "The third door key acquired.", "Inform");
					local doorInteractable: InteractableInstance = modInteractables.getById("MB2 door3");
					doorInteractable:SetPermissions("CanInteract", true);
				end)

			elseif triggerId == "MB2 door3" then
				task.spawn(function()
					for _, obj in pairs(brokenDoor:GetChildren()) do
						if not obj:IsA("BasePart") then continue end;
						obj.Anchored = false;
					end
				end)

			elseif triggerId == "UnlockHalloweenPack" then
				local profile = shared.modProfile:Get(player);
				if profile and profile.SkinsPacks.Halloween == nil then
					modUnlockPack.UnlockPack(player, "SkinsPacks", "Halloween");
				end

			elseif triggerId == "MB2 Generator" then
				Debugger:Warn(`Generator interact`, interactable.Values.IsPowered);
				if interactable.Values.IsPowered ~= true then
					return;
				end

				shared.Notify(player, "The exit door is now powered", "Inform");

				local travelPart = cutsceneAssets:WaitForChild("Travel_TheResidentials"):Clone();
				travelPart.Parent = workspace.Interactables;

			end
		end)

		shared.modEventService:OnInvoked("Destructibles_BindDestroyed", function(event: EventPacket, ...)
			local destructible: DestructibleInstance, damageData: DamageData = ...;

			if destructible.Id == "key2Shelf" then
				task.spawn(function()
					shared.Notify(game.Players:GetPlayers(), "Another door key acquired.", "Inform");

					local doorInteractable: InteractableInstance = modInteractables.getById("MB2 door2");
					doorInteractable.Config:SetAttribute("Locked", false);
				end)

			elseif destructible.Id == "key3Shelf" then
				task.spawn(function()
					cabinetKey.Transparency = 0;
					shared.Notify(game.Players:GetPlayers(), "The key drops onto the tool cabinet.", "Inform");

				end)

			end
		end)
		

	end

else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	--MARK: TheWarehouse
	if shared.WorldName == "TheWarehouse" then
		CutsceneSequence:Initialize(function()
			local noteTrigger = cutsceneAssets:WaitForChild("noteTrigger");
			local footSteps = cutsceneAssets:WaitForChild("warehouseFootprints");

			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			if modMission:IsComplete(player, MISSION_ID) then return end;

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					local newNoteTrigger = noteTrigger:Clone();
					mission.Garbage:Tag(newNoteTrigger);

					local interactConfig = modInteractables.createInteractable("ButtonRotd");
					interactConfig:SetAttribute("_Id", "MB2 Note");
					interactConfig:SetAttribute("_Label", `"Thank you for freeing my spirit from the zombie body. My soul is no longer tormented and will no longer haunt the world." ~ Jack, Pick Up Note`);
					interactConfig.Parent = newNoteTrigger;

					newNoteTrigger.Parent = workspace.Interactables;
					modReplicationManager.ReplicateOut(player, newNoteTrigger);

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						local newFootsteps = footSteps:Clone();
						mission.Garbage:Tag(newFootsteps);

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


	--MARK: TheResidentials
	elseif shared.WorldName == "TheResidentials" then
		CutsceneSequence:Initialize(function()
			local residentialsFootprints = cutsceneAssets:WaitForChild("residentialsFootprints");
			local jacksPhonePrefab = cutsceneAssets:WaitForChild("jacksPhone");
			local trapTriggerPrefab = cutsceneAssets:WaitForChild("trapTrigger");
			local trapDoorPrefab = cutsceneAssets:WaitForChild("trapDoor");
			local freeScythePrefab = cutsceneAssets:WaitForChild("freeScythe");
			local basementDoorPrefab = cutsceneAssets:WaitForChild("basementSecondDoor");

			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				

			if modMission:IsComplete(player, MISSION_ID) then
				if modEvents:GetEvent(player, "mb2_scythepickup") == nil then
					local freeScythe = freeScythePrefab:Clone();
					mission.Garbage:Tag(freeScythe);

					local interactConfig = modInteractables.createInteractable("ButtonRotd");
					interactConfig:SetAttribute("_Id", "MB2_TakeScythe");
					interactConfig:SetAttribute("_Label", "Take Jack's Scythe");
					interactConfig.Parent = freeScythe;
					freeScythe.Parent = workspace.Interactables;

					modReplicationManager.ReplicateOut(player, freeScythe);
				end
				
				local basementDoor = basementDoorPrefab:Clone();
				mission.Garbage:Tag(basementDoor);
				basementDoor.Parent = workspace.Interactables;
				modReplicationManager.ReplicateOut(player, basementDoor);

				return;
			end
			

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						local footsteps = residentialsFootprints:Clone();
						mission.Garbage:Tag(footsteps);
						footsteps.Parent = workspace.Environment;
						modReplicationManager.ReplicateOut(player, footsteps);

						local jacksPhone = jacksPhonePrefab:Clone();
						mission.Garbage:Tag(jacksPhone);
						jacksPhone.Parent = workspace.Interactables;
						modReplicationManager.ReplicateOut(player, jacksPhone);

						local interactConfig = modInteractables.createInteractable("Message");
						interactConfig:SetAttribute("_Sound", "PhoneRinging");
						interactConfig:SetAttribute("_EndSound", "PhonePickUp");
						interactConfig:SetAttribute("Text", `*Picks Up* Phone: You.. How dare you come here... LEAVE NOW OR ELSE!`);
						interactConfig.Parent = jacksPhone;
						
					elseif mission.ProgressionPoint == 2 then
						local trapTrigger = trapTriggerPrefab:Clone();
						mission.Garbage:Tag(trapTrigger);

						local interactConfig = modInteractables.createInteractable("ButtonRotd");
						interactConfig:SetAttribute("_Id", "MB2 Trap Door");
						interactConfig:SetAttribute("_Label", "Enter Door");
						interactConfig.Parent = trapTrigger;
						trapTrigger.Parent = workspace.Interactables;
						
						modReplicationManager.ReplicateOut(player, trapTrigger);
						
					elseif mission.ProgressionPoint == 3 then
						local trapDoor = trapDoorPrefab:Clone();
						mission.Garbage:Tag(trapDoor);
						trapDoor.Parent = workspace.Environment;
						modReplicationManager.ReplicateOut(player, trapDoor);
						modStatusEffects.SetWalkspeed(player, 10);
						
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 4;
						end)
						task.delay(5, function()
							modServerManager:Travel(player, "WitherweenBasement");
						end)
						CutsceneSequence:NextScene("poisonTrap");
						task.wait(3)
						modStatusEffects.Dizzy(player, 5);
						
					elseif mission.ProgressionPoint == 4 and firstRun then
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 2;
						end)
						
					end
				elseif mission.Type == 3 then -- OnComplete

					mission.OnChanged:Disconnect(OnChanged);
				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);

		end)
		
		CutsceneSequence:NewScene("poisonTrap", function()
			task.spawn(function()
				local poisonVent = workspace.Environment:WaitForChild("poisonVent");
				poisonVent.Attachment.Smoke.Enabled = true;
				task.wait(3);
	       		modClientGuis.toggleGameBlinds(false, 10);
			end)
		end)

	--MARK: WitherweenBasement
	elseif shared.WorldName == "WitherweenBasement" then
	end

	return CutsceneSequence;
end;