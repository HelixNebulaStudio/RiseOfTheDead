local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

if RunService:IsServer() then

end

local WorldCore = {};
--==

function WorldCore.onRequire()
    Debugger:Warn(`BioXResearch core loaded.`);
end

return WorldCore;