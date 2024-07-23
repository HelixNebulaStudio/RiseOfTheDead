local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionFunctions = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

if RunService:IsServer() then
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	
	function MissionFunctions.Init(missionProfile, mission)
		Debugger:StudioLog("MissionFunctions: ", mission)
		local player = missionProfile.Player;
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable

			elseif mission.Type == 1 then -- OnActive
				if not modBranchConfigs.IsWorld("BanditsRecruitment") then
					if mission.ProgressionPoint >= 3 and mission.ProgressionPoint <= 11 then
						if firstRun then
							modMission:Progress(player, 63, function(mission)
								mission.ProgressionPoint = 2;
								Debugger:Log("Rewind mission 62 to point 2.");
							end)
						end
						
					end
				end
			elseif mission.Type == 3 then -- OnComplete


			end
		end
		
		mission.Changed:Connect(OnChanged);
		OnChanged(true, mission);
	end
end

return MissionFunctions;