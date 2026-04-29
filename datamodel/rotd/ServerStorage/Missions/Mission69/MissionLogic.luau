local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");

local MISSION_ID = 69;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	shared.modEventService:OnInvoked("Npcs_BindDeath", function(event: EventPacket, ...)
		local npcClass: NpcClass, reasonData: anydict? = ...;
		if npcClass == nil or npcClass.HumanoidType ~= "Zombie" then return end;
		if reasonData == nil then return end;
	
		local damageData: DamageData = reasonData;
		local storageItem: StorageItem? = damageData.StorageItem;
		if storageItem == nil then return end;

		local playerClass: PlayerClass? = damageData.DamageBy :: PlayerClass;
		if playerClass == nil or playerClass.ClassName ~= "PlayerClass" then return end;

		local player: Player = playerClass:GetInstance();
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil or mission.Type ~= 1 then return end;
		if mission.SaveData.WeaponType == nil then return end;

		local damageTo: CharacterClass? = damageData.DamageTo :: CharacterClass;
		if damageTo == nil or damageTo.HumanoidType ~= "Zombie" then return end;
		
		local equipmentClass: EquipmentClass? = playerClass.WieldComp.EquipmentClass;
		if equipmentClass == nil then return end;
		if equipmentClass.StorageItem ~= storageItem then return end;
		if equipmentClass.Package.WeaponClass ~= mission.SaveData.WeaponType then return end;

		modMission:Progress(player, MISSION_ID, function(mission)
			mission.SaveData.Kills = mission.SaveData.Kills -1;
			if mission.SaveData.Kills <= 0 then
				modMission:CompleteMission(player, MISSION_ID);
			end
		end)
	end)
end

return MissionLogic;