local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local LogicHandlerPackage = {
    Type = "MissionRequire";
};

function LogicHandlerPackage.process(instance: ObjectValue, packet)
    local player = packet.Player;
    if player == nil then return false; end;
    
    local modData = shared.require(player:WaitForChild("DataModule") :: ModuleScript);

    local missionId = instance:GetAttribute("MissionId");
    if missionId == nil then return false; end;

    local missionData = modData:GetMission(missionId);
    if missionData == nil then return false; end;

    for k, v in pairs(instance:GetAttributes()) do
        if k:sub(1, 11) == "MissionType" then
            if tostring(missionData.Type) ~= tostring(v) then
                return false;
            end
        elseif k == "ProgressionPoint" then
            if missionData.ProgressionPoint < v then
                return false;
            end
        end
    end
    
    return true;
end

return LogicHandlerPackage;