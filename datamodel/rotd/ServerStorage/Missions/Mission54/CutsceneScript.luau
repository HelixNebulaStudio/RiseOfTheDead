local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);

--== Variables;
local MISSION_ID = 54;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
	modSafehomeService = shared.require(game.ServerScriptService.ServerLibrary.SafehomeService);

else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigurations.IsWorld("Safehome") or workspace:GetAttribute("FactionHeadquarters") ~= nil then
		Debugger:Warn("Invalid place for cutscene ("..script.Name..")");

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;

			if mission.Type == 1 and mission.ProgressionPoint > 1 then
				modMission:Progress(player, MISSION_ID, function(mission)
					mission.ProgressionPoint = 1;
				end)
			end
		end)
		return;
	end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
		
		while shared.WorldCore.SafehomeClass == nil do
			task.wait(1);
			Debugger:Log("Waiting for safehome class.");
		end

		local safehomeClass = shared.WorldCore.SafehomeClass;
		while safehomeClass.Owner ~= modServerManager.PrivateWorldCreator do
			wait(1);
			Debugger:Log("Waiting for private world creator.");
		end

		modConfigurations.Set("InfTargeting", true);

		local masonSpawnAtt = safehomeClass:GetNpcSpot("Mason");

		local masonNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Mason");
		if masonNpcClass == nil then
			masonNpcClass = modNpcs.spawn2{
				Name = "Mason";
				CFrame = masonSpawnAtt.WorldCFrame;
				Player = player;
			};
		end
		

		local enemySpawns = {};
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				
				if mission.ProgressionPoint == 2 then
					masonNpcClass:SetCFrame(CFrame.new(112.371384, 2.57112098, -88.6676178, 0, 0, 0.999999285, 0, 1, 0, -1, 0, 0));

				elseif mission.ProgressionPoint == 3 then
					masonNpcClass:SetCFrame(CFrame.new(112.371384, 2.57112098, -88.6676178, 0, 0, 0.999999285, 0, 1, 0, -1, 0, 0));
					masonNpcClass.Move:MoveTo(Vector3.new(83.326, 2.571, -79.19));
					masonNpcClass.Move.OnMoveToEnded:Wait(20);
					
					task.wait(0.5);

					local doorConfig = workspace.Environment.Game:WaitForChild("FrontDoubleDoors"):WaitForChild("Door");
					local frontDoors = modDoors.getOrNew(doorConfig);
					frontDoors:Toggle(true);
					masonNpcClass.PlayAnimation("OpenDoor");

					task.wait(1);

					modAudio.Play("HordeGrowl", workspace);

					masonNpcClass.Move:Face(Vector3.new(1000, 0, 0));
					task.wait(1);
					
					masonNpcClass.Chat(player, "Hmmmm, sounds like a horde is roaming this way..");
					task.wait(3);
					
					masonNpcClass.Move:Face("Player");
					masonNpcClass.Chat(player, "We better be ready to defend. Go inside and look for ammo.");

					task.wait(3);
					masonNpcClass.Move:MoveTo(Vector3.new(61.968, 2.59, -79.037));
					masonNpcClass.Move.OnMoveToEnded:Wait(20);
					
					task.wait(0.3);
					masonNpcClass.Move:Face(Vector3.new(1000, 0, 0));

					masonNpcClass.Chat(player, "I'll watch your back..");
					masonNpcClass.WieldComp:Equip{
						ItemId = "revolver454";
						OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
							if toolHandler.EquipmentClass == nil then return end;
							local equipmentClass: EquipmentClass = toolHandler.EquipmentClass;
							
							local modifier: ConfigModifier = equipmentClass.Configurations.newModifier("npcDmg");
							modifier.SetValues.Damage = 35;
							modifier.Priority = 999;
							equipmentClass.Configurations:AddModifier(modifier, true);
						end;
					};

					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 3 then
							mission.ProgressionPoint = 4;
						end;
					end)

				elseif mission.ProgressionPoint == 4 then

					masonNpcClass:GetComponent("ProtectPlayer")();
					masonNpcClass:GetComponent("FollowPlayer")(nil, function() 
						return mission.ProgressionPoint == 4;
					end);

					task.wait(5);

					local playerClass: PlayerClass = shared.modPlayers.get(player);

					local allSpawned = false;
					local function spawnEnemy(enemyName, spawnPoint)
						local zombieNpcClass: NpcClass = modNpcs.spawn2{
							Name = enemyName;
							CFrame = spawnPoint;

							BindSetup = function(npcClass: NpcClass)
								table.insert(enemySpawns, npcClass);

								npcClass.HealthComp.OnIsDeadChanged:Connect(function()
									for a=#enemySpawns, 1, -1 do
										if enemySpawns[a] == npcClass then
											table.remove(enemySpawns, a);
										end
									end

									Debugger:StudioWarn(`allSpawned`, allSpawned, `#enemySpawns`, #enemySpawns);
									if allSpawned and #enemySpawns <= 0 then
										Debugger:Warn("Progress mission 54 ProgressionPoint 5");
										modMission:Progress(player, MISSION_ID, function(mission)
											if mission.ProgressionPoint == 4 then
												mission.ProgressionPoint = 5;
											end;
										end)
									end
								end)

							end
						};

						zombieNpcClass.Properties.HordeAggression = true;
						zombieNpcClass.Properties.TargetableDistance = 4096;

						local targetHandlerComp = zombieNpcClass:GetComponent("TargetHandler");
						targetHandlerComp:AddTarget(playerClass.Character);

						zombieNpcClass.OnThink:Fire();
					end

					for a=1, 120 do
						local newSpawnCf: CFrame = safehomeClass:GetSpawnPlatform(
							Vector3.new(3, 6, 1),
							function(spawnPlatformPart)
								return spawnPlatformPart.Name == "Outside"; 
							end
						);

						while #enemySpawns > 60 do
							task.wait(0.1);
						end

						task.spawn(spawnEnemy, "Zombie", newSpawnCf);
						task.wait(1);
					end
					allSpawned = true;

				elseif mission.ProgressionPoint == 5 then
					masonNpcClass.Chat(player, "Great, that should be the last of them.");
					masonNpcClass.WieldComp:Unequip();
					masonNpcClass:GetComponent("FollowPlayer").FollowingPlayer = nil;
					
					masonNpcClass.Move:Stop();

					task.wait(0.5);
					masonNpcClass:SetCFrame(CFrame.new(55.8925056, 2.71029401, -52.6312675, 0, 0, 0.999999821, 0, 1, 0, -1, 0, 0));

				end
				
				
			elseif mission.Type == 3 then -- OnComplete
				masonNpcClass.PlayAnimation("CrossedArm");

			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;