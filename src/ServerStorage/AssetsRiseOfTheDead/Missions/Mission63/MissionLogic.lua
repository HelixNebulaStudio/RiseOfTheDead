local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};

local RunService = game:GetService("RunService");
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local missionId = 63;
if RunService:IsServer() then
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	
	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

		local function OnChanged(firstRun)
			if mission.Type == 1 then -- OnActive
				if not modBranchConfigs.IsWorld("BanditsRecruitment") then
					if mission.ProgressionPoint >= 3 and mission.ProgressionPoint <= 11 then
						if firstRun then
							modMission:Progress(player, missionId, function(mission)
								mission.ProgressionPoint = 2;
								Debugger:Log("Rewind mission 62 to point 2.");
							end)
						end
						
					end
				end
			end
		end
		
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;