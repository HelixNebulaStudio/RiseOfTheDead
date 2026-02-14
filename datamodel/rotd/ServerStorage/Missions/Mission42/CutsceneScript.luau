local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

--== Variables;
local MISSION_ID = 42;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modDialogues = shared.require(game.ServerScriptService.ServerLibrary.DialogueSave);
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
	modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);
	
	bridgeCFrameTweener = script.Parent:WaitForChild("BridgeCFrameTween");
	nekronMask = script.Parent:WaitForChild("Nekron Mask");
	vtExit = script.Parent:WaitForChild("Travel_TheWarehouse");

	if modBranchConfigurations.IsWorld("VindictiveTreasure") then

		shared.modEventService:OnInvoked("Generic_BindItemPickup", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;
			local itemId = interactable.Values.ItemId;

			if itemId == "tacticalbowbp" then
				modMission:CompleteMission(player, MISSION_ID);
				modEvents:NewEvent(player, {Id="mission42Bp2"});
			end
		end)

		shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(eventPacket: EventPacket, ...)
			local player = eventPacket.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;
			if interactable.Id ==  "VT Cave Exit" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 6 then
						mission.ProgressionPoint = 7; 
					end;
				end)
			end
		end)

	end
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	--if not modBranchConfigurations.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;

		local playerClass: PlayerClass = shared.modPlayers.get(player);
		
		if not modBranchConfigurations.IsWorld("VindictiveTreasure") and mission.ProgressionPoint >= 2 then
			if mission.ProgressionPoint >= 1 then
				mission.ProgressionPoint = 1
				modMission:FailMission(player, MISSION_ID, "You left Victor behind..");
			end
			
			if modEvents:GetEvent(player, "mission42Bp2") == nil and mission.Type == 3 then
				local dropPrefab, interactable = modItemDrops.spawn{
					ItemId = "tacticalbowbp";
					SpawnCFrame = playerClass.RootPart.CFrame;
					Players = {player};
					DespawnDuration = false;
				};
			end
		end
		if not modBranchConfigurations.IsWorld("VindictiveTreasure") then return; end;
		
		playerClass.CharacterGarbage:Tag(playerClass.OnIsDeadChanged:Connect(function(isDead)
			if not isDead then return end;
			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint <= 7 then
					mission.ProgressionPoint = 2;
				end;
			end)
		end))
		
		local cutsceneElements = workspace.Environment:WaitForChild("CutsceneElements");
		
		local victorSpawn = CFrame.new(-84.4009476, 105.079651, -5.06139994, -0.813923717, 0, 0.580971837, 0, 1, 0, -0.580971837, 0, -0.813923717);
		local victorNpcClass: NpcClass = modNpcs.spawn2{
			Name = "Victor";
			CFrame = victorSpawn;
		};
		
		victorNpcClass.SetAnimation("PushButton", {script.Parent:WaitForChild("PushButton")});
		victorNpcClass.SetAnimation("LookDown", {script.Parent:WaitForChild("LookDown")});
		victorNpcClass.SetAnimation("Push", {script.Parent:WaitForChild("Push")});
		victorNpcClass.SetAnimation("Focus", {script.Parent:WaitForChild("Focus")});
		victorNpcClass.SetAnimation("Stuck", {script.Parent:WaitForChild("Stuck")});
		
		local victorNekronPos = CFrame.new(-124.74456, 277.363892, 488.052307, 0.999588668, 0.00731913559, 0.0277291685, -0.00711599784, 0.99994725, -0.00741736963, -0.0277819913, 0.00721699791, 0.999588013);
		
		local tweenObjs = {};
		
		local bridgeDefaultCF = CFrame.new(-89.8137436, 105.176735, -195.79068, -1, 0, 0, 0, 1, 0, 0, 0, -1);

		bridgeCFrameTweener.Value = bridgeDefaultCF;
		bridgeCFrameTweener:GetPropertyChangedSignal("Value"):Connect(function()
			cutsceneElements.Bridge:SetPrimaryPartCFrame(bridgeCFrameTweener.Value);
		end)
		
		
		local zombieSpawn = CFrame.new(-90.0430374, 109.353867, -184.626266, -0.999588668, -0.00731913559, -0.0277291685, -0.00711599784, 0.99994725, -0.00741736963, 0.0277819913, -0.00721699791, -0.999588013);
		local zombies = {};
		
		local weakWall = cutsceneElements:WaitForChild("weakWall");
		weakWall.Parent = game.ServerStorage;
		
		local weakWallDestructible: DestructibleInstance;
		
		if not modMission:IsComplete(player, MISSION_ID) then
			CutsceneSequence:NextScene("showInterface");
			
			if mission.Type == 1 and mission.ProgressionPoint > 2 then
				mission.ProgressionPoint = 2;
			end
			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then

					elseif mission.ProgressionPoint == 2 then
						victorNpcClass.RootPart.Anchored = false;

						victorNpcClass:ToggleInteractable(true);
						victorNpcClass:SetCFrame(victorSpawn);
						CutsceneSequence:NextScene("hideInv");
						
						for a=1, #zombies do
							if zombies[a] and zombies[a].Prefab then zombies[a].Prefab:Destroy(); end
						end
						zombies = {};
						
						for a=1, #tweenObjs do
							if tweenObjs[a] then tweenObjs[a]:Cancel(); end
						end
						tweenObjs = {};
						
						cutsceneElements.firstGate.Position = Vector3.new(-88.706, 115.984, -70.402);
						cutsceneElements.bridgeButton.Position = Vector3.new(-89.946, 84.157, -114.959);
						bridgeCFrameTweener.Value = bridgeDefaultCF;
						
						for _, obj in pairs(victorNpcClass.Character:GetChildren()) do
							if obj.Name == "Nekron Mask" then
								obj:Destroy();
							end
						end
						
						if weakWallDestructible == nil then
							local newWeakWall = weakWall:Clone();
							newWeakWall.Parent = cutsceneElements;

							weakWallDestructible = modDestructibles.getOrNew(newWeakWall.Destructible);
							weakWallDestructible:SetEnabled(false);

							weakWallDestructible.OnDestroy:Connect(function()
								Debugger:Warn(`Weak wall destroyed`);
								modMission:Progress(player, MISSION_ID, function(mission)
									if mission.ProgressionPoint < 6 then
										mission.ProgressionPoint = 6;
									end;
								end)
							end)
						end

						victorNpcClass.StopAnimation("Stuck");
						victorNpcClass.WieldComp:Equip{
							ItemId = "lantern";
						};
						
					elseif mission.ProgressionPoint == 3 then
						victorNpcClass:ToggleInteractable(false);
						
						task.wait(3);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorNpcClass.Move:SetMoveSpeed("set", "default", 10);
						victorNpcClass.Move:MoveTo(Vector3.new(-77.7885666, 106.959663, -65.7213898));
						victorNpcClass.Move.OnMoveToEnded:Wait(7);
						victorNpcClass.PlayAnimation("Idle");
						victorNpcClass.Chat(victorNpcClass.Player, "It's got to be here somewhere.");
						
						task.wait(1.4);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorNpcClass.Move:MoveTo(Vector3.new(-89.4285507, 106.959663, -60.8513794));
						victorNpcClass.Move.OnMoveToEnded:Wait(7);
						victorNpcClass.Move:Face(Vector3.new(-89.4285507, 106.959663, -63.0313835));
						victorNpcClass.Chat(victorNpcClass.Player, "Hmmmmm.");
						victorNpcClass.PlayAnimation("Idle");
						
						task.wait(1);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorNpcClass.Move:MoveTo(Vector3.new(-99.8985519, 106.959663, -66.8313904));
						victorNpcClass.Move.OnMoveToEnded:Wait(3);
						victorNpcClass.Move:Face(Vector3.new(-102.694046, 106.959663, -69.2457275));
						
						task.wait(0.3);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorNpcClass.Chat(victorNpcClass.Player, "Aha! Here it is..");
						victorNpcClass.PlayAnimation("PushButton");
						
						task.wait(0.3);
						if mission.ProgressionPoint ~= 3 then return end;
						
						shared.modPlayers.cameraShakeAndZoom(player, 5, 0, 7, 1, true);
						
						task.wait(0.2);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorNpcClass.Move:Face(Vector3.new(-96.7893219, 107.311867, -69.3222656));
						
						table.insert(tweenObjs, TweenService:Create(cutsceneElements.firstGate, TweenInfo.new(5), {Position=Vector3.new(-88.706, 129.802, -70.402)}))
						tweenObjs[#tweenObjs]:Play();
						
						task.wait(1.2);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorNpcClass.Chat(victorNpcClass.Player, "Woah!");
						
						task.wait(1);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorNpcClass.PlayAnimation("Idle");
						
						task.wait(4);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorNpcClass.Move:MoveTo(Vector3.new(-89.3929596, 108.797752, -74.5014954));
						victorNpcClass.Move.OnMoveToEnded:Wait(5);
						victorNpcClass:SetCFrame(CFrame.new(-89.3929596, 108.797752, -74.5014954));
						victorNpcClass.Move:MoveTo(Vector3.new(-90.3007202, 108.976707, -107.224884));
						victorNpcClass.Move.OnMoveToEnded:Wait(5);
						victorNpcClass.Chat(victorNpcClass.Player, "Hmmm, there's a button down there..");
						victorNpcClass.PlayAnimation("LookDown");
						
						task.wait(2.5);
						if mission.ProgressionPoint ~= 3 then return end;
						
						local pushed = false;
						local fellOff = false;
						spawn(function()
							while mission.ProgressionPoint == 3 do
								if playerClass.RootPart.Position.Y <= 103 then
									fellOff = true;
									break;
								end
								victorNpcClass.Move:Face(playerClass.RootPart.Position);
								wait(0.2);
							end
							
							if mission.ProgressionPoint == 3 then
								victorNpcClass.Move:Face(playerClass.RootPart.Position);
								if pushed then
									victorNpcClass.Chat(victorNpcClass.Player, "Oops.. *Smirk*");
									
								elseif fellOff then
									victorNpcClass.PlayAnimation("LookDown");
									victorNpcClass.Chat(victorNpcClass.Player, "Oh god, you fell!");
									task.wait(2);
									if mission.ProgressionPoint ~= 3 then return end;
									victorNpcClass.Chat(victorNpcClass.Player, "Press the button so I could get you back up.");
									
									local distance = 100;
									local timeout = 20;
									repeat
										distance = playerClass:DistanceFromCharacter(cutsceneElements.bridgeButton.Position);
										task.wait(1);
										if mission.ProgressionPoint ~= 3 then return end;
										timeout = timeout -1;
									until distance <= 8 or timeout <= 0;
									
									victorNpcClass.Chat(victorNpcClass.Player, "Thanks but sike! I'm not helping you back up.");
								end
								
								table.insert(tweenObjs, 
									TweenService:Create(
										cutsceneElements.bridgeButton, 
										TweenInfo.new(3, Enum.EasingStyle.Linear), 
										{Position=Vector3.new(-89.946, 83.336, -114.959)})
									);
								tweenObjs[#tweenObjs]:Play();
								task.wait(3);

								if mission.ProgressionPoint ~= 3 then return end;
								
								shared.modPlayers.cameraShakeAndZoom(player, 2, 0, 55, 1, true);

								table.insert(tweenObjs, 
									TweenService:Create(
										bridgeCFrameTweener, 
										TweenInfo.new(25, Enum.EasingStyle.Linear), 
										{Value=CFrame.new(-89.8137436, 105.176735, -146.230911, -1, 0, 0, 0, 1, 0, 0, 0, -1)})
									);
								tweenObjs[#tweenObjs]:Play();

								task.wait(2.5);
								if mission.ProgressionPoint ~= 3 then return end;
								
								local activeDialogues = modDialogues:Get(player);
								local gaveMask = activeDialogues.Victor and activeDialogues.Victor.gaveMask == true;
								
								if gaveMask then
									victorNpcClass.Chat(victorNpcClass.Player, "Time to try out this Nekron Mask..");
									task.wait(5);

									if mission.ProgressionPoint ~= 3 then return end;
									victorNpcClass.PlayAnimation("Focus");
									nekronMask:Clone().Parent = victorNpcClass.Character;
									victorNpcClass.Chat(victorNpcClass.Player, "Woow, it feels.. incredible..  But.. how do I use this?!");
									task.wait(6);
									
									if mission.ProgressionPoint ~= 3 then return end;
									victorNpcClass.Chat(victorNpcClass.Player, "Arrghh! It hurts..");
									victorNpcClass.PlayAnimation("Focus");
									
									modMission:Progress(player, MISSION_ID, function(mission)
										mission.ProgressionPoint = 4;
									end)
								else
									victorNpcClass.Chat(victorNpcClass.Player, "It's a shame that the mask isn't here, it would've been fun to try it out now.");
									task.wait(7);

									if mission.ProgressionPoint ~= 3 then return end;
									victorNpcClass.Chat(victorNpcClass.Player, "I have no clue why you trusted me, and now you will starve down there..");
									task.wait(8);

									if mission.ProgressionPoint ~= 3 then return end;
									victorNpcClass.Chat(victorNpcClass.Player, "When I do find that mask, the cultists will pay..");
									task.wait(10);

									if mission.ProgressionPoint ~= 3 then return end;
									modMission:Progress(player, MISSION_ID, function(mission)
										mission.ProgressionPoint = 5;
									end)
								end
							end	
						end)
						
						if fellOff then return; end
						victorNpcClass.Chat(victorNpcClass.Player, "Come take a look.");
						
						local distance = 5;
						repeat
							victorNpcClass:GetComponent("WaitForPlayer")(distance);
							distance = distance +2;
							pushed = true;
							victorNpcClass.PlayAnimation("Push");
							CutsceneSequence:NextScene("push");
							task.wait(1);
						until fellOff == true or mission.ProgressionPoint ~= 3;
							
					elseif mission.ProgressionPoint == 4 then
						CutsceneSequence:NextScene("showInv");
									
						for a=1, 10 do
							modNpcs.spawn2{
								Name = "Zombie";
								CFrame = zombieSpawn;
								BindSetup = function(npcClass: NpcClass)
									npcClass.Properties.TargetableDistance = 4096;
									npcClass.Properties.Level = math.random(2, 4);
									
									table.insert(zombies, npcClass);
								end
							};
							wait(1);
							if mission.ProgressionPoint ~= 4 then return end;
						end
						if mission.ProgressionPoint ~= 4 then return end;
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 5;
						end)
						
					elseif mission.ProgressionPoint == 5 then
						CutsceneSequence:NextScene("showInv");
					
						weakWallDestructible:SetEnabled(true);
						

						victorNpcClass.WieldComp:Unequip();
						victorNpcClass.PlayAnimation("Stuck");
						victorNpcClass.RootPart.Anchored = true;
						victorNpcClass:SetCFrame(victorNekronPos);
						
					elseif mission.ProgressionPoint == 6 then
						victorNpcClass:ToggleInteractable(true);

					elseif mission.ProgressionPoint == 7 then
						workspace.StartSpawn.Enabled = false;
						workspace.EndSpawn.Enabled = true;
						victorNpcClass:ToggleInteractable(true);
						
					elseif mission.ProgressionPoint == 8 then
						modConfigurations.Set("DisableItemDrops", false);
						local saveVictor = mission.SaveData.SaveVictor == 1;
						victorNpcClass:ToggleInteractable(false);
						
						if saveVictor then
							cutsceneElements.NekronTrap:Destroy();
							victorNpcClass.Chat(victorNpcClass.Player, "Thanks, I promise you will never see me again..");
							victorNpcClass.RootPart.Anchored = false;
							victorNpcClass.StopAnimation("Stuck");
							victorNpcClass.Move:Face(playerClass.RootPart.Position);
							wait(3);
							victorNpcClass.Character:Destroy();
							
						else
							cutsceneElements.NekronTrap:Destroy();
							victorNpcClass.RootPart.Anchored = false;
							if victorNpcClass.RootPart:CanSetNetworkOwnership() then 
								victorNpcClass.RootPart:SetNetworkOwner(nil);
							end;
							
							victorNpcClass.Humanoid.PlatformStand = true;
							victorNpcClass.RootPart.AssemblyLinearVelocity = Vector3.new(0, 20, 30);
							victorNpcClass.Chat(victorNpcClass.Player, "Ahhhhhhhh");
							wait(2);
							modAudio.Play("HeavySplash", cutsceneElements.splashSound);
						end

						if modEvents:GetEvent(player, "mission42Bp2") == nil then
							local blueprintSpawnCf = CFrame.new(-124.434, 277.531, 488.565);
							local dropPrefab = modItemDrops.spawn{
								ItemId = "tacticalbowbp";
								Quantity = 1;
								SpawnCFrame = blueprintSpawnCf;
								CanInteractNames = {player.Name};
								DespawnDuration = false;
							};
							dropPrefab.PrimaryPart.Anchored = true;
							dropPrefab:PivotTo(blueprintSpawnCf);
						end
					end

				elseif mission.Type == 3 then -- OnComplete
					local newVtExit = vtExit:Clone();
					modReplicationManager.ReplicateIn(player, newVtExit, workspace.Interactables);
					mission.OnChanged:Disconnect(OnChanged);

				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		else -- Loading Completed
			
		end

	end)
	
	CutsceneSequence:NewScene("push", function()
		local playerClass: PlayerClass = shared.modPlayers.get(game.Players.LocalPlayer);
		playerClass.RootPart.AssemblyLinearVelocity = Vector3.new(0, 50, -100);
	end)
	
	
	CutsceneSequence:NewScene("showInterface", function()
		modConfigurations.Set("DisablePinnedMission", false);
		modConfigurations.Set("DisableDialogue", false);
		modConfigurations.Set("DisableMajorNotifications", false);
	end)
	
	CutsceneSequence:NewScene("hideInv", function()
		modConfigurations.Set("DisableHotbar", true);
		modConfigurations.Set("CanQuickEquip", false);
		modConfigurations.Set("DisableInventoryHotkey", true);
		modConfigurations.Set("DisableHealthbar", true);
		modConfigurations.Set("DisableInventory", true);
		modConfigurations.Set("DisableMajorNotifications", true);
	end)
	
	CutsceneSequence:NewScene("showInv", function()
		modConfigurations.Set("DisableHotbar", false);
		modConfigurations.Set("CanQuickEquip", true);
		modConfigurations.Set("DisableInventoryHotkey", false);
		modConfigurations.Set("DisableHealthbar", false);
		modConfigurations.Set("DisableInventory", false);
		modConfigurations.Set("DisableMajorNotifications", false);
	end)

	return CutsceneSequence;
end;