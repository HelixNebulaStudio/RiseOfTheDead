local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Workbench = {};
local Interface;

local player = game.Players.LocalPlayer;
local UserInputService = game:GetService("UserInputService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);
local modCustomizationData = require(game.ReplicatedStorage.Library.CustomizationData);
local modColorsLibrary = require(game.ReplicatedStorage.Library.ColorsLibrary);
local modItemSkinsLibrary = require(game.ReplicatedStorage.Library.ItemSkinsLibrary);

local modDropdownList = require(game.ReplicatedStorage.Library.UI.DropdownList);
local modComponents = require(game.ReplicatedStorage.Library.UI.Components);
local modColorPicker = require(game.ReplicatedStorage.Library.UI.ColorPicker);

local remoteCustomizationData = modRemotesManager:Get("CustomizationData") :: RemoteFunction;

local modData = require(player:WaitForChild("DataModule") :: ModuleScript);

local templateMainFrame = script.Parent:WaitForChild("CustomizationMain");
local templateDropDownLabel = script.Parent:WaitForChild("DropDownLabel");
local templateColorOption = game.ReplicatedStorage.Library.UI.ColorPicker.ColorOption;

local garbage = modGarbageHandler.new();
local firstSync = false;
--==

function Workbench.init(interface)
	Interface = interface;
	return Workbench;
end

function Workbench.new(itemId, appearanceLib, storageItem)
	if firstSync == false then
		firstSync = true;

		modData:RequestData("ColorPacks");
		modData:RequestData("SkinsPacks");
		modData:GetFlag("CustomColors", true);
	end

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

	local emptyCustomPlan = modCustomizationData.newCustomizationPlan();

	type PartData = {
		Name: string; 
		Part: BasePart; 
		DisplayModelData: {
			Prefab: Model; 
			BasePrefab: Model; 
			Prefix: string; 
			WeldName: string; 
			Offset: CFrame;
		};
		PredefinedGroup: string?;
	}
	type PartSelection = {[number]:PartData};
	function listMenu:Refresh()
		Debugger:StudioWarn("Select refresh");

		local activeGroupName = nil;
		local activePartSelection: PartSelection = nil;
		local customizationPlanCache = {};

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
					predefinedGroup = predefinedGroup and `[{predefinedGroup}]` or nil;

					local modelPartData = {
						Name=prefix..basePart.Name;
						Part=basePart;
						DisplayModelData = displayModelData;
						PredefinedGroup = predefinedGroup;
					};

					if predefinedGroup and table.find(groupsList, predefinedGroup) == nil then
						table.insert(groupsList, predefinedGroup);
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

		local colorPickerObj = modColorPicker.new(Interface);
		local colorFrame = colorPickerObj.Frame;
		colorFrame.Size = UDim2.new(0, 310, 0, 300);
		colorFrame.UIGradient:Destroy();
		colorFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50);
		colorFrame.Content.BackgroundTransparency = 1;
		colorFrame.Content.Position = UDim2.new(0, 0, 0, 0);
		colorFrame.Content.Size = UDim2.new(1, 0, 1, 0);
		colorFrame.Content.Advance.Visible = false;
		colorFrame.Content.ColorPalette.Size = UDim2.new(1, 0, 1, 0);
		colorFrame.NameTag.Visible = false;
		colorFrame.touchCloseButton.Visible = false;
		garbage:Tag(function()
			colorPickerObj:Destroy();
		end);

		local newDropDownList = modDropdownList.new();
		local dropDownFrame: Frame = newDropDownList.Frame;
		dropDownFrame.Size = UDim2.new(1, 0, 1, 0);
		garbage:Tag(dropDownFrame);
		newDropDownList.Frame.Parent = scrollFrame;
	
		newDropDownList.Frame:GetPropertyChangedSignal("Visible"):Connect(function()
			if newDropDownList.Frame.Visible then 
				newDropDownList.ScrollFrame.CanvasPosition = Vector2.zero;
				return 
			end;
			colorPickerObj.Frame.Parent = nil;
			colorFrame.Visible = false;
		end)

		local mainFrame = templateMainFrame:Clone();
		garbage:Tag(mainFrame);
		mainFrame.Parent = scrollFrame;
	
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

		local selectTextbox: TextBox = mainFrame:WaitForChild("SelectTextbox");
		local saveGroupNameButton = selectTextbox:WaitForChild("SaveButton") :: TextButton;
		local selectDropButton = selectTextbox:WaitForChild("SelectDropButton") :: TextButton;

		local editPanel = mainFrame:WaitForChild("EditPanel") :: Frame;
		local hintLabel: TextLabel = mainFrame:WaitForChild("HintLabel");
		local infoLabel: TextLabel = editPanel:WaitForChild("InfoLabel");
		local partLabel: TextLabel = editPanel:WaitForChild("PartList");

		-- MARK: function declarations;
		local newSelection;

		-- MARK: UpdateCustomizations;
		local function updateCustomization(func)
			if activePartSelection == nil then return end;

			for a=1, #activePartSelection do
				local partData = activePartSelection[a];

				if customizationPlanCache[partData.Name] == nil then
					customizationPlanCache[partData.Name] = modCustomizationData.newCustomizationPlan();
				end

				func(customizationPlanCache[partData.Name], partData);
				
				editPanel.serializeText.Text = customizationPlanCache[partData.Name]:Serialize();
			end
		end


		-- MARK: OpenColorCustomizations;
		local function OpenColorCustomizations(onSelectFunc)
			local customColors = modData:GetFlag("CustomColors");
			local colorGroupOptionsList = {
				"ColorPickerLabel";
				"ColorPicker";
			};
			local colorPacksList = {};

			-- Load Unique Colors;
			if customColors then
				local uniqueColors = {Name="Unique Colors"; LayoutOrder=0; List={}; Owned=true; CustomColors=true;};

				local orderList = {};
				for hex, _ in pairs(customColors.Unlocked) do
					local color = Color3.fromHex(hex);
					if modColorPicker.IsInColorPicker(color) then continue end;
					local h, s, v = color:ToHSV();
					local hLayer = math.floor(h*255/10)*10;
					table.insert(orderList, {Id=hex; Value=(hLayer*10000 + v*1000 + s*255);});
				end
				table.sort(orderList, function(a, b) 
					return a.Value > b.Value;
				end);

				for a=1, #orderList do
					local hex = orderList[a].Id;
					local customId = "#"..hex;

					local getColor = modColorsLibrary.Get(customId);
					table.insert(uniqueColors.List, getColor);
				end

				if #orderList > 0 then
					table.insert(colorGroupOptionsList, "UniqueColorsLabel");
					table.insert(colorGroupOptionsList, "UniqueColors");
					modColorsLibrary.Packs.UniqueColors = uniqueColors;
				end
			end
			table.insert(colorGroupOptionsList, "ColorPacksLabel");

			-- Load Color Packs;
			for packId, packInfo in pairs(modColorsLibrary.Packs) do
				if packId == "UniqueColors" then continue end;
				table.insert(colorPacksList, packId);
			end
			table.sort(colorPacksList, function(a, b)
				local packInfoA = modColorsLibrary.Packs[a];
				local packInfoB = modColorsLibrary.Packs[b];
				return ((packInfoA.Owned and 0 or 100) + (packInfoA.LayoutOrder or 0)) < ((packInfoB.Owned and 0 or 100) + (packInfoB.LayoutOrder or 0))
			end)
			for a=1, #colorPacksList do
				table.insert(colorGroupOptionsList, colorPacksList[a]);
			end
			

			function newDropDownList:OnNewButton(index, optionButton: TextButton)
				local selectionName = optionButton.Name;
				if selectionName == "ColorPicker" then
					optionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50);
					optionButton.AutoButtonColor = false;
					optionButton.AutomaticSize = Enum.AutomaticSize.Y;
					colorFrame.Parent = optionButton;
					
					if customColors then
						colorPickerObj:SetUnlocked(customColors.Unlocked);
					end
					function colorPickerObj:OnColorSelect(selectColor, colorName, colorLabel)
						if colorLabel:FindFirstChild("LockedTemplate") then
							Debugger:StudioWarn("Selection locked");
							return;
						end

						Interface:PlayButtonClick();
						if onSelectFunc then
							onSelectFunc(selectColor);
						end

						dropDownFrame.Visible = false;
					end
					colorFrame.Visible = true;

				elseif selectionName:sub(#selectionName-4, #selectionName) == "Label" then
					
					local newDdLabel = templateDropDownLabel:Clone();
					newDdLabel.LayoutOrder = optionButton.LayoutOrder;
					local label = newDdLabel:WaitForChild("TextLabel");
					newDdLabel.Parent = newDropDownList.ScrollFrame;

					if selectionName == "ColorPickerLabel" then
						label.Text = "Color Palette";
					elseif selectionName == "UniqueColorsLabel" then
						label.Text = "Custom Colors";
					elseif selectionName == "ColorPacksLabel" then
						label.Text = "Color Packs";
					end
					optionButton:Destroy();

				elseif modColorsLibrary.Packs[selectionName] then
					local colorPackInfo = modColorsLibrary.Packs[selectionName];
					local isOwned = colorPackInfo.Owned;

					optionButton.AutomaticSize = Enum.AutomaticSize.Y;
					optionButton.TextYAlignment = Enum.TextYAlignment.Top;
					optionButton.AutoButtonColor = false;

					optionButton.BackgroundColor3 = isOwned and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(30, 30, 30);
					optionButton.TextColor3 = isOwned and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100);

					local padding = Instance.new("UIPadding");
					padding.PaddingLeft = UDim.new(0, 5);
					padding.PaddingRight = UDim.new(0, 5);
					padding.PaddingBottom = UDim.new(0, 10);
					padding.PaddingTop = UDim.new(0, 10);
					padding.Parent = optionButton;

					local colorsFrame = Instance.new("Frame");
					colorsFrame.Position = UDim2.new(0, 0, 0, 25);
					colorsFrame.Size = UDim2.new(1, 0, 0, 0);
					colorsFrame.Parent = optionButton;

					if selectionName == "UniqueColors" then
						colorsFrame.Position = UDim2.new(0, 0, 0, 0);
						optionButton.TextTransparency = 1;
					end

					local gridLayout = Instance.new("UIGridLayout");
					gridLayout.CellSize = UDim2.new(0, 25, 0, 25);
					gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
					gridLayout.Parent = colorsFrame;

					local selectionHighlight = templateColorOption.Parent.SelectTemplate:Clone();
					selectionHighlight.Parent = nil;

					for a=1, #colorPackInfo.List do
						local colorInfo = colorPackInfo.List[a];
						local newColorOption = templateColorOption:Clone() :: ImageButton;
						newColorOption.ImageColor3 = colorInfo.Color;
						newColorOption.Parent = colorsFrame;

						if not isOwned then
							local newLocked = templateColorOption.Parent.LockedTemplate:Clone();
							newLocked.ImageColor3 = modColorPicker.GetBackColor(colorInfo.Color);
							newLocked.Parent = newColorOption;
						end

						newColorOption.MouseMoved:Connect(function()
							if not isOwned then return end;
							selectionHighlight.Parent = newColorOption;
						end)
						newColorOption.MouseLeave:Connect(function()
							selectionHighlight.Parent = nil;
						end)

						newColorOption.MouseButton1Click:Connect(function() 
							if not isOwned then return end;
							Interface:PlayButtonClick();

							if onSelectFunc then
								onSelectFunc(colorInfo.Color);
							end

							dropDownFrame.Visible = false;
						end)
					end

				end
			end

			function newDropDownList:OnOptionSelect(index, optionButton)
				Debugger:StudioWarn("index", index, "optionButton", optionButton);
				
			end
	
			newDropDownList:LoadOptions(colorGroupOptionsList);
			toggleVisibility(dropDownFrame);

		end

		-- MARK: OpenSkinCustomizations;
		local function OpenSkinCustomizations(onSelectFunc)
			-- Get Owned Skins;
			local unlockedSkins = {};
			if storageItem.Values.Skins then
				for _, oldSkinId in pairs(storageItem.Values.Skins) do
					local skinId = modItemSkinsLibrary.GetSkinIdFromOldId(oldSkinId);
					if skinId then
						unlockedSkins[skinId] = true;
					end
				end
			end
			if modData.Profile.SkinsPacks then
				for skinId, _ in pairs(modData.Profile.SkinsPacks) do
					if modItemSkinsLibrary:Find(skinId) then
						unlockedSkins[skinId] = true;
						break;
					end

					skinId = modItemSkinsLibrary.GetSkinIdFromOldId(skinId);
					if skinId then
						unlockedSkins[skinId] = true;
					end
				end
			end
			
			-- Load Skin Packs;
			local skinPackOptionsList = {"PatternsLabel";};
			local skinPacksList = {};
			local texturePhase = false;
			for index, skinInfo in pairs(modItemSkinsLibrary:GetIndexList()) do
				if skinInfo.Type == modItemSkinsLibrary.SkinType.Texture and skinInfo.Textures[storageItem.ItemId] == nil then
					continue;
				end
				if skinInfo.Type == modItemSkinsLibrary.SkinType.Texture and texturePhase == false then
					texturePhase = true;
					table.insert(skinPackOptionsList, "TexturesLabel");
				end

				table.insert(skinPackOptionsList, skinInfo.Name);
				table.insert(skinPacksList, skinInfo);
			end
			table.insert(skinPackOptionsList, "LockedLabel");

			local selctionStroke = Instance.new("UIStroke");
			selctionStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
			selctionStroke.Color = Color3.fromRGB(255, 255, 255);
			selctionStroke.Thickness = 4;
			selctionStroke.Parent = nil;

			function newDropDownList:OnNewButton(index, optionButton: TextButton)
				local selectionName = optionButton.Name;
				if selectionName:sub(#selectionName-4, #selectionName) == "Label" then
					
					local newDdLabel = templateDropDownLabel:Clone();
					newDdLabel.LayoutOrder = optionButton.LayoutOrder;
					local label = newDdLabel:WaitForChild("TextLabel");
					newDdLabel.Parent = newDropDownList.ScrollFrame;

					if selectionName == "PatternsLabel" then
						label.Text = "Patterns";
						optionButton.LayoutOrder = 0;

					elseif selectionName == "TexturesLabel" then
						label.Text = "Skins";
						optionButton.LayoutOrder = 1000;

					elseif selectionName == "LockedLabel" then
						label.Text = "Locked";
						optionButton.LayoutOrder = 1500;

					end
					optionButton:Destroy();

					return;
				end

				local skinInfo = nil;
				for a=1, #skinPacksList do
					if skinPacksList[a].Name == selectionName then
						skinInfo = skinPacksList[a];
						break;
					end
				end
				if skinInfo == nil then return end;

				local isUnlocked = unlockedSkins[skinInfo.Id];

				if not isUnlocked then
					if skinInfo.Type == modItemSkinsLibrary.SkinType.Pattern then
						optionButton.LayoutOrder = 500+index

					elseif skinInfo.Type == modItemSkinsLibrary.SkinType.Texture then
						optionButton.LayoutOrder = 1500+index

					end
				end

				optionButton.AutomaticSize = Enum.AutomaticSize.Y;
				optionButton.TextYAlignment = Enum.TextYAlignment.Top;
				optionButton.AutoButtonColor = false;
				optionButton.Size = UDim2.new(1, 0, 0, 0);

				local padding = Instance.new("UIPadding");
				padding.PaddingTop = UDim.new(0, 10);
				padding.PaddingBottom = UDim.new(0, 15);
				padding.PaddingLeft = UDim.new(0, 10);
				padding.PaddingRight = UDim.new(0, 10);
				padding.Parent = optionButton;

				optionButton.BackgroundColor3 = isUnlocked and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(30, 30, 30);
				optionButton.TextColor3 = isUnlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100);
				
				local gridFrame = Instance.new("Frame");
				gridFrame.BackgroundTransparency = 1;
				gridFrame.AutomaticSize = Enum.AutomaticSize.Y;
				gridFrame.Position = UDim2.new(0, 0, 0, 30);
				gridFrame.Size = UDim2.new(1, 0, 0, 0);
				gridFrame.ZIndex = 3;
				gridFrame.Parent = optionButton;

				local gridLayout = Instance.new("UIGridLayout");
				gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
				gridLayout.CellSize = UDim2.new(0, 60, 0, 60);
				gridLayout.Parent = gridFrame;

				if skinInfo.Type == modItemSkinsLibrary.SkinType.Pattern then
					local packIcon = Instance.new("ImageButton");
					packIcon.ZIndex = 3;
					packIcon.BackgroundTransparency = 1;
					packIcon.Image = skinInfo.Icon;
					packIcon.Parent = gridFrame;

					for a=1, #skinInfo.Patterns do
						local patternData = skinInfo.Patterns[a];

						local newPatternButton = Instance.new("ImageButton");
						newPatternButton.AutoButtonColor = false;
						newPatternButton.ZIndex = 3;
						newPatternButton.Name = patternData.Id;
						newPatternButton.Image = patternData.Image;

						newPatternButton.BackgroundColor3 = isUnlocked and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(70, 70, 70);
						newPatternButton.ImageColor3 = isUnlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150);

						local corner = Instance.new("UICorner");
						corner.CornerRadius = UDim.new(0, 5);
						corner.Parent = newPatternButton;
						newPatternButton.Parent = gridFrame;
						
						newPatternButton.MouseMoved:Connect(function()
							if not isUnlocked then return end;
							selctionStroke.Parent = newPatternButton;
						end)

						newPatternButton.MouseLeave:Connect(function()
							selctionStroke.Parent = nil;
						end)

						newPatternButton.MouseButton1Click:Connect(function() 
							if not isUnlocked then return end;
							Interface:PlayButtonClick();

							if onSelectFunc then
								onSelectFunc(skinInfo.Id, patternData.Id);
							end

							dropDownFrame.Visible = false;
						end)

					end

				elseif skinInfo.Type == modItemSkinsLibrary.SkinType.Texture then
					local textureData = skinInfo.Textures[itemId];
					
					if textureData then
						local newTextureButton = Instance.new("ImageButton");
						newTextureButton.AutoButtonColor = false;
						newTextureButton.ZIndex = 3;
						newTextureButton.Name = textureData.Id;
						newTextureButton.Image = textureData.Icon;

						newTextureButton.BackgroundColor3 = isUnlocked and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(70, 70, 70);
						newTextureButton.ImageColor3 = isUnlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150);

						local corner = Instance.new("UICorner");
						corner.CornerRadius = UDim.new(0, 5);
						corner.Parent = newTextureButton;
						newTextureButton.Parent = gridFrame;
						
						newTextureButton.MouseMoved:Connect(function()
							if not isUnlocked then return end;
							selctionStroke.Parent = newTextureButton;
						end)

						newTextureButton.MouseLeave:Connect(function()
							selctionStroke.Parent = nil;
						end)

						newTextureButton.MouseButton1Click:Connect(function() 
							if not isUnlocked then return end;
							Interface:PlayButtonClick();

							if onSelectFunc then
								onSelectFunc(skinInfo.Id, textureData.Id);
							end

							dropDownFrame.Visible = false;
						end)

					end

				end


			end
			
			function newDropDownList:OnOptionSelect(index, optionButton)
				Debugger:StudioWarn("index", index, "optionButton", optionButton);
				
			end
	
			newDropDownList:LoadOptions(skinPackOptionsList);
			toggleVisibility(dropDownFrame);
		end

		
		-- MARK: Part Color;
		local colorButton = editPanel.ColorFrame.Button;
		colorButton.MouseButton1Click:Connect(function()
			Interface:PlayButtonClick();
			OpenColorCustomizations(function(selectColor: Color3)
				colorButton.BackgroundColor3 = selectColor;
				colorButton.TextColor3 = modColorPicker.GetBackColor(selectColor);
				colorButton.Text = `#{selectColor:ToHex()}`;

				Debugger:StudioWarn("Set Color=", colorButton.Text);
				updateCustomization(function(customPlan, partData: PartData)
					customPlan.Color = selectColor;
					customPlan:Apply(partData.Part);
				end)
			end);
		end)


		-- MARK: Part Transparency
		local transparencySlider = modComponents.NewSliderButton() :: TextButton;
		transparencySlider.AnchorPoint = Vector2.new(1, 0);
		transparencySlider.Position = UDim2.new(1, -5,0, 0);
		transparencySlider.Size = UDim2.new(0, 200, 0, 30);
		transparencySlider.Parent = editPanel.TransparencyFrame;

		local function onTransparencySet(v)
			Debugger:StudioWarn("Set Transparency=", v);
			updateCustomization(function(customPlan, partData: PartData)
				customPlan.Transparency = v;
				customPlan:Apply(partData.Part);
			end)

			return v;
		end
		modComponents.CreateSlider(Interface, {
			Button=transparencySlider;
			RangeInfo={Min=0; Max=100; Scale=100; Default=0; ValueType="Flat";};
			SetFunc=onTransparencySet;
			DisplayValueFunc=onTransparencySet;
		});


		-- MARK: Texture Skin;
		local textureSetButton = editPanel.SkinFrame.Button;
		textureSetButton.MouseButton1Click:Connect(function()
			Interface:PlayButtonClick();

			OpenSkinCustomizations(function(skinId, variantId)
				local skinLib, skinVariantData = modItemSkinsLibrary:FindVariant(skinId, variantId)
				Debugger:StudioWarn("Select Pattern", skinId, variantId, skinLib~=nil, skinVariantData~=nil);
				
				if skinLib.Type == modItemSkinsLibrary.SkinType.Pattern then
					editPanel.SkinColorFrame.Button.Image = skinVariantData.Image;
					editPanel.SkinFrame.Button.Image = skinVariantData.Image;
					editPanel.SkinFrame.Button.TextLabel.Text = `{skinLib.Name}: {skinVariantData.Name}`;

				elseif skinLib.Type == modItemSkinsLibrary.SkinType.Texture then
					editPanel.SkinColorFrame.Button.Image = skinVariantData.Icon;
					editPanel.SkinFrame.Button.Image = skinVariantData.Icon;
					editPanel.SkinFrame.Button.TextLabel.Text = `{skinLib.Name}`;

				end

				updateCustomization(function(customPlan, partData: PartData)
					customPlan.Skin = `{skinId}_{variantId}`;
					customPlan:Apply(partData.Part);
				end)
			end)
		end)

		-- MARK: Texture Color;
		local textureColorButton = editPanel.SkinColorFrame.Button;
		textureColorButton.MouseButton1Click:Connect(function()
			Interface:PlayButtonClick();
			OpenColorCustomizations(function(selectColor: Color3)
				textureColorButton.ImageColor3 = selectColor;
				textureColorButton.BackgroundColor3 = modColorPicker.GetBackColor(selectColor);
				textureColorButton.TextLabel.Text = `#{selectColor:ToHex()}`;
				textureColorButton.TextLabel.TextColor3 = modColorPicker.GetBackColor(selectColor);

				Debugger:StudioWarn("Set TextureColor=", textureColorButton.TextLabel.Text);
				updateCustomization(function(customPlan, partData: PartData)
					customPlan.PatternData.Color = selectColor;
					customPlan:Apply(partData.Part);
				end)
			end);
		end)


		-- MARK: Texture Offset
		local textureOffsetXSlider = modComponents.NewSliderButton() :: TextButton;
		textureOffsetXSlider.AnchorPoint = Vector2.new(1, 0);
		textureOffsetXSlider.Position = UDim2.new(1, -110, 0, 0);
		textureOffsetXSlider.Size = UDim2.new(0, 95, 0, 30);
		textureOffsetXSlider.Parent = editPanel.SkinOffsetFrame;

		local textureOffsetYSlider = textureOffsetXSlider:Clone();
		textureOffsetYSlider.Position = UDim2.new(1, -5, 0, 0);
		textureOffsetYSlider.Parent = editPanel.SkinOffsetFrame;
		
		local function onTextureOffsetX(v)
			Debugger:StudioWarn("Set TextureOffsetX=", v);
			updateCustomization(function(customPlan, partData: PartData)
				if customPlan.PatternData.Offset == nil then
					customPlan.PatternData.Offset = Vector2.zero;
				end
				customPlan.PatternData.Offset = Vector2.new(v, customPlan.PatternData.Offset.Y);
				customPlan:Apply(partData.Part);
			end)

			return v;
		end
		local function onTextureOffsetY(v)
			Debugger:StudioWarn("Set TextureOffsetY=", v);
			updateCustomization(function(customPlan, partData: PartData)
				if customPlan.PatternData.Offset == nil then
					customPlan.PatternData.Offset = Vector2.zero;
				end
				customPlan.PatternData.Offset = Vector2.new(customPlan.PatternData.Offset.X, v);
				customPlan:Apply(partData.Part);
			end)

			return v;
		end
		modComponents.CreateSlider(Interface, {
			Button=textureOffsetXSlider;
			RangeInfo={Min=-400; Max=400; Scale=100; Default=0; ValueType="Flat";};
			SetFunc=onTextureOffsetX;
			DisplayValueFunc=onTextureOffsetX;
		});
		modComponents.CreateSlider(Interface, {
			Button=textureOffsetYSlider;
			RangeInfo={Min=-400; Max=400; Scale=100; Default=0; ValueType="Flat";};
			SetFunc=onTextureOffsetY;
			DisplayValueFunc=onTextureOffsetY;
		});


		-- MARK: Texture Scale
		local textureScaleXSlider = modComponents.NewSliderButton() :: TextButton;
		textureScaleXSlider.AnchorPoint = Vector2.new(1, 0);
		textureScaleXSlider.Position = UDim2.new(1, -110, 0, 0);
		textureScaleXSlider.Size = UDim2.new(0, 95, 0, 30);
		textureScaleXSlider.Parent = editPanel.SkinScaleFrame;

		local textureScaleYSlider = textureScaleXSlider:Clone();
		textureScaleYSlider.Position = UDim2.new(1, -5, 0, 0);
		textureScaleYSlider.Parent = editPanel.SkinScaleFrame;
		
		local function onTextureScaleX(v)
			Debugger:StudioWarn("Set TextureScaleX=", v);
			updateCustomization(function(customPlan, partData: PartData)
				if customPlan.PatternData.Scale == nil then
					customPlan.PatternData.Scale = Vector2.new(1, 1);
				end
				customPlan.PatternData.Scale = Vector2.new(v, customPlan.PatternData.Scale.Y);
				customPlan:Apply(partData.Part);
			end)

			return v;
		end
		local function onTextureScaleY(v)
			Debugger:StudioWarn("Set TextureScaleY=", v);
			updateCustomization(function(customPlan, partData: PartData)
				if customPlan.PatternData.Scale == nil then
					customPlan.PatternData.Scale = Vector2.new(1, 1);
				end
				customPlan.PatternData.Scale = Vector2.new(customPlan.PatternData.Scale.X, v);
				customPlan:Apply(partData.Part);
			end)

			return v;
		end
		modComponents.CreateSlider(Interface, {
			Button=textureScaleXSlider;
			RangeInfo={Min=10; Max=400; Scale=100; Default=100; ValueType="Flat";};
			SetFunc=onTextureScaleX;
			DisplayValueFunc=onTextureScaleX;
		});
		modComponents.CreateSlider(Interface, {
			Button=textureScaleYSlider;
			RangeInfo={Min=10; Max=400; Scale=100; Default=100; ValueType="Flat";};
			SetFunc=onTextureScaleY;
			DisplayValueFunc=onTextureScaleY;
		});


		-- MARK: Texture Transparency;
		local textureAlphaSlider = modComponents.NewSliderButton() :: TextButton;
		textureAlphaSlider.AnchorPoint = Vector2.new(1, 0);
		textureAlphaSlider.Position = UDim2.new(1, -5,0, 0);
		textureAlphaSlider.Size = UDim2.new(0, 200, 0, 30);
		textureAlphaSlider.Parent = editPanel.SkinTransparencyFrame;

		local function onTextureAlphaSet(v)
			Debugger:StudioWarn("Set TextureAlpha=", v);
			updateCustomization(function(customPlan, partData: PartData)
				customPlan.PatternData.Transparency = v;
				customPlan:Apply(partData.Part);
			end)

			return v;
		end
		modComponents.CreateSlider(Interface, {
			Button=textureAlphaSlider;
			RangeInfo={Min=0; Max=100; Scale=100; Default=0; ValueType="Flat";};
			SetFunc=onTextureAlphaSet;
			DisplayValueFunc=onTextureAlphaSet;
		});


		-- MARK: PartOffsetFrame
		local partOffsetXSlider = modComponents.NewSliderButton() :: TextButton;
		partOffsetXSlider.AnchorPoint = Vector2.new(1, 0);
		partOffsetXSlider.Position = UDim2.new(1, -143, 0, 0);
		partOffsetXSlider.Size = UDim2.new(0, 63, 0, 30);
		partOffsetXSlider.Parent = editPanel.PartOffsetFrame;

		local partOffsetYSlider = partOffsetXSlider:Clone();
		partOffsetYSlider.Position = UDim2.new(1, -74, 0, 0);
		partOffsetYSlider.Parent = editPanel.PartOffsetFrame;

		local partOffsetZSlider = partOffsetXSlider:Clone();
		partOffsetZSlider.Position = UDim2.new(1, -5, 0, 0);
		partOffsetZSlider.Parent = editPanel.PartOffsetFrame;

		local function onPartOffsetX(v)
			Debugger:StudioWarn("Set PartOffset.X=", v);
			updateCustomization(function(customPlan, partData: PartData)
				if customPlan.PositionOffset == nil then
					customPlan.PositionOffset = Vector3.zero;
				end
				customPlan.PositionOffset = Vector3.new(
					v,
					customPlan.PositionOffset.Y,
					customPlan.PositionOffset.Z
				);
				customPlan:Apply(partData.Part);
			end)

			return v;
		end
		modComponents.CreateSlider(Interface, {
			Button=partOffsetXSlider;
			RangeInfo={Min=-100; Max=100; Scale=100; Default=0; ValueType="Flat";};
			SetFunc=onPartOffsetX;
			DisplayValueFunc=onPartOffsetX;
		});
		
		local function onPartOffsetY(v)
			Debugger:StudioWarn("Set PartOffset.Y=", v);
			updateCustomization(function(customPlan, partData: PartData)
				if customPlan.PositionOffset == nil then
					customPlan.PositionOffset = Vector3.zero;
				end
				customPlan.PositionOffset = Vector3.new(
					customPlan.PositionOffset.X,
					v,
					customPlan.PositionOffset.Z
				);
				customPlan:Apply(partData.Part);
			end)

			return v;
		end
		modComponents.CreateSlider(Interface, {
			Button=partOffsetYSlider;
			RangeInfo={Min=-100; Max=100; Scale=100; Default=0; ValueType="Flat";};
			SetFunc=onPartOffsetY;
			DisplayValueFunc=onPartOffsetY;
		});
		
		local function onPartOffsetZ(v)
			Debugger:StudioWarn("Set PartOffset.Z=", v);
			updateCustomization(function(customPlan, partData: PartData)
				if customPlan.PositionOffset == nil then
					customPlan.PositionOffset = Vector3.zero;
				end
				customPlan.PositionOffset = Vector3.new(
					customPlan.PositionOffset.X,
					customPlan.PositionOffset.Y,
					v
				);
				customPlan:Apply(partData.Part);
			end)

			return v;
		end
		modComponents.CreateSlider(Interface, {
			Button=partOffsetZSlider;
			RangeInfo={Min=-100; Max=100; Scale=100; Default=0; ValueType="Flat";};
			SetFunc=onPartOffsetZ;
			DisplayValueFunc=onPartOffsetZ;
		});


		-- MARK: Part Reflectance;
		local reflectanceSlider = modComponents.NewSliderButton() :: TextButton;
		reflectanceSlider.AnchorPoint = Vector2.new(1, 0);
		reflectanceSlider.Position = UDim2.new(1, -5, 0, 0);
		reflectanceSlider.Size = UDim2.new(0, 200, 0, 30);
		reflectanceSlider.Parent = editPanel.ReflectanceFrame;

		local function onReflectanceSet(v)
			Debugger:StudioWarn("Set Reflectance=", v);
			updateCustomization(function(customPlan, partData: PartData)
				customPlan.Reflectance = v;
				customPlan:Apply(partData.Part);
			end)

			return v;
		end
		modComponents.CreateSlider(Interface, {
			Button=reflectanceSlider;
			RangeInfo={Min=0; Max=100; Scale=100; Default=0; ValueType="Flat";};
			SetFunc=onReflectanceSet;
			DisplayValueFunc=onReflectanceSet;
		});


		-- MARK: Part Material
		local materialButton = editPanel.MaterialFrame.Button;
		materialButton.MouseButton1Click:Connect(function()
			Interface:PlayButtonClick();

			local materialOptionList = {};
			for index, matName in pairs(Enum.Material:GetEnumItems()) do
				if matName.Name == "Air" then continue end;
				table.insert(materialOptionList, matName.Name);
			end
			
			function newDropDownList:OnOptionSelect(index, optionButton)
				Debugger:StudioWarn("index", index, "optionButton", optionButton);
				
				Debugger:StudioWarn("Set Material=", optionButton);
				updateCustomization(function(customPlan, partData: PartData)
					local mat = nil;
					pcall(function()
						mat = Enum.Material[optionButton.Name];
					end)
					customPlan.Material = mat;
					customPlan:Apply(partData.Part);
				end)

				materialButton.Text = optionButton.Name;
				dropDownFrame.Visible = false;
			end
	
			newDropDownList:LoadOptions(materialOptionList);
			toggleVisibility(dropDownFrame);

		end)
			
		editPanel:GetPropertyChangedSignal("Visible"):Connect(function()
			hintLabel.Visible = not editPanel.Visible;
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

		saveGroupNameButton.MouseButton1Click:Connect(function()
			activeGroupName = selectTextbox.Text;
			saveGroupNameButton.Visible = false;

			for a=1, #activePartSelection do
				local partData = activePartSelection[a];
				partData.PredefinedGroup = activeGroupName;
			end

			table.insert(groupsList, activeGroupName);
			table.insert(groupPartList, #groupsList, activeGroupName);
			Debugger:StudioWarn("Save group name", selectTextbox.Text);
		end)

		-- MARK: PartLabelButton
		local partLabelButton = partLabel:WaitForChild("Button");
		partLabelButton.MouseButton1Click:Connect(function()
			Interface:PlayButtonClick();

			if partLabelButton.Text == "+" then
				Debugger:StudioWarn("Add part to group", activeGroupName);

				function newDropDownList:OnOptionSelect(index, optionButton)
					Debugger:StudioWarn("index", index, "optionButton", optionButton);
					dropDownFrame.Visible = false;
	
					local modelPartData = nil;
					for a=1, #modelParts do
						if modelParts[a].Name == optionButton.Name then
							modelPartData = modelParts[a];
							break;
						end
					end
					if modelPartData and table.find(activePartSelection, modelPartData) == nil then
						table.insert(activePartSelection, modelPartData);
						partLabel.Text = partLabel.Text..`, {modelPartData.Name}`;
					end
				end
				
				local partDropDownList = {};
				for a=1, #modelParts do
					if table.find(activePartSelection, modelParts[a]) == nil then
						table.insert(partDropDownList, modelParts[a].Name);
					end
				end

				newDropDownList:LoadOptions(partDropDownList);
				toggleVisibility(dropDownFrame);

			elseif partLabelButton.Text == "⦿" then
				Debugger:StudioWarn("Select group of part", activeGroupName);

				local selectionPartData = {};

				for a=1, #modelParts do
					if activeGroupName and modelParts[a].PredefinedGroup == activeGroupName then
						table.insert(selectionPartData, modelParts[a]);
					end
				end

				newSelection(selectionPartData, activeGroupName);
			end
		end)

		-- MARK: newSelection;
		function newSelection(selectionPartData, predefinedGroup)
			dropDownFrame.Visible = false;
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
			activePartSelection = selectionPartData :: PartSelection;

			Debugger:StudioWarn("selectionPartData", selectionPartData, "predefinedGroup", predefinedGroup);
			
			selectTextbox.Text = "";
			if #selectionPartData <= 0 then
				editPanel.Visible = false;
				activeGroupName = nil;
				return; 
			end

			local groupName = predefinedGroup or "[New Group]";
			if predefinedGroup then
				activeGroupName = predefinedGroup;
			end

			editPanel.Visible = true;

			local partNames = {};
			for a=1, #selectionPartData do
				table.insert(partNames, selectionPartData[a].Name);
			end;
			
			if predefinedGroup or #selectionPartData > 1 then
				selectTextbox.Text = groupName;
				selectTextbox.PlaceholderText = "";
				infoLabel.Text = `<b>Type:</b> Group`; --    Layer: 0
				partLabel.Text = `<font size="14"><b>Group Parts:</b></font> {table.concat(partNames, ", ")}`;
				selectTextbox.TextEditable = true;
				
				partLabelButton.Text = "+";

			else
				local partData = selectionPartData[1];
				selectTextbox.Text = "";
				selectTextbox.PlaceholderText = partData.Name;
				infoLabel.Text = `<b>Type:</b> Part`;
				partLabel.Text = `<font size="14"><b>Part Group:</b> {partData.PredefinedGroup or "None"}</font>`;
				selectTextbox.TextEditable = false;

				if partData.PredefinedGroup then
					activeGroupName = partData.PredefinedGroup;
				end

				partLabelButton.Text = "⦿";

			end

			for a=1, #selectionPartData do
				local partData = selectionPartData[a];
				if partData.DisplayModelData and partData.DisplayModelData.Prefab then
					local defaultPartName = string.gsub(partData.Name, partData.DisplayModelData.Prefix, "");
					local defaultPart = partData.DisplayModelData.BasePrefab:FindFirstChild(defaultPartName);
					partData.Part:SetAttribute("DefaultColor", defaultPart.Color);
					partData.Part:SetAttribute("DefaultTransparency", defaultPart.Transparency);
					partData.Part:SetAttribute("DefaultMaterial", defaultPart.Material);
					partData.Part:SetAttribute("DefaultReflectance", defaultPart.Reflectance);
				end
			end

			do -- MARK: selection update
				local partData = selectionPartData[1];

				if partData then
					local partName = partData.Name;

					local basePart: BasePart = partData.Part;
					local planObj = partName and customizationPlanCache[partName] or emptyCustomPlan;

					local newColor = planObj.Color or basePart:GetAttribute("DefaultColor");
					if newColor then
						local colorButton = editPanel.ColorFrame.Button;
						colorButton.BackgroundColor3 = newColor;
						colorButton.TextColor3 = modColorPicker.GetBackColor(newColor);
						colorButton.Text = `#{newColor:ToHex()}`;
					end

					local newSkin = planObj.Skin;
					local skinId, variantId = string.match(newSkin or "", "(.*)_(.*)");
					local skinLib, skinVariantData = modItemSkinsLibrary:FindVariant(skinId, variantId)
					
					if skinId and skinVariantData then
						if skinLib.Type == modItemSkinsLibrary.SkinType.Pattern then
							editPanel.SkinColorFrame.Button.Image = skinVariantData.Image;
							editPanel.SkinFrame.Button.Image = skinVariantData.Image;
							editPanel.SkinFrame.Button.TextLabel.Text = `{skinLib.Name}: {skinVariantData.Name}`;
							
							local newPatternColor = planObj.PatternData.Color;
							if newPatternColor then
								editPanel.SkinColorFrame.Button.BackgroundColor3 = modColorPicker.GetBackColor(newPatternColor);
								editPanel.SkinColorFrame.Button.ImageColor3 = newPatternColor;
							end

							local newPatternOffset = planObj.PatternData.Offset or Vector2.zero;
							textureOffsetXSlider:SetAttribute("Value", newPatternOffset.X);
							textureOffsetYSlider:SetAttribute("Value", newPatternOffset.Y);
							
							local newPatternScale = planObj.PatternData.Scale or skinVariantData.DefaultScale or Vector2.one;
							textureScaleXSlider:SetAttribute("Value", newPatternScale.X);
							textureScaleYSlider:SetAttribute("Value", newPatternScale.Y);

							local newPatternAlpha = planObj.PatternData.Transparency or 0;
							transparencySlider:SetAttribute("Value", newPatternAlpha);

						elseif skinLib.Type == modItemSkinsLibrary.SkinType.Texture then
							editPanel.SkinColorFrame.Button.Image = skinVariantData.Icon;
							editPanel.SkinFrame.Button.Image = skinVariantData.Icon;
							editPanel.SkinFrame.Button.TextLabel.Text = `{skinLib.Name}`;
							editPanel.SkinColorFrame.Button.BackgroundColor3 = Color3.fromRGB(100, 100, 100);
							editPanel.SkinColorFrame.Button.ImageColor3 = Color3.fromRGB(255, 255, 255);
	
						end
					else
						editPanel.SkinColorFrame.Button.Image = "";
						editPanel.SkinFrame.Button.Image = "";
						editPanel.SkinFrame.Button.TextLabel.Text = `None`;
						editPanel.SkinColorFrame.Button.BackgroundColor3 = Color3.fromRGB(100, 100, 100);
						editPanel.SkinColorFrame.Button.ImageColor3 = Color3.fromRGB(255, 255, 255);

					end
					editPanel.SkinColorFrame.Button.TextLabel.TextColor3 = modColorPicker.GetBackColor(editPanel.SkinColorFrame.Button.ImageColor3);
					editPanel.SkinColorFrame.Button.TextLabel.Text = `#{editPanel.SkinColorFrame.Button.ImageColor3:ToHex()}`;


					local newTransparency = planObj.Transparency or basePart:GetAttribute("DefaultTransparency");
					if newTransparency then
						transparencySlider:SetAttribute("Value", newTransparency);
					end

					local newPartOffset = planObj.PositionOffset or Vector3.zero;
					partOffsetXSlider:SetAttribute("Value", newPartOffset.X);
					partOffsetYSlider:SetAttribute("Value", newPartOffset.Y);
					partOffsetZSlider:SetAttribute("Value", newPartOffset.Z);

					local newMaterial = planObj.Material or basePart:GetAttribute("DefaultMaterial");
					if newMaterial then
						local materialButton = editPanel.MaterialFrame.Button;
						materialButton.Text = newMaterial.Name;
					end

					local newReflectance = planObj.Reflectance or basePart:GetAttribute("DefaultReflectance");
					if newReflectance then
						reflectanceSlider:SetAttribute("Value", newReflectance);
					end

				end
				




			end

			local function onTextBoxUpdate()
				if not selectTextbox.TextEditable then return end;

				local cap1 = string.gsub(selectTextbox.Text, "[%[%]]", "") or ""; --string.match(selectTextbox.Text, "%[(.*)%]")
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

		dropDownFrame:GetPropertyChangedSignal("Visible"):Connect(function()
			if dropDownFrame.Visible == false then
				toggleVisibility();
			end
		end);
	
		-- MARK: SelectPartDropDown;
		selectDropButton.MouseButton1Click:Connect(function()
			Interface:PlayButtonClick();
	
			function newDropDownList:OnNewButton(index, optionButton)
				local selectionName = optionButton.Name;

				if customizationPlanCache[selectionName] then
					local customizeData = customizationPlanCache[selectionName];
					
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
				activeGroupName = nil;

				local selectionName = optionButton.Name;
				local selectionPartData = {};
				local predefinedGroup = selectionName:sub(1,1) == "[" and selectionName;

				for a=1, #modelParts do
					if predefinedGroup == "[All]" then
						table.insert(selectionPartData, modelParts[a]);

					elseif predefinedGroup and modelParts[a].PredefinedGroup == selectionName then
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