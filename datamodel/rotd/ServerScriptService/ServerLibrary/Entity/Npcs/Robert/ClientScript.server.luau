local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local characterTag = script:WaitForChild("Character");
repeat task.wait(0.1) until characterTag.Value ~= nil;

local character = characterTag.Value;
if not workspace:IsAncestorOf(character) then return end;

local localplayer = game.Players.LocalPlayer;
local modData = shared.require(localplayer:WaitForChild("DataModule") :: ModuleScript);

local function updateVisual()
    pcall(function()
        local mission18 = modData:GetMission(18); -- A New Community
        if mission18 and mission18.Type == 3 then
            local hair = character:WaitForChild("Hair");
            hair.Handle.Transparency = 0;
    
            local robloxUBeanie = character:WaitForChild("RobloxUBeanie");
            robloxUBeanie.Handle.Transparency = 1;
        end
    end)

    pcall(function()
        local mission52 = modData:GetMission(52); -- The Investigation
        if mission52 and mission52.Type == 3 then
            character:WaitForChild("RightHand").Transparency = 1;
            character:WaitForChild("RightPoint").Transparency = 1;
            character:WaitForChild("RightMiddle").Transparency = 1;
            character:WaitForChild("RightPinky").Transparency = 1;
        end
    end)
end

updateVisual();