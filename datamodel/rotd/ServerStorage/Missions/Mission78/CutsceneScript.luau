local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

--== Variables;
local MISSION_ID = 78;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
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

	if modBranchConfigurations.IsWorld("Safehome") or modBranchConfigurations.IsWorld("BioXResearch") then

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
					local lydiaNpcClass: NpcClass = modNpcs.getByModel(killerTag.Prefab);
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

						npcClass.Chat(player, "Yay, let's go zombies hunting!");
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
	if shared.WorldName ~= "Safehome" and shared.WorldName ~= "BioXResearch" then 
		Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); 
		return;
	end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		local lydiaNpcClass: NpcClass;
		
		local checkpoint2 = false;
		local checkpoint3 = false;
		local checkpoint4 = false;
		local checkpoint5 = false;
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
					if checkpoint2 then return end;
					checkpoint2 = true;

					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 2 then
							mission.SaveData.LydiaKills = 10;
							mission.SaveData.PlayerKills = 5;
							mission.ProgressionPoint = 3;
						end
					end)
					
				elseif mission.ProgressionPoint == 3 then
					if checkpoint3 then return end;
					checkpoint3 = true;

					local safehomeClass = shared.WorldCore.SafehomeClass;

					task.spawn(function()
						while mission.ProgressionPoint <= 4 do
							local newSpawnCf: CFrame = safehomeClass:GetSpawnPlatform(
								Vector3.new(3, 6, 1),
								function(spawnPlatformPart)
									return spawnPlatformPart.Name == "Outside"; 
								end
							);

							local zombieNpcClass: NpcClass = modNpcs.spawn2{
								Name = "Zombie";
								CFrame = newSpawnCf;
								Properties = {
									TargetableDistance = 4096;
									HordeAggression = true;
								};
								BindSetup = function(npcClass: NpcClass)
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
					
					lydiaNpcClass.Chat(lydiaNpcClass.Player, "Wow, this piece of metal is quite heavy..");
					lydiaNpcClass.WieldComp:InvokeToolAction("ToggleIdle");
					
					lydiaNpcClass:GetComponent("FollowPlayer")(nil, function()
						if mission.ProgressionPoint <= 3 then
							if math.random(1, 100) == 1 then
								lydiaNpcClass.Move:Face(player.Character and player.Character.PrimaryPart);
							end
						end
						return mission.ProgressionPoint <= 6 and mission.Type == 1;
					end);
					

				elseif mission.ProgressionPoint == 4 then
					if checkpoint4 then return end;
					checkpoint4 = true;
					
					local attractNpcsComp = lydiaNpcClass:GetComponent("AttractNpcs");
					if attractNpcsComp then
						attractNpcsComp.AttractHumanoidType = {"Zombie"};
						attractNpcsComp.SelfAttractAlert = true;
						attractNpcsComp:Activate();
					end
					lydiaNpcClass:GetComponent("ProtectPlayer")();


				elseif mission.ProgressionPoint == 5 then
					if checkpoint5 then return end;
					checkpoint5 = true;

					task.spawn(function()
						local timeOutTick = tick();
						while mission.ProgressionPoint == 5 do
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
								lydiaNpcClass:GetComponent("ProtectPlayer").IsProtecting = false;
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