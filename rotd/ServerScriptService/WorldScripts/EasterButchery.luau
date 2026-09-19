local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");


local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);
--==

function WorldCore.onRequire()
    if RunService:IsServer() then
        shared.modNpcs.spawn2{
            Name = "Bunny Man";
            CFrame = CFrame.new(-28.7378807, 2.70967245, -176.53212, -0.998637021, 0, -0.0523354448, 0, 1, 0, 0.0523354448, 0, -0.998637021);
        };
    end
end


return WorldCore;