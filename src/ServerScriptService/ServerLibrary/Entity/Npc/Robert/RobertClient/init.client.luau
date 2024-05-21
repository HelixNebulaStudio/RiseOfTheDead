local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local prefabObjVal = script:WaitForChild("Prefab");
while prefabObjVal.Value == nil do task.wait() end;
local prefab = prefabObjVal.Value;

if not workspace:IsAncestorOf(prefab) then return end;

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule") :: ModuleScript);

local function updateVisual()
    pcall(function()
        local mission18 = modData:GetMission(18); -- A New Community
        if mission18 and mission18.Type == 3 then
            local hair = prefab:WaitForChild("Hair");
            hair.Handle.Transparency = 0;
    
            local robloxUBeanie = prefab:WaitForChild("RobloxUBeanie");
            robloxUBeanie.Handle.Transparency = 1;
        end
    end)

    pcall(function()
        local mission52 = modData:GetMission(52); -- The Investigation
        if mission52 and mission52.Type == 3 then
            prefab:WaitForChild("RightHand").Transparency = 1;
            prefab:WaitForChild("RightPoint").Transparency = 1;
            prefab:WaitForChild("RightMiddle").Transparency = 1;
            prefab:WaitForChild("RightPinky").Transparency = 1;
        end
    end)
end

updateVisual();
while true do
    updateVisual();
    task.wait(5);
end