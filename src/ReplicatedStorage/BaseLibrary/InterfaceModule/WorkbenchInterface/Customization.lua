local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Workbench = {};
local Interface;

local player = game.Players.LocalPlayer;
local UserInputService = game:GetService("UserInputService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);
local modCustomizationData = require(game.ReplicatedStorage.Library.CustomizationData);

local modDropdownList = require(game.ReplicatedStorage.Library.UI.DropdownList);

local remoteCustomizationData = modRemotesManager:Get("CustomizationData") :: RemoteFunction;

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

	local itemViewport = Interface.WorkbenchItemDisplay;

	function listMenu:Refresh()
		Debugger:StudioWarn("Select refresh");
        local siid = storageItem.ID;
        local rawLz4 = remoteCustomizationData:InvokeServer("get", siid);

        local customSkin = modCustomizationData.newCustomizationPlan(rawLz4);
		Debugger:StudioWarn("customSkin", customSkin);

		local newDropDownList = modDropdownList.new();
		newDropDownList.Frame.Parent = self.Menu;

		newDropDownList:LoadOptions({
			"A";
			"B";
			"C";
			"D";
			"E";
			"F";
		})
    end
	
	function listMenu:OnVisiblityChanged()
		if not self.Menu.Visible then
			garbage:Destruct();
			return;
		end

		itemViewport.HightlightSelect = true;
		garbage:Tag(UserInputService.InputEnded:Connect(function(inputObject) 
			if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 and inputObject.UserInputType ~= Enum.UserInputType.Touch then return end;
			task.wait();
			Debugger:StudioWarn("Customize Select", itemViewport.SelectedHighlightPart);

		end))
		garbage:Tag(function()
			itemViewport.HightlightSelect = false;
			Debugger:StudioWarn("Destruct HightlightSelect=false")
		end)

	end

	return listMenu;
end


return Workbench;