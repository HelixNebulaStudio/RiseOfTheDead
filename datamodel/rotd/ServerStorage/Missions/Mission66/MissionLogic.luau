local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local MISSION_ID = 66;

if RunService:IsServer() then
	if not modBranchConfigs.IsWorld("SectorD") then return {}; end;
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	shared.modEventService:OnInvoked("GameModeManager_BindGameModeComplete", function(eventPacket: EventPacket, packet)
		local room = packet.Room;

		if room.Type ~= "Survival" or room.Stage ~= "Sector D" then return end;
		if eventPacket.Players == nil then return end;
		
		for _, player: Player in pairs(eventPacket.Players) do
			if not modMission:Progress(player, MISSION_ID) then continue end;

			modMission:Progress(player, MISSION_ID, function(mission)
				mission.ObjectivesCompleted["CompleteSurvival"] = true;
			end)
		end
	end)

	shared.modEventService:OnInvoked("Generic_BindTrigger", function(eventPacket: EventPacket, triggerId, ...)
		if triggerId ~= "Monorail_Activate" then return end;

		for _, p in pairs(game.Players:GetPlayers()) do
			modMission:Progress(p, MISSION_ID, function(mission)
				mission.ObjectivesCompleted["ActivateMonorail"] = true;
			end)
		end
	end)
end

return MissionLogic;