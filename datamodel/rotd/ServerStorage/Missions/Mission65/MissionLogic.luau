local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");

local MISSION_ID = 65;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	shared.modEventService:OnInvoked("Npcs_OnDamaged", function(event: EventPacket, damageData: DamageData)
		local damageBy: CharacterClass? = damageData.DamageBy;
		if damageBy == nil or damageBy.ClassName ~= "PlayerClass" then return end;

		local player: Player = (damageBy :: PlayerClass):GetInstance();
		if modMission:IsComplete(player, MISSION_ID) then return end;

		local damageTo: CharacterClass? = damageData.DamageTo;
		if damageTo == nil or damageTo.HumanoidType ~= "Zombie" then return end;

		if damageData.DamageType ~= "Fire" then return end;
		if damageTo.StatusLogicIsOnFire == nil or damageTo.StatusLogicIsOnFire() ~= true then return end;

		modMission:Progress(player, MISSION_ID, function(mission)
			mission.SaveData.Kills = mission.SaveData.Kills -1;
			if mission.SaveData.Kills <= 0 then
				modMission:CompleteMission(player, MISSION_ID);
			end
		end)
	end)

end

return MissionLogic;