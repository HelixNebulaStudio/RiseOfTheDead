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
local modItemSkinsLibrary = require(game.ReplicatedStorage.Library.ItemSkinsLibrary)

local modDropdownList = require(game.ReplicatedStorage.Library.UI.DropdownList);
local modComponents = require(game.ReplicatedStorage.Library.UI.Components);
local modColorPicker = require(game.ReplicatedStorage.Library.UI.ColorPicker);

local remoteCustomizationData = modRemotesManager:Get("CustomizationData") :: RemoteFunction;

local modData = require(player:WaitForChild("DataModule") :: ModuleScript);

local templateMainFrame = script.Parent:WaitForChild("CustomizationMain");
local templateDropDownLabel = script.Parent:WaitForChild("DropDownLabel");
local templateColorOption = game.ReplicatedStorage.Library.UI.ColorPicker.ColorOption;
local templateTitledSkin = script.Parent:WaitForChild("TitledSkinButton");

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

	local siid = storageItem.ID;
	
	local listMenu = Interface.List.create();
	listMenu.Menu.Name = "customize";
	listMenu:SetEnableSearchBar(false);

	local scrollFrame = listMenu.Menu.scrollList;
	local itemViewport = Interface.WorkbenchItemDisplay;

	if itemViewport.PartDataList == nil then
		Debugger:StudioWarn("Selected ("..itemId..") not customizable.");
		return;
	end


	local customPlansCache = {};
	local groupPartList = {};
	local groupsList = {};


	do -- load list of modelParts and part list
		for a=1, #itemViewport.PartDataList do
			local partData = itemViewport.PartDataList;
	
			if partData.PredefinedGroup and table.find(groupsList, partData.PredefinedGroup) == nil then
				table.insert(groupsList, partData.PredefinedGroup);
			end
	
			table.insert(groupPartList, partData.Key);
		end
		table.sort(groupPartList);
		table.sort(groupsList);
		table.insert(groupsList, 1, "[All]");
	
		for a=1, #groupsList do
			table.insert(groupPartList, a, groupsList[a]);
		end
	end


	-- MARK: getBaseSkinFromActiveSkinId(activeSkinId)
	local function getBaseSkinFromActiveSkinId(activeSkinId)
		if activeSkinId == nil then return end;
		
		local skinLib = modItemSkinsLibrary:Find(activeSkinId);
		if skinLib == nil then
			skinLib = modItemSkinsLibrary:FindByKeyValue("OldId", activeSkinId);
		end
		
		local variantId = nil;
		if skinLib.Type == modItemSkinsLibrary.SkinType.Pattern then
			variantId = "v1";
		else
			variantId = itemId..skinLib.Id;
		end
	
		return `{skinLib.Id}_{variantId}`;
	end


	-- MARK: GetCustomPlan
	local GetCustomEnum = {
		Part=1;
		Group=2;
	};
	local baseCustomPlan = modCustomizationData.newCustomizationPlan();
	local function getCustomPlan(partData, newType)
		local customPlan = customPlansCache[partData.Key] or customPlansCache[partData.Group];

		if customPlan == nil and newType ~= nil then
			customPlan = modCustomizationData.newCustomizationPlan();
			customPlan.BaseSkin = getBaseSkinFromActiveSkinId(storageItem.Values.ActiveSkin);

			if partData.Group and newType == GetCustomEnum.Part then
				customPlan.Group = partData.Group;
				customPlansCache[partData.Group] = customPlan;
			else
				customPlansCache[partData.Key] = customPlan;
			end
		end

		return customPlan or baseCustomPlan;
	end
	

	do -- load premade customPlans
		local baseSkin = getBaseSkinFromActiveSkinId(storageItem.Values.ActiveSkin);
		baseCustomPlan.BaseSkin = baseSkin;
		
		task.spawn(function()
			local rPacket = remoteCustomizationData:InvokeServer("loadskin", siid);
			if rPacket == nil or rPacket.Success ~= true then
				if rPacket and rPacket.FailMsg then
					Debugger:StudioWarn("rPacket.FailMsg", rPacket.FailMsg); 
				end
				
				itemViewport.ApplyCustomizationPlans(nil, baseCustomPlan);
				return; 
			end;
	
			local rawCustomPlans = rPacket.RawPlans;
	
			for planId, rawPlan in pairs(rawCustomPlans) do
				customPlansCache[planId] = modCustomizationData.newCustomizationPlan(rawPlan);
				customPlansCache[planId].BaseSkin = baseSkin;
			end

			itemViewport.ApplyCustomizationPlans(customPlansCache);
		end)
	end
	

	-- listMenu:Refresh();
	function listMenu:Refresh()
		local activeGroupName = nil;
		local activePartSelection = nil;

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
		local saveGroupNameButton = mainFrame:WaitForChild("SaveButton") :: TextButton;
		local selectDropButton = mainFrame:WaitForChild("SelectDropButton") :: TextButton;

		local hintLabel: TextLabel = mainFrame:WaitForChild("HintLabel");
		local baseSkinFrame: Frame = mainFrame:WaitForChild("BaseSkins");

		baseSkinFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			hintLabel.Position = UDim2.new(0, 0, 0, baseSkinFrame.Position.Y.Offset + baseSkinFrame.AbsoluteSize.Y + 10);
		end)

		local function getUnlockedSkins()
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
			return unlockedSkins;
		end

		-- MARK: Titled Skin List
		local rareSkinsList = {};
		local baseSkinList = modItemSkinsLibrary:GetItemSkinIdList(itemId);
		if baseSkinList and #baseSkinList > 0 then
			for a=1, #baseSkinList do
				table.insert(rareSkinsList, baseSkinList[a]);
			end
		end

		local unlockedSkins = getUnlockedSkins();
		for index, skinInfo in pairs(modItemSkinsLibrary:GetIndexList()) do
			if skinInfo.Rare ~= true then continue end;
			if unlockedSkins[skinInfo.Id] == nil then continue end;
			table.insert(rareSkinsList, skinInfo.Id);
		end

		local function refreshSkinPerm()
			local activeSkinId = storageItem.Values.ActiveSkin;
			local baseSkin = getBaseSkinFromActiveSkinId(activeSkinId);

			for _, customPlan in pairs(customPlansCache) do
				customPlan.BaseSkin = baseSkin;
			end
			baseCustomPlan.BaseSkin = baseSkin;

			for _, obj in pairs(baseSkinFrame:GetChildren()) do
				local skinId = obj:GetAttribute("SkinId")
				if skinId == nil then continue end;

				local selectedLabel = obj.SelectedLabel;

				local skinLib = modItemSkinsLibrary:Find(skinId);
				if skinLib == nil then 
					if skinId == "None" then
						selectedLabel.Visible = activeSkinId == nil;
					end

					continue;
				end;

				selectedLabel.Visible = activeSkinId == skinId or tostring(activeSkinId) == skinLib.OldId;
				
			end
		end
		
		if #rareSkinsList > 0 then
			table.insert(rareSkinsList, 1, "None");

			local newLabel = templateDropDownLabel:Clone();
			newLabel.TextLabel.Text = "Skin-Permanents";
			newLabel.Parent = baseSkinFrame;

			for a=1, #rareSkinsList do
				local skinId = rareSkinsList[a];
				local skinLib = modItemSkinsLibrary:Find(skinId);
				local isUnlocked = unlockedSkins[skinId] == true;

				local unlockButton = templateTitledSkin:Clone();
				unlockButton.LayoutOrder = a;
				unlockButton:SetAttribute("SkinId", skinId);
				
				unlockButton.AutoButtonColor = isUnlocked;
				unlockButton.MouseButton1Click:Connect(function()
					if not isUnlocked and skinId ~= "None" then return end;
					Interface:PlayButtonClick();

					local rPacket = remoteCustomizationData:InvokeServer("setbaseskin", {
						WorkbenchPart=Interface.Object;
						Siid=storageItem.ID;
						SkinId=skinId;
						Test="";
					});

					if rPacket.Success then
						if skinId == "None" then
							storageItem.Values.ActiveSkin = nil;
						else
							storageItem.Values.ActiveSkin = skinId;
						end

						refreshSkinPerm();

						itemViewport.ApplyCustomizationPlans(customPlansCache, baseCustomPlan);
					end
				end)

				if skinId == "None" then
					local imgLabel = unlockButton:WaitForChild("TextureLabel");
					imgLabel.Image = "";
					local textLabel = unlockButton:WaitForChild("TitleLabel");
					textLabel.Text = "None";
					unlockButton.Parent = baseSkinFrame;

					continue;
				end

				if skinLib == nil then continue end;

				local imgLabel = unlockButton:WaitForChild("TextureLabel");
				imgLabel.Image = skinLib.Icon;
				local textLabel = unlockButton:WaitForChild("TitleLabel");
				textLabel.Text = skinLib.Name;
				
				unlockButton.ImageColor3 = isUnlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100);
				imgLabel.ImageColor3 = isUnlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100);

				if skinLib.Type == modItemSkinsLibrary.SkinType.Texture then
					local variantLib = skinLib.Textures[itemId];
					imgLabel.Image = variantLib.Icon;
				end

				unlockButton.LayoutOrder = isUnlocked and unlockButton.LayoutOrder or 100+unlockButton.LayoutOrder;
				unlockButton.Parent = baseSkinFrame;

			end

			refreshSkinPerm();
		end


		local editPanel = mainFrame:WaitForChild("EditPanel") :: Frame;
		local infoLabel: TextLabel = editPanel:WaitForChild("InfoLabel");
		local partLabel: TextLabel = editPanel:WaitForChild("PartList");

		-- MARK: function declarations;
		local newSelection;
		local refreshConfigActive;

		-- MARK: UpdateCustomizations;
		local function updateCustomization(func)
			if activePartSelection == nil then return end;

			for a=1, #activePartSelection do
				local partData = activePartSelection[a];

				local customPlan = getCustomPlan(partData, #activePartSelection == 1 and GetCustomEnum.Part or GetCustomEnum.Group);
				func(customPlan);

				customPlan:Apply(partData.Part);
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
			local unlockedSkins = getUnlockedSkins();
			
			-- Load Skin Packs;
			local skinPackOptionsList = {"PatternsLabel";};
			local skinPacksList = {};
			local texturePhase = false;
			for index, skinInfo in pairs(modItemSkinsLibrary:GetIndexList()) do
				if skinInfo.Type == modItemSkinsLibrary.SkinType.Texture then -- and skinInfo.Textures[storageItem.ItemId] == nil
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
			if colorButton.Darken.Visible then return end;

			Interface:PlayButtonClick();
			OpenColorCustomizations(function(selectColor: Color3)
				colorButton.BackgroundColor3 = selectColor;
				colorButton.TextColor3 = modColorPicker.GetBackColor(selectColor);
				colorButton.Text = `#{selectColor:ToHex()}`;

				Debugger:StudioWarn("Set Color=", colorButton.Text);
				updateCustomization(function(customPlan)
					customPlan.Color = selectColor;
				end)
			end);
		end)

		local templateDarkenFrame = colorButton.Darken;
		
		-- MARK: Part Transparency
		local transparencySlider = modComponents.NewSliderButton() :: TextButton;
		transparencySlider.AnchorPoint = Vector2.new(1, 0);
		transparencySlider.Position = UDim2.new(1, -5,0, 0);
		transparencySlider.Size = UDim2.new(0, 200, 0, 30);
		transparencySlider.Parent = editPanel.TransparencyFrame;
		templateDarkenFrame:Clone().Parent = transparencySlider;

		local function onTransparencySet(v)
			Debugger:StudioWarn("Set Transparency=", v);
			updateCustomization(function(customPlan)
				customPlan.Transparency = v;
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
		templateDarkenFrame:Clone().Parent = textureSetButton;

		local function OnSkinSelect(skinId, variantId)
			local skinLib, skinVariantData = modItemSkinsLibrary:FindVariant(skinId, variantId)
			Debugger:StudioWarn("Select Skin", skinId, variantId, skinLib~=nil, skinVariantData~=nil);
			
			if skinLib.Type == modItemSkinsLibrary.SkinType.Pattern then
				editPanel.SkinColorFrame.Button.Image = skinVariantData.Image;
				editPanel.SkinFrame.Button.Image = skinVariantData.Image;
				editPanel.SkinFrame.Button.TextLabel.Text = `{skinLib.Name}: {skinVariantData.Name}`;

			elseif skinLib.Type == modItemSkinsLibrary.SkinType.Texture then
				editPanel.SkinColorFrame.Button.Image = skinVariantData.Icon;
				editPanel.SkinFrame.Button.Image = skinVariantData.Icon;
				editPanel.SkinFrame.Button.TextLabel.Text = `{skinLib.Name}`;

			end

			updateCustomization(function(customPlan)
				customPlan.Skin = `{skinId}_{variantId}`;
			end)
			
			editPanel.SkinFrame.Button:SetAttribute("SkinId", skinId);
			refreshConfigActive();
		end

		textureSetButton.MouseButton1Click:Connect(function()
			if textureSetButton.Darken.Visible then return end;

			Interface:PlayButtonClick();
			OpenSkinCustomizations(OnSkinSelect)
		end)
		local function resetTextureSet()
			if textureSetButton.Darken.Visible then return end;

			Interface:PlayButtonClick();
			updateCustomization(function(customPlan)
				customPlan.Skin = nil;
			end)
			editPanel.SkinFrame.Button:SetAttribute("SkinId", nil);
			refreshConfigActive();
		end
		textureSetButton.TouchLongPress:Connect(resetTextureSet);
		textureSetButton.MouseButton2Click:Connect(resetTextureSet);

		-- MARK: Texture Color;
		local textureColorButton = editPanel.SkinColorFrame.Button;
		templateDarkenFrame:Clone().Parent = textureColorButton;

		local function OnSelectTextureColor(selectColor: Color3)
			textureColorButton.ImageColor3 = selectColor;
			textureColorButton.BackgroundColor3 = modColorPicker.GetBackColor(selectColor);
			textureColorButton.TextLabel.Text = `#{selectColor:ToHex()}`;
			textureColorButton.TextLabel.TextColor3 = modColorPicker.GetBackColor(selectColor);

			Debugger:StudioWarn("Set TextureColor=", textureColorButton.TextLabel.Text);
			updateCustomization(function(customPlan)
				customPlan.PatternData.Color = selectColor;
			end)
		end

		textureColorButton.MouseButton1Click:Connect(function()
			if textureColorButton.Darken.Visible then return end;

			Interface:PlayButtonClick();
			OpenColorCustomizations(OnSelectTextureColor);
		end)


		-- MARK: Texture Offset
		local textureOffsetXSlider = modComponents.NewSliderButton() :: TextButton;
		textureOffsetXSlider.AnchorPoint = Vector2.new(1, 0);
		textureOffsetXSlider.Position = UDim2.new(1, -110, 0, 0);
		textureOffsetXSlider.Size = UDim2.new(0, 95, 0, 30);
		textureOffsetXSlider.Parent = editPanel.SkinOffsetFrame;
		templateDarkenFrame:Clone().Parent = textureOffsetXSlider;

		local textureOffsetYSlider = textureOffsetXSlider:Clone();
		textureOffsetYSlider.Position = UDim2.new(1, -5, 0, 0);
		textureOffsetYSlider.Parent = editPanel.SkinOffsetFrame;
		templateDarkenFrame:Clone().Parent = textureOffsetYSlider;
		
		local function onTextureOffsetX(v)
			Debugger:StudioWarn("Set TextureOffsetX=", v);
			updateCustomization(function(customPlan)
				if customPlan.PatternData.Offset == nil then
					customPlan.PatternData.Offset = Vector2.zero;
				end
				customPlan.PatternData.Offset = Vector2.new(v, customPlan.PatternData.Offset.Y);
			end)

			return v;
		end
		local function onTextureOffsetY(v)
			Debugger:StudioWarn("Set TextureOffsetY=", v);
			updateCustomization(function(customPlan)
				if customPlan.PatternData.Offset == nil then
					customPlan.PatternData.Offset = Vector2.zero;
				end
				customPlan.PatternData.Offset = Vector2.new(customPlan.PatternData.Offset.X, v);
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
		templateDarkenFrame:Clone().Parent = textureScaleXSlider;

		local textureScaleYSlider = textureScaleXSlider:Clone();
		textureScaleYSlider.Position = UDim2.new(1, -5, 0, 0);
		textureScaleYSlider.Parent = editPanel.SkinScaleFrame;
		templateDarkenFrame:Clone().Parent = textureScaleYSlider;
		
		local function onTextureScaleX(v)
			Debugger:StudioWarn("Set TextureScaleX=", v);
			updateCustomization(function(customPlan)
				if customPlan.PatternData.Scale == nil then
					customPlan.PatternData.Scale = Vector2.new(1, 1);
				end
				customPlan.PatternData.Scale = Vector2.new(v, customPlan.PatternData.Scale.Y);
			end)

			return v;
		end
		local function onTextureScaleY(v)
			Debugger:StudioWarn("Set TextureScaleY=", v);
			updateCustomization(function(customPlan)
				if customPlan.PatternData.Scale == nil then
					customPlan.PatternData.Scale = Vector2.new(1, 1);
				end
				customPlan.PatternData.Scale = Vector2.new(customPlan.PatternData.Scale.X, v);
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
		templateDarkenFrame:Clone().Parent = textureAlphaSlider;

		local function onTextureAlphaSet(v)
			Debugger:StudioWarn("Set TextureAlpha=", v);
			updateCustomization(function(customPlan)
				customPlan.PatternData.Transparency = v;
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
		templateDarkenFrame:Clone().Parent = partOffsetXSlider;

		local partOffsetYSlider = partOffsetXSlider:Clone();
		partOffsetYSlider.Position = UDim2.new(1, -74, 0, 0);
		partOffsetYSlider.Parent = editPanel.PartOffsetFrame;
		templateDarkenFrame:Clone().Parent = partOffsetYSlider;

		local partOffsetZSlider = partOffsetXSlider:Clone();
		partOffsetZSlider.Position = UDim2.new(1, -5, 0, 0);
		partOffsetZSlider.Parent = editPanel.PartOffsetFrame;
		templateDarkenFrame:Clone().Parent = partOffsetZSlider;

		local function onPartOffsetX(v)
			Debugger:StudioWarn("Set PartOffset.X=", v);
			updateCustomization(function(customPlan)
				if customPlan.PositionOffset == nil then
					customPlan.PositionOffset = Vector3.zero;
				end
				customPlan.PositionOffset = Vector3.new(
					v,
					customPlan.PositionOffset.Y,
					customPlan.PositionOffset.Z
				);
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
			updateCustomization(function(customPlan)
				if customPlan.PositionOffset == nil then
					customPlan.PositionOffset = Vector3.zero;
				end
				customPlan.PositionOffset = Vector3.new(
					customPlan.PositionOffset.X,
					v,
					customPlan.PositionOffset.Z
				);
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
			updateCustomization(function(customPlan)
				if customPlan.PositionOffset == nil then
					customPlan.PositionOffset = Vector3.zero;
				end
				customPlan.PositionOffset = Vector3.new(
					customPlan.PositionOffset.X,
					customPlan.PositionOffset.Y,
					v
				);
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
		templateDarkenFrame:Clone().Parent = reflectanceSlider;

		local function onReflectanceSet(v)
			Debugger:StudioWarn("Set Reflectance=", v);
			updateCustomization(function(customPlan)
				customPlan.Reflectance = v;
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
		templateDarkenFrame:Clone().Parent = materialButton;

		local function OnMaterialSelect(materialName)
			Debugger:StudioWarn("Set Material=", materialName);
			updateCustomization(function(customPlan)
				local mat = nil;
				pcall(function()
					mat = Enum.Material[materialName];
				end)
				customPlan.Material = mat;
			end)

			materialButton.Text = materialName;
		end

		materialButton.MouseButton1Click:Connect(function()
			if materialButton.Darken.Visible then return end;
			Interface:PlayButtonClick();

			local materialOptionList = {};
			for index, matName in pairs(Enum.Material:GetEnumItems()) do
				if matName.Name == "Air" then continue end;
				table.insert(materialOptionList, matName.Name);
			end
			
			function newDropDownList:OnOptionSelect(index, optionButton)
				Debugger:StudioWarn("index", index, "optionButton", optionButton);

				OnMaterialSelect(optionButton.Name);

				dropDownFrame.Visible = false;
			end
	
			newDropDownList:LoadOptions(materialOptionList);
			toggleVisibility(dropDownFrame);

		end)
			
		editPanel:GetPropertyChangedSignal("Visible"):Connect(function()
			hintLabel.Visible = not editPanel.Visible;
			baseSkinFrame.Visible = not editPanel.Visible;
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

		-- MARK: RefreshConfigActive
		local canEdit = false;
		function refreshConfigActive()
			local skinLib = modItemSkinsLibrary:Find(editPanel.SkinFrame.Button:GetAttribute("SkinId"));
			local canEditPatternData = false;
			if skinLib and skinLib.Type == modItemSkinsLibrary.SkinType.Pattern then
				canEditPatternData = true;
			end

			local patternLabelColor = canEditPatternData and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100);
			local labelColor = canEdit and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100);

			-- Part Color
			local hasAlphaTexture = skinLib and skinLib.HasAlphaTexture;
			editPanel.ColorFrame.Button.AutoButtonColor = canEditPatternData or hasAlphaTexture;
			editPanel.ColorFrame.Button.Darken.Visible = not (canEditPatternData or hasAlphaTexture);
			editPanel.ColorFrame.NameLabel.TextColor3 = (canEditPatternData or hasAlphaTexture) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100);

			-- Part Transparency
			transparencySlider:SetAttribute("DisableSlider", not canEdit);
			transparencySlider.AutoButtonColor = canEdit;
			transparencySlider.Darken.Visible = not canEdit;
			editPanel.TransparencyFrame.NameLabel.TextColor3 = labelColor;

			-- Part Skin/Pattern
			editPanel.SkinFrame.Button.AutoButtonColor = canEdit;
			editPanel.SkinFrame.Button.Darken.Visible = not canEdit;
			editPanel.SkinFrame.NameLabel.TextColor3 = labelColor;

			-- Pattern Color
			editPanel.SkinColorFrame.Button.AutoButtonColor = canEditPatternData;
			editPanel.SkinColorFrame.Button.Darken.Visible = not canEditPatternData;
			editPanel.SkinColorFrame.NameLabel.TextColor3 = patternLabelColor;

			-- Pattern Offset
			textureOffsetXSlider:SetAttribute("DisableSlider", not canEditPatternData);
			textureOffsetXSlider.AutoButtonColor = canEditPatternData;
			textureOffsetXSlider.Darken.Visible = not canEditPatternData;
			textureOffsetYSlider:SetAttribute("DisableSlider", not canEditPatternData);
			textureOffsetYSlider.AutoButtonColor = canEditPatternData;
			textureOffsetYSlider.Darken.Visible = not canEditPatternData;
			editPanel.SkinOffsetFrame.NameLabel.TextColor3 = patternLabelColor;

			-- Pattern Scale
			textureScaleXSlider:SetAttribute("DisableSlider", not canEditPatternData);
			textureScaleXSlider.AutoButtonColor = canEditPatternData;
			textureScaleXSlider.Darken.Visible = not canEditPatternData;
			textureScaleYSlider:SetAttribute("DisableSlider", not canEditPatternData);
			textureScaleYSlider.AutoButtonColor = canEditPatternData;
			textureScaleYSlider.Darken.Visible = not canEditPatternData;
			editPanel.SkinScaleFrame.NameLabel.TextColor3 = patternLabelColor;

			-- Pattern Alpha
			textureAlphaSlider:SetAttribute("DisableSlider", not canEditPatternData);
			textureAlphaSlider.AutoButtonColor = canEditPatternData;
			textureAlphaSlider.Darken.Visible = not canEditPatternData;
			editPanel.SkinTransparencyFrame.NameLabel.TextColor3 = patternLabelColor;

			-- Part Offset
			partOffsetXSlider:SetAttribute("DisableSlider", not canEdit);
			partOffsetXSlider.AutoButtonColor = canEdit;
			partOffsetXSlider.Darken.Visible = not canEdit;
			partOffsetYSlider:SetAttribute("DisableSlider", not canEdit);
			partOffsetYSlider.AutoButtonColor = canEdit;
			partOffsetYSlider.Darken.Visible = not canEdit;
			partOffsetZSlider:SetAttribute("DisableSlider", not canEdit);
			partOffsetZSlider.AutoButtonColor = canEdit;
			partOffsetZSlider.Darken.Visible = not canEdit;
			editPanel.PartOffsetFrame.NameLabel.TextColor3 = labelColor;

			-- Part Reflectance
			reflectanceSlider:SetAttribute("DisableSlider", not canEdit);
			reflectanceSlider.AutoButtonColor = canEdit;
			reflectanceSlider.Darken.Visible = not canEdit;
			editPanel.ReflectanceFrame.NameLabel.TextColor3 = labelColor;

			-- Part Material
			editPanel.MaterialFrame.Button.AutoButtonColor = canEdit;
			editPanel.MaterialFrame.Button.Darken.Visible = not canEdit;
			editPanel.MaterialFrame.NameLabel.TextColor3 = labelColor;

		end

		local function saveGroupName()
			activeGroupName = selectTextbox.Text;
			saveGroupNameButton.Visible = false;

			for a=1, #activePartSelection do
				local partData = activePartSelection[a];
				partData.Group = activeGroupName;
			end

			table.insert(groupsList, activeGroupName);
			table.insert(groupPartList, #groupsList, activeGroupName);
			Debugger:StudioWarn("Save group name", selectTextbox.Text);

			canEdit = true;
			refreshConfigActive();
		end
		saveGroupNameButton.MouseButton1Click:Connect(saveGroupName)
		selectTextbox.FocusLost:Connect(function(returnPressed)
			if returnPressed then
				saveGroupName();
			end
		end)

		-- MARK: Part Group Edit
		local partLabelButton = partLabel:WaitForChild("Button");
		partLabelButton.MouseButton1Click:Connect(function()
			Interface:PlayButtonClick();

			if partLabelButton.Text == "+" then
				Debugger:StudioWarn("Add part to group", activeGroupName);

				function newDropDownList:OnNewButton(index, optionButton: TextButton)
					local selectionName = optionButton.Name;
					
					local modelPartData = nil;
					for a=1, #itemViewport.PartDataList do
						if itemViewport.PartDataList[a].Key == selectionName then
							modelPartData = itemViewport.PartDataList[a];
							break;
						end
					end
					if modelPartData then
						local isInActiveSelection = table.find(activePartSelection, modelPartData) ~= nil;
						optionButton.BackgroundColor3 = isInActiveSelection and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(150, 150, 150);
						optionButton.TextColor3 = isInActiveSelection and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(255, 255, 255);
						optionButton.LayoutOrder = isInActiveSelection and optionButton.LayoutOrder or optionButton.LayoutOrder+100;
						optionButton:SetAttribute("IsInActiveSelection", isInActiveSelection);
					else
						optionButton:Destroy();
					end

				end

				function newDropDownList:OnOptionSelect(index, optionButton)
					Debugger:StudioWarn("index", index, "optionButton", optionButton);
					dropDownFrame.Visible = false;
	
					local isInActiveSelection = optionButton:GetAttribute("IsInActiveSelection")
					
					local partData = nil;
					for a=1, #itemViewport.PartDataList do
						if itemViewport.PartDataList[a].Key == optionButton.Name then
							partData = itemViewport.PartDataList[a];
							break;
						end
					end

					if partData then
						if isInActiveSelection then
							-- remove from selection;
							local selectionIndex = table.find(activePartSelection, partData);
							if selectionIndex then
								table.remove(activePartSelection, selectionIndex);
								
								partData.Group = partData.PredefinedGroup;
								
								local customPlan = getCustomPlan(partData, GetCustomEnum.Part);
								customPlan:Apply(partData.Part);
							end

						else
							-- add to selection;
							if table.find(activePartSelection, partData) == nil then
								table.insert(activePartSelection, partData);

								partData.Group = activeGroupName;
							end

						end
					end

					newSelection(activePartSelection, activeGroupName);
				end
				
				local partDropDownList = {};
				for a=1, #itemViewport.PartDataList do
					table.insert(partDropDownList, itemViewport.PartDataList[a].Key);
				end

				newDropDownList:LoadOptions(partDropDownList);
				toggleVisibility(dropDownFrame);

			elseif partLabelButton.Text == "⦿" then
				Debugger:StudioWarn("Select group of part", activeGroupName);

				local selectionPartData = {};

				for a=1, #itemViewport.PartDataList do
					if activeGroupName and itemViewport.PartDataList[a].Group == activeGroupName then
						table.insert(selectionPartData, itemViewport.PartDataList[a]);
					end
				end

				newSelection(selectionPartData, activeGroupName);
			end
		end)


		-- MARK: newSelection;
		function newSelection(selectionPartData, selectGroupName)
			dropDownFrame.Visible = false;
			if selectGroupTextChangeConn then selectGroupTextChangeConn:Disconnect(); selectGroupTextChangeConn=nil; end;

			if selectionPartData == nil then
				selectionPartData = {};

				local highlightSelect = itemViewport.SelectedHighlightParts;
				for a=1, #highlightSelect do
					for b=1, #itemViewport.PartDataList do
						if itemViewport.PartDataList[b].Part == highlightSelect[a] then 
							table.insert(selectionPartData, itemViewport.PartDataList[b]);
							break;
						end;
					end
				end
			end
			activePartSelection = selectionPartData;

			selectTextbox.Text = "";
			if #selectionPartData <= 0 then
				editPanel.Visible = false;
				activeGroupName = nil;
				return; 
			end

			local groupName = selectGroupName or "[NewGroup]";
			if selectGroupName then
				activeGroupName = selectGroupName;
			end

			editPanel.Visible = true;

			local partNames = {};
			for a=1, #selectionPartData do
				table.insert(partNames, selectionPartData[a].Key);
			end;
			
			if selectGroupName or #selectionPartData > 1 then

				selectTextbox.Text = groupName;
				selectTextbox.PlaceholderText = "";
				infoLabel.Text = `<b>Currently Editing:</b> Group`; --    Layer: 0
				partLabel.Text = `<font size="14"><b>Group Parts:</b></font> {table.concat(partNames, "  |  ")}`;
				selectTextbox.TextEditable = true;
				
				partLabelButton.Text = "+";

			else

				local partData = selectionPartData[1];
				selectTextbox.Text = "";
				selectTextbox.PlaceholderText = partData.Key;
				infoLabel.Text = `<b>Currently Editing:</b> Part`;
				partLabel.Text = `<font size="14"><b>Part Group:</b> {partData.Group or "None"}</font>`;
				selectTextbox.TextEditable = false;

				if partData.Group then
					activeGroupName = partData.Group;
				end

				partLabelButton.Text = "⦿";
				partLabelButton.Visible = partData.Group ~= nil;

			end

			for a=1, #selectionPartData do
				local partData = selectionPartData[a];

				if partData.DisplayModelData and partData.DisplayModelData.Prefab then
					local defaultPartName = string.gsub(partData.Key, partData.DisplayModelData.Prefix, "");
					local defaultPart = partData.DisplayModelData.BasePrefab:FindFirstChild(defaultPartName);
					partData.Part:SetAttribute("DefaultColor", defaultPart.Color);
					partData.Part:SetAttribute("DefaultTransparency", defaultPart.Transparency);
					partData.Part:SetAttribute("DefaultMaterial", defaultPart.Material);
					partData.Part:SetAttribute("DefaultReflectance", defaultPart.Reflectance);
				end
			end


			do -- MARK: selection update
				local partData = selectionPartData[1];
				local customPlan = getCustomPlan(activeGroupName and {Group=activeGroupName;} or {Key=partData.Key});

				if customPlan then
					local newColor = customPlan.Color;
					if newColor then
						local colorButton = editPanel.ColorFrame.Button;
						colorButton.BackgroundColor3 = newColor;
						colorButton.TextColor3 = modColorPicker.GetBackColor(newColor);
						colorButton.Text = `#{newColor:ToHex()}`;
					end

					local newSkin = customPlan.Skin;
					local skinId, variantId = string.match(newSkin or "", "(.*)_(.*)");
					local skinLib, skinVariantData = modItemSkinsLibrary:FindVariant(skinId, variantId)
					
					if skinId and skinVariantData then
						if skinLib.Type == modItemSkinsLibrary.SkinType.Pattern then
							editPanel.SkinColorFrame.Button.Image = skinVariantData.Image;
							OnSkinSelect(skinId, variantId);
							
							local newPatternColor = customPlan.PatternData.Color;
							if newPatternColor then
								editPanel.SkinColorFrame.Button.BackgroundColor3 = modColorPicker.GetBackColor(newPatternColor);
								editPanel.SkinColorFrame.Button.ImageColor3 = newPatternColor;
								OnSelectTextureColor(newPatternColor);
							end

							local newPatternOffset = customPlan.PatternData.Offset or Vector2.zero;
							textureOffsetXSlider:SetAttribute("Value", newPatternOffset.X);
							textureOffsetYSlider:SetAttribute("Value", newPatternOffset.Y);
							
							local newPatternScale = customPlan.PatternData.Scale or skinVariantData.DefaultScale or Vector2.one;
							textureScaleXSlider:SetAttribute("Value", newPatternScale.X);
							textureScaleYSlider:SetAttribute("Value", newPatternScale.Y);

							local newPatternAlpha = customPlan.PatternData.Transparency or 0;
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

					local newTransparency = customPlan.Transparency;
					if newTransparency then
						transparencySlider:SetAttribute("Value", newTransparency);
					end

					local newPartOffset = customPlan.PositionOffset or Vector3.zero;
					partOffsetXSlider:SetAttribute("Value", newPartOffset.X);
					partOffsetYSlider:SetAttribute("Value", newPartOffset.Y);
					partOffsetZSlider:SetAttribute("Value", newPartOffset.Z);

					local newMaterial = customPlan.Material;
					if newMaterial then
						local materialButton = editPanel.MaterialFrame.Button;
						materialButton.Text = newMaterial.Name;
					end

					local newReflectance = customPlan.Reflectance;
					if newReflectance then
						reflectanceSlider:SetAttribute("Value", newReflectance);
					end
				end
			end

			
			local function onTextBoxUpdate()
				if not selectTextbox.TextEditable then return end;

				local cap1 = string.gsub(selectTextbox.Text, "[%[%]]", "") or ""; --string.match(selectTextbox.Text, "%[(.*)%]")
				groupName = string.gsub(cap1, "[^%a%d]*", "") or "NewGroup";
				groupName = groupName:sub(1, 16);
				
				selectTextbox.Text = `[{groupName}]`;
				selectTextbox.CursorPosition = math.clamp(selectTextbox.CursorPosition, #selectTextbox.Text == 3 and 3 or 2, #selectTextbox.Text);

				if activeGroupName and selectTextbox.Text ~= activeGroupName then
					saveGroupNameButton.Visible = true;

					if selectTextbox.Text == `[NewGroup]` then
						canEdit = false;
						refreshConfigActive();
					end
				else
					saveGroupNameButton.Visible = false;
					canEdit = true;
					refreshConfigActive();
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
				local selectGroupName = selectionName:sub(1,1) == "[" and selectionName or nil;

				local customPlan = customPlansCache[selectionName];
				if customPlan then

					if selectGroupName then
						local groupCount = 0;
						
						for a=1, #itemViewport.PartDataList do
							local partData = itemViewport.PartDataList[a];
							if partData.Group == customPlan.Group then
								groupCount = groupCount +1;
							end
						end

						optionButton.Text = optionButton.Text..` ({groupCount}/{#itemViewport.PartDataList})`

					else
						if customPlan.Group then
							optionButton.Text = optionButton.Text..` [{customPlan.Group}]`;
						else
							optionButton.Text = optionButton.Text..`*`;
						end

					end

				end

			end
			
			function newDropDownList:OnOptionSelect(index, optionButton)
				Debugger:StudioWarn("index", index, "optionButton", optionButton);
				dropDownFrame.Visible = false;
				activeGroupName = nil;

				local selectionName = optionButton.Name;
				local selectionPartData = {};
				local selectGroupName = selectionName:sub(1,1) == "[" and selectionName;

				for a=1, #itemViewport.PartDataList do
					local partData = itemViewport.PartDataList[a];
					if selectGroupName == "[All]" then
						table.insert(selectionPartData, partData);

					elseif selectGroupName and partData.Group == selectionName then
						table.insert(selectionPartData, partData);

					elseif partData.Name == selectionName then
						table.insert(selectionPartData, partData);

					end
				end

				newSelection(selectionPartData, selectGroupName);
			end
	
			newDropDownList:LoadOptions(groupPartList);
			toggleVisibility(dropDownFrame);
		end)

		garbage:Tag(itemViewport.OnSelectionChanged:Connect(function()
			newSelection();
		end))

		itemViewport.ApplyCustomizationPlans(customPlansCache);
    end
	
	function listMenu:OnVisiblityChanged()
		if not self.Menu.Visible then
			garbage:Destruct();
			return;
		end

		itemViewport.HightlightSelect = true;
		garbage:Tag(function()
			itemViewport.HightlightSelect = false;
		end)

	end

	return listMenu;
end


return Workbench;