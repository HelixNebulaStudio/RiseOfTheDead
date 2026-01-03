local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local MISSION_ID = 87;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if RunService:IsServer() then
		modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	elseif RunService:IsClient() then


	end
end

if RunService:IsServer() then
	-- modBranchConfigs.IsWorld("TheMall")
	
	function MissionLogic.Init(missionProfile: MissionsProfile, mission: Mission)
		local player: Player = missionProfile.Player;

		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable

			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 2 then

				end
			elseif mission.Type == 3 then -- OnComplete

			end
		end
		
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;