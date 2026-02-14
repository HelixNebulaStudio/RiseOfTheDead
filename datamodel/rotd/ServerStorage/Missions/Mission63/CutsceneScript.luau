local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

--== Variables;
local MISSION_ID = 63;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	cutsceneAssets = script.Parent:WaitForChild("CutsceneAssets");

else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	-- MARK: TheMall / BioXResearch
	if modBranchConfigurations.IsWorld("TheMall") or modBranchConfigurations.IsWorld("BioXResearch") then
		
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;

			local playerClass: PlayerClass = shared.modPlayers.get(player);

			local gateBanditNpcClass: NpcClass;
			local function spawnBandit()
				gateBanditNpcClass = modNpcs.spawn2{
					Name = "Bandit";
					CFrame = CFrame.new(798.55481, 162.668854, -728.297119, 0, 0, 1, 0, 1, 0, -1, 0, 0);
					Player = player;
					ReplicateOut = true;
					BindSetup = function(npcClass: NpcClass)
						npcClass.Properties.Immortal = 0.5;
						npcClass.Properties.CutsceneActive = true;
					end
				};
				if modBranchConfigurations.IsWorld("BioXResearch") then
					gateBanditNpcClass:SetCFrame(playerClass:GetCFrame());
				end
				
				local dialogueInteractConfig = modInteractables.createInteractable("Dialogue");
				dialogueInteractConfig:SetAttribute("NpcName", gateBanditNpcClass.Name);
				dialogueInteractConfig.Parent = gateBanditNpcClass.Character;
				gateBanditNpcClass.Interactable = dialogueInteractConfig;

				gateBanditNpcClass.Move:SetMoveSpeed("set", "default", 8);
				
				task.delay(1, function()
					gateBanditNpcClass.WieldComp:Equip{
						ItemId = "ak47";
					};
				end)
			end
			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						if gateBanditNpcClass == nil then
							spawnBandit();
						end
						
					elseif mission.ProgressionPoint == 2 then
						if gateBanditNpcClass == nil then
							spawnBandit();
						end

					elseif mission.ProgressionPoint == 3 then
						if gateBanditNpcClass then
							task.wait(5);
							gateBanditNpcClass.Character:Destroy();
							gateBanditNpcClass:Destroy();
						end
					end
				elseif mission.Type == 3 then -- OnComplete


				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)


	-- MARK: BanditsRecruitment
	elseif modBranchConfigurations.IsWorld("BanditsRecruitment") then

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			game.Players:SetAttribute("AutoRespawn", true);
			workspace:FindFirstChild("Tom Greyman"):Destroy();
			
			local StrangerNpcs = {
				NameA={Index=1; SpawnCFrame=CFrame.new(-2203.62329, 110.573784, 2191.88818, 0.707106829, 0, 0.70710665, 0, 1, 0, -0.70710665, 0, 0.707106829); NpcClass=nil;};
				NameB={Index=2; SpawnCFrame=CFrame.new(-2200.81152, 110.573784, 2194.69971, 0.707106888, 0, 0.707106709, 0, 1, 0, -0.707106709, 0, 0.707106888); NpcClass=nil;};
				NameC={Index=3; SpawnCFrame=CFrame.new(-2197.92627, 110.573784, 2197.58545, 0.707106829, 0, 0.70710665, 0, 1, 0, -0.70710665, 0, 0.707106829); NpcClass=nil;};
			};
			
			for name, info in pairs(StrangerNpcs) do
				local strangerNpcClass: NpcClass = modNpcs.spawn2{
					Name = "Stranger";
					CFrame = info.SpawnCFrame;
					Player = player;
					BindSetup = function(npcClass: NpcClass)
						local properties = npcClass.Properties;
						properties.Seed = player.UserId + info.Index;
					
						if name == "NameB" then
							properties.Seed = 16170945;
						end

						npcClass.Character:SetAttribute("LookAtClient", false);
					end;
				};
				info.NpcClass = strangerNpcClass;

				if math.fmod(strangerNpcClass.Properties.Seed, 2) == 0 then
					strangerNpcClass:GetComponent("AvatarFace"):Set("Serious", game.Players:GetPlayers());
				else
					strangerNpcClass:GetComponent("AvatarFace"):Set("Skeptical", game.Players:GetPlayers());
				end
			end
			
			
			local BanditNpcs = {
				Name1={Index=1; SpawnCFrame=CFrame.new(-2191.70508, 110.573776, 2215.65112, 1, 0, 0, 0, 1, 0, 0, 0, 1); NpcClass=nil;};
				Name2={Index=2; SpawnCFrame=CFrame.new(-2223.28345, 110.573784, 2200.97583, 0.37460658, 0, -0.927183867, 0, 1, 0, 0.927183867, 0, 0.37460658); NpcClass=nil;};
				Name3={Index=3; SpawnCFrame=CFrame.new(-2219.10742, 110.573784, 2172.87793, -0.766045332, 0, -0.642788351, 0, 1, 0, 0.642788351, 0, -0.766045332); NpcClass=nil;};
				Name4={Index=4; SpawnCFrame=CFrame.new(-2179.39062, 110.573784, 2192.7644, 0, 0, 1.00000238, 0, 1, 0, -1.00000238, 0, 0); NpcClass=nil;};

				Name5={Index=5; SpawnCFrame=CFrame.new(-16.7903328, 3.50084543, 84.3079224, -0.207911521, 0, -0.978147745, 0, 1, 0, 0.978147626, 0, -0.207911551); NpcClass=nil;};
				Name6={Index=6; SpawnCFrame=CFrame.new(-9.2598114, 2.73089767, 63.6921425, -0.766044796, 0, -0.642788708, 0, 1, 0, 0.642787635, 0, -0.766045332); NpcClass=nil;};
				Name7={Index=7; SpawnCFrame=CFrame.new(46.8010941, 2.70089865, 59.8955536, -0.629318595, 0, 0.777143538, 0, 1, 0, -0.777143717, 0, -0.629318416); NpcClass=nil;};
				Name8={Index=8; SpawnCFrame=CFrame.new(46.9745407, 2.70089769, 68.4730835, 4.76837158e-07, 0, 1.00000274, 0, 1, 0, -1.0000006, 0, -4.76837158e-07); NpcClass=nil;};
			};
			
			local HeliBandits = {};
			
			for name, info in pairs(BanditNpcs) do
				local banditNpcClass: NpcClass = modNpcs.spawn2{
					Name = "Bandit";
					CFrame = info.SpawnCFrame;
					Player = player;
					BindSetup = function(npcClass: NpcClass)
						local properties = npcClass.Properties;
						properties.Seed = player.UserId + info.Index;
						properties.Immortal = 1;
						properties.CutsceneActive = true;
					
						if name == "NameB" then
							properties.Seed = 16170945;
						end

						npcClass.Character:SetAttribute("LookAtClient", false);
					end;
				};
				info.NpcClass = banditNpcClass;

				banditNpcClass.Move:SetMoveSpeed("set", "default", 8);

				banditNpcClass.WieldComp:Equip{
					ItemId = "ak47";
				};
				if math.fmod(info.NpcClass.Properties.Seed, 2) == 0 then
					banditNpcClass.WieldComp:InvokeToolAction("ToggleIdle");
				end
			end
			

			local extractionHelicopter = workspace.Environment:WaitForChild("ExtractionHelicopter");
			local heliAnimController = extractionHelicopter:WaitForChild("AnimationController");
			local heliRotationAtt = extractionHelicopter:WaitForChild("Root"):WaitForChild("OrientationAlign");
			
			extractionHelicopter:SetAttribute("DynamicPlatform", true);
			extractionHelicopter.PrimaryPart:SetNetworkOwner(nil);
			
			local heliControlPart = workspace:WaitForChild("HeliControl");
			local heliControlAtt = heliControlPart:WaitForChild("HeliPos");
			local HeliAnim = {};
			
			for _, anim in pairs(heliControlPart:WaitForChild("Animations"):GetChildren()) do
				HeliAnim[anim.Name] = heliAnimController:LoadAnimation(anim);
			end
			
			HeliAnim.TopRotor:Play();
			HeliAnim.TopRotor:AdjustSpeed(0.5);
			
			HeliAnim.OpenDoors:Play();
			

			local sound = modAudio.Play("HelicopterCore", extractionHelicopter.PrimaryPart);
			
			local rampClip = cutsceneAssets:WaitForChild("RampClip");

			local zarkNpcClass: NpcClass = modNpcs.spawn2{
				Name = "Zark";
				CFrame = CFrame.new(14.7941093, 21.8458672, 37.5151329, -0.999998569, 0, 0, 0, 1, 0, 0, 0, -0.99999845);
				Player = player;
			};
			
			local banditPilotNpcClass: NpcClass = modNpcs.spawn2{
				Name = "Bandit Pilot";
				CFrame = CFrame.new(-2193.129, 123.118, 2147.966);
				PackageOverride = "Human";
			};
			banditPilotNpcClass:Sit(extractionHelicopter.PilotSeatModelR.PSeat);
			
			for a=1, 2 do
				local banditNpcClass: NpcClass = modNpcs.spawn2{
					Name = "Bandit";
					CFrame = CFrame.new(-2193.129, 123.118, 2147.966);
					Player = player;
					BindSetup = function(npcClass: NpcClass)
						npcClass.Properties.CutsceneActive = true;
						npcClass.Properties.Immortal = 1;
						npcClass.Properties.Seed = player.UserId +10 + a;
					end
				};

				banditNpcClass.WieldComp:Equip{
					ItemId = "ak47";
				};
				banditNpcClass.WieldComp:InvokeToolAction("ToggleIdle");
				banditNpcClass:Sit(extractionHelicopter["SeatModel"..a].Seat);
				
				
				if a == 1 then
					HeliBandits.ANpcClass = banditNpcClass;
					
				elseif a == 2 then
					HeliBandits.BNpcClass = banditNpcClass;
					
				end
			end

			local loranNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Loran");
			if loranNpcClass == nil then
				loranNpcClass = modNpcs.spawn2{
					Name = "Loran";
					CFrame = CFrame.new(-2170.40186, 119.44278, 2131.82178, -0.874617875, 0, 0.484808505, 0, 1, 0, -0.484808505, 0, -0.874617875);
				};
				loranNpcClass:ToggleInteractable(false);
				loranNpcClass:GetComponent("AvatarFace"):Set("Suspicious", game.Players:GetPlayers());

				task.delay(1, function()
					loranNpcClass.PlayAnimation("crossedarm");
				end)
			end

			local heliBanditANpcClass: NpcClass = HeliBandits.ANpcClass;
			local heliBanditBNpcClass: NpcClass = HeliBandits.BNpcClass;

			local strangerANpcClass: NpcClass = StrangerNpcs.NameA.NpcClass;
			local strangerBNpcClass: NpcClass = StrangerNpcs.NameB.NpcClass;
			local strangerCNpcClass: NpcClass = StrangerNpcs.NameC.NpcClass;

			local banditANpcClass: NpcClass = BanditNpcs.Name1.NpcClass;
			local banditBNpcClass: NpcClass = BanditNpcs.Name2.NpcClass;
			
			local cutsceneTracks = {};
			local point3Active = false;
			local function OnChanged(firstRun)
				local playerClass: PlayerClass = shared.modPlayers.get(player);
				Debugger:Log("mission", mission)
				
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint <= 2 then
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 3;
						end)
						
					elseif mission.ProgressionPoint == 3 then
						Debugger:Warn("mission.ProgressionPoint", mission.ProgressionPoint);
						local playerSpawnA = CFrame.new(-2195.11426, 110.573784, 2200.39697, 0.707106829, 0, 0.70710665, 0, 1, 0, -0.70710665, 0, 0.707106829);
						
						repeat task.wait() until playerClass.Character ~= nil; task.wait(0.1);
						
						modStatusEffects.SetWalkspeed(player, 0);
						CutsceneSequence:NextScene("freezePlayer");
						modStatusEffects.SetWalkspeed(player, 0);
						playerClass:SetCFrame(playerSpawnA);
						CutsceneSequence:Pause(60);
						
						if point3Active then return end;
						point3Active = true;
						
						rampClip.Parent = workspace.Clips;
						
						banditANpcClass.Chat(player, "Listen up, yall going to meet Zark, so move along!");
						
						task.wait(4);

						banditBNpcClass.Chat(player, "Get on the chopper, one by one!");


						strangerANpcClass.Move:SetMoveSpeed("set", "walk", 6, 2);
						strangerANpcClass.Move:MoveTo(Vector3.new(-2189.084, 122.808, 2141.123));
						strangerANpcClass.Move.OnMoveToEnded:Once(function()
							task.wait();
							strangerANpcClass:Sit(extractionHelicopter["SeatModelA"].Seat);
						end)
						task.wait(1);

						strangerBNpcClass.Move:SetMoveSpeed("set", "walk", 6, 2);
						strangerBNpcClass.Move:MoveTo(Vector3.new(-2189.084, 122.808, 2141.123));
						strangerBNpcClass.Move.OnMoveToEnded:Once(function()
							task.wait();
							strangerBNpcClass:Sit(extractionHelicopter["SeatModelB"].Seat);
						end)
						task.wait(1);
						
						local strangerCSit = false;
						strangerCNpcClass.Move:SetMoveSpeed("set", "walk", 6, 2);
						strangerCNpcClass.Move:MoveTo(Vector3.new(-2189.084, 122.808, 2141.123));
						strangerCNpcClass.Move.OnMoveToEnded:Once(function()
							strangerCSit = true;
							task.wait();
							strangerCNpcClass:Sit(extractionHelicopter["SeatModelC"].Seat);
						end)

						modStatusEffects.SetWalkspeed(player, 6);

						local angerState =0;
						local angerCooldown = tick();
						task.spawn(function()
							while mission.ProgressionPoint == 3 do
								local distFromC = playerClass:DistanceFromCharacter(strangerCNpcClass:GetCFrame().Position);
								
								Debugger:Log("distFromC", distFromC);
								
								if tick()-angerCooldown >= 5 then
									angerCooldown = tick();
									
									if distFromC >= 15 then
										if angerState == 0 then
											banditBNpcClass.Chat(player, "Recruit! Get moving! Follow the line!");
											banditBNpcClass.Move:Face("Player");
									
											angerState = 1;
											
										elseif angerState == 1 then
											banditBNpcClass.Chat(player, "What are you doing?! Keep moving!");

											angerState = 2;

										elseif angerState == 2 then
											banditBNpcClass.Chat(player, "Don't make me say it again!");
											banditBNpcClass.WieldComp:InvokeToolAction("LoadGun");

											angerState = 3;

										elseif angerState == 4 then
											banditBNpcClass.WieldComp.TargetableTags.Player = true;
											banditBNpcClass.Move:Face(playerClass.RootPart.Position);
											banditBNpcClass.WieldComp:InvokeToolAction("PrimaryFireRequest", nil, playerClass.Humanoid);

											angerState = 5;
											break;
										end

									end
								end

								if distFromC < 10 and strangerCSit then

									repeat
										Debugger:Log("Waiting for player to sit");
										task.wait(0.1)
									until playerClass.Humanoid.Sit == true;
									
									if strangerANpcClass.Humanoid.Sit == false then
										strangerANpcClass:Sit(extractionHelicopter["SeatModelA"].Seat);
									end
									if strangerBNpcClass.Humanoid.Sit == false then
										strangerBNpcClass:Sit(extractionHelicopter["SeatModelB"].Seat);
									end
									if strangerCNpcClass.Humanoid.Sit == false then
										strangerCNpcClass:Sit(extractionHelicopter["SeatModelC"].Seat);
									end
									
									Debugger:Log("Player is sit");
									modMission:Progress(player, MISSION_ID, function(mission)
										mission.ProgressionPoint = 4;
									end)
								end
								
								task.wait(0.3);
							end
							
							Debugger:Log("Loop broke")
						end)
						
					elseif mission.ProgressionPoint == 4 then
						
						Debugger:Log("ProgressionPoint 4");
						modStatusEffects.SetWalkspeed(player, 0);

						loranNpcClass.StopAnimation("CrossedArm");
						loranNpcClass.Move:SetMoveSpeed("set", "default", 8);
						loranNpcClass.Chat(player, "Alright, let's get moving..");
						loranNpcClass.Move:MoveTo(Vector3.new(-2189.084, 122.808, 2141.123));
						loranNpcClass.Move.OnMoveToEnded:Wait(10);
						task.wait();

						loranNpcClass:Sit(extractionHelicopter["PilotSeatModelL"].PSeat1);
						task.wait(2);
						
						HeliAnim.OpenDoors:Stop(1);
						task.wait(1);
						
						TweenService:Create(heliControlAtt, TweenInfo.new(5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
							Position = Vector3.new(-0.199, 3.166+50, 6.049);
						}):Play();
						task.wait(5);


						local lastPosition, orientationAlignPos, lastRotY;
						local lastRotAttCFrame = heliRotationAtt.CFrame;
						RunService.Stepped:Connect(function(_, delta)
							if extractionHelicopter.PrimaryPart.Anchored then
								return;
							end
							extractionHelicopter.PrimaryPart:SetNetworkOwner(nil);
							if lastPosition == nil then lastPosition = extractionHelicopter:GetPivot().Position; end
							if orientationAlignPos == nil then orientationAlignPos = heliRotationAtt.CFrame.Position; end

							local rootPos = extractionHelicopter:GetPivot().Position;
							local motionDelta = (Vector2.new(lastPosition.X, lastPosition.Z) - Vector2.new(rootPos.X, rootPos.Z));
							local motionVel = motionDelta.Magnitude/delta;
							local motionDir = motionDelta.Unit;

							if motionVel > 1 then
								local worldRotationY = -math.atan2(motionDir.X, motionDir.Y);

								local newCf = CFrame.new(orientationAlignPos) 
									* CFrame.Angles(math.rad(12), 0, math.sin(tick())/16) 
									* CFrame.Angles(0, worldRotationY, 0);

								heliRotationAtt.CFrame = lastRotAttCFrame:Lerp(newCf, 0.01);

								lastRotAttCFrame = heliRotationAtt.CFrame;
								lastRotY = worldRotationY;

							else
								local sinWave = math.sin(tick()/2)/30;
								
								local newCf = CFrame.new(orientationAlignPos) 
									* CFrame.Angles(sinWave, 0, -sinWave)
									* CFrame.Angles(0, (lastRotY or 0), 0);
								

								heliRotationAtt.CFrame = lastRotAttCFrame:Lerp(newCf, 0.1);
								lastRotAttCFrame = heliRotationAtt.CFrame;
							end

							lastPosition = rootPos;
						end)
						
						local tweenTravel = TweenService:Create(heliControlAtt, TweenInfo.new(30, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
							WorldPosition = Vector3.new(-432.907, 169.953, 195.204);
						})
						
						tweenTravel:Play();
						
						repeat 
							task.wait(1);
							Debugger:Log("Traveling"); 
						until tweenTravel.PlaybackState ~= Enum.PlaybackState.Playing;
						
						task.wait(1);
						
						HeliAnim.OpenDoors:Play(1);
						task.wait(1.2);
						
						loranNpcClass.Character:SetAttribute("LookAtClient", false);
						--Vector3.new(-118.656, 169.953, 198.573);
						loranNpcClass:Sit();

						local joint = cutsceneAssets:WaitForChild("LoranHeliJoint"):Clone();
						joint.Parent = extractionHelicopter.Root;
						joint.Part0 = extractionHelicopter.Root;
						joint.Part1 = loranNpcClass.RootPart;
						loranNpcClass.Humanoid.PlatformStand = true;

						local jointB = cutsceneAssets:WaitForChild("StrangerAJoint"):Clone();
						jointB.Parent = extractionHelicopter.Root;
						jointB.Part0 = extractionHelicopter.Root;
						jointB.Part1 = strangerANpcClass.RootPart;
						strangerANpcClass.Humanoid.PlatformStand = true;
						
						loranNpcClass.Chat(player, "Listen up recruits! We know one of you is an intelligence officer.. Reveal yourselves or you will be kicked off the helicopter!");
						loranNpcClass:GetComponent("AvatarFace"):Set("Frustrated", game.Players:GetPlayers());

						loranNpcClass.Move:HeadTrack(playerClass.Head);
						loranNpcClass.Character:SetAttribute("LookAtClient", nil);
						
						strangerANpcClass.Move:HeadTrack(loranNpcClass.Head);
						strangerANpcClass.Character:SetAttribute("LookAtClient", nil);

						strangerBNpcClass.Move:HeadTrack(loranNpcClass.Head);
						strangerBNpcClass.Character:SetAttribute("LookAtClient", nil);
						
						strangerCNpcClass.Move:HeadTrack(loranNpcClass.Head);
						strangerCNpcClass.Character:SetAttribute("LookAtClient", nil);
						
						task.wait(8);
						
						loranNpcClass.Chat(player, "You have 3 seconds to reveal yourself!");
						
						strangerBNpcClass.Chat(player, "Wait wha...");
						strangerBNpcClass:GetComponent("AvatarFace"):Set("Skeptical", game.Players:GetPlayers());
						
						task.wait(3);
						loranNpcClass.Chat(player, "2!..");
						
						task.wait(0.5);

						strangerCNpcClass.Chat(player, "I'm not a spy!");
						strangerCNpcClass:GetComponent("AvatarFace"):Set("Scared", game.Players:GetPlayers());

						task.wait(1.5);
						loranNpcClass.Chat(player, "1 and a half..");
						task.wait(1.5);
						loranNpcClass.Chat(player, "Okay, one of you is getting toss out!");
						
						local animationL1: AnimationTrack = loranNpcClass.Humanoid:LoadAnimation(cutsceneAssets.L1);
						animationL1:SetAttribute("CustomAnimate", true);
						local animationS1: AnimationTrack = strangerANpcClass.Humanoid:LoadAnimation(cutsceneAssets.S1);
						animationS1:SetAttribute("CustomAnimate", true);
						
						strangerANpcClass:Sit();
						loranNpcClass.Move:HeadTrack(strangerANpcClass.Head);
						
						strangerANpcClass:GetComponent("AvatarFace"):Set("Worried", game.Players:GetPlayers());
						
						task.wait(0.3);
						animationL1:Play();
						animationS1:Play();
						
						strangerCNpcClass.Chat(player, "No!! Please!");
						strangerANpcClass:GetComponent("AvatarFace"):Set("Scared", game.Players:GetPlayers());
						
						task.wait(3);
						strangerANpcClass.Chat(player, "Ahhhh!");

						task.wait(1.66);
						loranNpcClass.Chat(player, "Well?!");
						animationL1:AdjustSpeed(0);
						animationS1:AdjustSpeed(0);
						cutsceneTracks.L1 = animationL1;
						cutsceneTracks.S1 = animationS1;
						
						strangerANpcClass.Chat(player, "Help!!!");

						modMission:Progress(player, 63, function(mission)
							mission.ProgressionPoint = 5;
						end)
						
						
					elseif mission.ProgressionPoint == 5 then

						Debugger:Log("ProgressionPoint 5");
						loranNpcClass:ToggleInteractable(true);
						
						zarkNpcClass.PlayAnimation("leanonfencing");
						zarkNpcClass.Move:HeadTrack(playerClass.Head);

					elseif mission.ProgressionPoint == 6 then

						task.wait(1);
						Debugger:Log("ProgressionPoint 6");
						loranNpcClass:ToggleInteractable(false);

						strangerBNpcClass:GetComponent("AvatarFace"):Set("Frustrated", game.Players:GetPlayers());
						
						cutsceneTracks.L1.TimePosition = 4.1;
						strangerBNpcClass.Chat(player, "Stop!");
						strangerBNpcClass.Move:HeadTrack(loranNpcClass.Head);
						strangerBNpcClass.Character:SetAttribute("LookAtClient", nil);
						
						task.wait(0.5);
						loranNpcClass.Move:HeadTrack(strangerBNpcClass.Head);
						
						task.wait(3);
						strangerBNpcClass.Chat(player, "I'm the informant! You can spare them..");
						
						task.wait(3.5);
						strangerANpcClass.Chat(player, "Ahhhhhh!");
						task.wait(0.5);
						
						loranNpcClass.Chat(player, "Took you a while to show yourself.");
						task.wait(3.5);
						
						loranNpcClass.Chat(player, "Is getting caught part of the plan?!");
						task.wait(4);

						strangerBNpcClass.Chat(player, "...");
						
						task.wait(3.5);
						loranNpcClass.Chat(player, "Well, you're going to see the insides of a cell.");
						
						local animationL2: AnimationTrack = loranNpcClass.Humanoid:LoadAnimation(cutsceneAssets.L2);
						animationL2:SetAttribute("CustomAnimate", true);
						local animationS2: AnimationTrack = strangerANpcClass.Humanoid:LoadAnimation(cutsceneAssets.S2);
						animationS2:SetAttribute("CustomAnimate", true);

						animationL2:Play();
						animationS2:Play();
						
						strangerANpcClass.Move:HeadTrack(nil);
						strangerANpcClass:GetComponent("AvatarFace"):Set("Worried", game.Players:GetPlayers());
						
						task.wait(2);
						cutsceneTracks.L1:Stop();
						cutsceneTracks.S1:Stop();
						
						strangerANpcClass.Chat(player, "Thank god!");
						task.wait(0.5);
						loranNpcClass.Chat(player, "Get back to your seat! We are landing..");

						strangerANpcClass.Move:HeadTrack(nil);
						strangerBNpcClass.Move:HeadTrack(nil);
						strangerCNpcClass.Move:HeadTrack(nil);
						
						task.wait(2);
						extractionHelicopter["SeatModelA"].Seat:Sit(strangerANpcClass.Humanoid);
						task.wait(2);
						extractionHelicopter["PilotSeatModelL"].PSeat1:Sit(loranNpcClass.Humanoid);

						HeliAnim.OpenDoors:Stop(1);
						
						task.wait(4);
						
						local tweenTravel = TweenService:Create(heliControlAtt, TweenInfo.new(16, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
							WorldPosition = Vector3.new(17.131, 6.445, 155.392);
						})
						tweenTravel:Play();
						
						task.wait(14);
						
						extractionHelicopter.PrimaryPart.Anchored = true;
						
						TweenService:Create(extractionHelicopter.PrimaryPart, TweenInfo.new(5), {
							CFrame=CFrame.new(17.1310005, 3.00069523, 155.391998, -4.37113954e-08, 2.22044605e-16, -1, 1.49011647e-08, 0.999999881, -7.4505806e-09, 1.00000024, 7.47552633e-16, -4.37113883e-08);
						}):Play();

						HeliAnim.OpenDoors:Play(1);

						game.Debris:AddItem(extractionHelicopter.Root:FindFirstChild("StrangerAJoint"), 0);
						game.Debris:AddItem(extractionHelicopter.Root:FindFirstChild("LoranHeliJoint"), 0);
						loranNpcClass.Humanoid.PlatformStand = false;
						strangerANpcClass.Humanoid.PlatformStand = false;
						
						task.wait(5);
						
						loranNpcClass:Sit();
						loranNpcClass:SetCFrame(CFrame.new(19.4782352, 5.81299686, 154.311783, 0.999999404, -6.31088724e-30, -7.10542312e-15, 1.05879081e-22, 0.999999702, 1.49011479e-08, 7.10542482e-15, -1.49011568e-08, 0.999999106))
						loranNpcClass.Move:MoveTo(Vector3.new(23.148, 2.399, 146.349));
						loranNpcClass:GetComponent("AvatarFace"):Set("Grumpy", game.Players:GetPlayers());

						task.wait(1);
						loranNpcClass.Move:Face(Vector3.new(17.35, 2.399, 154.063));
						loranNpcClass.Chat(player, "Everyone, get off!");
						
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 7;
						end)

					elseif mission.ProgressionPoint == 7 then
						Debugger:Log("ProgressionPoint 7");

						modStatusEffects.SetWalkspeed(player, nil);
						
						local movementCompleteSB = false;
						strangerANpcClass:Sit();
						task.wait(0.4);

						strangerANpcClass.Move:MoveTo(Vector3.new(19.219, 2.481, 128.767));
						strangerANpcClass.Move.OnMoveToEnded:Once(function()
							task.wait();
							strangerANpcClass:SetCFrame(CFrame.new(19.2189999, 2.48099995, 128.766998, 0.999998808, 3.78653475e-29, 1.69406246e-21, -5.04870949e-29, 0.999999404, 0, -2.54109662e-21, 0, 0.999998212));
							task.wait(1);
							strangerANpcClass.Move:MoveTo(Vector3.new(19.2190037, 2.54997015, 95.2484207))
						end)
						strangerANpcClass:GetComponent("AvatarFace"):Set("Worried", game.Players:GetPlayers());
						task.wait(0.5);
						
						strangerBNpcClass:Sit();
						task.wait(0.4);

						strangerBNpcClass.Move:MoveTo(Vector3.new(13.944, 2.481, 128.767));
						strangerBNpcClass.Move.OnMoveToEnded:Once(function()
							task.wait();
							strangerBNpcClass:SetCFrame(CFrame.new(13.9440002, 2.48099995, 128.766998, 0.999998808, 3.15544813e-29, 2.11757894e-21, -4.41762348e-29, 0.999999404, 0, -2.9646135e-21, 0, 0.999998212));

							loranNpcClass.Move:MoveTo(Vector3.new(17.107, 2.611, 82.917));
							loranNpcClass.Move.OnMoveToEnded:Once(function()
								loranNpcClass.Move:Face(Vector3.new(17.35, 2.399, 154.063));
								loranNpcClass.Chat(player, "In position!");
							end)
							
							task.wait(1);
							strangerBNpcClass.Move:MoveTo(Vector3.new(13.9440041, 2.54997015, 95.2484207));
							strangerBNpcClass.Move.OnMoveToEnded:Wait();
							movementCompleteSB = true;
						end)

						strangerBNpcClass:GetComponent("AvatarFace"):Set("Skeptical", game.Players:GetPlayers());
						task.wait(0.5);
						
						strangerCNpcClass:Sit();
						task.wait(0.4);

						strangerCNpcClass.Move:MoveTo(Vector3.new(18.02, 2.481, 132.745));
						strangerCNpcClass.Move.OnMoveToEnded:Once(function()
							task.wait();
							strangerCNpcClass:SetCFrame(CFrame.new(18.0200005, 2.48099995, 132.744995, 0.999998808, 4.41762107e-29, 1.27054599e-21, -5.67979551e-29, 0.999999404, 0, -2.11757994e-21, 0, 0.999998212));
							task.wait(1);
							strangerCNpcClass.Move:MoveTo(Vector3.new(18.0200062, 2.54997015, 99.2264175));
						end)
						strangerCNpcClass:GetComponent("AvatarFace"):Set("Skeptical", game.Players:GetPlayers());
						task.wait(0.5);
						
						heliBanditANpcClass:Sit();
						heliBanditBNpcClass:Sit();
						
						heliBanditANpcClass.Move:MoveTo(Vector3.new(-0.151, 2.481, 107.001));
						heliBanditANpcClass.Move.OnMoveToEnded:Once(function()
							task.wait();
							heliBanditANpcClass:SetCFrame(CFrame.new(-0.150912821, 2.48087144, 107.000923, 8.07793567e-28, 0, -1, -6.01853108e-36, 1, 0, 1, -6.01853108e-36, -8.07793567e-28));
						end)
						
						heliBanditBNpcClass.Move:MoveTo(Vector3.new(30.185, 2.481, 107.001));
						heliBanditBNpcClass.Move.OnMoveToEnded:Once(function()
							task.wait();
							heliBanditBNpcClass:SetCFrame(CFrame.new(30.1851215, 2.48087096, 107.000923, 0, 0, 1, 0, 1, 0, -1, 0, 0));
						end)
						
						repeat task.wait() until movementCompleteSB;
						Debugger:Log("wait for dist");
						
						modMission:Progress(player, 63, function(mission)
							mission.ProgressionPoint = 8;
						end)
						
					elseif mission.ProgressionPoint == 8 then
						zarkNpcClass:ToggleInteractable(false);

						local distFromC = math.huge;
						repeat
							distFromC = playerClass:DistanceFromCharacter(strangerCNpcClass:GetCFrame().Position);
							Debugger:Log("distFromC", distFromC);
							task.wait(1);
						until distFromC <= 15;
						
						task.wait(4);
						
						zarkNpcClass.Chat(player, "Welcome, recruits!");
						task.wait(4);
						zarkNpcClass.Chat(player, "We bandits are like bears.. Where there are fishes in the streams, we will catch and bring them back to me. It is just the new natural cycle. Isn't that right, Loran?");
						task.wait(10);
						loranNpcClass.Chat(player, "Yes, sir!");
						task.wait(4);
						zarkNpcClass.Chat(player, "It's kill or be killed. There is no them, there is only us!");
						task.wait(6);
						zarkNpcClass.Chat(player, "You will all have to prove your loyalty..");
						task.wait(6);
						

						zarkNpcClass.Move:SetMoveSpeed("set", "default", 8);
						zarkNpcClass.StopAnimation("leanonfencing");
						
						zarkNpcClass.Move:MoveTo(Vector3.new(52.525, 21.726, 34.061));
						zarkNpcClass.Move.OnMoveToEnded:Wait(10);
						zarkNpcClass:TeleportHide();
						task.wait(4);

						zarkNpcClass:SetCFrame(CFrame.new(49.6023064, 2.58089828, 35.0045166, -1, 0, 0, 0, 1, 0, 0, 0, -1));
						task.wait();

						zarkNpcClass.Move:MoveTo(Vector3.new(16.093, 2.611, 78.89));
						zarkNpcClass.Move.OnMoveToEnded:Wait(10);
						
						zarkNpcClass.Move:HeadTrack(loranNpcClass.Head);
						zarkNpcClass.Chat(player, "Loran, take the other two back to the mall camp and give them their assignments. I'll handle the spy and our special guest myself.");
						task.wait(6);
						
						loranNpcClass.Chat(player, "Yes, sir!");
						task.wait(4);
						
						zarkNpcClass.Move:HeadTrack(playerClass.Head);
						
						loranNpcClass.Move:MoveTo(Vector3.new(14.18, 0.7, 157.95));
						loranNpcClass.Move.OnMoveToEnded:Once(function()
							game.Debris:AddItem(loranNpcClass.Character, 0);
						end);
						
						strangerANpcClass.Move:MoveTo(Vector3.new(14.18, 0.7, 157.95));
						loranNpcClass.Move.OnMoveToEnded:Once(function()
							game.Debris:AddItem(strangerANpcClass.Character, 0);
						end);
						
						strangerCNpcClass.Move:MoveTo(Vector3.new(14.18, 0.7, 157.95));
						loranNpcClass.Move.OnMoveToEnded:Once(function()
							game.Debris:AddItem(strangerCNpcClass.Character, 0);
						end);
						
						
						modMission:Progress(player, 63, function(mission)
							mission.ProgressionPoint = 9;
						end)
						
					elseif mission.ProgressionPoint == 9 then
						zarkNpcClass:ToggleInteractable(true);
						
					elseif mission.ProgressionPoint == 10 then
						zarkNpcClass:ToggleInteractable(false);
						
						task.wait(8);
						zarkNpcClass.Move:HeadTrack(heliBanditANpcClass.Head);
						zarkNpcClass.Move:Face(Vector3.new(-0.151, 2.481, 107.001));
						zarkNpcClass.Chat(player, "You! Take that man to the lockers.");
						
						task.wait(0.5);
						heliBanditANpcClass.Move:HeadTrack(zarkNpcClass.Head);
						heliBanditANpcClass.Move:Face(zarkNpcClass.Head.Position);
						
						task.wait(4);
						heliBanditANpcClass.Chat(player, "Yes, sir.");
						
						task.wait(3);
						
						heliBanditANpcClass.Move:HeadTrack(strangerBNpcClass.Head);
						heliBanditANpcClass.Move:MoveTo(Vector3.new(11.036, 2.601, 100.253));
						heliBanditANpcClass.Move.OnMoveToEnded:Once(function()
							heliBanditANpcClass.Chat(player, "Get moving..");

							heliBanditANpcClass.Move:SetMoveSpeed("set", "default", 8);
							strangerBNpcClass.Move:SetMoveSpeed("set", "default", 8);

							task.wait(0.5);
							strangerBNpcClass.Move:MoveTo(Vector3.new(-20.405, 2.581, 34.629));
							strangerBNpcClass.Move.OnMoveToEnded:Once(function()
								task.wait(0.2);
								game.Debris:AddItem(strangerBNpcClass.Character, 0);
							end)
							heliBanditANpcClass.Move:MoveTo(Vector3.new(-20.405, 2.581, 34.629));
							heliBanditANpcClass.Move.OnMoveToEnded:Once(function()
								game.Debris:AddItem(heliBanditANpcClass.Character, 0);
							end)
						end)
						heliBanditBNpcClass.Move:MoveTo(Vector3.new(18.046, 2.601, 100.079));
						heliBanditBNpcClass.Move.OnMoveToEnded:Once(function()
							heliBanditBNpcClass.Move:SetMoveSpeed("set", "default", 8);
							task.wait(1.2);
							heliBanditBNpcClass.Move:MoveTo(Vector3.new(-20.405, 2.581, 34.629));
							heliBanditBNpcClass.Move.OnMoveToEnded:Once(function()
								game.Debris:AddItem(heliBanditBNpcClass.Character, 0);
							end)
						end)
						
						task.spawn(function()
							for a=1, 40 do
								zarkNpcClass.Move:Face(heliBanditANpcClass.Head.Position);
								task.wait(0.1);
							end
						end)
						
						
						task.wait(4);
						zarkNpcClass.Move:HeadTrack();
						zarkNpcClass.Move:Face(playerClass.Head.Position);
						
						task.wait(0.5);
						zarkNpcClass.Chat(player, "Anyways..");

						modMission:Progress(player, 63, function(mission)
							mission.ProgressionPoint = 11;
						end)

					elseif mission.ProgressionPoint == 11 then
						zarkNpcClass:ToggleInteractable(true);
						
						task.spawn(function()
							while mission.ProgressionPoint == 11 do
								task.wait(0.1);
								zarkNpcClass.Move:Face(playerClass.Head.Position);
							end
						end)

					elseif mission.ProgressionPoint == 12 then
						zarkNpcClass:ToggleInteractable(false);
						
					end
				elseif mission.Type == 3 then -- OnComplete

				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)

		CutsceneSequence:NewScene("freezePlayer", function()
			modConfigurations.Set("DisableMissions", false);
			modConfigurations.Set("DisableMajorNotifications", false);
			modConfigurations.Set("DisablePinnedMission", false);
			modConfigurations.Set("DisableDialogue", false);

			modData.ToggleChat();
		end)
		
	end

	
	return CutsceneSequence;
end;