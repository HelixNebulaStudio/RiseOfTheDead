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
        local mission52 = modData:GetMission(52); -- The Investigation
        if mission52 and mission52.Type == 3 then
			character:WaitForChild("Bandage"):WaitForChild("Handle").Transparency = 0;
			character:WaitForChild("LeftLowerArm").Transparency = 1;
			character:WaitForChild("LeftHand").Transparency = 1;
			character:WaitForChild("LeftPoint").Transparency = 1;
			character:WaitForChild("LeftMiddle").Transparency = 1;
			character:WaitForChild("LeftPinky").Transparency = 1;
        end
    end)

end

updateVisual();