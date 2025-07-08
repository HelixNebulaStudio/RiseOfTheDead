local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");

local MISSION_ID = 70;

if RunService:IsServer() then
	local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library.WorkbenchLibrary);
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	

	shared.modEventService:OnInvoked("Npcs_BindDamaged", function(event: EventPacket, damageData: DamageData)
		local storageItem: StorageItem? = damageData.StorageItem;
		if storageItem == nil then return end;

		local damageBy: CharacterClass? = damageData.DamageBy;
		if damageBy == nil or damageBy.ClassName ~= "PlayerClass" then return end;

		local player: Player = (damageBy :: PlayerClass):GetInstance();
		if modMission:IsComplete(player, MISSION_ID) then return end;
		
		local damageTo: CharacterClass? = damageData.DamageTo;
		if damageTo == nil or damageTo.HumanoidType ~= "Zombie" or damageTo.HealthComp.IsDead then return end;

		local toolWorkbenchLib = storageItem and modWorkbenchLibrary.ItemUpgrades[storageItem.ItemId] or nil;

		local mission: Mission = modMission:GetMission(player, MISSION_ID);
		if mission and mission.Type == 1 and toolWorkbenchLib and table.find(toolWorkbenchLib.Type, "Melee") ~= nil then
			if damageTo.Immunity == nil or damageTo.Immunity <= 0 then return end;
			
			modMission:Progress(player, MISSION_ID, function(mission)
				mission.SaveData.Kills = mission.SaveData.Kills -1;
				if mission.SaveData.Kills <= 0 then
					modMission:CompleteMission(player, MISSION_ID);
				end
			end)
		end

	end)
end

return MissionLogic;