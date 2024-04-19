local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule"));
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
	local pageFrameListLayout = pageFrame:WaitForChild("UIListLayout");
	
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
		if Interface.SelectedSlot == nil or Interface.SelectedSlot.ID ~= (slot and slot.ID or 0) then
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
		Interface.Update();
		Interface.LoadPage("Money");
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

					local purchaseDebounce = false;
					local function purchaseClicked()
						if purchaseDebounce then return end;
						purchaseDebounce = true;

						local promptWindow = Interface:PromptQuestion("Purchase ".. itemLib.Name,
							("Are you sure you want to purchase $ItemName for $Cost?")
							:gsub("$ItemName", itemLib.Name):gsub("$Cost", priceLabel.Text), 
							"Purchase", "Cancel", itemLib.Icon);
						local YesClickedSignal, NoClickedSignal;

						YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
							Interface:PlayButtonClick();

							promptWindow.Frame.Yes.buttonText.Text = "Purchasing";

							local serverReply = remoteShopService:InvokeServer("buyitem", Interface.Object, info.Id);
							if serverReply == modShopLibrary.PurchaseReplies.Success then
								promptWindow.Frame.Yes.buttonText.Text = "Purchased!";
								wait(0.5);
								Interface:OpenWindow("RatShopWindow");
							else
								warn("Sell Item>> Error Code:"..serverReply);
								promptWindow.Frame.Yes.buttonText.Text = (modShopLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply));
							end

							promptWindow:Close();
							Interface:OpenWindow("RatShopWindow");
							YesClickedSignal:Disconnect();
							NoClickedSignal:Disconnect();
						end);
						NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
							Interface:PlayButtonClick();
							promptWindow:Close();
							Interface:OpenWindow("RatShopWindow");
							YesClickedSignal:Disconnect();
							NoClickedSignal:Disconnect();
						end);

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
					local cataLabel = cataButtonB:WaitForChild("TextLabel");
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
					cataLabel.Text = optInfo.Title;
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

			local itemLib = modItemsLibrary:Find(selectedItem.ItemId);
			local weaponInfo = modData:GetItemClass(storageItemID);
			modData.OnAmmoUpdate:Fire(storageItemID);
			
			--==
			if weaponInfo and weaponInfo.OnShopSelect then
				weaponInfo:OnShopSelect(Interface, selectedItem);
			end

			local localplayerStats = modData.GetStats();

			--== Ammo;
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
					descLabel.Text = "<b>"..itemLib.Name.."</b>: ".."Buy "..mags.." magazine"..(mags > 1 and "s" or "").." = "..priceTag;
						
					titleLabel.Text = "Refill Ammunition";
					priceLabel.Text = priceTag;
					iconLabel.Image = "rbxassetid://2040144031";

					local purchaseAmmoDebounce = false;
					newListing.MouseButton1Click:Connect(function()
						if purchaseAmmoDebounce then return end;
						purchaseAmmoDebounce = true;
						
						local serverReply = localplayerStats and (localplayerStats[ammoCurrency] or 0) >= price and remoteShopService:InvokeServer("buyammo", Interface.Object, storageItemID) or modShopLibrary.PurchaseReplies.InsufficientCurrency;
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
			
			--== Repairable;
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
			
			--== Can be sold;
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
					iconLabel.Image = "rbxassetid://3598790816";

					local sellItemDebounce = false;
					newListing.MouseButton1Click:Connect(function()
						if sellItemDebounce then return end;
						sellItemDebounce = true;

						local promptWindow = Interface:PromptQuestion("Sell: ".. itemLib.Name,
							("Are you sure you want to sell $ItemName for $$Cost?")
							:gsub("$ItemName", itemLib.Name):gsub("$Cost", price), 
							"Sell", "Cancel", "rbxassetid://3598790816");
						local YesClickedSignal, NoClickedSignal;

						YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
							Interface:PlayButtonClick();

							promptWindow.Frame.Yes.buttonText.Text = "Selling item..";
							if selectedItem.Fav then
								promptWindow.Frame.Yes.buttonText.Text = "Can't sell favorited.";
								sellItemDebounce = false;
								Interface:OpenWindow("RatShopWindow");
								return
							end;

							local serverReply = remoteShopService:InvokeServer("sellitem", Interface.Object, storageItemID);
							if serverReply == modShopLibrary.PurchaseReplies.Success then
								promptWindow.Frame.Yes.buttonText.Text = "Sold!";
								wait(0.5);
								Interface:OpenWindow("RatShopWindow");
							else
								warn("Sell Item>> Error Code:"..tostring(serverReply));
								promptWindow.Frame.Yes.buttonText.Text = (modShopLibrary.PurchaseReplies[serverReply] or tostring(serverReply)):gsub("$Currency", "Money");
							end

							promptWindow:Close();
							Interface:OpenWindow("RatShopWindow");
							YesClickedSignal:Disconnect();
							NoClickedSignal:Disconnect();
						end);
						NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
							Interface:PlayButtonClick();
							promptWindow:Close();
							Interface:OpenWindow("RatShopWindow");
							YesClickedSignal:Disconnect();
							NoClickedSignal:Disconnect();
						end);

						sellItemDebounce = false;
					end)
				end)
				
				
				--== Sell all;
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
						iconLabel.Image = "rbxassetid://3598790816";

						local sellItemDebounce = false;
						newListing.MouseButton1Click:Connect(function()
							if sellItemDebounce then return end;
							sellItemDebounce = true;

							local promptWindow = Interface:PromptQuestion("Sell All: ".. itemLib.Name,
								("Are you sure you want to sell $Amt $ItemName for $$Cost?")
								:gsub("$Amt", selectedItem.Quantity):gsub("$ItemName", itemLib.Name):gsub("$Cost", allPrice), 
								"Sell All", "Cancel", "rbxassetid://3598790816");
							local YesClickedSignal, NoClickedSignal;

							YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
								Interface:PlayButtonClick();

								promptWindow.Frame.Yes.buttonText.Text = "Selling item..";
								if selectedItem.Fav then
									promptWindow.Frame.Yes.buttonText.Text = "Can't sell favorited.";
									sellItemDebounce = false;
									Interface:OpenWindow("RatShopWindow");
									return
								end;

								local serverReply = remoteShopService:InvokeServer("sellitem", Interface.Object, storageItemID, selectedItem.Quantity);
								if serverReply == modShopLibrary.PurchaseReplies.Success then
									promptWindow.Frame.Yes.buttonText.Text = "Sold!";
									wait(0.5);
									Interface:OpenWindow("RatShopWindow");
								else
									if serverReply then
										warn("Sell Item>> Error Code:"..serverReply);
										promptWindow.Frame.Yes.buttonText.Text = (modShopLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply)):gsub("$Currency", "Money");

									else
										promptWindow.Frame.Yes.buttonText.Text = "Unknown error";
									end
									
								end

								promptWindow:Close();
								Interface:OpenWindow("RatShopWindow");
								YesClickedSignal:Disconnect();
								NoClickedSignal:Disconnect();
							end);
							NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
								Interface:PlayButtonClick();
								promptWindow:Close();
								Interface:OpenWindow("RatShopWindow");
								YesClickedSignal:Disconnect();
								NoClickedSignal:Disconnect();
							end);

							sellItemDebounce = false;
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