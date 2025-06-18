local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modShopLibrary = shared.require(game.ReplicatedStorage.Library.RatShopLibrary);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));
    local remoteShopService = modRemotesManager:Get("ShopService");
    local branchColor = modBranchConfigs.BranchColor;

	local mainFrame = script:WaitForChild("ResupplyStation"):Clone();
	mainFrame.Parent = interface.ScreenGui;

	local titleLabel = mainFrame:WaitForChild("Title");
	local mainLabel = mainFrame:WaitForChild("label");
	local resupplyButton = mainFrame:WaitForChild("resupplyButton");
	local defaultText = resupplyButton.buttonText.Text;
	
    
	local window: InterfaceWindow = interface:NewWindow("ResupplyStation", mainFrame);
    window.DisableInteractables = true;
    window.CloseWithInteract = true;
	if modConfigurations.CompactInterface then
		mainFrame.AnchorPoint = Vector2.new(0, 0.5);
	end
	window:SetClosePosition(UDim2.new(0.5, 0, -1, 0), UDim2.new(0.5, 0, 0.5, 0));

    mainFrame:WaitForChild("Title"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
        window:Close();
    end)

    local binds = window.Binds;
    binds.Interactable = nil;
    binds.StorageId = nil;
    binds.SupplyStorageItem = nil;
    binds.SelectStorageItem = nil;
    binds.ResupplyButtonClick = nil;


    function binds.selectionChange()
        resupplyButton.Visible = false;
        mainLabel.Text = "Select a weapon you want to refill from your inventory.";
        binds.ResupplyButtonClick = nil;

        local selectedItem: StorageItem = binds.SelectStorageItem;
        if selectedItem == nil then return end;
        
        local patStorageId = "portableautoturret";
        if selectedItem.ItemId == patStorageId then
            selectedItem = modData.FindIndexFromStorage(patStorageId, 1);
            binds.StorageId = patStorageId;
        end
        
        local selectItemId = selectedItem.ItemId;
        local itemLib = modItemsLibrary:Find(selectItemId);

        local localplayerStats = modData.GetStats();
        local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
        local equipmentClass: EquipmentClass = playerClass.WieldComp:GetEquipmentClass(selectedItem.ID, selectItemId, selectedItem);

        if equipmentClass == nil then return end;
        local configurations = equipmentClass.Configurations;

        if binds.SupplyStorageItem and binds.SupplyStorageItem.ID == selectedItem.ID then
            mainLabel.Text = `You can't refill an ammo pouch from an ammo pouch..`;

        elseif equipmentClass.Class == "Gun" then
            local ammo = selectedItem:GetValues("A") or configurations.MagazineSize;
            local maxAmmo = selectedItem:GetValues("MA") or configurations.AmmoCapacity;

            local ammoIsNotFull = (ammo < configurations.MagazineSize)
                                or (maxAmmo < configurations.AmmoCapacity);

            if ammoIsNotFull then
                local ammoCurrency = modShopLibrary.AmmunitionCurrency or "Money";
                local localplayerCurrency = localplayerStats[ammoCurrency] or 0;
                local price, mags = modShopLibrary.CalculateAmmoPrice(
                    selectedItem.ItemId, 
                    selectedItem.Values, 
                    configurations, 
                    localplayerCurrency, 
                    modData.Profile.Punishment == modGlobalVars.Punishments.AmmoCostPenalty
                );

                local refillStr = `Refill ammo`;
                if price > 0 then
                    refillStr = `Buy {mags} magazine{mags > 1 and "s" or ""} for `;
                    refillStr = refillStr..(ammoCurrency == "Money" and `${price}` or `{price} {ammoCurrency}`);
                end
                resupplyButton.buttonText.Text = refillStr;
                resupplyButton.Visible = true;
                mainLabel.Text = `Do you want to refill your {itemLib.Name}?`;

                --MARK: Click Refill
                binds.ResupplyButtonClick = function()
                    resupplyButton.buttonText.Text = "Purchasing Ammo...";
                    local serverReply = modShopLibrary.PurchaseReplies.InsufficientCurrency;

                    if (localplayerCurrency or 0) >= price then
                        serverReply = remoteShopService:InvokeServer("buyammo", {
                            InteractConfig = binds.Interactable and binds.Interactable.Config;
                            AmmoPouchSiid = binds.SupplyStorageItem and binds.SupplyStorageItem.ID or nil;

                            Siid = selectedItem.ID;
                            StorageId = binds.StorageId;
                        });
                    end
                    resupplyButton.buttonText.Text = defaultText;
                    
                    if serverReply == modShopLibrary.PurchaseReplies.Success then
                        equipmentClass.ClassSelf:RefillAmmo(equipmentClass, selectedItem);
                        resupplyButton.Visible = false;

                    elseif serverReply == modShopLibrary.PurchaseReplies.ExhaustedUses then
                        if selectedItem then
                            resupplyButton.buttonText.Text = `Ammo pouch is out of charges.`;
                        else
                            resupplyButton.buttonText.Text = "You've used up this ammo box.";
                        end
                        task.wait(1);

                    else
                        warn("Ammunition Purchase>> Error Code:"..serverReply);
                        resupplyButton.buttonText.Text = (modShopLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply)):gsub("$Currency", "Money");
                        task.wait(1);
                    end
                end
                
            else
                mainLabel.Text = `This weapon is fully refilled.`;

            end

        else
            if selectItemId == "ammopouch" then
                local ammoPouchData = modData:GetEvent("AmmoPouchData");
                local charges = ammoPouchData and ammoPouchData.Charges or configurations.BaseRefillCharge;

                if charges >= configurations.BaseRefillCharge then
                    mainLabel.Text = `This ammo pouch has full charge.`;

                else
                    mainLabel.Text = `Do you want to refill {configurations.BaseRefillCharge} ammo pouch charges?`;
                    resupplyButton.buttonText.Text = `Refill`;
                    resupplyButton.Visible = true;
                    
                    --MARK: Click Refill
                    binds.ResupplyButtonClick = function()
                        resupplyButton.buttonText.Text = "Refilling...";
                        local serverReply = remoteShopService:InvokeServer(
                            "refillcharges", 
                            binds.InteractPart, 
                            selectedItem.ID, 
                            binds.StorageId
                        );

                        if serverReply == modShopLibrary.PurchaseReplies.Success then
                            resupplyButton.Visible = false;
            
                        else
                            warn("Ammunition Purchase>> Error Code:"..serverReply);
                            resupplyButton.buttonText.Text = (modShopLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply)):gsub("$Currency", "Money");
                            task.wait(1);
                        end

                    end
                end
            end
        end

        defaultText = resupplyButton.buttonText.Text;
    end

    function binds.onItemSelect(storageInterface, slot)
        
        if binds.SelectStorageItem == nil or binds.SelectStorageItem.ID ~= (slot and slot.ID or 0) then
            binds.clearSlotHighlight(slot);
            interface:PlayButtonClick();

            slot.Button.BackgroundTransparency = 0.3;
            slot.Button.BackgroundColor3 = branchColor;
            
            binds.StorageId = storageInterface.StorageId;
            binds.SelectStorageItem = slot.Item;
            binds.selectionChange();
        else
            binds.clearSlotHighlight();
            binds.SelectStorageItem = nil;
            binds.selectionChange();
        end
    end

	function binds.clearSlotHighlight(slot)
        binds.ResupplyButtonClick = nil;

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

        mainLabel.Text = `Select a weapon you want to refill from your inventory.`;
	end


    --MARK: OnToggle
	window.OnToggle:Connect(function(visible, interactable, info, supplierStorageItem)
        if interactable then
            binds.Interactable = interactable;
        end
        if supplierStorageItem then
            binds.SupplyStorageItem = supplierStorageItem;
        end

		if visible then
			interface:HideAll{[window.Name]=true; ["Inventory"]=true;};
            interface:ToggleWindow("Inventory", true);
            
			for a=1, #interface.StorageInterfaces do
				local storageInterface: StorageInterface = interface.StorageInterfaces[a];
				if storageInterface.StorageId ~= "Inventory" and storageInterface.StorageId ~= "Clothing" then
					continue;
				end
				storageInterface.OnItemButton1Click = binds.onItemSelect;
			end

			if binds.SupplyStorageItem and binds.SupplyStorageItem.ItemId == "ammopouch" then
				titleLabel.Text = `Ammo Pouch`;
			else
				titleLabel.Text = `Supply Station`;
			end

            task.spawn(function()
				if binds.SupplyStorageItem then return end;

                repeat until not window.Visible 
                or binds.Interactable == nil or binds.Interactable.Part == nil 
                or not workspace:IsAncestorOf(binds.Interactable.Part)
                or localPlayer:DistanceFromCharacter(binds.Interactable.Part.Position) >= 16 
                or not wait(0.5);

                window:Close();
                interface:ToggleWindow("Inventory", false);
            end)

		else
            binds.clearSlotHighlight();
            
			binds.SelectStorageItem = nil;
            binds.SupplyStorageItem = nil;
            binds.StorageId = nil;

			for a=#interface.StorageInterfaces, 1, -1 do
				local storageInterface: StorageInterface = interface.StorageInterfaces[a];
				if storageInterface == nil then continue end;
				if storageInterface.StorageId ~= "Inventory" and storageInterface.StorageId ~= "Clothing" then
					continue;
				end
				storageInterface.OnItemButton1Click = storageInterface.BeginDragItem;
			end

            interface:ToggleWindow("Inventory", false);
		end
	end)


	local purchaseAmmoDebounce = false;
	resupplyButton.MouseButton1Click:Connect(function()
		if purchaseAmmoDebounce then return end;
		purchaseAmmoDebounce = true;

		interface:PlayButtonClick();

        if binds.SelectStorageItem == nil then 
            purchaseAmmoDebounce = false; 
            return;
        end;

        binds.selectionChange();
        if binds.ResupplyButtonClick then
            binds.ResupplyButtonClick();
        end
        binds.selectionChange();

		purchaseAmmoDebounce = false;
	end)
	
end

return interfacePackage;

