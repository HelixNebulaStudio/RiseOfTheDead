local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

--== Variables;
local MISSION_ID = 78;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
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

		shared.modEventService:OnInvoked("Npcs_BindDeath", function(eventPacket: EventPacket, ...)
			local npcClass: NpcClass = ...;
			if npcClass == nil or npcClass.HumanoidType ~= "Zombie" then return end;
			
			local killerTags = modDamageTag:Get(npcClass.Character);
			for a=1, #killerTags do
				local killerTag = killerTags[a];

				if killerTag.Player then
					local player: Player = killerTag.Player;

					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 3 then
							local lydiaNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Lydia");
							if lydiaNpcClass then
								if mission.SaveData.PlayerKills == 4 then
									lydiaNpcClass.Chat(lydiaNpcClass.Player, "Hmm, I see..");
								elseif mission.SaveData.PlayerKills == 2 then
									lydiaNpcClass.Chat(lydiaNpcClass.Player, "Okay, seems simple enough..");
								end
							end
							
							mission.SaveData.PlayerKills = math.max(mission.SaveData.PlayerKills -1, 0);
							
							if mission.SaveData.PlayerKills <= 0 then
								mission.ProgressionPoint = 4;
								lydiaNpcClass.Chat(lydiaNpcClass.Player, "Okay, let me give this a try..");
							end
						end
					end)

				elseif killerTag.Prefab then
					local lydiaNpcClass: NpcClass = modNpcs.getByPrefab(killerTag.Prefab);
					if lydiaNpcClass == nil or lydiaNpcClass.Name ~= "Lydia" then continue end;

					for _, player in pairs(game.Players:GetPlayers()) do
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint == 4 then
								if lydiaNpcClass and mission.SaveData.LydiaKills > 0 and math.fmod(mission.SaveData.LydiaKills, 2) == 0 then
									lydiaNpcClass.Chat(lydiaNpcClass.Player, killDialogues[math.random(1, #killDialogues)]);
								end
								mission.SaveData.LydiaKills = math.max(mission.SaveData.LydiaKills -1, 0);
								
								if mission.SaveData.LydiaKills <= 0 then
									mission.ProgressionPoint = 5;
								end
							end
						end)
					end

				end
				
			end
		end)

		shared.modEventService:OnInvoked("Survivor_BindInventoryChanged", function(event: EventPacket, ...)
			local player: Player? = event.Player;
			if player == nil then return end;

			local npcClass: NpcClass, storage: Storage = ...;
			if storage.Id ~= "LydiaStorage" then return end;
						
			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.Type == 1 and mission.ProgressionPoint == 1 then
					local storageItemIndexList = storage:GetIndexDictionary();
					
					if storageItemIndexList[1] or storageItemIndexList[2] then
						mission.ProgressionPoint = 2;
						storage.Locked = true;

						npcClass.Chat(npcClass.Player, "Yay, let's go zombies hunting!");
					end
				end
			end)
		end)

	end
else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("Safehome") and not modBranchConfigs.IsWorld("BioXResearch") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		local lydiaNpcClass: NpcClass;
		
		local function OnChanged(firstRun)
			if lydiaNpcClass == nil then
				lydiaNpcClass = modNpcs.getPlayerNpc(player, "Lydia");
			end
			if lydiaNpcClass == nil then
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

					modMission:Progress(player, MISSION_ID, function(mission)
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

							local zombieNpcClass: NpcClass = modNpcs.spawn2{
								Name = "Zombie";
								CFrame = pickSpawnAtt.WorldCFrame * CFrame.new(0, 1.35, 0);
								BindSetup = function(npcClass: NpcClass)
									npcClass.Properties.TargetableDistance = 4096;
									npcClass.Properties.HordeAggression = true;
								end;
							};

							local zombieTargetHandlerComp = zombieNpcClass:GetComponent("TargetHandler");
							if mission.ProgressionPoint == 3 then
								zombieTargetHandlerComp:AddTarget(player.Character);
							else
								zombieTargetHandlerComp:AddTarget(lydiaNpcClass.Character);
							end
							
							task.wait(math.random(5, 20));
						end
					end)

					repeat task.wait() until lydiaNpcClass.WieldComp.ItemId ~= nil;
					
					lydiaNpcClass.Chat(lydiaNpcClass.Player, "Wow, it's quite heavy..");
					lydiaNpcClass.WieldComp:InvokeToolAction("ToggleIdle");
					
					lydiaNpcClass:GetComponent("ProtectPlayer")(nil, function()
						if mission.ProgressionPoint >= 4 then
							return true;

						else
							lydiaNpcClass.Move:Face(player.Character and player.Character.PrimaryPart);

						end
						
						return mission.ProgressionPoint <= 6 and mission.Type == 1;
					end);
					

				elseif mission.ProgressionPoint == 5 then
					task.spawn(function()
						local timeOutTick = tick();
						while mission.ProgressionPoint == 4 do
							local zombieNpcClasses = modNpcs.listNpcClasses(function(npcClass: NpcClass) 
								return npcClass.HumanoidType == "Zombie";
							end);
							if #zombieNpcClasses <= 0 then
								break;
							elseif tick()-timeOutTick >= 30 then
								break;
							else
								task.wait(1);
							end
						end

						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint == 5 then
								lydiaNpcClass.Chat(lydiaNpcClass.Player, "Wow, that was fun!");
								mission.ProgressionPoint = 6;
							end
						end)
					end)

				end
			elseif mission.Type == 3 then -- OnComplete


			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;