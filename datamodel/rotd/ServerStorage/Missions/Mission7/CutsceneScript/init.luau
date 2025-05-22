local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);
local modEventService = shared.require(game.ReplicatedStorage.Library.EventService);

--== Variables;
local MISSION_ID = 7;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
	modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);
	modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

	if modBranchConfigs.IsWorld("TheWarehouse") then
		modOnGameEvents:ConnectEvent("OnGameModeStart", function(player, gameType, gameStage, room)
			if gameType ~= "Boss" and gameStage ~= "The Prisoner" then return end;
			if not modMission:Progress(player, MISSION_ID) then return end;

			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint < 3 then
					mission.ProgressionPoint = 3;

					modAnalyticsService:LogOnBoarding{
						Player=player;
						OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission7_EnteredBossFight;
					};
				end;
			end)
			
		end)

		modOnGameEvents:ConnectEvent("OnBossDefeated", function(players, npcModule)
			if npcModule.Name ~= "The Prisoner" then return end;

			for _, player in pairs(players) do
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint < 4 then 
						mission.ProgressionPoint = 4;

						modAnalyticsService:LogOnBoarding{
							Player=player;
							OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission7_DefeatedBoss;
						};
					end;
				end)
			end
		end)
		
		modEventService:OnInvoked("GameModeManager_DisconnectPlayer", function(event, packet)
			local player = event.Player;
			local menuRoom = packet.MenuRoom;
			if menuRoom == nil or menuRoom.Type ~= "Boss" or menuRoom.Stage ~= "The Prisoner" then return end;

			local destination;
			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.Pinned ~= true or mission.ProgressionPoint ~= 4 then return end;

				local doorInstance = workspace.Interactables:FindFirstChild("securityRoomEntrance");
				if doorInstance == nil then return end;

				destination = CFrame.new(doorInstance.Destination.WorldPosition + Vector3.new(0, 2.3, 0)) 
					* CFrame.Angles(0, math.rad(doorInstance.Destination.WorldOrientation.Y-90), 0);
			end)

			if destination then
				packet.SetTeleportCfFunc(destination);
			end
		end)

		shared.modEventService:OnInvoked("Interactables_OnTrigger", function(eventPacket: EventPacket, interactData, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;
			
			local triggerId = interactData.TriggerTag;
			if triggerId ~= "BloxmartUnlock" then return end;
			if not modMission:Progress(player, MISSION_ID) then return end;

			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint == 5 then
					mission.ProgressionPoint = 6;
					
					modAnalyticsService:LogOnBoarding{
						Player=player;
						OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission7_UnlockedBloxmartGate;
					};
				end;
			end)
		end)

		modOnGameEvents:ConnectEvent("OnDoorEnter", function(player, interactData)
			local doorName = interactData.Name;
			if doorName == nil then return end;
	
			if doorName == "Security Entrance Door" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 4 then mission.ProgressionPoint = 5; end;
				end)
				
			elseif doorName == "Security Exit Door" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 6 then mission.ProgressionPoint = 7; end;
				end)

			elseif doorName == "Sundays Entrance" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 7 then
						modMission:CompleteMission(player, 7); 
						modAnalyticsService:LogOnBoarding{
							Player=player;
							OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission7_Complete;
						};

					end;
				end)

			end
		end)

		modOnGameEvents:ConnectEvent("OnGameLobbyDisconnect", function(player, menuRoom)
			if not modMission:Progress(player, MISSION_ID) then return end;
			
			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint == 4 then
					mission.ProgressionPoint = 5;
				end;
			end)
		end)
	end

else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
		
		
		local robertModule = modNpcs.getByOwner(player, "Robert");
		if robertModule == nil then
			local npc = modNpcs.spawn("Robert", nil, function(npc, npcModule)
				npcModule.Owner = player;
				robertModule = npcModule;
			end);
			modReplicationManager.ReplicateOut(player, npc);
		end
		local warehouseSitCf = CFrame.new(15.6800423, 57.6597404, 42.3099594, 1, 0, 0, 0, 1, 0, 0, 0, 1);

		
		local function OnChanged(firstRun)
			if firstRun then
				if mission.Type == 3 or mission.ProgressionPoint > 5 then
					CutsceneSequence:NextScene("Open Bloxmart Gate");
				end
			end
			
			if mission.Type == 2 then -- OnAvailable
				robertModule.StopAnimation("Holding");
				robertModule.StopAnimation("Sit");
				robertModule.Actions:EnterDoor("warehouseEntrance");
				robertModule.Chat(robertModule.Owner, "Oh thank goodness dude..");
				local face = robertModule.Prefab:FindFirstChild("face", true);
				if face then face.Texture = "rbxassetid://15470952" end;
				
				robertModule:ToggleInteractable(false);
				
				robertModule.Actions:Teleport(CFrame.new(58.4135704, 57.6597404, -28.7544289, -0.573575675, 0, 0.819152594, 0, 1, 0, -0.819152594, 0, -0.573575675));
				robertModule.Move:Stop();
				task.wait(0.3);
				
				robertModule.Move:SetMoveSpeed("set", "default", 10);
				robertModule.Humanoid.JumpPower = 0;
				
				robertModule.Move:MoveTo(Vector3.new(13, 57.5, 39.3));
				robertModule.Move.MoveToEnded:Wait(10);
				robertModule.Move:Stop(1);
				
				robertModule.Actions:Teleport(CFrame.new(15.6800423, 57.6597404, 42.3099594));
				
				robertModule.Move:Face(Vector3.new(15.6800423, 57.6597404, 37.0099602));
				robertModule.Chat(robertModule.Owner, "");
				
				task.wait(0.4);
				robertModule.PlayAnimation("Sit", 0.75);
				task.wait(0.75);
				robertModule:ToggleInteractable(true);
				
				
			elseif mission.Type == 1 then -- OnActive
				if firstRun then
					robertModule.StopAnimation("Holding");
					robertModule.StopAnimation("Sit");
				end
				
				if mission.ProgressionPoint == 1 then
					robertModule.Actions:Teleport(warehouseSitCf);
					robertModule.StopAnimation("Holding");

					robertModule.Move:SetMoveSpeed("set", "default", 20);

					robertModule.Chat(player, "Follow me");
					wait(1);
					robertModule.Interactable.Parent = script;

					local classPlayer = modPlayers.GetByName(player.Name);
					classPlayer.EnemyDetectionRange = 10;

					robertModule.StopAnimation("Sit", 0.75);
					local face = robertModule.Prefab:FindFirstChild("face", true);
					if face then face.Texture = "rbxassetid://277939506" end;
					wait(0.5)
					
					robertModule.Move:MoveTo(Vector3.new(58.482, 57.7, -28.756));
					robertModule.Move.MoveToEnded:Wait(10);
					
					-- Run to Warehouse Exit;
					robertModule.Actions:WaitForOwner(30);
					task.wait(0.5);
					robertModule.Actions:EnterDoor("warehouseExit");

					-- Run to Fence Door;
					robertModule.Move:MoveTo(Vector3.new(107.235, 57.7, -30.3));
					robertModule.Move.MoveToEnded:Wait(5);
					
					robertModule.Actions:WaitForOwner(30);
					robertModule.Actions:EnterDoor("warehouseFenceExit");

					-- Run to Boss Door;
					robertModule.Move:MoveTo(Vector3.new(304.6, 57.7, 66.7));
					robertModule.Move.MoveToEnded:Wait(20);
					
					robertModule.Actions:WaitForOwner(50);
					robertModule.Actions:FaceOwner();

					-- Dialogue;
					robertModule.Actions:Teleport(CFrame.new(304.6, 57.7, 66.7));
					robertModule.Actions:WaitForOwner(50);
					robertModule.Chat(player, "Lets go in and put it out of it's misery!");
					classPlayer.EnemyDetectionRange = nil;

					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint < 2 then mission.ProgressionPoint = 2; end;
					end)

				elseif mission.ProgressionPoint == 2 then
					if firstRun then
						robertModule.StopAnimation("Sit");
						local face = robertModule.Prefab:FindFirstChild("face", true);
						if face then face.Texture = "rbxassetid://277939506" end;
					end
					robertModule.Actions:Teleport(CFrame.new(304.6, 57.7, 66.7));
					robertModule.Actions:WaitForOwner(50);
					if firstRun then
						robertModule.Chat(player, "Where have you been man? We need to kill this zombie.");
					end
					robertModule.Actions:FaceOwner();

				elseif mission.ProgressionPoint == 3 then
					if firstRun then
						robertModule.StopAnimation("Sit");
						robertModule.StopAnimation("Holding");
						local face = robertModule.Prefab:FindFirstChild("face", true);
						if face then face.Texture = "rbxassetid://277939506" end;
					end
					robertModule.Actions:Teleport();
					robertModule.Interactable.Parent = script;
					robertModule.Chat(player, "");
					robertModule.Wield.Equip("sawedoff");
					pcall(function()
						robertModule.Wield.ToolModule.Configurations.MinBaseDamage = 35;
					end);

					robertModule.Actions:FollowOwner(function()
						if robertModule.Target then
							local enemyHumanoid = robertModule.Target:FindFirstChildWhichIsA("Humanoid");
							if enemyHumanoid and enemyHumanoid.Health > 0 and enemyHumanoid.RootPart then
								robertModule.Wield.SetEnemyHumanoid(enemyHumanoid);
								robertModule.Move:Face(enemyHumanoid.RootPart);
								robertModule.Wield.PrimaryFireRequest();
							end
						end
						return mission.Type == 1 and mission.ProgressionPoint == 3;
					end);

				elseif mission.ProgressionPoint == 4 then
					robertModule.StopAnimation("Holding");
					robertModule.StopAnimation("Sit");
					robertModule.Wield.Unequip();

					local face = robertModule.Prefab:FindFirstChild("face", true);
					if face then face.Texture = "rbxassetid://209713384" end;
					robertModule.Chat(player, "Woohoo! We did it!");
					robertModule.Actions:FaceOwner();

				elseif mission.ProgressionPoint == 5 then
					robertModule.Chat(player, "");
					
					if modEvents:GetEvent(player, "mission7Money") == nil then
						modItemDrops.Spawn({Name="Money"; Type=modItemDrops.Types.Money; Quantity=500}, CFrame.new(288.96, 72.39, 3.59), {player}, false);
						modEvents:NewEvent(player, {Id="mission7Money"});
					end
					
					robertModule.Actions:EnterDoor("securityRoomEntrance");
					robertModule.Move:SetMoveSpeed("set", "default", 10);

					robertModule.Move:MoveTo(Vector3.new(288.262, 70.5, -13.902));
					robertModule.Move.MoveToEnded:Wait(5);

					robertModule.Move:Face(Vector3.new(292.362, 70.5, -8.102));
					wait(1.5);
					if modMission:Progress(player, 7).ProgressionPoint ~= 5 then return end;
					
					robertModule.Move:MoveTo(Vector3.new(287.8, 70.5, 1.1));
					robertModule.Move.MoveToEnded:Wait(5);
					robertModule.Move:Face(Vector3.new(287.8, 70.5, 4.8));
					
					robertModule.SetAnimation("CrouchLook", {script:WaitForChild("RobertCrouchLookAnim")});
					robertModule.PlayAnimation("CrouchLook", 1);
					local face = robertModule.Prefab:FindFirstChild("face", true);
					if face then face.Texture = "rbxassetid://2222767231" end;
					robertModule.Chat(player, "Poor guy...");
					wait(5);
					if modMission:Progress(player, 7).ProgressionPoint ~= 5 then return end;
					robertModule.StopAnimation("CrouchLook", 1);
					wait(1);
					if modMission:Progress(player, 7).ProgressionPoint ~= 5 then return end;
					robertModule.Move:Face(Vector3.new(303.242, 73.489, 10.267));
					robertModule.Chat(player, "Press that green button to open up the gates.");

				elseif mission.ProgressionPoint == 6 then
					CutsceneSequence:NextScene("Show Gate Opening");
					robertModule.StopAnimation("CrouchLook");
					robertModule.Chat(player, "Great, now let's go back to my safehouse.");
					robertModule.Actions:FaceOwner();

				elseif mission.ProgressionPoint == 7 then
					robertModule.Interactable.Parent = script;
					robertModule.StopAnimation("CrouchLook");
					
					robertModule.Move:SetMoveSpeed("set", "default", 22);

					robertModule.Actions:EnterDoor("securityRoomExit");

					local face = robertModule.Prefab:FindFirstChild("face", true);
					if face then face.Texture = "rbxassetid://405704879" end;
					robertModule.Chat(player, "Follow me and don't stop running!");
					delay(6, function()
						robertModule.Chat(player, "RUNNN");
					end);

					robertModule.Move:MoveTo(Vector3.new(636.112, 55.8, 9.348));
					robertModule.Move.MoveToEnded:Wait(32);
					
					robertModule.Actions:Teleport(CFrame.new(636.112, 57.7, 9.348));
					robertModule.Move:Face(Vector3.new(624.712, 55.8, 11.148));
					robertModule.Chat(player, "Hurry, get in.");
				end
				
				
			elseif mission.Type == 3 then -- OnComplete
				if not firstRun then
					robertModule.Actions:EnterDoor("safehouse2Entrance");
					robertModule.Chat(player, "");
					local face = robertModule.Prefab:FindFirstChild("face", true);
					if face then face.Texture = "rbxassetid://21311520" end;
					
					robertModule.Move:SetMoveSpeed("set", "default", 10);
					robertModule.Humanoid.JumpPower = 0;
					
					robertModule.Move:MoveTo(Vector3.new(662.87, 57.81, -13.28));
					robertModule.Move.MoveToEnded:Wait(32);
					
					robertModule.Move:Face(Vector3.new(650, 57.8096695, -13.2840099));
					robertModule.Interactable.Parent = robertModule.Prefab;
					
				end

			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	
	CutsceneSequence:NewScene("Open Bloxmart Gate", function()
		local gateModel = workspace.Environment:WaitForChild("BloxmartGate", 60);
		for a=1, 20 do
			if gateModel.PrimaryPart == nil then
				wait(1);
			else
				break;
			end
		end
		gateModel:SetPrimaryPartCFrame(CFrame.new(286.61203, 69.4899445, 103.898018, 1, 0, 0, 0, 1, 0, 0, 0, 1));
		if gateModel:FindFirstChild("Interactable") then
			gateModel.Interactable:Destroy();
		end
	end)
	
	
	CutsceneSequence:NewScene("Show Gate Opening", function()
		modConfigurations.Set("DisableHotbar", true);
		modConfigurations.Set("DisableWeaponInterface", true);
		modConfigurations.Set("DisableInventory", true);
		modConfigurations.Set("DisableHealthbar", true);
		modConfigurations.Set("DisableWorkbench", true);
		modConfigurations.Set("DisableExperiencebar", true);
		modConfigurations.Set("DisableGeneralStats", true);
		modConfigurations.Set("DisableHotbar", true);
		modConfigurations.Set("CanQuickEquip", false);
		modConfigurations.Set("DisableSquadInterface", true);
		modConfigurations.Set("DisableMasteryMenu", true);

		local modCharacter = modData:GetModCharacter();
		modCharacter.CharacterProperties.CanMove = false;
		modCharacter.CharacterProperties.CanInteract = false;
		modCharacter.CharacterProperties.CharacterCameraEnabled = false;
		modCharacter.MouseProperties.CameraSmoothing = 0.01;

		local modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);
		modCameraGraphics:Bind("LobbyCamera", {
			RenderStepped=function(camera)
				camera.CFrame = CFrame.new(270.571594, 63.6824913, 125.062851, 0.796943724, 0.0513714477, -0.601865232, -0, 0.99637723, 0.0850445181, 0.604053617, -0.0677756965, 0.794056535);
				camera.Focus = CFrame.new(271.77533, 63.5124016, 123.474731, 1, 0, 0, 0, 1, 0, 0, 0, 1);
			end;
		}, 2, 6);

		--local camera = workspace.CurrentCamera;
		--camera.CFrame = CFrame.new(270.571594, 63.6824913, 125.062851, 0.796943724, 0.0513714477, -0.601865232, -0, 0.99637723, 0.0850445181, 0.604053617, -0.0677756965, 0.794056535);
		--camera.Focus = CFrame.new(271.77533, 63.5124016, 123.474731, 1, 0, 0, 0, 1, 0, 0, 0, 1);

		local gateInteractable = workspace.Interactables:FindFirstChild("lockedBloxmartGate");
		if gateInteractable then gateInteractable:Destroy() end;

		local TweenService = game:GetService("TweenService");
		local gateModel = workspace.Environment:WaitForChild("BloxmartGate", 60);
		if gateModel then
			gateModel:SetPrimaryPartCFrame(CFrame.new(286.61203, 60.7738342, 103.898018, 1, 0, 0, 0, 1, 0, 0, 0, 1));

			local cframeValue = Instance.new("CFrameValue", script);
			cframeValue.Value = gateModel:GetPrimaryPartCFrame();

			local connection = cframeValue:GetPropertyChangedSignal("Value"):Connect(function()
				gateModel:SetPrimaryPartCFrame(cframeValue.Value);
			end)
			TweenService:Create(cframeValue, TweenInfo.new(6), {Value=CFrame.new(286.61203, 69.4899445, 103.898018, 1, 0, 0, 0, 1, 0, 0, 0, 1)}):Play();
			if gateModel:FindFirstChild("Interactable") then
				gateModel.Interactable:Destroy();
			end
			wait(6);
			connection:Disconnect();
		else
			Debugger:Warn("Missing Bloxmart Gate.");
			wait(2);
		end
		modCharacter.CharacterProperties.CanMove = true;
		modCharacter.CharacterProperties.CanInteract = true;
		modCharacter.CharacterProperties.CharacterCameraEnabled = true;
		modCharacter.MouseProperties.CameraSmoothing = 0;

		modConfigurations.Set("DisableHotbar", false);
		modConfigurations.Set("DisableWeaponInterface", false);
		modConfigurations.Set("DisableInventory", false);
		modConfigurations.Set("DisableHealthbar", false);
		modConfigurations.Set("DisableWorkbench", false);
		modConfigurations.Set("DisableExperiencebar", false);
		modConfigurations.Set("DisableGeneralStats", false);
		modConfigurations.Set("DisableHotbar", false);
		modConfigurations.Set("CanQuickEquip", true);
		modConfigurations.Set("DisableSquadInterface", false);
		modConfigurations.Set("DisableMasteryMenu", false);
	end)
	
	return CutsceneSequence;
end;