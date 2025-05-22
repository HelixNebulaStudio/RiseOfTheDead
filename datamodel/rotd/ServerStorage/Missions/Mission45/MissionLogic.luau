local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local missionId = 45;
if RunService:IsServer() then
	if not modBranchConfigs.IsWorld("Prison") then return {}; end;

	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	modOnGameEvents:ConnectEvent("OnGameModeStart", function(player, gameType, gameStage, room)
		if gameType == "Survival" and gameStage == "Prison" then
			modMission:Progress(player, missionId, function(mission)
				if mission.ProgressionPoint == 1 then
					mission.ProgressionPoint = 2;
				end;
			end)

		end
	end);
	

	modOnGameEvents:ConnectEvent("OnGameModeComplete", function(player, gameType, gameStage, room)
		if gameType == "Survival" and gameStage == "Prison" then
			modMission:Progress(player, missionId, function(mission)
				mission.ProgressionPoint = 3;
			end)
			
		end
	end)
	
	local luckyCoin = script.Parent:WaitForChild("Mike's Lucky Coin");

	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

		if mission.Type == 3 then return end;
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable

			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 3 then
					local new = luckyCoin:Clone();
					new.Parent = workspace.Interactables;
					modReplicationManager.ReplicateOut(player, new);
				end
			elseif mission.Type == 3 then -- OnComplete

			end
		end
		
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;