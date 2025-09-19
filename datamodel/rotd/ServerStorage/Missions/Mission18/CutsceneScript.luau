local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 18;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	if modBranchConfigs.IsWorld("TheUnderground") then
        shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

            local interactable: InteractableInstance = ...;

			if interactable.Id == "underbridgeEntrance" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 5 then mission.ProgressionPoint = 6; end;
				end)
			end
        end)
	end

else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	
	--MARK: TheWarehouse
	if modBranchConfigs.IsWorld("TheWarehouse") then
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

		
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					robertNpcClass.Move:Stop();
					wait(0.5);
					robertNpcClass:UseInteractable("sundaysEntrance");
					
					local face = robertNpcClass.Character:FindFirstChild("face", true);
					if face then face.Texture = "rbxassetid://21311520" end;
					
					robertNpcClass.Move:SetMoveSpeed("set", "default", 10);
					robertNpcClass.Humanoid.JumpPower = 0;

					robertNpcClass.Move:MoveTo(Vector3.new(662.87, 57.81, -13.28));
					robertNpcClass.Move.OnMoveToEnded:Wait(10);
					robertNpcClass.Move:Face(Vector3.new(650, 57.8096695, -13.2840099));
					
					robertNpcClass:ToggleInteractable(true);
					
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 2 then

						robertNpcClass.Chat(robertNpcClass.Player, "I'll follow your lead.");
						robertNpcClass:ToggleInteractable(false);
						
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
							
							return mission.Type == 1 and mission.ProgressionPoint == 2;
						end);

					end
					
				elseif mission.Type == 3 then -- OnComplete
					robertNpcClass:TeleportHide();

				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)
		
	--MARK: TheUnderground
	elseif modBranchConfigs.IsWorld("TheUnderground") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
			
			
			local carlsonModule = modNpcs.getPlayerNpc(player, "Carlson");
			if carlsonModule == nil then
				modReplicationManager.ReplicateOut(player, modNpcs.spawn("Carlson", nil, function(npc, npcModule)
					npcModule.Player = player;
					carlsonModule = npcModule;
				end));
			end

			local erikModule = modNpcs.getPlayerNpc(player, "Erik");
			if erikModule == nil then
				modReplicationManager.ReplicateOut(player, modNpcs.spawn("Erik", nil, function(npc, npcModule)
					npcModule.Player = player;
					erikModule = npcModule;
				end));
			end

			local dianaModule = modNpcs.getPlayerNpc(player, "Diana");
			if dianaModule == nil then
				modReplicationManager.ReplicateOut(player, modNpcs.spawn("Diana", nil, function(npc, npcModule)
					npcModule.Player = player;
					dianaModule = npcModule;
				end));
			end

			local robertNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Robert");
			if robertNpcClass == nil then
				robertNpcClass = shared.modNpcs.spawn2{
					Name = "Robert";
					CFrame = CFrame.new(1.65, 15, -2.57);
					Player = player;
					ReplicateOut = true;
				};
			end
			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					dianaModule.Actions:Teleport(CFrame.new(-200.6, 49.5, 245.7));

					carlsonModule.PlayAnimation("Injured");
					local carlsonFace = carlsonModule.Prefab:FindFirstChild("face", true);
					if carlsonFace then carlsonFace.Texture = "rbxassetid://168332209" end;
					
					erikModule.PlayAnimation("Scared");
					local erikFace = erikModule.Prefab:FindFirstChild("face", true);
					if erikFace then erikFace.Texture = "rbxassetid://2222767231" end;

					if mission.ProgressionPoint >= 4 then
						local robertFace = robertNpcClass.Character:FindFirstChild("face", true);
						if robertFace then robertFace.Texture = "rbxassetid://22877631" end;
					end

					if firstRun then
						if mission.ProgressionPoint <= 2 then
							modMission:Progress(player, MISSION_ID, function(mission)
								if mission.ProgressionPoint < 3 then mission.ProgressionPoint = 3; end;
							end)
						elseif mission.ProgressionPoint >= 9 then
							robertNpcClass:TeleportHide();
						elseif mission.ProgressionPoint >= 7 then
							robertNpcClass:SetCFrame(CFrame.new(-81.5, 8.682, 290));
						end
					end

					if mission.ProgressionPoint == 3 then
						local robertFace = robertNpcClass.Character:FindFirstChild("face", true);
						if robertFace then robertFace.Texture = "rbxassetid://416829404" end; 

						robertNpcClass:SetCFrame(CFrame.new(1.65, 15, -2.57));
						robertNpcClass:ToggleInteractable(false);
						
						local exitPosition = Vector3.new(-25.5, 7.5, 159.0);
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
							
							if (robertNpcClass.RootPart.Position-exitPosition).Magnitude <= 50 then
								modMission:Progress(player, MISSION_ID, function(mission)
									if mission.ProgressionPoint < 4 then mission.ProgressionPoint = 4; end;
								end)
							end
							return mission.Type == 1 and mission.ProgressionPoint == 3;
						end);

						task.delay(1, function()
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
						end)
						
					elseif mission.ProgressionPoint == 4 then
						
						robertNpcClass.Move:SetMoveSpeed("set", "default", 15);
						
						robertNpcClass.Chat(robertNpcClass.Player, "I hear something, follow me.");
						robertNpcClass.WieldComp:InvokeToolAction("ReloadRequest");

						robertNpcClass.Move:MoveTo(Vector3.new(5.2, 8.65, 177.85));
						robertNpcClass.Move.OnMoveToEnded:Wait(5);
						
						robertNpcClass:SetCFrame(CFrame.new(5.2, 8.65, 177.85));
						if mission.ProgressionPoint ~= 4 then return end;

						robertNpcClass.Move:Face(Vector3.new(-7.35, 8.65, 167.4));

						robertNpcClass:GetComponent("WaitForPlayer")(30);
						if mission.ProgressionPoint ~= 4 then return end;

						robertNpcClass.Chat(robertNpcClass.Player, "This way..");

						robertNpcClass.Move:MoveTo(Vector3.new(3.15, 8.071, 257.45));
						robertNpcClass.Move.OnMoveToEnded:Wait(6);
						
						robertNpcClass:SetCFrame(CFrame.new(3.15, 8.071, 257.45));
						if mission.ProgressionPoint ~= 4 then return end;

						robertNpcClass.Chat(robertNpcClass.Player, "Woah, look at this place..");
						robertNpcClass.Move:Face(Vector3.new(-10.3, 8.071, 262.6));

						local robertFace = robertNpcClass.Character:FindFirstChild("face", true);
						if robertFace then robertFace.Texture = "rbxassetid://22877631" end;
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint < 5 then mission.ProgressionPoint = 5; end;
						end)
						
					elseif mission.ProgressionPoint == 5 then
						if firstRun then
							robertNpcClass:SetCFrame(CFrame.new(-50.795, 8.232, 279.45));
						end
						
						robertNpcClass.Move:Stop();
						wait(1);
						if mission.ProgressionPoint ~= 5 then return end;

						robertNpcClass.Move:MoveTo(Vector3.new(-50.795, 8.232, 279.45));
						robertNpcClass.Move:SetMoveSpeed("set", "default", 8);
						
					elseif mission.ProgressionPoint == 6 then
						if not firstRun then
							robertNpcClass.Move:Stop();
							
							robertNpcClass:UseInteractable("underbridgeEntrance");
							robertNpcClass.Chat(robertNpcClass.Player, "Oh my god! What happened here?!");
							robertNpcClass.WieldComp:Unequip();
							
							robertNpcClass.Move:SetMoveSpeed("set", "default", 15);

							robertNpcClass.Move:MoveTo(Vector3.new(-101.6, 8.682, 315.75));
							robertNpcClass.Move.OnMoveToEnded:Wait(20);
							
							robertNpcClass.Move:Face(Vector3.new(-101.25, 8.682, 318.9));
							
							robertNpcClass.PlayAnimation("CrouchLook", 1);
							wait(0.5);
							robertNpcClass.Chat(robertNpcClass.Player, "Hey, are you okay?");
							wait(1);
							erikModule.Chat(erikModule.Player, "Are.. are they gone?");
							wait(3);
							erikModule.Chat(erikModule.Player);
							robertNpcClass.Chat(robertNpcClass.Player, "Who are they?");
							wait(3);
							erikModule.Chat(erikModule.Player, "The bandits");
							wait(3);
							erikModule.Chat(erikModule.Player);
							robertNpcClass.Chat(robertNpcClass.Player, "Don't worry, I think they're gone now..");
							wait(3);
							robertNpcClass.StopAnimation("CrouchLook", 1);
							
							robertNpcClass.Move:MoveTo(Vector3.new(-81.5, 8.682, 290));
							robertNpcClass.Move.OnMoveToEnded:Wait(10);
							
						else
							robertNpcClass:SetCFrame(CFrame.new(-81.5, 8.682, 290));
						end
						
					elseif mission.ProgressionPoint == 8 then
						robertNpcClass:ToggleInteractable(true);
						
					elseif mission.ProgressionPoint == 9 then
						carlsonModule.StopAnimation("Injured");
						robertNpcClass:ToggleInteractable(false);
						
						robertNpcClass.Move:SetMoveSpeed("set", "default", 15);

						robertNpcClass.Move:MoveTo(Vector3.new(-57.95, 8.682, 279.45));
						robertNpcClass.Move.OnMoveToEnded:Wait(10);
						
						robertNpcClass:UseInteractable("underbridgeExit");
						
						robertNpcClass.Move:MoveTo(Vector3.new(1.75, 8.55, 231.1));
						robertNpcClass.Move.OnMoveToEnded:Wait(10);
						
						robertNpcClass:TeleportHide();
						
					end
					
				elseif mission.Type == 3 then -- OnComplete
					dianaModule.Actions:Teleport(dianaModule.SpawnPoint);
					if modMission:GetMission(player, 38) == nil then
						robertNpcClass:TeleportHide();
					end

					local carlsonFace = carlsonModule.Prefab:FindFirstChild("face", true);
					if carlsonFace then carlsonFace.Texture = "rbxassetid://21311520" end; 

					if firstRun then
						erikModule.PlayAnimation("ScaredPeek");
					end
					robertNpcClass:TeleportHide();

				end
			end

			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.Type == 1 and mission.ProgressionPoint == 4 then
					mission.ProgressionPoint = 5;
				end;
			end)
			
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)
		
	end
	
	return CutsceneSequence;
end;