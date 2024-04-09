local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local random = Random.new();
--== Server Variables;
if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule"));
	
end

--== Script;
return function(CutsceneSequence)
	if modBranchConfigs.IsWorld("TheMall") or modBranchConfigs.IsWorld("BioXResearch") then
		
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, 63);
			if mission == nil then return end;

			local gateBandit;
			
			local function spawnBandit()
				modNpc.Spawn("Bandit", CFrame.new(798.55481, 162.668854, -728.297119, 0, 0, 1, 0, 1, 0, -1, 0, 0), function(npc, npcModule)
					npcModule.Owner = player;
					gateBandit = npcModule;
					
					npcModule.Seed = player.UserId;
					npcModule:AddDialogueInteractable();
					npcModule:AddComponent(game.ServerScriptService.ServerLibrary.Entity.Npc.Bandit.RandomSkin);
					npcModule.RandomSkin();
					npcModule.Movement:SetWalkSpeed("default", 8);

				end, modNpc.NpcBaseModules.CutsceneHuman);
				
				task.delay(1, function()
					gateBandit.Wield.Equip("ak47");
					task.wait();
					gateBandit.RootPart.Anchored = true;
				end)
				
				modReplicationManager.ReplicateOut(player, gateBandit.Prefab);
			end
			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						if gateBandit == nil then
							spawnBandit();
						end
						
					elseif mission.ProgressionPoint == 2 then
						if gateBandit == nil then
							spawnBandit();
						end

					elseif mission.ProgressionPoint == 3 then
						local classPlayer = shared.modPlayers.Get(player);
						
						--modStatusEffects.CoveredVision(player, true);
						
						--local newClothmask = game.ServerStorage.PrefabStorage.Cosmetics.HeadGroup.clothbagmask:Clone();
						--newClothmask.Parent = classPlayer.Character;
						
						if gateBandit then
							task.wait(5);
							gateBandit.Prefab:Destroy();
							gateBandit:Destroy();
						end
					end
				elseif mission.Type == 3 then -- OnComplete


				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true, mission);
		end)
		
		
	elseif modBranchConfigs.IsWorld("BanditsRecruitment") then
		
		CutsceneSequence:Initialize(function()
			local clothBagMaskPrefab = game.ServerStorage:WaitForChild("PrefabStorage"):WaitForChild("Cosmetics"):WaitForChild("HeadGroup"):WaitForChild("clothbagmask");
			
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			
			local mission = modMission:GetMission(player, 63);
			if mission == nil then return end;

			game.Players:SetAttribute("AutoRespawn", true);
			workspace:FindFirstChild("Tom Greyman"):Destroy();
			
			local StrangerNpcs = {
				NameA={Index=1; SpawnCFrame=CFrame.new(-2203.62329, 110.573784, 2191.88818, 0.707106829, 0, 0.70710665, 0, 1, 0, -0.70710665, 0, 0.707106829);};
				NameB={Index=2; SpawnCFrame=CFrame.new(-2200.81152, 110.573784, 2194.69971, 0.707106888, 0, 0.707106709, 0, 1, 0, -0.707106709, 0, 0.707106888);};
				NameC={Index=3; SpawnCFrame=CFrame.new(-2197.92627, 110.573784, 2197.58545, 0.707106829, 0, 0.70710665, 0, 1, 0, -0.70710665, 0, 0.707106829);};
			};
			
			for name, info in pairs(StrangerNpcs) do
				modNpc.Spawn("Stranger", info.SpawnCFrame, function(npc, npcModule)
					npcModule.Seed = player.UserId + info.Index;
					
					if name == "NameB" then
						npcModule.Seed = 16170945;
					end
					
					npcModule.Owner = player;
					npcModule.Prefab.Name = name;
					
					--npcModule.RandomSkin();
					--npcModule:AddComponent(game.ServerScriptService.ServerLibrary.Entity.Npc.Bandit.RandomSkin);
					
					npcModule:AddComponent("RandomClothing");
					npcModule.RandomClothing("Stranger", npcModule.Seed);
					
					npcModule.Movement:SetWalkSpeed("default", 6);
					
					npc:SetAttribute("LookAtClient", false);

					info.NpcModule = npcModule;
				end, modNpc.NpcBaseModules.CutsceneHuman);


				if math.fmod(info.NpcModule.Seed, 2) == 0 then
					info.NpcModule.AvatarFace:Set("Serious", game.Players:GetPlayers());
				else
					info.NpcModule.AvatarFace:Set("Skeptical", game.Players:GetPlayers());
				end
			end
			
			
			local BanditNpcs = {
				Name1={Index=1; SpawnCFrame=CFrame.new(-2191.70508, 110.573776, 2215.65112, 1, 0, 0, 0, 1, 0, 0, 0, 1)};
				Name2={Index=2; SpawnCFrame=CFrame.new(-2223.28345, 110.573784, 2200.97583, 0.37460658, 0, -0.927183867, 0, 1, 0, 0.927183867, 0, 0.37460658)};
				Name3={Index=3; SpawnCFrame=CFrame.new(-2219.10742, 110.573784, 2172.87793, -0.766045332, 0, -0.642788351, 0, 1, 0, 0.642788351, 0, -0.766045332)};
				Name4={Index=4; SpawnCFrame=CFrame.new(-2179.39062, 110.573784, 2192.7644, 0, 0, 1.00000238, 0, 1, 0, -1.00000238, 0, 0)};

				Name5={Index=5; SpawnCFrame=CFrame.new(-16.7903328, 3.50084543, 84.3079224, -0.207911521, 0, -0.978147745, 0, 1, 0, 0.978147626, 0, -0.207911551)};
				Name6={Index=6; SpawnCFrame=CFrame.new(-9.2598114, 2.73089767, 63.6921425, -0.766044796, 0, -0.642788708, 0, 1, 0, 0.642787635, 0, -0.766045332)};
				Name7={Index=7; SpawnCFrame=CFrame.new(46.8010941, 2.70089865, 59.8955536, -0.629318595, 0, 0.777143538, 0, 1, 0, -0.777143717, 0, -0.629318416)};
				Name8={Index=8; SpawnCFrame=CFrame.new(46.9745407, 2.70089769, 68.4730835, 4.76837158e-07, 0, 1.00000274, 0, 1, 0, -1.0000006, 0, -4.76837158e-07)};
			};
			
			local HeliBandits = {};
			
			for name, info in pairs(BanditNpcs) do
				modNpc.Spawn("Bandit", info.SpawnCFrame, function(npc, npcModule)
					npcModule.Seed = player.UserId + info.Index;
					npcModule.Owner = player;
					
					npcModule:AddComponent(game.ServerScriptService.ServerLibrary.Entity.Npc.Bandit.RandomSkin);
					npcModule.RandomSkin();
					npcModule.Movement:SetWalkSpeed("default", 8);

					info.NpcModule = npcModule;
				end, modNpc.NpcBaseModules.CutsceneHuman);

				info.NpcModule.Wield.Equip("ak47");
				if math.fmod(info.NpcModule.Seed, 2) == 0 then
					info.NpcModule.Wield.Handler:ToggleIdle();
				end
			end
			
			local extractionHelicopter = workspace.Environment:WaitForChild("ExtractionHelicopter");
			local heliAnimController = extractionHelicopter:WaitForChild("AnimationController");
			local heliRotationAtt = extractionHelicopter:WaitForChild("Root"):WaitForChild("OrientationAlign");
			
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
			
			local rampClip = script:WaitForChild("RampClip");

			local zarkNpcModule;
			modNpc.Spawn("Zark", CFrame.new(14.7941093, 21.8458672, 37.5151329, -0.999998569, 0, 0, 0, 1, 0, 0, 0, -0.99999845), function(npc, npcModule)
				npcModule.Owner = player;
				zarkNpcModule = npcModule;
			end);
			
			local banditPilotModule;
			modNpc.Spawn("Bandit Pilot", CFrame.new(-2193.129, 123.118, 2147.966), function(npc, npcModule)
				npcModule.Owner = player;
				banditPilotModule = npcModule;
			end, modNpc.NpcBaseModules.CutsceneHuman);
			extractionHelicopter.PilotSeatModelR.PSeat:Sit(banditPilotModule.Humanoid);
			
			for a=1, 2 do
				local banditNpcModule;
				modNpc.Spawn("Bandit", CFrame.new(-2193.129, 123.118, 2147.966), function(npc, npcModule)
					npcModule.Seed = player.UserId +10 + a;
					npcModule.Owner = player;

					npcModule:AddComponent(game.ServerScriptService.ServerLibrary.Entity.Npc.Bandit.RandomSkin);
					npcModule.RandomSkin();

					banditNpcModule = npcModule;
				end, modNpc.NpcBaseModules.CutsceneHuman);

				banditNpcModule.Wield.Equip("ak47");
				banditNpcModule.Wield.Handler:ToggleIdle();

				extractionHelicopter["SeatModel"..a].Seat:Sit(banditNpcModule.Humanoid);
				
				if a == 1 then
					HeliBandits.A = banditNpcModule;
					
				elseif a == 2 then
					HeliBandits.B = banditNpcModule;
					
				end
			end

			local loranModule = modNpc.GetPlayerNpc(player, "Loran");
			if loranModule == nil then
				local npc = modNpc.Spawn("Loran", CFrame.new(-2170.40186, 119.44278, 2131.82178, -0.874617875, 0, 0.484808505, 0, 1, 0, -0.484808505, 0, -0.874617875), function(npc, npcModule)
					npcModule.Owner = player;
					loranModule = npcModule;
				end);
				loranModule.Interactable.Parent = script;
				
				loranModule.AvatarFace:Set("Suspicious", game.Players:GetPlayers());

				task.delay(1, function()
					loranModule.PlayAnimation("crossedarm");
				end)
			end

			local banditA = HeliBandits.A;
			local banditB = HeliBandits.B;

			local strangerAModule = StrangerNpcs.NameA.NpcModule;
			local strangerBModule = StrangerNpcs.NameB.NpcModule;
			local strangerCModule = StrangerNpcs.NameC.NpcModule;
			
			local cutsceneTracks = {};
			local point3Active = false;
			local function OnChanged(firstRun)
				local classPlayer = shared.modPlayers.Get(player);
				Debugger:Log("mission", mission)
				
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint <= 2 then
						modMission:Progress(player, 63, function(mission)
							mission.ProgressionPoint = 3;
						end)
						
					elseif mission.ProgressionPoint == 3 then
						Debugger:Warn("mission.ProgressionPoint", mission.ProgressionPoint);
						local playerSpawnA = CFrame.new(-2195.11426, 110.573784, 2200.39697, 0.707106829, 0, 0.70710665, 0, 1, 0, -0.70710665, 0, 0.707106829);
						
						repeat task.wait() until classPlayer.Character ~= nil; task.wait(0.1);
						
						--modStatusEffects.CoveredVision(player, true);
						--if classPlayer.Character:FindFirstChild(clothBagMaskPrefab.Name) == nil then
						--	local newClothmask = clothBagMaskPrefab:Clone();
						--	newClothmask.Parent = classPlayer.Character;
							
						--end

						modStatusEffects.SetWalkspeed(player, 0);
						CutsceneSequence:NextScene("freezePlayer");
						modStatusEffects.SetWalkspeed(player, 0);
						shared.modAntiCheatService:Teleport(player, playerSpawnA);
						CutsceneSequence:Pause(60);
						
						if point3Active then return end;
						point3Active = true;
						
						rampClip.Parent = workspace.Clips;
						
						BanditNpcs.Name1.NpcModule.Chat(player, "Listen up, yall going to meet Zark, so move along!");
						
						task.wait(4);

						BanditNpcs.Name2.NpcModule.Chat(player, "Get on the chopper, one by one!");


						StrangerNpcs.NameA.NpcModule.Movement:Move(Vector3.new(-2189.084, 122.808, 2141.123)):OnComplete(function()
							task.wait();
							extractionHelicopter["SeatModelA"].Seat:Sit(StrangerNpcs.NameA.NpcModule.Humanoid);
						end)
						task.wait(1);
						StrangerNpcs.NameB.NpcModule.Movement:Move(Vector3.new(-2189.084, 122.808, 2141.123)):OnComplete(function()
							task.wait();
							extractionHelicopter["SeatModelB"].Seat:Sit(StrangerNpcs.NameB.NpcModule.Humanoid);
						end)
						task.wait(1);
						
						local strangerCSit = false;
						StrangerNpcs.NameC.NpcModule.Movement:Move(Vector3.new(-2189.084, 122.808, 2141.123)):OnComplete(function()
							strangerCSit = true;
							task.wait();
							extractionHelicopter["SeatModelC"].Seat:Sit(StrangerNpcs.NameC.NpcModule.Humanoid);
						end)

						modStatusEffects.SetWalkspeed(player, 6);

						local angerState =0;
						local angerCooldown = tick();
						task.spawn(function()
							while mission.ProgressionPoint == 3 do
								
								local distFromC = (classPlayer.RootPart.Position - StrangerNpcs.NameC.NpcModule.RootPart.Position).Magnitude;
								
								Debugger:Log("distFromC", distFromC);
								
								if tick()-angerCooldown >= 5 then
									angerCooldown = tick();
									
									if distFromC >= 15 then
										if angerState == 0 then
											BanditNpcs.Name2.NpcModule.Chat(player, "Recruit! Get moving! Follow the line!");
											BanditNpcs.Name2.NpcModule.Actions:FaceOwner();
											--task.wait(0.3);
											--local b2RootPart = BanditNpcs.Name2.NpcModule.RootPart;
											--BanditNpcs.Name2.NpcModule.Movement:Move(b2RootPart.Position + b2RootPart.CFrame.LookVector *5 );
											
											angerState = 1;
											
										elseif angerState == 1 then
											BanditNpcs.Name2.NpcModule.Chat(player, "What are you doing?! Keep moving!");

											angerState = 2;

										elseif angerState == 2 then
											BanditNpcs.Name2.NpcModule.Chat(player, "Don't make me say it again!");
											BanditNpcs.Name2.NpcModule.Wield.LoadRequest();

											angerState = 3;

										elseif angerState == 4 then
											BanditNpcs.Name2.NpcModule.Wield.Targetable.Humanoid = 0.5;
											BanditNpcs.Name2.NpcModule.Wield.SetEnemyHumanoid(classPlayer.Humanoid);
											BanditNpcs.Name2.NpcModule.Movement:Face(classPlayer.RootPart.Position);
											BanditNpcs.Name2.NpcModule.Wield.PrimaryFireRequest();
											
											
											angerState = 5;
											break;
										end

									end
								end

								if distFromC < 10 and strangerCSit then

									repeat
										Debugger:Log("Waiting for player to sit");
										task.wait(0.1)
									until classPlayer.Humanoid.Sit == true;
									
									if strangerAModule.Humanoid.Sit == false then
										extractionHelicopter["SeatModelA"].Seat:Sit(strangerAModule.Humanoid);
									end
									if strangerBModule.Humanoid.Sit == false then
										extractionHelicopter["SeatModelB"].Seat:Sit(strangerBModule.Humanoid);
									end
									if strangerCModule.Humanoid.Sit == false then
										extractionHelicopter["SeatModelC"].Seat:Sit(strangerCModule.Humanoid);
									end
									
									Debugger:Log("Player is sit");
									modMission:Progress(player, 63, function(mission)
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

						loranModule.StopAnimation("CrossedArm");
						loranModule.Movement:SetWalkSpeed("default", 8);
						loranModule.Chat(player, "Alright, let's get moving..");
						loranModule.Movement:Move(Vector3.new(-2189.084, 122.808, 2141.123)):Wait();
						
						task.wait();
						extractionHelicopter["PilotSeatModelL"].PSeat1:Sit(loranModule.Humanoid);
						
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
						
						repeat task.wait(1) Debugger:Log("Traveling") until tweenTravel.PlaybackState ~= Enum.PlaybackState.Playing;
						
						task.wait(1);
						
						HeliAnim.OpenDoors:Play(1);
						
						task.wait(1.2);
						
						loranModule.Prefab:SetAttribute("LookAtClient", false);
						--Vector3.new(-118.656, 169.953, 198.573);
						loranModule.Humanoid.Jump = true;

						local joint = script:WaitForChild("LoranHeliJoint"):Clone();
						joint.Parent = extractionHelicopter.Root;
						joint.Part0 = extractionHelicopter.Root;
						joint.Part1 = loranModule.RootPart;

						local jointB = script:WaitForChild("StrangerAJoint"):Clone();
						jointB.Parent = extractionHelicopter.Root;
						jointB.Part0 = extractionHelicopter.Root;
						jointB.Part1 = StrangerNpcs.NameA.NpcModule.RootPart;
						
						loranModule.Chat(player, "Listen up recruits! We know one of you is an intelligence officer.. Reveal yourselves or you will be kicked off the helicopter!");
						loranModule.AvatarFace:Set("Frustrated", game.Players:GetPlayers());

						loranModule.Move:HeadTrack(classPlayer.Head);
						loranModule.Prefab:SetAttribute("LookAtClient", nil);
						
						strangerAModule.Move:HeadTrack(loranModule.Head);
						strangerAModule.Prefab:SetAttribute("LookAtClient", nil);

						strangerBModule.Move:HeadTrack(loranModule.Head);
						strangerBModule.Prefab:SetAttribute("LookAtClient", nil);
						
						strangerCModule.Move:HeadTrack(loranModule.Head);
						strangerCModule.Prefab:SetAttribute("LookAtClient", nil);
						
						task.wait(8);
						
						loranModule.Chat(player, "You have 3 seconds to reveal yourself!");
						
						StrangerNpcs.NameB.NpcModule.Chat(player, "Wait wha...");
						StrangerNpcs.NameB.NpcModule.AvatarFace:Set("Skeptical", game.Players:GetPlayers());
						
						task.wait(3);
						loranModule.Chat(player, "2!..");
						
						task.wait(0.5);

						StrangerNpcs.NameC.NpcModule.Chat(player, "I'm not a spy!");
						StrangerNpcs.NameC.NpcModule.AvatarFace:Set("Scared", game.Players:GetPlayers());

						task.wait(1.5);
						loranModule.Chat(player, "1 and a half..");
						task.wait(1.5);
						loranModule.Chat(player, "Okay, one of you is getting toss out!");
						
						local animationL1 = loranModule.Humanoid:LoadAnimation(script.L1);
						local animationS1 = strangerAModule.Humanoid:LoadAnimation(script.S1);
						
						strangerAModule.Humanoid.Jump = true;
						loranModule.Move:HeadTrack(strangerAModule.Head);
						
						StrangerNpcs.NameA.NpcModule.AvatarFace:Set("Worried", game.Players:GetPlayers());
						
						task.wait(0.3);
						animationL1:Play();
						animationS1:Play();
						
						StrangerNpcs.NameC.NpcModule.Chat(player, "No!! Please!");
						StrangerNpcs.NameA.NpcModule.AvatarFace:Set("Scared", game.Players:GetPlayers());
						
						task.wait(3);
						strangerAModule.Chat(player, "Ahhhh!");

						task.wait(1.66);
						loranModule.Chat(player, "Well?!");
						animationL1:AdjustSpeed(0);
						animationS1:AdjustSpeed(0);
						cutsceneTracks.L1 = animationL1;
						cutsceneTracks.S1 = animationS1;
						
						strangerAModule.Chat(player, "Help!!!");

						modMission:Progress(player, 63, function(mission)
							mission.ProgressionPoint = 5;
						end)
						
						
					elseif mission.ProgressionPoint == 5 then

						Debugger:Log("ProgressionPoint 5");
						loranModule.Interactable.Parent = loranModule.Prefab;
						
						zarkNpcModule.PlayAnimation("leanonfencing");
						zarkNpcModule.Move:HeadTrack(classPlayer.Head);

					elseif mission.ProgressionPoint == 6 then

						task.wait(1);
						Debugger:Log("ProgressionPoint 6");
						loranModule.Interactable.Parent = script;

						local strangerAModule = StrangerNpcs.NameA.NpcModule;
						local strangerBModule = StrangerNpcs.NameB.NpcModule;

						strangerBModule.AvatarFace:Set("Frustrated", game.Players:GetPlayers());
						
						cutsceneTracks.L1.TimePosition = 4.1;
						strangerBModule.Chat(player, "Stop!");
						strangerBModule.Move:HeadTrack(loranModule.Head);
						strangerBModule.Prefab:SetAttribute("LookAtClient", nil);
						
						task.wait(0.5);
						loranModule.Move:HeadTrack(strangerBModule.Head);
						
						task.wait(3);
						strangerBModule.Chat(player, "I'm the informant! You can spare them..");
						
						task.wait(3.5);
						strangerAModule.Chat(player, "Ahhhhhh!");
						task.wait(0.5);
						
						loranModule.Chat(player, "Took you a while to show yourself.");
						task.wait(3.5);
						
						loranModule.Chat(player, "Is getting caught part of the plan?!");
						task.wait(4);

						strangerBModule.Chat(player, "...");
						
						task.wait(3.5);
						loranModule.Chat(player, "Well, you're going to see the insides of a cell.");
						
						local animationL2 = loranModule.Humanoid:LoadAnimation(script.L2);
						local animationS2 = strangerAModule.Humanoid:LoadAnimation(script.S2);

						animationL2:Play();
						animationS2:Play();
						
						strangerAModule.Move:HeadTrack(nil);
						strangerAModule.AvatarFace:Set("Worried", game.Players:GetPlayers());
						
						task.wait(2);
						cutsceneTracks.L1:Stop();
						cutsceneTracks.S1:Stop();
						
						strangerAModule.Chat(player, "Thank god!");
						task.wait(0.5);
						loranModule.Chat(player, "Get back to your seat! We are landing..");
						
						task.wait(2);
						extractionHelicopter["SeatModelA"].Seat:Sit(strangerAModule.Humanoid);
						task.wait(2);
						extractionHelicopter["PilotSeatModelL"].PSeat1:Sit(loranModule.Humanoid);

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
						
						task.wait(5);
						
						loranModule.Humanoid.Jump = true;
						loranModule.Actions:Teleport(CFrame.new(19.4782352, 5.81299686, 154.311783, 0.999999404, -6.31088724e-30, -7.10542312e-15, 1.05879081e-22, 0.999999702, 1.49011479e-08, 7.10542482e-15, -1.49011568e-08, 0.999999106))
						loranModule.Movement:Move(Vector3.new(23.148, 2.399, 146.349));
						loranModule.AvatarFace:Set("Grumpy", game.Players:GetPlayers());

						task.wait(1);
						loranModule.Movement:Face(Vector3.new(17.35, 2.399, 154.063));
						loranModule.Chat(player, "Everyone, get off!");
						
						modMission:Progress(player, 63, function(mission)
							mission.ProgressionPoint = 7;
						end)

					elseif mission.ProgressionPoint == 7 then
						Debugger:Log("ProgressionPoint 7");

						modStatusEffects.SetWalkspeed(player, nil);
						
						local movementCompleteSB = false;
						strangerAModule.Humanoid.Jump = true;
						task.wait(0.4);
						strangerAModule.Movement:Move(Vector3.new(19.219, 2.481, 128.767)):OnComplete(function()
							task.wait();
							strangerAModule.Actions:Teleport(CFrame.new(19.2189999, 2.48099995, 128.766998, 0.999998808, 3.78653475e-29, 1.69406246e-21, -5.04870949e-29, 0.999999404, 0, -2.54109662e-21, 0, 0.999998212));
							task.wait(1);
							strangerAModule.Movement:Move(Vector3.new(19.2190037, 2.54997015, 95.2484207))
						end)
						strangerAModule.AvatarFace:Set("Worried", game.Players:GetPlayers());
						task.wait(0.5);
						
						strangerBModule.Humanoid.Jump = true;
						task.wait(0.4);
						strangerBModule.Movement:Move(Vector3.new(13.944, 2.481, 128.767)):OnComplete(function()
							task.wait();
							strangerBModule.Actions:Teleport(CFrame.new(13.9440002, 2.48099995, 128.766998, 0.999998808, 3.15544813e-29, 2.11757894e-21, -4.41762348e-29, 0.999999404, 0, -2.9646135e-21, 0, 0.999998212));

							loranModule.Movement:Move(Vector3.new(17.107, 2.611, 82.917)):OnComplete(function()
								loranModule.Movement:Face(Vector3.new(17.35, 2.399, 154.063));
								loranModule.Chat(player, "In position!");
							end)
							
							task.wait(1);
							strangerBModule.Movement:Move(Vector3.new(13.9440041, 2.54997015, 95.2484207)):Wait();
							movementCompleteSB = true;
						end)
						strangerBModule.AvatarFace:Set("Skeptical", game.Players:GetPlayers());
						task.wait(0.5);
						
						strangerCModule.Humanoid.Jump = true;
						task.wait(0.4);
						strangerCModule.Movement:Move(Vector3.new(18.02, 2.481, 132.745)):OnComplete(function()
							task.wait();
							strangerCModule.Actions:Teleport(CFrame.new(18.0200005, 2.48099995, 132.744995, 0.999998808, 4.41762107e-29, 1.27054599e-21, -5.67979551e-29, 0.999999404, 0, -2.11757994e-21, 0, 0.999998212));
							task.wait(1);
							strangerCModule.Movement:Move(Vector3.new(18.0200062, 2.54997015, 99.2264175));
						end)
						strangerCModule.AvatarFace:Set("Skeptical", game.Players:GetPlayers());
						task.wait(0.5);
						
						banditA.Humanoid.Jump = true;
						banditB.Humanoid.Jump = true;
						
						banditA.Movement:Move(Vector3.new(-0.151, 2.481, 107.001)):OnComplete(function()
							task.wait();
							banditA.Actions:Teleport(CFrame.new(-0.150912821, 2.48087144, 107.000923, 8.07793567e-28, 0, -1, -6.01853108e-36, 1, 0, 1, -6.01853108e-36, -8.07793567e-28));
						end)
						
						banditB.Movement:Move(Vector3.new(30.185, 2.481, 107.001)):OnComplete(function()
							task.wait();
							banditB.Actions:Teleport(CFrame.new(30.1851215, 2.48087096, 107.000923, 0, 0, 1, 0, 1, 0, -1, 0, 0));
						end)
						
						repeat task.wait() until movementCompleteSB;
						Debugger:Log("wait for dist");
						
						modMission:Progress(player, 63, function(mission)
							mission.ProgressionPoint = 8;
						end)
						
					elseif mission.ProgressionPoint == 8 then
						zarkNpcModule.Interactable.Parent = script;

						local distFromC = math.huge;
						repeat
							distFromC = (classPlayer.RootPart.Position - strangerCModule.RootPart.Position).Magnitude
							Debugger:Log("distFromC", distFromC);
							task.wait(1);
						until distFromC <= 15;
						
						task.wait(4);
						
						zarkNpcModule.Chat(player, "Welcome, recruits!");
						task.wait(4);
						zarkNpcModule.Chat(player, "We bandits are like bears.. Where there are fishes in the streams, we will catch and bring them back to me. It is just the new natural cycle. Isn't that right, Loran?");
						task.wait(10);
						loranModule.Chat(player, "Yes, sir!");
						task.wait(4);
						zarkNpcModule.Chat(player, "It's kill or be killed. There is no them, there is only us!");
						task.wait(6);
						zarkNpcModule.Chat(player, "You will all have to prove your loyalty..");
						task.wait(6);
						

						zarkNpcModule.Movement:SetWalkSpeed("default", 8);
						zarkNpcModule.StopAnimation("leanonfencing");
						
						zarkNpcModule.Movement:Move(Vector3.new(52.525, 21.726, 34.061)):Wait();
						zarkNpcModule:TeleportHide();
						
						task.wait(4);
						zarkNpcModule.Actions:Teleport(CFrame.new(49.6023064, 2.58089828, 35.0045166, -1, 0, 0, 0, 1, 0, 0, 0, -1));
						task.wait();
						zarkNpcModule.Movement:Move(Vector3.new(16.093, 2.611, 78.89)):Wait();
						
						zarkNpcModule.Move:HeadTrack(loranModule.Head);
						zarkNpcModule.Chat(player, "Loran, take the other two back to the mall camp and give them their assignments. I'll handle the spy and our special guest myself.");
						task.wait(6);
						
						loranModule.Chat(player, "Yes, sir!");
						task.wait(4);
						
						zarkNpcModule.Move:HeadTrack(classPlayer.Head);
						
						loranModule.Movement:Move(Vector3.new(14.18, 0.7, 157.95)):OnComplete(function()
							game.Debris:AddItem(loranModule.Prefab, 0);
						end);
						
						strangerAModule.Movement:Move(Vector3.new(14.18, 0.7, 157.95)):OnComplete(function()
							game.Debris:AddItem(strangerAModule.Prefab, 0);
						end);
						
						strangerCModule.Movement:Move(Vector3.new(14.18, 0.7, 157.95)):OnComplete(function()
							game.Debris:AddItem(strangerCModule.Prefab, 0);
						end);
						
						
						modMission:Progress(player, 63, function(mission)
							mission.ProgressionPoint = 9;
						end)
						
					elseif mission.ProgressionPoint == 9 then
						zarkNpcModule.Interactable.Parent = zarkNpcModule.Prefab;
						
					elseif mission.ProgressionPoint == 10 then
						zarkNpcModule.Interactable.Parent = script;
						
						task.wait(8);
						zarkNpcModule.Move:HeadTrack(banditA.Head);
						zarkNpcModule.Movement:Face(Vector3.new(-0.151, 2.481, 107.001));
						zarkNpcModule.Chat(player, "You! Take that man to the lockers.");
						
						task.wait(0.5);
						banditA.Move:HeadTrack(zarkNpcModule.Head);
						banditA.Movement:Face(zarkNpcModule.Head.Position);
						
						task.wait(4);
						banditA.Chat(player, "Yes, sir.");
						
						task.wait(3);
						
						banditA.Move:HeadTrack(strangerBModule.Head);
						banditA.Movement:Move(Vector3.new(11.036, 2.601, 100.253)):OnComplete(function()
							banditA.Chat(player, "Get moving..");

							banditA.Movement:SetWalkSpeed("default", 8);
							strangerBModule.Movement:SetWalkSpeed("default", 8);

							task.wait(0.5);
							strangerBModule.Movement:Move(Vector3.new(-20.405, 2.581, 34.629)):OnComplete(function()
								task.wait(0.2);
								game.Debris:AddItem(strangerBModule.Prefab, 0);
							end)
							banditA.Movement:Move(Vector3.new(-20.405, 2.581, 34.629)):OnComplete(function()
								game.Debris:AddItem(banditA.Prefab, 0);
							end)
						end)
						banditB.Movement:Move(Vector3.new(18.046, 2.601, 100.079)):OnComplete(function()
							banditB.Movement:SetWalkSpeed("default", 8);
							task.wait(1.2);
							banditB.Movement:Move(Vector3.new(-20.405, 2.581, 34.629)):OnComplete(function()
								game.Debris:AddItem(banditB.Prefab, 0);
							end)
						end)
						
						task.spawn(function()
							for a=1, 40 do
								zarkNpcModule.Movement:Face(banditA.Head.Position);
								task.wait(0.1);
							end
						end)
						
						
						task.wait(4);
						zarkNpcModule.Move:HeadTrack();
						zarkNpcModule.Movement:Face(classPlayer.Head.Position);
						
						task.wait(0.5);
						zarkNpcModule.Chat(player, "Anyways..");

						modMission:Progress(player, 63, function(mission)
							mission.ProgressionPoint = 11;
						end)

					elseif mission.ProgressionPoint == 11 then
						zarkNpcModule.Interactable.Parent = zarkNpcModule.Prefab;
						
						task.spawn(function()
							while mission.ProgressionPoint == 11 do
								task.wait(0.1);
								zarkNpcModule.Movement:Face(classPlayer.Head.Position);
							end
						end)

					elseif mission.ProgressionPoint == 12 then
						zarkNpcModule.Interactable.Parent = script;
						
					end
				elseif mission.Type == 3 then -- OnComplete


				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true, mission);
		end)

		CutsceneSequence:NewScene("freezePlayer", function()
			local modCharacter = modData:GetModCharacter();

			--modCharacter.CharacterProperties.CanMove = false;
			--modCharacter.CharacterProperties.CanInteract = false;

			modConfigurations.Set("DisableMissions", false);
			modConfigurations.Set("DisableMajorNotifications", false);
			modConfigurations.Set("DisablePinnedMission", false);
			modConfigurations.Set("DisableDialogue", false);

			--modConfigurations.Set("DisableInventory", false);
			modData.ToggleChat();
		end)
		
	end;
	
	
	return CutsceneSequence;
end;