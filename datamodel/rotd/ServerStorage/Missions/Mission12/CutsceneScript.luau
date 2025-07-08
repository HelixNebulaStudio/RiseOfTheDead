local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local missionId = 12;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = shared.require(localPlayer :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)

	if modBranchConfigs.IsWorld("TheWarehouse") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then return end;


			local masonModule = modNpcs.get(player, "Mason");
			if masonModule == nil then
				local npc = modNpcs.spawn("Mason", nil, function(npc, npcModule)
					npcModule.Owner = player;
					masonModule = npcModule;
				end);
				modReplicationManager.ReplicateOut(player, npc);
			end


			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						masonModule.StopCarLoop();
						masonModule.Move:Stop();
						
						masonModule.StopAnimation("Lean");
						masonModule:ToggleInteractable(false);

						masonModule.Chat(masonModule.Owner, "Let me refill my weapons first.");
						
						task.wait(1.5);
						masonModule.Move:Face();
						masonModule.Move:SetMoveSpeed("set", "default", 12);

						task.delay(1, function()
							masonModule.Wield.Equip("revolver454");
							pcall(function()
								masonModule.Wield.ToolModule.Configurations.MinBaseDamage = 35;
								masonModule.Wield.ToolModule.Properties.Ammo = 0;
							end);
						end)
						
						masonModule.Move:MoveTo(Vector3.new(-5.8, 57, 19));
						masonModule.Move.OnMoveToEnded:Wait(10);
						task.wait(0.5);
						masonModule.Move:Face(Vector3.new(-12, 57, 19));
						
						task.wait(0.5);
						masonModule.Wield.ReloadRequest();
						task.wait(1);
						masonModule.Wield.Unequip();
						task.wait(0.1);
						masonModule.Wield.Equip("m4a4");
						
						pcall(function()
							masonModule.Wield.ToolModule.Configurations.MinBaseDamage = 10;
							masonModule.Wield.ToolModule.Properties.Ammo = 0;
						end);
						
						task.wait(1);
						masonModule.Wield.ReloadRequest();
						task.wait(4);
						masonModule.Wield.Unequip();
						task.wait(0.1);
						masonModule.Wield.Equip("revolver454");
						masonModule.Chat(masonModule.Owner, "I'm ready when you are.");
						masonModule:ToggleInteractable(true);
						masonModule.Actions:FaceOwner(function()
							return mission.ProgressionPoint ~= 1;
						end);

					elseif mission.ProgressionPoint == 2 then
						masonModule.StopCarLoop();
						masonModule.Move:Stop();
						
						if masonModule.Wield.ToolModule == nil then
							masonModule.Wield.Equip("revolver454");
						end

						masonModule:ToggleInteractable(false);
						
						masonModule.Move:SetMoveSpeed("set", "default", 12);

						masonModule.Move:MoveTo(Vector3.new(59.34, 57.66, -28.03));
						masonModule.Move.OnMoveToEnded:Wait(6);
						
						masonModule.Actions:WaitForOwner(30);
						masonModule.Actions:EnterDoor("warehouseExit");
						masonModule.Move:Stop();

						pcall(function() masonModule.Wield.ToolModule.Configurations.MinBaseDamage = 60; end);
						
						task.wait(0.1);
						masonModule.Move:MoveTo(Vector3.new(77.6, 57.6, -20.3));
						masonModule.Move.OnMoveToEnded:Wait(10);
						masonModule.Move:Face(Vector3.new(92.12, 57.62, 66.21));

						task.wait(0.5);
						masonModule.Chat(masonModule.Owner, "Stupid zombies..");
						masonModule.Move:MoveTo(Vector3.new(92.12, 57.62, 66.21));

						local region = Region3.new(Vector3.new(58.35, 56.65, -63.15), Vector3.new(110.45, 61.75, 69.95));
						local targets = workspace:FindPartsInRegion3WithWhiteList(region, CollectionService:GetTagged("SpawnerRootParts"), 16);
						local timeout = tick();

						repeat
							for a=#targets, 1, -1 do
								local rootPart = targets[a];
								local humanoid = rootPart and rootPart.Parent and rootPart.Parent:FindFirstChild("Zombie") or nil;
								local relativeCFrame = masonModule.RootPart.CFrame:toObjectSpace(rootPart.CFrame);
								local direction = math.atan2(relativeCFrame.p.X, -relativeCFrame.p.Z);

								if humanoid and humanoid.Health > 0 and direction > -math.pi/3 and direction < math.pi/3 then
									masonModule.Wield.SetEnemyHumanoid(humanoid);
									masonModule.Move:Face(rootPart);
									masonModule.Wield.PrimaryFireRequest();
									
								else
									table.remove(targets, a);
									
								end
							end
						until #targets <= 0 or tick()-timeout >= 10 or not wait(1);
						
						RunService.Heartbeat:Wait();
						
						masonModule.Wield.ReloadRequest();
						task.wait(0.2);

						masonModule.Move:MoveTo(Vector3.new(92.12, 57.62, 66.21));
						masonModule.Move.OnMoveToEnded:Wait(10);
						
						--masonModule.Movement:Move(Vector3.new(92.12, 57.62, 66.21)):Wait(10);

						masonModule.Actions:WaitForOwner(30);
						masonModule.Actions:EnterDoor("lockedFactorydoor");
						--masonModule.Movement:EndMovement();
						masonModule.Move:Stop();
						
						--masonModule.Movement:Move(Vector3.new(75.2, 57.7, 156.7));
						masonModule.Move:MoveTo(Vector3.new(75.2, 57.7, 156.7));

						local region = Region3.new(Vector3.new(30.5, 55.9, 76.8), Vector3.new(110.5, 60.3, 158.3));
						local targets = workspace:FindPartsInRegion3WithWhiteList(region, CollectionService:GetTagged("SpawnerRootParts"), 16);
						local timeout = tick();

						repeat
							for a=#targets, 1, -1 do
								local rootPart = targets[a];
								local humanoid = rootPart and rootPart.Parent and rootPart.Parent:FindFirstChild("Zombie") or nil;
								local relativeCFrame = masonModule.RootPart.CFrame:toObjectSpace(rootPart.CFrame);
								local direction = math.atan2(relativeCFrame.p.X, -relativeCFrame.p.Z);

								if humanoid and humanoid.Health > 0 and direction > -math.pi/3 and direction < math.pi/3 then
									masonModule.Wield.SetEnemyHumanoid(humanoid);
									--masonModule.Movement:Face(rootPart.Position);
									masonModule.Move:Face(rootPart);
									masonModule.Wield.PrimaryFireRequest();
								else
									table.remove(targets, a);
								end
							end
						until #targets <= 0 or tick()-timeout >= 10 or not wait(0.3);
						RunService.Heartbeat:Wait();
						masonModule.Wield.ReloadRequest();
						wait(0.2);

						--masonModule.Movement:Move(Vector3.new(75.2, 57.7, 156.7)):Wait(10);
						masonModule.Move:MoveTo(Vector3.new(75.2, 57.7, 156.7));
						masonModule.Move.OnMoveToEnded:Wait(10);
						
						masonModule.Actions:WaitForOwner(30);
						masonModule.Actions:EnterDoor("factoryEntrance");
						--masonModule.Movement:EndMovement();
						masonModule.Move:Stop();

						--masonModule.Movement:Move(Vector3.new(18.9, 57.7, 183)):Wait(10);
						masonModule.Move:MoveTo(Vector3.new(18.9, 57.7, 183));
						masonModule.Move.OnMoveToEnded:Wait(10);
						
						modMission:Progress(masonModule.Owner, 12, function(mission)
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

							local destructibleObj = shared.require(blockadePrefab:FindFirstChild("Destructible"));
							destructibleObj:SetHealth(maxHealth, maxHealth);
							destructibleObj.Enabled = true;
							destructibleObj.OnDestroySignal:Connect(function()
								Debugger:StudioWarn("Factory Blockade destroyed");
								mission.Cache.Blockade = nil;
							end)
						else
							Debugger:Warn("No factory blockade");
						end

						if firstRun then
							if mission.ProgressionPoint == 4 then
								masonModule.Actions:Teleport(CFrame.new(18.9, 57.7, 183) * (masonModule.RootPart.CFrame - masonModule.RootPart.CFrame.p));
								masonModule.Actions:WaitForOwner(30);
								masonModule.Chat(masonModule.Owner, "Where have you been? Let's go in already..");
							end
							
						else
							masonModule.StopCarLoop();
							if masonModule.Wield.ToolModule == nil then
								masonModule.Wield.Equip("revolver454");
							end
							masonModule:ToggleInteractable(false);
							masonModule.Actions:Teleport(CFrame.new(18.9, 57.7, 183) * (masonModule.RootPart.CFrame - masonModule.RootPart.CFrame.p));
							RunService.Heartbeat:Wait();
							
							masonModule.Move:Face(Vector3.new(26, 58, 179));
							
							masonModule.Chat(masonModule.Owner, "Here it is. You first, haha!");
							task.wait(2);
							if mission.Cache.Blockade then
								masonModule.Chat(masonModule.Owner, "Destroy the wooden barricades so we can go in.");
							end
							masonModule:ToggleInteractable(true);
						end
						
					elseif mission.ProgressionPoint >= 5 then
						masonModule.StopCarLoop();
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint < 6 then
								mission.ProgressionPoint = 6;
							end;
						end)

						masonModule.Actions:FollowOwner(function()
							return mission.Type == 1 and mission.ProgressionPoint >= 5;
						end);
					end
					
				elseif mission.Type == 3 then -- OnComplete
					masonModule.Actions:EnterDoor("warehouseEntrance");

					--masonModule.Movement:Move(Vector3.new(51.2800293, 57.6597404, 40.0281067));
					if not firstRun then
						masonModule.Move:MoveTo(Vector3.new(51.2800293, 57.6597404, 40.0281067));
						masonModule.Chat(masonModule.Owner, "Good work, "..masonModule.Owner.Name.."!");
					end
					masonModule.CarLoop();

				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)
		
		
	elseif modBranchConfigs.IsWorld("Factory") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then return end;

			if not modMission:IsComplete(player, 12) then
				local masonModule = modNpcs.get(player, "Mason");
				if masonModule == nil then
					local npc = modNpcs.spawn("Mason", CFrame.new(63.452, 45.89, 3.248, 0, 0, 1, 0, 1, 0, -1, 0, 0), function(npc, npcModule)
						npcModule.Owner = player;
						masonModule = npcModule;
					end);
					modReplicationManager.ReplicateOut(player, npc);
				end

				masonModule:ToggleInteractable(false);
				masonModule.Move:SetMoveSpeed("set", "default", 12);
				
				masonModule.Wield.Equip("revolver454");
				
				masonModule.Actions:FollowOwner(function()
					if masonModule.Target then
						local enemyHumanoid = masonModule.Target:FindFirstChildWhichIsA("Humanoid");
						if enemyHumanoid and enemyHumanoid.Health > 0 and enemyHumanoid.RootPart and masonModule.IsInVision(enemyHumanoid.RootPart) then
							pcall(function()
								masonModule.Wield.ToolModule.Configurations.MinBaseDamage = math.max(80, enemyHumanoid.MaxHealth*0.3);
							end);
							masonModule.Wield.SetEnemyHumanoid(enemyHumanoid);
							masonModule.Move:Face(enemyHumanoid.RootPart);
							masonModule.Wield.PrimaryFireRequest();
							
						else
							masonModule.Target = nil;
						end
					end
					
					return mission.Type == 1 and (mission.ProgressionPoint >= 3 or mission.ProgressionPoint <= 5);
				end);
				

				local function OnChanged()
					if mission.Type == 1 and mission.ProgressionPoint == 5 then
						masonModule:ToggleInteractable(true);
						masonModule.Wield.Unequip();
					end
				end
				mission.OnChanged:Connect(OnChanged);
			end
		end)
		
	else
		return;
	end
	
	return CutsceneSequence;
end;