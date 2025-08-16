local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local localPlayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modClothingLibrary = shared.require(game.ReplicatedStorage.Library.ClothingLibrary);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local modStorageInterface = shared.require(game.ReplicatedStorage.Library.UI.StorageInterface);

local UI_GRADIENT_SEQUENCE = {
	ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
	ColorSequenceKeypoint.new(0.001, Color3.fromRGB(50, 50, 50)),
	ColorSequenceKeypoint.new(0.002, Color3.fromRGB(20, 20, 20)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
}

local interfacePackage = {
    Type = "Character";
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    local storageTitleTag;
    
	local remoteStorageService = modRemotesManager:Get("StorageService");
	local remoteUpgradeStorage = modRemotesManager:Get("UpgradeStorage");
	local remoteItemActionHandler = modRemotesManager:Get("ItemActionHandler");

    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	local interfaceScreenGui = interface.ScreenGui;
	
	local storageFrame;
	if modConfigurations.CompactInterface then
        storageFrame = script:WaitForChild("MobileStorage"):Clone();
    else
        storageFrame = script:WaitForChild("Storage"):Clone();
    end
    storageFrame.Parent = interfaceScreenGui;
    
	local storageList = storageFrame:WaitForChild("MainList");
	local slotTemplate = script:WaitForChild("Slot");
	local addSlotButton = script:WaitForChild("PurchaseSlot");
	local pageButton = script:WaitForChild("pageButton");
	local buttonsFrame = storageFrame:WaitForChild("ButtonsFrame");
	local gridLayout = storageList:WaitForChild("UIGridLayout");
    
	
    local window: InterfaceWindow = interface:NewWindow("ExternalStorage", storageFrame);
    window.DisableInteractables = true;
    window.CloseWithInteract = true;

    local binds = window.Binds;
    local openSettings = {
        StorageId = nil;
        SetVanitySiid = nil;
        Interactable = nil;
    };
    binds.OpenSettings = openSettings;
    
	if modConfigurations.CompactInterface then
        window.CompactFullscreen = true;
        
		storageTitleTag = storageFrame:WaitForChild("TitleFrame"):WaitForChild("Title");
		
		storageFrame.TitleFrame:WaitForChild("closeButton").MouseButton1Click:Connect(function()
            window:Close();
		end)
		
		gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right;

		local padding = Instance.new("UIPadding");
		padding.PaddingLeft = UDim.new(0, 15);
		padding.Parent = storageList;

		buttonsFrame.Size = UDim2.new(1, 0, 0, 40);

	else
		storageTitleTag = storageFrame:WaitForChild("Title");
        window:SetClosePosition(UDim2.new(0.5, 0, 1, 0), UDim2.new(0.5, 0, 0.5, 0));
	end

	local addSlotDebounce = tick();
	
	local function openStorage(storageId, page)
        if page == 1 then page = nil; end
        
        local storage = modData.RequestStorage{
            Action = "GetStorage";
            StorageId = storageId;
            StoragePage = page;
            InteractConfig = openSettings.Interactable.Config;
        };

        if storage then
            openSettings.StorageId = storage.Id;
        end

		return storage;
	end

	local firstload = true;
	local function refreshBoundarySize()
		if modConfigurations.CompactInterface then
            window.OpenPoint = UDim2.new(0.5, 0, 0, 0);
			return;
		end
		
		local total = 0;
		
		for _, obj in pairs(storageList:GetChildren()) do
			if obj:IsA("GuiObject") and obj.Visible then
				total = total +1;
			end
		end
		
		local viewPortX = camera.ViewportSize.X;
		local slots = total > 25 and 10 or 5;
		local xSize = (slots*65)+6;
		local finalXSize = xSize;
		
		finalXSize = math.clamp(xSize, 0, math.clamp(math.floor((viewPortX-350)/5)*5-6, 200, math.huge));
		
		storageFrame.AnchorPoint = Vector2.new(0.5, 0.5);

		local minXPos = 350+math.ceil(finalXSize/2);
		local newStorageX = math.max(minXPos, viewPortX*0.5)
		storageFrame.Position = UDim2.new(0, newStorageX, 0.5, 0);
		window.OpenPoint = UDim2.new(0, newStorageX, 0.5, 0);

		return finalXSize;
	end
	
	local function updateFrame()
		if not modConfigurations.CompactInterface then
			storageFrame.Size = UDim2.new(0, refreshBoundarySize(), 0, math.clamp(storageList.UIGridLayout.AbsoluteContentSize.Y + 41, 0, 360) + (buttonsFrame.Visible and 35 or 0));
		else
			storageList.CanvasSize = UDim2.new(0, 0, 0, storageList.UIGridLayout.AbsoluteContentSize.Y);
		end

		if not modConfigurations.CompactInterface then	
			local r = storageTitleTag.AbsoluteSize.Y/storageFrame.AbsoluteSize.Y;
			UI_GRADIENT_SEQUENCE[2] = ColorSequenceKeypoint.new(r-0.001, Color3.fromRGB(50, 50, 50));
			UI_GRADIENT_SEQUENCE[3] = ColorSequenceKeypoint.new(r, Color3.fromRGB(20, 20, 20));
			storageFrame.UIGradient.Color = ColorSequence.new(UI_GRADIENT_SEQUENCE);
		end
	end
	
    local activeStorageId = nil;
    local activeStorageInterface = nil;

    --MARK: OnUpdate
	window.OnUpdate:Connect(function(forceReload)
        if forceReload ~= true and activeStorageId == openSettings.StorageId and activeStorageInterface then
            activeStorageInterface:Update();
            Debugger:Warn(`Refresh storage: {activeStorageId}/{openSettings.StorageId}`);
            return;
        end

        activeStorageId = openSettings.StorageId;
        local storage = modData.GetStorage(activeStorageId);

		Debugger:Log("Opening storage:",activeStorageId,"(",storage and storage.Name or nil,")");
		
		local storageName = storage.Name or activeStorageId or "nil";
		storageTitleTag.Text = storageName;

		if storage.MaxPages and storage.MaxPages > 1 then
			storageName = storageName .. " [".. (storage.Page or "1") .."/".. storage.MaxPages .."]"
		end
		
		if activeStorageInterface then
            activeStorageInterface:Destroy();
        end;
		for _, c in pairs(storageList:GetChildren()) do
            if c:IsA("GuiObject") then 
                c:Destroy();
            end;
        end;
		
		local slotFrames = {};
		local yieldTick = tick(); 
        repeat until storage.Size or tick()-yieldTick >1 or not wait(1/60);

        if storage.Size == nil then
            Debugger:Warn(`Failed to load external storage: {activeStorageId}`);
            window:Close();
            return;
        end

        for a=1, 50 do --(storage.MaxSize or storage.Size)
            local slot = slotTemplate:Clone();
            slot:SetAttribute("Index", a);
            slot.LayoutOrder = a;
            slot.Parent = storageList;
            table.insert(slotFrames, slot);
        end
        
        activeStorageInterface = modStorageInterface.new(activeStorageId, storageFrame, slotFrames);
        
        function activeStorageInterface:DecorateSlot(index, slotTable)
            local slotFrame = slotTable.Frame;
            if index > storage.PremiumStorage or (storage.Page or 1) >= storage.PremiumPage then
                slotFrame.ImageColor3 = Color3.fromRGB(75, 50, 50);
            else
                slotFrame.ImageColor3 = Color3.fromRGB(50, 50, 50);
            end
        end
        

        --==MARK: AddSlot
        local newAddSlotButton = addSlotButton:Clone();
        newAddSlotButton.LayoutOrder = storage.Size+1;
        newAddSlotButton.Parent = storageList;

        local function enableAddSlotButton()
            newAddSlotButton.Visible = true;
            
            local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library.WorkbenchLibrary);
            local cost = modWorkbenchLibrary.StorageCost(storage.Id, storage.Size, storage.Page);
            newAddSlotButton.MouseButton1Click:Connect(function()
                if tick()-addSlotDebounce <= 0.1 then return end;
                addSlotDebounce = tick();
                
                cost = modWorkbenchLibrary.StorageCost(storage.Id, storage.Size, storage.Page);
                modClientGuis.promptDialogBox({
                    Title=`Purchase storage slot?`;
                    Desc=`Are you sure you want to purchase a storage slot for {cost} Perks?`;
                    Icon=`rbxassetid://3187395807`;
                    Buttons={
                        {
                            Text="Purchase";
                            Style="Confirm";
                            OnPrimaryClick=function(dialogWindow)
                                local statusLabel = dialogWindow.Binds.StatusLabel;
                                statusLabel.Text = "Purchasing<...>";

                                local r = remoteUpgradeStorage:InvokeServer(storage.Id);
                                if type(r) == "table" and r.Id then
                                    storage = modData.SetStorage(r);
                                    window:Update(true);

                                    statusLabel.Text = "Slot Purchased!";
                                    wait(0.5);
                                    
                                elseif r == 1 then
                                    statusLabel.Text = "Purchase Failed!";
                                    wait(2);
                                    
                                elseif r == 2 then
                                    statusLabel.Text = "Not enough Perks!";
                                    wait(1);
                                    window:Close();
                                    interface:ToggleWindow("GoldMenu", true, "PerksPage");
                                    return;
                                end
                            end;
                        };
                        {
                            Text="Cancel";
                            Style="Cancel";
                        };
                    }
                });
                
            end)
        end

        if storage.Expandable and storage.Size < storage.MaxSize then
            enableAddSlotButton();
        else
            newAddSlotButton.Visible = false;
        end
        --== AddSlot


        buttonsFrame.Visible = false;
        for _, obj in pairs(buttonsFrame:GetChildren()) do
            if obj.Name == "pageButton" then
                obj:Destroy();
            end
        end
        
        local storagePresetId = storage.PresetId;
        if storage.MaxPages and storage.MaxPages >= 1 then
            buttonsFrame.Visible = true;
            
            local isRentalEnabled = storage.Settings and storage.Settings.Rental > 0;
            
            for a=1, storage.MaxPages do
                local isOnButtonPage = a == (storage.Page or 1);
                local pageStorageId = a==1 and storagePresetId or `{storagePresetId}#p{a}`;

                local newButton = pageButton:Clone();
                newButton.Text = a;
                
                newButton.LayoutOrder = a;
                newButton.Parent = buttonsFrame;

                if modConfigurations.CompactInterface then
                    newButton.ZIndex = 4;
                end
                
                local pageStorage = modData.GetStorage(pageStorageId);
                if storage.Settings and storage.Settings.Rental > 0 then
                    if pageStorage then
                        local timeLeft = pageStorage.RentalUnlockTime - modSyncTime.GetTime();
                        local isLocked = timeLeft <= 0;
                        
                        if a == (storage.Page or 1) then
                            newButton.BackgroundColor3 = isLocked and Color3.fromRGB(105, 75, 143) or Color3.fromRGB(50, 50, 50);
                        else
                            newButton.BackgroundColor3 = isLocked and Color3.fromRGB(75, 64, 90) or Color3.fromRGB(100, 100, 100);
                        end
                        
                    else
                        newButton.BackgroundColor3 = Color3.fromRGB(75, 64, 90);

                    end
                else
                    local isPremiumPage = a >= (storage.PremiumPage or 10)
                    if isOnButtonPage then
                        if isPremiumPage then
                            newButton.BackgroundColor3 = Color3.fromRGB(160, 128, 53);
                        else
                            newButton.BackgroundColor3 = Color3.fromRGB(160, 160, 160);
                        end
                    else
                        if isPremiumPage then
                            newButton.BackgroundColor3 = Color3.fromRGB(100, 81, 33);
                        else
                            newButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100);
                        end
                    end

                end

                local onButtonClick;

                newButton.MouseButton1Click:Connect(function()
                    interface:PlayButtonClick();
                    local newStorageId = storagePresetId;
                    
                    if a ~= 1 then
                        newStorageId = `{storagePresetId}#p{a}`;
                    end
                    
                    if activeStorageId ~= newStorageId then
                        openStorage(newStorageId, a);
                        window:Update();

                        return;
                    end

                    if onButtonClick then
                        onButtonClick();
                    end
                end)

                if isRentalEnabled and isOnButtonPage then
                    local rentalPrice = storage.Settings.Rental;
                    
                    local function updateRental()
                        local storage = modData.Storages[activeStorageInterface.StorageId];
                        if storage.Settings == nil or storage.Settings.Rental <= 0 then
                            return;
                        end
                        
                        local itemCount = 0;
                        
                        for storageItemId, storageItem in pairs(storage.Container) do
                            itemCount = itemCount +1;
                        end
                        local rentCost = itemCount * rentalPrice;
                        
                        local timeLeft = storage.RentalUnlockTime - modSyncTime.GetTime();
                        if timeLeft > 0 then
                            storageTitleTag.Text = storageName..` (Unlock Time Left: {modSyncTime.ToString(timeLeft)})`;
                        end

                        local goldSuffix = modConfigurations.CompactInterface and "G" or " Gold";

                        if timeLeft <= 0 then
                            activeStorageInterface.ViewOnly = true;
                            newButton.Text = `Unlock {a} (<b><font color='rgb(170, 120, 0)'>{rentCost}{goldSuffix}</font></b>)`

                        else
                            activeStorageInterface.ViewOnly = false;
                            newButton.Text = `{a} (<b><font color='rgb(170, 120, 0)'>{rentCost}{goldSuffix}</font></b>)`;
                            
                        end
                        
                        for id, buttonTable in pairs(activeStorageInterface.Buttons) do
                            buttonTable.ItemButtonObject.DimOut = timeLeft <= 0 and 0.392157 or false;
                            buttonTable.ItemButtonObject:Update(buttonTable.Item);
                        end
                        
                        return itemCount, timeLeft;
                    end

                    activeStorageInterface:ConnectOnUpdate(updateRental);
                    
                    local function updateRentalJob()
                        if not window.Visible or activeStorageId == nil then 
                            return;
                        end;
                        local storage = modData.GetStorage(activeStorageId);
                        if a ~= (storage.Page or 1) then
                            return;
                        end;

                        updateRental();
                        interface.Scheduler:ScheduleFunction(updateRentalJob, tick()+1);
                    end
                    updateRentalJob();
                    
                    onButtonClick = function()
                        local itemCount, timeLeft = updateRental();
                        local rentCost = itemCount * rentalPrice;
                        
                        if timeLeft > 0 then return end;
                        
                        modClientGuis.promptDialogBox({
                            Title=`Rent Rat Storage for <b><font color='rgb(170, 120, 0)'>{rentCost} Gold</font></b>?`;
                            Desc=`Unlock rat storage for 24 hours, <b><font color='rgb(170, 120, 0)'>{rentalPrice} Gold per slot used</font></b>.\n\n<b>Important: Your items will be inaccessible after 24 hours and it will cost gold to re-unlock the storage.</b>`;
                            Buttons={
                                {
                                    Text="Rent";
                                    Color=Color3.fromRGB(105, 75, 143);
                                    OnPrimaryClick=function(dialogWindow)
                                        local statusLabel = dialogWindow.Binds.StatusLabel;
                                        statusLabel.Text = "Unlocking<...>";
                                        
                                        local returnPacket = remoteStorageService:InvokeServer({Action="Rental"; StorageId=storage.Id; Request=true;});
                                        if returnPacket.Success then
                                            if returnPacket.Storages then
                                                for sId, _ in pairs(returnPacket.Storages) do
                                                    modData.SetStorage(returnPacket.Storages[sId]);
                                                end
                                            end
                                            
                                            task.wait(0.5);

                                            openSettings.StorageId = pageStorageId;
                                            window:Update(true);
                                            
                                        else
                                            statusLabel.Text = "Insufficient Gold.";

                                            task.wait(2);
                                            window:Close();
                                            interface:ToggleWindow("GoldMenu", true, "GoldPage");
                                            return;
                                            
                                        end

                                        activeStorageInterface:Update();
                                        
                                    end;
                                };
                                {
                                    Text="Cancel";
                                    Style="Cancel";
                                };
                            }
                        });
                    end

                end
            end
        end
        
        refreshBoundarySize();
        if firstload then
            firstload = false;
            task.delay(0.31, refreshBoundarySize);
        end
        
        if openSettings.SetVanitySiid then
            storageTitleTag.Text = "Set Vanity Clothing";
            
            local storageItemA = modData.GetItemById(openSettings.SetVanitySiid)
            local clothingLibA = modClothingLibrary:Find(storageItemA.ItemId);
            
            for id, buttonTable in pairs(activeStorageInterface.Buttons) do
                local clothingLibB = modClothingLibrary:Find(buttonTable.Item.ItemId);
                
                local canSetVanity = true;

                if clothingLibB.CanVanity == false then 
                    canSetVanity = false;
                end;
                if clothingLibA.GroupName ~= clothingLibB.GroupName and clothingLibB.UniversalVanity ~= true then
                    canSetVanity = false;
                end
                
                buttonTable.ItemButtonObject.HideTypeIcon = true;
                buttonTable.ItemButtonObject.HideFavIcon = true;
                buttonTable.ItemButtonObject.HideAttachmentIcons = true;
                buttonTable.ItemButtonObject.DimOut = not canSetVanity;
                buttonTable.ItemButtonObject:Update(buttonTable.Item);
            end

            activeStorageInterface.OnItemButton1Click = function(interface, slot)
                local slotId = (slot and slot.ID or 0);
                
                if slot.ItemButtonObject.DimOut ~= true then
                    remoteItemActionHandler:FireServer(activeStorageId, slotId, "setvanity", openSettings.SetVanitySiid);
                    window:Close();
                end
            end
            
        else
            modStorageInterface.SetQuickTarget(activeStorageInterface);

        end
        
        updateFrame();
        activeStorageInterface:Update(nil, nil, true);
	end)

	storageList.UIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() --not crash
		updateFrame();

	end)

	storageFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if not storageFrame.Visible then
			if activeStorageInterface then
				activeStorageInterface:ToggleDescriptionFrame(false, nil, 0.3);
			end
		end
	end)

	local debounce = false;
	storageFrame.InputChanged:Connect(function(inputObject, gameProcessedEvent)
		if inputObject.UserInputType == Enum.UserInputType.MouseWheel then
			if debounce then return end;
			debounce = true;
			
			if buttonsFrame.Visible then
				local dir = -inputObject.Position.Z;
				local storage = modData.GetStorage(openSettings.StorageId);
				if storage then
					local page = storage.Page;
					local maxPages = storage.MaxPages;
                    local storagePresetId = storage.PresetId;
					
					if maxPages == nil then return end;
					
					local newStorageId = storagePresetId;
					local a = page or 1;
					if dir < 0 then
						a = math.clamp(a -1, 1, maxPages);
					elseif dir > 0 then
						a = math.clamp(a +1, 1, maxPages);
					end
					
                    if a ~= 1 then
                        newStorageId = `{storagePresetId}#p{a}`;
                    else
                        newStorageId = storagePresetId;
                    end
                    
                    if activeStorageId ~= newStorageId then
						openStorage(newStorageId, a);
					end
					window:Update();
						
				end
			end
			debounce = false;
		end
	end)
	
	refreshBoundarySize();
    --MARK: OnToggle
	window.OnToggle:Connect(function(visible, storageId, packet)
		if visible then
            modTables.ReplaceValues(openSettings, packet);
            
            openSettings.StorageId = storageId;

            local storage = modData.GetStorage(storageId);
			if openSettings.SetVanitySiid then
				local function cancelWardrobe()
					window:Close();
				end
                
                for a=#interface.StorageInterfaces, 1, -1 do
                    local storageInterface: StorageInterface = interface.StorageInterfaces[a];
                    if storageInterface == nil then continue end;
                    if storageInterface.StorageId ~= "Inventory" and storageInterface.StorageId ~= "Clothing" then
                        continue;
                    end
                    storageInterface.OnItemButton1Click = cancelWardrobe;
                end
			end
			
			interface:HideAll{[window.Name]=true; ["Inventory"]=true;};
            interface:ToggleWindow("Inventory", true);
            
			window:Update(true);
			refreshBoundarySize();

			spawn(function()
				if storageId == "Wardrobe" then
					if openSettings.SetVanitySiid then return end;
					return;
				end
				if storage and storage.Virtual then return end;
				repeat until not window.Visible
                    or openSettings.Interactable == nil
                    or openSettings.Interactable.Part == nil
					or localPlayer:DistanceFromCharacter(openSettings.Interactable.Part.Position) >= 16
					or not wait(0.1);
				window:Close();
			end)
			
		else
            table.clear(openSettings);
            openSettings.Interactable = nil;

			for a=#interface.StorageInterfaces, 1, -1 do
				local storageInterface: StorageInterface = interface.StorageInterfaces[a];
			    if storageInterface == nil then continue end;
				if storageInterface == nil or storageInterface.StorageId ~= "Inventory" 
                and storageInterface.StorageId ~= "Clothing" then
					continue;
				end
				storageInterface.OnItemButton1Click = storageInterface.BeginDragItem;
			end

			modStorageInterface.SetQuickTarget();
            interface:ToggleWindow("Inventory", false);
			
			task.spawn(function()
				local _rPacket = remoteStorageService:InvokeServer({
					Action="CloseStorage";
					StorageId=storageId;
				});
			end)
		end
	end)
	
end

return interfacePackage;

