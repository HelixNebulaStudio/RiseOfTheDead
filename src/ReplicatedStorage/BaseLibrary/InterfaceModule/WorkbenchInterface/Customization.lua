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
local modComponents = require(game.ReplicatedStorage.Library.UI.Components);

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
		local activeGroupName = nil;

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
		local saveGroupNameButton = selectTextbox:WaitForChild("SaveButton") :: TextButton;
		local selectDropButton = selectTextbox:WaitForChild("SelectDropButton") :: TextButton;

		local editPanel = mainFrame:WaitForChild("EditPanel") :: Frame;
		local hintLabel: TextLabel = mainFrame:WaitForChild("HintLabel");
		local infoLabel: TextLabel = editPanel:WaitForChild("InfoLabel");
		local partLabel: TextLabel = editPanel:WaitForChild("PartList");

		do -- Load edit panel 


			-- Transparency slider
			local transparencySlider = modComponents.NewSliderButton() :: TextButton;
			transparencySlider.AnchorPoint = Vector2.new(1, 0);
			transparencySlider.Position = UDim2.new(1, -5,0, 0);
			transparencySlider.Size = UDim2.new(0, 200, 0, 30);
			transparencySlider.Parent = editPanel.TransparencyFrame;

			modComponents.CreateSlider(Interface, {
				Button=transparencySlider;
				RangeInfo={Min=0; Max=100; Scale=100; Default=0; ValueType="Flat";};
				SetFunc=function(v)
					Debugger:StudioWarn("Set Transparency=", v);
				end;
				DisplayValueFunc=function(v)
					return v;
				end;
			});

			-- Texture Offset
			local textureOffsetXSlider = modComponents.NewSliderButton() :: TextButton;
			textureOffsetXSlider.AnchorPoint = Vector2.new(1, 0);
			textureOffsetXSlider.Position = UDim2.new(1, -110, 0, 0);
			textureOffsetXSlider.Size = UDim2.new(0, 95, 0, 30);
			textureOffsetXSlider.Parent = editPanel.SkinOffsetFrame;

			local textureOffsetYSlider = textureOffsetXSlider:Clone();
			textureOffsetYSlider.Position = UDim2.new(1, -5, 0, 0);
			textureOffsetYSlider.Parent = editPanel.SkinOffsetFrame;
			
			modComponents.CreateSlider(Interface, {
				Button=textureOffsetXSlider;
				RangeInfo={Min=-400; Max=400; Scale=100; Default=0; ValueType="Flat";};
				SetFunc=function(v)
					Debugger:StudioWarn("Set TextureOffsetX=", v);
				end;
				DisplayValueFunc=function(v)
					return v;
				end;
			});
			modComponents.CreateSlider(Interface, {
				Button=textureOffsetYSlider;
				RangeInfo={Min=-400; Max=400; Scale=100; Default=0; ValueType="Flat";};
				SetFunc=function(v)
					Debugger:StudioWarn("Set TextureOffsetY=", v);
				end;
				DisplayValueFunc=function(v)
					return v;
				end;
			});

			-- Texture Scale
			local textureScaleXSlider = modComponents.NewSliderButton() :: TextButton;
			textureScaleXSlider.AnchorPoint = Vector2.new(1, 0);
			textureScaleXSlider.Position = UDim2.new(1, -110, 0, 0);
			textureScaleXSlider.Size = UDim2.new(0, 95, 0, 30);
			textureScaleXSlider.Parent = editPanel.SkinScaleFrame;

			local textureScaleYSlider = textureScaleXSlider:Clone();
			textureScaleYSlider.Position = UDim2.new(1, -5, 0, 0);
			textureScaleYSlider.Parent = editPanel.SkinScaleFrame;
			
			modComponents.CreateSlider(Interface, {
				Button=textureScaleXSlider;
				RangeInfo={Min=-400; Max=400; Scale=100; Default=0; ValueType="Flat";};
				SetFunc=function(v)
					Debugger:StudioWarn("Set TextureScaleX=", v);
				end;
				DisplayValueFunc=function(v)
					return v;
				end;
			});
			modComponents.CreateSlider(Interface, {
				Button=textureScaleYSlider;
				RangeInfo={Min=-400; Max=400; Scale=100; Default=0; ValueType="Flat";};
				SetFunc=function(v)
					Debugger:StudioWarn("Set TextureScaleY=", v);
				end;
				DisplayValueFunc=function(v)
					return v;
				end;
			});

			-- Texture Transparency;
			local textureAlphaSlider = modComponents.NewSliderButton() :: TextButton;
			textureAlphaSlider.AnchorPoint = Vector2.new(1, 0);
			textureAlphaSlider.Position = UDim2.new(1, -5,0, 0);
			textureAlphaSlider.Size = UDim2.new(0, 200, 0, 30);
			textureAlphaSlider.Parent = editPanel.SkinTransparencyFrame;

			modComponents.CreateSlider(Interface, {
				Button=textureAlphaSlider;
				RangeInfo={Min=0; Max=100; Scale=100; Default=0; ValueType="Flat";};
				SetFunc=function(v)
					Debugger:StudioWarn("Set Texture Transparency=", v);
				end;
				DisplayValueFunc=function(v)
					return v;
				end;
			});

			-- PartOffsetFrame
			local partOffsetXSlider = modComponents.NewSliderButton() :: TextButton;
			partOffsetXSlider.AnchorPoint = Vector2.new(1, 0);
			partOffsetXSlider.Position = UDim2.new(1, -143, 0, 0);
			partOffsetXSlider.Size = UDim2.new(0, 63, 0, 30);
			partOffsetXSlider.Parent = editPanel.PartOffsetFrame;

			local partOffsetYSlider = partOffsetXSlider:Clone();
			partOffsetXSlider.Position = UDim2.new(1, -74, 0, 0);
			partOffsetYSlider.Parent = editPanel.PartOffsetFrame;

			local partOffsetZSlider = partOffsetXSlider:Clone();
			partOffsetZSlider.Position = UDim2.new(1, -5, 0, 0);
			partOffsetZSlider.Parent = editPanel.PartOffsetFrame;

			modComponents.CreateSlider(Interface, {
				Button=partOffsetXSlider;
				RangeInfo={Min=-100; Max=100; Scale=100; Default=0; ValueType="Flat";};
				SetFunc=function(v)
					Debugger:StudioWarn("Set PartOffset.X=", v);
				end;
				DisplayValueFunc=function(v)
					return v;
				end;
			});
			
			modComponents.CreateSlider(Interface, {
				Button=partOffsetYSlider;
				RangeInfo={Min=-100; Max=100; Scale=100; Default=0; ValueType="Flat";};
				SetFunc=function(v)
					Debugger:StudioWarn("Set PartOffset.X=", v);
				end;
				DisplayValueFunc=function(v)
					return v;
				end;
			});
			
			modComponents.CreateSlider(Interface, {
				Button=partOffsetZSlider;
				RangeInfo={Min=-100; Max=100; Scale=100; Default=0; ValueType="Flat";};
				SetFunc=function(v)
					Debugger:StudioWarn("Set PartOffset.X=", v);
				end;
				DisplayValueFunc=function(v)
					return v;
				end;
			});

			-- Texture Transparency;
			local reflectanceSlider = modComponents.NewSliderButton() :: TextButton;
			reflectanceSlider.AnchorPoint = Vector2.new(1, 0);
			reflectanceSlider.Position = UDim2.new(1, -5, 0, 0);
			reflectanceSlider.Size = UDim2.new(0, 200, 0, 30);
			reflectanceSlider.Parent = editPanel.ReflectanceFrame;

			modComponents.CreateSlider(Interface, {
				Button=reflectanceSlider;
				RangeInfo={Min=0; Max=100; Scale=100; Default=0; ValueType="Flat";};
				SetFunc=function(v)
					Debugger:StudioWarn("Set Reflectance=", v);
				end;
				DisplayValueFunc=function(v)
					return v;
				end;
			});

		end

		editPanel:GetPropertyChangedSignal("Visible"):Connect(function()
			hintLabel.Visible = not editPanel.Visible;
		end)

		saveGroupNameButton.MouseButton1Click:Connect(function()
			activeGroupName = selectTextbox.Text;
			saveGroupNameButton.Visible = false;

			Debugger:StudioWarn("Save group name", selectTextbox.Text);
		end)

		local selectGroupTextChangeConn;
		garbage:Tag(function()
			if selectGroupTextChangeConn then
				selectGroupTextChangeConn:Disconnect();
				selectGroupTextChangeConn = nil;
			end
		end)
		
		selectTextbox:GetPropertyChangedSignal("CursorPosition"):Connect(function()
			selectTextbox.CursorPosition = selectTextbox.CursorPosition > 0 and math.clamp(selectTextbox.CursorPosition, math.min(2, #selectTextbox.Text-1), #selectTextbox.Text) or -1;
		end)

		local function newSelection(selectionPartData, predefinedGroup)
			if selectGroupTextChangeConn then selectGroupTextChangeConn:Disconnect(); selectGroupTextChangeConn=nil; end;

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
			if predefinedGroup then
				activeGroupName = predefinedGroup;
			end

			editPanel.Visible = true;
			selectTextbox.Text = "";

			local partNames = {};
			for a=1, #selectionPartData do
				table.insert(partNames, selectionPartData[a].Name);
			end;
			
			if predefinedGroup or #selectionPartData > 1 then
				selectTextbox.Text = `[{groupName}]`;
				selectTextbox.PlaceholderText = "";
				infoLabel.Text = `Type: Group`; --    Layer: 0
				partLabel.Text = `<font size="14"><b>Grouped Parts:</b></font> {table.concat(partNames, ", ")}`;
				selectTextbox.TextEditable = true;
			
			else
				local partData = selectionPartData[1];
				selectTextbox.Text = "";
				selectTextbox.PlaceholderText = partData.Name;
				infoLabel.Text = `Type: Part`;
				partLabel.Text = `<font size="14"><b>Part Group:</b> {partData.PredefinedGroup or "None"}</font>`;
				selectTextbox.TextEditable = false;

			end

			local function onTextBoxUpdate()
				if not selectTextbox.TextEditable then return end;

				local cap1 = string.match(selectTextbox.Text, "%[(.*)%]") or "";
				groupName = string.gsub(cap1, "[^%a%d]*", "") or "New Group";
				groupName = groupName:sub(1, 16);
				
				selectTextbox.Text = `[{groupName}]`;
				selectTextbox.CursorPosition = math.clamp(selectTextbox.CursorPosition, 2, #selectTextbox.Text);

				if selectTextbox.Text ~= activeGroupName then
					saveGroupNameButton.Visible = true;
				end
			end
			selectGroupTextChangeConn = selectTextbox:GetPropertyChangedSignal("Text"):Connect(onTextBoxUpdate);
			onTextBoxUpdate();

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
	
			function newDropDownList:OnNewButton(index, optionButton)
				local selectionName = optionButton.Name;

				if customizationCache[selectionName] then
					local customizeData = customizationCache[selectionName];
					
					if customizeData.GroupId then
						optionButton.Text = optionButton.Text..` [{customizeData.GroupId}]`;
					else
						optionButton.Text = optionButton.Text..`*`;
					end
				end

			end

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
	
			newDropDownList:LoadOptions(groupPartList);
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