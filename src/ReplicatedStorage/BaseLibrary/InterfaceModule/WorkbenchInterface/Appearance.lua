local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Workbench = {};
local Interface = {
	List = nil;
	WorkbenchItemDisplay = nil;
	PlayButtonClick = nil;
	Object = nil;
	OpenWindow = nil;
	ClearPages = nil;
	RefreshNavigations = nil;
	SetPage = nil;
	PromptQuestion = nil;
};

local TweenService = game:GetService("TweenService");
local UserInputService = game:GetService("UserInputService");
local player = game.Players.LocalPlayer;

local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
local modBranchConfigs = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("BranchConfigurations"));
local modItemLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modClothingLibrary = require(game.ReplicatedStorage.Library.ClothingLibrary);

local modColorsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("ColorsLibrary"));
local modSkinsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("SkinsLibrary"));
local modItemUnlockablesLibrary = require(game.ReplicatedStorage.Library.ItemUnlockablesLibrary);


local _appearanceFrameTemplate = script:WaitForChild("AppearanceFrame");
local appearanceListingTemplate = script:WaitForChild("AppearanceListing");
local templateHintLabel = script:WaitForChild("HintLabel");

local packFrameTemplate = script:WaitForChild("PackFrame");
local styleButtonTemplate = script:WaitForChild("StyleButton");
local unlockButtonTemplate = script:WaitForChild("UnlockableButton");

local remotes = game.ReplicatedStorage.Remotes;
local remoteSetAppearance = remotes.Workbench:WaitForChild("SetAppearance");

local selectedColor3 = Color3.fromRGB(163, 255, 130);

local firstSync = false;
function Workbench.new(itemId, library, storageItem)
	local itemDisplay = Interface.WorkbenchItemDisplay;
	while #itemDisplay.DisplayModels == 0 and itemDisplay.OnDisplayID == storageItem.ID do
		task.wait();
	end
	if itemDisplay.OnDisplayID ~= storageItem.ID then return end;
	
	if firstSync == false then
		firstSync = true;

		modData:RequestData("ColorPacks");
		modData:RequestData("SkinsPacks");
		modData:GetFlag("CustomColors", true);
	end
	
	local listMenu = Interface.List.create();
	listMenu.Menu.Name = "appearanceMenu";
	listMenu:SetListPadding(UDim2.new(1, 0, 1, 0), {Top=UDim.new(0, 2)});
	listMenu:SetEnableScrollBar(false);
	listMenu:SetEnableSearchBar(false);
	
	local ItemValues = storageItem.Values;
	local previousPart, previousPartMat, previousPartCol, tweenLink, itemPartSelected;
	local currentHighlight;
	
	local pickerMenu;
	
	local function highlightPart(partInstance)
		currentHighlight = partInstance;
		if partInstance == nil then
			if tweenLink then tweenLink:Cancel(); end;
			if previousPart then
				previousPart.Material = previousPartMat or Enum.Material.Metal;
				previousPart.Color = previousPartCol or Color3.fromRGB(60, 60, 60);
			end
			previousPart = nil;
		else
			previousPartMat = partInstance.Material;
			previousPartCol = partInstance.Color;
			
			partInstance.Material = Enum.Material.Glass;
			partInstance.Color = Color3.fromRGB(50, 50, 50);
			
			tweenLink = TweenService:Create(partInstance, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Color=Color3.fromRGB(30, 30, 30)});
			tweenLink:Play();
			previousPart = partInstance;
		end;
	end
	
	local appearanceListingFrames = {};
	local styleButtonDebounce = false;
	
	for a=1, #itemDisplay.DisplayModels do
		local basePrefab = itemDisplay.DisplayModels[a].BasePrefab;
		local prefab = itemDisplay.DisplayModels[a].Prefab;
		
		local unlockableLib = modItemUnlockablesLibrary:Find(itemId);
		if unlockableLib then
			local clothingLib = modClothingLibrary:Find(itemId);
			local itemUnlockables = modItemUnlockablesLibrary:ListByKeyValue("ItemId", itemId);
			if itemUnlockables then
				local function setCharacterAccessories(unlockId)
					for _, obj in pairs(prefab:GetChildren()) do
						modItemUnlockablesLibrary.UpdateSkin(obj, unlockId);
					end
				end
				setCharacterAccessories(ItemValues.ActiveSkin);
				
				listMenu:SetEnableScrollBar(true);
				listMenu:SetEnableSearchBar(true);
				
				local unlockablesList = listMenu:NewBasicList();
				local newCateTab = listMenu:NewTab(unlockablesList);
				newCateTab.titleLabel.Text = "Skins";
				listMenu:Add(newCateTab, 1);
				listMenu:Add(unlockablesList, 2);

				local refreshButtonFuncs = {};
				
				local unlockableData = ItemValues.Skins or {};
				local chargesData = modData.Profile and modData.Profile.ItemUnlockables[itemId] or {};
				for b=1, #itemUnlockables do
					local unlockItemLib = itemUnlockables[b];
					
					local isUnlocked = table.find(unlockableData, unlockItemLib.Id);
					if unlockItemLib.Name == "Default" or unlockItemLib.Unlocked == true then
						isUnlocked = true;
					elseif typeof(unlockItemLib.Unlocked) == "string" and table.find(unlockableData, unlockItemLib.Unlocked) then
						isUnlocked = true;
					end
					
					if unlockItemLib.Hidden ~= true then
						-- MARK: New UnlockableButton 
						local unlockButton = unlockButtonTemplate:Clone();
						local txrLabel = unlockButton:WaitForChild("TextureLabel");
						local selectedLabel = unlockButton:WaitForChild("SelectedLabel");
						local titleLabel = unlockButton:WaitForChild("TitleLabel");
						local chargeLabel = unlockButton:WaitForChild("ChargesLabel");

						local unlockableIcon = unlockItemLib.Icon;
						
						local itemLib = modItemLibrary:Find(unlockItemLib.Id);
						if itemLib then
							unlockableIcon = itemLib.Icon;
						end
						
						txrLabel.Image = unlockableIcon or "";
						titleLabel.Text = unlockItemLib.Name;
						unlockButton.LayoutOrder = unlockItemLib.Name == "Default" and 0 or unlockItemLib.LayoutOrder or 1;
						unlockButton.LayoutOrder = isUnlocked and unlockButton.LayoutOrder or unlockButton.LayoutOrder + 999;
						txrLabel.ImageColor3 = isUnlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100);

						local hasCharges = chargesData[unlockItemLib.Id] and chargesData[unlockItemLib.Id] > 0
						if hasCharges then
							chargeLabel.Text = `Charges: {chargesData[unlockItemLib.Id]}`;
						end
						
						local function refresh()
							if ItemValues.ActiveSkin == nil and unlockItemLib.Name == "Default" then
								selectedLabel.Visible = true;
							else
								selectedLabel.Visible = ItemValues.ActiveSkin == unlockItemLib.Id;
							end
						end
						table.insert(refreshButtonFuncs, refresh);
						
						local canPreview;
						local function previewStyle()
							canPreview = true;
							setCharacterAccessories(unlockItemLib.Id);
						end

						unlockButton.MouseEnter:Connect(previewStyle);
						unlockButton.MouseMoved:Connect(function()
							if not canPreview then return end;
							previewStyle()
						end);

						unlockButton.MouseLeave:Connect(function()
							setCharacterAccessories(ItemValues.ActiveSkin);
						end)
						
						if player.UserId == 16170943 then
							unlockButton.MouseButton2Click:Connect(function()
								Interface:PlayButtonClick();
								
								local oldActiveId = ItemValues.ActiveSkin;
								if ItemValues.ActiveSkin == unlockItemLib.Id then
									remoteSetAppearance:FireServer(Interface.Object, 9, storageItem.ID, "UnlockableId");
								else
									remoteSetAppearance:FireServer(Interface.Object, 9, storageItem.ID, "UnlockableId", unlockItemLib.Id);
								end
								canPreview = false;
								
								for a=1, 10, 0.1 do
									storageItem = modData.GetItemById(storageItem.ID);
									ItemValues = storageItem.Values;
									if ItemValues.ActiveSkin ~= oldActiveId then break; end;
									wait(0.1);
								end
								
								if unlockItemLib.PackageId or unlockItemLib.DefaultPackage then
									-- switch viewport accessory
									itemDisplay:SetDisplay(storageItem);
								end

								for b=1, #refreshButtonFuncs do
									if type(refreshButtonFuncs[b]) == "function" then
										refreshButtonFuncs[b]();
									end
								end
							end)
						end
						
						unlockButton.MouseButton1Click:Connect(function()
							Interface:PlayButtonClick();

							if isUnlocked == nil and hasCharges then

								-- MARK: Use charge;
								local name = itemLib and itemLib.Name or `{unlockItemLib.ItemId}:{unlockItemLib.Name}`;
								local icon = itemLib and itemLib.Icon or unlockItemLib.Icon;
								
								local promptWindow = Interface:PromptQuestion("Apply Skin?",
									`Are you sure you want to apply {name}? This will consume a charge.`, 
									"Use Charge", "Cancel", icon);
								local YesClickedSignal, NoClickedSignal;
								
								local applyDebounce = tick();
								YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
									if tick()-applyDebounce <= 0.2 then return end;
									applyDebounce = tick();
									
									Interface:PlayButtonClick();
									promptWindow.Frame.Yes.buttonText.Text = "Applying...";
									
									remoteSetAppearance:FireServer(Interface.Object, 9, storageItem.ID, "UnlockableId", unlockItemLib.Id);

									promptWindow:Close();
									YesClickedSignal:Disconnect();
									NoClickedSignal:Disconnect();
								end);
								
								NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
									Interface:PlayButtonClick();
									promptWindow:Close();
									YesClickedSignal:Disconnect();
									NoClickedSignal:Disconnect();
								end);

								return;
							end

							if isUnlocked == nil then
								Interface:OpenWindow("GoldMenu", unlockItemLib.Id);
								
								return
							end;
							
							local oldActiveId = ItemValues.ActiveSkin;
							if ItemValues.ActiveSkin == unlockItemLib.Id then
								remoteSetAppearance:FireServer(Interface.Object, 9, storageItem.ID, "UnlockableId");
							else
								remoteSetAppearance:FireServer(Interface.Object, 9, storageItem.ID, "UnlockableId", unlockItemLib.Id);
							end
							canPreview = false;
							
							for a=1, 10, 0.1 do
								storageItem = modData.GetItemById(storageItem.ID);
								ItemValues = storageItem.Values;
								if ItemValues.ActiveSkin ~= oldActiveId then break; end;
								wait(0.1);
							end
							
							if unlockItemLib.PackageId or unlockItemLib.DefaultPackage then
								-- switch viewport accessory
								itemDisplay:SetDisplay(storageItem, function()
									for a=1, #itemDisplay.DisplayModels do
										local prefab = itemDisplay.DisplayModels[a].Prefab;

										for _, obj in pairs(prefab:GetChildren()) do
											modItemUnlockablesLibrary.UpdateSkin(obj, ItemValues.ActiveSkin);
										end
									end
								end);

							end
							
							for b=1, #refreshButtonFuncs do
								if type(refreshButtonFuncs[b]) == "function" then
									refreshButtonFuncs[b]();
								end
							end
						end)

						refresh();
						listMenu:AddSearchIndex(unlockButton, {unlockItemLib.ItemId; unlockItemLib.Id; titleLabel.Text;});
						unlockButton.Parent = unlockablesList.list;
					end
				end
			end
		end
		
		if library == nil then continue end; -- weapon customizations;


		local weldName = itemDisplay.DisplayModels[a].WeldName;
		local appearLib = library[weldName];
		
		local sortedAppearLib = {};
		for _, weaponPart in pairs(prefab:GetChildren()) do
			if not weaponPart:IsA("BasePart") then continue end
			if modBranchConfigs.CurrentBranch.Name ~= "Dev" and weaponPart:GetAttribute("WorkbenchIgnore") == true then continue end;
			table.insert(sortedAppearLib, weaponPart.Name);
		end
		table.sort(sortedAppearLib, function(a, b) return a:lower() < b:lower() end);
		
		for a=1, #sortedAppearLib do
			local partName = sortedAppearLib[a];
			
			local refBasePart = basePrefab:FindFirstChild(partName);
			
			local newListing = appearanceListingTemplate:Clone();
			local listTitle = newListing:WaitForChild("Title");
			local colorButton = newListing:WaitForChild("ColorButton");
			local textureLabel = colorButton:WaitForChild("TextureLabel");

			local partInstance = prefab and prefab:FindFirstChild(partName);

			local prefix = (weldName == "LeftToolGrip" and "L-" or weldName == "RightToolGrip" and "R-" or "");
			local partTitle = (prefix == "L-" and "Left " or prefix == "R-" and "Right " or "")..(refBasePart:GetAttribute("PartLabel") or partName);

			if partInstance:GetAttribute("WorkbenchIgnore") == true then
				partTitle = "[DB] "..partTitle;
			end
			
			local dataKey = prefix..partName;
			
			local function updateUi()
				if ItemValues.PartAlpha and ItemValues.PartAlpha[dataKey] == true then
					partTitle = "<s>"..partTitle.."</s>";
				end

				listTitle.Text = partTitle;
			end
			updateUi();

			local defaultPartColor = refBasePart.Color;
			local colorObject = ItemValues.Colors and ItemValues.Colors[dataKey] and modColorsLibrary.Get(ItemValues.Colors[dataKey]);
			if colorObject then
				textureLabel.BackgroundColor3 = colorObject.Color;
			else
				textureLabel.BackgroundColor3 = partInstance and partInstance.Color or defaultPartColor;
			end
			local skinObject = ItemValues.Textures and ItemValues.Textures[dataKey] and modSkinsLibrary.Get(ItemValues.Textures[dataKey]);
			if skinObject then
				textureLabel.Image = skinObject.Image;
				textureLabel.ImageColor3 = skinObject.Color;
			else
				textureLabel.Image = "";
			end
			
			local function clearAllButtonClick()
				if styleButtonDebounce then return end;
				if partInstance == nil then return end;

				Debugger:Log("Clear")
				styleButtonDebounce = true;
				Interface:PlayButtonClick();
				highlightPart();

				textureLabel.BackgroundColor3 = defaultPartColor;
				remoteSetAppearance:FireServer(Interface.Object, 5, storageItem.ID, dataKey);
				
				modColorsLibrary.SetColor(partInstance, nil);
				modSkinsLibrary.SetTexture(partInstance, nil);

				textureLabel.Image = "";
				wait(0.1);
				styleButtonDebounce = false;
			end
			
			colorButton.MouseButton2Click:Connect(clearAllButtonClick)
			if UserInputService.TouchEnabled then
				colorButton.TouchLongPress:Connect(clearAllButtonClick);
			end
			
			colorButton.MouseButton1Click:Connect(function()
				if styleButtonDebounce then return end;

				itemPartSelected = partInstance;
				if itemPartSelected == nil then
					return 
				end;
				
				styleButtonDebounce = true;
				Interface:PlayButtonClick();
				highlightPart();
				
				local activePartColor = itemPartSelected:GetAttribute("ColorId");
				local activePartTexture = itemPartSelected:GetAttribute("SkinId");

				local function newAppearancePicker()
					local listMenuAppearance = Interface.List.create();
					listMenuAppearance.Menu.Name = "appearancePicker";

					local function revertPartColor()
						modColorsLibrary.SetColor(itemPartSelected, activePartColor);
						modSkinsLibrary.SetTexture(itemPartSelected, activePartTexture);

						local invis = ItemValues.PartAlpha and ItemValues.PartAlpha[dataKey]
						if invis == true then
							itemPartSelected.Transparency = 1;
							
						else
							if itemPartSelected:GetAttribute("DefaultTransparency") then
								itemPartSelected.Transparency = itemPartSelected:GetAttribute("DefaultTransparency");
							end
						end
					end

					local function loadPackList(packsList, listFrame)
						local refreshButtonFuncs = {};
						local canPreview = true;

						local customColors = modData:GetFlag("CustomColors");
						if customColors and packsList == modColorsLibrary.Packs then
							packsList.Custom = {Name="Lydia's Colors"; LayoutOrder=0; List={}; Owned=true; CustomColors=true;};

							local orderList = {};

							for hex, _ in pairs(customColors.Unlocked) do
								local color = Color3.fromHex(hex);
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
								table.insert(packsList.Custom.List, getColor);
							end
						end

						for packIndex, packData in pairs(packsList) do
							if packData.Owned == nil or packData.Owned == false then continue end;

							local newPackFrame = packFrameTemplate:Clone();
							local titleLabel = newPackFrame:WaitForChild("Title");
							local stylesList = newPackFrame:WaitForChild("GridList");
							local stylesListGridLayout = stylesList:WaitForChild("UIGridLayout");

							titleLabel.Text = packData.Name;
							newPackFrame.LayoutOrder = packData.LayoutOrder;

							for a=1, #packData.List do
								local styleButton = styleButtonTemplate:Clone();
								local txrLabel = styleButton:WaitForChild("TextureLabel");
								local selectedLabel = styleButton:WaitForChild("SelectedLabel");
								
								if packsList == modColorsLibrary.Packs then
									stylesListGridLayout.CellSize = UDim2.new(0, 25, 0, 25);
								end
								
								local function refreshButton()
									if packsList == modColorsLibrary.Packs and activePartColor == packData.List[a].Id then
										selectedLabel.Visible = true;
										styleButton.ImageColor3 = selectedColor3;
									elseif packsList == modSkinsLibrary.Packs and activePartTexture == packData.List[a].Id then
										selectedLabel.Visible = true;
										styleButton.ImageColor3 = selectedColor3;
									else
										selectedLabel.Visible = false;
										styleButton.ImageColor3 = Color3.fromRGB(255, 255, 255);
									end
								end
								table.insert(refreshButtonFuncs, refreshButton);
								refreshButton();

								local function previewStyle()
									canPreview = true;
									if packsList == modColorsLibrary.Packs then
										modColorsLibrary.SetColor(itemPartSelected, packData.List[a].Id, false);

									elseif packsList == modSkinsLibrary.Packs then
										modSkinsLibrary.SetTexture(itemPartSelected, packData.List[a].Id, false);

									end
								end

								styleButton.MouseEnter:Connect(previewStyle);
								styleButton.MouseMoved:Connect(function()
									if not canPreview then return end;
									previewStyle()
								end);

								styleButton.MouseLeave:Connect(function()
									revertPartColor();
								end)

								styleButton.MouseButton1Click:Connect(function()
									Interface:PlayButtonClick();
									if packsList == modColorsLibrary.Packs then
										if activePartColor == packData.List[a].Id then
											textureLabel.BackgroundColor3 = defaultPartColor;
											remoteSetAppearance:FireServer(Interface.Object, 3, storageItem.ID, dataKey);
											activePartColor = nil;
											canPreview = false;
										else
											textureLabel.BackgroundColor3 = packData.List[a].Color;
											remoteSetAppearance:FireServer(Interface.Object, 1, storageItem.ID, dataKey, packData.List[a].Id);
											activePartColor = packData.List[a].Id;
										end
										modColorsLibrary.SetColor(itemPartSelected, activePartColor);

									elseif packsList == modSkinsLibrary.Packs then
										if activePartTexture == packData.List[a].Id then
											remoteSetAppearance:FireServer(Interface.Object, 4, storageItem.ID, dataKey);
											textureLabel.Image = "";
											activePartTexture = nil;
											canPreview = false;

										else
											if packData.List[a].Icon == nil then
												remoteSetAppearance:FireServer(Interface.Object, 2, storageItem.ID, dataKey, packData.List[a].Id);
												textureLabel.Image = packData.List[a].Image;
												textureLabel.ImageColor3 = packData.List[a].Color;
												textureLabel.TileSize = UDim2.new(packData.List[a].StudsPerTile.X, 0, packData.List[a].StudsPerTile.Y, 0);
											else
												textureLabel.Image = packData.List[a].Icon;
											end
											activePartTexture = packData.List[a].Id;
										end
										modSkinsLibrary.SetTexture(itemPartSelected, activePartTexture);

									end
									for b=1, #refreshButtonFuncs do
										if type(refreshButtonFuncs[b]) == "function" then
											refreshButtonFuncs[b]();
										end
									end
									--Interface.RefreshNavigations();
									--Interface.SetPage(listMenu.Menu);
								end)

								if packsList == modColorsLibrary.Packs then
									txrLabel.BackgroundColor3 = packData.List[a].Color;
									txrLabel.BackgroundTransparency = 0;
									
								elseif packsList == modSkinsLibrary.Packs then
									if packData.List[a].Icon == nil then
										txrLabel.Image = packData.List[a].Image;
										txrLabel.BackgroundTransparency = 1;
										txrLabel.ImageColor3 = packData.List[a].Color;
										local scale = packData.List[a].StudsPerTile;
										txrLabel.TileSize = UDim2.new(scale.X*5, 0, scale.Y*5, 0);
									else
										txrLabel.Image = packData.List[a].Icon;
									end
									
								end
								styleButton.LayoutOrder = packData.List[a].Order or a;
								styleButton.Name = packData.List[a].Name;
								styleButton.Parent = stylesList;
								listMenuAppearance:AddSearchIndex(styleButton, {packData.List[a].Id; packData.List[a].Name; "custom"});
							end
							newPackFrame.Parent = listFrame;
						end
					end
					
					--= Set empty
					do
						local styleButton = styleButtonTemplate:Clone();
						local txrLabel = styleButton:WaitForChild("TextureLabel");
						local selectedLabel = styleButton:WaitForChild("SelectedLabel");
						
						txrLabel.Visible = false;
						
						local textLabel = styleButton:WaitForChild("TextLabel");
						textLabel.Visible = true;
						styleButton.Size = UDim2.new(1, 0, 0, 30);
						styleButton.ImageColor3 = Color3.fromRGB(205, 255, 211)
						
						local function refreshButton()
							if activePartTexture == 0 then
								selectedLabel.Visible = true;
								styleButton.ImageColor3 = selectedColor3;
							else
								selectedLabel.Visible = false;
								styleButton.ImageColor3 = Color3.fromRGB(255, 255, 255);
							end
						end
						refreshButton();
						
						local function previewStyle()
							canPreview = true;
							modSkinsLibrary.SetTexture(itemPartSelected, 0, false);
						end

						styleButton.MouseEnter:Connect(previewStyle);
						styleButton.MouseMoved:Connect(function()
							if not canPreview then return end;
							previewStyle();
							
						end);

						styleButton.MouseLeave:Connect(function()
							revertPartColor();
							
						end)

						styleButton.MouseButton1Click:Connect(function()
							Interface:PlayButtonClick();

							remoteSetAppearance:FireServer(Interface.Object, 2, storageItem.ID, dataKey, 0);
							modSkinsLibrary.SetTexture(itemPartSelected, activePartTexture);
							activePartTexture = 0;
							
							updateUi();
						end)

						styleButton.LayoutOrder = 0;
						styleButton.Name = "Clear";
						
						listMenuAppearance:AddSearchIndex(styleButton, {"Clear";});
						
						local basicList = listMenuAppearance:NewBasicList();
						basicList.Size = UDim2.new(1, 0, 0, 30);
						listMenuAppearance:Add(basicList, 0);
						styleButton.Parent = basicList.list;
					end
					
					-- ToggleVisibility
					if true then--partData.ToggleVisibility == true or modBranchConfigs.CurrentBranch.Name == "Dev" then
						do
							local styleButton = styleButtonTemplate:Clone();
							local txrLabel = styleButton:WaitForChild("TextureLabel");
							local selectedLabel = styleButton:WaitForChild("SelectedLabel");

							txrLabel.Visible = false;

							local textLabel = styleButton:WaitForChild("TextLabel");
							textLabel.Text = "Toggle Visibility";
							textLabel.Visible = true;
							styleButton.Size = UDim2.new(1, 0, 0, 30);
							styleButton.ImageColor3 = Color3.fromRGB(100, 100, 100)

							local function previewStyle()
								canPreview = true;
								if itemPartSelected:GetAttribute("DefaultTransparency") == nil then
									itemPartSelected:SetAttribute("DefaultTransparency", itemPartSelected.Transparency);
								end
								
								local invis = ItemValues.PartAlpha and ItemValues.PartAlpha[dataKey]
								if invis == true then
									itemPartSelected.Transparency = 0;
								else
									itemPartSelected.Transparency = 1;
								end
							end

							styleButton.MouseEnter:Connect(previewStyle);
							styleButton.MouseMoved:Connect(function()
								if not canPreview then return end;
								previewStyle()
							end);

							styleButton.MouseLeave:Connect(function()
								revertPartColor();
							end)

							styleButton.MouseButton1Click:Connect(function()
								Interface:PlayButtonClick();

								remoteSetAppearance:FireServer(Interface.Object, 6, storageItem.ID, dataKey);
								
								local invis = ItemValues.PartAlpha and ItemValues.PartAlpha[dataKey]
								if invis == true then
									if itemPartSelected:GetAttribute("DefaultTransparency") then
										itemPartSelected.Transparency = itemPartSelected:GetAttribute("DefaultTransparency");
									end
									
									ItemValues.PartAlpha[dataKey] = nil;
								else
									itemPartSelected.Transparency = 1;
									
									if ItemValues.PartAlpha == nil then
										ItemValues.PartAlpha = {};
									end
									ItemValues.PartAlpha[dataKey] = true;
								end
								
								updateUi();
							end)

							styleButton.LayoutOrder = 0;
							styleButton.Name = "Toggle Visibility";

							listMenuAppearance:AddSearchIndex(styleButton, {"Visibility";});

							local basicList = listMenuAppearance:NewBasicList();
							basicList.Size = UDim2.new(1, 0, 0, 30);
							listMenuAppearance:Add(basicList, 0);
							styleButton.Parent = basicList.list;
						end
						
					end
					

					local categoryColors = modColorsLibrary.Packs;
					local colorsList = listMenuAppearance:NewBasicList();
					local newCateTab = listMenuAppearance:NewTab(colorsList);
					newCateTab.titleLabel.Text = "Colors";
					listMenuAppearance:Add(newCateTab, 4);

					listMenuAppearance:Add(colorsList, 5);
					loadPackList(categoryColors, colorsList.list);

					local categoryTextures = modSkinsLibrary.Packs;
					local texturesList = listMenuAppearance:NewBasicList();
					local newCateTab = listMenuAppearance:NewTab(texturesList);
					newCateTab.titleLabel.Text = "Textures";
					listMenuAppearance:Add(newCateTab, 7);
					listMenuAppearance:Add(texturesList, 8);
					loadPackList(categoryTextures, texturesList.list);

					return listMenuAppearance;
				end

				Interface.ClearPages("appearancePicker");
				pickerMenu = newAppearancePicker();
				Interface.RefreshNavigations();
				Interface.SetPage(pickerMenu.Menu);

				wait(0.1);
				styleButtonDebounce = false;
			end)

			newListing.MouseEnter:Connect(function()
				for a=1, #appearanceListingFrames do
					if appearanceListingFrames[a] ~= newListing then
						TweenService:Create(appearanceListingFrames[a], TweenInfo.new(0.2), {BackgroundColor3=Color3.new(10/255, 10/255, 10/255)}):Play();
					end
				end
				if previousPart then highlightPart() end;
				TweenService:Create(newListing, TweenInfo.new(0.2), {BackgroundColor3=Color3.new(20/255, 20/255, 20/255)}):Play();
				highlightPart(partInstance);
			end)

			newListing.MouseLeave:Connect(function()
				TweenService:Create(newListing, TweenInfo.new(0.2), {BackgroundColor3=Color3.new(10/255, 10/255, 10/255)}):Play();
				highlightPart();
			end)

			listMenu:Add(newListing);
			table.insert(appearanceListingFrames, newListing);
		end
		
		local newHint = templateHintLabel:Clone();
		
		if UserInputService.TouchEnabled and UserInputService.MouseEnabled == false then
			newHint.Text = "Tap to set, Hold to clear";
		end
		
		listMenu:Add(newHint);
		
		
		local unlockablesList = listMenu:NewBasicList();
		local newCateTab = listMenu:NewTab(unlockablesList);
		newCateTab.titleLabel.Text = "Skins";
		listMenu:Add(newCateTab, 3);
		listMenu:Add(unlockablesList, 4);

		local weaponSkins = ItemValues.Skins or {};
		local refreshButtonFuncs = {};
		for a=1, #weaponSkins do
			local skinId = weaponSkins[a];
			local skinLib = modSkinsLibrary.Get(tostring(skinId));
			if skinLib == nil then continue end;
			
			local skinName = skinLib.Name;
			
			local unlockButton = unlockButtonTemplate:Clone();
			local txrLabel = unlockButton:WaitForChild("TextureLabel");
			local selectedLabel = unlockButton:WaitForChild("SelectedLabel");
			local titleLabel = unlockButton:WaitForChild("TitleLabel");

			txrLabel.Image = "";
			titleLabel.Text = skinName;
			unlockButton.LayoutOrder = a;
			selectedLabel.Visible = false;

			local function refreshButton()
				if ItemValues.ActiveSkin == skinId then
					selectedLabel.Visible = true;
				else
					selectedLabel.Visible = false;
				end
			end
			table.insert(refreshButtonFuncs, refreshButton);
			refreshButton();

			unlockButton.MouseButton1Click:Connect(function()
				Interface:PlayButtonClick();

				local oldActiveId = ItemValues.ActiveSkin;
				if ItemValues.ActiveSkin == skinId then
					remoteSetAppearance:FireServer(Interface.Object, 9, storageItem.ID, "WeaponSkinId");
				else
					remoteSetAppearance:FireServer(Interface.Object, 9, storageItem.ID, "WeaponSkinId", skinId);
				end
				canPreview = false;
				
				for a=1, 10, 0.1 do
					storageItem = modData.GetItemById(storageItem.ID);
					ItemValues = storageItem.Values;
					if ItemValues.ActiveSkin ~= oldActiveId then break; end;
					wait(0.1);
				end

				if prefab then
					for a=1, #sortedAppearLib do
						local partName = sortedAppearLib[a];
						local partInstance = prefab:FindFirstChild(partName);

						modSkinsLibrary.SetTexture(partInstance, skinId);
					end
				end
				for b=1, #refreshButtonFuncs do
					if type(refreshButtonFuncs[b]) == "function" then
						refreshButtonFuncs[b]();
					end
				end
			end)

			listMenu:AddSearchIndex(unlockButton, {skinName});
			unlockButton.Parent = unlockablesList.list;
		end

	end
	
	return listMenu;
end

function Workbench.init(interface)
	Interface = interface;
	return Workbench;
end

return Workbench;