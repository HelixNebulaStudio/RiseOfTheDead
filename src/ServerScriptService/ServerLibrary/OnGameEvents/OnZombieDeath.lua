local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modVoxelSpace = require(game.ReplicatedStorage.Library.VoxelSpace);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);

local random = Random.new();

local chunkStats = modVoxelSpace.new();
chunkStats.StepSize = 64;

--== When a zombie dies;
return function(zombie)
	local deathPosition = zombie.DeathPosition;
	local config = zombie.Configuration;

	players = players or {};
	for _, player in pairs(players) do
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
		if not modMission:IsComplete(player, 19) and (zombie.Name == "Ticks Zombie" or zombie.Name == "Ticks") then
			modMission:Progress(player, 19, function(mission)
				if mission.ProgressionPoint == 1 then
					mission.SaveData.Kills = mission.SaveData.Kills -1;
					if mission.SaveData.Kills <= 0 then
						mission.ProgressionPoint = 2;
					end
				end;
			end)
		end
		if not modMission:IsComplete(player, 20) and zombie.Name == "Zpider" then
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
			if zombie.Name == "The Prisoner" or zombie.Name == "Tanker" or zombie.Name == "Fumes" then
				bossName = zombie.Name;
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
		
		if modMission:Progress(player, 24) and zombie.Name == "Bandit Zombie" then
			modMission:Progress(player, 24, function(mission)
				if mission.ProgressionPoint == 5 then
					mission.ProgressionPoint = 6;
				end;
			end)
		end
		
		if modMission:Progress(player, 23) and zombie.Configuration.MissionTag == 23 then
			modMission:Progress(player, 23, function(mission)
				if mission.ProgressionPoint == 1 then
					mission.SaveData.Kills = mission.SaveData.Kills -1;
					if mission.SaveData.Kills <= 0 then
						mission.ProgressionPoint = 2;
					end
				end;
			end)
		end
		
		if modMission:Progress(player, 25) and zombie.Configuration.SantaHat then
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

		if zombie and zombie.JackReapZombie and zombie.Owner then
			modMission:Progress(player, 43, function(mission)
				if mission.ProgressionPoint == 5 then
					modMission:CompleteMission(zombie.Owner, 43);
					--modItemDrops.Spawn({Type="Tool"; ItemId="jacksscythe";}, CFrame.new(zombie.DeathPosition), zombie.Owner);
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
				--local humanoid = classPlayer.Humanoid;
				
				--local healAmount = classPlayer.Properties.Lifesteal.Amount;
				--local newHealth = humanoid.Health + healAmount;
				--if newHealth > classPlayer.Properties.BaseHealth then
				--	local amount = newHealth - classPlayer.Properties.BaseHealth;

				--	local skill = profile.SkillTree:GetSkill(player, "ovehea");
				--	local level, stats = profile.SkillTree:CalStats(skill.Library, skill.Points);
				--	classPlayer.Properties.OverHealLimit = stats.Amount.Default + stats.Amount.Value;

				--	classPlayer.Properties.OverHeal = math.clamp(amount, 0, classPlayer.Properties.OverHealLimit);

				--	local overhealDuration = 20;
				--	classPlayer:SetProperties("ovehea", {
				--		Expires=modSyncTime.GetTime()+overhealDuration;
				--		Duration=overhealDuration;
				--		Amount=classPlayer.Properties.OverHealLimit;
				--	});

				--	humanoid.MaxHealth = classPlayer.Properties.BaseHealth + classPlayer.Properties.OverHeal;
				--end
				--humanoid.Health = newHealth;

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
