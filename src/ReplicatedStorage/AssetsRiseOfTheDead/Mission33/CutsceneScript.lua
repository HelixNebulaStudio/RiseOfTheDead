local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modGameModeLibrary = require(game.ReplicatedStorage.Library.GameModeLibrary);
local modNpcProfileLibrary = require(game.ReplicatedStorage.Library.NpcProfileLibrary);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

--== Variables;
local missionId = 33;

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);

	modMatchMaking = require(game.ServerScriptService.ServerLibrary.MatchMaking);
	modRaid = require(game.ServerScriptService.ServerLibrary.GameModeManager.Raid);
	
else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule"));
	
end

--== Script;
return function(CutsceneSequence)
	if modBranchConfigs.IsWorld("TheMall") then
		local stanNpcProfile = modNpcProfileLibrary:Find("Stan");
		stanNpcProfile.World="TheMall";

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then return end;

			local patrickPrefab = workspace.Entity:FindFirstChild("Patrick");
			local patrickModule = patrickPrefab and modNpc.GetNpcModule(patrickPrefab);

			local stanModule = modNpc.GetPlayerNpc(player, "Stan");
			if stanModule == nil and mission.ProgressionPoint <= 13 then
				local npc = modNpc.Spawn("Stan", CFrame.new(755.090332, 94.8246002, -653.329224, -1, 0, 0, 0, 1, 0, 0, 0, -1), function(npc, npcModule)
					npcModule.Owner = player;
					stanModule = npcModule;
				end);
				modReplicationManager.ReplicateOut(player, npc);
			end

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					stanModule.Movement:EndMovement();
					stanModule.Actions:Teleport(CFrame.new(755.090332, 94.8246002, -653.329224, -1, 0, 0, 0, 1, 0, 0, 0, -1));

				elseif mission.Type == 4 and firstRun then
					stanModule.Actions:Teleport(CFrame.new(755.090332, 94.8246002, -653.329224, -1, 0, 0, 0, 1, 0, 0, 0, -1));

					modMission:Progress(player, missionId, function(mission)
						mission.ProgressionPoint = 3;
					end)

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						
						if mission.Redo then
							Debugger:Warn("Redo");
							if stanModule == nil then
								local npc = modNpc.Spawn("Stan", CFrame.new(755.090332, 94.8246002, -653.329224, -1, 0, 0, 0, 1, 0, 0, 0, -1), function(npc, npcModule)
									npcModule.Owner = player;
									stanModule = npcModule;
								end);
								modReplicationManager.ReplicateOut(player, npc);
							end
						end
						
						stanModule.Actions:Teleport(CFrame.new(755.090332, 94.8246002, -653.329224, -1, 0, 0, 0, 1, 0, 0, 0, -1));
						stanModule:ToggleInteractable(false);

						stanModule.Movement:SetWalkSpeed("default", 25);

						local waypoint = Vector3.new(735.36, 94.775, -695.904);
						stanModule.Movement:Move(waypoint):Wait(5);
						stanModule.Chat(stanModule.Owner, "When you're ready.");
						wait(0.1);
						stanModule.Actions:FaceOwner()
						stanModule.Actions:WaitForOwner(20);
						stanModule.Actions:EnterDoor("safehouse5MainDoor");

						waypoint = Vector3.new(793.870911, 162.633194, -727.308044);
						stanModule.Movement:Move(waypoint):Wait(60);

						if stanModule.Actions:DistanceFrom(waypoint) > 20 then
							stanModule.Actions:Teleport(CFrame.new(waypoint));
						end

						wait(1);
						stanModule.Chat(stanModule.Owner, "Patrick, is there a way in yet?");
						stanModule:ToggleInteractable(true);
						stanModule.Movement:Face(Vector3.new(796.521973, 162.679657, -730.796265));
						wait(1);

						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint <= 1 then
								mission.ProgressionPoint = 2;
							end;
						end)

					elseif mission.ProgressionPoint == 2 then
						stanModule:ToggleInteractable(false);
						stanModule.Actions:Teleport(CFrame.new(Vector3.new(793.870911, 162.633194, -727.308044)));
						stanModule.Actions:WaitForOwner(20);
						stanModule.Movement:Face(Vector3.new(796.521973, 162.679657, -730.796265));


					elseif mission.ProgressionPoint == 3 then
						stanModule:ToggleInteractable(false);
						stanModule.Chat(stanModule.Owner, "Alright, let's go..");
						stanModule.Actions:FollowOwner(function()
							return mission.Type == 1 and mission.ProgressionPoint == 3
						end);

					end
				elseif mission.Type == 3 then -- OnComplete

				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true, mission);
		end)
		
		
	elseif modBranchConfigs.IsWorld("AwokenTheBear") then
		CutsceneSequence:Initialize(function()
			local players: {Player} = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then return end;

			local classPlayer = shared.modPlayers.Get(player);

			classPlayer.OnIsAliveChanged:Connect(function(isAlive)
				if not isAlive then
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint <= 13 then
							mission.ProgressionPoint = 4;
						end;
					end)
				end
			end)

			if modMission:IsComplete(player, missionId) then return end;
			
			local stanModule = modNpc.GetPlayerNpc(player, "Stan");
			if stanModule == nil then
				local npc = modNpc.Spawn("Stan", CFrame.new(-0.0199999996, 163.47496, -38.7299995, 1, 0, 0, 0, 1, 0, 0, 0, 1), 
					function(npc, npcModule)
						npcModule.Owner = player;
						stanModule = npcModule;
					end);
				modReplicationManager.ReplicateOut(player, npc);
			end
			
			local zarkModule = modNpc.GetPlayerNpc(player, "Zark");
			if zarkModule == nil then
				local npc = modNpc.Spawn("Zark", CFrame.new(-66.0924149, 194.864609, -32.347641, -0.0348989964, 0, 0.9993909, 0, 1, 0, -0.9993909, 0, -0.0348989964), 
					function(npc, npcModule)
						npcModule.Owner = player;
						zarkModule = npcModule;
					end);
				modReplicationManager.ReplicateOut(player, npc);
			end

			local jasonModule = modNpc.GetPlayerNpc(player, "Jason");
			if jasonModule == nil then
				local npc = modNpc.Spawn("Jason", CFrame.new(-113.02739, 194.864609, -44.0382957, -0.422619998, 0, 0.906306982, 0, 1, 0, -0.906306982, 0, -0.422619998), 
					function(npc, npcModule)
						npcModule.Owner = player;
						jasonModule = npcModule;
					end);
				jasonModule.Wield.Equip("ak47");
				jasonModule:ToggleInteractable(false);
				modReplicationManager.ReplicateOut(player, npc);
			end

			local loranModule = modNpc.GetPlayerNpc(player, "Loran");
			if loranModule == nil then
				local npc = modNpc.Spawn("Loran", CFrame.new(-115.057365, 194.864609, -31.1187763, 0.694657087, 0, 0.71934104, 0, 1, 0, -0.71934104, 0, 0.694657087), function(npc, npcModule)
					npcModule.Owner = player;
					loranModule = npcModule;
				end);
				loranModule.Wield.Equip("ak47");
				loranModule:ToggleInteractable(false);
				modReplicationManager.ReplicateOut(player, npc);
			end

			local function OnChanged(firstRun)
				if mission.Type == 1 then -- OnActive
					Debugger:Warn("Mission progression point, ",mission.ProgressionPoint);
					
					if mission.ProgressionPoint == 4 then
						CutsceneSequence:NextScene("enableInterfaces");
						stanModule.StopAnimation("Surrender");
						stanModule.StopAnimation("Shot");
						stanModule:ToggleInteractable(false);

						zarkModule:ToggleInteractable(false);
						zarkModule.Actions:Teleport(CFrame.new(-66.0924149, 194.864609, -32.347641, -0.0348989964, 0, 0.9993909, 0, 1, 0, -0.9993909, 0, -0.0348989964));
						
						local exitPosition = Vector3.new(-101.99, 180.193, -70.54);
						stanModule.Actions:FollowOwner(function()
							if (stanModule.RootPart.Position-exitPosition).Magnitude <= 20 then
								modMission:Progress(player, missionId, function(mission)
									if mission.ProgressionPoint < 5 then mission.ProgressionPoint = 5; end;
								end)
							end
							return mission.Type == 1 and mission.ProgressionPoint == 4
						end);

					elseif mission.ProgressionPoint == 5 then
						wait(1);
						jasonModule.Movement:SetWalkSpeed("default", 18);
						local waypoint = Vector3.new(-143.957703, 194.634598, -65.9168854);
						stanModule.Movement:Move(waypoint):Wait(5);
						stanModule.Movement:Face(Vector3.new(-132.616409, 194.718018, -64.660614));
						wait(2);
						if mission.ProgressionPoint ~= 5 then return end;

						stanModule.Chat(player, "It's too quiet, something's not right..");
						wait(3);
						if mission.ProgressionPoint ~= 5 then return end;

						waypoint = Vector3.new(-132.53479, 194.634567, -40.8270035);
						stanModule.Movement:Move(waypoint):Wait(5);
						wait(1);
						if mission.ProgressionPoint ~= 5 then return end;

						stanModule.Actions:EnterDoor("throneRoomDoor");
						wait(1/60);
						if mission.ProgressionPoint ~= 5 then return end;
						stanModule.Actions:Teleport(CFrame.new(-119.893661, 194.634567, -33.8498764, 0, 0, -1, 0, 1, 0, 1, 0, 0));

					elseif mission.ProgressionPoint == 6 then
						stanModule.Actions:Teleport(CFrame.new(-119.893661, 194.634567, -33.8498764, 0, 0, -1, 0, 1, 0, 1, 0, 0));
						stanModule.PlayAnimation("Surrender");
						loranModule.Chat(player, "STAY RIGHT THERE!");
						stanModule.Chat(player, "Oh god.");
						CutsceneSequence:NextScene("freezePlayer");
						loranModule.Movement:Face(stanModule.RootPart.Position);
						jasonModule.Actions:FaceOwner()
						wait(1);
						zarkModule.Movement:Move(Vector3.new(-79.5326004, 194.909668, -33.090416)):Wait(5);
						wait(1);
						stanModule.Chat(player);

						CutsceneSequence:NextScene("walkToZark");
						jasonModule.Chat(player, "WALK!");
						loranModule.Chat(player);

						wait(0.2);
						stanModule.Movement:SetWalkSpeed("default", 10);
						stanModule.Movement:Move(Vector3.new(-95.599, 194.91, -27.702));
						wait(0.2);

						loranModule.Movement:SetWalkSpeed("default", 10);
						jasonModule.Movement:SetWalkSpeed("default", 10);
						loranModule.Movement:Move(Vector3.new(-109.017929, 194.909668, -25.8456249))
						jasonModule.Movement:Move(Vector3.new(-108.607742, 194.909668, -38.5568581)):Wait(5);

						spawn(function()
							repeat
								loranModule.Movement:Face(stanModule.RootPart.Position);
								wait(0.2);
							until mission.ProgressionPoint ~= 6;
						end)

						spawn(function()
							repeat
								jasonModule.Actions:FaceOwner()
								wait(0.2);
							until mission.ProgressionPoint ~= 6;
						end)
						modStatusEffects.Slowness(player, 10, 60);

						spawn(function()
							local position = Vector3.new(-99.4085159, 194.909668, -36.03228);
							local initMag = (classPlayer.RootPart.Position-position).Magnitude;
							local shoutCD = tick()-5;
							local count = 0;
							repeat
								local dist = (classPlayer.RootPart.Position-position).Magnitude;
								if dist <= 2 then
									modMission:Progress(player, missionId, function(mission)
										if mission.ProgressionPoint < 7 then mission.ProgressionPoint = 7; end;
									end)
								elseif dist >= (initMag + 5) then
									if tick()- shoutCD >= 5 then
										jasonModule.Wield.LoadRequest();
										shoutCD = tick();
										count = count +1;
										if count == 1 then
											jasonModule.Chat(player, "WALK TOWARDS ZARK OR ELSE");

										elseif count == 2 then
											jasonModule.Chat(player, "I SAID WALK!");

										elseif count == 3 then
											jasonModule.Chat(player, "LAST WARNING!!");

										elseif count > 3 then
											jasonModule.Wield.Targetable.Humanoid = 0.5;
											jasonModule.Wield.SetEnemyHumanoid(classPlayer.Humanoid);
											jasonModule.Movement:Face(classPlayer.RootPart.Position);
											jasonModule.Wield.PrimaryFireRequest();
										end
									end
								end 
								wait(0.2);
								initMag = initMag -0.2;
							until mission.ProgressionPoint ~= 6;
						end)

					elseif mission.ProgressionPoint == 7 then
						CutsceneSequence:NextScene("freezePlayer");
						wait(0.1);
						classPlayer.RootPart.CFrame = CFrame.new(-99.0285263, 194.909668, -36.03228, -0.173647955, 0, -0.984807789, 0, 1, 0, 0.984807789, 0, -0.173647955);
						zarkModule.Movement:Move(Vector3.new(-92.1926346, 194.99115, -32.4804077)):Wait(5);
						zarkModule.Actions:Teleport(CFrame.new(-91.4179306, 194.941971, -32.5195656, 0.419815749, 3.3732789e-08, 0.907609344, -8.04018683e-08, 1, 2.33395889e-11, -0.907609344, -7.29832834e-08, 0.419815749))

						jasonModule.Actions:Teleport(CFrame.new(-109.033821, 194.604858, -39.1135788, -0.225035056, 9.75815206e-10, -0.974350691, -5.01063635e-09, 1, 2.15875473e-09, 0.974350691, 5.36791234e-09, -0.225035056))
						loranModule.Actions:Teleport(CFrame.new(-109.619606, 194.604858, -26.3946896, 0.110896394, -2.35750406e-08, -0.993831992, 4.2527283e-08, 1, -1.89759621e-08, 0.993831992, -4.01606073e-08, 0.110896394))
						stanModule.Actions:Teleport(CFrame.new(-96.3242645, 194.604858, -27.8066845, 0.426399022, -7.00883547e-08, -0.904535174, 4.63206042e-08, 1, -5.56498989e-08, 0.904535174, -1.8169553e-08, 0.426399022))
						wait(1);
						zarkModule.Actions:FaceOwner();
						zarkModule.Move:HeadTrack(classPlayer.Head);
						zarkModule.Chat(player, "Heh heh heh, what do we have here?");
						jasonModule.Chat(player);
						wait(3);
						
						zarkModule.Chat(player, "I've been told that somebody wants to meet me?");
						zarkModule:ToggleInteractable(true);
						
						CutsceneSequence:NextScene("canInteract");


					elseif mission.ProgressionPoint == 8 then
						zarkModule.Chat(player);
						zarkModule.Wield.Equip("deagle");
						zarkModule.Wield.Targetable.Human = 1;
						stanModule.Immortal = 0.1;

					elseif mission.ProgressionPoint == 9 then
						wait(1.4)
						pcall(function()
							zarkModule.Wield.ToolModule.Configurations.MinBaseDamage = 35;
						end);

						zarkModule.Move:HeadTrack(stanModule.RootPart);
						zarkModule.Movement:Face(stanModule.RootPart.Position);
						task.wait(0.4);
						zarkModule.Wield.SetEnemyHumanoid(stanModule.Humanoid);
						zarkModule.Wield.PrimaryFireRequest();
						
						stanModule.PlayAnimation("Shot");
						stanModule.AvatarFace:Set("Frustrated", game.Players:GetPlayers());
						task.wait(0.2);
						stanModule.Chat(player, "Ouhh..");
						
						wait(1);
						zarkModule.Actions:FaceOwner();
						zarkModule.Move:HeadTrack(classPlayer.Head);

					elseif mission.ProgressionPoint == 10 then
						task.wait(1.4);
						
						stanModule.Chat(player);
						zarkModule.Move:HeadTrack(stanModule.RootPart);
						zarkModule.Movement:Face(stanModule.RootPart.Position);
						task.wait(0.4);
						
						zarkModule.Wield.SetEnemyHumanoid(stanModule.Humanoid);
						zarkModule.Wield.PrimaryFireRequest();
						task.wait(0.2);
						
						stanModule.Chat(player, "*hard to breath*");
						
						wait(1);
						zarkModule.Actions:FaceOwner();
						zarkModule.Move:HeadTrack(classPlayer.Head);

					elseif mission.ProgressionPoint == 11 then
						wait(1.4);
						stanModule.Chat(player);
						zarkModule.Movement:Face(stanModule.RootPart.Position);
						zarkModule.Move:HeadTrack(stanModule.RootPart);
						task.wait(0.4);
						
						zarkModule.Wield.SetEnemyHumanoid(stanModule.Humanoid);
						zarkModule.Wield.PrimaryFireRequest();
						task.wait(0.2);
						zarkModule.Wield.PrimaryFireRequest();
						task.wait(0.2);
						stanModule.Chat(player, "*unresponsive*");
						stanModule.AvatarFace:DialogSet("Unconscious", players);
						
						zarkModule.Wield.PrimaryFireRequest();
						task.wait(1);

						zarkModule.Chat(player, "Hm..");
						task.wait(0.6);
						zarkModule.Wield.Unequip();

						task.wait(0.3);
						
						zarkModule.Actions:FaceOwner();
						zarkModule.Move:HeadTrack(classPlayer.Head);
						task.wait(0.4);
						
						Debugger:Log("11 done");

					elseif mission.ProgressionPoint == 12 then
						zarkModule:ToggleInteractable(false);
						task.wait(2);
						
						zarkModule.Movement:Face(jasonModule.RootPart.Position);
						zarkModule.Move:HeadTrack(jasonModule.Head);
						zarkModule.Chat(player, "JASON, Team delta has been taken out by the infector, find some replacements now!");
						task.wait(3);
						
						jasonModule.Chat(player, "Sure thing boss.");
						spawn(function() 
							jasonModule.Movement:Move(Vector3.new(-124.898, 194.146, -40.23)):Wait(5);
							jasonModule.Actions:Teleport(CFrame.new(0.301, 194.146, -40.23));
						end)
						task.wait(3);
						
						zarkModule.Movement:Face(loranModule.RootPart.Position);
						zarkModule.Move:HeadTrack(loranModule.Head);
						task.wait(0.3);
						
						zarkModule.Chat(player, "Loran, knock'em out and take this other one somewhere..");
						task.wait(1.5);
						
						loranModule.Movement:Move(Vector3.new(-99.4085159, 194.909668, -36.03228)):Wait(5);
						loranModule.PlayAnimation("WeaponHit");
						task.wait(0.3);
						
						CutsceneSequence:NextScene("knockout");
						task.wait(0.1);
						
						modStatusEffects.Dizzy(player, 5);
						task.wait(1)
						
						modMission:Progress(player, missionId, function(mission)
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
							Type="Raid";
							Stage="BanditOutpost";
							StageLib=stageLib;
						});
						room.Mission=true;
						room:AddPlayer(player);
						system:Start(room);

					end
				elseif mission.Type == 3 then -- OnComplete

					mission.Changed:Disconnect(OnChanged);
				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true, mission);
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

			local humanoid = modCharacter.Character.Humanoid;
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
			local modInterface = modData:GetInterfaceModule();
			local modCharacter = modData:GetModCharacter();

			local head = modCharacter.Character.Head;
			modData.ToggleChat();
			if head:FindFirstChild("face") ~= nil then
				head.face.Parent = script;
			end

			local unconsciousFace = script:WaitForChild("unconsciousFace"):Clone();
			unconsciousFace.Parent = head;
			unconsciousFace.Texture = "rbxassetid://2255073000";

			modCharacter.CharacterProperties.CanInteract = false;
			modInterface:ToggleGameBlinds(false, 1);

			local humanoid = modCharacter.Character.Humanoid;
			playerAnimTracks.Unconscious = humanoid:LoadAnimation(script:WaitForChild("Unconscious"));
			playerAnimTracks.Unconscious:Play();
		end);
		
		
	elseif modBranchConfigs.IsWorld("BanditOutpost") then
		local hostageSpawn = workspace.Environment:WaitForChild("StageElements"):WaitForChild("HostageSpawn");
		
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then return end;
			
			local patrickModule = modNpc.GetPlayerNpc(player, "Patrick");

			if modMission:IsComplete(player, missionId) then return end;
			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					Debugger:Log("Mission progression point, ",mission.ProgressionPoint);

					if firstRun and mission.ProgressionPoint >= 13 then
						if patrickModule == nil then
							local npc = modNpc.Spawn("Patrick", CFrame.new(25.4873447, 41.7153206, 12.5784693, 0.017451996, 0, 0.99984777, 0, 1, 0, -0.99984777, 0, 0.017451996), function(npc, npcModule)
								npcModule.Owner = player;
								patrickModule = npcModule;
							end, require(game.ServerStorage.PrefabStorage.CustomNpcModules.CutsceneHuman));
							patrickModule.RootPart.Anchored = false;
						end
						patrickModule.Wield.Equip("ak47");
						patrickModule.Wield.Targetable.Bandit = 1;

						local mask = script:WaitForChild("ContrastMask"):Clone();
						mask.Parent = patrickModule.Prefab;
						patrickModule.Prefab:WaitForChild("Shirt").ShirtTemplate = "http://www.roblox.com/asset/?id=3243872086";

						pcall(function()
							patrickModule.Wield.ToolModule.Configurations.AmmoLimit = 40;
							patrickModule.Wield.ToolModule.Properties.ReloadSpeed = 1;

							patrickModule.Wield.ToolModule.Configurations.MinBaseDamage = 40;

							patrickModule.Wield.SetSkin({
								Textures={
									["Grip"]=102;
									["Stock"]=102;
								};
							});
						end);
					end

					if mission.ProgressionPoint == 13 then
						shared.modAntiCheatService:Teleport(player, hostageSpawn.CFrame);
						CutsceneSequence:NextScene("teleportToHostage");
						wait(1);
						patrickModule.Actions:FaceOwner();
						patrickModule.Chat(player, "C'mon, we got to go.");

					elseif mission.ProgressionPoint == 14 then
						if patrickModule.Interactable then
							patrickModule:ToggleInteractable(false);
						end
						patrickModule.Wield.Targetable.Bandit = 1;

						task.spawn(function()
							while true do
								for _, child in pairs(workspace.Interactables:GetChildren()) do
									local interactDoor = child:FindFirstChild("Interactable") and require(child.Interactable) or nil;
									if interactDoor and interactDoor.Type == 1 and child.Name == ("Door5") then
										interactDoor.Script = child.Interactable;
										interactDoor.Locked = false;
										interactDoor:Sync();
									end
								end
								task.wait(5);
							end
						end)

						patrickModule.Actions:FollowOwner(function()
							if patrickModule.Owner and patrickModule.Owner.Character and patrickModule.Owner.Character:FindFirstChild("Humanoid") then

								local entities = workspace.Entity:GetChildren();
								for a=1, #entities do
									if entities[a]:FindFirstChild("NpcStatus") and entities[a] ~= patrickModule.Prefab then
										local npcModule = require(entities[a].NpcStatus).NpcModule;
										if npcModule then
											if npcModule.Humanoid and npcModule.Humanoid.Health > 0 then
												if npcModule.Wield 
													and npcModule.Wield.EnemyHumanoid == patrickModule.Owner.Character.Humanoid then
													if npcModule.RootPart and patrickModule.IsInVision(npcModule.RootPart) then
														patrickModule.Wield.SetEnemyHumanoid(npcModule.Humanoid);
														patrickModule.Move:Face(npcModule.RootPart);
														patrickModule.Wield.PrimaryFireRequest();
														break;
													end
												end
											end
										end
									end
								end
							end
							return mission.Type == 1 and mission.ProgressionPoint == 14;
						end);

					end
				elseif mission.Type == 3 then -- OnComplete

					mission.Changed:Disconnect(OnChanged);
				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true, mission);
		end)

		CutsceneSequence:NewScene("teleportToHostage", function()
			local modInterface = modData:GetInterfaceModule();
			local modCharacter = modData:GetModCharacter();
			local rootPart = modCharacter.Character.HumanoidRootPart;
			
			modInterface:ToggleGameBlinds(false, 0);
			rootPart.CFrame = hostageSpawn.CFrame;
			modInterface:ToggleGameBlinds(true, 5);

		end);
		
	end
	
	return CutsceneSequence;
end;