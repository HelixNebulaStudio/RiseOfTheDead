local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Workbench = {};
local Interface = {} :: any;

local player = game.Players.LocalPlayer;

local modData = require(player:WaitForChild("DataModule") :: any);

function Workbench.new(itemId, library, storageItem)
	local listMenu = Interface.List.create();
	
	return listMenu;
end

function Workbench.init(interface)
	Interface = interface;
	return Workbench;
end

return Workbench;