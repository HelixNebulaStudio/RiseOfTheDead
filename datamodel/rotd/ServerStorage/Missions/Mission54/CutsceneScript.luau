local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);

--== Variables;
local MISSION_ID = 54;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	--if not modBranchConfigs.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	if not modBranchConfigs.IsWorld("Safehome") or workspace:GetAttribute("FactionHeadquarters") ~= nil then
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
		
		
		while not shared.modSafehomeService.MapLoaded do
			wait(1);
			Debugger:Log("Waiting for safehome map to load..");
		end

		while modServerManager.PrivateWorldCreator == nil do
			wait(1);
			Debugger:Log("Waiting for private world creator.");
		end

		modConfigurations.Set("InfTargeting", true);

		CutsceneSequence:NextScene("updateConfig");

		local isOwner = modServerManager.PrivateWorldCreator == player;
		if not isOwner then return end;

		local masonSpawn = shared.modSafehomeService.GetNpcSpot("Mason");
		local masonModule = modNpcs.getPlayerNpc(player, "Mason");
		if masonModule == nil then
			local npc = modNpcs.spawn("Mason", nil, function(npc, npcModule)
				npcModule.Player = player;
				masonModule = npcModule;
			end);
			modReplicationManager.ReplicateOut(player, npc);
		end
		
		
		local spawnZonePart = script:WaitForChild("spawnZone");

		local worldSpaceSize = spawnZonePart.CFrame:vectorToWorldSpace(spawnZonePart.Size);
		worldSpaceSize = Vector3.new(math.abs(worldSpaceSize.X), math.abs(worldSpaceSize.Y), math.abs(worldSpaceSize.Z));

		local pointMin = Vector3.new(spawnZonePart.Position.X-worldSpaceSize.X/2, spawnZonePart.Position.Y-worldSpaceSize.Y/2, spawnZonePart.Position.Z-worldSpaceSize.Z/2);
		local pointMax = Vector3.new(spawnZonePart.Position.X+worldSpaceSize.X/2, spawnZonePart.Position.Y+worldSpaceSize.Y/2, spawnZonePart.Position.Z+worldSpaceSize.Z/2);


		local spawnRegion = {Min=pointMin; Max=pointMax;};
		local centerPos = spawnZonePart.Position;

		local function randomPointOnCircle()
			local angle = math.random()*math.pi*2;
			return centerPos+Vector3.new(math.cos(angle)*(worldSpaceSize.X/2), 128, math.sin(angle)*(worldSpaceSize.Z/2));
		end

		local enemySpawns = {};
		
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				
				if mission.ProgressionPoint == 2 then
					masonModule.Actions:Teleport(CFrame.new(112.371384, 2.57112098, -88.6676178, 0, 0, 0.999999285, 0, 1, 0, -1, 0, 0));

				elseif mission.ProgressionPoint == 3 then

					masonModule.Actions:Teleport(CFrame.new(112.371384, 2.57112098, -88.6676178, 0, 0, 0.999999285, 0, 1, 0, -1, 0, 0));
					masonModule.Move:MoveTo(Vector3.new(83.326, 2.571, -79.19));
					masonModule.Move.OnMoveToEnded:Wait(20);
					
					task.wait(0.5);
					local frontDoors = shared.require(workspace.Environment.Game:WaitForChild("FrontDoubleDoors"):WaitForChild("Door"));
					frontDoors:Toggle(true);
					task.wait(1);

					modAudio.Play("HordeGrowl", workspace);

					masonModule.Move:Face(Vector3.new(1000, 0, 0));
					task.wait(1);
					
					masonModule.Chat(player, "Hmmmm, sounds like a horde is roaming this way..");
					task.wait(3);
					
					masonModule.Actions:FaceOwner();
					masonModule.Chat(player, "We better be ready to defend. Go inside and look for ammo.");

					wait(3);
					masonModule.Move:MoveTo(Vector3.new(61.968, 2.59, -79.037));
					masonModule.Move.OnMoveToEnded:Wait(20);
					
					wait(0.3);
					masonModule.Move:Face(Vector3.new(1000, 0, 0));

					masonModule.Chat(player, "I'll watch your back..");

					masonModule.Wield.Equip("revolver454");
					pcall(function()
						masonModule.Wield.ToolModule.Configurations.MinBaseDamage = 35;
						masonModule.Wield.ToolModule.Properties.Ammo = 0;
					end);

					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 3 then
							mission.ProgressionPoint = 4;
						end;
					end)

				elseif mission.ProgressionPoint == 4 then

					masonModule.Actions:FollowOwner(function()
						if masonModule.Target then
							local enemyHumanoid = masonModule.Target:FindFirstChildWhichIsA("Humanoid");
							if enemyHumanoid and enemyHumanoid.Health > 0 and enemyHumanoid.RootPart and masonModule.IsInVision(enemyHumanoid.RootPart) then
								masonModule.Wield.SetEnemyHumanoid(enemyHumanoid);
								masonModule.Move:Face(enemyHumanoid.RootPart);
								masonModule.Wield.PrimaryFireRequest();
							else
								masonModule.Target = nil;
							end
						end
						return mission.ProgressionPoint == 4;
					end);

					task.wait(5);

					local allSpawned = false;
					local function spawnEnemy(enemyName, spawnPoint)
						modNpcs.spawn(enemyName, spawnPoint, function(npc, npcModule)
							table.insert(enemySpawns, npcModule);

							npcModule.SetAggression = 3;

							npcModule.Configuration.Level = 1;
							npcModule.ForgetEnemies = false;
							npcModule.AutoSearch = true;
							npcModule.Properties.TargetableDistance = 4096;
							npcModule.OnTarget(player);

							npcModule.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject;
							npcModule.Humanoid.Health = npcModule.Humanoid.MaxHealth;

							local isAlive = true;
							npcModule.Humanoid.Died:Connect(function()
								isAlive = false;
								for a=#enemySpawns, 1, -1 do
									if enemySpawns[a] == npcModule then
										table.remove(enemySpawns, a);
									end
								end

								if allSpawned and #enemySpawns <= 0 then
									Debugger:Warn("Progress mission 54 ProgressionPoint 5");
									modMission:Progress(player, MISSION_ID, function(mission)
										if mission.ProgressionPoint == 4 then
											mission.ProgressionPoint = 5;
										end;
									end)
								end

								npcModule.DeathPosition = npcModule.RootPart.CFrame.p;
								Debugger.Expire(npc, 10);
							end);

							task.spawn(function()
								while true do
									task.wait(120);
									if not isAlive then return; end;
									if npcModule.RootPart then
										npcModule.RootPart.CFrame = spawnPoint;
									end
								end	
							end)
						end);
					end

					for a=1, 50 do
						local randPos = randomPointOnCircle();

						local groundRay = Ray.new(randPos, Vector3.new(0, -256, 0));
						local groundHit, groundPoint = workspace:FindPartOnRayWithWhitelist(groundRay, {workspace.Environment; workspace.Terrain}, true);

						--Debugger:PointPart(randPos);
						if groundHit then
							local newSpawn = CFrame.new(groundPoint) * CFrame.new(0, 3, 0);
							spawnEnemy("Zombie", newSpawn);
						else
							Debugger:Log("ray miss", randPos);
						end
						task.wait(0.1);
					end
					allSpawned = true;

				elseif mission.ProgressionPoint == 5 then
					masonModule.Chat(player, "Great, that should be the last of them.");
					masonModule.Wield.Unequip();
					masonModule.Move:Stop();
					task.wait(0.5);
					masonModule.Actions:Teleport(CFrame.new(55.8925056, 2.71029401, -52.6312675, 0, 0, 0.999999821, 0, 1, 0, -1, 0, 0));

				end
				
				
			elseif mission.Type == 3 then -- OnComplete

				masonModule.PlayAnimation("CrossedArm");

			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)

	CutsceneSequence:NewScene("updateConfig", function()
		modConfigurations.Set("AutoMarkEnemies", true);
	end);
	
	return CutsceneSequence;
end;