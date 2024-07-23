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
				if mission.ProgressionPoint == 1 then
					if modBranchConfigs.IsWorld("TheMall") then
						
					end
				elseif mission.ProgressionPoint == 2 then

				end
			elseif mission.Type == 3 then -- OnComplete


			end
		end
		
		mission.Changed:Connect(OnChanged);
		OnChanged(true, mission);
	end
end

return MissionFunctions;