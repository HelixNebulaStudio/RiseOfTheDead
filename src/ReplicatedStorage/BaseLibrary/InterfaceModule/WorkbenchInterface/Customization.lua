local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Workbench = {};
local Interface;

local player = game.Players.LocalPlayer;

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);
local modCustomizationData = require(game.ReplicatedStorage.Library.CustomizationData);

local remoteCustomizationData = modRemotesManager:Get("CustomizationData");

local modData = require(player:WaitForChild("DataModule") :: ModuleScript);

local garbage = modGarbageHandler.new();
--==

function Workbench.init(interface)
	Interface = interface;
	return Workbench;
end

function Workbench.new(itemId, appearanceLib, storageItem)
	local listMenu = Interface.List.create();
	listMenu.Menu.Name = "customize";
	listMenu:SetEnableSearchBar(false);

	function listMenu:Refresh()
        garbage:Destruct();
        
        local siid = storageItem.ID;
        local rawLz4 = remoteCustomizationData:InvokeServer("get", siid);

        local customSkin = modCustomizationData.newCustomizationSkin(rawLz4);
		Debugger:StudioWarn("customSkin", customSkin);

    end
	
	return listMenu;
end


return Workbench;