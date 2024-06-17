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

local templateMainFrame = script.Parent:WaitForChild("CustomizationMain");

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

	local scrollFrame = listMenu.Menu.scrollList;
	local itemViewport = Interface.WorkbenchItemDisplay;

	local newDropDownList = modDropdownList.new();
	local dropDownFrame = newDropDownList.Frame;
	dropDownFrame.Size = UDim2.new(1, 0, 1, 0);
	newDropDownList.Frame.Parent = scrollFrame;
	garbage:Tag(dropDownFrame);

	local mainFrame = templateMainFrame:Clone();
	mainFrame.Parent = scrollFrame;

	local selectTextbox = mainFrame:WaitForChild("SelectTextbox");
	local selectDropButton: TextButton = selectTextbox:WaitForChild("SelectDropButton");

	local function toggleVisibility(frame)
		local exist = false;
		for _, obj in pairs(scrollFrame:GetChildren()) do
			if not obj:IsA("GuiObject") then continue end;
			obj.Visible = obj == frame;
			if obj.Visible then
				exist = true;
			end
		end
		if not exist then
			mainFrame.Visible = true;
		end
	end

	dropDownFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if dropDownFrame.Visibility == false then
			toggleVisibility();
		end
	end);

	selectDropButton.MouseButton1Click:Connect(function()
		Interface:PlayButtonClick();

		newDropDownList:LoadOptions({
			"[All]";
			"[Priamry]";
			"[Secondary]";
			"Handle";
			"Grips";
			"Body";
			"ScopeBody";
		});

		toggleVisibility(newDropDownList);
	end)
	
	function listMenu:Refresh()
		Debugger:StudioWarn("Select refresh");
        local siid = storageItem.ID;
        local rawLz4 = remoteCustomizationData:InvokeServer("get", siid);

        local customSkin = modCustomizationData.newCustomizationPlan(rawLz4);
		Debugger:StudioWarn("customSkin", customSkin);

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