local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);

--== Variables;
local missionId = 78;

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	local killDialogues = {
		"Boom! Sit down zombies!";
		"Not today buddy!";
		"This is what you get for ruining my life!";
		"The dead shouldn't be moving!";
		"Your fate is decided by me zombies!";
		"A bullet to your face is your destiny zombies!";
		"Zombie, meet lead. Lead, meet zombie!";
		"You're not so scary now, are you?";
		"This is too much fun!";
		"I'm the one who knocks... zombies out!";
		"I will be the savior of the human race!";
		"I am the best survivor!";
	};

	if modBranchConfigs.IsWorld("Safehome") or modBranchConfigs.IsWorld("BioXResearch") then
		modOnGameEvents:ConnectEvent("OnZombieDeath", function(npcModule)
			local killerTags = modDamageTag:Get(npcModule.Prefab);
	
			for a=1, #killerTags do
				local tag = killerTags[a];
				if tag.Player then 
					modMission:Progress(tag.Player, missionId, function(mission)
						if mission.ProgressionPoint == 3 then
							local lydiaNpcModule = modNpc.GetPlayerNpc(tag.Player, "Lydia");
							if lydiaNpcModule then
								if mission.SaveData.PlayerKills == 4 then
									lydiaNpcModule.Chat(lydiaNpcModule.Owner, "Hmm, I see..");
								elseif mission.SaveData.PlayerKills == 2 then
									lydiaNpcModule.Chat(lydiaNpcModule.Owner, "Okay, seems simple enough..");
								end
							end
							
							mission.SaveData.PlayerKills = math.max(mission.SaveData.PlayerKills -1, 0);
							
							if mission.SaveData.PlayerKills <= 0 then
								mission.ProgressionPoint = 4;
								lydiaNpcModule.Chat(lydiaNpcModule.Owner, "Okay, let me give this a try..");
							end
						end
					end)
	
				else
					local lydiaNpcModule = modNpc.GetNpcModule(tag.Prefab);
					if lydiaNpcModule == nil or lydiaNpcModule.Name ~= "Lydia" then continue end;
		
					for _, player in pairs(game.Players:GetPlayers()) do
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint == 4 then
								if lydiaNpcModule and mission.SaveData.LydiaKills > 0 and math.fmod(mission.SaveData.LydiaKills, 2) == 0 then
									lydiaNpcModule.Chat(lydiaNpcModule.Owner, killDialogues[math.random(1, #killDialogues)]);
								end
								mission.SaveData.LydiaKills = math.max(mission.SaveData.LydiaKills -1, 0);
								
								if mission.SaveData.LydiaKills <= 0 then
									mission.ProgressionPoint = 5;
								end
							end
						end)
					end
	
				end;
			end
		end);
		
		modOnGameEvents:ConnectEvent("OnStorageChanged", function(player, storage)
			modMission:Progress(player, missionId, function(mission)
				if mission.Type == 1 and mission.ProgressionPoint == 1 and storage.Id == "LydiaStorage" then
					local storageItemIndexList = storage:GetIndexDictionary();
					
					if storageItemIndexList[1] or storageItemIndexList[2] then
						mission.ProgressionPoint = 2;
						storage.Locked = true;

						local lydiaNpcModule = modNpc.GetPlayerNpc(player, "Lydia");
						if lydiaNpcModule then
							lydiaNpcModule.Chat(lydiaNpcModule.Owner, "Yay, let's go zombies hunting!");
						end
					end
				end
			end)
		end)
		
	end
else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("Safehome") and not modBranchConfigs.IsWorld("BioXResearch") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, missionId);
		if mission == nil then return end;
			
		local lydiaModule;
		
		local function OnChanged(firstRun)
			if lydiaModule == nil then
				lydiaModule = modNpc.GetPlayerNpc(player, "Lydia");
			end
			if lydiaModule == nil then
				Debugger:Warn("Missing lydia module.");
				return;
			end;

			local profile = shared.modProfile:Get(player);
			local safehomeData = profile.Safehome;
			
			local npcData = safehomeData:GetNpc("Lydia");

			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then

				elseif mission.ProgressionPoint == 2 then
					task.wait(4);

					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint == 2 then
							mission.SaveData.LydiaKills = 10;
							mission.SaveData.PlayerKills = 5;
							mission.ProgressionPoint = 3;
						end
					end)
					
				elseif mission.ProgressionPoint == 3 then
					local hordeSpawnPart = workspace:FindFirstChild("HostileSpawnPart")
					local spawnPoints = hordeSpawnPart:GetChildren();

					task.spawn(function()
						while mission.ProgressionPoint <= 4 do
							local pickSpawnAtt = spawnPoints[math.random(1, #spawnPoints)];

							modNpc.Spawn("Zombie", pickSpawnAtt.WorldCFrame, function(npcPrefab, npcModule)
								npcModule.InfTargeting = true;

								if mission.ProgressionPoint == 3 then
									npcModule.OnTarget({player});

								else
									npcModule.OnTarget({lydiaModule.Prefab; player});
									
								end
							end)

							task.wait(math.random(5, 20));
						end
					end)

					repeat task.wait() until lydiaModule.Wield.ToolModule ~= nil;
					
					lydiaModule.Chat(lydiaModule.Owner, "Wow, it's quite heavy..");
					lydiaModule.Wield:ToggleIdle();
					
					lydiaModule.Actions:FollowOwner(function()
						if mission.ProgressionPoint >= 4 then
							local attractedEntities = modNpc.AttractEnemies(lydiaModule.Prefab, 32, function(npcModule)
								return npcModule.Name == "Zombie" and npcModule.IsDead ~= true;
							end);
							
							if #attractedEntities > 0 then
								local pickEnemyPrefab: Actor = attractedEntities[math.random(1, #attractedEntities)];
								local zombieNpcModule = modNpc.GetNpcModule(pickEnemyPrefab);
								local isInVision = lydiaModule.IsInVision(pickEnemyPrefab.PrimaryPart);
	
								if isInVision and zombieNpcModule.IsDead ~= true then
									pcall(function()
										local dmg = math.clamp(100/(lydiaModule.Wield.ToolModule.Properties.Rpm/60), 5, 30);
										lydiaModule.Wield.ToolModule.Configurations.MinBaseDamage = dmg;
									end)

									lydiaModule.Wield.SetEnemyHumanoid(zombieNpcModule.Humanoid);
									lydiaModule.Move:Face(zombieNpcModule.Humanoid.RootPart);
									lydiaModule.Wield.PrimaryFireRequest();
								end
							else
								lydiaModule.Wield.ReloadRequest();
							end

						else
							lydiaModule.Move:Face(player.Character and player.Character.PrimaryPart);

						end
						
						return mission.ProgressionPoint <= 6 and mission.Type == 1;
					end)

				elseif mission.ProgressionPoint == 5 then
					task.spawn(function()
						local timeOutTick = tick();
						while mission.ProgressionPoint == 4 do
							local npcModuleList = modNpc.ListEntities("Zombie");
							if #npcModuleList <= 0 then
								break;
							elseif tick()-timeOutTick >= 30 then
								break;
							else
								task.wait(1);
							end
						end

						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint == 5 then
								lydiaModule.Chat(lydiaModule.Owner, "Wow, that was fun!");
								mission.ProgressionPoint = 6;
							end
						end)
					end)

				end
			elseif mission.Type == 3 then -- OnComplete


			end
		end
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;