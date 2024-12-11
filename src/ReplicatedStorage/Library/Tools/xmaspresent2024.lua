local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGeneralCrate = require(script.Parent.crate);

return function(handler)
    local toolConfig = modGeneralCrate(handler, script.Name, script.Name);
    toolConfig.PlaceOffset = CFrame.Angles(math.rad(90), 0, math.rad(-90));
    return toolConfig;
end;