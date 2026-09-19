local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClass).new(script);
--==

function WorldCore.onRequire()
    if RunService:IsClient() then return end;
end

return WorldCore;