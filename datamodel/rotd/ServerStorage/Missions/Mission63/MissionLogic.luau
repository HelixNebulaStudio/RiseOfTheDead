local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};

local RunService = game:GetService("RunService");

local MISSION_ID = 63;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

		local function OnChanged(firstRun)
			if mission.Type == 1 then -- OnActive
				if shared.WorldName == "BanditsRecruitment" then
					if firstRun then
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 3;
						end)
					end
				else
					if mission.ProgressionPoint >= 3 and mission.ProgressionPoint <= 11 then
						if firstRun then
							modMission:Progress(player, MISSION_ID, function(mission)
								Debugger:Warn(`{mission.ProgressionPoint} Reverted to point 2, not in mission world.`)
								mission.ProgressionPoint = 2;
							end)
						end
						
					end
				end
			end
		end
		
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;