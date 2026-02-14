local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modShopLibrary = shared.require(game.ReplicatedStorage.Library.RatShopLibrary);
local modBlueprintLibrary = shared.require(game.ReplicatedStorage.Library.BlueprintLibraryRotd);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modFormatNumber = shared.require(game.ReplicatedStorage.Library.FormatNumber);
local modBattlePassLibrary = shared.require(game.ReplicatedStorage.Library.BattlePassLibrary);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local remoteShopService = modRemotesManager:Get("ShopService");
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local typeOptionTemplate = script:WaitForChild("TypeOption");
    local listingTemplate = script:WaitForChild("templateOption");
        
    local branchColor = modBranchConfigurations.BranchColor;	

	local activeShopType = "Rats";
	local interfaceScreenGui = interface.ScreenGui;
	
	local shopFrame = nil;
	if modConfigurations.CompactInterface then
        shopFrame = script:WaitForChild("MobileRatShopFrame"):Clone();
    else
        shopFrame = script:WaitForChild("RatShopFrame"):Clone();
    end
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


    --MARK: Window
	local window: InterfaceWindow = interface:NewWindow("RatShopWindow", shopFrame);
    window.BoolStringWhenActive = {String="!CharacterHud | CurrencyStats"; Priority=2;};
    window.DisableInteractables = true;
	if modConfigurations.CompactInterface then
		window.CompactFullscreen = true;
		window:SetClosePosition(UDim2.new(0.5, 0, 1, 0), UDim2.new(0.5, 0, 0, 0));
		shopTitleLabel.Parent:WaitForChild("closeButton").MouseButton1Click:Connect(function()
			window:Close();
		end)
		
	else
		window:SetClosePosition(UDim2.new(2, -10, 0.5, 0), UDim2.new(1, -10, 0.5, 0));

	end
	window:AddCloseButton(shopFrame);

    local binds = window.Binds;

	binds.PageFrame = pageFrame;
    binds.RankColors = {
        Color3.fromRGB(255, 220, 112);
        Color3.fromRGB(255, 255, 255);
        Color3.fromRGB(181, 99, 85);
        Color3.fromRGB(170, 170, 170);
    };
	binds.SelectedSlot = nil;

	--MARK: OnToggle
	window.OnToggle:Connect(function(visible, interactable, interactInfo)
		if visible then
			binds.Interactable = interactable;
			local shopType = interactable.Values.ShopType;
			binds.InteractPart = interactable.Part;

			for a=1, #interface.StorageInterfaces do
				local storageInterface: StorageInterface? = interface.StorageInterfaces[a];
				if storageInterface == nil or storageInterface.StorageId ~= "Inventory" and storageInterface.StorageId ~= "Clothing" then
					continue;
				end
				storageInterface.OnItemButton1Click = binds.onItemSelect;
			end
			
			activeShopType = shopType or "Rats";
			
			Debugger:Log("activeShopType", activeShopType);
			
			if activeShopType == "Bandits" then
				shopTitleLabel.Text = "Bandit's Market";
			else
				shopTitleLabel.Text = "R.A.T. Services";
			end

			if interactable and interactable.Values.ItemId then
				
			end
			
			interface:HideAll{[window.Name]=true; ["Inventory"]=true;};
            
            interface:ToggleWindow("Inventory", true);
            
			task.spawn(function()
				modData:GetFlag("ItemCodex", true);
			end)
			task.spawn(function()
				repeat until 
                    not window.Visible 
                    or binds.InteractPart == nil 
                    or not binds.InteractPart:IsDescendantOf(workspace) 
                    or localPlayer:DistanceFromCharacter(binds.InteractPart.Position) >= 16 
                    or not wait(0.5);

                window:Close();
			end)

			-- if reselectSlot and reselectSlot.Button then
			-- 	binds.onItemSelect(nil, reselectSlot);
	
			-- else
                window:Update();
				binds.LoadPage("Money");
	
			-- end
			
		else
			game.Debris:AddItem(shopFrame:FindFirstChild("ToolTip"), 0);
			
			binds.ClearPage();
			binds.SelectedSlot = nil;

			for a=#interface.StorageInterfaces, 1, -1 do
				local storageInterface: StorageInterface = interface.StorageInterfaces[a];
				if storageInterface == nil then continue end;
				if storageInterface.StorageId ~= "Inventory" and storageInterface.StorageId ~= "Clothing" then
					continue;
				end
				storageInterface.OnItemButton1Click = storageInterface.BeginDragItem;
			end

            interface:ToggleWindow("Inventory", false);
            interface:ToggleWindow("WeaponStats", false);
			
		end
	end)



	function binds.onItemSelect(storageInterface, slot)
		if slot and slot.Button 
            and (binds.SelectedSlot == nil or binds.SelectedSlot.ID ~= (slot and slot.ID or 0)) then
			binds.clearSlotHighlight(slot);
			binds.SelectedSlot = slot;
			interface:PlayButtonClick();

			slot.Button.BackgroundTransparency = 0.3;
			slot.Button.BackgroundColor3 = branchColor;

            window:Update();
		else
			binds.ClearSelection();

            window:Update();
			binds.LoadPage("Money");
		end
    end

	function binds.clearSlotHighlight(slot)
		for a=#interface.StorageInterfaces, 1, -1 do
			local storageInterface: StorageInterface = interface.StorageInterfaces[a];
			if storageInterface == nil then continue end;
			if storageInterface.StorageId ~= "Inventory" and storageInterface.StorageId ~= "Clothing" then
				continue;
			end

			for id, button in pairs(storageInterface.Buttons) do
				if (slot == nil or id ~= slot.ID) and button.Button then
					button.Button.BackgroundTransparency = 1;
				end
			end
		end
	end




	function binds.ClearSelection()
		binds.clearSlotHighlight();
		binds.SelectedSlot = nil;
	end


	function binds.ClearPage()
		for _, obj in pairs(pageFrame:GetChildren()) do
			if obj:IsA("GuiObject") then
				obj:Destroy();
			end
		end
	end

	function binds.LoadPage(catalogType, pageName)
		if modShopLibrary.Pages[catalogType] == nil then return end;
		local cataInfo = modShopLibrary.Pages[catalogType];

		binds.ClearSelection();
		binds.ClearPage();
		
		pageName = pageName or "FrontPage";
		if cataInfo.Type == "Page" then
			pageName = cataInfo.Id;
		end
		
		if cataInfo[pageName] == nil then

			local modPage = script:FindFirstChild(pageName);
			modPage = modPage and shared.require(modPage) or nil;

			if modPage then
				modPage:Load(interface, window);
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
			
			
			binds.NewListing(function(newListing)
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
						binds.LoadPage(catalogType, info.Id);
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

						modClientGuis.promptDialogBox({
							Title=`Purchase: {itemLib.Name}`;
							Desc=`Are you sure you want to purchase <b>{itemLib.Name}</b> for <b>{priceLabel.Text}</b>?\n\n<font size="8">(Right click to enable multi purchase.)</font>`;
							Icon=itemLib.Icon;
							Buttons={
								{
									Text="Purchase";
									Style="Confirm";
									OnPrimaryClick=function(dialogWindow, textButton)
                                    	local statusLabel = dialogWindow.Binds.StatusLabel;

										local buyMulti = textButton:GetAttribute("SkipClose");

										statusLabel.Text = "Purchasing item<...>";
				
										local serverReply = remoteShopService:InvokeServer("buyitem", binds.InteractPart, info.Id);
										if serverReply == modShopLibrary.PurchaseReplies.Success then
											statusLabel.Text = "Purchased!";

											wait(buyMulti and 0.2 or 0.5);
										else
											warn("Purchase Item>> Error Code:"..serverReply);
											statusLabel.Text = (modShopLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply)):gsub("$Currency", product.Currency);
											wait(1);
										end
	
										if buyMulti == true then
											return true;
										end;

                                        window:Update();
										return;
									end;
									OnSecondaryClick=function(promptDialogFrame, textButton)
										if textButton:GetAttribute("SkipClose") then
											textButton:SetAttribute("SkipClose", nil);
											textButton.Text = "Purchase";

										else
											textButton:SetAttribute("SkipClose", true);
											textButton.Text = "Purchase Again";

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

	--MARK: OnUpdate
    window.OnUpdate:Connect(function()
        local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
		local wieldComp: WieldComp = playerClass.WieldComp;

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
				interface:PlayButtonClick();
				binds.LoadPage(cataType);
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
						interface:PlayButtonClick();
						binds.LoadPage(cataType, optInfo.Id);
					end)
				end
			end
		end
		
		binds.ClearPage();

		if binds.SelectedSlot == nil then return end;

		local storageItemID = binds.SelectedSlot.ID;
		local selectedItem = modData.GetItemById(storageItemID);
		if selectedItem == nil then
			binds.SelectedSlot = nil;
			binds.LoadPage("Money");
			return;
		end

		local itemLib = modItemsLibrary:Find(selectedItem.ItemId);

		local equipmentClass: EquipmentClass = wieldComp:GetEquipmentClass(storageItemID);
		
		if equipmentClass and equipmentClass.Properties.OnShopSelect then
			equipmentClass.Properties:OnShopSelect(interface, selectedItem);
		end

		local localplayerStats = modData.GetStats();

		if equipmentClass then
			local configurations = equipmentClass.Configurations;

			--== MARK: Ammo
			local usesAmmo = configurations.MagazineSize ~= nil or configurations.AmmoCapacity ~= nil;
			local ammo = selectedItem:GetValues("A") or configurations.MagazineSize;
			local maxAmmo = selectedItem:GetValues("MA") or configurations.AmmoCapacity;

			local ammoIsNotFull = usesAmmo 
								and (ammo < configurations.MagazineSize or maxAmmo < configurations.AmmoCapacity);
			
			if ammoIsNotFull then
				local ammoCurrency = modShopLibrary.AmmunitionCurrency or "Money";
				local localplayerCurrency = localplayerStats and localplayerStats[ammoCurrency] or 0;
				local price, _mags = modShopLibrary.CalculateAmmoPrice(
					selectedItem.ItemId, 
					selectedItem.Values, 
					configurations, 
					localplayerCurrency, 
					modData.Profile.Punishment == modGlobalVars.Punishments.AmmoCostPenalty
				);

				binds.NewListing(function(newListing)
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

					titleLabel.Text = "Refill Ammunition";
					priceLabel.Text = priceTag;
					iconLabel.Image = "rbxassetid://2040144031";

					local purchaseAmmoDebounce = false;
					newListing.MouseButton1Click:Connect(function()
						if purchaseAmmoDebounce then return end;
						purchaseAmmoDebounce = true;
						
						if localplayerStats == nil or (localplayerStats[ammoCurrency] or 0) < price then
							purchaseAmmoDebounce = false;
							descLabel.Text = "Not enough money!";
							return;
						end

						local serverReply = remoteShopService:InvokeServer("buyammo", {
                            InteractConfig = binds.Interactable and binds.Interactable.Config;
                            Siid = selectedItem.ID;
                            StorageId = binds.StorageId;
						});

						if serverReply == modShopLibrary.PurchaseReplies.Success then
							RunService.Heartbeat:Wait();
                        	equipmentClass.ClassSelf:RefillAmmo(equipmentClass, selectedItem);
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
			if selectedItem.ItemId == "ammopouch" then
				local ammoPouchData = modData:GetEvent("AmmoPouchData");
				local charges = ammoPouchData and ammoPouchData.Charges or configurations.BaseRefillCharge;

				if charges < configurations.BaseRefillCharge then
					binds.NewListing(function(newListing)
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

						descLabel.Text = `Do you want to refill {configurations.BaseRefillCharge} ammo pouch charges?`;
							
						titleLabel.Text = "Refill Charges";
						priceLabel.Text = `Refill`;
						iconLabel.Image = itemLib.Icon;

						local refillDebounce = false;
						newListing.MouseButton1Click:Connect(function()
							if refillDebounce then return end;
							refillDebounce = true;
							
							local serverReply = remoteShopService:InvokeServer("refillcharges", binds.InteractPart, selectedItem.ID);

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
			end
		end
		--== MARK: Repairable
		local repairPrice = modShopLibrary.RepairPrice[selectedItem.ItemId];
		if repairPrice and selectedItem.Values and selectedItem.Values.Health and selectedItem.Values.MaxHealth and selectedItem.Values.Health <= selectedItem.Values.MaxHealth then
			
			binds.NewListing(function(newListing)
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
					and remoteShopService:InvokeServer("buyrepair", binds.InteractPart, storageItemID) or modShopLibrary.PurchaseReplies.InsufficientCurrency;

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

		if itemLib and price and selectedItem.Quantity > 0 then
			binds.NewListing(function(newListing)
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

					modClientGuis.promptDialogBox({
						Title=`Sell: {itemLib.Name}`;
						Desc=`Are you sure you want to sell <b>{itemLib.Name}</b> for <b>${price}</b>?`;
						Icon=itemLib.Icon;
						Buttons={
							{
								Text="Sell";
								Style="Confirm";
								OnPrimaryClick=function(dialogWindow, textButton)
									local statusLabel = dialogWindow.Binds.StatusLabel;
									statusLabel.Text = "Selling item<...>";
			
									if selectedItem.Fav then
										statusLabel.Text  = "Can't sell favourited item.";
										sellItemDebounce = false;
										return;
									end;

									local serverReply = remoteShopService:InvokeServer("sellitem", binds.InteractPart, storageItemID);
									if serverReply == modShopLibrary.PurchaseReplies.Success then
										statusLabel.Text = "Sold!";
										selectedItem.Quantity -= 1;

										if selectedItem.Quantity <= 1 then
											binds.ClearPage();
										end
										wait(0.5);
									else
										warn("Sell Item>> Error Code:"..tostring(serverReply));
										statusLabel.Text = (modShopLibrary.PurchaseReplies[serverReply] or tostring(serverReply)):gsub("$Currency", "Money");
										wait(1);
									end

									window:Update();
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
				binds.NewListing(function(newListing)
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
						modClientGuis.promptDialogBox({
							Title=`Sell All: {itemLib.Name}`;
							Desc=`Are you sure you want to sell <b>{allQuantity}</b> <b>{itemLib.Name}</b> for <b>${allPrice}</b>?`;
							Icon=itemLib.Icon;
							Buttons={
								{
									Text="Sell";
									Style="Confirm";
									OnPrimaryClick=function(dialogWindow, textButton)
										local statusLabel = dialogWindow.Binds.StatusLabel;
										statusLabel.Text = "Selling item<...>";
				
										if selectedItem.Fav then
											statusLabel.Text  = "Can't sell favourited item.";
											sellItemDebounce = false;
											return;
										end;

										
										local serverReply = remoteShopService:InvokeServer("sellitem", binds.InteractPart, storageItemID, allQuantity);
										if serverReply == modShopLibrary.PurchaseReplies.Success then
											statusLabel.Text = `Sold all <b>{allQuantity}</b> {itemLib.Name}!`;
											selectedItem.Quantity = 0;
											binds.ClearPage();
											task.wait(1);
										else
											warn("Sell Item>> Error Code:"..tostring(serverReply));
											statusLabel.Text = (modShopLibrary.PurchaseReplies[serverReply] or tostring(serverReply)):gsub("$Currency", "Money");
											task.wait(1);
										end

										window:Update();
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
		local activeBpId = modBattlePassLibrary.Active and #modBattlePassLibrary.Active > 0 and modBattlePassLibrary.Active or nil;
		local battlepassLib = activeBpId and modBattlePassLibrary:Find(activeBpId);

		local hasBpTree = battlepassLib and battlepassLib.Tree 

		if modBattlePassLibrary.Library.GiftShop and activeBpId and isExchangable and hasBpTree then
			binds.NewListing(function(newListing)
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

					modClientGuis.promptDialogBox({
						Title=`Exchange: {itemLib.Name}`;
						Desc=`Are you sure you want to exchange <b>1 {itemLib.Name}</b> for <b>{tokenReward}</b> token.`;
						Icon=itemLib.Icon;
						Buttons={
							{
								Text="Exchange";
								Style="Confirm";
								OnPrimaryClick=function(dialogWindow, textButton)
									local statusLabel = dialogWindow.Binds.StatusLabel;
									statusLabel.Text = "Exchanging item<...>";

									if selectedItem.Fav then
										statusLabel.Text = "Can't exchange favorited items.";
										exchangeItemDebounce = false;
										
										return;
									end;

									local serverReply = remoteShopService:InvokeServer("exchangefortoken", binds.InteractPart, storageItemID);
									if serverReply == modShopLibrary.PurchaseReplies.Success then
										statusLabel.Text = "Exchanged!";
										wait(0.5);
										
									else
										warn("Exchange Item>> Error Code:"..tostring(serverReply));
										statusLabel.Text = (modShopLibrary.PurchaseReplies[serverReply] or tostring(serverReply));
										task.wait(1);

									end

									window:Update();
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
				binds.NewListing(function(newListing)
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
						modClientGuis.promptDialogBox({
							Title=`Exchange All: {itemLib.Name}`;
							Desc=`Are you sure you want to exchange <b>{exchangeQuantity} {itemLib.Name}</b> for <b>{tokenReward}</b> tokens.`;
							Icon=itemLib.Icon;
							Buttons={
								{
									Text="Exchange All";
									Style="Confirm";
									OnPrimaryClick=function(dialogWindow, textButton)
										local statusLabel = dialogWindow.Binds.StatusLabel;
										statusLabel.Text = "Exchanging item<...>";

										if selectedItem.Fav then
											statusLabel.Text = "Can't exchange favorited items.";
											exchangeItemDebounce = false;
											
											return;
										end;

										local serverReply = remoteShopService:InvokeServer("exchangefortoken", binds.InteractPart, storageItemID, exchangeQuantity);
										if serverReply == modShopLibrary.PurchaseReplies.Success then
											statusLabel.Text = `Exchanged <b>{exchangeQuantity} {itemLib.Name}</b> for <b>{tokenReward}</b> tokens!`;
											wait(1);
											
										else
											warn("Exchange Item>> Error Code:"..tostring(serverReply));
											statusLabel.Text = (modShopLibrary.PurchaseReplies[serverReply] or tostring(serverReply));
											task.wait(1);

										end

										window:Update();
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

		if modConfigurations.CompactInterface then
			typesFrame.CanvasSize = UDim2.new(0, typesListLayout.AbsoluteContentSize.X, 0, 0);
		else
			typesFrame.CanvasSize = UDim2.new(0, 0, 0, typesListLayout.AbsoluteContentSize.Y+10);
		end
    end)
    
	function binds.NewListing(func)
		local newListing = listingTemplate:Clone();
		func(newListing);
		newListing.MouseButton1Click:Connect(function()
			interface:PlayButtonClick();
		end)
		newListing.MouseMoved:Connect(function()
			newListing.BackgroundTransparency = 0.6;
		end)
		newListing.MouseLeave:Connect(function()
			newListing.BackgroundTransparency = 0.8;
		end)

		newListing.Parent = pageFrame;
	end




-- modData.OnDataEvent:Connect(function(action, hierarchyKey, data)
-- 	if action ~= "syncevent" or (data and data.Id ~= "AmmoPouchData") then return end;
	
-- 	modStorageInterface.RefreshSlotOfItemId("ammopouch");
-- end)

end

return interfacePackage;

