local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionFunctions = {};
local RunService = game:GetService("RunService");

local MISSION_ID = 78;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	function MissionFunctions.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

        if shared.WorldName ~= "Safehome" and shared.WorldName ~= "BioXResearch" then
            local function OnChanged(firstRun)
                if mission.Type == 2 then -- OnAvailable
    
                elseif mission.Type == 1 then -- OnActive
                    if mission.ProgressionPoint >= 2 and mission.ProgressionPoint <= 5 then
                        modMission:Progress(player, MISSION_ID, function(mission)
                            Debugger:StudioWarn("Reverted to point 1, not in mission world.");
                            mission.ProgressionPoint = 1;
                        end)

                    end
                elseif mission.Type == 3 then -- OnComplete
    
                end
            end
            
            mission.OnChanged:Connect(OnChanged);
            OnChanged(true);
        end
	end
end

return MissionFunctions;