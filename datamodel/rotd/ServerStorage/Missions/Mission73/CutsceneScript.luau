local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 73;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	modCoopMission = shared.require(game.ServerScriptService.ServerLibrary.CoopMission);
	modFactions = shared.require(game.ServerScriptService.ServerLibrary.Factions);

	modOnGameEvents:ConnectEvent("OnNpcDeath", function(npcModule)
		local coopMission = npcModule.CoopId and modCoopMission:Get(npcModule.CoopId.GroupId, npcModule.CoopId.MissionId) or nil;
		if coopMission == nil then return end;
		
		modMission:CompleteMission(coopMission:GetPlayers(), MISSION_ID);
		coopMission:Destroy();
	end);
	

	shared.modPlayers.OnPlayerDied:Connect(function(playerClass: PlayerClass)
		local player = playerClass:GetInstance();

		Debugger:Warn("Player died", player.Name);

		local profile = shared.modProfile:Get(player);
		local factionTag = tostring(profile.Faction.Tag);


		local coopMission = modCoopMission:Get(factionTag, MISSION_ID);
		if coopMission == nil then Debugger:Warn("No coop mission OnPlayerDied"); return end;
		
		if coopMission.Type == 1 and coopMission.CheckPoint == 2 then
			Debugger:Warn("Fail coopMission", coopMission);
			coopMission:Fail(player.Name.." died fighting Prime "..coopMission.SaveData.BossName);
			coopMission:Destroy();
		end
	end)
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("Safehome") and not RunService:IsStudio() then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local hostPlayer = CutsceneSequence:GetPlayers()[1];
		local _cutscene = CutsceneSequence:GetCutscene();

		local profile = shared.modProfile:Get(hostPlayer);
		local factionTag = tostring(profile.Faction.Tag);
		
		Debugger:Warn("Load cutscene", hostPlayer);

		local coopMission = modCoopMission:Get(factionTag, MISSION_ID);
		if coopMission ~= nil then
			-- coopMission exist;
			coopMission:AddPlayer(hostPlayer);
			
			Debugger:Warn("coopMission Loaded ", coopMission);
			return;
		end
		
		
		coopMission = modCoopMission.new(factionTag, MISSION_ID);
		coopMission:AddPlayer(hostPlayer);
		
		local activeBossNpcModule = nil;

		local function OnChanged(firstRun, coopMission)
			Debugger:Warn("coopMission OnChanged ", coopMission);
			
			local checkPoint = coopMission.CheckPoint;
			
			if coopMission.Type == 1 then
				if checkPoint == 1 then
					
					coopMission:ForEachPlayer(function(player)
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 1;
						end)
					end)
					
					
				elseif checkPoint == 2 then
					if firstRun == true then
						coopMission:Progress(function()
							coopMission.CheckPoint = 1;
						end)
						return;
					end
					
					local pickBossName = {"Zomborg Prime"; "Hector Shot"};
					pickBossName = pickBossName[math.random(1, #pickBossName)];
					coopMission.SaveData.BossName = pickBossName;
					
					coopMission:ForEachPlayer(function(player)
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.SaveData.BossName = pickBossName;
							mission.ProgressionPoint = 2;
						end)
					end)
					
					
					if activeBossNpcModule then
						activeBossNpcModule:Destroy();
						Debugger.Expire(activeBossNpcModule.Prefab, 0);
					end
					
					local bossSpawnCf = workspace:FindFirstChildWhichIsA("SpawnLocation").CFrame * CFrame.new(0, 10, 0);
					modNpcs.spawn(pickBossName, bossSpawnCf, function(npc, npcModule)
						activeBossNpcModule = npcModule;

						npc:SetAttribute("Soundtrack", "Soundtrack:StadiumOfDreams");
						npc:SetAttribute("EntityHudHealth", true);
						
						npc.Name = "Zenith ".. tostring(pickBossName);
						
						npcModule.Configuration.CrateId = "zenithcrate";
						
						npcModule.Properties.TargetableDistance = 4096;
						npcModule.OnTarget(coopMission:GetPlayers());
						npcModule.Properties.AttackDamage = 1;
						
						npcModule.CoopId = {GroupId=factionTag; MissionId=MISSION_ID;};
						
						local maxHpVal = 5000000;
						if RunService:IsStudio() then
							maxHpVal = 100000;
						end
						npcModule.Humanoid.MaxHealth = maxHpVal;
						npcModule.Humanoid.Health = maxHpVal;
						
						if npcModule.Immunity == nil or npcModule.Immunity <= 1 then
							npcModule.Immunity = 0.7;
						end
						npcModule.WeakenImmunity = 0.8;
						npcModule.DisabledImmunity = 0.5;
						
						task.spawn(function()
							while true do
								task.wait(3);
								if not workspace:IsAncestorOf(npc) or npcModule.Humanoid.Health <= 0 then
									break;
								end
								
								npcModule.OnTarget(coopMission:GetPlayers());
								npcModule.Properties.AttackDamage = math.clamp(npcModule.Properties.AttackDamage +1, 1, 100);
							end
						end)
						task.spawn(function()
							npcModule.LastBlinkUse = tick();
							npcModule.LastForceBlink = tick();
							while true do
								task.wait(1);
								if not workspace:IsAncestorOf(npc) or npcModule.Humanoid.Health <= 0 then
									break;
								end
								
								if tick()-npcModule.LastForceBlink >= 10 then
									npcModule.LastForceBlink = tick();
									if npcModule.Enemy and npcModule.Enemy.Humanoid then
										npcModule.Blink(npcModule.Enemy.Humanoid);
									end
									
								elseif tick()-npcModule.LastDamageTaken >= 3 and tick()-npcModule.LastBlinkUse >= 3 then
									npcModule.LastBlinkUse = tick();
									if npcModule.Enemy and npcModule.Enemy.Humanoid then
										npcModule.Blink(npcModule.Enemy.Humanoid);
									end
									
								end
							end
							
						end)
						
						if npcModule.Blink == nil then
							npcModule:AddComponent(modNpcs.Script.Zombie.Blink);
						end
						npcModule.Humanoid.Died:Connect(function()
							npcModule.OnDeath();

							if npcModule.CrateReward then
								local coopPlayers = coopMission:GetPlayers();
								local selectCoopPlayer = coopPlayers[math.random(1, #coopPlayers)];
								local classPlayer = shared.modPlayers.get(selectCoopPlayer);

								local spawnCFrame;
								if spawnCFrame == nil then
									local _dropRayHit, dropRayPos = workspace:FindPartOnRayWithWhitelist(Ray.new(npcModule.DeathPosition, Vector3.new(0, -32, 0)), {workspace.Environment; workspace.Terrain}, true);
									spawnCFrame = CFrame.new(dropRayPos);
								end
								
								if classPlayer and classPlayer.SafeCFrame and spawnCFrame == nil then
									local _dropRayHit, dropRayPos = workspace:FindPartOnRayWithWhitelist(Ray.new(classPlayer.SafeCFrame.Position, Vector3.new(0, -32, 0)), {workspace.Environment; workspace.Terrain}, true);
									spawnCFrame = CFrame.new(dropRayPos);
								end

								spawnCFrame = spawnCFrame * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);

								local _cratePrefab, _crateInteractable = npcModule:CrateReward(spawnCFrame, coopPlayers);
							end
						end);
						
					end);
					
				end
				
			elseif coopMission.Type == 4 then

				coopMission:ForEachPlayer(function(player)
					Debugger:Warn("failing ", player);
					modMission:FailMission(player, MISSION_ID, coopMission.FailReason);
					
					if activeBossNpcModule then
						activeBossNpcModule:Destroy();
						Debugger.Expire(activeBossNpcModule.Prefab, 0);
						activeBossNpcModule = nil;
					end
				end)

				
			end
		end
		coopMission.OnChanged:Connect(OnChanged)
		OnChanged(true, coopMission);
		
		coopMission.OnPlayerAdded:Connect(function(player)
			modMission:Progress(player, MISSION_ID, function(mission)
				mission.Type = coopMission.Type;
				mission.SaveData.BossName = coopMission.SaveData.BossName;
				mission.ProgressionPoint = coopMission.CheckPoint;
			end)
		end)
	end)
	
	return CutsceneSequence;
end;