local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modNpcProfileLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary);

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modCharacterInteractions = require(game.ReplicatedStorage.Library.CharacterInteractions);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local envelopeInteractable = script:WaitForChild("envelopeInteractable");

local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
local remoteCameraShakeAndZoom = remotes:FindFirstChild("CameraShakeAndZoom");

local activeEnemies = {};
local enemiesSpawned = false;
--== Variables;
local missionId = 58;

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	modEvents = require(game.ServerScriptService.ServerLibrary.Events);
	modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);

	modOnGameEvents:ConnectEvent("OnTrigger", function(player, interactData)
		local triggerId = interactData.TriggerTag;

		if modMission:Progress(player, missionId) then
			if triggerId == "RevasEnvelope" then
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint < 7 then
						mission.ProgressionPoint = 7;
					end;
				end)

			elseif triggerId == "DoubleCrossHide" then
				Debugger:Warn("DoubleCrossHide");

				game.Debris:AddItem(interactData.Script, 0);
				shared.modAntiCheatService:Teleport(player, CFrame.new(-14.968, 2.044, -7.641));
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint < 11 then
						if mission.ProgressionPoint < 10 then
							local revasModule = modNpc.GetPlayerNpc(player, "Revas");
							if revasModule then
								revasModule.Chat(player, "Oh. You already know what to do.");
							end
						end
						mission.ProgressionPoint = 11;
					end
				end)

			elseif triggerId == "RescuePatrick" then

				local classPlayer = shared.modPlayers.Get(player);
				local patrickModule = modNpc.GetPlayerNpc(player, "Patrick");
				patrickModule.StopAnimation("injured2");

				patrickModule.Prefab.Head.CanCollide = true;
				patrickModule.Prefab.UpperTorso.CanCollide = true;
				patrickModule.Prefab.LowerTorso.CanCollide = true;
				patrickModule.RescueInteractable.Parent = nil;

				patrickModule.PlayAnimation("carriedinjured");
				modCharacterInteractions.Mount(player.Character, patrickModule.Prefab);

				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint < 16 then
						mission.ProgressionPoint = 16;
					end
				end)
			end
		end
	end);

	if modBranchConfigs.IsWorld("DoubleCross") then

		modOnGameEvents:ConnectEvent("OnToggle", function(player, interactData)
			local triggerId = interactData.TriggerTag;

			if triggerId == "DoubleCrossLever" then
				local mission = modMission:GetMission(player, missionId);
				if mission.ProgressionPoint == 14 then
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint == 14 then
							local stanChamber = workspace.Environment:WaitForChild("StansRejuvenation"):WaitForChild("RejuvenationChamber");


							task.wait(5);
							if mission.ProgressionPoint ~= 14 then return end;
							task.spawn(function()
								repeat
									task.wait()
								until stanChamber.Base.Position.Y <= -11;

								local basePos = stanChamber.Base.Position;
								game.Debris:AddItem(stanChamber.ChamberGlass, 0);
								for _, obj in pairs(stanChamber:GetDescendants()) do
									if obj:IsA("Motor6D") or obj:IsA("Weld") then
										game.Debris:AddItem(obj, 0);
									end
								end
								for _, obj in pairs(stanChamber:GetChildren()) do
									if obj:IsA("BasePart") and obj.Name ~= "Base" then
										local dir = (obj.Position-basePos).Unit;
										obj:ApplyImpulse(dir * 1000);
										obj:ApplyAngularImpulse(dir * 500);
									end
								end
							end)

							for a=1, 4 do
								game.Debris:AddItem(stanChamber.Base:FindFirstChild("Attachment"..a), 0);
							end

							modMission:Progress(player, missionId, function(mission)
								mission.ProgressionPoint = 15;

								modEvents:GetEvent(player, "mission58choice").ClosedGates = true;
							end)
						end
					end)
				end
			end

		end)

		modOnGameEvents:ConnectEvent("OnDismount", function(mountChar, passengerChar)
			Debugger:Log("OnDismount", mountChar, passengerChar);

			local player = game.Players:GetPlayerFromCharacter(mountChar);
			if player then

				local patrickModule = modNpc.GetPlayerNpc(player, "Patrick");
				patrickModule.StopAnimation("carriedinjured");
				patrickModule.PlayAnimation("injured2");
				patrickModule.Chat(player, "Arrgg.. Help..");
				patrickModule.RescueInteractable.Parent = patrickModule.Prefab;

			end
		end)

		for _, obj in pairs(workspace.Environment:GetChildren()) do
			if obj:IsA("Seat") and obj.Name == "DinghySeat" then
				local dinghySeat = obj;
				dinghySeat.Touched:Connect(function(hitPart)
					local player = game.Players:GetPlayerFromCharacter(hitPart.Parent);
					if player then
						Debugger:Log("Sat on Dinghy ", player);

						local classPlayer = shared.modPlayers.Get(player);
						dinghySeat:Sit(classPlayer.Humanoid);

						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint == 16 then
								mission.ProgressionPoint = 17;
								modServerManager:Travel(player, "Safehome");
							end
						end)
					end
				end)
			end
		end
	end
	
else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	local modInterface;

	if modBranchConfigs.IsWorld("TheHarbor") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then return end;

			local choiceEventObj = modEvents:GetEvent(player, "mission58choice") or modEvents:NewEvent(player, {Id="mission58choice";});

			local caitlinModule = modNpc.GetNpcModule(workspace.Entity:FindFirstChild("Caitlin"));
			local revasModule = modNpc.GetPlayerNpc(player, "Revas");
			if revasModule == nil then
				local npc = modNpc.Spawn("Revas", nil, function(npc, npcModule)
					npcModule.Owner = player;
					revasModule = npcModule;
				end);
				modReplicationManager.ReplicateOut(player, npc);

				revasModule:TeleportHide();
			end

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then

					elseif mission.ProgressionPoint == 2 then
						if caitlinModule then
							task.wait(0.3);
							caitlinModule.Prefab:SetAttribute("LookAtClient", false);
							caitlinModule.Wield.Equip("walkietalkie");
							task.wait(0.3);
							caitlinModule.Wield.PrimaryFireRequest(true);
							task.wait(1);
							caitlinModule.Chat(player, "...");
							task.wait(5);
							caitlinModule.Chat(player, "Mhm..");
							task.wait(5);
							caitlinModule.Chat(player, "Yes, sir");
							task.wait(3);
							caitlinModule.Wield.PrimaryFireRequest(false);
							caitlinModule.Prefab:SetAttribute("LookAtClient", nil);
						else
							Debugger:Log("Missing caitlin");
							task.wait(5);
						end
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint < 3 then
								mission.ProgressionPoint = 3;
							end;
						end)

					elseif mission.ProgressionPoint == 4 then
						local revasDoor = modReplicationManager.GetReplicated(player, "RevasDoorway")[1];

						local doorData = require(revasDoor.Door);
						doorData:SetAccess(player, true);

						revasModule.Interactable.Parent = script;
						revasModule.Actions:Teleport(CFrame.new(-275.068512, 105.362907, 292.467896, -0.999996185, 0, 0, 0, 1, 0, 0, 0, -0.999995351))
						revasModule.Actions:WaitForOwner(40);

						revasModule.Movement:SetWalkSpeed("default", 6);
						revasModule.Chat(player, "So you are the person I've been hearing so much about...");
						task.wait(1);
						revasModule.Movement:Move(Vector3.new(-282.269379, 105.362907, 283.569366));
						task.wait(4);
						revasModule.Chat(player, "What brings you to me?");
						revasModule.Actions:Teleport(CFrame.new(-282.269379, 105.362907, 283.569366, 0.990268052, 0, 0.139173105, 0, 1, 0, -0.139173105, 0, 0.990268052))
						revasModule.Actions:FaceOwner();
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint < 5 then
								mission.ProgressionPoint = 5;
							end;
						end)

					elseif mission.ProgressionPoint == 5 then
						revasModule.Interactable.Parent = revasModule.Prefab;
						revasModule.Actions:Teleport(CFrame.new(-282.269379, 105.362907, 283.569366, 0.990268052, 0, 0.139173105, 0, 1, 0, -0.139173105, 0, 0.990268052))
						revasModule.Actions:FaceOwner();

					elseif mission.ProgressionPoint == 6 then
						revasModule.Interactable.Parent = nil;
						revasModule.Actions:Teleport(CFrame.new(-282.269379, 105.362907, 283.569366, 0.990268052, 0, 0.139173105, 0, 1, 0, -0.139173105, 0, 0.990268052))
						revasModule.Actions:FaceOwner();

						task.wait(0.3);
						revasModule.Wield.Equip("envelope");
						task.wait(0.3);
						revasModule.Wield.PrimaryFireRequest(true);

						local newInteractable = envelopeInteractable:Clone();
						newInteractable.Name = "Interactable";
						newInteractable.Parent = revasModule.Wield.Instances[1];

					elseif mission.ProgressionPoint == 7 then
						revasModule.Chat(player, "Close the door on your way out, please.");

						revasModule.Actions:Teleport(CFrame.new(-282.269379, 105.362907, 283.569366, 0.990268052, 0, 0.139173105, 0, 1, 0, -0.139173105, 0, 0.990268052))
						revasModule.Actions:FaceOwner();
						revasModule.Wield.Unequip();

					elseif mission.ProgressionPoint >= 9 then
						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 8;
						end)
					end
				elseif mission.Type == 3 then -- OnComplete


				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true, mission);
		end)
		
		
	elseif modBranchConfigs.IsWorld("DoubleCross") then
		
		if modData then
			repeat
				modInterface = modData:GetInterfaceModule();
				Debugger:Warn("Waiting for interface..");
				if modInterface == nil then task.wait(); end
			until modInterface ~= nil;
		end

		local stanChamber = workspace.Environment:WaitForChild("StansRejuvenation"):WaitForChild("RejuvenationChamber");
		local chamberBodyGyro = stanChamber.Base.BodyGyro
		local chamberBodyPosition = stanChamber.Base.BodyPosition;

		local gateLever = workspace.Environment:WaitForChild("CargoShip"):WaitForChild("GateLever");
		local gateInteractData = require(gateLever:WaitForChild("Interactable"));

		for _, obj in pairs(gateLever.LeftGate:GetChildren()) do
			if obj:IsA("BasePart") then obj.CanCollide = false; end;
		end
		for _, obj in pairs(gateLever.RightGate:GetChildren()) do
			if obj:IsA("BasePart") then obj.CanCollide = false; end;
		end

		local tweenInfo = TweenInfo.new(12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut);

		local stanModel = workspace.Environment.StansRejuvenation.Stan;
		stanModel.Human.PlatformStand = true;

		local patrick = modNpcProfileLibrary:Find("Patrick");
		patrick.Class="Survivor";

		game.Lighting.ClockTime = 18.1;
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then return end;

			local revasModule;
			modNpc.Spawn("Revas", CFrame.new(-5.3425169, 2.63293743, -9.23565102, 0.939692616, 0, -0.342019618, 0, 1, 0, 0.342020214, 0, 0.939691067), function(npc, npcModule)
				npcModule.Owner = player;
				revasModule = npcModule;
			end);

			local zarkModule;
			modNpc.Spawn("Zark", CFrame.new(-8.77352238, 2.6205008, 90.7937851, 0, 0, 1, 0, 1, 0, -1, 0, 0), function(npc, npcModule)
				npcModule.Owner = player;
				zarkModule = npcModule;
			end);

			zarkModule:TeleportHide();

			local patrickModule;
			modNpc.Spawn("Patrick", CFrame.new(4.555336, 3, 91.5086823, 0.358367682, 0, -0.933580518, 0, 1, 0, 0.933580518, 0, 0.358367682), function(npc, npcModule)
				npcModule.Owner = player;
				patrickModule = npcModule;
			end, modNpc.NpcBaseModules.BasicNpcModule);

			patrickModule:TeleportHide();

			local eugeneModule;
			modNpc.Spawn("Eugene", nil, function(npc, npcModule)
				npcModule.Owner = player;
				eugeneModule = npcModule;
			end, modNpc.NpcBaseModules.CutsceneHuman);
			eugeneModule:TeleportHide();

			local stanModule;
			modNpc.Spawn("Stan", nil, function(npc, npcModule)
				npcModule.Owner = player;
				stanModule = npcModule;
			end, modNpc.NpcBaseModules.CutsceneHuman);
			stanModule:TeleportHide();
			stanModule.SetAnimation("Scream", script.Aggro:GetChildren());
			stanModule.SetAnimation("Attack", script.Attack:GetChildren());

			local playerProfile = shared.modProfile:Get(player);
			local classPlayer = shared.modPlayers.Get(player);

			local enemyLevel = 1;
			if playerProfile then
				local playerSave = playerProfile:GetActiveSave();
				local playerLevel = playerSave and playerSave:GetStat("Level") or 1;
				enemyLevel = modGlobalVars.GetLevelToFocus(playerLevel);
			end

			local function spawnEnemy(enemyName, spawnPoint)
				modNpc.Spawn(enemyName, spawnPoint, function(npc, npcModule)
					table.insert(activeEnemies, npcModule);
					npcModule.Configuration.Level = npcModule.Configuration.Level + enemyLevel + math.random(-1, 1);
					npcModule.Properties.AttackDamage = 3;
					npcModule.ForgetEnemies = false;
					npcModule.Properties.Hostile = true;
					npcModule.Properties.TargetableDistance = 4096;
					npcModule.Properties.WalkSpeed={Min=8; Max=16};
					npcModule.Wield.Targetable.Humanoid = 0.05;

					task.delay(1, function()
						npcModule.Properties.FeelsSafe = tick()+30000;
						npcModule.Wield.Equip(npcModule.Properties.WeaponId);
					end)

					if enemyName == "Bandit" then
						local weapons = {"ak47"};

						npcModule.Properties.WeaponId = weapons[math.random(1, #weapons)];
						npcModule.Speeches = {}

					elseif enemyName == "Rat" then
						local weapons = {"m4a4"};

						npcModule.Properties.WeaponId = weapons[math.random(1, #weapons)];
						npcModule.Speeches = {}
					end

					npcModule.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject;
					npcModule.Humanoid.Health = npcModule.Humanoid.MaxHealth;

					local isAlive = true;
					npcModule.Humanoid.Died:Connect(function()
						isAlive = false;
						npcModule.DeathPosition = npcModule.RootPart.CFrame.p;

						game.Debris:AddItem(npc, 10);
					end);
					task.spawn(function()
						npcModule.VisionDistance = 128;
						while not npcModule.IsDead do
							if npcModule.IsInVision(classPlayer.RootPart) then
								npcModule.OnTarget(player);
								break;
							end
							task.wait(math.random(10, 50)/100);
						end
					end);

					npcModule:AddComponent("ObjectScan");
				end);

			end

			local ratGoons = {};
			local banditGoons = {};

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint <= 8 then
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint < 9 then
								mission.ProgressionPoint = 9;
							end;
						end)

					elseif mission.ProgressionPoint == 9 then
						CutsceneSequence:NextScene("enableInterfaces");

					elseif mission.ProgressionPoint == 10 then
						CutsceneSequence:NextScene("enableInterfaces");
						revasModule.Movement:SetWalkSpeed("default", 6);
						revasModule.Movement:Move(Vector3.new(-4.593, 2.633, -20.375)):Wait();
						revasModule.Movement:Face(Vector3.new(-18.414, 2.727, -8.107));

					elseif mission.ProgressionPoint == 11 then
						revasModule.Chat(player, "Alright good.");
						task.wait(3);
						revasModule.Movement:Move(Vector3.new(-1.041, 1.807, -0.298)):Wait();
						revasModule.Chat(player, "*Pulls Lever*");
						gateInteractData:OnToggle();
						task.wait(1);
						revasModule.Movement:Move(Vector3.new(20.126, 1.013, -42.771)):OnComplete(function()
							revasModule:TeleportHide();
						end);
						task.wait(3);

						CutsceneSequence:NextScene("showBinds");
						task.wait(6);
						shared.Notify(player, '<b><font size="16" color="#634335">Bandit</font></b>: Control room looks clear.. *walkie talkie clicks*', "Message");
						task.wait(4);
						CutsceneSequence:NextScene("hideBinds");
						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 12;
						end)

					elseif mission.ProgressionPoint == 12 then
						revasModule.Actions:Teleport(CFrame.new(15.0913296, -10.0268202, 19.9245567, -0.48480919, 0, 0.874619484, 0, 1, 0, -0.874619484, 0, -0.48480919));
						revasModule.Movement:Move(Vector3.new(5.16559792, -10.0268202, 25.8680305));

						local ratSpawns = {
							CFrame.new(8.09436226, -10.0268202, 19.3195877, -0.601814806, 0, 0.798635602, 0, 1, 0, -0.798635602, 0, -0.601814866);
							CFrame.new(26.6262875, 2.63293743, 22.1311874, -0.559192896, 0, 0.829037607, 0, 1, 0, -0.829037607, 0, -0.559192896);
							CFrame.new(-29.2394066, 2.63293695, 22.1311836, -0.642787576, 0, -0.766044438, 0, 1, 0, 0.766044438, 0, -0.642787576);
						}

						for a=1, #ratSpawns do
							modNpc.Spawn("Rat", ratSpawns[a], function(npc, npcModule)
								npcModule.Prefab:SetAttribute("Cutscene", a);
								npcModule.Owner = player;
								table.insert(ratGoons, npcModule);

								npcModule:AddComponent(game.ServerScriptService.ServerLibrary.Entity.Npc.Rat.RandomSkin);
								npcModule.RandomSkin();
								npcModule.Movement:SetWalkSpeed("default", 8);
							end, modNpc.NpcBaseModules.CutsceneHuman);
						end

						local banditSpawns = {
							CFrame.new(-4.26995277, 2.63293743, 96.1551437, 1, 0, -3.27823898e-07, 0, 1, 0, 3.27823898e-07, 0, 1);
							CFrame.new(-9.1372118, -10.0268211, 79.6050186, 0.951056421, 0, -0.309016943, 0, 1, 0, 0.309017003, 0, 0.951056421);
							CFrame.new(-2.67881417, 2.62050056, 89.616272, 0.999999821, 0, 2.98023224e-08, 0, 1, 0, 2.98023224e-08, 0, 0.999999762);
						}

						for a=1, #banditSpawns do
							modNpc.Spawn("Bandit", banditSpawns[a], function(npc, npcModule)
								npcModule.Prefab:SetAttribute("Cutscene", a);
								npcModule.Owner = player;
								table.insert(banditGoons, npcModule);

								npcModule:AddComponent(game.ServerScriptService.ServerLibrary.Entity.Npc.Bandit.RandomSkin);
								npcModule.RandomSkin();
								npcModule.Movement:SetWalkSpeed("default", 8);
							end, modNpc.NpcBaseModules.CutsceneHuman);
						end

						zarkModule.Actions:Teleport(CFrame.new(-8.77352238, 2.6205008, 90.7937851, 0, 0, 1, 0, 1, 0, -1, 0, 0));
						patrickModule.Actions:Teleport(CFrame.new(4.555336, 2.63293743, 91.5086823, 0.358367682, 0, -0.933580518, 0, 1, 0, 0.933580518, 0, 0.358367682));

						CutsceneSequence:Pause(10);
						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 13;
						end)

					elseif mission.ProgressionPoint == 13 then
						shared.modAntiCheatService:Teleport(player, CFrame.new(-14.416, 2.633, -11.506));

						task.spawn(function()
							local f=500;
							while true do
								local distance = stanChamber.Base.Position.Y-(-11.5663881);
								local d = 1-(math.clamp(distance, 0, 10)/10);

								chamberBodyPosition.MaxForce = d*Vector3.new(f, f, f);
								chamberBodyGyro.MaxTorque = d*Vector3.new(f, f, f);

								task.wait(0.2);
							end
						end)

						stanChamber.Base.Anchored = true;

						local heliAnimationController = workspace.Environment.BanditHelicopterRig.AnimationController
						local animator = heliAnimationController:WaitForChild("Animator");

						local heliTrack = animator:LoadAnimation(script:WaitForChild("HeliDescentAnim"));
						heliTrack:Play(nil, nil, 0);

						local animator = stanChamber:WaitForChild("AnimationController"):WaitForChild("Animator");
						local chamberTrack = animator:LoadAnimation(script:WaitForChild("ChamberOpenAnim"));
						chamberTrack:Play(nil, nil, 0);

						zarkModule.Movement:SetWalkSpeed("default", 8);
						patrickModule.Move:SetMoveSpeed("set", "default", 8);
						eugeneModule.Movement:SetWalkSpeed("default", 8);

						task.wait(1);
						modAudio.Play("WoodDoorOpen", workspace.Environment.SoundPart);
						modAudio.Play("HeavyMetalDoor", workspace.Environment.SoundPart);
						playerProfile.Cache.LowTension = modAudio.Play("Soundtrack:LowTension", workspace)
						playerProfile.Cache.LowTension.Volume = 0.4;

						task.delay(3, function()
							zarkModule.Chat(player, "Well well well..");
							task.wait(2);
							if math.random(1, 2) == 1 then
								revasModule.Chat(player, "Oh? You’re approaching me?");
							end
							task.wait(2);
							zarkModule.Chat(player, "Revas, we finally meet. Hahah..");
						end)

						revasModule.Move:HeadTrack(zarkModule.Head);
						patrickModule.Move:HeadTrack(revasModule.Head);
						patrickModule.Move:MoveTo(Vector3.new(-0.717552722, -10.0268211, 35.5515823));
						task.spawn(function()
							patrickModule.Move.MoveToEnded:Wait(15);
							task.wait(0.1);
							patrickModule.Move:Face(revasModule.RootPart);
						end)
						task.spawn(function()
							banditGoons[1].Movement:Move(Vector3.new(-16.5431557, -10.0268211, 25.0535679)):Wait()
							banditGoons[1].Movement:Face(Vector3.new(8.09436226, -10.0268202, 19.3195877));
						end)
						zarkModule.Move:HeadTrack(revasModule.Head);
						zarkModule.Movement:Move(Vector3.new(-10.8155708, -10.0268202, 30.3059406)):Wait();
						zarkModule.Movement:Face(Vector3.new(5.16559792, -10.0268202, 25.8680305));

						task.wait(2);
						revasModule.Chat(player, "Zark..");

						task.wait(4);
						zarkModule.Chat(player, "You made the right choice agreeing to the offer.");
						task.wait(6);
						revasModule.Chat(player, "You made quite a compelling offer..");
						task.wait(6);
						zarkModule.Chat(player, "The payload should be here any minute now..");
						task.wait(2);

						task.delay(math.random(25, 100)/100, function()
							zarkModule.Movement:Face(Vector3.new(-0.704, 22.936, 55.041));
							zarkModule.Move:HeadTrack(stanChamber.Base);
						end)

						task.delay(math.random(25, 100)/100, function()
							patrickModule.Move:Face(Vector3.new(-0.704, 22.936, 55.041));
							patrickModule.Move:HeadTrack(stanChamber.Base);
						end)

						task.delay(math.random(25, 100)/100, function()
							revasModule.Movement:Face(Vector3.new(-0.704, 22.936, 55.041));
							revasModule.Move:HeadTrack(stanChamber.Base);
						end)

						stanChamber.Base.Anchored = false;
						local heliSound = modAudio.Play("HelicopterCore", heliAnimationController.Parent.Root);
						heliSound.Volume = 0;

						TweenService:Create(heliSound, TweenInfo.new(5), {
							Volume=1;
						}):Play();
						task.wait(1);

						TweenService:Create(heliTrack, tweenInfo, {
							TimePosition=9.99;
						}):Play();

						task.wait(8);

						task.delay(math.random(25, 100)/100, function()
							zarkModule.Movement:Face(revasModule.RootPart.Position);
							zarkModule.Move:HeadTrack(revasModule.Head);
						end)

						task.delay(math.random(25, 100)/100, function()
							patrickModule.Move:Face(revasModule.RootPart.Position);
							patrickModule.Move:HeadTrack(revasModule.Head);
						end)

						task.delay(math.random(25, 100)/100, function()
							revasModule.Movement:Face(zarkModule.RootPart.Position);
							revasModule.Move:HeadTrack(zarkModule.Head);
						end)


						zarkModule.Chat(player, "As promised.. An infector, in exchange for the location of Sector C..");
						task.wait(6);
						revasModule.Chat(player, "Is it alive?");
						task.wait(4);
						zarkModule.Chat(player, "Yes, it's just unconscious inside this rejuvenation chamber.");
						task.wait(6);
						revasModule.Chat(player, "Eugene, please verify the specimen for me.");
						eugeneModule.Actions:Teleport(CFrame.new(-5.34416199, -10.0268211, 2.89855337, -1, 0, 0, 0, 1, 0, 0, 0, -1));
						revasModule.Movement:Face(eugeneModule.RootPart.Position);
						revasModule.Move:HeadTrack(eugeneModule.Head);
						task.wait(3);
						task.delay(1, function()
							eugeneModule.Chat(player, "Yes, sir.");
						end)

						revasModule.Move:HeadTrack(eugeneModule.Head);
						zarkModule.Move:HeadTrack(eugeneModule.Head);
						patrickModule.Move:HeadTrack(eugeneModule.Head);

						task.delay(2.5, function()
							patrickModule.Move:MoveTo(Vector3.new(4.528, -10.027, 35.273));
						end)

						local eugeneWalk = true;
						eugeneModule.Movement:Move(stanChamber.Base.InteractPoint.WorldPosition):OnComplete(function()
							eugeneWalk = false;
						end)

						while eugeneWalk do
							revasModule.Movement:Face(eugeneModule.RootPart.Position);
							patrickModule.Move:Face(eugeneModule.RootPart.Position);
							zarkModule.Movement:Face(eugeneModule.RootPart.Position);

							task.wait(0.1);
						end

						eugeneModule.PlayAnimation("useterminal");
						task.wait(2);

						TweenService:Create(chamberTrack, TweenInfo.new(5), {
							TimePosition=4.99;
						}):Play();

						eugeneModule.Chat(player, "Hmm.. Vitals are stable, but it seems that the parasite has yet to take over the body?!");

						task.wait(6);
						eugeneModule.StopAnimation("useterminal");

						patrickModule.Move:MoveTo(Vector3.new(1.954, -10.027, 35.552));
						task.spawn(function()
							patrickModule.Move.MoveToEnded:Wait();
							task.wait(0.1);
							patrickModule.Move:Face(revasModule.RootPart);
						end)

						eugeneWalk = true;
						eugeneModule.Movement:Move(Vector3.new(12.714, -10.027, 31.405)):OnComplete(function()
							eugeneModule.Movement:Face(revasModule.RootPart.Position);
							revasModule.Movement:Face(eugeneModule.RootPart.Position);
							eugeneWalk = false;
						end)

						while eugeneWalk do
							revasModule.Movement:Face(eugeneModule.RootPart.Position);
							patrickModule.Move:Face(eugeneModule.RootPart);
							zarkModule.Movement:Face(eugeneModule.RootPart.Position);

							task.wait(0.1);
						end


						revasModule.Chat(player, "What do you mean doc?");
						task.wait(6);
						eugeneModule.Chat(player, "The parasite may still be incubating in the host.. We have no clue when it will complete.");
						eugeneModule.Move:HeadTrack(revasModule.Head);
						task.wait(6);
						revasModule.Chat(player, "Hmmm.. Is that so..");
						revasModule.Move:HeadTrack(patrickModule.Head);
						patrickModule.Move:HeadTrack(revasModule.Head);

						task.wait(4);

						revasModule.Move:HeadTrack(zarkModule.Head);
						revasModule.Chat(player, "Change of plans.");
						revasModule.Wield.Equip("revolver454");
						revasModule.Movement:Face(zarkModule.RootPart.Position);

						task.wait(1);
						eugeneModule.Movement:Face(zarkModule.RootPart.Position);

						task.delay(math.random(10, 60)/100,function()
							patrickModule.Wield.Equip("ak47");
							patrickModule.Move:Face(zarkModule.RootPart);
							patrickModule.Move:HeadTrack(zarkModule.Head);
						end)

						task.wait(0.5);
						zarkModule.Move:HeadTrack(patrickModule.Head);
						zarkModule.Wield.Equip("deagle")

						for a=1, #banditGoons do
							task.delay(math.random(45, 150)/100,function()
								banditGoons[a].Wield.Equip("ak47");
							end)
						end
						for a=1, #ratGoons do
							task.delay(math.random(45, 150)/100,function()
								ratGoons[a].Wield.Equip("m4a4");
							end)
						end


						eugeneModule.Move:HeadTrack();
						task.wait(2);
						zarkModule.Movement:Face(patrickModule.RootPart.Position);
						zarkModule.Chat(player, "Woah there.. Hah hah!");

						task.wait(6);
						zarkModule.Chat(player, "What is this?");

						task.wait(3);
						zarkModule.Chat(player, "A traitor in our midst?");

						task.wait(6);
						patrickModule.Chat(player, "I'm done with the Bandits..");


						task.wait(6);
						revasModule.Chat(player, "Here's the new deal. You hand over your military contacts, and I keep the infector in return for Sector C..");
						zarkModule.Movement:Face(revasModule.RootPart.Position);
						zarkModule.Move:HeadTrack(revasModule.Head);

						task.wait(6);
						zarkModule.Chat(player, "No deal, no dice..");

						task.wait(6);
						revasModule.Chat(player, "How about I sweeten the deal?");

						task.wait(2.5);
						revasModule.Movement:Face(patrickModule.RootPart.Position);
						task.wait(0.5);
						revasModule.Wield.SetEnemyHumanoid(patrickModule.Humanoid);
						revasModule.Wield.PrimaryFireRequest();

						patrickModule.Move:HeadTrack();
						patrickModule.PlayAnimation("injured2");
						patrickModule.AvatarFace:Set("Frustrated", player);
						patrickModule.Chat(player, "Arrgg.. Why..");
						patrickModule.Wield.Unequip();

						patrickModule.Prefab.Head.CanCollide = false;
						patrickModule.Prefab.UpperTorso.CanCollide = false;
						patrickModule.Prefab.LowerTorso.CanCollide = false;

						zarkModule.Movement:Face(patrickModule.RootPart.Position);
						zarkModule.Move:HeadTrack(patrickModule.Head);

						task.wait(1.5);
						revasModule.Movement:Face(zarkModule.RootPart.Position);

						task.wait(1.5);
						zarkModule.Movement:Face(revasModule.RootPart.Position);
						zarkModule.Move:HeadTrack(revasModule.Head);
						zarkModule.Chat(player, "Oooh, it's tempting but still no deal..");

						task.wait(3);
						zarkModule.Chat(player, "*whistles*");
						task.wait(1.5);
						zarkModule.Movement:SetWalkSpeed("default", 16);
						patrickModule.Move:SetMoveSpeed("set", "default", 0);
						eugeneModule.Movement:SetWalkSpeed("default", 16);

						zarkModule.Wield.Unequip();
						zarkModule.Chat(player, "Farewell Revas, we both know you are not going to shoot me.");
						zarkModule.Move:HeadTrack();


						heliTrack.TimePosition = 7.6;
						TweenService:Create(heliTrack, TweenInfo.new(25, Enum.EasingStyle.Linear), {
							TimePosition=0;
						}):Play();

						task.wait(1.3);
						eugeneModule.Chat(player, "Ahhh!!");
						eugeneModule.Movement:Move(Vector3.new(-25.928, -7.538, -12.168)):OnComplete(function() 
							eugeneModule:TeleportHide();
						end)

						gateInteractData.GateLocked = nil;
						gateInteractData:Sync();

						task.delay(1.2, function()
							zarkModule.Movement:Move(Vector3.new(-18.351, 1.88, 110.928)):OnComplete(function() 
								zarkModule:TeleportHide();
							end)

							local mainRatGoon = ratGoons[1];
							mainRatGoon.Movement:SetWalkSpeed("default", 16);
							mainRatGoon.Movement:Move(Vector3.new(-25.928, -7.538, -12.168)):OnComplete(function()
								mainRatGoon:TeleportHide();
							end)
							task.wait(0.2);

							ratGoons[2].Movement:SetWalkSpeed("default", 12);
							ratGoons[2].Movement:Move(Vector3.new(27.919, 1.028, 50.847)):OnComplete(function()
								ratGoons[2].Wield.SetEnemyHumanoid(banditGoons[3].Humanoid);
								local c = 0;
								while true do
									task.wait();
									task.spawn(function()
										if ratGoons[2] == nil then return end;
										if banditGoons[2] == nil or banditGoons[2].RootPart == nil then return end;
										ratGoons[2].Movement:Face(banditGoons[2].RootPart.Position);
										ratGoons[2].Wield.PrimaryFireRequest();
									end)
									c = c+1;
									if c == 6 then
										remoteCameraShakeAndZoom:FireClient(player, 8, 1, 10, 2, false);

										local destructibleExplosiveBarrel = require(workspace.Environment.Destructible.ExplosiveBarrel.Destructible);
										--destructibleExplosiveBarrel:TakeDamage(10000);
										destructibleExplosiveBarrel:TakeDamagePackage(modDamagable.NewDamageSource{
											Damage=10000;
										});

										banditGoons[2].Humanoid.Health = 0;

										task.delay(0.4, function()
											local s = modAudio.Play("TornadoWarning", workspace);
											s.Looped = true;
											local reverb = Instance.new("ReverbSoundEffect");
											reverb.Parent = s;

											local particles = workspace.Environment.FirePart:GetChildren();
											for a=1, #particles do
												if particles[a]:FindFirstChild("Fire") then
													particles[a].Fire.Enabled = true;
												elseif particles[a]:FindFirstChild("Smoke") then
													particles[a].Smoke.Enabled = true;
												end
											end

											local alertLights = workspace.Environment.AlertLights:GetChildren();
											for a=1, #alertLights do
												local modAlertLight = require(alertLights[a].AlertLight);
												modAlertLight:Toggle(true);
											end

											if playerProfile.Cache.LowTension then
												playerProfile.Cache.LowTension.PlaybackSpeed = 2;
											end
										end)
									end

									if stanModule.AttackMode then
										break;
									end
								end

								ratGoons[2].Wield.ReloadRequest()
								task.wait(1);
								ratGoons[2].Wield.SetEnemyHumanoid(stanModule.Humanoid);
								while not ratGoons[2].IsDead do
									task.wait();
									ratGoons[2].Movement:Face(stanModule.RootPart.Position);
									ratGoons[2].Wield.PrimaryFireRequest();
								end
							end)
							banditGoons[2].Movement:SetWalkSpeed("default", 12);
							banditGoons[2].Movement:Move(Vector3.new(-9.1372118, -10.0268211, 77.6050186)):OnComplete(function()
								banditGoons[2].Wield.SetEnemyHumanoid(ratGoons[2].Humanoid);
								while true do
									task.wait();
									banditGoons[2].Movement:Face(ratGoons[2].RootPart.Position);
									banditGoons[2].Wield.PrimaryFireRequest();

									if stanModule.AttackMode then
										break;
									end
								end

								banditGoons[2].Wield.SetEnemyHumanoid(stanModule.Humanoid);
								while not banditGoons[2].IsDead do
									task.wait();
									banditGoons[2].Movement:Face(stanModule.RootPart.Position);
									banditGoons[2].Wield.PrimaryFireRequest();
								end
							end)

							task.spawn(function()
								ratGoons[3].Wield.SetEnemyHumanoid(banditGoons[3].Humanoid);
								while true do
									task.wait();
									ratGoons[3].Movement:Face(banditGoons[3].RootPart.Position);
									ratGoons[3].Wield.PrimaryFireRequest();

									if stanModule.AttackMode then
										break;
									end
								end
							end)
							task.spawn(function()
								banditGoons[3].Wield.SetEnemyHumanoid(ratGoons[3].Humanoid);
								while true do
									task.wait();
									banditGoons[3].Movement:Face(ratGoons[3].RootPart.Position);
									banditGoons[3].Wield.PrimaryFireRequest();

									if stanModule.AttackMode then
										break;
									end
								end

								banditGoons[3].Wield.ReloadRequest()
								task.wait(2);
								banditGoons[3].Wield.SetEnemyHumanoid(stanModule.Humanoid);
								while not banditGoons[3].IsDead do
									task.wait();
									banditGoons[3].Movement:Face(stanModule.RootPart.Position);
									banditGoons[3].Wield.PrimaryFireRequest();
								end
							end)

							local mainBanditGoon = banditGoons[1];
							mainBanditGoon.Movement:SetWalkSpeed("default", 12);
							mainBanditGoon.Wield.SetEnemyHumanoid(mainRatGoon.Humanoid);
							repeat
								task.wait();
								mainBanditGoon.Movement:Face(mainRatGoon.RootPart.Position);
								mainBanditGoon.Wield.PrimaryFireRequest();
							until stanModule.AttackMode;

							mainBanditGoon.Movement:Move(Vector3.new(-18.351, 1.88, 110.928)):OnComplete(function() 
								mainBanditGoon:TeleportHide();
							end)
						end)

						revasModule.Chat(player, "Pull the lever now!");
						revasModule.Movement:Face(Vector3.new(-1.268, 6.636, 5.186));

						local classPlayer = shared.modPlayers.Get(player);
						local playerHead = classPlayer.Head;

						revasModule.Move:HeadTrack(playerHead);
						task.delay(2, function()
							revasModule.Move:HeadTrack(playerHead);
							revasModule.Prefab:SetAttribute("LookAtClient", false);
						end)
						task.delay(4, function()
							revasModule.Movement:SetWalkSpeed("default", 16);
							revasModule.Movement:Move(Vector3.new(-25.928, -7.538, -12.168)):OnComplete(function()
								revasModule:TeleportHide();
							end)
						end)

						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 14;
						end)

					elseif mission.ProgressionPoint == 14 then
						repeat
							task.wait();
							if mission.ProgressionPoint ~= 14 then
								break;
							end
						until stanChamber.Base.Position.Y >= 11;

						if mission.ProgressionPoint == 14 then
							modMission:Progress(player, missionId, function(mission)
								mission.ProgressionPoint = 15;

								modEvents:GetEvent(player, "mission58choice").ClosedGates = false;
							end)
						end

					elseif mission.ProgressionPoint == 15 then

						local missionChoice = modEvents:GetEvent(player, "mission58choice");

						local closedGates = missionChoice.ClosedGates == true;

						if closedGates then
							missionChoice.Rats = true;
						else
							missionChoice.Bandits = true;
						end

						Debugger:Warn("missionChoice", missionChoice);

						patrickModule.Prefab:SetAttribute("LookAtClient", false);
						patrickModule.Humanoid.PlatformStand = false;

						local interactPoint = Instance.new("Attachment");
						interactPoint.Name = "InteractPoint";
						interactPoint.Parent = patrickModule.RootPart;
						interactPoint.Position = Vector3.new(2.108, -0.03, 0.001);

						if closedGates then -- Helped Rats
							local fakeStanModel = workspace.Environment:WaitForChild("StansRejuvenation"):WaitForChild("Stan");

							task.wait(3);
							stanModule.Actions:Teleport(fakeStanModel.PrimaryPart.CFrame);
							stanModule.Interactable.Parent = script;
							stanModule.Movement:Face(Vector3.new(-1.322, -0.012, 0.781));

							game.Debris:AddItem(fakeStanModel, 0);
							stanModule.AvatarFace:Set("Infector");
							stanModule.PlayAnimation("Scream");

							local s = modAudio.Play("ZombieGroan", workspace);
							s.Volume = 1;
							local reverb = Instance.new("ReverbSoundEffect");
							reverb.Parent = s;

							stanModule.Movement:SetWalkSpeed("default", 30);

							task.spawn(function()
								local targetGoon = banditGoons[1];

								local function hunt(playScream)
									repeat
										stanModule.AttackMode = true;
										stanModule.Movement:Move(targetGoon.RootPart.Position);
										if (stanModule.RootPart.Position-targetGoon.RootPart.Position).Magnitude <= 6 then
											stanModule.PlayAnimation("Attack");
											modAudio.Play("Slice", workspace).PlaybackSpeed = 0.5;
											modAudio.Play("Punch", workspace).PlaybackSpeed = 0.7;
											task.wait(0.2);
											targetGoon.Humanoid.Health = 0;
											modAudio.Play("HumanDeath", workspace);
											task.wait(0.4);

											if playScream then
												stanModule.PlayAnimation("Scream");
												modAudio.Play("ZombieGroan", workspace);
												task.wait(0.4);
											end
											task.wait(0.4);
										end
										task.wait();
									until targetGoon.IsDead == true;
								end
								hunt(true);

								targetGoon = banditGoons[3];
								hunt(false);

								targetGoon = ratGoons[2];
								hunt(true);

								task.wait(2);
								stanModule.Movement:Move(Vector3.new(-18.351, 1.88, 110.928)):OnComplete(function() 
									stanModule:TeleportHide();
								end)
							end)

							local lastDamaged = tick();
							stanModule.Garbage:Tag(stanModule.Humanoid.HealthChanged:Connect(function()
								stanModule.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn; lastDamaged = tick();
								delay(2, function()
									if tick()-lastDamaged > 2 and stanModule.Humanoid then
										stanModule.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
									end;
								end);

								task.wait();
								local hurtSound = modAudio.Play("ZombieHurt", stanModule.RootPart);
								hurtSound.Volume = math.random(50, 60)/100;
								hurtSound.PlaybackSpeed = math.random(110, 120)/100;
							end));

							ratGoons[3].Movement:SetWalkSpeed("default", 12);
							ratGoons[3].Movement:Move(Vector3.new(-31.179, 5.066, -11.033)):OnComplete(function()
								ratGoons[3]:TeleportHide();
							end)
							for a=1, #banditGoons do
								banditGoons[a].Immortal = nil;
							end

						else -- Helped Bandits;
							for a=1, #ratGoons do
								ratGoons[a].Immortal = nil;
							end
							stanModule.AttackMode = true;

							ratGoons[2].Movement:SetWalkSpeed("default", 12);
							ratGoons[2].Movement:Move(Vector3.new(28.452, 5.066, -11)):OnComplete(function()
								ratGoons[2]:TeleportHide();
							end)

							ratGoons[3].Movement:SetWalkSpeed("default", 12);
							ratGoons[3].Movement:Move(Vector3.new(-31.179, 5.066, -11.033)):OnComplete(function()
								ratGoons[3]:TeleportHide();
							end)

							banditGoons[3].Movement:SetWalkSpeed("default", 12);
							banditGoons[3].Movement:Move(Vector3.new(-18.351, 1.88, 110.928)):OnComplete(function()
								banditGoons[3]:TeleportHide();
							end)

						end

						task.spawn(function()
							local clientEffect = game.ServerScriptService.ServerLibrary.Entity.Npc["Bandit Pilot"].HelicopterEffect:Clone();

							local prefabTag = clientEffect:WaitForChild("Prefab");
							prefabTag.Value = workspace.Environment.BanditHelicopterRig;

							clientEffect.Parent = player.Character;
						end)


						patrickModule.Interactable.Parent = script;

						if patrickModule.RescueInteractable == nil then
							local new = script:WaitForChild("rescuePatrickInteractable"):Clone();
							new.Name = "Interactable";
							new.Parent = patrickModule.Prefab;
							patrickModule.RescueInteractable = new;
						end

						task.delay(5, function()
							local shipDoors = workspace.Environment.CargoShip.ShipDoors:GetChildren();
							for a=1, #shipDoors do
								if shipDoors[a]:GetAttribute("DoubleCross") == "A" then
									local doorObj = require(shipDoors[a].Door);
									doorObj:Toggle(true);
								end
							end
						end)

						task.spawn(function()
							local heliAnimationController = workspace.Environment.BanditHelicopterRig.AnimationController
							local animator = heliAnimationController:WaitForChild("Animator");

							local heliLeavesAnimTrack = animator:LoadAnimation(script:WaitForChild("HeliLeavesAnim"));
							heliLeavesAnimTrack:Play(nil, nil, 0);

							local playerCf;
							repeat
								task.wait(0.2);
								playerCf = classPlayer:GetCFrame();
							until playerCf.Y >= 12.5 and playerCf.Z >= 33;

							Debugger:Log("Helicopter leaves");

							TweenService:Create(heliLeavesAnimTrack, TweenInfo.new(10, Enum.EasingStyle.Linear), {
								TimePosition=9.98;
							}):Play();
							task.wait(3);

							for ct=18.2, 18.6, 0.008 do
								game.Lighting.ClockTime =ct;
								task.wait(0.1);
							end
						end)

						for _, obj in pairs(gateLever.LeftGate:GetChildren()) do
							if obj:IsA("BasePart") then obj.CanCollide = true; end;
						end
						for _, obj in pairs(gateLever.RightGate:GetChildren()) do
							if obj:IsA("BasePart") then obj.CanCollide = true; end;
						end

						local enemySpawns = game.ServerStorage.EnemySpawns:GetChildren()
						for a=1, #enemySpawns do
							local spawnPart = enemySpawns[a];
							local spawnCf = spawnPart.CFrame;

							if spawnPart.Name == "SpawnA" then
								task.spawn(function()
									if mission.ProgressionPoint < 15 then return; end

									spawnEnemy(closedGates and "Bandit" or "Rat", spawnCf);
								end)
							end
						end
						CutsceneSequence:NextScene("endCutscene");


					elseif mission.ProgressionPoint == 16 then

						local eventObj = modEvents:GetEvent(player, "mission58choice");
						local closedGates = eventObj.ClosedGates == true;

						local shipDoors = workspace.Environment.CargoShip.ShipDoors:GetChildren();
						for a=1, #shipDoors do
							if shipDoors[a]:GetAttribute("DoubleCross") == "B" then
								local doorObj = require(shipDoors[a].Door);
								doorObj:Toggle(true);
							end
						end

						local enemySpawns = game.ServerStorage.EnemySpawns:GetChildren()
						for a=1, #enemySpawns do
							local spawnPart = enemySpawns[a];
							local spawnCf = spawnPart.CFrame;

							if spawnPart.Name == "SpawnB" then
								task.spawn(function()
									if mission.ProgressionPoint < 15 then return; end

									spawnEnemy(closedGates and "Bandit" or "Rat", spawnCf);
								end)
							end
						end

					elseif mission.ProgressionPoint == 17 then
						CutsceneSequence:NextScene("escapeCargoShip");
					end
				elseif mission.Type == 3 then -- OnComplete


				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true);
		end)

		CutsceneSequence:NewScene("enableInterfaces", function()
			modConfigurations.Set("DisablePinnedMission", false);
			modConfigurations.Set("DisableDialogue", false);
			modConfigurations.Set("DisableInventory", false);
			modData.ToggleChat();
		end);

		CutsceneSequence:NewScene("showBinds", function()
			modInterface:ToggleGameBlinds(false, 5);
			modData.ToggleChat();
		end);
		CutsceneSequence:NewScene("hideBinds", function()
			modInterface:ToggleGameBlinds(true, 1);
			modData.ToggleChat();
		end);

		CutsceneSequence:NewScene("endCutscene", function()
			modConfigurations.Set("DisableHotbar", false);
			modConfigurations.Set("DisableWeaponInterface", false);
			modConfigurations.Set("DisableInventory", false);
			modConfigurations.Set("DisableHealthbar", false);
			modConfigurations.Set("DisableMissions", false);
			modConfigurations.Set("DisablePinnedMission", false);
			modConfigurations.Set("DisableWorkbench", false);
			modConfigurations.Set("DisableReportMenu", false);
			modConfigurations.Set("DisableMasteryMenu", false);
			modConfigurations.Set("DisableExperiencebar", false);
			modConfigurations.Set("DisableGeneralStats", false);
			modConfigurations.Set("CanQuickEquip", true);
			modConfigurations.Set("DisableInventoryHotkey", false);
			modConfigurations.Set("DisableSquadInterface", false);
			modConfigurations.Set("DisableMajorNotifications", false);
			modConfigurations.Set("DisableDialogue", false);
			modConfigurations.Set("DisableWaypointers", false);
			modConfigurations.Set("DisableSocialMenu", false);
			modConfigurations.Set("DisableEmotes", false);
			modConfigurations.Set("DisableSettingsMenu", false);
			modConfigurations.Set("DisableInfoBubbles", false);
			modConfigurations.Set("DisableMapMenu", false);
			modConfigurations.Set("DisableGoldMenu", false);
			modConfigurations.Set("DisableStatusHud", false);
			modConfigurations.Set("NotificationViewPos", 1);
			modConfigurations.Set("DisableSafehomeMenu", true);
			modConfigurations.Set("AllowFreecam", true);
			modData.ToggleChat();
		end);

		CutsceneSequence:NewScene("escapeCargoShip", function()
			modInterface:ToggleGameBlinds(false, 3);
		end)
		

	elseif modBranchConfigs.IsWorld("Safehome") then

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then return end;

			local npcSpawns = workspace:FindFirstChild("Spawns");
			repeat
				npcSpawns = workspace:FindFirstChild("Spawns");
				Debugger:Log("Waiting for (workspace.Spawns).")
				task.wait(0.1);
			until npcSpawns ~= nil;

			local cp = shared.modSafehomeService.GetNpcSpot("Patrick");

			local classPlayer = shared.modPlayers.Get(player);
			local patrickModule;
			local function OnChanged(firstRun)
				local spawnPatrick = 0;

				if mission.Type == 1 then -- Active
					if mission.ProgressionPoint > 16 then
						spawnPatrick = 1;
					elseif mission.ProgressionPoint == 7 or mission.ProgressionPoint == 8 then
						spawnPatrick = 1;
					end

				elseif mission.Type == 2 then -- Available 
					if mission.ProgressionPoint <= 1 then
						spawnPatrick = 1;
					end

				elseif mission.Type == 3 then -- OnComplete
					spawnPatrick = 2;

					if patrickModule then
						patrickModule.Move:MoveTo(cp.WorldPosition);
						task.spawn(function()
							task.wait(0.1);
							patrickModule.Move:Face(patrickModule.RootPart.Position + cp.WorldCFrame.LookVector);
						end)

					end
				end

				if spawnPatrick > 0 then
					patrickModule = modNpc.GetPlayerNpc(player, "Patrick");

					if patrickModule == nil then
						local npc = modNpc.Spawn("Patrick", spawnPatrick == 2 and cp.WorldCFrame or classPlayer:GetCFrame(), function(npc, npcModule)
							npcModule.Owner = player;
							patrickModule = npcModule;

							function npcModule.Initialize()
								npcModule:AddComponent("ObjectScan");
								npcModule:AddComponent("SafehomeSurvivor");
								coroutine.yield();
							end
						end, modNpc.NpcBaseModules.CutsceneHuman);
						modReplicationManager.ReplicateOut(player, npc);
					end
				end
			end

			mission.Changed:Connect(OnChanged);
			OnChanged(true);
		end)
		
	end
	
	return CutsceneSequence;
end;