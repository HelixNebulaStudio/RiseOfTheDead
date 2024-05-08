local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

--== When a npc takes damage;
return function(player, damageSource)
	local modWorkbenchLibrary = require(game.ReplicatedStorage.Library.WorkbenchLibrary);
	local modSkillTree = require(game.ServerScriptService.ServerLibrary.SkillTree);
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	
	if player == nil or typeof(player) ~= "Instance" then return end;
	if not player:IsA("Player") then return end;
	
	modSkillTree:TriggerSkills(player, script.Name, damageSource);

	local npcModule = damageSource.NpcModule;
	local storageItem = damageSource.ToolStorageItem;
	local humanoid = npcModule.Humanoid;

	if damageSource and damageSource.Damage > 0 and damageSource.DamageType ~= "Heal" then
		local classPlayer = shared.modPlayers.Get(player);
		if classPlayer then
			classPlayer.LastDamageDealt = tick();
		end
	end
	
	if humanoid.Name == "Zombie" and damageSource.Killed == true and npcModule.IsDead ~= true then
		
		if not modMission:IsComplete(player, 65) and (damageSource.DamageType == "FireDamage" or (npcModule.StatusLogicIsOnFire and npcModule.StatusLogicIsOnFire() == true)) then
			modMission:Progress(player, 65, function(mission)
				mission.SaveData.Kills = mission.SaveData.Kills -1;
				if mission.SaveData.Kills <= 0 then
					modMission:CompleteMission(player, 65);
				end
			end)
		end
		
		local toolWorkbenchLib = storageItem and modWorkbenchLibrary.ItemUpgrades[storageItem.ItemId] or nil;
		
		local mission = modMission:GetMission(player, 69);
		if mission and mission.Type == 1 and toolWorkbenchLib and (mission.SaveData.WeaponItemId or table.find(toolWorkbenchLib.Type, mission.SaveData.WeaponType) ~= nil) then
			modMission:Progress(player, 69, function(mission)
				mission.SaveData.Kills = mission.SaveData.Kills -1;
				if mission.SaveData.Kills <= 0 then
					modMission:CompleteMission(player, 69);
				end
			end)
		end
		

		local mission = modMission:GetMission(player, 70);
		if mission and mission.Type == 1 and toolWorkbenchLib and table.find(toolWorkbenchLib.Type, "Melee") ~= nil then
			if damageSource.Immunity and damageSource.Immunity > 0 then
				modMission:Progress(player, 70, function(mission)
					mission.SaveData.Kills = mission.SaveData.Kills -1;
					if mission.SaveData.Kills <= 0 then
						modMission:CompleteMission(player, 70);
					end
				end)
			end
		end
		
	end

	if (humanoid.Name == "Zombie" or humanoid.Name == "Bandit" or humanoid.Name == "Rat") and damageSource.Killed == true and npcModule.IsDead ~= true then

		local throwableWeaponList = {"beachball"; "pickaxe"; "broomspear"; "snowballs"};
		local isThrowableWeapon = false;
		if table.find(throwableWeaponList, storageItem.ItemId) then
			isThrowableWeapon = true;
		end

		Debugger:Warn("isThrowableWeapon storageItem.ItemId", storageItem.ItemId, isThrowableWeapon);
		local mission = modMission:GetMission(player, 79);
		if mission and mission.Type == 1 and isThrowableWeapon then
			modMission:Progress(player, 79, function(mission)
				mission.SaveData.Kills = mission.SaveData.Kills -1;
				if mission.SaveData.Kills <= 0 then
					modMission:CompleteMission(player, 79);
				end
			end)
		end
	end
	
end;
