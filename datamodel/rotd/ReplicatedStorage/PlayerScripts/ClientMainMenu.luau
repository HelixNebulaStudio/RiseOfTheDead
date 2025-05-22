local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local localPlayer = game.Players.LocalPlayer;

local ClientMainMenu = {};
--==

function ClientMainMenu.onRequire()
	Debugger:Warn("Load ClientMainMenu");

	if modBranchConfigs.IsWorld("MainMenu") 
    	and localPlayer.PlayerGui:FindFirstChild("ClientMainMenu") == nil then

		local new = game.ReplicatedFirst.ClientMainMenu:Clone();
		new.Parent = localPlayer.PlayerGui;
		new.Disabled = false;
	end
end

return ClientMainMenu;