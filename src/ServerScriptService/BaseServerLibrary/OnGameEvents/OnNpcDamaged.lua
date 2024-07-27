local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

--== When a npc takes damage;
return function(player, damageSource)
	local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

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
	
	if storageItem == nil then return end; -- Missing Dealer StorageItem
	if (humanoid.Name == "Zombie" or humanoid.Name == "Bandit" or humanoid.Name == "Rat") and damageSource.Killed == true and npcModule.IsDead ~= true
		and damageSource.DamageCate == modDamagable.DamageCategory.Projectile then

		local throwableWeaponList = {"beachball"; "pickaxe"; "broomspear"; "snowballs"; "boomerang"};
		local isThrowableWeapon = false;
		if table.find(throwableWeaponList, storageItem.ItemId) then
			isThrowableWeapon = true;
		end

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
