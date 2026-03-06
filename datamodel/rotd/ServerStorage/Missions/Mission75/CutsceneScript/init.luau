local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modStorageItem = shared.require(game.ReplicatedStorage.Library.StorageItem);
local modDialogueService = shared.require(game.ReplicatedStorage.Library.DialogueService);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);

--==
local MISSION_ID = 75;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
	modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
end

--==
return function(CutsceneSequence)
	--if not modBranchConfigurations.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	local modClothingLibrary = shared.require(game.ReplicatedStorage.Library.ClothingLibrary);

	local gameFolder = workspace:WaitForChild("Environment"):WaitForChild("Game");

	local patrolBandit: NpcClass;

	if RunService:IsServer() then
		modStorage.RegisterItemName("Stan's Blood Samples");
		modStorage.RegisterItemName("Dr. Deniski's Report Insights");
		modStorage.RegisterItemName("Stan's Blood Samples Report #1");
		modStorage.RegisterItemName("Stan's Blood Samples Report #2");
		modStorage.RegisterItemName("Stan's Blood Samples Report #3");
		modStorage.RegisterItemName("Stan's Blood Samples Report #4");
	end
	
	if RunService:IsServer() and modBranchConfigurations.IsWorld("MedicalBreakthrough") then
		local jerCan = script:WaitForChild("JerryCan");
		local pickupConfig = modInteractables.createInteractable("Pickupable");
		pickupConfig:SetAttribute("ItemId", "jerrycan");
		pickupConfig.Parent = jerCan;
		jerCan.Parent = workspace.Interactables;
		
		shared.modEventService:OnInvoked("Generic_BindTrigger", function(eventPacket: EventPacket, ...)
			local id: string, interactable: InteractableInstance = ...;

			local player: Player? = eventPacket.Player;
			if player == nil then return end;
			local playerClass: PlayerClass = shared.modPlayers.get(player);
			
			local mission = modMission:GetMission(player, MISSION_ID);
			
			local profile = shared.modProfile:Get(player);
			local playerSave = profile:GetActiveSave();
			local inventory = playerSave.Inventory;

			if id ~= "m75bloodmachine" then return end;

			local bloodMachineInteractable: InteractableInstance = interactable;
			local state = bloodMachineInteractable.Values.State;
			
			Debugger:Warn("bloodMachineInteractData state", state);
			
			if state == 1 then
				local _, itemList = inventory:ListQuantity("bloodsample", 1);

				if itemList and #itemList > 0 then
					local listItem = itemList[1];
					local storageItem = inventory:Find(listItem.ID);
					local sampleName = storageItem and storageItem.CustomName or "n/a";
					
					--inventory:Remove(listItem.ID, 1);
					playerClass.WieldComp:Unequip();

					bloodMachineInteractable.Config:SetAttribute("_EquipItemId", nil);
					bloodMachineInteractable.Label = "Scanning Sample..";
					bloodMachineInteractable.CanInteract = false;
					bloodMachineInteractable.Values.State = 2;
					bloodMachineInteractable:Sync();

					task.spawn(function()
						task.wait(1);
						for a=1, 30 do
							bloodMachineInteractable.Config:SetAttribute("_Label", `Scanning Sample ({math.round((a/30)*100)}%)`);
							task.wait(1);
						end
						bloodMachineInteractable.Config:SetAttribute("_Uses", 1);
						bloodMachineInteractable.Values.State = 3;
						bloodMachineInteractable.Label = "Scan Complete (Take Printed Report)";
						bloodMachineInteractable.CanInteract = true;
						bloodMachineInteractable:Sync();
					end)
					
					shared.Notify(game.Players:GetPlayers(), `{sampleName} inserted into blood scanner.`, "Inform");
				else
					shared.Notify(game.Players:GetPlayers(), "You do not have any test samples.", "Negative");
				end
				
			elseif state == 2 then
				Debugger:Warn("state 2");

			elseif state == 3 then
				Debugger:Warn("state 3");

				local hasSpace = inventory:SpaceCheck{{ItemId="samplereport"}};
				if not hasSpace then
					shared.Notify(player, "Inventory is full!", "Negative");
					return;
				end
				
				bloodMachineInteractable.Values.State = 4;
				
				inventory:Add("samplereport", {
					CustomName="Stan's Blood Samples Report #1";
					Values={
						Result=false;
						--DescExtend=h3O.."\nReport Status: "..h3C.."Negative";
					};}, function(queueEvent, storageItem)
						table.insert(mission.SaveData.MissionItems, storageItem.ID);
					end);
				shared.Notify(player, "A sample report added to your inventory.", "Inform");
				
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 7 then
						mission.ProgressionPoint = 7;
					end
				end);

			elseif state == 4 and bloodMachineInteractable.CanInteract then
				Debugger:Warn("4: Insert 2nd sample");

				local _, itemList = inventory:ListQuantity("bloodsample", 1);

				if itemList and #itemList > 0 then
					local listItem = itemList[1];
					local storageItem = inventory:Find(listItem.ID);
					local sampleName = storageItem and storageItem.CustomName or "n/a";

					playerClass.WieldComp:Unequip();

					bloodMachineInteractable.Label = "Scanning Sample..";
					bloodMachineInteractable.CanInteract = false;
					bloodMachineInteractable.Values.State = 5;
					bloodMachineInteractable:Sync();
					
					task.spawn(function()
						task.wait(1);
						for a=1, 60 do
							bloodMachineInteractable.Config:SetAttribute("_Label", `Scanning Sample ({math.round((a/60)*100)}%)`);
							task.wait(1);
						end
						
						bloodMachineInteractable.Config:SetAttribute("_Uses", 1);
						bloodMachineInteractable.Values.State = 6;
						bloodMachineInteractable.Label = "Scan Complete (Take Printed Report)";
						bloodMachineInteractable.CanInteract = true;
						bloodMachineInteractable:Sync();
					end)

					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint <= 8 then
							mission.ProgressionPoint = 8;
						end
					end);

					shared.Notify(game.Players:GetPlayers(), sampleName.." inserted into blood scanner.", "Inform");
				end
				
			elseif state == 6 then
				Debugger:Warn("6: Claim Report#2");
				
				local hasSpace = inventory:SpaceCheck{{ItemId="samplereport"}};
				if not hasSpace then
					shared.Notify(player, "Inventory is full!", "Negative");
					return;
				end

				bloodMachineInteractable.Config:SetAttribute("_Uses", 1);
				bloodMachineInteractable.Values.State = 7;
				bloodMachineInteractable.Label = "Insert sample 3/4";
				bloodMachineInteractable.CanInteract = true;
				bloodMachineInteractable:Sync();

				inventory:Add("samplereport", {
					CustomName="Stan's Blood Samples Report #2";
					Values={
						Result=true;
					};}, function(queueEvent, storageItem)
						table.insert(mission.SaveData.MissionItems, storageItem.ID);
					end);
				shared.Notify(player, "Sample report #2 added to your inventory.", "Inform");

			elseif state == 7 and bloodMachineInteractable.CanInteract then
				Debugger:Warn("7: Insert 3rd sample");

				local _, itemList = inventory:ListQuantity("bloodsample", 1);

				if itemList and #itemList > 0 then
					local listItem = itemList[1];
					local storageItem = inventory:Find(listItem.ID);
					local sampleName = storageItem and storageItem.CustomName or "n/a";

					playerClass.WieldComp:Unequip();

					bloodMachineInteractable.Label = "Scanning Sample..";
					bloodMachineInteractable.CanInteract = false;
					bloodMachineInteractable.Values.State = 7;
					bloodMachineInteractable:Sync();

					task.spawn(function()
						task.wait(1);
						for a=1, 10 do
							bloodMachineInteractable.Config:SetAttribute("_Label", `Scanning Sample ({math.round((a/10)*100)}%)`);
							task.wait(1);
						end

						bloodMachineInteractable.Config:SetAttribute("_Uses", 1);
						bloodMachineInteractable.Values.State = 8;
						bloodMachineInteractable.Label = "Scan Complete (Take Printed Report)";
						bloodMachineInteractable.CanInteract = true;
						bloodMachineInteractable:Sync();
					end)

					shared.Notify(game.Players:GetPlayers(), `{sampleName} inserted into blood scanner.`, "Inform");
				end

			elseif state == 8 then
				Debugger:Warn("8: Take Report#3");
				
				local hasSpace = inventory:SpaceCheck{{ItemId="samplereport"}};
				if not hasSpace then
					shared.Notify(player, "Inventory is full!", "Negative");
					return;
				end

				bloodMachineInteractable.Config:SetAttribute("_Uses", 1);
				bloodMachineInteractable.Values.State = 9;
				bloodMachineInteractable.Label = "Insert sample 4/4";
				bloodMachineInteractable.CanInteract = true;
				bloodMachineInteractable:Sync();

				inventory:Add("samplereport", {
					CustomName="Stan's Blood Samples Report #3";
					Values={
						Result=false;
					};}, function(queueEvent, storageItem)
						table.insert(mission.SaveData.MissionItems, storageItem.ID);
					end);
				shared.Notify(player, "Sample report #3 added to your inventory.", "Inform");

			elseif state == 9 and bloodMachineInteractable.CanInteract then
				Debugger:Warn("9: Test sample 4/4");

				local _, itemList = inventory:ListQuantity("bloodsample", 1);

				if itemList and #itemList > 0 then
					local listItem = itemList[1];
					local storageItem = inventory:Find(listItem.ID);
					local sampleName = storageItem and storageItem.CustomName or "n/a";

					playerClass.WieldComp:Unequip();

					bloodMachineInteractable.Label = "Scanning Sample..";
					bloodMachineInteractable.CanInteract = false;
					bloodMachineInteractable.Values.State = 9;
					bloodMachineInteractable:Sync();

					task.spawn(function()
						task.wait(1);
						for a=1, 25 do
							bloodMachineInteractable.Config:SetAttribute("_Label", `Scanning Sample ({math.round((a/25)*100)}%)`);
							task.wait(1);
						end

						bloodMachineInteractable.Config:SetAttribute("_Uses", 1);
						bloodMachineInteractable.Values.State = 10;
						bloodMachineInteractable.Label = "Scan Complete (Take Printed Report)";
						bloodMachineInteractable.CanInteract = true;
						bloodMachineInteractable:Sync();
					end)

					shared.Notify(game.Players:GetPlayers(), `{sampleName} inserted into blood scanner.`, "Inform");
				end
				
			elseif state == 10 then
				Debugger:Warn("10: Take final report");

				local hasSpace = inventory:SpaceCheck{{ItemId="samplereport"}};
				if not hasSpace then
					shared.Notify(player, "Inventory is full!", "Negative");
					return;
				end

				bloodMachineInteractable.Values.State = 11;
				bloodMachineInteractable.Label = "Idle";
				bloodMachineInteractable.CanInteract = false;
				bloodMachineInteractable:Sync();

				inventory:Add("samplereport", {
					CustomName="Stan's Blood Samples Report #4";
					Values={
						Result=true;
					};}, function(queueEvent, storageItem)
						table.insert(mission.SaveData.MissionItems, storageItem.ID);
					end);
				shared.Notify(player, "Sample report #4 added to your inventory.", "Inform");
				
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 12 then
						mission.ProgressionPoint = 12;
					end
				end);
			end
			
		end)

		shared.modEventService:OnInvoked("Players_BindWieldEvent", function(event: EventPacket, ...)
			local action: string, toolHandler: ToolHandlerInstance = ...;

			local playerClass: PlayerClass = toolHandler.CharacterClass :: PlayerClass;
			local player: Player = (playerClass :: PlayerClass):GetInstance();

			if action == "Equip" then
				local missionData = modMission:GetMission(player, MISSION_ID);
				if missionData.Type ~= 1 then return end;
				if missionData.ProgressionPoint ~= 9 then return end;
				
				if patrolBandit then
					if patrolBandit.Properties.Allied then
						patrolBandit.Chat(player, "What the!");
						
					else
						patrolBandit.Chat(player, "He's got a gun!");
						
					end
				end
				
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 10 then
						mission.ProgressionPoint = 10;
					end
				end);

			end
		end)

		local generatorPoint = workspace:WaitForChild("CutscenePoints"):WaitForChild("Generator");
		shared.modEventService:OnInvoked("Generic_BindTrigger", function(eventPacket: EventPacket, interactData, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;
			
			local profile = shared.modProfile:Get(player);
			local playerSave = profile:GetActiveSave();
			local inventory = playerSave.Inventory;
			
			local triggerTag = interactData.TriggerTag;
			if triggerTag == "m75Generator" then

				local _, itemList = inventory:ListQuantity("jerrycan", 1);

				if itemList and #itemList > 0 then
					inventory:Remove(itemList[1].ID, 1);
					
					modAudio.Play("PouringLiquid", generatorPoint);
					
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint <= 5 then
							mission.ProgressionPoint = 5;
						end
					end);
					
					interactData.TriggerTag = "StartGenerator";
					interactData.Label = "Start Generator";
					interactData.ItemRequired = "";
					interactData:Sync();
					shared.Notify(game.Players:GetPlayers(), "Generator now has enough fuel to operate.", "Inform");
				
				else
					shared.Notify(game.Players:GetPlayers(), "You do not have any jerrycans, look for some around.", "Negative");
				end
				
			end
		end)
		
		local generatorActive = false;
		shared.modEventService:OnInvoked("Generic_BindTrigger", function(eventPacket: EventPacket, ...)
			local id: string, interactable: InteractableInstance = ...;
			if id ~= "m75Generator" then return end;

			local player: Player? = eventPacket.Player;
			if player == nil then return end;

			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.Type ~= 1 then return end;

				if mission.ProgressionPoint == 3 then
					if generatorActive then return end;
					generatorActive = true;
					shared.Notify(player, `<b>Generator:</b> `, "Inform");
					task.wait(2);
					mission.ProgressionPoint = 4;
				end;
			end)
		end)

		shared.modEventService:OnInvoked("Interactables_BindPickupableInteract", function(event: EventPacket, ...)
			local interactable: InteractableInstance = ...;
			local player: Player? = event.Player;
			if player == nil then return end;

			if interactable.Values.ItemId == "jerrycan" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.Type ~= 1 then return end;
					if mission.ProgressionPoint <= 4 then
						mission.ProgressionPoint = 5;
					end
				end)
			end
		end)
	end
	
	--MARK: Initialize
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		local profile = shared.modProfile:Get(player);
		local inventory = profile.ActiveInventory;
		
		local playerClass: PlayerClass = shared.modPlayers.get(player);
		playerClass.HealthComp.OnHealthChanged:Connect(function(newHealth, oldHealth, damageData)
			if newHealth > oldHealth then return end;
			if damageData.Damage == nil then return end;

			local damage = math.max(math.ceil(damageData.Damage * 0.5), 1);

			if mission.Type ~= 1 then return end;
			if not (mission.ProgressionPoint == 2 
				or mission.ProgressionPoint == 9 
				or mission.ProgressionPoint == 10 
				or mission.ProgressionPoint == 11) then 
				return 
			end;
			
			local storageItemId = mission.SaveData.SampleId;
			if storageItemId == nil then return end;

			local storageItem = inventory:Find(storageItemId);
			if storageItem == nil then return end;
			
			storageItem.Values.Health = math.max(storageItem.Values.Health-damage, 0);
			storageItem:Sync({"Health"});
			modStorageItem.PopupItemStatus(storageItem);
			
			if storageItem.Values.Health <= 0 then
				inventory:Remove(storageItemId);
				modMission:FailMission(player, MISSION_ID, "Stan's blood samples were destroyed.");

				if modBranchConfigurations.IsWorld("MedicalBreakthrough") then
					modServerManager:Travel(player, profile.PreviousWorldName);
				end
			end
		end)

		local generatorInteractable: InteractableInstance, bloodMachineInteractable: InteractableInstance;

		if modBranchConfigurations.IsWorld("TheMall") then
			player:GetAttributeChangedSignal("Location"):Connect(function()
				local locationId = player:GetAttribute("Location");
				if locationId ~= "Clinic Safehouse" then return end;

				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.Type ~= 1 then return end;
					if mission.ProgressionPoint <= 2 then
						mission.ProgressionPoint = 3;
					end
				end)
			end)

		elseif modBranchConfigurations.IsWorld("MedicalBreakthrough") then
			player:GetAttributeChangedSignal("Location"):Connect(function()
				local locationId = player:GetAttribute("Location");
				if locationId ~= "Clinic Laboratory" then return end;

				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.Type ~= 1 then return end;
					if mission.ProgressionPoint <= 3 then
						mission.ProgressionPoint = 4;
					end
				end)
			end)
			
			playerClass.OnIsDeadChanged:Connect(function(isDead)
				if not isDead then return end;

				modMission:FailMission(player, MISSION_ID, "You died and the bandits stole the sample.");
				modServerManager:Travel(player, profile.PreviousWorldName);
			end)

			local mainHospitalDoorModel = workspace.Environment.Game:WaitForChild("MainHospitalDoor");
			local mainHospitalDoor: DoorInstance = modDoors.getOrNew(mainHospitalDoorModel:WaitForChild("Door"));
			mainHospitalDoor:Toggle(true);
			
			generatorInteractable = modInteractables.getById("m75Generator");
			bloodMachineInteractable = modInteractables.getById("m75bloodmachine");
			bloodMachineInteractable.CanInteract = false;

			generatorInteractable.Values.OnChanged:Connect(function(k, nv, ov)
				if k ~= "IsPowered" then return end;
				if nv ~= true then return end;

				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.Type ~= 1 then return end;
					if mission.ProgressionPoint <= 5 then
						mission.ProgressionPoint = 6;

						generatorInteractable.Label = "Generator is active";
						generatorInteractable.CanInteract = false;
						generatorInteractable:Sync();
					
						for _, lightPart in ipairs(gameFolder:WaitForChild("Lights"):GetChildren()) do
							lightPart.Material = Enum.Material.Neon;
							lightPart:WaitForChild("_lightPoint"):WaitForChild("PointLight").Enabled = true;
						end
					end
				end)
			end)

		end
		

		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				local stage = mission.ProgressionPoint;
				
				if stage == 1 then

				elseif stage == 2 then

				end
				
				if not (stage >= 3 and modBranchConfigurations.IsWorld("MedicalBreakthrough")) then
					return;
				end
				
				
				if stage == 3 then
					
				elseif stage == 4 then

				elseif stage == 6 then
					
					-- Insert first sample
					local scannerState = bloodMachineInteractable.Values.State or 0;
					if scannerState == 0 then
						bloodMachineInteractable.Config:SetAttribute("_Uses", 1);
						bloodMachineInteractable.Values.State = 1;
						bloodMachineInteractable.Label = "Insert sample 1/4";
						bloodMachineInteractable.CanInteract = true;
						bloodMachineInteractable:Sync();
					end
					
					local bmLight:BasePart = gameFolder:WaitForChild("BloodMachine"):WaitForChild("Light");
					bmLight.Color = Color3.fromRGB(102, 199, 102);
					bmLight.Material = Enum.Material.Neon;
					
					local bmPointLight: PointLight = bmLight:WaitForChild("_lightPoint"):WaitForChild("PointLight") :: PointLight;
					bmPointLight.Enabled = true;

				elseif stage == 7 then

					bloodMachineInteractable.Config:SetAttribute("_Uses", 1);
					bloodMachineInteractable.Label = "Insert sample 2/4";
					bloodMachineInteractable.CanInteract = true;
					bloodMachineInteractable:Sync();

				elseif stage == 8 then

					local missionCache = modEvents:GetEvent(player, "MissionCache");
					local banditsAllied = missionCache and missionCache.Value and missionCache.Value.BanditsAllied == true;
					
					task.wait(math.random(3, 4));

					-- patrol bandit
					local patrolBanditSpawn = CFrame.new(498.82, 136.42, -1134.768) * CFrame.Angles(0, math.rad(-165), 0);
					patrolBandit = modNpcs.spawn2{
						Name = "Bandit";
						CFrame = patrolBanditSpawn;
						Player = player;
						BindSetup = function(npcClass: NpcClass)
							npcClass.Properties.Allied = banditsAllied;
							npcClass.Properties.CutsceneActive = true;
								
							local bandanaHandle = npcClass.Character:WaitForChild("Bandana"):WaitForChild("Handle");
							bandanaHandle.Color = Color3.fromRGB(85, 85, 85);

							local interactConfig = modInteractables.createInteractable("Dialogue");
							interactConfig:SetAttribute("NpcName", npcClass.Name);
							interactConfig.Parent = npcClass.Character;
							npcClass.Interactable = interactConfig;

							npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
								if not isDead then return end;
								npcClass:ToggleInteractable(false);
								modMission:Progress(player, MISSION_ID, function(mission)
									if mission.ProgressionPoint <= 9 then
										mission.ProgressionPoint = 10;
									end
								end);
							end)
						end
					};
					patrolBandit.Move:SetMoveSpeed("set", "default", 8);

					Debugger:Warn("walking to point");
					patrolBandit:ToggleInteractable(false);
					task.wait(0.5);
					patrolBandit.Move:MoveTo(Vector3.new(498.82, 136.42, -1119.558));

					task.wait(3);
					Debugger:Warn("walking to point2");
					
					patrolBandit:ToggleInteractable(true);
					CutsceneSequence:NextScene("BanditScout");
					patrolBandit.Chat(player, "What the?! Who are you?!");
					
					patrolBandit.WieldComp:Equip{
						ItemId = "ak47";
						OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
							local equipmentClass: EquipmentClass? = toolHandler.EquipmentClass;
							if equipmentClass == nil then return end;

							equipmentClass:AddBaseModifier("BanditGun", {
								SetValues = {
									Damage = 2
								};
							});
						end
					};
					patrolBandit.Properties.Immortal = nil;
					
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint <= 9 then
							mission.ProgressionPoint = 9;
						end
					end);

					patrolBandit.Move:MoveTo(Vector3.new(507.441, 136.42, -1112.584));
					task.wait(1);
					patrolBandit.Move:Face(playerClass:GetCFrame().Position);

					modDialogueService:InvokeDialogue(player, "talk", {
						NpcModel = patrolBandit.Character;
					});
					
					local threatenMsgs = {
						"Answer me!";
						"Well?!";
						"Are you going to speak or not?!";
					}
					local lastTalkedToTick = nil;
					patrolBandit.ActorEvent.Event:Connect(function(action, player)
						Debugger:StudioLog(`ActorEvent`, action, player);
						if mission.ProgressionPoint ~= 9 then return end;

						if action == "dialogueopen" then
							lastTalkedToTick = tick();
							task.delay(5, function()
								if lastTalkedToTick == nil or tick()-lastTalkedToTick > 4 then
									patrolBandit.Chat(player, threatenMsgs[math.random(1, #threatenMsgs)]);
								end
							end)

						elseif action == "dialogueclose" then
							patrolBandit.Chat(player, "Okay, you asked for this!");

							modMission:Progress(player, MISSION_ID, function(mission)
								if mission.ProgressionPoint <= 10 then
									mission.ProgressionPoint = 10;
								end
							end);

						end
					end)

				elseif stage == 10 then

					-- Bandit aggro-ed
					mission.SaveData.FightBandits = true;
					patrolBandit:ToggleInteractable(false);
					
					patrolBandit.Move:Follow(playerClass.RootPart, 10);
					
					patrolBandit.Move:Face(playerClass.RootPart.Position);
					
					patrolBandit.WieldComp:InvokeToolAction("PrimaryFireRequest", nil, playerClass.Humanoid);
					task.wait(4);
					Debugger:Warn("4s");
					
					task.spawn(function()
						local enemies = {};
						
						local function spawnEnemy(spawnPoint)
							if #enemies >= 6 then return end;
							
							Debugger:StudioLog(`Spawn Aggro Bandit`);
							modNpcs.spawn2{
								Name = "Bandit";
								CFrame = spawnPoint;
								BindSetup = function(npcClass: NpcClass)
									table.insert(enemies, npcClass);

									local npcChar = npcClass.Character;
									local properties = npcClass.Properties;
									properties.Level = properties.Level + 2;
									properties.TargetableDistance = 4096;
									
									local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");
									local banditarmorLib = modClothingLibrary:Find("banditarmor");
									for _, accessory in pairs(banditarmorLib.Accessories) do
										local newAccessory = accessory:Clone();
										
										local destructible: DestructibleInstance = bodyDestructiblesComp:Create("Bandit Armor", newAccessory);
										destructible.HealthComp:SetMaxHealth(100);
										destructible.HealthComp:Reset();
										destructible.OnDestroy:Connect(function()
											local handle = newAccessory:FindFirstChildWhichIsA("BasePart");
											if handle then 
												local cf = handle.CFrame;
												handle.Parent = workspace.Debris;
												handle.CanCollide = true;
												handle.CFrame = cf;
											end;
											game.Debris:AddItem(handle, 10);
											newAccessory:Destroy();
										end)

										newAccessory.Parent = npcChar;
									end


									npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
										if not isDead then return end;

										for a=#enemies, 1, -1 do
											if enemies[a] == npcClass then
												table.remove(enemies, a);
											end
										end
									end)

									local bandanaHandle = npcChar:WaitForChild("Bandana"):WaitForChild("Handle");
									bandanaHandle.Color = Color3.fromRGB(85, 85, 85);

									local targetHandlerComp = npcClass:GetComponent("TargetHandler");
									targetHandlerComp:AddTarget(playerClass.Character);
								end
							};
						end
						
						
						patrolBandit.Move:SetMoveSpeed("set", "default", 16);
						while true do
							task.wait(1);
							if patrolBandit.HealthComp.IsDead then
								patrolBandit.Chat(player, "You.. have no idea who you're messing with..");
								break;
							elseif playerClass.Humanoid.Health <= 0 then
								patrolBandit.Chat(player, "Tragic, should've listen..");
								break;
							end

							patrolBandit.Move:Face(playerClass.RootPart.Position);
						end
						
						local spawnPoints = {
							CFrame.new(498.455, 136.42, -1237.131) * CFrame.Angles(0, math.pi, 0);
							CFrame.new(552.464, 136.42, -1196.059) * CFrame.Angles(0, math.pi, 0);
						}
						
						for a=1, 5 do
							task.wait((a-1)*2);
							for b=1, #spawnPoints do
								for c=1, a do
									spawnEnemy(spawnPoints[b]);
									task.wait(2);
								end
							end
							
							Debugger:Warn("Wave ", a);
							repeat task.wait() until #enemies <= 0;
							Debugger:Warn("Wave ", a, "complete");
						end

						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 11 then
								mission.ProgressionPoint = 11;
							end
						end);
					end)
					
				elseif stage == 11 then
					Debugger:Warn("mission point 11");
					
				end
				

			elseif mission.Type == 3 then -- OnComplete
				
			elseif mission.Type == 4 then -- OnFail
				Debugger:Warn("On fail");
				mission.ProgressionPoint = 1;

				local profile = shared.modProfile:Get(player);
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				
				if mission.SaveData.MissionItems then
					for a, itemIDs in pairs(mission.SaveData.MissionItems) do
						inventory:Remove(itemIDs, 1);
					end
					table.clear(mission.SaveData.MissionItems);
				end
			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
		
		if modBranchConfigurations.IsWorld("MedicalBreakthrough") then
			CutsceneSequence:NextScene("enableInterfaces");
		end
	end)

	CutsceneSequence:NewScene("enableInterfaces", function()
		modConfigurations.Set("DisableInventory", false);
		modConfigurations.Set("DisablePinnedMission", false);
	end);

	CutsceneSequence:NewScene("BanditScout", function()
		local modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);
		modCameraGraphics:Bind("BanditCam", {
			RenderStepped=function(camera)
				camera.CFrame = CFrame.new(517.524658, 142.722305, -1105.28735, 0.604053557, -0.177485421, 0.776928782, 7.4505806e-09, 0.974885404, 0.222707585, -0.796943784, -0.134527311, 0.588882923);
				camera.Focus = CFrame.new(515.97052, 142.27681, -1106.46533, 1, 0, 0, 0, 1, 0, 0, 0, 1);
			end;
		}, 2, 3);
	end)
	
	return CutsceneSequence;
end;