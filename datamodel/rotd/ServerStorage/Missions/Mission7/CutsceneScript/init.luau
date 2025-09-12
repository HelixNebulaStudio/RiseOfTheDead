local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

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
		
        shared.modEventService:OnInvoked("GameModeManager_BindGameModeStart", function(eventPacket: EventPacket, packet)
			local room = packet.Room;
			if room.Type ~= "Boss" or room.Stage ~= "The Prisoner" then return end;
			if eventPacket.Players == nil then return end;
			
			for _, player: Player in pairs(eventPacket.Players) do
				if not modMission:Progress(player, MISSION_ID) then continue end;

				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint < 3 then
						mission.ProgressionPoint = 3;

						modAnalyticsService:LogOnBoarding{
							Player=player;
							OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission7_EnteredBossFight;
						};
					end;
				end)

			end
		end)

        shared.modEventService:OnInvoked("Boss_BindDefeated", function(eventPacket: EventPacket, packet)
			local npcClass: NpcClass = packet.NpcClass;
			if npcClass.Name ~= "The Prisoner" then return end;
			if eventPacket.Players == nil then return end;

			for _, player: Player in pairs(eventPacket.Players) do
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
		
		shared.modEventService:OnInvoked("GameModeManager_BindDisconnectPlayer", function(event, packet)
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

			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint == 4 then
					mission.ProgressionPoint = 5;
				end;
			end)
			
		end)

        shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

            local interactable: InteractableInstance = ...;

			if interactable.Id == "securityRoomEntrance" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 4 then mission.ProgressionPoint = 5; end;
				end)

			elseif interactable.Id == "securityRoomExit" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 6 then mission.ProgressionPoint = 7; end;
				end)

			elseif interactable.Id == "safehouse2Entrance" then
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

		shared.modEventService:OnInvoked("Interactables_BindButtonInteract", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;
			if interactable.Id ~= "BloxmartGateButton" then return end;

			Debugger:Warn("BloxmartGateButton pressed");
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

	end

else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheWarehouse") then return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
		
		
		local robertNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Robert");
		if robertNpcClass == nil then
			robertNpcClass = shared.modNpcs.spawn2{
				Name = "Robert";
				Player = player;
				ReplicateOut = true;
			};
		end
		local warehouseSitCf = CFrame.new(15.6800423, 57.6597404, 42.3099594, 1, 0, 0, 0, 1, 0, 0, 0, 1);

		
		local function OnChanged(firstRun)
			if firstRun then
				if mission.Type == 3 or mission.ProgressionPoint > 5 then
					CutsceneSequence:NextScene("Open Bloxmart Gate");
				end
			end
			
			if mission.Type == 2 then -- OnAvailable
				robertNpcClass.StopAnimation("Holding");
				robertNpcClass.StopAnimation("Sit");
				robertNpcClass:UseInteractable("warehouseEntrance");
				robertNpcClass.Chat(robertNpcClass.Player, "Oh thank goodness dude..");

				local face = robertNpcClass.Character:FindFirstChild("face", true);
				if face then face.Texture = "rbxassetid://15470952" end;
				
				robertNpcClass:ToggleInteractable(false);
				
				robertNpcClass:SetCFrame(CFrame.new(58.4135704, 57.6597404, -28.7544289, -0.573575675, 0, 0.819152594, 0, 1, 0, -0.819152594, 0, -0.573575675));
				robertNpcClass.Move:Stop();
				task.wait(0.3);
				
				robertNpcClass.Move:SetMoveSpeed("set", "default", 10);
				robertNpcClass.Humanoid.JumpPower = 0;
				
				robertNpcClass.Move:MoveTo(Vector3.new(13, 57.5, 39.3));
				robertNpcClass.Move.OnMoveToEnded:Wait(10);
				robertNpcClass.Move:Stop(1);
				
				robertNpcClass:SetCFrame(CFrame.new(15.6800423, 57.6597404, 42.3099594));
				
				robertNpcClass.Move:Face(Vector3.new(15.6800423, 57.6597404, 37.0099602));
				robertNpcClass.Chat(robertNpcClass.Player, "");
				
				task.wait(0.4);
				robertNpcClass.PlayAnimation("Sit", 0.75);
				task.wait(0.75);
				robertNpcClass:ToggleInteractable(true);
				
				
			elseif mission.Type == 1 then -- OnActive
				if firstRun then
					robertNpcClass.StopAnimation("Holding");
					robertNpcClass.StopAnimation("Sit");
				end
				
				if mission.ProgressionPoint == 1 then
					robertNpcClass:SetCFrame(warehouseSitCf);
					robertNpcClass.StopAnimation("Holding");

					robertNpcClass.Move:SetMoveSpeed("set", "default", 20);

					robertNpcClass.Chat(player, "Follow me");
					wait(1);
					
					robertNpcClass:ToggleInteractable(false);

					local playerClass: PlayerClass = modPlayers.GetByName(player.Name);
					playerClass.Properties.EnemyDetectionRange = 10;

					robertNpcClass.StopAnimation("Sit", 0.75);
					local face = robertNpcClass.Character:FindFirstChild("face", true);
					if face then face.Texture = "rbxassetid://277939506" end;
					wait(0.5)
					
					robertNpcClass.Move:MoveTo(Vector3.new(58.482, 57.7, -28.756));
					robertNpcClass.Move.OnMoveToEnded:Wait(10);
					
					-- Run to Warehouse Exit;
					robertNpcClass:GetComponent("WaitForPlayer")(30);
					task.wait(0.5);
					robertNpcClass:UseInteractable("warehouseExit");

					-- Run to Fence Door;
					robertNpcClass.Move:MoveTo(Vector3.new(107.235, 57.7, -30.3));
					robertNpcClass.Move.OnMoveToEnded:Wait(5);
					
					robertNpcClass:GetComponent("WaitForPlayer")(30);
					robertNpcClass:UseInteractable("warehouseFenceExit");

					-- Run to Boss Door;
					robertNpcClass.Move:MoveTo(Vector3.new(304.6, 57.7, 66.7));
					robertNpcClass.Move.OnMoveToEnded:Wait(20);
					
					robertNpcClass:GetComponent("WaitForPlayer")(50);
					robertNpcClass.Move:Face("Player");

					-- Dialogue;
					robertNpcClass:SetCFrame(CFrame.new(304.6, 57.7, 66.7));
					robertNpcClass:GetComponent("WaitForPlayer")(50);
					robertNpcClass.Chat(player, "Lets go in and put it out of it's misery!");
					playerClass.Properties.EnemyDetectionRange = nil;

					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint < 2 then mission.ProgressionPoint = 2; end;
					end)

				elseif mission.ProgressionPoint == 2 then
					if firstRun then
						robertNpcClass.StopAnimation("Sit");
						local face = robertNpcClass.Character:FindFirstChild("face", true);
						if face then face.Texture = "rbxassetid://277939506" end;
					end
					robertNpcClass:SetCFrame(CFrame.new(304.6, 57.7, 66.7));
					robertNpcClass:GetComponent("WaitForPlayer")(50);
					if firstRun then
						robertNpcClass.Chat(player, "Where have you been man? We need to kill this zombie.");
					end
					robertNpcClass.Move:Face("Player");

				elseif mission.ProgressionPoint == 3 then
					if firstRun then
						robertNpcClass.StopAnimation("Sit");
						robertNpcClass.StopAnimation("Holding");
						local face = robertNpcClass.Character:FindFirstChild("face", true);
						if face then face.Texture = "rbxassetid://277939506" end;
					end
					robertNpcClass:SetCFrame();
					robertNpcClass:ToggleInteractable(false);
					robertNpcClass.Chat(player, "");
					robertNpcClass.WieldComp:Equip{
						ItemId = robertNpcClass.Properties.PrimaryGunItemId;
						OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
							if toolHandler.EquipmentClass == nil then return end;
							local equipmentClass: EquipmentClass = toolHandler.EquipmentClass;

							local modifier: ConfigModifier = equipmentClass.Configurations.newModifier("npcDmg");
							modifier.SetValues.Damage = 10;
							modifier.Priority = 999;
							equipmentClass.Configurations:AddModifier(modifier, true);
						end;
					};

					robertNpcClass:GetComponent("FollowPlayer")(nil, function()
						local enemyTargetData = robertNpcClass:GetComponent("TargetHandler"):MatchFirstWieldTargettable();
						if enemyTargetData then
							local enemyHealthComp: HealthComp = enemyTargetData.HealthComp;
							local enemyNpcClass: NpcClass = enemyHealthComp.CompOwner;

							if enemyNpcClass
							and enemyHealthComp.IsDead ~= true
							and enemyHealthComp:CanTakeDamageFrom(robertNpcClass) then
								local equipmentClass: EquipmentClass? = robertNpcClass.WieldComp.EquipmentClass;
								if equipmentClass then
									if equipmentClass.Properties.Ammo <= 0 then
										robertNpcClass.WieldComp:InvokeToolAction("ReloadRequest");

									else
										local shootDirection = (enemyNpcClass.RootPart.Position - robertNpcClass.RootPart.Position).Unit;
										
										robertNpcClass.Move:Face(enemyNpcClass.RootPart);
										robertNpcClass.WieldComp:InvokeToolAction(
											"PrimaryFireRequest", 
											shootDirection, 
											enemyNpcClass.Humanoid 
										);
									end
								end
							end
						else
							robertNpcClass.WieldComp.Controls.Mouse1Down = false;
						end
						
						return mission.Type == 1 and mission.ProgressionPoint == 3;
					end);

				elseif mission.ProgressionPoint == 4 then
					robertNpcClass.StopAnimation("Holding");
					robertNpcClass.StopAnimation("Sit");
					robertNpcClass.WieldComp:Unequip();

					local face = robertNpcClass.Character:FindFirstChild("face", true);
					if face then face.Texture = "rbxassetid://209713384" end;
					robertNpcClass.Chat(player, "Woohoo! We did it!");
					robertNpcClass.Move:Face("Player");

				elseif mission.ProgressionPoint == 5 then
					robertNpcClass.Chat(player, "");
					
					if modEvents:GetEvent(player, "mission7Money") == nil then
						modItemDrops.Spawn({
							Name="Money"; 
							Type=modItemDrops.Types.Money; 
							Quantity=500}, CFrame.new(288.96, 72.39, 3.59), {player}, false);
						modEvents:NewEvent(player, {Id="mission7Money"});
					end
					
					robertNpcClass:UseInteractable("securityRoomEntrance");
					robertNpcClass.Move:SetMoveSpeed("set", "default", 10);
					
					robertNpcClass.Move:Stop();
					robertNpcClass:GetComponent("WaitForPlayer")(10);

					robertNpcClass.Move:Face(Vector3.new(292.362, 70.5, -8.102));
					robertNpcClass.SetAnimation("CrouchLook", {script:WaitForChild("RobertCrouchLookAnim")});
					if modMission:Progress(player, 7).ProgressionPoint ~= 5 then return end;
					
					robertNpcClass.Move:MoveTo(Vector3.new(287.8, 70.5, 1.1)); -- Infront of body
					robertNpcClass.Move.OnMoveToEnded:Wait(2);
					robertNpcClass.Move:Face(Vector3.new(287.8, 70.5, 4.8));
					
					robertNpcClass.PlayAnimation("CrouchLook", 1);
					local face = robertNpcClass.Character:FindFirstChild("face", true);
					if face then face.Texture = "rbxassetid://2222767231" end;

					robertNpcClass.Chat(player, "Poor guy...");
					wait(4);
					if modMission:Progress(player, 7).ProgressionPoint ~= 5 then return end;
					robertNpcClass.StopAnimation("CrouchLook", 1);
					wait(1);
					if modMission:Progress(player, 7).ProgressionPoint ~= 5 then return end;
					robertNpcClass.Move:Face(Vector3.new(303.242, 73.489, 10.267));
					robertNpcClass.Chat(player, "Press that green button to open up the gates.");

				elseif mission.ProgressionPoint == 6 then
					CutsceneSequence:NextScene("Show Gate Opening");
					robertNpcClass.StopAnimation("CrouchLook");
					task.delay(6, function()
						robertNpcClass.Chat(player, "Great, now let's go back to my safehouse.");
					end)
					robertNpcClass.Move:Face("Player");

				elseif mission.ProgressionPoint == 7 then
					robertNpcClass:ToggleInteractable(false);
					robertNpcClass.StopAnimation("CrouchLook");
					
					robertNpcClass.Move:SetMoveSpeed("set", "default", 22);

					robertNpcClass:UseInteractable("securityRoomExit");

					local face = robertNpcClass.Character:FindFirstChild("face", true);
					if face then face.Texture = "rbxassetid://405704879" end;
					robertNpcClass.Chat(player, "Follow me and don't stop running!");
					delay(6, function()
						robertNpcClass.Chat(player, "RUNNN");
					end);

					robertNpcClass.Move:MoveTo(Vector3.new(636.112, 55.8, 9.348));
					robertNpcClass.Move.OnMoveToEnded:Wait(32);
					
					robertNpcClass:SetCFrame(CFrame.new(636.112, 57.7, 9.348));
					robertNpcClass.Move:Face(Vector3.new(624.712, 55.8, 11.148));
					robertNpcClass.Chat(player, "Hurry, get in.");
				end
				
				
			elseif mission.Type == 3 then -- OnComplete
				if not firstRun then
					robertNpcClass:UseInteractable("safehouse2Entrance");
					robertNpcClass.Chat(player, "");
					local face = robertNpcClass.Character:FindFirstChild("face", true);
					if face then face.Texture = "rbxassetid://21311520" end;
					
					robertNpcClass.Move:SetMoveSpeed("set", "default", 10);
					robertNpcClass.Humanoid.JumpPower = 0;
					
					robertNpcClass.Move:MoveTo(Vector3.new(662.87, 57.81, -13.28));
					robertNpcClass.Move.OnMoveToEnded:Wait(32);
					
					robertNpcClass.Move:Face(Vector3.new(650, 57.8096695, -13.2840099));
					robertNpcClass:ToggleInteractable(true);
					
				end

			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	
	-- MARK: Open Bloxmart Gate
	CutsceneSequence:NewScene("Open Bloxmart Gate", function()
		local gateModel = workspace.Environment:WaitForChild("BloxmartGate", 60);
		for a=1, 20 do
			if gateModel.PrimaryPart == nil then
				wait(1);
			else
				break;
			end
		end
		gateModel:PivotTo(CFrame.new(286.61203, 69.4899445, 103.898018, 1, 0, 0, 0, 1, 0, 0, 0, 1));
		if gateModel:FindFirstChild("Interactable") then
			gateModel.Interactable:Destroy();
		end
		
		local gateButton = workspace.Interactables:WaitForChild("gateButton");
		local gateButtonInteractable: InteractableInstance = modInteractables.getOrNew(gateButton:WaitForChild("Interactable"));
		local gateButtonPart = gateButtonInteractable.Part;

		if gateButtonPart then
			gateButtonPart.ButtonPanel.button.Color = Color3.fromRGB(107, 59, 59);
			gateButtonPart.ButtonPanel.button.Position = Vector3.new(303.242, 73.349, 10.282);

			gateButtonInteractable.Label = "Bloxmart gates are now opened.";
			gateButtonInteractable.CanInteract = false;
		end
		
	end)
	
	
	-- MARK: Show Gate Opening
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


		local gateButton = workspace.Interactables:WaitForChild("gateButton");
		local gateButtonInteractable: InteractableInstance = modInteractables.getOrNew(gateButton:WaitForChild("Interactable"));
		local gateButtonPart = gateButtonInteractable.Part;

		if gateButtonPart then
			gateButtonPart.ButtonPanel.button.Color = Color3.fromRGB(107, 59, 59);
			gateButtonPart.ButtonPanel.button.Position = Vector3.new(303.242, 73.349, 10.282);

			gateButtonInteractable.Label = "Bloxmart gates are now opened.";
			gateButtonInteractable.CanInteract = false;
		end

		local gateModel = workspace.Environment:WaitForChild("BloxmartGate", 60);
		if gateModel then
			local gateInteractable = gateModel:FindFirstChild("Interactable");
			if gateInteractable then gateInteractable:Destroy() end;

			gateModel:PivotTo(CFrame.new(286.61203, 60.7738342, 103.898018, 1, 0, 0, 0, 1, 0, 0, 0, 1));

			local cframeValue = Instance.new("CFrameValue", script);
			cframeValue.Value = gateModel:GetPrimaryPartCFrame();

			local connection = cframeValue:GetPropertyChangedSignal("Value"):Connect(function()
				gateModel:PivotTo(cframeValue.Value);
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