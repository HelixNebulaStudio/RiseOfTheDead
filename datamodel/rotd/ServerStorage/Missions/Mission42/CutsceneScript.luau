local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;
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

else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	--if not modBranchConfigs.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;

		local classPlayer = shared.modPlayers.get(player);
		
		if not modBranchConfigs.IsWorld("VindictiveTreasure") and mission.ProgressionPoint >= 2 then
			if mission.ProgressionPoint >= 1 then
				mission.ProgressionPoint = 1
				modMission:FailMission(player, MISSION_ID, "You left Victor behind..");
			end
			
			if modEvents:GetEvent(player, "mission42Bp2") == nil and mission.Type == 3 then
				modItemDrops.Spawn({Type=modItemDrops.Types.Blueprint; ItemId="tacticalbowbp";}, classPlayer.RootPart.CFrame, {player}, false);
			end
		end
		if not modBranchConfigs.IsWorld("VindictiveTreasure") then return; end;
		
		local playerClass: PlayerClass = shared.modPlayers.get(player);
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
		local victorModule;
		modNpcs.spawn("Victor", victorSpawn, function(npc, npcModule)
			npcModule.Owner = player;
			victorModule = npcModule;
			victorModule.RootPart.Anchored = false;
		end);
		victorModule.SetAnimation("PushButton", {script.Parent:WaitForChild("PushButton")});
		victorModule.SetAnimation("LookDown", {script.Parent:WaitForChild("LookDown")});
		victorModule.SetAnimation("Push", {script.Parent:WaitForChild("Push")});
		victorModule.SetAnimation("Focus", {script.Parent:WaitForChild("Focus")});
		victorModule.SetAnimation("Stuck", {script.Parent:WaitForChild("Stuck")});
		
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
		local activeWeakWall;
		
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
						victorModule.Interactable.Parent = victorModule.Prefab;
						victorModule.Actions:Teleport(victorSpawn);
						victorModule.Chat(victorModule.Owner);
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
						
						for _, obj in pairs(victorModule.Prefab:GetChildren()) do
							if obj.Name == "Nekron Mask" then
								obj:Destroy();
							end
						end
						
						if activeWeakWall then activeWeakWall:Destroy(); end
						activeWeakWall = weakWall:Clone();
						activeWeakWall.Parent = cutsceneElements;
						victorModule.StopAnimation("Stuck");
						victorModule.Wield.Equip("lantern");
						
					elseif mission.ProgressionPoint == 3 then
						victorModule.Interactable.Parent = script;
						
						wait(3);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorModule.Movement:SetWalkSpeed("default", 10);
						victorModule.Movement:Move(Vector3.new(-77.7885666, 106.959663, -65.7213898)):Wait(7);
						victorModule.PlayAnimation("Idle");
						victorModule.Chat(victorModule.Owner, "It's got to be here somewhere.");
						
						wait(1.4);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorModule.Movement:Move(Vector3.new(-89.4285507, 106.959663, -60.8513794)):Wait(7);
						victorModule.Movement:Face(Vector3.new(-89.4285507, 106.959663, -63.0313835));
						victorModule.Chat(victorModule.Owner, "Hmmmmm.");
						victorModule.PlayAnimation("Idle");
						
						wait(1);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorModule.Movement:Move(Vector3.new(-99.8985519, 106.959663, -66.8313904)):Wait(3);
						victorModule.Movement:Face(Vector3.new(-102.694046, 106.959663, -69.2457275));
						
						wait(0.3);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorModule.Chat(victorModule.Owner, "Aha! Here it is..");
						victorModule.PlayAnimation("PushButton");
						
						wait(0.3);
						if mission.ProgressionPoint ~= 3 then return end;
						
						remoteCameraShakeAndZoom:FireClient(player, 5, 0, 7, 1, true);
						
						wait(0.2);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorModule.Movement:Face(Vector3.new(-96.7893219, 107.311867, -69.3222656));
						
						table.insert(tweenObjs, TweenService:Create(cutsceneElements.firstGate, TweenInfo.new(5), {Position=Vector3.new(-88.706, 129.802, -70.402)}))
						tweenObjs[#tweenObjs]:Play();
						
						wait(1.2);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorModule.Chat(victorModule.Owner, "Woah!");
						
						wait(1);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorModule.PlayAnimation("Idle");
						
						wait(4);
						if mission.ProgressionPoint ~= 3 then return end;
						
						victorModule.Movement:Move(Vector3.new(-89.3929596, 108.797752, -74.5014954)):Wait(5);
						victorModule.Actions:Teleport(CFrame.new(-89.3929596, 108.797752, -74.5014954));
						victorModule.Movement:Move(Vector3.new(-90.3007202, 108.976707, -107.224884)):Wait(5);
						victorModule.Chat(victorModule.Owner, "Hmmm, there's a button down there..");
						victorModule.PlayAnimation("LookDown");
						
						wait(2.5);
						if mission.ProgressionPoint ~= 3 then return end;
						
						local pushed = false;
						local fellOff = false;
						spawn(function()
							while mission.ProgressionPoint == 3 do
								if classPlayer.RootPart.Position.Y <= 103 then
									fellOff = true;
									break;
								end
								victorModule.Movement:Face(classPlayer.RootPart.Position);
								wait(0.2);
							end
							
							if mission.ProgressionPoint == 3 then
								victorModule.Movement:Face(classPlayer.RootPart.Position);
								if pushed then
									victorModule.Chat(victorModule.Owner, "Oops.. *Smirk*");
									
								elseif fellOff then
									victorModule.PlayAnimation("LookDown");
									victorModule.Chat(victorModule.Owner, "Oh god, you fell!");
									wait(2);
									if mission.ProgressionPoint ~= 3 then return end;
									victorModule.Chat(victorModule.Owner, "Press the button so I could get you back up.");
									
									local distance = 100;
									local timeout = 20;
									repeat
										distance = (classPlayer.RootPart.Position - cutsceneElements.bridgeButton.Position).Magnitude;
										wait(1);
										if mission.ProgressionPoint ~= 3 then return end;
										timeout = timeout -1;
									until distance <= 8 or timeout <= 0;
									
									victorModule.Chat(victorModule.Owner, "Thanks but sike! I'm not helping you back up.");
								end
								
								table.insert(tweenObjs, 
									TweenService:Create(
										cutsceneElements.bridgeButton, 
										TweenInfo.new(3, Enum.EasingStyle.Linear), 
										{Position=Vector3.new(-89.946, 83.336, -114.959)})
									);
								tweenObjs[#tweenObjs]:Play();
								wait(3);
								if mission.ProgressionPoint ~= 3 then return end;
								
								remoteCameraShakeAndZoom:FireClient(player, 2, 0, 55, 1, true);
								table.insert(tweenObjs, 
									TweenService:Create(
										bridgeCFrameTweener, 
										TweenInfo.new(25, Enum.EasingStyle.Linear), 
										{Value=CFrame.new(-89.8137436, 105.176735, -146.230911, -1, 0, 0, 0, 1, 0, 0, 0, -1)})
									);
								tweenObjs[#tweenObjs]:Play();

								wait(2.5);
								if mission.ProgressionPoint ~= 3 then return end;
								
								local activeDialogues = modDialogues:Get(player);
								local gaveMask = activeDialogues.Victor and activeDialogues.Victor.gaveMask == true;
								
								if gaveMask then
									victorModule.Chat(victorModule.Owner, "Time to try out this Nekron Mask..");
									wait(3);
									if mission.ProgressionPoint ~= 3 then return end;
									victorModule.PlayAnimation("Focus");
									nekronMask:Clone().Parent = victorModule.Prefab;
									victorModule.Chat(victorModule.Owner, "Woow, it feels.. incredible..  But.. how do I use this?!");
									wait(2.5);
									if mission.ProgressionPoint ~= 3 then return end;
									
									victorModule.Chat(victorModule.Owner, "Arrghh! It hurts..");
									victorModule.PlayAnimation("Focus");
									
									modMission:Progress(player, MISSION_ID, function(mission)
										mission.ProgressionPoint = 4;
									end)
								else
									victorModule.Chat(victorModule.Owner, "It's a shame that the mask isn't here, it would've been fun to try it out now.");
									wait(3);
									if mission.ProgressionPoint ~= 3 then return end;
									victorModule.Chat(victorModule.Owner, "I have no clue why you trusted me, and now you will starve down there..");
									wait(2.5);
									if mission.ProgressionPoint ~= 3 then return end;
									victorModule.Chat(victorModule.Owner, "When I do find that mask, the cultists will pay..");
									wait(10);
									if mission.ProgressionPoint ~= 3 then return end;
									modMission:Progress(player, MISSION_ID, function(mission)
										mission.ProgressionPoint = 5;
									end)
								end
							end	
						end)
						
						if fellOff then return; end
						victorModule.Chat(victorModule.Owner, "Come take a look.");
						
						local distance = 5;
						repeat
							victorModule.Actions:WaitForOwner(distance);
							distance = distance +2;
							pushed = true;
							victorModule.PlayAnimation("Push");
							CutsceneSequence:NextScene("push");
							wait(1);
						until fellOff == true or mission.ProgressionPoint ~= 3;
							
					elseif mission.ProgressionPoint == 4 then
						CutsceneSequence:NextScene("showInv");
									
						for a=1, 10 do
							modNpcs.spawn("Zombie", zombieSpawn, function(npc, npcModule)
								npcModule.NekronAppearance = victorModule.Prefab;
								npcModule.Properties.TargetableDistance = 4096;
								npcModule.Configuration.Level = math.random(2, 4);
								npcModule.ForgetEnemies = false;
								npcModule.OnTarget({player});
								table.insert(zombies, npcModule);
							end);
							wait(1);
							if mission.ProgressionPoint ~= 4 then return end;
						end
						if mission.ProgressionPoint ~= 4 then return end;
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 5;
						end)
						
					elseif mission.ProgressionPoint == 5 then
						CutsceneSequence:NextScene("showInv");
						
						if activeWeakWall then
							local destructible = shared.require(activeWeakWall.Destructible);
							destructible.Enabled = true;
							destructible.OnDestroy = function()
								game.Debris:AddItem(activeWeakWall, 0);
								modMission:Progress(player, MISSION_ID, function(mission)
									if mission.ProgressionPoint < 6 then
										mission.ProgressionPoint = 6;
									end;
								end)
							end
						end
						
						victorModule.Wield.Unequip();
						victorModule.PlayAnimation("Stuck");
						victorModule.RootPart.Anchored = true;
						victorModule.Actions:Teleport(victorNekronPos);
						
					elseif mission.ProgressionPoint == 7 then
						workspace.StartSpawn.Enabled = false;
						workspace.EndSpawn.Enabled = true;
						victorModule.Interactable.Parent = victorModule.Prefab;
						victorModule.Chat(victorModule.Owner);
						
					elseif mission.ProgressionPoint == 8 then
						modConfigurations.Set("DisableItemDrops", false);
						local saveVictor = mission.SaveData.SaveVictor == 1;
						victorModule.Interactable.Parent = script;
						
						if saveVictor then
							cutsceneElements.NekronTrap:Destroy();
							victorModule.Chat(victorModule.Owner, "Thanks, I promise you will never see me again..");
							victorModule.RootPart.Anchored = false;
							victorModule.StopAnimation("Stuck");
							victorModule.Movement:Face(classPlayer.RootPart.Position);
							wait(3);
							victorModule.Prefab:Destroy();
							
						else
							cutsceneElements.NekronTrap:Destroy();
							victorModule.RootPart.Anchored = false;
							if victorModule.RootPart:CanSetNetworkOwnership() then victorModule.RootPart:SetNetworkOwner(nil) end;
							
							victorModule.Humanoid.PlatformStand = true;
							victorModule.RootPart.Velocity = Vector3.new(0, 20, 30);
							victorModule.Chat(victorModule.Owner, "Ahhhhhhhh");
							wait(2);
							modAudio.Play("HeavySplash", cutsceneElements.splashSound);
						end

						if modEvents:GetEvent(player, "mission42Bp2") == nil then
							local blueprintSpawnCf = CFrame.new(-124.434, 277.531, 488.565);
							modItemDrops.Spawn({Type=modItemDrops.Types.Blueprint; ItemId="tacticalbowbp";}, blueprintSpawnCf, {player}, false);
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
		local classPlayer = shared.modPlayers.get(game.Players.LocalPlayer);
		classPlayer.RootPart.Velocity = Vector3.new(0, 50, -100);
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