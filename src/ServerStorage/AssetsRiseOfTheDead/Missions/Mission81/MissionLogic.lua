local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local missionId = 81;
if RunService:IsServer() then
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

	modOnGameEvents:ConnectEvent("OnFotlLossNpc", function(npcPrefab)
		for _, player in pairs(game.Players:GetPlayers()) do

			if npcPrefab.Name == "David" then
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint <= 3 then
						mission.ProgressionPoint = 4;
					end
				end)

			elseif npcPrefab.Name == "Cooper" then
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint <= 4 then
						mission.ProgressionPoint = 5;
					end
				end)

			end
		end
	end)

	modOnGameEvents:ConnectEvent("OnFotlWonNpc", function(npcPrefab)
		
	end)

	-- modBranchConfigs.IsWorld("TheMall")
	
	-- function MissionLogic.Init(missionProfile, mission)
	-- 	local player: Player = missionProfile.Player;

	-- 	local function OnChanged(firstRun)
	-- 		if mission.Type == 2 then -- OnAvailable

	-- 		elseif mission.Type == 1 then -- OnActive
	-- 			if mission.ProgressionPoint == 2 then

	-- 			end
	-- 		elseif mission.Type == 3 then -- OnComplete

	-- 		end
	-- 	end
		
	-- 	mission.Changed:Connect(OnChanged);
	-- 	OnChanged(true);
	-- end
end

return MissionLogic;