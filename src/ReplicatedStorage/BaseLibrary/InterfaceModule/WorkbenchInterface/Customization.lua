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

	--[[ 
		itemViewport.DisplayModels = {
			{WeldName=weldName; Prefab=prefab; BasePrefab=itemPrefabs[prefabName]; Offset=displayOffset; Prefix=prefix;})
		};
	]]

	function listMenu:Refresh()
		Debugger:StudioWarn("Select refresh");

		local customizationCache = {};

		local groupPartList = {};
		local groupsList = {}
		local modelParts = {};
		--[[
			{Name=prefix..obj.Name; Part=obj; DisplayModelData = displayModelData;}
		]]

		do -- load list of modelParts and part list
			for a=1, #itemViewport.DisplayModels do
				local displayModelData = itemViewport.DisplayModels[a];
				local prefix = displayModelData.Prefix;

				for _, basePart in pairs(displayModelData.Prefab:GetChildren()) do
					if not basePart:IsA("BasePart") then continue end;
					local predefinedGroup = basePart:GetAttribute("CustomizationGroup");
					local modelPartData = {
						Name=prefix..basePart.Name;
						Part=basePart;
						DisplayModelData = displayModelData;
						PredefinedGroup = predefinedGroup;
					};

					if predefinedGroup and table.find(groupsList, `[{predefinedGroup}]`) == nil then
						table.insert(groupsList, `[{predefinedGroup}]`);
					end

					table.insert(modelParts, modelPartData);
					table.insert(groupPartList, modelPartData.Name);
				end
			end
			table.sort(modelParts, function(a, b) return a.Name > b.Name; end);
			table.sort(groupPartList);
			table.sort(groupsList);
			table.insert(groupsList, 1, "[All]");

			for a=1, #groupsList do
				table.insert(groupPartList, a, groupsList[a]);
			end

			garbage:Tag(function()
				table.clear(groupPartList);
				table.clear(groupsList);
				table.clear(modelParts);
			end)
		end

		local newDropDownList = modDropdownList.new();
		local dropDownFrame = newDropDownList.Frame;
		dropDownFrame.Size = UDim2.new(1, 0, 1, 0);
		garbage:Tag(dropDownFrame);
		newDropDownList.Frame.Parent = scrollFrame;
	
		local mainFrame = templateMainFrame:Clone();
		garbage:Tag(mainFrame);
		mainFrame.Parent = scrollFrame;
	
		local selectTextbox: TextBox = mainFrame:WaitForChild("SelectTextbox");
		local selectDropButton = selectTextbox:WaitForChild("SelectDropButton") :: TextButton;

		local editPanel = mainFrame:WaitForChild("EditPanel") :: Frame;
		local hintLabel: TextLabel = mainFrame:WaitForChild("HintLabel");
		local infoLabel: TextLabel = editPanel:WaitForChild("InfoLabel");
		local partLabel: TextLabel = editPanel:WaitForChild("PartList");

		editPanel:GetPropertyChangedSignal("Visible"):Connect(function()
			hintLabel.Visible = not editPanel.Visible;
		end)

		local function newSelection(selectionPartData, predefinedGroup)
			if selectionPartData == nil then
				selectionPartData = {};

				local highlightSelect = itemViewport.SelectedHighlightParts;
				for a=1, #highlightSelect do
					for b=1, #modelParts do
						if modelParts[b].Part == highlightSelect[a] then 
							table.insert(selectionPartData, modelParts[b]);
							break;
						end;
					end
				end
			end

			Debugger:StudioWarn("selectionPartData", selectionPartData, "predefinedGroup", predefinedGroup);

			if #selectionPartData <= 0 then
				editPanel.Visible = false;
				return; 
			end

			local groupName = predefinedGroup or "New Group";

			editPanel.Visible = true;
			selectTextbox.Text = "";

			local partNames = {};
			for a=1, #selectionPartData do
				table.insert(partNames, selectionPartData[a].Name);
			end;
			
			if predefinedGroup or #selectionPartData > 1 then
				selectTextbox.Text = groupName;
				infoLabel.Text = `Type: Group    Layer: 0`;
				partLabel.Text = `<font size="14"><b>Grouped Parts:</b></font> {table.concat(partNames, ", ")}`;
			
			else
				local partData = selectionPartData[1];
				selectTextbox.Text = partData.Name;
				infoLabel.Text = `Type: Part    Layer: 0`;
				partLabel.Text = `<font size="14"><b>Part Group:</b> {partData.PredefinedGroup or "None"}</font>`;
			end


		end

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
			if dropDownFrame.Visible == false then
				toggleVisibility();
			end
		end);
	
		selectDropButton.MouseButton1Click:Connect(function()
			Interface:PlayButtonClick();
	
			newDropDownList:LoadOptions(groupPartList);

			function newDropDownList:OnOptionSelect(index, optionButton)
				Debugger:StudioWarn("index", index, "optionButton", optionButton);
				dropDownFrame.Visible = false;

				local selectionName = optionButton.Name;
				local selectionPartData = {};
				local predefinedGroup = selectionName:sub(1,1) == "[" and selectionName;

				for a=1, #modelParts do
					if predefinedGroup == "[All]" then
						table.insert(selectionPartData, modelParts[a]);

					elseif predefinedGroup and `[{modelParts[a].PredefinedGroup}]` == selectionName then
						table.insert(selectionPartData, modelParts[a]);

					elseif modelParts[a].Name == selectionName then
						table.insert(selectionPartData, modelParts[a]);

					end
				end

				newSelection(selectionPartData, predefinedGroup);
			end
	
			toggleVisibility(dropDownFrame);
		end)


        local siid = storageItem.ID;
        local rawLz4 = remoteCustomizationData:InvokeServer("get", siid);

        local customSkin = modCustomizationData.newCustomizationPlan(rawLz4);
		--Debugger:StudioWarn("customSkin", customSkin);

		garbage:Tag(itemViewport.OnSelectionChanged:Connect(function()
			--Debugger:StudioWarn("Customize Select", itemViewport.SelectedHighlightParts);
			newSelection();
		end))
    end
	
	function listMenu:OnVisiblityChanged()
		if not self.Menu.Visible then
			garbage:Destruct();
			return;
		end

		itemViewport.HightlightSelect = true;
		garbage:Tag(function()
			itemViewport.HightlightSelect = false;
			Debugger:StudioWarn("Destruct HightlightSelect=false")
		end)

	end

	return listMenu;
end


return Workbench;