local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local localPlayer = game.Players.LocalPlayer;

local ClientMainMenu = {};
--==

function ClientMainMenu.onRequire()
end

return ClientMainMenu;