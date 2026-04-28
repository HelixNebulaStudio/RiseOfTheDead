local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local MissionLogic = {};
local RunService = game:GetService("RunService");

local MISSION_ID = 70;

if RunService:IsServer() then
	local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library.WorkbenchLibrary);
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	shared.modEventService:OnInvoked("Npcs_BindDamaged", function(event: EventPacket, damageData: DamageData)
		task.spawn(function()
			local storageItem: StorageItem? = damageData.StorageItem;
			if storageItem == nil then return end;

			local damageBy: PlayerClass? = damageData.DamageBy :: PlayerClass;
			if damageBy == nil or damageBy.ClassName ~= "PlayerClass" then return end;

			local player: Player = damageBy:GetInstance();
			if modMission:IsComplete(player, MISSION_ID) then return end;
			
			local damageTo: CharacterClass? = damageData.DamageTo :: CharacterClass;
			if damageTo == nil
			or damageTo.ClassName ~= "NpcClass" 
			or damageTo.HumanoidType ~= "Zombie" 
			or damageTo.HealthComp.IsDead then 
				return;
			end;

			if damageTo.Properties.Immunity == nil 
			or damageTo.Properties.Immunity <= 0 then return end;

			local toolWorkbenchLib = storageItem and modWorkbenchLibrary.ItemUpgrades[storageItem.ItemId] or nil;

			local mission: Mission = modMission:GetMission(player, MISSION_ID);
			if mission 
			and mission.Type == 1 
			and toolWorkbenchLib 
			and table.find(toolWorkbenchLib.Type, "Melee") ~= nil then
				modMission:Progress(player, MISSION_ID, function(mission)
					mission.SaveData.Kills = mission.SaveData.Kills -1;
					if mission.SaveData.Kills <= 0 then
						modMission:CompleteMission(player, MISSION_ID);
					end
				end)
			end
		end)
	end)
end

return MissionLogic;