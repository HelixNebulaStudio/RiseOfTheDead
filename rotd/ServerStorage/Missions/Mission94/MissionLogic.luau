local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

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

			if event.Player == nil then return end;
			local player = event.Player;

			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil or mission.Type ~= 1 or mission.ProgressionPoint ~= 1 then Debugger:Warn(`Mission 94 inactive`); return end;

			local raidId = mission.SaveData.Raid;
			if room.Stage ~= raidId then Debugger:Warn(`Wrong raid for mission 94`); return end;

			modMission:CompleteMission(player, MISSION_ID);
		end)
	end
end

return MissionLogic;