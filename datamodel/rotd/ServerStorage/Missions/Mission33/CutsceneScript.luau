local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modNpcProfileLibrary = shared.require(game.ReplicatedStorage.Library.NpcProfileLibrary);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modDialogueService = shared.require(game.ReplicatedStorage.Library.DialogueService);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

--== Variables;
local MISSION_ID = 33;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);

	modMatchMaking = shared.require(game.ServerScriptService.ServerLibrary.MatchMaking);
	modRaid = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager.Raid);
	
	if modBranchConfigs.IsWorld("TheMall") then
		shared.modEventService:OnInvoked("Generic_BindTrigger", function(eventPacket: EventPacket, ...)
			local triggerId: string = ...;
			local player: Player? = eventPacket.Player;
			if player == nil then return end;
			
			if triggerId ~= "awokenTheBearVentLadder" then return end;

			local mission = modMission:GetMission(player, MISSION_ID);
			if mission.Type == 2 and mission.ProgressionPoint > 2 then
				modServerManager:Travel(player, "AwokenTheBear");
			end
		end)

	elseif modBranchConfigs.IsWorld("AwokenTheBear") then
		shared.modEventService:OnInvoked("Generic_BindTrigger", function(eventPacket: EventPacket, ...)
			local triggerId: string = ...;
			local player: Player? = eventPacket.Player;
			if player == nil then return end;
			
			if triggerId ~= "awokenTheBearForfeit" then return end;

			modMission:FailMission(player, MISSION_ID, "You left Stan behind..");
			task.wait(2);
			modServerManager:Travel(player, "TheMall");
		end)

		shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;
			
			local interactable: InteractableInstance = ...;
			if interactable == nil then return end;

			if interactable.Id == "throneRoomDoor" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint < 6 then 
						mission.ProgressionPoint = 6;
					end;
				end)
				modAudio.Play("Suspense", workspace);
			end
		end)

	elseif modBranchConfigs.IsWorld("BanditOutpost") then
        shared.modEventService:OnInvoked("GameModeManager_BindGameModeComplete", function(eventPacket: EventPacket, packet)
			local room = packet.Room;
			Debugger:Warn("GameModeManager_BindGameModeComplete", room.Type, room.Stage);

			if room.Type ~= "Raid" or room.Stage ~= "BanditOutpost" then return end;
			if eventPacket.Players == nil then return end;
			
			for _, player: Player in pairs(eventPacket.Players) do
				if not modMission:Progress(player, MISSION_ID) then continue end;

				modMission:CompleteMission(player, MISSION_ID);
			end
		end)

	end

else
	modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	-- MARK: TheMall
	if modBranchConfigs.IsWorld("TheMall") then
		local stanNpcProfile = modNpcProfileLibrary:Find("Stan");
		stanNpcProfile.World = "TheMall";

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;

			local stanNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Stan");
			local stanMallShopSpawnCf = CFrame.new(755.090332, 94.8246002, -653.329224, -1, 0, 0, 0, 1, 0, 0, 0, -1);
			if stanNpcClass == nil and mission.ProgressionPoint <= 13 then
				stanNpcClass = modNpcs.spawn2{
					Name = "Stan";
					CFrame = stanMallShopSpawnCf;
					Player = player;
					ReplicateOut = true;
				};
			end

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 4 and firstRun then
					stanNpcClass:SetCFrame(stanMallShopSpawnCf);
					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 3;
					end)

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						
						if mission.Redo then
							Debugger:Warn("Redo");
							if stanNpcClass == nil then
								stanNpcClass = modNpcs.spawn2{
									Name = "Stan";
									CFrame = stanMallShopSpawnCf;
									Player = player;
									ReplicateOut = true;
								};
							end
						end
							
						stanNpcClass:SetCFrame(stanMallShopSpawnCf);
						stanNpcClass:ToggleInteractable(false);

						stanNpcClass.Move:SetMoveSpeed("set", "default", 25);

						local waypoint = Vector3.new(735.36, 94.775, -695.904);

						stanNpcClass.Move:MoveTo(waypoint);
						stanNpcClass.Move.OnMoveToEnded:Wait(5);
						if stanNpcClass == nil then return end;

						stanNpcClass.Chat(stanNpcClass.Player, "When you're ready.");
						wait(0.1);

						stanNpcClass.Move:Face("Player");
						stanNpcClass:GetComponent("WaitForPlayer")(20);
						stanNpcClass:UseInteractable("mallShopSafehouseExit");

						waypoint = Vector3.new(793.870911, 162.633194, -727.308044);

						stanNpcClass.Move:MoveTo(waypoint);
						stanNpcClass.Move.OnMoveToEnded:Wait(60);
						if stanNpcClass == nil then return end;

						if not stanNpcClass.Move:IsAtPosition(waypoint) then
							stanNpcClass:SetCFrame(CFrame.new(waypoint));
						end

						task.wait(1);
						if stanNpcClass == nil then return end;

						stanNpcClass.Chat(stanNpcClass.Player, "Patrick, is there a way in yet?");
						stanNpcClass:ToggleInteractable(true);
						
						task.wait(1);
						if stanNpcClass == nil then return end;

						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 1 then
								mission.ProgressionPoint = 2;
							end;
						end)

					elseif mission.ProgressionPoint == 2 then
						stanNpcClass:ToggleInteractable(false);
						stanNpcClass:SetCFrame(CFrame.new(Vector3.new(793.870911, 162.633194, -727.308044)));
						
						local waitForPlayer = stanNpcClass:GetComponent("WaitForPlayer");
						waitForPlayer.FacePlayerWhileWaiting = false;
						waitForPlayer(20);
						waitForPlayer.FacePlayerWhileWaiting = true;
						if stanNpcClass == nil then return end;

						stanNpcClass.Move:Face("Player");

					elseif mission.ProgressionPoint == 3 then
						stanNpcClass:ToggleInteractable(false);
						stanNpcClass.Chat(stanNpcClass.Player, "Alright, let's go..");
						
						stanNpcClass:GetComponent("FollowPlayer")(nil, function()
							return mission.Type == 1 and mission.ProgressionPoint == 3
						end);

					end
				elseif mission.Type == 3 then -- OnComplete

				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)
		

	-- MARK: AwokenTheBear
	elseif modBranchConfigs.IsWorld("AwokenTheBear") then

		CutsceneSequence:Initialize(function()
			local players: {Player} = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;


			local playerClass: PlayerClass = shared.modPlayers.get(player);
			playerClass.OnIsDeadChanged:Connect(function(isDead)
				if not isDead then return end;
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 13 then
						mission.ProgressionPoint = 4;
					end;
				end)
			end)
			if modMission:IsComplete(player, MISSION_ID) then return end;

			local stanNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Stan");
			if stanNpcClass == nil then
				stanNpcClass = modNpcs.spawn2{
					Name = "Stan";
					CFrame = CFrame.new(-0.0199999996, 163.47496, -38.7299995, 1, 0, 0, 0, 1, 0, 0, 0, 1);
					Player = player;
				};
			end
			
			local zarkNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Zark");
			if zarkNpcClass == nil then
				zarkNpcClass = modNpcs.spawn2{
					Name = "Zark";
					CFrame = CFrame.new(-66.0924, 194.8646, -32.347, -0.0348989, 0, 0.9993, 0, 1, 0, -0.9993, 0, -0.0348989);
					Player = player;
				};
			end

			local jasonNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Jason");
			if jasonNpcClass == nil then
				jasonNpcClass = modNpcs.spawn2{
					Name = "Jason";
					CFrame = CFrame.new(-113.027, 194.8646, -44.03829, -0.422619, 0, 0.906306, 0, 1, 0, -0.906306, 0, -0.422619);
					Player = player;
				};
				jasonNpcClass:ToggleInteractable(false);
				jasonNpcClass.WieldComp:Equip{
					ItemId="ak47";
				};
			end

			local loranNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Loran");
			if loranNpcClass == nil then
				loranNpcClass = modNpcs.spawn2{
					Name = "Loran";
					CFrame = CFrame.new(-115.057, 194.8646, -31.1187, 0.694657, 0, 0.71934, 0, 1, 0, -0.71934, 0, 0.694657);
					Player = player;
				};
				loranNpcClass:ToggleInteractable(false);
				loranNpcClass.WieldComp:Equip{
					ItemId="ak47";
				};
			end

			local function OnChanged(firstRun)
				if mission.Type == 1 then -- OnActive
					Debugger:Warn("Mission progression point, ",mission.ProgressionPoint);
					
					if mission.ProgressionPoint == 4 then
						CutsceneSequence:NextScene("enableInterfaces");
						
						stanNpcClass.StopAnimation("Surrender");
						stanNpcClass.StopAnimation("Shot");
						stanNpcClass:ToggleInteractable(false);

						zarkNpcClass:ToggleInteractable(false);
						zarkNpcClass:SetCFrame(CFrame.new(-66.0924149, 194.864609, -32.347641, -0.0348989964, 0, 0.9993909, 0, 1, 0, -0.9993909, 0, -0.0348989964));
						
						local exitPosition = Vector3.new(-101.99, 180.193, -70.54);
						stanNpcClass:GetComponent("FollowPlayer")(nil, function()
							if (stanNpcClass.RootPart.Position-exitPosition).Magnitude <= 20 then
								modMission:Progress(player, MISSION_ID, function(mission)
									if mission.ProgressionPoint < 5 then mission.ProgressionPoint = 5; end;
								end)
							end
							return mission.Type == 1 and mission.ProgressionPoint == 4
						end);

					elseif mission.ProgressionPoint == 5 then
						task.wait(1);
						jasonNpcClass.Move:SetMoveSpeed("set", "default", 18);

						local waypoint = Vector3.new(-143.957703, 194.634598, -65.9168854);
						stanNpcClass.Move:MoveTo(waypoint);
						stanNpcClass.Move.OnMoveToEnded:Wait(5);
						stanNpcClass.Move:Face(Vector3.new(-132.616409, 194.718018, -64.660614));
					
						task.wait(2);
						if mission.ProgressionPoint ~= 5 then return end;

						stanNpcClass.Chat(player, "It's too quiet, something's not right..");
						wait(3);
						if mission.ProgressionPoint ~= 5 then return end;

						waypoint = Vector3.new(-132.53479, 194.634567, -40.8270035);
						stanNpcClass.Move:MoveTo(waypoint);
						stanNpcClass.Move.OnMoveToEnded:Wait(5);
						task.wait(1);
						if mission.ProgressionPoint ~= 5 then return end;

						stanNpcClass:UseInteractable("throneRoomDoor");
						wait(1/60);
						if mission.ProgressionPoint ~= 5 then return end;
						stanNpcClass:SetCFrame(CFrame.new(-119.893661, 194.634567, -33.8498764, 0, 0, -1, 0, 1, 0, 1, 0, 0));

					elseif mission.ProgressionPoint == 6 then
						stanNpcClass:SetCFrame(CFrame.new(-119.893661, 194.634567, -33.8498764, 0, 0, -1, 0, 1, 0, 1, 0, 0));
						stanNpcClass.PlayAnimation("Surrender");

						loranNpcClass.Chat(player, "STAY RIGHT THERE!");
						CutsceneSequence:NextScene("freezePlayer");
						task.wait(1);

						stanNpcClass.Chat(player, "Oh god.");

						loranNpcClass.Move:HeadTrack(stanNpcClass.Head);
						jasonNpcClass.Move:HeadTrack(playerClass.Head);
						wait(1);

						zarkNpcClass.Move:MoveTo(Vector3.new(-79.5326004, 194.909668, -33.090416));
						zarkNpcClass.Move.OnMoveToEnded:Wait(5);
						wait(1);

						CutsceneSequence:NextScene("walkToZark");
						jasonNpcClass.Chat(player, "WALK!");
						wait(0.2);

						stanNpcClass.Move:SetMoveSpeed("set", "default", 10);
						stanNpcClass.Move:MoveTo(Vector3.new(-95.599, 194.91, -27.702));
						wait(0.2);

						loranNpcClass.Move:SetMoveSpeed("set", "default", 10);
						jasonNpcClass.Move:SetMoveSpeed("set", "default", 10);
						loranNpcClass.Move:MoveTo(Vector3.new(-109.017929, 194.909668, -25.8456249))
						jasonNpcClass.Move:MoveTo(Vector3.new(-108.607742, 194.909668, -38.5568581))
						jasonNpcClass.Move.OnMoveToEnded:Wait(5);

						modStatusEffects.Slowness(player, 10, 60);

						spawn(function()
							local position = Vector3.new(-99.4085159, 194.909668, -36.03228);
							local initMag = (playerClass.RootPart.Position-position).Magnitude;
							local shoutCD = tick()-5;
							local count = 0;
							repeat
								local dist = (playerClass.RootPart.Position-position).Magnitude;
								if dist <= 4 then
									modMission:Progress(player, MISSION_ID, function(mission)
										if mission.ProgressionPoint < 7 then mission.ProgressionPoint = 7; end;
									end)

								elseif dist >= (initMag + 5) then
									if tick()- shoutCD >= 5 then
										if jasonNpcClass.WieldComp.ToolHandler then
											jasonNpcClass.WieldComp.ToolHandler.ToolAnimator:Play("Load");
										end
										shoutCD = tick();
										count = count +1;
										if count == 1 then
											jasonNpcClass.Chat(player, "WALK TOWARDS ZARK OR ELSE");

										elseif count == 2 then
											jasonNpcClass.Chat(player, "I SAID WALK!");

										elseif count == 3 then
											jasonNpcClass.Chat(player, "LAST WARNING!!");

										elseif count > 3 then
											jasonNpcClass.WieldComp.TargetableTags.Player = true;
											jasonNpcClass.Move:Face(playerClass.RootPart.Position);
											jasonNpcClass.WieldComp:InvokeToolAction(
												"PrimaryFireRequest", 
												(playerClass.RootPart.Position - jasonNpcClass.RootPart.Position).Unit, 
												playerClass.Humanoid
											);
										end
									end
								end 
								task.wait(0.1);
								initMag = initMag -0.1;
							until mission.ProgressionPoint ~= 6;
						end)

					elseif mission.ProgressionPoint == 7 then
						CutsceneSequence:NextScene("freezePlayer");
						task.wait(0.1);
						
						playerClass:SetCFrame(CFrame.new(-99.0285263, 194.909668, -36.03228, -0.173647955, 0, -0.984807789, 0, 1, 0, 0.984807789, 0, -0.173647955));
						
						zarkNpcClass.Move:MoveTo(Vector3.new(-92.1926346, 194.99115, -32.4804077));
						zarkNpcClass.Move.OnMoveToEnded:Wait(5);

						zarkNpcClass:SetCFrame(CFrame.new(-91.4179306, 194.941971, -32.5195656, 0.419815749, 3.3732789e-08, 0.907609344, -8.04018683e-08, 1, 2.33395889e-11, -0.907609344, -7.29832834e-08, 0.419815749));

						jasonNpcClass:SetCFrame(CFrame.new(-109.033821, 194.604858, -39.1135788, -0.225035056, 9.75815206e-10, -0.974350691, -5.01063635e-09, 1, 2.15875473e-09, 0.974350691, 5.36791234e-09, -0.225035056))
						loranNpcClass:SetCFrame(CFrame.new(-109.619606, 194.604858, -26.3946896, 0.110896394, -2.35750406e-08, -0.993831992, 4.2527283e-08, 1, -1.89759621e-08, 0.993831992, -4.01606073e-08, 0.110896394))
						stanNpcClass:SetCFrame(CFrame.new(-96.3242645, 194.604858, -27.8066845, 0.426399022, -7.00883547e-08, -0.904535174, 4.63206042e-08, 1, -5.56498989e-08, 0.904535174, -1.8169553e-08, 0.426399022))
						task.wait(1);

						zarkNpcClass.Move:HeadTrack(playerClass.Head);
						zarkNpcClass.Chat(player, "Heh heh heh, what do we have here?");
						task.wait(3.5);
						
						zarkNpcClass.Chat(player, "I've been told that somebody wants to meet me?");
						zarkNpcClass:ToggleInteractable(true);
						
						CutsceneSequence:NextScene("canInteract");


					elseif mission.ProgressionPoint == 8 then
					
						zarkNpcClass.WieldComp.TargetableTags.Human = true;
						zarkNpcClass.WieldComp:Equip{
							ItemId = "deagle";
							OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
								if toolHandler.EquipmentClass == nil then return end;
								local equipmentClass: EquipmentClass = toolHandler.EquipmentClass;

								local modifier: ConfigModifier = equipmentClass.Configurations.newModifier("npcDmg");
								modifier.SetValues.Damage = 45;
								modifier.Priority = 999;
								equipmentClass.Configurations:AddModifier(modifier, true);
							end;
						};
						stanNpcClass.Properties.Immotal = 0.1;

						task.wait(1);
						modDialogueService:InvokeDialogue(player, "talk", {
							NpcModel = zarkNpcClass.Character;
						});

					elseif mission.ProgressionPoint == 9 then

						zarkNpcClass.Chat(player, "I've answered that question already, I do not know who is Robert!");
						task.wait(6.5);

						zarkNpcClass.Move:HeadTrack(stanNpcClass.RootPart);
						zarkNpcClass.Move:Face(stanNpcClass.RootPart.Position);
						task.wait(1);

						zarkNpcClass.WieldComp:InvokeToolAction(
							"PrimaryFireRequest", 
							(stanNpcClass.RootPart.Position - zarkNpcClass.RootPart.Position).Unit,
							stanNpcClass.Humanoid
						);
						stanNpcClass.Chat(player, "Ouhh..");
						task.wait(0.2);
						
						stanNpcClass.PlayAnimation("Shot");
						stanNpcClass:GetComponent("AvatarFace"):Set("Frustrated");
						
						task.wait(1);
						zarkNpcClass.Move:HeadTrack(playerClass.Head);

						task.wait(2);
						modDialogueService:InvokeDialogue(player, "talk", {
							NpcModel = zarkNpcClass.Character;
						});

					elseif mission.ProgressionPoint == 10 then
						zarkNpcClass.Chat(player, "That is not a question, last chance..");
						task.wait(3);
						
						zarkNpcClass.Move:HeadTrack(stanNpcClass.RootPart);
						zarkNpcClass.Move:Face(stanNpcClass.RootPart.Position);
						task.wait(0.4);
						
						zarkNpcClass.WieldComp:InvokeToolAction(
							"PrimaryFireRequest", 
							(stanNpcClass.RootPart.Position - zarkNpcClass.RootPart.Position).Unit,
							stanNpcClass.Humanoid
						);
						task.wait(0.2);
						
						stanNpcClass.Chat(player, "*hard to breath*");
						
						task.wait(1);
						zarkNpcClass.Move:HeadTrack(playerClass.Head);

						task.wait(2);
						modDialogueService:InvokeDialogue(player, "talk", {
							NpcModel = zarkNpcClass.Character;
						});

					elseif mission.ProgressionPoint == 11 then
						zarkNpcClass.Chat(player, ".. Yes, there was reports of that happening. But oh well.");
						wait(3.5);

						zarkNpcClass.Move:HeadTrack(stanNpcClass.RootPart);
						zarkNpcClass.Move:Face(stanNpcClass.RootPart.Position);
						task.wait(0.4);
						
						zarkNpcClass.WieldComp:InvokeToolAction(
							"PrimaryFireRequest", 
							(stanNpcClass.RootPart.Position - zarkNpcClass.RootPart.Position).Unit,
							stanNpcClass.Humanoid
						);
						task.wait(0.2);

						zarkNpcClass.WieldComp:InvokeToolAction(
							"PrimaryFireRequest", 
							(stanNpcClass.RootPart.Position - zarkNpcClass.RootPart.Position).Unit,
							stanNpcClass.Humanoid
						);
						task.wait(0.2);

						stanNpcClass.Chat(player, "*unresponsive*");
						stanNpcClass:GetComponent("AvatarFace"):Set("Unconscious");
				
						zarkNpcClass.WieldComp:InvokeToolAction(
							"PrimaryFireRequest", 
							(stanNpcClass.RootPart.Position - zarkNpcClass.RootPart.Position).Unit,
							stanNpcClass.Humanoid
						);
						stanNpcClass.HealthComp:TakeDamage(DamageData.new{
							Damage = 100;
							DamageType = "IgnoreArmor";
						});
						task.wait(1);

						zarkNpcClass.Chat(player, "..");
						task.wait(0.6);
						zarkNpcClass.WieldComp:Unequip();

						task.wait(0.3);
						
						zarkNpcClass.Move:HeadTrack(playerClass.Head);
						task.wait(0.4);
						
						task.wait(1);
						modDialogueService:InvokeDialogue(player, "talk", {
							NpcModel = zarkNpcClass.Character;
						});

					elseif mission.ProgressionPoint == 12 then

						zarkNpcClass.Chat(player, "Is that so...");
						zarkNpcClass:ToggleInteractable(false);
						task.wait(5);
						
						zarkNpcClass.Move:HeadTrack(jasonNpcClass.Head);
						zarkNpcClass.Chat(player, "JASON, Team delta has been taken out by the infector, find some replacements now!");
						task.wait(7.5);
						
						jasonNpcClass.Chat(player, "Sure thing boss.");
						spawn(function() 
							jasonNpcClass.Move:MoveTo(Vector3.new(-124.898, 194.146, -40.23));
							jasonNpcClass.Move.OnMoveToEnded:Wait(5);
							jasonNpcClass:SetCFrame(CFrame.new(0.301, 194.146, -40.23));
						end)
						task.wait(3);
						
						zarkNpcClass.Move:HeadTrack(loranNpcClass.Head);
						task.wait(0.3);
						
						zarkNpcClass.Chat(player, "Loran, knock'em out and take this other one somewhere..");
						task.wait(3.5);
						
						loranNpcClass.Move:MoveTo(Vector3.new(-99.4085159, 194.909668, -36.03228));
						loranNpcClass.Move.OnMoveToEnded:Wait(5);
						loranNpcClass.PlayAnimation("WeaponHit");
						modAudio.Play("Punch", playerClass.Head);
						
						CutsceneSequence:NextScene("knockout");
						task.wait(0.1);
						
						modStatusEffects.Dizzy(player, 5);
						task.wait(1);
						
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 12 then
								mission.ProgressionPoint = 13;
							end;
						end)
						task.wait(2);
						
						local gameLib = modGameModeLibrary.GetGameMode("Raid");
						local stageLib = gameLib and modGameModeLibrary.GetStage("Raid", "BanditOutpost");

						local system = modRaid.new();
						local room = modMatchMaking.Room.new();

						system:Init({
							Type = "Raid";
							Stage = "BanditOutpost";
							StageLib = stageLib;
						});
						room.Mission=true;
						room:AddPlayer(player);
						system:Start(room);
					end

				elseif mission.Type == 3 then -- OnComplete
					mission.OnChanged:Disconnect(OnChanged);
				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)

		CutsceneSequence:NewScene("enableInterfaces", function()
			modConfigurations.Set("DisablePinnedMission", false);
			modConfigurations.Set("DisableDialogue", false);
			modConfigurations.Set("DisableInventory", false);
			modConfigurations.Set("DisableHealthbar", false);
		end);

		CutsceneSequence:NewScene("freezePlayer", function()
			local modCharacter = modData:GetModCharacter();

			modCharacter.CharacterProperties.CanMove = false;
			modCharacter.CharacterProperties.CanInteract = false;

			local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
			local humanoid = playerClass.Humanoid;
			local surrenderAnimation = humanoid:LoadAnimation(script:WaitForChild("Surrender"));
			if surrenderAnimation then surrenderAnimation:Play(); end;

		end);

		CutsceneSequence:NewScene("walkToZark", function()
			local modCharacter = modData:GetModCharacter();

			modCharacter.CharacterProperties.CanMove = true;
		end);

		CutsceneSequence:NewScene("canInteract", function()
			local modCharacter = modData:GetModCharacter();

			modCharacter.CharacterProperties.CanInteract = true;
			modCharacter.CharacterProperties.FirstPersonCamCFrame = CFrame.new(-98.6663208, 197.423386, -36.0137405, -0.438371867, 0, -0.898793757, 0, 1, 0, 0.898793757, 0, -0.438371867);
		end);

		local playerAnimTracks = {};
		CutsceneSequence:NewScene("knockout", function()
			local modCharacter = modData:GetModCharacter();

			local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
			local head = playerClass.Head;

			modData.ToggleChat();
			if head:FindFirstChild("face") ~= nil then
				head.face.Parent = script;
			end

			local unconsciousFace = script:WaitForChild("unconsciousFace"):Clone();
			unconsciousFace.Parent = head;
			unconsciousFace.Texture = "rbxassetid://2255073000";

			modCharacter.CharacterProperties.CanInteract = false;
			modClientGuis.toggleGameBlinds(false, 1);

			local humanoid = playerClass.Humanoid;
			playerAnimTracks.Unconscious = humanoid:LoadAnimation(script:WaitForChild("Unconscious"));
			playerAnimTracks.Unconscious:Play();
		end);
		
		
	--MARK: BanditOutpost
	elseif modBranchConfigs.IsWorld("BanditOutpost") then
		if RunService:IsServer() then
			modGamemodeStronghold = shared.require(game.ServerScriptService.ServerLibrary.GameModeStronghold);
		end

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
			
			local patrickNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Patrick");
			if modMission:IsComplete(player, MISSION_ID) then return end;
			
			local hostageSpawn = workspace.Environment:WaitForChild("Game"):WaitForChild("HostageSpawn");

			local activeController = modGamemodeStronghold.Active;
			Debugger:StudioLog(`init activeController`, activeController);

			local playerClass: PlayerClass = shared.modPlayers.get(player);
			playerClass.OnCharacterSpawn:Connect(function()
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint >= 13 then
						mission.ProgressionPoint = 13;
					end
				end)
			end)

			playerClass.OnIsDeadChanged:Connect(function()
				if not playerClass.HealthComp.IsDead then return end;

				Debugger:Warn(`{player.Name} died in mission.`);
				modMission:FailMission(player, MISSION_ID, "You died.");
				modServerManager:Travel(player, "TheMall");
			end)

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					Debugger:Log("Mission progression point, ",mission.ProgressionPoint);

					if firstRun and mission.ProgressionPoint >= 13 then
						if patrickNpcClass == nil then
							patrickNpcClass = modNpcs.spawn2{
								Name = "Patrick";
								CFrame = CFrame.new(31.509, 40.911, 12.906) * CFrame.Angles(0, math.rad(92.957), 0);
								Player = player;
							};
						end
						patrickNpcClass.WieldComp:Equip{
							ItemId = "ak47";
							OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
								if toolHandler.EquipmentClass == nil then return end;
								local equipmentClass: EquipmentClass = toolHandler.EquipmentClass;

								local modifier: ConfigModifier = equipmentClass.Configurations.newModifier("npcDmg");
								modifier.SetValues.Damage = 40;
								modifier.SetValues.ReloadTime = 1;
								modifier.Priority = 999;
								equipmentClass.Configurations:AddModifier(modifier, true);
							end;
						};
						patrickNpcClass.WieldComp.TargetableTags.Bandit = true;
						-- patrickNpcClass.Wield.SetSkin({
						-- 	Textures={
						-- 		["Grip"]=102;
						-- 		["Stock"]=102;
						-- 	};
						-- });

						local mask = script:WaitForChild("ContrastMask"):Clone();
						mask.Parent = patrickNpcClass.Character;
						(patrickNpcClass.Character:WaitForChild("Shirt") :: Shirt).ShirtTemplate = "http://www.roblox.com/asset/?id=3243872086";
					end

					if mission.ProgressionPoint == 13 then
						CutsceneSequence:NextScene("closeBlinds");
						CutsceneSequence:Pause(20);

						playerClass:SetCFrame(hostageSpawn.CFrame);
						task.wait(0.5);

						CutsceneSequence:NextScene("openBlinds");
						task.wait(1);

						patrickNpcClass.Chat(player, "Wake up, we got to go.");

						patrickNpcClass.Move:HeadTrack(playerClass.Head, 5);

					elseif mission.ProgressionPoint == 14 then

						local rewardSpawnPart = workspace.Environment.Game:FindFirstChild("RewardSpawn");
						game.Debris:AddItem(rewardSpawnPart, 0);

						patrickNpcClass:ToggleInteractable(false);
						patrickNpcClass.WieldComp.TargetableTags.Bandit = true;
						patrickNpcClass.Properties.Immortal = 0.5;

						local followPlayerComp = patrickNpcClass:GetComponent("FollowPlayer");
						followPlayerComp.FollowInFront = true;
						followPlayerComp();
						local protectPlayerComp = patrickNpcClass:GetComponent("ProtectPlayer");
						protectPlayerComp();

					end

				elseif mission.Type == 3 then -- OnComplete
					mission.OnChanged:Disconnect(OnChanged);

					task.wait(3);
					patrickNpcClass.Move:HeadTrack(playerClass.Head, 5);
					patrickNpcClass.Chat(player, "Good job, I think you can manage from here.");

					task.delay(6, function()
						patrickNpcClass.Character:Destroy();
					end)

				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)

		CutsceneSequence:NewScene("closeBlinds", function()
			modClientGuis.toggleGameBlinds(false, 0);
		end);

		CutsceneSequence:NewScene("openBlinds", function()
			modClientGuis.toggleGameBlinds(true, 5);
		end);
		
	end
	
	return CutsceneSequence;
end;