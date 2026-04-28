local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local MISSION_ID = 66;

if RunService:IsServer() then
	if not modBranchConfigurations.IsWorld("SectorD") then return {}; end;
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	shared.modEventService:OnInvoked("Survival_BindWaveReached", function(eventPacket: EventPacket, ...)
		local players = eventPacket.Players;
		if players == nil then return end;

		local gameController = ...;

		task.spawn(function()
			if gameController.ModeType ~= "Survival" or gameController.ModeStage ~= "Sector D" then return end;
			if gameController.Wave < 5 then return end;
			
			for _, player: Player in pairs(players) do
				if not modMission:Progress(player, MISSION_ID) then continue end;

				modMission:Progress(player, MISSION_ID, function(mission)
					mission.ObjectivesCompleted["CompleteSurvival"] = true;
				end)
			end
		end)
	end)

	shared.modEventService:OnInvoked("Generic_BindTrigger", function(eventPacket: EventPacket, ...)
		local triggerId = ...;
		if triggerId ~= "StartMonorail" then return end;

		task.spawn(function()
			for _, p in pairs(game.Players:GetPlayers()) do
				modMission:Progress(p, MISSION_ID, function(mission)
					mission.ObjectivesCompleted["ActivateMonorail"] = true;
				end)
			end
		end)
	end)
end

return MissionLogic;