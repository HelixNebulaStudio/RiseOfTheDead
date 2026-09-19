local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;

local WorkbenchClass = {};
--==

function WorkbenchClass.init(interface: InterfaceInstance, workbenchWindow: InterfaceWindow)
	local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	local binds = workbenchWindow.Binds;

	function WorkbenchClass.new(itemId, library, storageItem)
		
	end

	return WorkbenchClass
end

return WorkbenchClass;