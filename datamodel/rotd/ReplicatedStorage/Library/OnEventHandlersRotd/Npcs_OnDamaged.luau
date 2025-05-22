local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

--== When a npc takes damage;
return function(event: EventPacket, damageData: DamageData)
	local modSkillTree = shared.require(game.ServerScriptService.ServerLibrary.SkillTree);
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	local damageBy: CharacterClass? = damageData.DamageBy;
	if damageBy == nil or damageBy.ClassName ~= "PlayerClass" then return end;

	local player: Player = (damageBy :: PlayerClass):GetInstance();
	if player == nil then return end;

	modSkillTree:TriggerSkills(player, script.Name, damageData);

	local damageTo: CharacterClass? = damageData.DamageTo;
	if damageTo == nil then return end;

	local storageItem: StorageItem? = damageData.StorageItem;
	if storageItem == nil then return end;

	local humanoidType = damageTo.HumanoidType;
	if (humanoidType == "Zombie" or humanoidType == "Bandit" or humanoidType == "Rat") 
		and damageTo.HealthComp.IsDead == true
		and damageData.DamageCate == DamageData.DamageCategory.Projectile then

		local throwableWeaponList = {"beachball"; "pickaxe"; "broomspear"; "snowballs"; "boomerang"};
		local isThrowableWeapon = false;
		if table.find(throwableWeaponList, storageItem.ItemId) then
			isThrowableWeapon = true;
		end

		local JAVELINEER_PRODIGY_MISSION_ID = 79;
		local mission = modMission:GetMission(player, JAVELINEER_PRODIGY_MISSION_ID);
		if mission and mission.Type == 1 and isThrowableWeapon then
			modMission:Progress(player, JAVELINEER_PRODIGY_MISSION_ID, function(mission)
				mission.SaveData.Kills = mission.SaveData.Kills -1;
				if mission.SaveData.Kills <= 0 then
					modMission:CompleteMission(player, JAVELINEER_PRODIGY_MISSION_ID);
				end
			end)
		end
	end
	
end;
