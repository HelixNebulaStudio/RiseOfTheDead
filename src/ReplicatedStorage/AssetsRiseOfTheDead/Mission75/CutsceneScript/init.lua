local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modEntity = require(game.ReplicatedStorage.Library.Entity);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modStorageItem = require(game.ReplicatedStorage.Library.StorageItem);

--== Variables;
local missionId = 75;

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	modEvents = require(game.ServerScriptService.ServerLibrary.Events);
	modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
end

--== Script;
return function(CutsceneSequence)
	--if not modBranchConfigs.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	local modClothingLibrary = require(game.ReplicatedStorage.Library.ClothingLibrary);

	local patrolBandit;

	if RunService:IsServer() and modBranchConfigs.IsWorld("MedicalBreakthrough") then
		local jerCan = script:WaitForChild("JerryCan");
		jerCan.Parent = workspace.Interactables;
		
		modOnGameEvents:ConnectEvent("OnTrigger", function(player, interactData, ...)
			local classPlayer = shared.modPlayers.Get(player);
			
			local mission = modMission:GetMission(player, missionId);
			
			local profile = shared.modProfile:Get(player);
			local playerSave = profile:GetActiveSave();
			local inventory = playerSave.Inventory;

			local triggerTag = interactData.TriggerTag;
			if triggerTag ~= "m75bloodmachine" then return end;

			local bloodMachineInteractData = interactData;
			local state = bloodMachineInteractData.State;
			
			Debugger:Warn("bloodMachineInteractData state", state);
			
			if state == 1 then

				local _, itemList = inventory:ListQuantity("bloodsample", 1);

				if itemList and #itemList > 0 then
					local listItem = itemList[1];
					local storageItem = inventory:Find(listItem.ID);
					local sampleName = storageItem and storageItem.Name or "n/a";
					
					--inventory:Remove(listItem.ID, 1);
					classPlayer:UnequipTools();

					bloodMachineInteractData.Label = "Scanning Sample..";
					bloodMachineInteractData.CanInteract = false;
					bloodMachineInteractData.ItemRequired = "";
					bloodMachineInteractData.State = 2;
					bloodMachineInteractData:Sync();
					task.spawn(function()
						task.wait(1);
						for a=1, 30 do
							bloodMachineInteractData.Label = "Scanning Sample (".. math.round((a/30)*100) .."%)";
							task.wait(1);
						end
						bloodMachineInteractData.State = 3;
						bloodMachineInteractData.Label = "Scan Complete (Take Printed Report)";
						bloodMachineInteractData.CanInteract = true;
						bloodMachineInteractData:Sync();
					end)
					
					shared.Notify(game.Players:GetPlayers(), sampleName.." inserted into blood scanner.", "Inform");

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
				
				bloodMachineInteractData.State = 4;
				
				inventory:Add("samplereport", {Values={
					Name=modStorage.RegisterItemName("Stan's Blood Samples Report #1");
					Result=false;
					--DescExtend=h3O.."\nReport Status: "..h3C.."Negative";
				};}, function(queueEvent, storageItem)
					table.insert(mission.SaveData.MissionItems, storageItem.ID);
				end);
				shared.Notify(player, "A sample report added to your inventory.", "Inform");
				
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint <= 7 then
						mission.ProgressionPoint = 7;
					end
				end);

			elseif state == 4 and bloodMachineInteractData.CanInteract then
				Debugger:Warn("4: Insert 2nd sample");

				local _, itemList = inventory:ListQuantity("bloodsample", 1);

				if itemList and #itemList > 0 then
					local listItem = itemList[1];
					local storageItem = inventory:Find(listItem.ID);
					local sampleName = storageItem and storageItem.Name or "n/a";

					classPlayer:UnequipTools();

					bloodMachineInteractData.Label = "Scanning Sample..";
					bloodMachineInteractData.CanInteract = false;
					bloodMachineInteractData.ItemRequired = "";
					bloodMachineInteractData.State = 5;
					bloodMachineInteractData:Sync();
					
					task.spawn(function()
						task.wait(1);
						for a=1, 60 do
							bloodMachineInteractData.Label = "Scanning Sample (".. math.round((a/60)*100) .."%)";
							task.wait(1);
						end
						
						bloodMachineInteractData.State = 6;
						bloodMachineInteractData.Label = "Scan Complete (Take Printed Report)";
						bloodMachineInteractData.CanInteract = true;
						bloodMachineInteractData:Sync();
					end)

					modMission:Progress(player, missionId, function(mission)
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

				bloodMachineInteractData.State = 7;
				bloodMachineInteractData.Label = "Insert sample 3/4";
				bloodMachineInteractData.CanInteract = true;
				bloodMachineInteractData.ItemRequired = "bloodsample";
				bloodMachineInteractData:Sync();

				inventory:Add("samplereport", {Values={
					Name=modStorage.RegisterItemName("Stan's Blood Samples Report #2");
					Result=true;
				};}, function(queueEvent, storageItem)
					table.insert(mission.SaveData.MissionItems, storageItem.ID);
				end);
				shared.Notify(player, "Sample report #2 added to your inventory.", "Inform");

			elseif state == 7 and bloodMachineInteractData.CanInteract then
				Debugger:Warn("7: Insert 3rd sample");

				local _, itemList = inventory:ListQuantity("bloodsample", 1);

				if itemList and #itemList > 0 then
					local listItem = itemList[1];
					local storageItem = inventory:Find(listItem.ID);
					local sampleName = storageItem and storageItem.Name or "n/a";

					classPlayer:UnequipTools();

					bloodMachineInteractData.Label = "Scanning Sample..";
					bloodMachineInteractData.CanInteract = false;
					bloodMachineInteractData.ItemRequired = "";
					bloodMachineInteractData.State = 7;
					bloodMachineInteractData:Sync();

					task.spawn(function()
						task.wait(1);
						for a=1, 10 do
							bloodMachineInteractData.Label = "Scanning Sample (".. math.round((a/10)*100) .."%)";
							task.wait(1);
						end

						bloodMachineInteractData.State = 8;
						bloodMachineInteractData.Label = "Scan Complete (Take Printed Report)";
						bloodMachineInteractData.CanInteract = true;
						bloodMachineInteractData:Sync();
					end)

					shared.Notify(game.Players:GetPlayers(), sampleName.." inserted into blood scanner.", "Inform");
				end

			elseif state == 8 then
				Debugger:Warn("8: Take Report#3");
				
				local hasSpace = inventory:SpaceCheck{{ItemId="samplereport"}};
				if not hasSpace then
					shared.Notify(player, "Inventory is full!", "Negative");
					return;
				end

				bloodMachineInteractData.State = 9;
				bloodMachineInteractData.Label = "Insert sample 4/4";
				bloodMachineInteractData.CanInteract = true;
				bloodMachineInteractData.ItemRequired = "bloodsample";
				bloodMachineInteractData:Sync();

				inventory:Add("samplereport", {Values={
					Name=modStorage.RegisterItemName("Stan's Blood Samples Report #3");
					Result=false;
				};}, function(queueEvent, storageItem)
					table.insert(mission.SaveData.MissionItems, storageItem.ID);
				end);
				shared.Notify(player, "Sample report #3 added to your inventory.", "Inform");

			elseif state == 9 and bloodMachineInteractData.CanInteract then
				Debugger:Warn("9: Test sample 4/4");

				local _, itemList = inventory:ListQuantity("bloodsample", 1);

				if itemList and #itemList > 0 then
					local listItem = itemList[1];
					local storageItem = inventory:Find(listItem.ID);
					local sampleName = storageItem and storageItem.Name or "n/a";

					classPlayer:UnequipTools();

					bloodMachineInteractData.Label = "Scanning Sample..";
					bloodMachineInteractData.CanInteract = false;
					bloodMachineInteractData.ItemRequired = "";
					bloodMachineInteractData.State = 9;
					bloodMachineInteractData:Sync();

					task.spawn(function()
						task.wait(1);
						for a=1, 25 do
							bloodMachineInteractData.Label = "Scanning Sample (".. math.round((a/25)*100) .."%)";
							task.wait(1);
						end

						bloodMachineInteractData.State = 10;
						bloodMachineInteractData.Label = "Scan Complete (Take Printed Report)";
						bloodMachineInteractData.CanInteract = true;
						bloodMachineInteractData:Sync();
					end)

					shared.Notify(game.Players:GetPlayers(), sampleName.." inserted into blood scanner.", "Inform");
				end
				
			elseif state == 10 then
				Debugger:Warn("10: Take final report");

				local hasSpace = inventory:SpaceCheck{{ItemId="samplereport"}};
				if not hasSpace then
					shared.Notify(player, "Inventory is full!", "Negative");
					return;
				end

				bloodMachineInteractData.State = 11;
				bloodMachineInteractData.Label = "Idle";
				bloodMachineInteractData.CanInteract = false;
				bloodMachineInteractData.ItemRequired = "";
				bloodMachineInteractData:Sync();

				inventory:Add("samplereport", {Values={
					Name=modStorage.RegisterItemName("Stan's Blood Samples Report #4");
					Result=true;
				};}, function(queueEvent, storageItem)
					table.insert(mission.SaveData.MissionItems, storageItem.ID);
				end);
				shared.Notify(player, "Sample report #4 added to your inventory.", "Inform");
				
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint <= 12 then
						mission.ProgressionPoint = 12;
					end
				end);
			end
			
		end)

		modOnGameEvents:ConnectEvent("OnToolEquipped", function(player, storageItem)

			local missionData = modMission:GetMission(player, missionId);
			if missionData.Type ~= 1 then return end;
			if missionData.ProgressionPoint ~= 9 then return end;
			
			if patrolBandit then
				if patrolBandit.Allied then
					patrolBandit.Chat(player, "What the!");
					
				else
					patrolBandit.Chat(player, "He's got a gun!");
					
				end
			end
			
			modMission:Progress(player, missionId, function(mission)
				if mission.ProgressionPoint <= 10 then
					mission.ProgressionPoint = 10;
				end
			end);
		end)
	end
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		local mission = modMission:GetMission(player, missionId);
		if mission == nil then return end;
			
		
		local classPlayer = shared.modPlayers.Get(player);
		classPlayer.OnDamageTaken:Connect(function(dmg)
			if mission.Type ~= 1 then return end;
			if not (mission.ProgressionPoint == 2 
				or mission.ProgressionPoint == 9 
				or mission.ProgressionPoint == 10 
				or mission.ProgressionPoint == 11) then 
				return 
			end;
			if dmg <= 0 then return end;
			
			local storageItemId = mission.SaveData.SampleId;

			if storageItemId == nil then return end;

			local profile = shared.modProfile:Get(player);
			local playerSave = profile:GetActiveSave();
			local inventory = profile.ActiveInventory;
			local storageItem = inventory:Find(storageItemId);
			
			if storageItem == nil then return end;
			
			storageItem.Values.Health = math.max(storageItem.Values.Health-dmg, 0);
			storageItem:Sync({"Health"});
			modStorageItem.PopupItemStatus(storageItem);
			
			if storageItem.Values.Health <= 0 then
				inventory:Remove(storageItemId);
				modMission:FailMission(player, 75, "Stan's blood samples were destroyed.");

				if modBranchConfigs.IsWorld("MedicalBreakthrough") then
					modServerManager:Travel(player, profile.PreviousWorldName);
				end
			end
		end)
		

		if modBranchConfigs.IsWorld("MedicalBreakthrough") then
			local generatorPoint = workspace:WaitForChild("CutscenePoints"):WaitForChild("Generator");
			local generatorLights = workspace:WaitForChild("Generator"):WaitForChild("Lights"):GetChildren();

			local profile = shared.modProfile:Get(player);
			
			classPlayer.Died:Connect(function(character)
				modMission:FailMission(player, missionId, "You died and the bandits stole the sample.");
				
				modServerManager:Travel(player, profile.PreviousWorldName);
			end);
			
			modOnGameEvents:ConnectEvent("OnTrigger", function(player, interactData, ...)
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				
				local triggerTag = interactData.TriggerTag;
				if triggerTag == "m75Generator" then

					local _, itemList = inventory:ListQuantity("jerrycan", 1);

					if itemList and #itemList > 0 then
						inventory:Remove(itemList[1].ID, 1);
						
						modAudio.Play("PouringLiquid", generatorPoint);
						
						modMission:Progress(player, missionId, function(mission)
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
					
				elseif triggerTag == "StartGenerator" then

					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint <= 6 then
							mission.ProgressionPoint = 6;
						end
					end);
					modAudio.Play("GeneratorStart", generatorPoint);
					
					interactData.TriggerTag = "StartGenerator";
					interactData.Label = "Generator is active";
					interactData.CanInteract = false;
					interactData.ItemRequired = "";
					interactData:Sync();
					
					for _, obj in pairs(generatorLights) do
						local lightPoint: PointLight = obj:WaitForChild("_lightPoint"):WaitForChild("PointLight");
						obj.Material = Enum.Material.Neon;
						lightPoint.Enabled = true;
					end
					
				end
			end)
		end
		
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				local stage = mission.ProgressionPoint;
				
				if stage == 1 then

				elseif stage == 2 then

				end
				
				if not (stage >= 3 and modBranchConfigs.IsWorld("MedicalBreakthrough")) then
					return;
				end
				
				local generatorPoint = workspace:WaitForChild("CutscenePoints"):WaitForChild("Generator");
				local interactData = modEntity:GetEntity(workspace.Interactables:WaitForChild("generator")).Interactable;

				local bloodMachineInteractData = modEntity:GetEntity(workspace.Interactables:WaitForChild("bloodmachine")).Interactable;
				
				local doubleDoor = modEntity:GetEntity(workspace.Interactables:WaitForChild("OpenedHospitalDoor"));
				doubleDoor.Door:Toggle(true);
				
				if stage == 3 then
					
				elseif stage == 4 then
					interactData.Label = "Use Jerrycan"
					interactData.CanInteract = true;
					interactData.ItemRequired = "jerrycan";
					interactData:Sync();
					

				elseif stage == 6 then
					
					-- Insert first sample
					local scannerState = bloodMachineInteractData.State or 0;
					if scannerState == 0 then
						bloodMachineInteractData.State = 1;
						bloodMachineInteractData.Label = "Insert sample 1/4";
						bloodMachineInteractData.CanInteract = true;
						bloodMachineInteractData.ItemRequired = "bloodsample";
						bloodMachineInteractData:Sync();
					end
					
					local bmLight:BasePart = workspace:WaitForChild("BloodMachine"):WaitForChild("Light");
					bmLight.Color = Color3.fromRGB(102, 199, 102);
					bmLight.Material = Enum.Material.Neon;
					
					local bmPointLight: PointLight = bmLight:WaitForChild("_lightPoint"):WaitForChild("PointLight") :: PointLight;
					bmPointLight.Enabled = true;

				elseif stage == 7 then

					bloodMachineInteractData.Label = "Insert sample 2/4";
					bloodMachineInteractData.CanInteract = true;
					bloodMachineInteractData.ItemRequired = "bloodsample";
					bloodMachineInteractData:Sync();

				elseif stage == 8 then

					local missionCache = modEvents:GetEvent(player, "MissionCache");
					local banditsAllied = missionCache and missionCache.Value and missionCache.Value.BanditsAllied == true;
					
					task.wait(math.random(3, 4));
					-- patrol bandit
					local patrolBanditSpawn = CFrame.new(498.821, 136.42, -1123.854) * CFrame.Angles(0, math.rad(-165), 0);
					modNpc.Spawn("Bandit", patrolBanditSpawn, function(npc, npcModule)
						npcModule.Owner = player;
						patrolBandit = npcModule;
						
						npcModule.Allied = banditsAllied;

						npcModule:AddComponent(game.ServerScriptService.ServerLibrary.Entity.Npc.Bandit.RandomSkin);
						npcModule.RandomSkin();
						npcModule.Movement:SetWalkSpeed("default", 8);
						
						local newInteractable = script:WaitForChild("BanditInteractable"):Clone();
						newInteractable.Name = "Interactable"
						newInteractable.Parent = npc;
						
						local bandanaHandle = npc:WaitForChild("Bandana"):WaitForChild("Handle");
						bandanaHandle.Color = Color3.fromRGB(85, 85, 85);
						
						npcModule.Interactable = newInteractable;
						
						npcModule.Humanoid.Died:Connect(function()
							modMission:Progress(player, missionId, function(mission)
								if mission.ProgressionPoint <= 9 then
									mission.ProgressionPoint = 10;
								end
							end);
						end)
					end, require(game.ServerStorage.PrefabStorage.CustomNpcModules.CutsceneHuman));
					
					Debugger:Warn("walking to point");
					patrolBandit:ToggleInteractable(false);
					patrolBandit.Movement:Move(Vector3.new(498.82, 136.42, -1119.558)):Wait(1);
					
					Debugger:Warn("walking to point2");
					
					patrolBandit:ToggleInteractable(true);
					CutsceneSequence:NextScene("BanditScout");
					patrolBandit.Chat(player, "What the?! Who are you?!");
					patrolBandit.Wield.Equip("ak47");
					pcall(function()
						patrolBandit.Wield.ToolModule.Configurations.MinBaseDamage = 3;
					end);
					patrolBandit.Immortal = nil;
					
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint <= 9 then
							mission.ProgressionPoint = 9;
						end
					end);

					patrolBandit.Movement:Move(Vector3.new(507.441, 136.42, -1112.584));
					task.wait(1);
					patrolBandit.Movement:Face(classPlayer:GetCFrame().Position);

					shared.OnDialogueHandler(player, "talk", {
						NpcModel=patrolBandit.Prefab;
					});
					
					local threatenMsgs = {
						"Answer me!";
						"Well?!";
						"Are you going to speak or not?!";
					}
					local lastTalkedToTick = nil;
					patrolBandit.BindOnTalkedTo.Event:Connect(function(prefab, target, choice)
						if prefab ~= patrolBandit.Prefab then return end;
						if mission.ProgressionPoint ~= 9 then return end;
						
						lastTalkedToTick = tick();
						task.delay(5, function()
							if lastTalkedToTick == nil or tick()-lastTalkedToTick > 4 then
								patrolBandit.Chat(player, threatenMsgs[math.random(1, #threatenMsgs)]);
							end
						end)
						
						if choice == "close" then
							patrolBandit.Chat(player, "Okay, you asked for this!");

							modMission:Progress(player, missionId, function(mission)
								if mission.ProgressionPoint <= 10 then
									mission.ProgressionPoint = 10;
								end
							end);
							
						end
					end);

				elseif stage == 10 then

					-- Bandit aggro-ed
					mission.SaveData.FightBandits = true;
					patrolBandit:ToggleInteractable(false);
					
					patrolBandit.Follow(classPlayer.RootPart, 10);
					
					patrolBandit.Wield.Targetable.Humanoid = 1;
					patrolBandit.Wield.SetEnemyHumanoid(classPlayer.Humanoid);
					patrolBandit.Movement:Face(classPlayer.RootPart.Position);
					
					patrolBandit.Wield.PrimaryFireRequest();
					task.wait(4);
					Debugger:Warn("4s");
					
					task.spawn(function()
						local enemies = {};
						local weapons = {"xm1014"; "mp5"; "ak47"; };
						
						local function spawnEnemy(spawnPoint)
							modNpc.Spawn("Bandit", spawnPoint, function(npc, npcModule)
								table.insert(enemies, npcModule);
								npcModule.Configuration.Level = npcModule.Configuration.Level + 2;
								npcModule.Properties.AttackDamage = math.clamp(npcModule.Configuration.Level*40, 1*40, 15*40);
								npcModule.ForgetEnemies = false;
								npcModule.Properties.Hostile = true;
								npcModule.AutoSearch = true;
								npcModule.Properties.TargetableDistance = 4096;
								npcModule.Properties.WalkSpeed={Min=8; Max=16};
								npcModule.OnTarget(player);

								npcModule.Properties.WeaponId = weapons[math.random(1, #weapons)];

								npcModule.Speeches = {
									"Come on out!";
									"You're dead meat!";
								}

								npcModule.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject;
								npcModule.Humanoid.Health = npcModule.Humanoid.MaxHealth;

								local bandanaHandle = npc:WaitForChild("Bandana"):WaitForChild("Handle");
								bandanaHandle.Color = Color3.fromRGB(85, 85, 85);
								
								local isAlive = true;
								npcModule.Humanoid.Died:Connect(function()
									isAlive = false;
									for a=#enemies, 1, -1 do
										if enemies[a] == npcModule then
											table.remove(enemies, a);
										end
									end
									npcModule.DeathPosition = npcModule.RootPart.CFrame.p;

									game.Debris:AddItem(npc, 10);
								end);
								
								
								npcModule.BaseArmor = 100;
								npcModule:AddComponent("ArmorSystem");

								local banditarmorLib = modClothingLibrary:Find("banditarmor");
								for _, accessory in pairs(banditarmorLib.Accessories) do
									local newAccessory = accessory:Clone();
									
									npcModule.ArmorSystem.OnArmorChanged:Connect(function()
										if npcModule.ArmorSystem.Armor > 0 then return end;
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

									newAccessory.Parent = npc;
								end
								
							end);
						end
						
						
						patrolBandit.Movement:SetWalkSpeed("default", 16);
						while true do
							task.wait(1);
							if patrolBandit.Humanoid.Health <= 0 then
								patrolBandit.Chat(player, "You.. have no idea who you're messing with..");
								break;
							elseif classPlayer.Humanoid.Health <= 0 then
								patrolBandit.Chat(player, "Tragic, should've listen..");
								break;
							end

							patrolBandit.Wield.SetEnemyHumanoid(classPlayer.Humanoid);
							patrolBandit.Movement:Face(classPlayer.RootPart.Position);
							
							if patrolBandit.IsInVision(classPlayer.RootPart) then
								patrolBandit.Wield.PrimaryFireRequest();
							end
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

						modMission:Progress(player, missionId, function(mission)
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
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
		
		CutsceneSequence:NextScene("enableInterfaces");
	end)

	CutsceneSequence:NewScene("enableInterfaces", function()
		modConfigurations.Set("DisableInventory", false);
		modConfigurations.Set("DisablePinnedMission", false);
	end);

	CutsceneSequence:NewScene("BanditScout", function()
		CutsceneSequence.modData.CameraClass:Bind("BanditCam", {
			RenderStepped=function(camera)
				camera.CFrame = CFrame.new(517.524658, 142.722305, -1105.28735, 0.604053557, -0.177485421, 0.776928782, 7.4505806e-09, 0.974885404, 0.222707585, -0.796943784, -0.134527311, 0.588882923);
				camera.Focus = CFrame.new(515.97052, 142.27681, -1106.46533, 1, 0, 0, 0, 1, 0, 0, 0, 1);
			end;
		}, 2, 3);
	end)
	
	return CutsceneSequence;
end;