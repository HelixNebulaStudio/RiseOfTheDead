local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local MISSION_ID = 9;

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
				if bpLib.Product ~= "incendiarymod" then return end;
				if not modMission:Progress(player, MISSION_ID) then return end;
				modMission:CompleteMission(player, MISSION_ID);
			end)
		end)
		
	end
end

return MissionLogic;