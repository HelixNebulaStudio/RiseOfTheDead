local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modInteractables = require(game.ReplicatedStorage.Library.Interactables);

--== Variables;
local missionId = 24;

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

	modOnGameEvents:ConnectEvent("OnItemPickup", function(player, interactData)
		if interactData.Type == modInteractables.Types.Collectible then
			local id = interactData.Id;
			if id ~= "rb" then return end;
			
			if modMission:Progress(player, missionId) then
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint <= 2 then
						mission.ProgressionPoint = 3;
					end;
				end)
			end
		end
	end);
	
else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule"));
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheUnderground") then return end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, missionId);
		if mission == nil then return end;
		
		local profile = shared.modProfile:Get(player);
		
		local banditZombie, banditInteractable;

		local function spawnEnemy()
			local npc = modNpc.Spawn("Bandit Zombie", CFrame.new(138.553329, 12.2096834, 87.6066055, 0, 0, 1, 0, 1, 0, -1, 0, 0), function(npc, npcModule)
				banditZombie = npcModule;
				banditZombie.NetworkOwners = {player};
				banditZombie.Prefab:SetAttribute("LookAtClient", false);
				banditZombie.IgnoreScan = true;
				banditInteractable = script:WaitForChild("banditZombieInteractable"):Clone();
				banditInteractable.Name = "Interactable";
				banditInteractable.Parent = npc;
			end);
			modReplicationManager.ReplicateOut(player, npc);
		end
		
		local function OnChanged(firstRun)
			if mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 2 then
					if profile.Collectibles["rb"] then
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint <= 2 then
								mission.ProgressionPoint = 3;
							end;
						end)
						
					else
						mission.Cache.BeaniePrefab = script:WaitForChild("robertsbeanie"):Clone();
						modReplicationManager.ReplicateIn(player, mission.Cache.BeaniePrefab, workspace.Interactables);

					end
					
				elseif mission.ProgressionPoint == 3 then
					Debugger.Expire(mission.Cache.BeaniePrefab, 0);

				elseif mission.ProgressionPoint == 4 then
					spawnEnemy()
					if banditZombie then
						banditZombie.RootPart.Anchored = true;
						banditZombie.Immunity = 1;

						banditZombie.SetAnimation("Wake", {script.WakeAnimation});
						local wakeTrack: AnimationTrack = banditZombie.GetAnimation("Wake");
						banditZombie.WakeTrack = wakeTrack;

						for a=1, 14 do
							task.wait(0.5);
							if wakeTrack.Length > 0 then break; end;
						end

						wakeTrack:Play();
						wakeTrack:AdjustSpeed(0);
					end
					
				elseif mission.ProgressionPoint == 5 then
					if firstRun then spawnEnemy() end;
					if banditZombie then
						if banditInteractable then banditInteractable:Destroy() end;
						banditZombie.Chat(player, "It got me... arrggggggg.. errerrr..");
						wait(3);
						if banditZombie.WakeTrack then
							banditZombie.WakeTrack:AdjustSpeed(1);
						end
						wait(1.4)
						banditZombie.RootPart.Anchored = false;
						local rootPart = player.Character.PrimaryPart;
						banditZombie.Movement:Face(rootPart.Position);
						wait(0.2);
						banditZombie.Wield.Equip("tec9");
						pcall(function()
							banditZombie.Wield.ToolModule.Configurations.MinBaseDamage = 2;
							banditZombie.Wield.ToolModule.Configurations.BaseInaccuracy = 14;
						end);
						repeat
							banditZombie.Immunity = nil;
							local enemyHumanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid");
							if enemyHumanoid and enemyHumanoid.Health > 0 and enemyHumanoid.RootPart and banditZombie.IsInVision(enemyHumanoid.RootPart) then
								banditZombie.Wield.SetEnemyHumanoid(enemyHumanoid);
								banditZombie.Movement:Face(enemyHumanoid.RootPart.Position);
								banditZombie.Wield.PrimaryFireRequest();
							end
						until banditZombie == nil or banditZombie.IsDead or mission.ProgressionPoint ~= 5 or not RunService.Heartbeat:Wait();
					end
					
				end
				
			elseif mission.Type == 3 then -- OnComplete
				mission.Changed:Disconnect(OnChanged);
				
			end
		end
		mission.Changed:Connect(OnChanged);
		OnChanged(true, mission);
	end)
	
	return CutsceneSequence;
end;