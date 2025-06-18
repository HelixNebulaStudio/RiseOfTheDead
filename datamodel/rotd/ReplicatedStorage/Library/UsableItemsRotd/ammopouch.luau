local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local UsablePreset = shared.require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();
--==

function UsablePreset:ClientUse(storageItem)
	modClientGuis.toggleWindow("ResupplyStation", true, nil, nil, storageItem);
end

return UsablePreset;