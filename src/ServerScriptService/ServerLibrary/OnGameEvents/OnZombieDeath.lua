local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modVoxelSpace = require(game.ReplicatedStorage.Library.VoxelSpace);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);

local random = Random.new();

local chunkStats = modVoxelSpace.new();
chunkStats.StepSize = 64;

--== When a zombie dies;
return function(zombieNpcModule)
	local deathPosition = zombieNpcModule.DeathPosition;
	local config = zombieNpcModule.Configuration;

	local playerTags = modDamageTag:Get(zombieNpcModule.Prefab, "Player");
	for _, playerTag in pairs(playerTags) do
		local player = playerTag.Player;

		local profile = modProfile:Get(player);
		local activeSave = profile:GetActiveSave();
		local inventory = activeSave.Inventory;
		
		if not modMission:IsComplete(player, 2) then
			modMission:Progress(player, 2, function(mission)
				if mission.ProgressionPoint == 9 then
					mission.SaveData.Kills = mission.SaveData.Kills -1;
					if mission.SaveData.Kills <= 0 then
						mission.ProgressionPoint = 10;
					end
				end;
			end)
		end
		if not modMission:IsComplete(player, 13) then
			modMission:Progress(player, 13, function(mission)
				if mission.ProgressionPoint == 1 then
					mission.SaveData.Kills = mission.SaveData.Kills -1;
					if mission.SaveData.Kills <= 0 then
						mission.ProgressionPoint = 2;
					end
				end;
			end)
		end
		if not modMission:IsComplete(player, 19) and (zombieNpcModule.Name == "Ticks Zombie" or zombieNpcModule.Name == "Ticks") then
			modMission:Progress(player, 19, function(mission)
				if mission.ProgressionPoint == 1 then
					mission.SaveData.Kills = mission.SaveData.Kills -1;
					if mission.SaveData.Kills <= 0 then
						mission.ProgressionPoint = 2;
					end
				end;
			end)
		end
		if not modMission:IsComplete(player, 20) and zombieNpcModule.Name == "Zpider" then
			modMission:Progress(player, 20, function(mission)
				if mission.ProgressionPoint == 1 then
					mission.SaveData.Kills = mission.SaveData.Kills -1;
					if mission.SaveData.Kills <= 0 then
						mission.ProgressionPoint = 2;
					end
				end;
			end)
		end
		if not modMission:IsComplete(player, 21) then
			local bossName;
			if zombieNpcModule.Name == "The Prisoner" or zombieNpcModule.Name == "Tanker" or zombieNpcModule.Name == "Fumes" then
				bossName = zombieNpcModule.Name;
			end
			if bossName then
				modMission:Progress(player, 21, function(mission)
					mission.ObjectivesCompleted[bossName] = true;
				end)
			end
		end
		if not modMission:IsComplete(player, 59) then
			modMission:Progress(player, 59, function(mission)
				if mission.ProgressionPoint == 1 then
					mission.SaveData.Kills = mission.SaveData.Kills -1;
					if mission.SaveData.Kills <= 0 then
						mission.ProgressionPoint = 2;
					end
				end;
			end)
		end
		
		if modMission:Progress(player, 24) and zombieNpcModule.Name == "Bandit Zombie" then
			modMission:Progress(player, 24, function(mission)
				if mission.ProgressionPoint == 5 then
					mission.ProgressionPoint = 6;
				end;
			end)
		end
		
		if modMission:Progress(player, 23) and zombieNpcModule.Configuration.MissionTag == 23 then
			modMission:Progress(player, 23, function(mission)
				if mission.ProgressionPoint == 1 then
					mission.SaveData.Kills = mission.SaveData.Kills -1;
					if mission.SaveData.Kills <= 0 then
						mission.ProgressionPoint = 2;
					end
				end;
			end)
		end
		
		if modMission:Progress(player, 25) and zombieNpcModule.Configuration.SantaHat then
			modMission:Progress(player, 25, function(mission)
				if mission.SaveData.Kills > 0 then
					mission.SaveData.Kills = mission.SaveData.Kills -1;
				end
				if mission.SaveData.Kills <= 0 then
					mission.ProgressionPoint = 2;
				end
			end)
		end
		
		if modMission:Progress(player, 4) and modMission:Progress(player, 4).ObjectivesCompleted.ArmSearch ~= true then
			if random:NextInteger(1,6) <= 1 or (activeSave:GetStat("Kills") or 0) >= 70 then
				local randomV3 = Vector3.new(random:NextNumber(-1.5, 1.5), random:NextNumber(-1.5, 1.5), random:NextNumber(-1.5, 1.5));
				local newCframe = CFrame.new(randomV3 + deathPosition) * CFrame.Angles(math.rad(random:NextNumber(0, 360)), math.rad(random:NextNumber(0, 360)), math.rad(random:NextNumber(0, 360)));
				local new = modItemDrops.Spawn({ItemId="zombiearm"; OnceOnly=true;}, newCframe, player);
				modReplicationManager.ReplicateIn(player, new, workspace.Interactables);
			end
		end

		if zombieNpcModule and zombieNpcModule.JackReapZombie and zombieNpcModule.Owner then
			modMission:Progress(player, 43, function(mission)
				if mission.ProgressionPoint == 5 then
					modMission:CompleteMission(zombieNpcModule.Owner, 43);
				end
			end)

		end
		
		local classPlayer = modPlayers.Get(player);
		if classPlayer and classPlayer.Properties then
			
			if classPlayer.Properties.FrostivusSpirit then
				classPlayer.Properties.FrostivusSpirit.Amount = math.min(classPlayer.Properties.FrostivusSpirit.Amount +20, 10000);
				classPlayer:SyncProperty("FrostivusSpirit");
			end
			
			if classPlayer.Properties.Lifesteal then
				local healAmount = classPlayer.Properties.Lifesteal.Amount;
				
				classPlayer:TakeDamagePackage(modDamagable.NewDamageSource{
					Damage=healAmount;
					Dealer=player;
					TargetPart=classPlayer.RootPart;
					DamageType="Heal";
				});
				
			end
		end

	end
	
	
	if modConfigurations.WithererSpawnLogic == true then
		local voxelPoint = chunkStats:GetOrDefault(chunkStats:GetVoxelPosition(deathPosition, 64), {});
		local voxelData = voxelPoint.Value;
		
		if voxelData.WithererTrigger == nil then
			voxelData.WithererTrigger = {};
		end
		local withererSpawnData = voxelData.WithererTrigger;
		
		withererSpawnData.Counter = (withererSpawnData.Counter or 0) +1;
		
		if withererSpawnData.Counter > 20 then
			withererSpawnData.Counter = 0;

			local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

			local witherList = modNpc.ListEntities("Witherer");
			if #witherList <= 5 then
				modNpc.Spawn("Witherer", CFrame.new(deathPosition), function(npc, withererNpcModule)
					withererNpcModule.Configuration.Level = config.Level;
				end)
			end
			
		end
	end
end;
