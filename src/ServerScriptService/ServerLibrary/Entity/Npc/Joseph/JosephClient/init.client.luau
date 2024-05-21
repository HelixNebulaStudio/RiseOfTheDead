local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local prefab = script:WaitForChild("Prefab").Value;
if not workspace:IsAncestorOf(prefab) then return end;

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule") :: ModuleScript);

local function updateVisual()
    pcall(function()
        local mission58 = modData:GetMission(58); -- The Investigation
        if mission58 and mission58.Type == 3 then
			prefab:WaitForChild("Bandage"):WaitForChild("Handle").Transparency = 0;
			prefab:WaitForChild("LeftLowerArm").Transparency = 1;
			prefab:WaitForChild("LeftHand").Transparency = 1;
			prefab:WaitForChild("LeftPoint").Transparency = 1;
			prefab:WaitForChild("LeftMiddle").Transparency = 1;
			prefab:WaitForChild("LeftPinky").Transparency = 1;
        end
    end)
end

updateVisual();
while true do
    updateVisual();
    task.wait(5);
end