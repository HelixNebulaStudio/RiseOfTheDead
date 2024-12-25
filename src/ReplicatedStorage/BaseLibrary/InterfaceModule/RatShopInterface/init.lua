local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule") :: ModuleScript);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modShopLibrary = require(game.ReplicatedStorage.Library.RatShopLibrary);
local modBlueprintLibrary = require(game.ReplicatedStorage.Library.BlueprintLibrary);
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);
local modBattlePassLibrary = require(game.ReplicatedStorage.Library.BattlePassLibrary);

local typeOptionTemplate = script:WaitForChild("TypeOption");
local listingTemplate = script:WaitForChild("templateOption");

local remoteShopService = modRemotesManager:Get("ShopService");

local branchColor = modBranchConfigs.BranchColor;	

Interface.RankColors = {
	Color3.fromRGB(255, 220, 112);
	Color3.fromRGB(255, 255, 255);
	Color3.fromRGB(181, 99, 85);
	Color3.fromRGB(170, 170, 170);
};

--== Script;

function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	local activeShopType = "Rats";
	local interfaceScreenGui = localplayer.PlayerGui:WaitForChild("MainInterface");
	
	local shopFrame = modConfigurations.CompactInterface and script:WaitForChild("MobileRatShopFrame"):Clone() or script:WaitForChild("RatShopFrame"):Clone();
	shopFrame.Parent = interfaceScreenGui;
	
	local typesListLayout = nil;
	local shopTitleLabel;
	
	if modConfigurations.CompactInterface then
		shopFrame.Name = "RatShopFrame";
		typeOptionTemplate = script:WaitForChild("TypeOptionMobile");
		typesListLayout = shopFrame:WaitForChild("ShopTypes"):WaitForChild("UITableLayout");
		shopTitleLabel = shopFrame:WaitForChild("TitleFrame"):WaitForChild("Title");

	else
		shopTitleLabel = shopFrame:WaitForChild("Title");
		typesListLayout = shopFrame:WaitForChild("ShopTypes"):WaitForChild("UIListLayout");

	end
	
	local typesFrame = shopFrame:WaitForChild("ShopTypes");
	local pageFrame = shopFrame:WaitForChild("PageFrame");

	Interface.PageFrame = pageFrame;
	Interface.SelectedSlot = nil;
	
	local defaultInterface, premiumInterface = Interface.modInventoryInterface.DefaultInterface, Interface.modInventoryInterface.PremiumInterface;
	local clothingInterface = Interface.modInventoryInterface.ClothingInterface;
	
	local function clearSlotHighlight(slot)
		for id, button in pairs(defaultInterface.Buttons) do
			if (slot == nil or id ~= slot.ID) and button.Button then
				button.Button.BackgroundTransparency = 1;
			end
		end
		for id, button in pairs(premiumInterface.Buttons) do
			if (slot == nil or id ~= slot.ID) and button.Button then
				button.Button.BackgroundTransparency = 1;
			end
		end
		for id, button in pairs(clothingInterface.Buttons) do
			if (slot == nil or id ~= slot.ID) and button.Button then
				button.Button.BackgroundTransparency = 1;
			end
		end
	end

	local function onItemSelect(interface, slot)
		if slot and slot.Button and (Interface.SelectedSlot == nil or Interface.SelectedSlot.ID ~= (slot and slot.ID or 0)) then
			clearSlotHighlight(slot);
			Interface.SelectedSlot = slot;
			Interface:PlayButtonClick();

			slot.Button.BackgroundTransparency = 0.3;
			slot.Button.BackgroundColor3 = branchColor;

			Interface.Update();
		else
			Interface.ClearSelection();

			Interface.Update();
			Interface.LoadPage("Money");
		end
	end
	
	
	local window = Interface.NewWindow("RatShopWindow", shopFrame);
	if modConfigurations.CompactInterface then
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0, 0), UDim2.new(0.5, 0, 1, 0));
		
	else
		window:SetOpenClosePosition(UDim2.new(1, -10, 0.5, 0), UDim2.new(2, -10, 0.5, 0));
	end
	
	window.OnWindowToggle:Connect(function(visible, shopType, ...)

		if visible then
			local reselectSlot = ...;

			if defaultInterface then defaultInterface.OnItemButton1Click = onItemSelect; end
			if premiumInterface then premiumInterface.OnItemButton1Click = onItemSelect; end
			if clothingInterface then clothingInterface.OnItemButton1Click = onItemSelect; end
			
			activeShopType = shopType or "Rats";
			
			Debugger:Log("activeShopType", activeShopType, ...);
			
			if activeShopType == "Bandits" then
				shopTitleLabel.Text = "Bandit's Market";
				
			else
				shopTitleLabel.Text = "R.A.T. Services";
				
			end
			
			Interface:HideAll{[window.Name]=true; ["Inventory"]=true;};
			Interface:ToggleInteraction(false);
			Interface:OpenWindow("Inventory");
			task.spawn(function()
				modData:GetFlag("ItemCodex", true);
			end)
			task.spawn(function()
				repeat until not window.Visible or Interface.Object == nil or not Interface.Object:IsDescendantOf(workspace) or Interface.modCharacter.Player:DistanceFromCharacter(Interface.Object.Position) >= 16 or not wait(0.5);
				Interface:ToggleWindow("RatShopWindow", false);
			end)

			if reselectSlot and reselectSlot.Button then
				onItemSelect(nil, reselectSlot);
	
			else
				Interface.Update();
				Interface.LoadPage("Money");
	
			end
			
		else
			game.Debris:AddItem(shopFrame:FindFirstChild("ToolTip"), 0);
			
			Interface.ClearPage();
			Interface.SelectedSlot = nil;
			if defaultInterface then defaultInterface.OnItemButton1Click = Interface.modInventoryInterface.DefaultInterface.BeginDragItem; end
			if premiumInterface then premiumInterface.OnItemButton1Click = Interface.modInventoryInterface.PremiumInterface.BeginDragItem; end
			if clothingInterface then clothingInterface.OnItemButton1Click = Interface.modInventoryInterface.ClothingInterface.BeginDragItem; end
			Interface:CloseWindow("Inventory");
			Interface:CloseWindow("WeaponStats");
			task.delay(0.3, function()
				Interface:ToggleInteraction(true);
			end)
			
		end

	end)
	
	function Interface.ClearSelection()
		clearSlotHighlight();
		Interface.SelectedSlot = nil;
	end


	function Interface.ClearPage()
		for _, obj in pairs(pageFrame:GetChildren()) do
			if obj:IsA("GuiObject") then
				obj:Destroy();
			end
		end
	end

	function Interface.LoadPage(catalogType, pageName)
		if modShopLibrary.Pages[catalogType] == nil then return end;
		local cataInfo = modShopLibrary.Pages[catalogType];

		Interface.ClearSelection();
		Interface.ClearPage();
		
		pageName = pageName or "FrontPage";
		if cataInfo.Type == "Page" then
			pageName = cataInfo.Id;
		end
		
		if cataInfo[pageName] == nil then

			local modPage = script:FindFirstChild(pageName);
			modPage = modPage and require(modPage) or nil;

			if modPage then
				modPage:Load(Interface);
			end

			return
		end;

		for a=1, #cataInfo[pageName] do
			local info = cataInfo[pageName][a];

			if info.ShopType and info.ShopType ~= activeShopType then
				continue;
			end

			if info.Id == "MissionPassLbPage" then
				local activeBpId = modBattlePassLibrary.Active;
				local battlepassLib = modBattlePassLibrary:Find(activeBpId);
				if battlepassLib == nil then continue end;
			end
			
			
			Interface.NewListing(function(newListing)
				local infoBox = newListing:WaitForChild("infoFrame");
				local descFrame = infoBox:WaitForChild("descFrame");

				local purchaseButton = newListing:WaitForChild("purchaseButton");
				local priceLabel = purchaseButton:WaitForChild("buttonText");
				local iconButton = newListing:WaitForChild("iconButton");
				local iconLabel = iconButton:WaitForChild("iconLabel");
				local titleLabel = descFrame:WaitForChild("titleLabel");
				local labelFrame = descFrame:WaitForChild("labelFrame");
				local descLabel = labelFrame:WaitForChild("descLabel");

				if info.Type == "Page" then
					
					if info.Id == "MissionPassLbPage" then
						local activeBpId = modBattlePassLibrary.Active;
						local battlepassLib = modBattlePassLibrary:Find(activeBpId);

						info.Icon = battlepassLib.Icon;
						info.Title = battlepassLib.Title;
						info.Desc = "• Leaderboard of "..battlepassLib.Title.."!";
					end
					
					newListing.Name = info.Id;
					iconLabel.Image = info.Icon;
					titleLabel.Text = info.Title;
					descLabel.Text = info.Desc;
					purchaseButton.Visible = false;

					newListing.MouseButton1Click:Connect(function()
						Interface.LoadPage(catalogType, info.Id);
					end)

				elseif info.Type == "Product" then
					local product = modShopLibrary.Products:Find(info.Id);
					if product == nil then Debugger:Warn("Missing product lib:", info.Id) end;

					newListing.Name = info.Id;
					local itemLib = modItemsLibrary:Find(product.Id);
					iconLabel.Image = itemLib.Icon;
					titleLabel.Text = itemLib.Name;
					 
					local desc = info.Desc or itemLib.Description;
					
					local modStackCutoffI = string.find(desc, "EffectTrigger:")
					if modStackCutoffI then
						desc = desc:sub(1, modStackCutoffI-5);
					end
					
					descLabel.Text = desc;

					priceLabel.Text = product.Currency == "Money" and "$"..modFormatNumber.Beautify(product.Price)
						or modFormatNumber.Beautify(product.Price).." "..product.Currency;


					-- MARK: BuyItem
					local purchaseDebounce = false;
					local function purchaseClicked()
						if purchaseDebounce then return end;
						purchaseDebounce = true;

						Interface:PromptDialogBox({
							Title=`Purchase: {itemLib.Name}`;
							Desc=`Are you sure you want to purchase <b>{itemLib.Name}</b> for <b>{priceLabel.Text}</b>?\n\n<font size="8">(Right click to enable multi purchase.)</font>`;
							Icon=itemLib.Icon;
							Buttons={
								{
									Text="Purchase";
									Style="Confirm";
									OnPrimaryClick=function(promptDialogFrame, textButton)
										local buyMulti = textButton:GetAttribute("SkipClose");

										promptDialogFrame.statusLabel.Text = "Purchasing item...";
				
										local serverReply = remoteShopService:InvokeServer("buyitem", Interface.Object, info.Id);
										if serverReply == modShopLibrary.PurchaseReplies.Success then
											promptDialogFrame.statusLabel.Text = "Purchased!";

											wait(buyMulti and 0.2 or 0.5);
										else
											warn("Purchase Item>> Error Code:"..serverReply);
											promptDialogFrame.statusLabel.Text = (modShopLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply)):gsub("$Currency", product.Currency);
											wait(1);
										end
	
										if buyMulti == true then
											return true;
										end;

										Interface.Update();
										return;
									end;
									OnSecondaryClick=function(promptDialogFrame, textButton)
										if textButton:GetAttribute("SkipClose") then
											textButton:SetAttribute("SkipClose", nil);
											textButton.Text = "Purchase";

										else
											textButton:SetAttribute("SkipClose", true);
											textButton.Text = "Purchase Multiple";

										end
										return true;
									end;
								};
								{
									Text="Cancel";
									Style="Cancel";
								};
							};
						});

						purchaseDebounce = false;
					end

					newListing.MouseButton1Click:Connect(purchaseClicked);
				end

			end)
		end

		--pageFrame
	end

	function Interface.Update()
		for _, obj in pairs(typesFrame:GetChildren()) do
			if obj:IsA("GuiObject") then
				obj:Destroy();
			end
		end
		for cataType, cataInfo in pairs(modShopLibrary.Pages) do
			local newCataButton = typeOptionTemplate:Clone();
			local cataButton = newCataButton:WaitForChild("Button");

			local cataLabel = cataButton:WaitForChild("TextLabel");
			cataLabel.Text = "<b>"..cataType.."</b>";
			if not modConfigurations.CompactInterface then
				cataLabel.Size = UDim2.new(1, -35, 1, -10);
			end
			newCataButton.LayoutOrder = cataInfo.Order*100;
			newCataButton.Parent = typesFrame;
			
			if activeShopType == "Bandits" then
				cataButton.BackgroundColor3 = Color3.fromRGB(100, 67, 60);
				
			else
				cataButton.BackgroundColor3 = Color3.fromRGB(70, 60, 100);
				
			end
			cataButton.MouseButton1Click:Connect(function()
				Interface:PlayButtonClick();
				Interface.LoadPage(cataType);
			end)

			if cataInfo.FrontPage and not modConfigurations.CompactInterface then
				for a=1, #cataInfo.FrontPage do
					local optInfo = cataInfo.FrontPage[a];

					if optInfo.ShopType and optInfo.ShopType ~= activeShopType then
						continue;
					end

					local newOptButton = typeOptionTemplate:Clone();
					newOptButton.Size = UDim2.new(1, 0, 0, 30);

					local cataButtonB = newOptButton:WaitForChild("Button");
					local cataLabelB = cataButtonB:WaitForChild("TextLabel");
					local imageIcon = cataButtonB:WaitForChild("ImageIcon");

					if activeShopType == "Bandits" then
						cataButtonB.BackgroundColor3 = Color3.fromRGB(86, 56, 50);

					else
						cataButtonB.BackgroundColor3 = Color3.fromRGB(60, 50, 86);

					end
					

					if optInfo.Id == "MissionPassLbPage" then
						local activeBpId = modBattlePassLibrary.Active;
						local battlepassLib = modBattlePassLibrary:Find(activeBpId);
						if battlepassLib == nil then
							continue;
						end

						optInfo.Icon = battlepassLib.Icon;
						optInfo.Title = battlepassLib.Title;
					end
					
					cataButtonB.Size = UDim2.new(1, -20, 1, 0);
					cataLabelB.Text = optInfo.Title;
					imageIcon.Image = optInfo.Icon or "";
					newOptButton.LayoutOrder = newCataButton.LayoutOrder + a;
					newOptButton.Parent = typesFrame;

					cataButtonB.MouseButton1Click:Connect(function()
						Interface:PlayButtonClick();
						Interface.LoadPage(cataType, optInfo.Id);
					end)
				end
			end
		end
		
		if Interface.SelectedSlot then
			Interface.ClearPage();

			local storageItemID = Interface.SelectedSlot.ID;
			local selectedItem = modData.GetItemById(storageItemID);
			if selectedItem == nil then
				Interface.SelectedSlot = nil;
				Interface.LoadPage("Money");
				return;
			end

			local itemLib = modItemsLibrary:Find(selectedItem.ItemId);
			local weaponInfo = modData:GetItemClass(storageItemID);
			modData.OnAmmoUpdate:Fire(storageItemID);
			
			--==
			if weaponInfo and weaponInfo.OnShopSelect then
				weaponInfo:OnShopSelect(Interface, selectedItem);
			end

			local localplayerStats = modData.GetStats();

			--== MARK: Ammo
			local hasAmmoData = (weaponInfo and ((selectedItem.Values.A and selectedItem.Values.A < weaponInfo.Configurations.AmmoLimit)
				or (selectedItem.Values.MA and selectedItem.Values.MA < weaponInfo.Configurations.MaxAmmoLimit)));
			
			if hasAmmoData then
				local ammoCurrency = modShopLibrary.AmmunitionCurrency or "Money";
				local localplayerCurrency = localplayerStats and localplayerStats[ammoCurrency] or 0;
				local price, mags = modShopLibrary.CalculateAmmoPrice(selectedItem.ItemId, selectedItem.Values, weaponInfo.Configurations, localplayerCurrency, modData.Profile.Punishment == modGlobalVars.Punishments.AmmoCostPenalty);

				Interface.NewListing(function(newListing)
					newListing.Name = "AmmoRefillOption";
					local infoBox = newListing:WaitForChild("infoFrame");
					local descFrame = infoBox:WaitForChild("descFrame");

					local purchaseButton = newListing:WaitForChild("purchaseButton");
					local priceLabel = purchaseButton:WaitForChild("buttonText");
					local iconButton = newListing:WaitForChild("iconButton");
					local iconLabel = iconButton:WaitForChild("iconLabel");
					local titleLabel = descFrame:WaitForChild("titleLabel");
					local labelFrame = descFrame:WaitForChild("labelFrame");
					local descLabel = labelFrame:WaitForChild("descLabel");

					local priceTag = "$"..modFormatNumber.Beautify(price);
					descLabel.Text = `Refill <b>{itemLib.Name}</b> ammunition`..(price > 0 and ` for <b>{priceTag}</b>.` or `.`);
					--"<b>"..itemLib.Name.."</b>: ".."Buy "..mags.." magazine"..(mags > 1 and "s" or "").." = "..priceTag;
						
					titleLabel.Text = "Refill Ammunition";
					priceLabel.Text = priceTag;
					iconLabel.Image = "rbxassetid://2040144031";

					local purchaseAmmoDebounce = false;
					newListing.MouseButton1Click:Connect(function()
						if purchaseAmmoDebounce then return end;
						purchaseAmmoDebounce = true;
						
						local serverReply = localplayerStats and (localplayerStats[ammoCurrency] or 0) >= price and remoteShopService:InvokeServer("buyammo", {StoreObj=Interface.Object;}, storageItemID) or modShopLibrary.PurchaseReplies.InsufficientCurrency;
						if serverReply == modShopLibrary.PurchaseReplies.Success then
							modData.OnAmmoUpdate:Fire(storageItemID);
							
							RunService.Heartbeat:Wait();
							newListing:Destroy();

						else
							warn("Ammunition Purchase>> Error Code:"..serverReply);
							descLabel.Text = string.gsub(modShopLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply), "$Currency", "Money");
						end
						purchaseAmmoDebounce = false;
					end)
				end)
			end
			
			--== MARK: Refill Charges
			if selectedItem.ItemId == "ammopouch" and selectedItem.Values and selectedItem.Values.C then
				local itemClass = modData:GetItemClass(selectedItem.ID);

				Interface.NewListing(function(newListing)
					newListing.Name = "RefillOption";
					local infoBox = newListing:WaitForChild("infoFrame");
					local descFrame = infoBox:WaitForChild("descFrame");

					local purchaseButton = newListing:WaitForChild("purchaseButton");
					local priceLabel = purchaseButton:WaitForChild("buttonText");
					local iconButton = newListing:WaitForChild("iconButton");
					local iconLabel = iconButton:WaitForChild("iconLabel");
					local titleLabel = descFrame:WaitForChild("titleLabel");
					local labelFrame = descFrame:WaitForChild("labelFrame");
					local descLabel = labelFrame:WaitForChild("descLabel");

					descLabel.Text = `Do you want to refill {itemClass.Configurations.BaseRefillCharge} ammo pouch charges?`;
						
					titleLabel.Text = "Refill Charges";
					priceLabel.Text = `Refill`;
					iconLabel.Image = itemLib.Icon;

					local refillDebounce = false;
					newListing.MouseButton1Click:Connect(function()
						if refillDebounce then return end;
						refillDebounce = true;
						
						local serverReply = remoteShopService:InvokeServer("refillcharges", Interface.Object, selectedItem.ID);

						if serverReply == modShopLibrary.PurchaseReplies.Success then
							RunService.Heartbeat:Wait();
							newListing:Destroy();

						else
							warn("Refill Purchase>> Error Code:"..serverReply);
							descLabel.Text = string.gsub(modShopLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply), "$Currency", "Money");
						end
						refillDebounce = false;
					end)
				end)
			end

			--== MARK: Repairable
			local repairPrice = modShopLibrary.RepairPrice[selectedItem.ItemId];
			if repairPrice and selectedItem.Values and selectedItem.Values.Health and selectedItem.Values.MaxHealth and selectedItem.Values.Health <= selectedItem.Values.MaxHealth then
				
				Interface.NewListing(function(newListing)
					newListing.Name = "RepairOption";
					local infoBox = newListing:WaitForChild("infoFrame");
					local descFrame = infoBox:WaitForChild("descFrame");

					local purchaseButton = newListing:WaitForChild("purchaseButton");
					local priceLabel = purchaseButton:WaitForChild("buttonText");
					local iconButton = newListing:WaitForChild("iconButton");
					local iconLabel = iconButton:WaitForChild("iconLabel");
					local titleLabel = descFrame:WaitForChild("titleLabel");
					local labelFrame = descFrame:WaitForChild("labelFrame");
					local descLabel = labelFrame:WaitForChild("descLabel");

					local priceTag = "$"..modFormatNumber.Beautify(repairPrice);
					descLabel.Text = "<b>"..itemLib.Name.."</b>: Repair for "..priceTag;
						
					titleLabel.Text = "Repair Item";
					priceLabel.Text = priceTag;
					iconLabel.Image = "";

					local purchaseRepairDebounce = false;
					newListing.MouseButton1Click:Connect(function()
						if purchaseRepairDebounce then return end;
						purchaseRepairDebounce = true;
						
						local serverReply = localplayerStats and (localplayerStats.Money or 0) >= repairPrice 
						and remoteShopService:InvokeServer("buyrepair", Interface.Object, storageItemID) or modShopLibrary.PurchaseReplies.InsufficientCurrency;

						if serverReply == modShopLibrary.PurchaseReplies.Success then
							RunService.Heartbeat:Wait();
							newListing:Destroy();

						else
							warn("Repair Purchase>> Error Code:"..serverReply);
							descLabel.Text = string.gsub(modShopLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply), "$Currency", "Money");
						end
						purchaseRepairDebounce = false;
					end)
				end)
			end
			
			--== MARK: Can be sold
			local bpLib = modBlueprintLibrary.Get(selectedItem.ItemId);
			local price = modShopLibrary.SellPrice[selectedItem.ItemId]
				or bpLib and (bpLib.SellPrice or (bpLib.Tier and modShopLibrary.SellPrice["Tier"..bpLib.Tier])) or nil;

			if itemLib and price then
				Interface.NewListing(function(newListing)
					local infoBox = newListing:WaitForChild("infoFrame");
					local descFrame = infoBox:WaitForChild("descFrame");

					local purchaseButton = newListing:WaitForChild("purchaseButton");
					local priceLabel = purchaseButton:WaitForChild("buttonText");
					local iconButton = newListing:WaitForChild("iconButton");
					local iconLabel = iconButton:WaitForChild("iconLabel");
					local titleLabel = descFrame:WaitForChild("titleLabel");
					local labelFrame = descFrame:WaitForChild("labelFrame");
					local descLabel = labelFrame:WaitForChild("descLabel");

					local priceTag = "$"..modFormatNumber.Beautify(price);
					descLabel.Text = "Sell "..itemLib.Name.." for "..priceTag;
					titleLabel.Text = "Sell";
					priceLabel.Text = priceTag;
					iconLabel.Image = itemLib.Icon or "";

					local sellItemDebounce = false;
					newListing.MouseButton1Click:Connect(function()
						if sellItemDebounce then return end;
						sellItemDebounce = true;

						Interface:PromptDialogBox({
							Title=`Sell: {itemLib.Name}`;
							Desc=`Are you sure you want to sell <b>{itemLib.Name}</b> for <b>${price}</b>?`;
							Icon=itemLib.Icon;
							Buttons={
								{
									Text="Sell";
									Style="Confirm";
									OnPrimaryClick=function(promptDialogFrame, textButton)
										promptDialogFrame.statusLabel.Text = "Selling item...";
				
										if selectedItem.Fav then
											promptDialogFrame.statusLabel.Text  = "Can't sell favourited item.";
											sellItemDebounce = false;
											return;
										end;

										
										local serverReply = remoteShopService:InvokeServer("sellitem", Interface.Object, storageItemID);
										if serverReply == modShopLibrary.PurchaseReplies.Success then
											promptDialogFrame.statusLabel.Text = "Sold!";
											wait(0.5);
										else
											warn("Sell Item>> Error Code:"..tostring(serverReply));
											promptDialogFrame.statusLabel.Text = (modShopLibrary.PurchaseReplies[serverReply] or tostring(serverReply)):gsub("$Currency", "Money");
											wait(1);
										end

										Interface.Update();
									end;
								};
								{
									Text="Cancel";
									Style="Cancel";
								};
							}
						});

						sellItemDebounce = false;
					end)
				end)
				
				
				--== MARK:  Sell all
				if selectedItem.Quantity > 1 then
					Interface.NewListing(function(newListing)
						local infoBox = newListing:WaitForChild("infoFrame");
						local descFrame = infoBox:WaitForChild("descFrame");

						local purchaseButton = newListing:WaitForChild("purchaseButton");
						local priceLabel = purchaseButton:WaitForChild("buttonText");
						local iconButton = newListing:WaitForChild("iconButton");
						local iconLabel = iconButton:WaitForChild("iconLabel");
						local titleLabel = descFrame:WaitForChild("titleLabel");
						local labelFrame = descFrame:WaitForChild("labelFrame");
						local descLabel = labelFrame:WaitForChild("descLabel");

						local allPrice = price * selectedItem.Quantity;
						local priceTag = "$"..modFormatNumber.Beautify(allPrice);
						descLabel.Text = "Sell all "..itemLib.Name.." for "..priceTag;
						titleLabel.Text = "Sell All";
						priceLabel.Text = priceTag;
						iconLabel.Image = itemLib.Icon or "";

						local sellItemDebounce = false;
						newListing.MouseButton1Click:Connect(function()
							if sellItemDebounce then return end;
							sellItemDebounce = true;

							local allQuantity = selectedItem.Quantity;
							Interface:PromptDialogBox({
								Title=`Sell All: {itemLib.Name}`;
								Desc=`Are you sure you want to sell <b>{allQuantity}</b> <b>{itemLib.Name}</b> for <b>${allPrice}</b>?`;
								Icon=itemLib.Icon;
								Buttons={
									{
										Text="Sell";
										Style="Confirm";
										OnPrimaryClick=function(promptDialogFrame, textButton)
											promptDialogFrame.statusLabel.Text = "Selling item...";
					
											if selectedItem.Fav then
												promptDialogFrame.statusLabel.Text  = "Can't sell favourited item.";
												sellItemDebounce = false;
												return;
											end;
	
											
											local serverReply = remoteShopService:InvokeServer("sellitem", Interface.Object, storageItemID, allQuantity);
											if serverReply == modShopLibrary.PurchaseReplies.Success then
												promptDialogFrame.statusLabel.Text = `Sold all <b>{allQuantity}</b> {itemLib.Name}!`;
												wait(1);
											else
												warn("Sell Item>> Error Code:"..tostring(serverReply));
												promptDialogFrame.statusLabel.Text = (modShopLibrary.PurchaseReplies[serverReply] or tostring(serverReply)):gsub("$Currency", "Money");
												wait(1);
											end
	
											Interface.Update();
										end;
									};
									{
										Text="Cancel";
										Style="Cancel";
									};
								}
							});

							sellItemDebounce = false;
						end)
					end)
				end
				
			end

			--== MARK: Exchange Gift Shop Tokens
			local isExchangable = modItemsLibrary:HasTag(itemLib.Id, "Skin Perm") or modItemsLibrary:HasTag(itemLib.Id, "Color Pack") or modItemsLibrary:HasTag(itemLib.Id, "Skin Pack");
			local activeBpId = modBattlePassLibrary.Active;
			local battlepassLib = activeBpId and modBattlePassLibrary:Find(activeBpId);
			if modBattlePassLibrary.Library.GiftShop and activeBpId and #activeBpId > 0 and isExchangable and battlepassLib and battlepassLib.Tree then
				Interface.NewListing(function(newListing)
					local infoBox = newListing:WaitForChild("infoFrame");
					local descFrame = infoBox:WaitForChild("descFrame");

					local purchaseButton = newListing:WaitForChild("purchaseButton");
					local priceLabel = purchaseButton:WaitForChild("buttonText");
					local iconButton = newListing:WaitForChild("iconButton");
					local iconLabel = iconButton:WaitForChild("iconLabel");
					local titleLabel = descFrame:WaitForChild("titleLabel");
					local labelFrame = descFrame:WaitForChild("labelFrame");
					local descLabel = labelFrame:WaitForChild("descLabel");

					local tokenReward = 1;
					descLabel.Text = `Exchange {itemLib.Name} for <b>{tokenReward}</b> Event Pass's Gift Shop Token`;
					titleLabel.Text = `Exchange {tokenReward} Token`;
					priceLabel.Text = `{tokenReward} Token`;
					iconLabel.Image = battlepassLib.Icon;

					local exchangeItemDebounce = false;
					newListing.MouseButton1Click:Connect(function()
						if exchangeItemDebounce then return end;
						exchangeItemDebounce = true;

						Interface:PromptDialogBox({
							Title=`Exchange: {itemLib.Name}`;
							Desc=`Are you sure you want to exchange <b>1 {itemLib.Name}</b> for <b>{tokenReward}</b> token.`;
							Icon=itemLib.Icon;
							Buttons={
								{
									Text="Exchange";
									Style="Confirm";
									OnPrimaryClick=function(promptDialogFrame, textButton)
										promptDialogFrame.statusLabel.Text = "Exchanging item..";

										if selectedItem.Fav then
											promptDialogFrame.statusLabel.Text = "Can't exchange favorited items.";
											exchangeItemDebounce = false;
											
											return;
										end;

										local serverReply = remoteShopService:InvokeServer("exchangefortoken", Interface.Object, storageItemID);
										if serverReply == modShopLibrary.PurchaseReplies.Success then
											promptDialogFrame.statusLabel.Text = "Exchanged!";
											wait(0.5);
											
										else
											warn("Exchange Item>> Error Code:"..tostring(serverReply));
											promptDialogFrame.statusLabel.Text = (modShopLibrary.PurchaseReplies[serverReply] or tostring(serverReply));
											task.wait(1);

										end

										Interface.Update();
									end;
								};
								{
									Text="Cancel";
									Style="Cancel";
								};
							}
						});

						exchangeItemDebounce = false;
					end)
				end)

				--== MARK: Exchange all for Gift Shop Tokens
				if selectedItem.Quantity > 1 then
					Interface.NewListing(function(newListing)
						local infoBox = newListing:WaitForChild("infoFrame");
						local descFrame = infoBox:WaitForChild("descFrame");
	
						local purchaseButton = newListing:WaitForChild("purchaseButton");
						local priceLabel = purchaseButton:WaitForChild("buttonText");
						local iconButton = newListing:WaitForChild("iconButton");
						local iconLabel = iconButton:WaitForChild("iconLabel");
						local titleLabel = descFrame:WaitForChild("titleLabel");
						local labelFrame = descFrame:WaitForChild("labelFrame");
						local descLabel = labelFrame:WaitForChild("descLabel");
	
						local tokenReward = 1 * selectedItem.Quantity;
						descLabel.Text = `Exchange <b>{itemLib.Name}</b> for <b>{tokenReward}</b> Event Pass's Gift Shop Token`;
						titleLabel.Text = `Exchange {tokenReward} Token`;
						priceLabel.Text = `{tokenReward} Token`;
						iconLabel.Image = battlepassLib.Icon;
	
						local exchangeItemDebounce = false;
						newListing.MouseButton1Click:Connect(function()
							if exchangeItemDebounce then return end;
							exchangeItemDebounce = true;
	
							local exchangeQuantity = selectedItem.Quantity;
							Interface:PromptDialogBox({
								Title=`Exchange All: {itemLib.Name}`;
								Desc=`Are you sure you want to exchange <b>{exchangeQuantity} {itemLib.Name}</b> for <b>{tokenReward}</b> tokens.`;
								Icon=itemLib.Icon;
								Buttons={
									{
										Text="Exchange All";
										Style="Confirm";
										OnPrimaryClick=function(promptDialogFrame, textButton)
											promptDialogFrame.statusLabel.Text = "Exchanging item..";
	
											if selectedItem.Fav then
												promptDialogFrame.statusLabel.Text = "Can't exchange favorited items.";
												exchangeItemDebounce = false;
												
												return;
											end;
	
											local serverReply = remoteShopService:InvokeServer("exchangefortoken", Interface.Object, storageItemID, exchangeQuantity);
											if serverReply == modShopLibrary.PurchaseReplies.Success then
												promptDialogFrame.statusLabel.Text = `Exchanged <b>{exchangeQuantity} {itemLib.Name}</b> for <b>{tokenReward}</b> tokens!`;
												wait(1);
												
											else
												warn("Exchange Item>> Error Code:"..tostring(serverReply));
												promptDialogFrame.statusLabel.Text = (modShopLibrary.PurchaseReplies[serverReply] or tostring(serverReply));
												task.wait(1);
	
											end
	
											Interface.Update();
										end;
									};
									{
										Text="Cancel";
										Style="Cancel";
									};
								}
							});
							
							exchangeItemDebounce = false;
						end)
					end)
				end
			end

		end

		if modConfigurations.CompactInterface then
			typesFrame.CanvasSize = UDim2.new(0, typesListLayout.AbsoluteContentSize.X, 0, 0);
		else
			typesFrame.CanvasSize = UDim2.new(0, 0, 0, typesListLayout.AbsoluteContentSize.Y+10);
		end
	end

	function Interface.NewListing(func)
		local newListing = listingTemplate:Clone();
		func(newListing);
		newListing.MouseButton1Click:Connect(function()
			Interface:PlayButtonClick();
		end)
		newListing.MouseMoved:Connect(function()
			newListing.BackgroundTransparency = 0.6;
		end)
		newListing.MouseLeave:Connect(function()
			newListing.BackgroundTransparency = 0.8;
		end)

		newListing.Parent = pageFrame;
	end

	return Interface;
end;

return Interface;