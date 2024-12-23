local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;
local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modShopLibrary = require(game.ReplicatedStorage.Library.RatShopLibrary);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local remoteShopService = modRemotesManager:Get("ShopService");
	
local windowFrameTemplate = script:WaitForChild("SupplyStation");

local branchColor = modBranchConfigs.BranchColor;
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	local selectedItem, storageId;
	local openStorageItem;
	
	local windowFrame = windowFrameTemplate:Clone();
	windowFrame.Parent = modInterface.MainInterface;
	
	local titleLabel = windowFrame:WaitForChild("Title");
	local mainLabel = windowFrame:WaitForChild("label");
	local resupplyButton = windowFrame:WaitForChild("resupplyButton");
	
	
	local defaultInterface, premiumInterface = Interface.modInventoryInterface.DefaultInterface, Interface.modInventoryInterface.PremiumInterface;
	local clothingInterface = Interface.modInventoryInterface.ClothingInterface;

	local defaultText = resupplyButton.buttonText.Text;

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
	
	local window = Interface.NewWindow("SupplyStation", windowFrame);
	if modConfigurations.CompactInterface then
		windowFrame.AnchorPoint = Vector2.new(0, 0.5);
	end
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1, 0));
	window.OnWindowToggle:Connect(function(visible, storageItem)
		if visible then
			openStorageItem = storageItem;
			Interface:HideAll{[window.Name]=true; ["Inventory"]=true;};

			local function onSelectionChange()
				resupplyButton.Visible = false;
				mainLabel.Text = "Select a weapon you want to refill from your inventory.";
				if selectedItem == nil then return end;
				
				local patStorageId = "portableautoturret";
				if selectedItem.ItemId == patStorageId then
					selectedItem = modData.FindIndexFromStorage(patStorageId, 1);
					storageId = patStorageId;
				end
				
				local selectItemId = selectedItem.ItemId;
				local itemLib = modItemsLibrary:Find(selectItemId);
				local itemClass, classType = modData:GetItemClass(selectedItem.ID);
				modData.OnAmmoUpdate:Fire(selectedItem.ID);
		
				if openStorageItem and openStorageItem.ID == selectedItem.ID then
					mainLabel.Text = `You can't refill an ammo pouch from an ammo pouch..`;

				elseif classType == "Weapon" then
					if selectedItem.Values.A == nil and selectedItem.Values.MA == nil then
						mainLabel.Text = `This weapon is fully refilled.`;

					elseif itemClass and ((selectedItem.Values.A and selectedItem.Values.A < itemClass.Configurations.AmmoLimit)
						or (selectedItem.Values.MA and selectedItem.Values.MA < itemClass.Configurations.MaxAmmoLimit)) then
			
						local ammoCurrency = modShopLibrary.AmmunitionCurrency or "Money";
						local localplayerStats = modData.GetStats();
						local localplayerCurrency = localplayerStats and localplayerStats[ammoCurrency] or 0;
						local price, mags = modShopLibrary.CalculateAmmoPrice(selectedItem.ItemId, selectedItem.Values, itemClass.Configurations, localplayerCurrency, modData.Profile.Punishment == modGlobalVars.Punishments.AmmoCostPenalty);
						
						resupplyButton.buttonText.Text = price > 0 
							and "Buy "..mags.." magazine"..(mags > 1 and "s" or "").." for "..(ammoCurrency == "Money" and "$"..price or price.." "..ammoCurrency) 
							or "Refill ammo";
						resupplyButton.Visible = true;
						mainLabel.Text = ("Do you want to refill your $itemName?"):gsub("$itemName", itemLib.Name);
					end
				
				else
					if selectItemId == "ammopouch" then
						if selectedItem.Values.C == nil then
							mainLabel.Text = `This ammo pouch has full charge.`;

						elseif selectedItem.Values.C then -- and selectedItem.Values.C < itemClass.Configurations.BaseRefillCharge
							mainLabel.Text = `Do you want to refill {itemClass.Configurations.BaseRefillCharge} ammo pouch charges?`;
							resupplyButton.buttonText.Text = `Refill`;
							resupplyButton.Visible = true;
							
						end
					end
		
				end

				defaultText = resupplyButton.buttonText.Text;
			end
			
			
			local function onItemSelect(storageInterface, slot)
				if selectedItem == nil or selectedItem.ID ~= (slot and slot.ID or 0) then
					clearSlotHighlight(slot);
					Interface:PlayButtonClick();
		
					slot.Button.BackgroundTransparency = 0.3;
					slot.Button.BackgroundColor3 = branchColor;
					
					storageId = storageInterface.StorageId;
					selectedItem = slot.Item;
					onSelectionChange();
				else
					clearSlotHighlight();
					selectedItem = nil;
					onSelectionChange();
				end
			end

			defaultInterface.OnItemButton1Click = onItemSelect;
			premiumInterface.OnItemButton1Click = onItemSelect;
			clothingInterface.OnItemButton1Click = onItemSelect;

			if openStorageItem and openStorageItem.ItemId == "ammopouch" then
				titleLabel.Text = `Ammo Pouch`;
			else
				titleLabel.Text = `Supply Station`;
			end

			Interface:ToggleInteraction(false);
			Interface:OpenWindow("Inventory");
			spawn(function()
				if openStorageItem then return end;
				repeat until not window.Visible or Interface.Object == nil or not Interface.Object:IsDescendantOf(workspace) or Interface.modCharacter.Player:DistanceFromCharacter(Interface.Object.Position) >= 16 or not wait(0.5);
				Interface:ToggleWindow("Inventory", false);
			end)
		else
			clearSlotHighlight();
			selectedItem = nil;
			defaultInterface.OnItemButton1Click = Interface.modInventoryInterface.DefaultInterface.BeginDragItem;
			premiumInterface.OnItemButton1Click = Interface.modInventoryInterface.PremiumInterface.BeginDragItem;
			clothingInterface.OnItemButton1Click = Interface.modInventoryInterface.ClothingInterface.BeginDragItem;
			Interface:CloseWindow("Inventory");
			task.delay(0.3, function()
				Interface:ToggleInteraction(true);
			end)
		end
	end)

	window:AddCloseButton(windowFrame);

	local purchaseAmmoDebounce = false;
	resupplyButton.MouseButton1Click:Connect(function()
		if purchaseAmmoDebounce then return end;
		purchaseAmmoDebounce = true;
		Interface:PlayButtonClick();
		if selectedItem then
			local selectItemId = selectedItem.ItemId;
			local itemLib = modItemsLibrary:Find(selectItemId);

			local itemClass, classType = modData:GetItemClass(selectedItem.ID);

			if openStorageItem and openStorageItem.ID == selectedItem.ID then

			elseif classType == "Weapon" then
				local ammoCurrency = modShopLibrary.AmmunitionCurrency or "Money";
				local localplayerStats = modData.GetStats();
				local localplayerCurrency = localplayerStats and localplayerStats[ammoCurrency] or 0;
				local price = modShopLibrary.CalculateAmmoPrice(selectItemId, selectedItem.Values, itemClass.Configurations, localplayerCurrency, modData.Profile.Punishment == modGlobalVars.Punishments.AmmoCostPenalty);
				
				resupplyButton.buttonText.Text = "Purchasing...";
				local serverReply = modShopLibrary.PurchaseReplies.InsufficientCurrency;
				if localplayerStats and (localplayerStats[ammoCurrency] or 0) >= price then
					serverReply = remoteShopService:InvokeServer("buyammo", {StoreObj=Interface.Object; AmmoPouch=(openStorageItem and openStorageItem.ID or nil)}, selectedItem.ID, storageId);
				end
				resupplyButton.buttonText.Text = defaultText;
				
				if serverReply == modShopLibrary.PurchaseReplies.Success then
					resupplyButton.Visible = false;
	
				elseif serverReply == modShopLibrary.PurchaseReplies.ExhaustedUses then
					if openStorageItem then
						resupplyButton.buttonText.Text = `Ammo pouch is out of charges.`;
					else
						resupplyButton.buttonText.Text = "You've used up this ammo box.";
					end
					wait(1);
	
				else
					warn("Ammunition Purchase>> Error Code:"..serverReply);
					resupplyButton.buttonText.Text = (modShopLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply)):gsub("$Currency", "Money");
					wait(1);
				end

			else
				if selectItemId == "ammopouch" then
					resupplyButton.buttonText.Text = "Refilling...";
					local serverReply = remoteShopService:InvokeServer("refillcharges", Interface.Object, selectedItem.ID, storageId);

					if serverReply == modShopLibrary.PurchaseReplies.Success then
						resupplyButton.Visible = false;
		
					else
						warn("Ammunition Purchase>> Error Code:"..serverReply);
						resupplyButton.buttonText.Text = (modShopLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply)):gsub("$Currency", "Money");
						wait(1);
					end

				end

			end
		end
		purchaseAmmoDebounce = false;
	end)
	
	return Interface;
end;

return Interface;