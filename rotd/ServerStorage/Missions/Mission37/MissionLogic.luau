local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local MISSION_ID = 37;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if RunService:IsServer() then
		modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		shared.modEventService:OnInvoked("WorkbenchService_BindClaimBuild", function(eventPacket: EventPacket, ...)
			local player = eventPacket.Player;
			if player == nil then return end;

			local bpLib = ...;
			task.spawn(function()
				if bpLib.Product ~= "wateringcan" then return end;
				if modMission:Progress(player, MISSION_ID) then
					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ObjectivesCompleted.wateringcan = true;
					end)
				end
			end)
		end)
		
	end
end

return MissionLogic;