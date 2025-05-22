local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionFunctions = {};
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local missionId = 78;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	function MissionFunctions.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

        if not modBranchConfigs.IsWorld("Safehome") then
            local function OnChanged(firstRun)
                if mission.Type == 2 then -- OnAvailable
    
                elseif mission.Type == 1 then -- OnActive
                    if mission.ProgressionPoint >= 2 and mission.ProgressionPoint <= 5 then
                        modMission:Progress(player, missionId, function(mission)
                            mission.ProgressionPoint = 1;
                        end)

                    end
                elseif mission.Type == 3 then -- OnComplete
    
                end
            end
            
            mission.Changed:Connect(OnChanged);
            OnChanged(true);
        end
	end
end

return MissionFunctions;