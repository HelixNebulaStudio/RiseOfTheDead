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
		local dropDownFrame = newDropDownList.Frame;
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

		do -- Load edit panel 

			-- MARK:OpenColorCustomizations;
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

			local colorButton = editPanel.ColorFrame.Button;
			colorButton.MouseButton1Click:Connect(function()
				Interface:PlayButtonClick();
				OpenColorCustomizations(function(selectColor: Color3)
					colorButton.BackgroundColor3 = selectColor;
					colorButton.TextColor3 = modColorPicker.GetBackColor(selectColor);
					colorButton.Text = `#{selectColor:ToHex()}`;

					Debugger:StudioWarn("Set Color=", colorButton.Text);
				end);
			end)

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

			-- Texture Color;
			local textureColorButton = editPanel.SkinColorFrame.Button;
			textureColorButton.MouseButton1Click:Connect(function()
				Interface:PlayButtonClick();
				OpenColorCustomizations(function(selectColor: Color3)
					textureColorButton.ImageColor3 = selectColor;
					textureColorButton.BackgroundColor3 = modColorPicker.GetBackColor(selectColor);
					textureColorButton.TextLabel.Text = `#{selectColor:ToHex()}`;
					textureColorButton.TextLabel.TextColor3 = modColorPicker.GetBackColor(selectColor);

					Debugger:StudioWarn("Set TextureColor=", textureColorButton.TextLabel.Text);
				end);
			end)


			-- Texture Skin;
			local textureSetButton = editPanel.SkinFrame.Button;
			textureSetButton.MouseButton1Click:Connect(function()
				Interface:PlayButtonClick();

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
				local skinPackOptionsList = {};
				local skinPacksList = {};
				for index, skinInfo in pairs(modItemSkinsLibrary:GetIndexList()) do
					if skinInfo.Type == modItemSkinsLibrary.SkinType.Texture and skinInfo.Textures[storageItem.ItemId] == nil then
						continue;
					end

					table.insert(skinPackOptionsList, skinInfo.Name);
					table.insert(skinPacksList, skinInfo);
				end

				local selctionStroke = Instance.new("UIStroke");
				selctionStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
				selctionStroke.Color = Color3.fromRGB(255, 255, 255);
				selctionStroke.Thickness = 4;
				selctionStroke.Parent = nil;
				
				function newDropDownList:OnNewButton(index, optionButton: TextButton)
					local skinInfo = skinPacksList[index];
					local isUnlocked = unlockedSkins[skinInfo.Id];

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
							newPatternButton.ZIndex = 3;
							newPatternButton.Name = patternData.Id;
							newPatternButton.Image = patternData.Image;

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
								dropDownFrame.Visible = false;
							end)

						end

					elseif skinInfo.Type == modItemSkinsLibrary.SkinType.Texture then
						local textureData = skinInfo.Textures[itemId];
						
						if textureData then
							local newPatternButton = Instance.new("ImageButton");
							newPatternButton.ZIndex = 3;
							newPatternButton.Name = textureData.Id;
							newPatternButton.Image = textureData.Icon;

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

			end)


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
				infoLabel.Text = `<b>Type:</b> Group`; --    Layer: 0
				partLabel.Text = `<font size="14"><b>Group Parts:</b></font> {table.concat(partNames, ", ")}`;
				selectTextbox.TextEditable = true;
			
			else
				local partData = selectionPartData[1];
				selectTextbox.Text = "";
				selectTextbox.PlaceholderText = partData.Name;
				infoLabel.Text = `<b>Type:</b> Part`;
				partLabel.Text = `<font size="14"><b>Part Group:</b> {partData.PredefinedGroup or "None"}</font>`;
				selectTextbox.TextEditable = false;

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