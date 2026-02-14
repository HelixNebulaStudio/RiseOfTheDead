local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService");
local Configurations = require(ReplicatedStorage.Library.Configurations)

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 73;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modCoopMission = shared.require(game.ServerScriptService.ServerLibrary.CoopMission);
	modFactions = shared.require(game.ServerScriptService.ServerLibrary.Factions);

	shared.modEventService:OnInvoked("Npcs_BindDeath", function(event: EventPacket, ...) 
		local npcClass: NpcClass = ...;
		if npcClass == nil then return end;
		
		local coopData = npcClass.Properties.CoopId;
		if coopData == nil then return end;
		
		local coopMission = modCoopMission:Get(coopData.GroupId, coopData.MissionId) or nil;
		if coopMission == nil then return end;
		
		modMission:CompleteMission(coopMission:GetPlayers(), MISSION_ID);
		coopMission:Destroy();
	end)
	

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
	if not modBranchConfigurations.IsWorld("Safehome") and not RunService:IsStudio() then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
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
		
		local activeBossNpcClass: NpcClass = nil;

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
					
					
					if activeBossNpcClass then
						activeBossNpcClass:Destroy();
						Debugger.Expire(activeBossNpcClass.Character, 0);
					end
					
					local bossSpawnCf = workspace:FindFirstChildWhichIsA("SpawnLocation").CFrame * CFrame.new(0, 10, 0);
					activeBossNpcClass = modNpcs.spawn2{
						Name = pickBossName;
						CFrame = bossSpawnCf;
						BindSetup = function(npcClass: NpcClass)
							npcClass.Name = "Zenith ".. tostring(pickBossName);

							local configuration = npcClass.Configurations;
							configuration.BaseValues.AttackDamage = 1;

							local properties = npcClass.Properties;
							properties.TargetableDistance = 4096;
							properties.CrateId = "zenithcrate";
							properties.CoopId = {GroupId=factionTag; MissionId=MISSION_ID;};


							local npcChar = npcClass.Character;
							npcChar:SetAttribute("Soundtrack", "Soundtrack:StadiumOfDreams");
							npcChar:SetAttribute("EntityHudHealth", true);

							local maxHpVal = 5000000;
							if RunService:IsStudio() then
								maxHpVal = 100000;
							end
							npcClass.HealthComp:SetMaxHealth(maxHpVal);
							npcClass.HealthComp:Reset();
							
							if properties.Immunity == nil or properties.Immunity <= 1 then
								properties.Immunity = 0.7;
							end
							properties.WeakenImmunity = 0.8;
							properties.DisabledImmunity = 0.5;

							if npcClass:GetComponent("BlinkTeleport") == nil then
								npcClass:AddComponent("BlinkTeleport");
							end

							-- task.spawn(function()
							-- 	npcModule.LastBlinkUse = tick();
							-- 	npcModule.LastForceBlink = tick();
							-- 	while true do
							-- 		task.wait(1);
							-- 		if not workspace:IsAncestorOf(npc) or npcModule.Humanoid.Health <= 0 then
							-- 			break;
							-- 		end
									
							-- 		if tick()-npcModule.LastForceBlink >= 10 then
							-- 			npcModule.LastForceBlink = tick();
							-- 			if npcModule.Enemy and npcModule.Enemy.Humanoid then
							-- 				npcModule.Blink(npcModule.Enemy.Humanoid);
							-- 			end
										
							-- 		elseif tick()-npcModule.LastDamageTaken >= 3 and tick()-npcModule.LastBlinkUse >= 3 then
							-- 			npcModule.LastBlinkUse = tick();
							-- 			if npcModule.Enemy and npcModule.Enemy.Humanoid then
							-- 				npcModule.Blink(npcModule.Enemy.Humanoid);
							-- 			end
										
							-- 		end
							-- 	end
								
							-- end)
							
							npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
								if not isDead then return end;
								if npcClass:GetComponent("CrateReward") == nil then return end;
								
								local coopPlayers = coopMission:GetPlayers();
								local selectCoopPlayer = coopPlayers[math.random(1, #coopPlayers)];
								local playerClass: PlayerClass = shared.modPlayers.get(selectCoopPlayer);

								local spawnCFrame;
								if spawnCFrame == nil then
									local _dropRayHit, dropRayPos = workspace:FindPartOnRayWithWhitelist(Ray.new(properties.DeathPosition, Vector3.new(0, -32, 0)), {workspace.Environment; workspace.Terrain}, true);
									spawnCFrame = CFrame.new(dropRayPos);
								end

								if playerClass and spawnCFrame == nil then
									local _dropRayHit, dropRayPos = workspace:FindPartOnRayWithWhitelist(Ray.new(playerClass:GetCFrame().Position, Vector3.new(0, -32, 0)), {workspace.Environment; workspace.Terrain}, true);
									spawnCFrame = CFrame.new(dropRayPos);
								end

								spawnCFrame = spawnCFrame * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);

								local _cratePrefab, _crateInteractable = npcClass:GetComponent("CrateReward")(spawnCFrame, coopPlayers);
							end)
						end
					};

					local targetHandlerComp = activeBossNpcClass:GetComponent("TargetHandler");
					activeBossNpcClass:GetComponent("Blink")();
					task.spawn(function()
						while true do
							task.wait(3);
							if activeBossNpcClass.HealthComp.IsDead then
								break;
							end
							
							for _, player in pairs(coopMission:GetPlayers()) do
								if player.Character == nil then continue end;
								targetHandlerComp:AddTarget(player.Character);
							end
							
							local configurations = activeBossNpcClass.Configurations;
							configurations.BaseValues.AttackDamage = math.clamp(configurations.BaseValues.AttackDamage +1, 1, 100);
						end
					end)
					
				end
				
			elseif coopMission.Type == 4 then

				coopMission:ForEachPlayer(function(player)
					Debugger:Warn("failing ", player);
					modMission:FailMission(player, MISSION_ID, coopMission.FailReason);
					
					if activeBossNpcClass then
						activeBossNpcClass:Destroy();
						Debugger.Expire(activeBossNpcClass.Character, 0);
						activeBossNpcClass = nil;
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