local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local MISSION_ID = 95;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if RunService:IsServer() then
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		shared.modEventService:OnInvoked("Mission_BindObjectivesChanged", function(event: EventPacket, ...)
			local player = event.Player;
			if player == nil then return end;

			local mId: number = ...;
			if mId ~= MISSION_ID then return end;

			task.spawn(function() 
				if not modMission:Progress(player, MISSION_ID) then return end;

				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 2 and mission.ObjectivesCompleted.Blueprint == true then
						mission.ProgressionPoint = 3;

					elseif mission.ProgressionPoint <= 3 and mission.ObjectivesCompleted.Component == true then
						mission.ProgressionPoint = 4;

					end
				end)
			end)
		end)

		if shared.WorldName ~= "TheMall" then return end;
		shared.modEventService:OnInvoked("Players_BindSpawn", function(event: EventPacket, playerClass: PlayerClass)
			local player = event.Player;
			if player == nil then return end;

			task.spawn(function() 
				if not modMission:Progress(player, MISSION_ID) then return end;

				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 1 then
						mission.ProgressionPoint = 2;
					end
				end)
			end)
		end)
	end
end

return MissionLogic;