local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

--== Variables;
local MISSION_ID = 12;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = shared.require(localPlayer :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)

	--MARK: TheWarehouse
	if modBranchConfigs.IsWorld("TheWarehouse") then
		shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;
			
			if interactable.Id == "warehouseEntrance" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint >= 5 then
						modMission:CompleteMission(player, MISSION_ID);
					end
				end)
			end
		end)

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;


			local masonNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Mason");
			if masonNpcClass == nil then
				masonNpcClass = modNpcs.spawn2({
					Name = "Mason";
					Player = player;
					ReplicateOut = true;
				});
			end

			local function equipPistol()
				masonNpcClass.WieldComp:Equip{
					ItemId = "revolver454";
					OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
						if toolHandler.EquipmentClass == nil then return end;
						local equipmentClass: EquipmentClass = toolHandler.EquipmentClass;
						
						if equipmentClass.Configurations:GetModifier("npcDmg") == nil then
							local modifier: ConfigModifier = equipmentClass.Configurations.newModifier("npcDmg");
							modifier.SetValues.Damage = 35;
							modifier.Priority = 999;
							equipmentClass.Configurations:AddModifier(modifier, true);
						end
					end;
				};
			end

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						masonNpcClass.Properties.CutsceneActive = true;
						masonNpcClass.Move:Stop();
						
						masonNpcClass.StopAnimation("Lean");
						masonNpcClass:ToggleInteractable(false);

						masonNpcClass.Chat(masonNpcClass.Player, "Let me refill my weapons first.");
						
						task.wait(1.5);
						masonNpcClass.Move:Face("Player");
						masonNpcClass.Move:SetMoveSpeed("set", "default", 12);

						task.delay(1, function()
							masonNpcClass.WieldComp:Equip{
								ItemId = "revolver454";
							};
							if masonNpcClass.WieldComp.ToolHandler then
								masonNpcClass.WieldComp.ToolHandler.ToolAnimator:Play("Reload");
							end
						end)
						
						masonNpcClass.Move:MoveTo(Vector3.new(-5.8, 57, 19));
						masonNpcClass.Move.OnMoveToEnded:Wait(10);
						task.wait(0.5);
						masonNpcClass.Move:Face(Vector3.new(-12, 57, 19));
						
						task.wait(2);
						masonNpcClass.WieldComp:Unequip();
						task.wait(0.1);
						masonNpcClass.WieldComp:Equip{
							ItemId = "m4a4";
						};
						
						task.wait(1);
						if masonNpcClass.WieldComp.ToolHandler then
							masonNpcClass.WieldComp.ToolHandler.ToolAnimator:Play("Reload");
						end
						
						task.wait(4);
						masonNpcClass.WieldComp:Unequip();
						task.wait(0.1);
						equipPistol();

						masonNpcClass.Chat(masonNpcClass.Player, "I'm ready when you are.");
						masonNpcClass:ToggleInteractable(true);

						masonNpcClass.Move:Face("Player");
						masonNpcClass.WieldComp:InvokeToolAction("ToggleIdle", true);

						masonNpcClass:GetComponent("WaitForPlayer")(nil, function(pDist)
							return mission.ProgressionPoint >= 2;
						end);
						masonNpcClass.WieldComp:InvokeToolAction("ToggleIdle", false);

					elseif mission.ProgressionPoint == 2 then
						masonNpcClass.Properties.CutsceneActive = true;
						masonNpcClass.Move:Stop();
						
						if masonNpcClass.WieldComp.ItemId then
							equipPistol();
						end
						
						masonNpcClass:ToggleInteractable(false);
						
						masonNpcClass.Move:SetMoveSpeed("set", "default", 12);

						masonNpcClass.Move:MoveTo(Vector3.new(59.34, 57.66, -28.03));
						masonNpcClass.Move.OnMoveToEnded:Wait(6);
						
						
						masonNpcClass:GetComponent("WaitForPlayer")(30);
						masonNpcClass:UseInteractable("warehouseExit");
						masonNpcClass.Move:Stop();

						
						task.wait(0.1);
						masonNpcClass.Move:MoveTo(Vector3.new(77.6, 57.6, -20.3));
						masonNpcClass.Move.OnMoveToEnded:Wait(10);
						masonNpcClass.Move:Face(Vector3.new(92.12, 57.62, 66.21));

						task.wait(0.5);
						masonNpcClass.Chat(masonNpcClass.Player, "Stupid zombies..");
						masonNpcClass.Move:MoveTo(Vector3.new(92.12, 57.62, 66.21));

						local region = Region3.new(Vector3.new(58.35, 56.65, -63.15), Vector3.new(110.45, 61.75, 69.95));
						local targets = workspace:FindPartsInRegion3WithWhiteList(region, CollectionService:GetTagged("SpawnerRootParts"), 16);
						local timeout = tick();

						local targetList = {};
						for a=1, #targets do
							local rootPart = targets[a];
							local healthComp: HealthComp = modHealthComponent.getByModel(rootPart.Parent);
							if healthComp == nil
							or healthComp.IsDead
							or healthComp:CanTakeDamageFrom(masonNpcClass) == false then 
								continue;
							end;

							table.insert(targetList, {
								RootPart = rootPart;
								HealthComp = healthComp;
								Distance = (masonNpcClass.RootPart.Position - rootPart.Position).Magnitude;
							});
						end

						table.sort(targetList, function(a, b) return a.Distance > b.Distance end);
						local shotsLeft = 10;
						repeat
							for a=#targetList, 1, -1 do
								local targetInfo = targetList[a];
								local targetRootPart = targetInfo.RootPart;
								local healthComp = targetInfo.HealthComp;
								local tarHumanoid = healthComp.CompOwner.Humanoid;

								local relativeCFrame = masonNpcClass.RootPart.CFrame:ToObjectSpace(targetRootPart.CFrame);
								local dirAng = math.atan2(relativeCFrame.p.X, -relativeCFrame.p.Z);
								local dir = (targetRootPart.Position - masonNpcClass.RootPart.Position).Unit;

								if not healthComp.IsDead 
								and dirAng > -math.pi/3 and dirAng < math.pi/3
								and tarHumanoid then
									masonNpcClass.Move:Face(targetRootPart);

									local equipmentClass: EquipmentClass? = masonNpcClass.WieldComp.EquipmentClass;
									if equipmentClass then
										if equipmentClass.Properties.Ammo <= 0 then
											masonNpcClass.WieldComp:InvokeToolAction("ReloadRequest");
										else
											masonNpcClass.WieldComp:InvokeToolAction("PrimaryFireRequest", dir, tarHumanoid);
											shotsLeft = shotsLeft -1;
										end
										if shotsLeft <= 0 then break; end;
									end
									
								else
									table.remove(targetList, a);
								end
							end
						until #targetList <= 0 or tick()-timeout >= 10 or not wait(0.5);
						
						RunService.Heartbeat:Wait();
						task.wait(0.2);

						masonNpcClass.Move:MoveTo(Vector3.new(92.12, 57.62, 66.21));
						masonNpcClass.Move.OnMoveToEnded:Wait(10);

						masonNpcClass:GetComponent("WaitForPlayer")(30);
						masonNpcClass:UseInteractable("lockedFactorydoor");
						masonNpcClass.Move:Stop();
						
						masonNpcClass.Move:MoveTo(Vector3.new(75.2, 57.7, 156.7));

						wait(0.2);

						masonNpcClass.Move:MoveTo(Vector3.new(75.2, 57.7, 156.7));
						masonNpcClass.Move.OnMoveToEnded:Wait(10);
						
						masonNpcClass:GetComponent("WaitForPlayer")(30);
						masonNpcClass:UseInteractable("factoryEntrance");
						masonNpcClass.Move:Stop();

						masonNpcClass.Move:MoveTo(Vector3.new(18.9, 57.7, 183));
						masonNpcClass.Move.OnMoveToEnded:Wait(10);
						
						modMission:Progress(masonNpcClass.Player, MISSION_ID, function(mission)
							if mission.ProgressionPoint < 3 then
								mission.ProgressionPoint = 3;
							end;
						end)

					elseif mission.ProgressionPoint == 3 or mission.ProgressionPoint == 4 then

						if mission.Cache.Blockade then
							local blockadePrefab = mission.Cache.Blockade;

							local profile = shared.modProfile:Get(player);
							local playerSave = profile:GetActiveSave();
							local playerLevel = playerSave and playerSave:GetStat("Level") or 1;
							local focusLevel = modGlobalVars.GetLevelToFocus(playerLevel);
							
							local maxHealth = math.clamp(focusLevel, 1, 56) *100;

							local destructible: DestructibleInstance = modDestructibles.getOrNew(blockadePrefab:WaitForChild("Destructible"));

							destructible.HealthComp:SetMaxHealth(maxHealth);	
							destructible.HealthComp:SetHealth(maxHealth);
							destructible:SetEnabled(true);
							destructible.OnDestroy:Connect(function()
								Debugger:StudioWarn("Factory Blockade destroyed");
								mission.Cache.Blockade = nil;
								modMission:Progress(player, MISSION_ID, function(mission)
									if mission.ProgressionPoint < 4 then
										mission.ProgressionPoint = 4;
									end;
								end)
							end)

						else
							Debugger:Warn("No factory blockade");
						end

						masonNpcClass.Properties.CutsceneActive = true;
						if firstRun then
							if mission.ProgressionPoint == 4 then
								masonNpcClass:SetCFrame(CFrame.new(18.9, 57.7, 183) * masonNpcClass.RootPart.CFrame.Rotation);
								masonNpcClass:GetComponent("WaitForPlayer")(30);
								masonNpcClass.Chat(masonNpcClass.Player, "Where have you been? Let's go in already..");

								equipPistol();
								masonNpcClass.WieldComp:InvokeToolAction("ToggleIdle", true);
							end
							
						else
							if masonNpcClass.WieldComp.ItemId == nil then
								equipPistol();
							end
							masonNpcClass:ToggleInteractable(false);
							masonNpcClass:SetCFrame(CFrame.new(18.9, 57.7, 183) * masonNpcClass.RootPart.CFrame.Rotation);
							RunService.Heartbeat:Wait();
							
							masonNpcClass.Move:Face(Vector3.new(26, 58, 179));
							
							masonNpcClass.WieldComp:InvokeToolAction("ToggleIdle", true);
							if mission.ProgressionPoint == 3 then
								masonNpcClass.Chat(masonNpcClass.Player, "Here it is. You first, haha!");
								task.wait(2);
								if mission.Cache.Blockade then
									masonNpcClass.Chat(masonNpcClass.Player, "Destroy the wooden barricades so we can go in.");
								end
							end
							masonNpcClass:ToggleInteractable(true);
						end
						
					elseif mission.ProgressionPoint >= 5 then

						masonNpcClass.Properties.CutsceneActive = true;
						masonNpcClass:GetComponent("FollowPlayer")(nil, function()
							return mission.Type == 1;
						end);

						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint < 6 then
								mission.ProgressionPoint = 6;
							end;
						end)

					end
					
				elseif mission.Type == 3 then -- OnComplete
					masonNpcClass:UseInteractable("warehouseEntrance");

					if not firstRun then
						if masonNpcClass.Player then
							masonNpcClass.Chat(masonNpcClass.Player, `Good work, {masonNpcClass.Player.Name}!`);
						end
					end

					masonNpcClass.Properties.Cache.RestFinishTick = nil;
					masonNpcClass.Properties.CutsceneActive = false;
				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)
		
		
	--MARK: Factory
	elseif modBranchConfigs.IsWorld("Factory") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;

			if modMission:IsComplete(player, 12) then return end;

			local masonNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Mason");
			if masonNpcClass == nil then
				masonNpcClass = modNpcs.spawn2({
					Name = "Mason";
					CFrame = CFrame.new(63.452, 45.89, 3.248, 0, 0, 1, 0, 1, 0, -1, 0, 0);
					Player = player;
				});
			end

			masonNpcClass:ToggleInteractable(false);
			masonNpcClass.Properties.IsProtectingPlayer = true;

			local function OnChanged()
				if mission.Type == 1 and mission.ProgressionPoint == 5 then
					masonNpcClass:ToggleInteractable(true);
				end
			end
			mission.OnChanged:Connect(OnChanged);
		end)
		
	else
		return;
	end
	
	return CutsceneSequence;
end;