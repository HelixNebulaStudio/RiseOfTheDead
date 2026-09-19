local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local SpecialEventPackage = {};

function SpecialEventPackage.onRequire()
    task.spawn(function()
        local eventSpawns = workspace:WaitForChild("Event");

        local bunnyManSpawn = eventSpawns:WaitForChild("Bunny Man");
        shared.modNpcs.spawn("Bunny Man", bunnyManSpawn.CFrame);
    end)
end

return SpecialEventPackage;
