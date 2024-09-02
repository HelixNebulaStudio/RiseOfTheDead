local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");

local missionId = 65;
if RunService:IsServer() then
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	modOnGameEvents:ConnectEvent("OnNpcDamaged", function(player, damageSource)
		local npcModule = damageSource.NpcModule;
		local humanoid = npcModule.Humanoid;

		if humanoid.Name ~= "Zombie" or damageSource.Killed ~= true then return end;
			
		if modMission:IsComplete(player, missionId) then return end;

		if (damageSource.DamageType == "FireDamage" or (npcModule.StatusLogicIsOnFire and npcModule.StatusLogicIsOnFire() == true)) then
			modMission:Progress(player, missionId, function(mission)
				mission.SaveData.Kills = mission.SaveData.Kills -1;
				if mission.SaveData.Kills <= 0 then
					modMission:CompleteMission(player, missionId);
				end
			end)
		end

	end)
end

return MissionLogic;