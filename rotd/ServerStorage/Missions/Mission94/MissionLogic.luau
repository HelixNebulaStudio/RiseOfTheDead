local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local MISSION_ID = 94;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if RunService:IsServer() then
    	local modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

        if modGameModeManager.IsGameWorld ~= true then return end;

		shared.modEventService:OnInvoked("GameModeManager_BindGameModeComplete", function(event: EventPacket, packet)
			local room = packet.Room;
			if room.Type ~= "Raid" then return end;

			for _, player in pairs(game.Players:GetPlayers()) do
				local mission = modMission:GetMission(player, MISSION_ID);
				if mission == nil then continue end;
				if mission.Type ~= 1 or mission.ProgressionPoint ~= 1 then continue end;
					
				local raidId = mission.SaveData.Raid;
				if room.Stage ~= raidId then continue end;
					
				modMission:CompleteMission(player, MISSION_ID);
			end
		end)
	end
end

return MissionLogic;