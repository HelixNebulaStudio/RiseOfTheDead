local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 71;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if modBranchConfigs.IsWorld("MainMenu") then return end;

	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
		
		local profile = shared.modProfile:Get(player);
		local banditSpawned = {};

		local function endMission()
			local inventory = profile.ActiveInventory;
			local total, itemList = inventory:ListQuantity("highvaluepackage", 1);

			if total > 0 then
				for a=1, #itemList do
					inventory:Remove(itemList[a].ID, itemList[a].Quantity);
				end
			end

			for _, npc in pairs(banditSpawned) do
				if workspace:IsAncestorOf(npc) then
					npc:Destroy();
				end
			end
		end

		task.spawn(function()

			while game.Players:IsAncestorOf(player) do
				task.wait(1);
			end

			for _, npc in pairs(banditSpawned) do
				if workspace:IsAncestorOf(npc) then
					npc:Destroy();
				end
			end
		end)

		local checkLoop = false;
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable

			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then

				elseif mission.ProgressionPoint == 2 then
					local classPlayer = shared.modPlayers.get(player);

					local spawnCfs = {};
					task.delay(5, function()
						checkLoop = true;

						local lastSpawnTick;
						while checkLoop do
							if not game.Players:IsAncestorOf(player) then return; end;
							if lastSpawnTick == nil or tick() > lastSpawnTick then
								if lastSpawnTick == nil then
									lastSpawnTick = tick()+math.random(3,4);

								else
									lastSpawnTick = tick()+math.random(14,32);

								end
								table.insert(spawnCfs, classPlayer.RootPart.CFrame);

								if #banditSpawned > 3 then continue end;
								if profile and classPlayer and classPlayer.IsAlive and classPlayer.Properties.InBossBattle == nil then
									local lastDoorCf = spawnCfs[math.random(1, #spawnCfs)] or profile.LastDoorCFrame;

									modNpcs.spawn("Bandit", profile.LastDoorCFrame, function(npc, npcModule)
										npcModule.Properties.TargetableDistance = 4096;
										npcModule.OnTarget(player);
										npcModule.Properties.AttackDamage = 500;

										function npcModule.CantFollow(destination)
											npcModule.Prefab:Destroy();
										end
										Debugger.Expire(npcModule.Prefab, 60);
										table.insert(banditSpawned, npc);
									end);
								end
							end

							if mission.ProgressionPoint ~= 2 or mission.Type ~= 1 then
								break;
							end
							if classPlayer.IsAlive == false then
								task.delay(1, function()
									modMission:FailMission(player, MISSION_ID, "You died and the high value package was stolen.");
								end)
								endMission();
								break;
							end
							task.wait(0.1);
						end
					end)

					local targetNpcName = string.split(mission.SaveData.TargetPlace, " ")[1];
					
					if targetNpcName == "Diana" then
						Debugger:Warn("Diana walk out");

						local dianaModule = modNpcs.getByOwner(player, "Diana");
						if dianaModule then
							dianaModule.StopAnimation("Idle");

							dianaModule.InCutscene = true;
							dianaModule.Actions:Teleport(CFrame.new(-130.710892, 10.5228786, 284.348938, 0, 0, -1, 0, 1, 0, 1, 0, 0));
							dianaModule.Move:MoveTo(Vector3.new(-137.6, 10.5, 275.6));
							dianaModule.Move.MoveToEnded:Wait(5);
							
							wait(0.3);
							dianaModule.Actions:Teleport(CFrame.new(-136.80545, 10.5228777, 268.696259, 0.866, 0, -0.500000954, 0, 1, 0, 0.500000954, 0, 0.866024852));
							dianaModule.Move:MoveTo(Vector3.new(-123.7, 10.5, 276.9));
							dianaModule.Move.MoveToEnded:Wait(5);
							dianaModule.Move:Face(Vector3.new(-118.4, 10.5, 276.9));
						end


					elseif targetNpcName == "Frank" then
						Debugger:Warn("Frank walk out");
						player:SetAttribute("FrankStandsOutside", true);
						
					end

				end

			elseif mission.Type == 3 then -- OnComplete		
				player:SetAttribute("FrankStandsOutside", nil);
				endMission();
				
			elseif mission.Type == 4 then -- OnFail/Abort
				player:SetAttribute("FrankStandsOutside", nil);
				endMission();

			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;