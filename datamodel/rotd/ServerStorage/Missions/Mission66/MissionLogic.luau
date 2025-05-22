local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local missionId = 66;

if RunService:IsServer() then
	if not modBranchConfigs.IsWorld("SectorD") then return {}; end;
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	modOnGameEvents:ConnectEvent("OnGameModeComplete", function(player, modeType, modeStage, roomData)
		if modeType ~= "Survival" then return end;
		if modeStage ~= "Sector D" then return end;
		
		modMission:Progress(player, missionId, function(mission)
			mission.ObjectivesCompleted["CompleteSurvival"] = true;
		end)
	end)

	modOnGameEvents:ConnectEvent("OnEventPoint", function(pointName)
		if pointName ~= "Monorail_Activate" then return end;

		for _, p in pairs(game.Players:GetPlayers()) do
			modMission:Progress(p, missionId, function(mission)
				mission.ObjectivesCompleted["ActivateMonorail"] = true;
			end)
		end
	end)
end

return MissionLogic;