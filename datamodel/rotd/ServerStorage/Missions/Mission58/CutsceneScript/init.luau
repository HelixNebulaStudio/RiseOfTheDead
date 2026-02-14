local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modNpcProfileLibrary = shared.require(game.ReplicatedStorage.Library.NpcProfileLibrary);

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modCharacterInteractions = shared.require(game.ReplicatedStorage.Library.CharacterInteractions);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local activeEnemies = {};
local enemiesSpawned = false;

local MISSION_ID = 58;
--== Variables;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
	modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
	modSafehomeService = shared.require(game.ServerScriptService.ServerLibrary.SafehomeService);

	if modBranchConfigurations.IsWorld("TheHarbor") then
		shared.modEventService:OnInvoked("Interactables_BindButtonInteract", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;
			if interactable == nil then return end;

			if interactable.Id == "mission58_TakeEnvelope" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint < 7 then
						mission.ProgressionPoint = 7;
					end;
				end)

			end
		end)

	elseif modBranchConfigurations.IsWorld("DoubleCross") then

		shared.modEventService:OnInvoked("Character_BindDismount", function(eventPacket: EventPacket, ...)
			local packet = ...;
			local mountChar = packet.MountCharacter;
			local passengerChar = packet.PassengerCharacter;
			local mountStyle = packet.MountStyle;

			local player = game.Players:GetPlayerFromCharacter(mountChar);
			if player == nil then return end;

			local patrickNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Patrick");
			if patrickNpcClass == nil then return end;

			patrickNpcClass.StopAnimation("carriedinjured");
			patrickNpcClass.PlayAnimation("injured2");
			patrickNpcClass.Chat(player, "Arrgg.. Help..");

			if patrickNpcClass.Properties.CarryInteractable == nil then
				local newInteractable = modInteractables.createInteractable("Button");
				newInteractable:SetAttribute("_Id", "mission58_RescuePatrick");
				newInteractable:SetAttribute("_Label", "Carry Patrick");
				newInteractable:SetAttribute("_Animation", "pickupcharacter");
				newInteractable:SetAttribute("_InteractDuration", 2.95);

				patrickNpcClass.Properties.CarryInteractable = newInteractable;
				newInteractable.Parent = patrickNpcClass.Character;
			end
		end)
		
		shared.modEventService:OnInvoked("Interactables_BindButtonInteract", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;
			if interactable == nil then return end;

			task.spawn(function()
				local playerClass: PlayerClass = shared.modPlayers.get(player);
				if playerClass == nil then return end;

				if interactable.Id == "mission58_GatesLever" then
					local mission = modMission:GetMission(player, MISSION_ID);
					if mission.ProgressionPoint == 14 then
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint == 14 then
								local stanModel = workspace.Environment.StansRejuvenation.Stan;
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
										if obj:IsA("Motor6D") or obj:IsA("Weld") and not stanModel:IsAncestorOf(obj) then
											game.Debris:AddItem(obj, 0);
										end
									end
									for _, obj in pairs(stanChamber:GetChildren()) do
										if obj:IsA("BasePart") and obj.Name ~= "Base" and not stanModel:IsAncestorOf(obj) then
											local dir = (obj.Position-basePos).Unit;
											obj:ApplyImpulse(dir * 1000);
											obj:ApplyAngularImpulse(dir * 500);
										end
									end
								end)

								for a=1, 4 do
									game.Debris:AddItem(stanChamber.Base:FindFirstChild(`Attachment{a}`), 0);
								end

								modMission:Progress(player, MISSION_ID, function(mission)
									mission.ProgressionPoint = 15;
									modEvents:GetEvent(player, "mission58choice").ClosedGates = true;
								end)
							end
						end)
					end

				elseif interactable.Id == "mission58_DoubleCrossHide" then
					Debugger:Warn("DoubleCrossHide");

					game.Debris:AddItem(interactable.Config, 0);
					playerClass:SetCFrame(CFrame.new(-14.968, 2.044, -7.641));

					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint < 11 then
							if mission.ProgressionPoint < 10 then
								local revasNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Revas");
								if revasNpcClass then
									revasNpcClass.Chat(player, "Oh. You already know what to do.");
								end

							end
							mission.ProgressionPoint = 11;
						end
					end)

				elseif interactable.Id == "mission58_RescuePatrick" then
					local patrickNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Patrick");
					patrickNpcClass.StopAnimation("injured2");

					patrickNpcClass.Head.CanCollide = true;

					local patrickChar = patrickNpcClass.Character;
					patrickChar.UpperTorso.CanCollide = true;
					patrickChar.LowerTorso.CanCollide = true;

					if patrickNpcClass.Properties.CarryInteractable then
						patrickNpcClass.Properties.CarryInteractable:Destroy();
						patrickNpcClass.Properties.CarryInteractable = nil;
					end

					patrickNpcClass:ToggleInteractable(false);

					patrickNpcClass.PlayAnimation("carriedinjured");
					modCharacterInteractions.Mount(player.Character, patrickNpcClass.Character);

					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint < 16 then
							mission.ProgressionPoint = 16;
						end
					end)

				end
			end)
		end)

		for _, obj in pairs(workspace.Environment:GetChildren()) do
			if obj:IsA("Seat") and obj.Name == "DinghySeat" then
				local dinghySeat = obj;
				dinghySeat.Touched:Connect(function(hitPart)
					local player = game.Players:GetPlayerFromCharacter(hitPart.Parent);
					if player then
						Debugger:Log("Sat on Dinghy ", player);

						local classPlayer = shared.modPlayers.get(player);
						dinghySeat:Sit(classPlayer.Humanoid);

						modMission:Progress(player, MISSION_ID, function(mission)
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
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	local function initEventPackge(player)
		local choiceEventObj = modEvents:GetEvent(player, "mission58choice");
		if choiceEventObj == nil then
			choiceEventObj = modEvents:NewEvent(player, {Id="mission58choice";});
		end
	end

	--MARK: TheHarbor
	if modBranchConfigurations.IsWorld("TheHarbor") then

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;

			initEventPackge(player);
			local choiceEventObj = modEvents:GetEvent(player, "mission58choice");
			local caitlinNpcClass: NpcClass = modNpcs.getByModel(workspace.Entity:FindFirstChild("Caitlin"));

			local revasNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Revas");
			if revasNpcClass == nil then
				revasNpcClass = shared.modNpcs.spawn2{
					Name = "Revas";
					Player = player;
					ReplicateOut = true;
				};
				revasNpcClass:TeleportHide();
			end

			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then

					elseif mission.ProgressionPoint == 2 then
						if caitlinNpcClass then

							caitlinNpcClass.Chat(player, "Is that so.. I'll pass the information up the chain, if he wants to talk to you, he will let you know.");
							task.wait(8);

							caitlinNpcClass.Character:SetAttribute("LookAtClient", false);
							caitlinNpcClass.WieldComp:Equip{
								ItemId = "walkietalkie";
							};
							task.wait(0.3);

							caitlinNpcClass.WieldComp:InvokeToolAction("PrimaryUse", true);
							task.wait(1);

							caitlinNpcClass.Chat(player, "...");
							task.wait(5);

							caitlinNpcClass.Chat(player, "Mhm..");
							task.wait(5);

							caitlinNpcClass.Chat(player, "Yes, sir");
							task.wait(5);

							caitlinNpcClass.WieldComp:InvokeToolAction("PrimaryUse", false);
							caitlinNpcClass.Character:SetAttribute("LookAtClient", nil);

							caitlinNpcClass.Chat(player, "Looks like it's your lucky day..");

						else
							Debugger:Log("Missing caitlin");
							task.wait(5);

						end
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint < 3 then
								mission.ProgressionPoint = 3;
							end;
						end)


					elseif mission.ProgressionPoint == 4 then
						local revasDoor = modReplicationManager.getReplicated(player, "RevasDoorway")[1];

						local doorInteractConfig = revasDoor:FindFirstChild("Interactable");
						local doorInteractable: InteractableInstance = modInteractables.getOrNew(doorInteractConfig);
						doorInteractable:SetUserPermissions(player.Name, "CanInteract", true);

						revasNpcClass:ToggleInteractable(false);
						
						revasNpcClass:SetCFrame(CFrame.new(-275.068512, 105.362907, 292.467896, -0.999996185, 0, 0, 0, 1, 0, 0, 0, -0.999995351))
						
						local waitForPlayerComp = revasNpcClass:GetComponent("WaitForPlayer");
						waitForPlayerComp(40);

						revasNpcClass.Move:SetMoveSpeed("set", "default", 6);
						revasNpcClass.Chat(player, "So you are the person I've been hearing so much about...");
						task.wait(1);
						revasNpcClass.Move:MoveTo(Vector3.new(-282.269379, 105.362907, 283.569366));
						task.wait(4);
						revasNpcClass.Chat(player, "What brings you to me?");
						revasNpcClass:SetCFrame(CFrame.new(-282.269379, 105.362907, 283.569366, 0.990268052, 0, 0.139173105, 0, 1, 0, -0.139173105, 0, 0.990268052))
						revasNpcClass.Move:Face("Player");
						
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint < 5 then
								mission.ProgressionPoint = 5;
							end;
						end)

					elseif mission.ProgressionPoint == 5 then
						
						revasNpcClass:ToggleInteractable(true);
						revasNpcClass:SetCFrame(CFrame.new(-282.269379, 105.362907, 283.569366, 0.990268052, 0, 0.139173105, 0, 1, 0, -0.139173105, 0, 0.990268052))
						revasNpcClass.Move:Face("Player");

					elseif mission.ProgressionPoint == 6 then
						
						revasNpcClass:ToggleInteractable(false);
						revasNpcClass:SetCFrame(CFrame.new(-282.269379, 105.362907, 283.569366, 0.990268052, 0, 0.139173105, 0, 1, 0, -0.139173105, 0, 0.990268052))
						revasNpcClass.Move:Face("Player");

						task.wait(0.3);
						revasNpcClass.WieldComp:Equip{
							ItemId = "envelope";
						};
						task.wait(0.3);
						revasNpcClass.WieldComp:InvokeToolAction("PrimaryUse", true);

						local newInteractable = modInteractables.createInteractable("Button");
						newInteractable:SetAttribute("_Label", "Take Envelope");
						newInteractable:SetAttribute("_Id", "mission58_TakeEnvelope");
						if revasNpcClass.WieldComp.ToolHandler then
							newInteractable.Parent = revasNpcClass.WieldComp.ToolHandler.MainToolModel.PrimaryPart;
						else
							newInteractable.Parent = revasNpcClass.Character;
						end

					elseif mission.ProgressionPoint == 7 then
						revasNpcClass.Chat(player, "Close the door on your way out, please.");

						revasNpcClass:SetCFrame(CFrame.new(-282.269379, 105.362907, 283.569366, 0.990268052, 0, 0.139173105, 0, 1, 0, -0.139173105, 0, 0.990268052));
						revasNpcClass.Move:Face("Player");
						revasNpcClass.WieldComp:Unequip();

					elseif mission.ProgressionPoint >= 9 then
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 8;
						end)

					end
				elseif mission.Type == 3 then -- OnComplete


				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);

		end)
		
		
	--MARK: DoubleCross
	elseif modBranchConfigurations.IsWorld("DoubleCross") then
		
		local stanChamber = workspace.Environment:WaitForChild("StansRejuvenation"):WaitForChild("RejuvenationChamber");
		local chamberBodyGyro = stanChamber.Base.BodyGyro
		local chamberBodyPosition = stanChamber.Base.BodyPosition;

		local gateLever = workspace.Environment:WaitForChild("CargoShip"):WaitForChild("GateLever");
		local gateInteractConfig = gateLever:WaitForChild("Interactable");
		local gateInteractable: InteractableInstance = modInteractables.getOrNew(gateInteractConfig);

		gateInteractable:SetPermissions("CanInteract", false);
		
		for _, obj in pairs(gateLever.LeftGate:GetChildren()) do
			if obj:IsA("BasePart") then obj.CanCollide = false; end;
		end
		for _, obj in pairs(gateLever.RightGate:GetChildren()) do
			if obj:IsA("BasePart") then obj.CanCollide = false; end;
		end

		local tweenInfo = TweenInfo.new(12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut);

		local stanModel = workspace.Environment.StansRejuvenation.Stan;
		stanModel.FakeHuman.PlatformStand = true;

		local patrick = modNpcProfileLibrary:Find("Patrick");
		patrick.Class="Survivor";

		game.Lighting.ClockTime = 18.1;
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;

			initEventPackge(player);

			local revasNpcClass: NpcClass = modNpcs.spawn2{
				Name = "Revas";
				Player = player;
				CFrame = CFrame.new(-5.3425169, 2.63293743, -9.23565102, 0.939692616, 0, -0.342019618, 0, 1, 0, 0.342020214, 0, 0.939691067);
			};

			local zarkNpcClass: NpcClass = modNpcs.spawn2{
				Name = "Zark";
				Player = player;
				CFrame = CFrame.new(-8.77352238, 2.6205008, 90.7937851, 0, 0, 1, 0, 1, 0, -1, 0, 0);
			};
			zarkNpcClass:TeleportHide();

			local patrickNpcClass: NpcClass = modNpcs.spawn2{
				Name = "Patrick";
				Player = player;
				CFrame = CFrame.new(4.555336, 3, 91.5086823, 0.358367682, 0, -0.933580518, 0, 1, 0, 0.933580518, 0, 0.358367682);
			};
			patrickNpcClass:TeleportHide();

			local eugeneNpcClass: NpcClass = modNpcs.spawn2{
				Name = "Eugene";
				Player = player;
			};
			eugeneNpcClass:TeleportHide();

			local stanNpcClass: NpcClass = modNpcs.spawn2{
				Name = "Stan";
				Player = player;
			};
			stanNpcClass:TeleportHide();
			stanNpcClass.SetAnimation("Scream", script.Aggro:GetChildren());
			stanNpcClass.SetAnimation("Attack", script.Attack:GetChildren());

			local profile: ProfileRotd = shared.modProfile:Get(player) :: ProfileRotd;
			local playerClass: PlayerClass = shared.modPlayers.get(player);

			local enemyLevel = 1;
			if profile then
				local gameSave: GameSaveRotd = profile:GetActiveSave() :: GameSaveRotd;
				local playerLevel = gameSave and gameSave:GetStat("Level") or 1;
				enemyLevel = modGlobalVars.GetLevelToFocus(playerLevel);
			end

			local function spawnEnemy(enemyName, spawnPoint)
				modNpcs.spawn2{
					Name = enemyName;
					CFrame = spawnPoint;
					BindSetup = function(npcClass: NpcClass)
						table.insert(activeEnemies, npcClass);

						local properties = npcClass.Properties;
						properties.Level = properties.Level + enemyLevel + math.random(-1,1);
						properties.IsHostile = true;
						properties.TargetableDistance = 4096;

						local configurations = npcClass.Configurations;
						local cutsceneModifier = configurations.newModifier("CutsceneModifier");
						cutsceneModifier.SetValues = {
							AttackDamage = 3;
						};
						configurations:AddModifier(cutsceneModifier);

						npcClass.HealthComp.OnIsDeadChanged:Connect(function()
							if not npcClass.HealthComp.IsDead then return end;
						end)
					end
				};

			end

			local shipDoors = workspace.Environment.CargoShip.ShipDoors:GetChildren();
			for a=1, #shipDoors do
				local doorInteractConfig = shipDoors[a]:FindFirstChild("Interactable");
				local doorInteractable = modInteractables.getOrNew(doorInteractConfig);
				doorInteractable:SetPermissions("CanInteract", false);
			end

			local ratGoons = {};
			local banditGoons = {};

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint <= 8 then
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint < 9 then
								mission.ProgressionPoint = 9;
							end;
						end)

					elseif mission.ProgressionPoint == 9 then
						CutsceneSequence:NextScene("enableInterfaces");

					elseif mission.ProgressionPoint == 10 then
						CutsceneSequence:NextScene("enableInterfaces");

						revasNpcClass:ToggleInteractable(false);
						revasNpcClass.Move:SetMoveSpeed("set", "default", 6);
						revasNpcClass.Move:MoveTo(Vector3.new(-4.593, 2.633, -20.375));
						revasNpcClass.Move.OnMoveToEnded:Wait(10);
						revasNpcClass.Move:Face(Vector3.new(-18.414, 2.727, -8.107));

					elseif mission.ProgressionPoint == 11 then
						revasNpcClass.Chat(player, "Alright good.");
						task.wait(3);

						revasNpcClass.Move:MoveTo(Vector3.new(-1.041, 1.807, -0.298));
						revasNpcClass.Move.OnMoveToEnded:Wait(5);
						revasNpcClass.Chat(player, "*Pulls Lever*");

						revasNpcClass:UseInteractable(gateInteractConfig);
						task.wait(1);

						revasNpcClass.Move:MoveTo(Vector3.new(20.126, 1.013, -42.771));

						revasNpcClass.Move.OnMoveToEnded:Once(function()
							revasNpcClass:TeleportHide();
						end)
						task.wait(3);

						CutsceneSequence:NextScene("showBinds");
						task.wait(6);
						
						shared.Notify(player, '<b><font size="16" color="#634335">Bandit</font></b>: Control room looks clear.. *walkie talkie clicks*', "Message");
						task.wait(4);
						
						CutsceneSequence:NextScene("hideBinds");
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 12;
						end)

					elseif mission.ProgressionPoint == 12 then
						revasNpcClass:SetCFrame(CFrame.new(15.0913296, -10.0268202, 19.9245567, -0.48480919, 0, 0.874619484, 0, 1, 0, -0.874619484, 0, -0.48480919));
						revasNpcClass.Move:MoveTo(Vector3.new(5.16559792, -10.0268202, 25.8680305));

						local ratSpawns = {
							CFrame.new(8.09436226, -10.0268202, 19.3195877, -0.601814806, 0, 0.798635602, 0, 1, 0, -0.798635602, 0, -0.601814866);
							CFrame.new(26.6262875, 2.63293743, 22.1311874, -0.559192896, 0, 0.829037607, 0, 1, 0, -0.829037607, 0, -0.559192896);
							CFrame.new(-29.2394066, 2.63293695, 22.1311836, -0.642787576, 0, -0.766044438, 0, 1, 0, 0.766044438, 0, -0.642787576);
						}

						for a=1, #ratSpawns do
							local ratNpcClass: NpcClass = modNpcs.spawn2{
								Name = "Rat";
								CFrame = ratSpawns[a];
								Player = player;

								BindSetup = function(npcClass: NpcClass)
									npcClass.Character:SetAttribute("Cutscene", a);

									local properties = npcClass.Properties;
									properties.CutsceneActive = true;

									npcClass:GetComponent("AttractNpcs").IsActive = false;

									table.insert(ratGoons, npcClass);
									npcClass.Move:SetMoveSpeed("set", "default", 8);
								end
							};
						end

						local banditSpawns = {
							CFrame.new(-4.26995277, 2.63293743, 96.1551437, 1, 0, -3.27823898e-07, 0, 1, 0, 3.27823898e-07, 0, 1);
							CFrame.new(-9.1372118, -10.0268211, 79.6050186, 0.951056421, 0, -0.309016943, 0, 1, 0, 0.309017003, 0, 0.951056421);
							CFrame.new(-2.67881417, 2.62050056, 89.616272, 0.999999821, 0, 2.98023224e-08, 0, 1, 0, 2.98023224e-08, 0, 0.999999762);
						}

						for a=1, #banditSpawns do
							local banditNpcClass: NpcClass = modNpcs.spawn2{
								Name = "Bandit";
								CFrame = banditSpawns[a];
								Player = player;

								BindSetup = function(npcClass: NpcClass)
									npcClass.Character:SetAttribute("Cutscene", a);

									local properties = npcClass.Properties;
									properties.CutsceneActive = true;

									npcClass:GetComponent("AttractNpcs").IsActive = false;

									table.insert(banditGoons, npcClass);

									npcClass.Move:SetMoveSpeed("set", "default", 8);
								end
							};
						end

						zarkNpcClass:SetCFrame(CFrame.new(-8.77352238, 2.6205008, 90.7937851, 0, 0, 1, 0, 1, 0, -1, 0, 0));
						patrickNpcClass:SetCFrame(CFrame.new(4.555336, 2.63293743, 91.5086823, 0.358367682, 0, -0.933580518, 0, 1, 0, 0.933580518, 0, 0.358367682));

						CutsceneSequence:Pause(10);
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 13;
						end)

					elseif mission.ProgressionPoint == 13 then
						playerClass:SetCFrame(CFrame.new(-14.416, 2.633, -11.506));

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
						local heliAnimator = heliAnimationController:WaitForChild("Animator");

						local heliTrack = heliAnimator:LoadAnimation(script:WaitForChild("HeliDescentAnim"));
						heliTrack:Play(nil, nil, 0);

						local chamberAnimator = stanChamber:WaitForChild("AnimationController"):WaitForChild("Animator");
						local chamberTrack = chamberAnimator:LoadAnimation(script:WaitForChild("ChamberOpenAnim"));
						chamberTrack:Play(nil, nil, 0);

						zarkNpcClass.Move:SetMoveSpeed("set", "default", 8);
						patrickNpcClass.Move:SetMoveSpeed("set", "default", 8);
						eugeneNpcClass.Move:SetMoveSpeed("set", "default", 8);
						task.wait(1);

						modAudio.Play("WoodDoorOpen", workspace.Environment.SoundPart);
						modAudio.Play("HeavyMetalDoor", workspace.Environment.SoundPart);
						profile.Cache.LowTension = modAudio.Play("Soundtrack:LowTension", workspace)
						profile.Cache.LowTension.Volume = 0.4;

						task.delay(3, function()
							zarkNpcClass.Chat(player, "Well well well..");
							task.wait(2);
							if math.random(1, 2) == 1 then
								revasNpcClass.Chat(player, "Oh? You’re approaching me?");
							end
							task.wait(2);
							zarkNpcClass.Chat(player, "Revas, we finally meet. Hahah..");
						end)

						revasNpcClass.Move:HeadTrack(zarkNpcClass.Head);
						patrickNpcClass.Move:HeadTrack(revasNpcClass.Head);
						patrickNpcClass.Move:MoveTo(Vector3.new(-0.717552722, -10.0268211, 35.5515823));
						task.spawn(function()
							patrickNpcClass.Move.OnMoveToEnded:Wait(15);
							task.wait(0.1);
							patrickNpcClass.Move:Face(revasNpcClass.RootPart);
						end)
						task.spawn(function()
							banditGoons[1].Move:MoveTo(Vector3.new(-16.5431557, -10.0268211, 25.0535679))
							banditGoons[1].Move.OnMoveToEnded:Wait(10);
							banditGoons[1].Move:Face(Vector3.new(8.09436226, -10.0268202, 19.3195877));
						end)
						zarkNpcClass.Move:HeadTrack(revasNpcClass.Head);
						zarkNpcClass.Move:MoveTo(Vector3.new(-10.8155708, -10.0268202, 30.3059406))
						zarkNpcClass.Move.OnMoveToEnded:Wait(10);
						zarkNpcClass.Move:Face(Vector3.new(5.16559792, -10.0268202, 25.8680305));

						task.wait(2);
						revasNpcClass.Chat(player, "Zark..");

						task.wait(4);
						zarkNpcClass.Chat(player, "You made the right choice agreeing to the offer.");
						task.wait(6);
						revasNpcClass.Chat(player, "You made quite a compelling offer..");
						task.wait(6);
						zarkNpcClass.Chat(player, "The payload should be here any minute now..");
						task.wait(2);

						task.delay(math.random(25, 100)/100, function()
							zarkNpcClass.Move:Face(Vector3.new(-0.704, 22.936, 55.041));
							zarkNpcClass.Move:HeadTrack(stanChamber.Base);
						end)

						task.delay(math.random(25, 100)/100, function()
							patrickNpcClass.Move:Face(Vector3.new(-0.704, 22.936, 55.041));
							patrickNpcClass.Move:HeadTrack(stanChamber.Base);
						end)

						task.delay(math.random(25, 100)/100, function()
							revasNpcClass.Move:Face(Vector3.new(-0.704, 22.936, 55.041));
							revasNpcClass.Move:HeadTrack(stanChamber.Base);
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
							zarkNpcClass.Move:Face(revasNpcClass.RootPart.Position);
							zarkNpcClass.Move:HeadTrack(revasNpcClass.Head);
						end)

						task.delay(math.random(25, 100)/100, function()
							patrickNpcClass.Move:Face(revasNpcClass.RootPart.Position);
							patrickNpcClass.Move:HeadTrack(revasNpcClass.Head);
						end)

						task.delay(math.random(25, 100)/100, function()
							revasNpcClass.Move:Face(zarkNpcClass.RootPart.Position);
							revasNpcClass.Move:HeadTrack(zarkNpcClass.Head);
						end)


						zarkNpcClass.Chat(player, "As promised.. An infector, in exchange for the location of Sector C..");
						task.wait(6);
						revasNpcClass.Chat(player, "Is it alive?");
						task.wait(4);
						zarkNpcClass.Chat(player, "Yes, it's just unconscious inside this rejuvenation chamber.");
						task.wait(6);
						revasNpcClass.Chat(player, "Eugene, please verify the specimen for me.");
						eugeneNpcClass:SetCFrame(CFrame.new(-5.34416199, -10.0268211, 2.89855337, -1, 0, 0, 0, 1, 0, 0, 0, -1));
						revasNpcClass.Move:Face(eugeneNpcClass.RootPart.Position);
						revasNpcClass.Move:HeadTrack(eugeneNpcClass.Head);
						task.wait(3);
						task.delay(1, function()
							eugeneNpcClass.Chat(player, "Yes, sir.");
						end)

						revasNpcClass.Move:HeadTrack(eugeneNpcClass.Head);
						zarkNpcClass.Move:HeadTrack(eugeneNpcClass.Head);
						patrickNpcClass.Move:HeadTrack(eugeneNpcClass.Head);

						task.delay(2.5, function()
							patrickNpcClass.Move:MoveTo(Vector3.new(4.528, -10.027, 35.273));
						end)

						local eugeneWalk = true;
						eugeneNpcClass.Move:MoveTo(stanChamber.Base.PathToInteract.WorldPosition);
						eugeneNpcClass.Move.OnMoveToEnded:Once(function()
							eugeneWalk = false;
						end)

						while eugeneWalk do
							revasNpcClass.Move:Face(eugeneNpcClass.RootPart.Position);
							patrickNpcClass.Move:Face(eugeneNpcClass.RootPart.Position);
							zarkNpcClass.Move:Face(eugeneNpcClass.RootPart.Position);

							task.wait(0.1);
						end

						eugeneNpcClass.PlayAnimation("useterminal");
						task.wait(2);

						TweenService:Create(chamberTrack, TweenInfo.new(5), {
							TimePosition=4.99;
						}):Play();

						eugeneNpcClass.Chat(player, "Hmm.. Vitals are stable, but..");
						task.wait(6);

						eugeneNpcClass.Chat(player, "It seems that the parasite has yet to take over the body?!");
						task.wait(6);

						eugeneNpcClass.StopAnimation("useterminal");

						patrickNpcClass.Move:MoveTo(Vector3.new(1.954, -10.027, 35.552));
						task.spawn(function()
							patrickNpcClass.Move.OnMoveToEnded:Wait();
							task.wait(0.1);
							patrickNpcClass.Move:Face(revasNpcClass.RootPart);
						end)

						eugeneWalk = true;
						eugeneNpcClass.Move:MoveTo(Vector3.new(12.714, -10.027, 31.405));
						eugeneNpcClass.Move.OnMoveToEnded:Once(function()
							eugeneNpcClass.Move:Face(revasNpcClass.RootPart.Position);
							revasNpcClass.Move:Face(eugeneNpcClass.RootPart.Position);
							eugeneWalk = false;
						end)

						while eugeneWalk do
							revasNpcClass.Move:Face(eugeneNpcClass.RootPart.Position);
							patrickNpcClass.Move:Face(eugeneNpcClass.RootPart);
							zarkNpcClass.Move:Face(eugeneNpcClass.RootPart.Position);

							task.wait(0.1);
						end


						revasNpcClass.Chat(player, "What do you mean doc?");
						task.wait(6);
						eugeneNpcClass.Chat(player, "The parasite may still be incubating in the host..");
						eugeneNpcClass.Move:HeadTrack(revasNpcClass.Head);
						task.wait(6);
						eugeneNpcClass.Chat(player, "We have no clue when it will complete.");
						task.wait(8);

						revasNpcClass.Chat(player, "Hmmm.. Is that so..");
						revasNpcClass.Move:HeadTrack(patrickNpcClass.Head);
						patrickNpcClass.Move:HeadTrack(revasNpcClass.Head);

						task.wait(6);

						revasNpcClass.Move:HeadTrack(zarkNpcClass.Head);
						revasNpcClass.Chat(player, "Change of plans.");
						revasNpcClass.WieldComp:Equip{
							ItemId = "revolver454";
						}
						revasNpcClass.Move:Face(zarkNpcClass.RootPart.Position);

						task.wait(1);
						eugeneNpcClass.Move:Face(zarkNpcClass.RootPart.Position);

						task.delay(math.random(10, 60)/100,function()
							patrickNpcClass.WieldComp:Equip{
								ItemId = "ak47";
							};
							patrickNpcClass.Move:Face(zarkNpcClass.RootPart);
							patrickNpcClass.Move:HeadTrack(zarkNpcClass.Head);
						end)

						task.wait(0.5);
						zarkNpcClass.Move:HeadTrack(patrickNpcClass.Head);
						zarkNpcClass.WieldComp:Equip{
							ItemId = "deagle";
						};

						for a=1, #banditGoons do
							task.delay(math.random(45, 150)/100,function()
								banditGoons[a].WieldComp:Equip{
									ItemId = "ak47";
								};
							end)
						end
						for a=1, #ratGoons do
							task.delay(math.random(45, 150)/100,function()
								ratGoons[a].WieldComp:Equip{
									ItemId = "m4a4";
								}
							end)
						end


						eugeneNpcClass.Move:HeadTrack();
						task.wait(2);

						zarkNpcClass.Move:Face(patrickNpcClass.RootPart.Position);
						zarkNpcClass.Chat(player, "Woah there.. Hah hah!");
						task.wait(6);

						zarkNpcClass.Chat(player, "What is this?");
						task.wait(6);

						zarkNpcClass.Chat(player, "A traitor in our midst?");
						task.wait(6);

						patrickNpcClass.Chat(player, "I'm done with the Bandits..");
						task.wait(6);

						revasNpcClass.Chat(player, "Here's the new deal.");
						task.wait(6);

						revasNpcClass.Chat(player, "You hand over your military contacts, and I keep the infector in return for Sector C..");
						task.wait(1);

						zarkNpcClass.Move:Face(revasNpcClass.RootPart.Position);
						zarkNpcClass.Move:HeadTrack(revasNpcClass.Head);
						task.wait(9);

						zarkNpcClass.Chat(player, "No deal, no dice..");
						task.wait(6);

						revasNpcClass.Chat(player, "How about I sweeten the deal?");
						task.wait(2.5);
						revasNpcClass.Move:Face(patrickNpcClass.RootPart.Position);
						task.wait(0.5);

						revasNpcClass.WieldComp:InvokeToolAction("PrimaryFireRequest", nil, patrickNpcClass.Humanoid)

						patrickNpcClass.Move:HeadTrack();
						patrickNpcClass.PlayAnimation("injured2");
						patrickNpcClass:GetComponent("AvatarFace"):Set("Frustrated", player);
						patrickNpcClass.Chat(player, "Arrgg.. Why..");
						patrickNpcClass.WieldComp:Unequip();

						patrickNpcClass.Head.CanCollide = false;

						local patrickChar = patrickNpcClass.Character;
						patrickChar.UpperTorso.CanCollide = false;
						patrickChar.LowerTorso.CanCollide = false;

						zarkNpcClass.Move:Face(patrickNpcClass.RootPart.Position);
						zarkNpcClass.Move:HeadTrack(patrickNpcClass.Head);

						task.wait(1.5);
						revasNpcClass.Move:Face(zarkNpcClass.RootPart.Position);

						task.wait(1.5);
						zarkNpcClass.Move:Face(revasNpcClass.RootPart.Position);
						zarkNpcClass.Move:HeadTrack(revasNpcClass.Head);

						zarkNpcClass.Chat(player, "Oooh, it's tempting but still no deal..");
						task.wait(6);
						
						zarkNpcClass.Chat(player, "*whistles*");
						task.wait(1.5);

						zarkNpcClass.Move:SetMoveSpeed("set", "default", 16);
						patrickNpcClass.Move:SetMoveSpeed("set", "default", 0);
						eugeneNpcClass.Move:SetMoveSpeed("set", "default", 16);

						zarkNpcClass.WieldComp:Unequip();
						zarkNpcClass.Chat(player, "Farewell Revas, we both know you are not going to shoot me.");
						zarkNpcClass.Move:HeadTrack();


						heliTrack.TimePosition = 7.6;
						TweenService:Create(heliTrack, TweenInfo.new(25, Enum.EasingStyle.Linear), {
							TimePosition=0;
						}):Play();

						task.wait(1.3);
						eugeneNpcClass.Chat(player, "Ahhh!!");
						eugeneNpcClass.Move:MoveTo(Vector3.new(-25.928, -10.738, -7.868));
						eugeneNpcClass.Move.OnMoveToEnded:Once(function() 
							eugeneNpcClass:TeleportHide();
						end)

						gateInteractable:SetPermissions("CanInteract", true);

						task.delay(1.2, function()
							zarkNpcClass.Move:MoveTo(Vector3.new(-18.351, 1.88, 110.928));
							zarkNpcClass.Move.OnMoveToEnded:Once(function() 
								zarkNpcClass:TeleportHide();
							end)

							local mainRatGoon: NpcClass = ratGoons[1];
							mainRatGoon.Move:SetMoveSpeed("set", "default", 16);
							mainRatGoon.Move:MoveTo(Vector3.new(-25.928, -10.738, -7.868));
							mainRatGoon.Move.OnMoveToEnded:Once(function()
								mainRatGoon:TeleportHide();
							end)
							task.wait(0.2);

							ratGoons[2].Move:SetMoveSpeed("set", "default", 12);
							ratGoons[2].Move:MoveTo(Vector3.new(27.919, 1.028, 50.847));
							ratGoons[2].Move.OnMoveToEnded:Once(function()
								ratGoons[2].Move:Face(banditGoons[3]:GetCFrame().Position);

								local c = 0;
								while true do
									task.wait();
									task.spawn(function()
										if ratGoons[2].HealthComp.IsDead then return end;
										if banditGoons[2].HealthComp.IsDead then return end;
										ratGoons[2].Move:Face(banditGoons[3]:GetCFrame().Position);
										ratGoons[2].WieldComp:InvokeToolAction("PrimaryFireRequest", nil, banditGoons[3].Humanoid);
									end)
									c = c+1;
									if c == 6 then
										shared.modPlayers.cameraShakeAndZoom(player, 8, 1, 10, 2, false);

										local explosiveBarrel = workspace.Environment.Destructible.ExplosiveBarrel;
										local explosiveBarrelHealthComp: HealthComp? = modHealthComponent.getByModel(explosiveBarrel);
										
										if explosiveBarrelHealthComp then
											explosiveBarrelHealthComp:TakeDamage(DamageData.new{
												Damage=10000;
											});
										end

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
												local modAlertLight = shared.require(alertLights[a].AlertLight);
												modAlertLight:Toggle(true);
											end

											if profile.Cache.LowTension then
												profile.Cache.LowTension.PlaybackSpeed = 2;
											end
										end)
									end

									if stanNpcClass.Properties.AttackMode then
										break;
									end
								end

								ratGoons[2].WieldComp:InvokeToolAction("ReloadRequest");
								task.wait(1);
								while not ratGoons[2].HealthComp.IsDead do
									ratGoons[2].Move:Face(stanNpcClass.RootPart.Position);
									ratGoons[2].WieldComp:InvokeToolAction("PrimaryFireRequest", nil, stanNpcClass.Humanoid);
									task.wait();
								end
							end)

							banditGoons[2].Move:SetMoveSpeed("set", "default", 12);
							banditGoons[2].Move:MoveTo(Vector3.new(-9.1372118, -10.0268211, 77.6050186));
							banditGoons[2].Move.OnMoveToEnded:Once(function()
								while true do
									banditGoons[2].Move:Face(ratGoons[2].RootPart.Position);
									banditGoons[2].WieldComp:InvokeToolAction("PrimaryFireRequest", nil, ratGoons[2].Humanoid);

									if stanNpcClass.Properties.AttackMode then
										break;
									end
									task.wait();
								end

								while not banditGoons[2].HealthComp.IsDead do
									banditGoons[2].Move:Face(stanNpcClass.RootPart.Position);
									banditGoons[2].WieldComp:InvokeToolAction("PrimaryFireRequest", nil, stanNpcClass.Humanoid);
									task.wait();
								end
							end)

							task.spawn(function()
								while not ratGoons[3].HealthComp.IsDead do
									ratGoons[3].Move:Face(banditGoons[3].RootPart.Position);
									ratGoons[3].WieldComp:InvokeToolAction("PrimaryFireRequest", nil, banditGoons[3].Humanoid);

									if stanNpcClass.Properties.AttackMode then
										break;
									end
									task.wait();
								end
							end)
							task.spawn(function()
								while not banditGoons[3].HealthComp.IsDead do
									banditGoons[3].Move:Face(ratGoons[3].RootPart.Position);
									banditGoons[3].WieldComp:InvokeToolAction("PrimaryFireRequest", nil, ratGoons[3].Humanoid);

									if stanNpcClass.Properties.AttackMode then
										break;
									end
									task.wait();
								end

								banditGoons[3].WieldComp:InvokeToolAction("ReloadRequest");
								task.wait(2);
								while not banditGoons[3].HealthComp.IsDead do
									banditGoons[3].Move:Face(stanNpcClass.RootPart.Position);
									banditGoons[3].WieldComp:InvokeToolAction("PrimaryFireRequest", nil, stanNpcClass.Humanoid);
									task.wait();
								end
							end)

							local mainBanditGoon: NpcClass = banditGoons[1];
							mainBanditGoon.Move:SetMoveSpeed("set", "default", 12);
							repeat
								task.wait();
								mainBanditGoon.Move:Face(mainRatGoon.RootPart.Position);
								mainBanditGoon.WieldComp:InvokeToolAction("PrimaryFireRequest", nil, mainRatGoon.Humanoid);
							until stanNpcClass.Properties.AttackMode;

							mainBanditGoon.Move:MoveTo(Vector3.new(-18.351, 1.88, 110.928));
							mainBanditGoon.Move.OnMoveToEnded:Once(function() 
								mainBanditGoon:TeleportHide();
							end)
						end)

						revasNpcClass.Chat(player, "Pull the lever now!");
						revasNpcClass.Move:Face(Vector3.new(-1.268, 6.636, 5.186));

						local playerHead = playerClass.Head;

						revasNpcClass.Move:HeadTrack(playerHead);
						task.delay(2, function()
							revasNpcClass.Move:HeadTrack(playerHead);
							revasNpcClass.Character:SetAttribute("LookAtClient", false);
						end)
						task.delay(4, function()
							revasNpcClass.Move:SetMoveSpeed("set", "default", 16);
							revasNpcClass.Move:MoveTo(Vector3.new(-25.928, -10.738, -7.868));
							revasNpcClass.Move.OnMoveToEnded:Once(function()
								revasNpcClass:TeleportHide();
							end)
						end)

						modMission:Progress(player, MISSION_ID, function(mission)
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
							modMission:Progress(player, MISSION_ID, function(mission)
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

						patrickNpcClass.Character:SetAttribute("LookAtClient", false);
						patrickNpcClass.Humanoid.PlatformStand = false;

						local pathToInteract = Instance.new("Attachment");
						pathToInteract.Name = "PathToInteract";
						pathToInteract.Parent = patrickNpcClass.RootPart;
						pathToInteract.Position = Vector3.new(2.108, -0.03, 0.001);

						if closedGates then -- Helped Rats
							local fakeStanModel = workspace.Environment:WaitForChild("StansRejuvenation"):WaitForChild("Stan");

							task.wait(3);
							stanNpcClass:SetCFrame(fakeStanModel:GetPivot());
							stanNpcClass:ToggleInteractable(false);
							stanNpcClass.Move:Face(Vector3.new(-1.322, -0.012, 0.781));

							game.Debris:AddItem(fakeStanModel, 0);
							stanNpcClass:GetComponent("AvatarFace"):Set("Infector");
							stanNpcClass.PlayAnimation("Scream");

							local s = modAudio.Play("ZombieGroan", workspace);
							s.Volume = 1;
							local reverb = Instance.new("ReverbSoundEffect");
							reverb.Parent = s;

							stanNpcClass.Move:SetMoveSpeed("set", "default", 30);

							task.spawn(function()
								local targetGoon: NpcClass = banditGoons[1];

								local function hunt(playScream)
									repeat
										stanNpcClass.Properties.AttackMode = true;

										local targetPosition = targetGoon.RootPart.Position;
										local targetDist = stanNpcClass:DistanceFromCharacter(targetPosition);

										if targetDist <= 100 then
											stanNpcClass.Move:MoveTo(targetGoon.RootPart.Position);
										end
										if targetDist <= 6 then
											stanNpcClass.PlayAnimation("Attack");
											modAudio.Play("Slice", workspace).PlaybackSpeed = 0.5;
											modAudio.Play("Punch", workspace).PlaybackSpeed = 0.7;
											task.wait(0.2);

											targetGoon.HealthComp:SetIsDead(true);
											modAudio.Play("HumanDeath", workspace);
											task.wait(0.4);

											if playScream then
												stanNpcClass.PlayAnimation("Scream");
												modAudio.Play("ZombieGroan", workspace);
												task.wait(0.4);
											end
											task.wait(0.4);
										end
										task.wait();

										if targetDist > 256 then
											Debugger:Warn(`Target {targetGoon.Name}#{targetGoon.Character:GetAttribute("Cutscene")} too far!`);
											break;
										end
									until targetGoon.HealthComp.IsDead == true;
								end
								hunt(true);

								targetGoon = banditGoons[3];
								hunt(false);

								targetGoon = ratGoons[2];
								hunt(true);

								task.wait(2);
								stanNpcClass.Move:MoveTo(Vector3.new(-18.351, 1.88, 110.928));
								stanNpcClass.Move.OnMoveToEnded:Once(function() 
									stanNpcClass:TeleportHide();
								end)
							end)

							local lastDamaged = tick();
							stanNpcClass.Properties.Immortal = 0.2;
							stanNpcClass.HealthComp.OnHealthChanged:Connect(function()
								stanNpcClass.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn; lastDamaged = tick();
								task.delay(2, function()
									if tick()-lastDamaged > 2 and stanNpcClass.Humanoid then
										stanNpcClass.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff;
									end;
								end);

								task.wait();
								local hurtSound = modAudio.Play("ZombieHurt", stanNpcClass.RootPart);
								hurtSound.Volume = math.random(50, 60)/100;
								hurtSound.PlaybackSpeed = math.random(110, 120)/100;
							end)

							local ratGoon3: NpcClass = ratGoons[3];
							if not ratGoon3.HealthComp.IsDead then
								ratGoon3.Move:SetMoveSpeed("set", "default", 12);
								ratGoon3.Move:MoveTo(Vector3.new(-31.179, 5.066, -11.033));
								ratGoon3.Move.OnMoveToEnded:Once(function()
									ratGoon3:TeleportHide();
								end)
							end
							for a=1, #banditGoons do
								banditGoons[a].Properties.Immortal = nil;
							end

						else -- Helped Bandits;
							for a=1, #ratGoons do
								ratGoons[a].Properties.Immortal = nil;
							end
							stanNpcClass.Properties.AttackMode = true;

							ratGoons[2].Move:SetMoveSpeed("set", "default", 12);
							ratGoons[2].Move:MoveTo(Vector3.new(28.452, 5.066, -11));
							ratGoons[2].Move.OnMoveToEnded:Once(function()
								ratGoons[2]:TeleportHide();
							end)

							ratGoons[3].Move:SetMoveSpeed("set", "default", 12);
							ratGoons[3].Move:MoveTo(Vector3.new(-31.179, 5.066, -11.033));
							ratGoons[3].Move.OnMoveToEnded:Once(function()
								ratGoons[3]:TeleportHide();
							end)

							banditGoons[3].Move:SetMoveSpeed("set", "default", 12);
							banditGoons[3].Move:MoveTo(Vector3.new(-18.351, 1.88, 110.928));
							banditGoons[3].Move.OnMoveToEnded:Once(function()
								banditGoons[3]:TeleportHide();
							end)

						end

						task.spawn(function()
							local clientEffect = game.ServerScriptService.ServerLibrary.Entity.Npcs["Bandit Pilot"].HelicopterEffect:Clone();

							local prefabTag = clientEffect:WaitForChild("Prefab");
							prefabTag.Value = workspace.Environment.BanditHelicopterRig;

							clientEffect.Parent = player.Character;
						end)


						patrickNpcClass:ToggleInteractable(false);

						if patrickNpcClass.Properties.CarryInteractable == nil then
							local newInteractable = modInteractables.createInteractable("Button");
							newInteractable:SetAttribute("_Id", "mission58_RescuePatrick");
							newInteractable:SetAttribute("_Label", "Carry Patrick");
							newInteractable:SetAttribute("_Animation", "pickupcharacter");
							newInteractable:SetAttribute("_InteractDuration", 2.95);

							patrickNpcClass.Properties.CarryInteractable = newInteractable;
							newInteractable.Parent = patrickNpcClass.Character;
						end

						task.delay(5, function()
							local shipDoors = workspace.Environment.CargoShip.ShipDoors:GetChildren();
							for a=1, #shipDoors do
								if shipDoors[a]:GetAttribute("DoubleCross") ~= "A" then continue end;
								local doorConfig = shipDoors[a]:FindFirstChild("Door");
								
								local doorObj = modDoors.getOrNew(doorConfig);
								doorObj:Toggle(true);
							end
							
							for a=1, #shipDoors do
								local doorInteractConfig = shipDoors[a]:FindFirstChild("Interactable");
								local doorInteractable = modInteractables.getOrNew(doorInteractConfig);
								doorInteractable:SetPermissions("CanInteract", true);
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
								if playerClass.Character == nil then return end;
								playerCf = playerClass:GetCFrame();
							until playerCf.Y >= 12.5 and playerCf.Z >= 33;

							Debugger:Log("Helicopter leaves");

							TweenService:Create(heliLeavesAnimTrack, TweenInfo.new(10, Enum.EasingStyle.Linear), {
								TimePosition=9.98;
							}):Play();
							task.wait(3);

							for ct=18.2, 18.6, 0.008 do
								game.Lighting.ClockTime = ct;
								task.wait(0.1);
							end
						end)

						for _, obj in pairs(gateLever.LeftGate:GetChildren()) do
							if obj:IsA("BasePart") then 
								obj.CanCollide = true;
							end;
						end
						for _, obj in pairs(gateLever.RightGate:GetChildren()) do
							if obj:IsA("BasePart") then 
								obj.CanCollide = true;
							end;
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
							if shipDoors[a]:GetAttribute("DoubleCross") ~= "B" then continue end;
							local doorConfig = shipDoors[a]:FindFirstChild("Door");
							
							local doorObj = modDoors.getOrNew(doorConfig);
							doorObj:Toggle(true);
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
			modClientGuis.toggleGameBlinds(false, 0.5);
			modData.ToggleChat();
		end);
		CutsceneSequence:NewScene("hideBinds", function()
			modClientGuis.toggleGameBlinds(true, 1);
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
			modClientGuis.toggleGameBlinds(false, 3);
		end)
		

	--MARK: Safehome
	elseif modBranchConfigurations.IsWorld("Safehome") then
		
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;

			local safehomeClass = shared.WorldCore.SafehomeClass;
			repeat
				safehomeClass = shared.WorldCore.SafehomeClass;
				Debugger:Log("Waiting for (safehomeClass).")
				task.wait(0.1);
			until safehomeClass ~= nil;

			local playerClass: PlayerClass = shared.modPlayers.get(player);

			local patrickNpcClass: NpcClass;
			local function OnChanged(firstRun)
				local spawnPatrick = 0;
				local spawnAtt = safehomeClass:GetNpcSpot("Patrick");

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

					if patrickNpcClass then
						patrickNpcClass.Move:MoveTo(spawnAtt.WorldPosition);
						task.spawn(function()
							task.wait(0.1);
							patrickNpcClass.Move:Face(patrickNpcClass.RootPart.Position + spawnAtt.WorldCFrame.LookVector);
						end)

					end
				end

				if spawnPatrick > 0 then
					patrickNpcClass = modNpcs.getPlayerNpc(player, "Patrick");

					if patrickNpcClass == nil then
						modNpcs.spawn2{
							Name = "Patrick";
							CFrame = spawnPatrick == 2 and spawnAtt.WorldCFrame or playerClass:GetCFrame();
							Player = player;
						};

					end
				end
			end

			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)
		
	end
	
	return CutsceneSequence;
end;