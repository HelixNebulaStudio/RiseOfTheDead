local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));
    local remoteUseStorageItem = modRemotesManager:Get("UseStorageItem");

    
	local windowFrame = script:WaitForChild("SkinPerm"):Clone();
	local slotFrame = windowFrame:WaitForChild("Slot");
	windowFrame.Parent = interface.ScreenGui;
	
	local window: InterfaceWindow = interface:NewWindow("SkinPerm", windowFrame);
    window.CloseWithInteract = true;
    
	if modConfigurations.CompactInterface then
		windowFrame.AnchorPoint = Vector2.new(0, 0.5);
	end
	window:SetClosePosition(UDim2.new(0.5, 0, -1, 0), UDim2.new(0.5, 0, 0.5, 0));

    local binds = window.Binds;

	local titleLabel = windowFrame:WaitForChild("TitleFrame"):WaitForChild("Title");
	local applyButton = windowFrame:WaitForChild("applyButton");
	
	windowFrame:WaitForChild("TitleFrame"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		window:Close();
	end)
	
	local selectItemButton = modItemInterface.newItemButton();
	local selectImgButton = selectItemButton.ImageButton;
	selectImgButton.Visible = false;
	selectImgButton.Parent = slotFrame;
	
    
	local skinPermItem, skinPermStorageId;
	local activeStorageItem;
	
	function binds.onItemSelect(interface, slot)
		if skinPermItem == nil then 
			selectImgButton.Visible = false;
			return 
		end;
		
		if activeStorageItem == nil or activeStorageItem.ID ~= (slot and slot.ID or 0) then
			interface:PlayButtonClick();

			activeStorageItem = slot.Item;

			local skinPermItemLib = modItemsLibrary:Find(skinPermItem.ItemId);
			if skinPermItemLib.PatPerm == true and not modItemsLibrary:HasTag(activeStorageItem.ItemId, "Skinnable") then
				selectItemButton.DimOut = true;
				applyButton.BackgroundColor3 = Color3.fromRGB(81, 107, 79);
				
			elseif skinPermItemLib.PatPerm ~= true and activeStorageItem.ItemId ~= skinPermItemLib.TargetItemId then
				selectItemButton.DimOut = true;
				applyButton.BackgroundColor3 = Color3.fromRGB(81, 107, 79);
				
			else
				applyButton.BackgroundColor3 = Color3.fromRGB(54, 107, 51);
				selectItemButton.DimOut = false;
			end;

			selectItemButton:Update(activeStorageItem);
			selectImgButton.Visible = true;
			
		else
			activeStorageItem = nil;
			selectImgButton.Visible = false;
			
		end
	end
	

	local debounce = false;
	applyButton.MouseButton1Click:Connect(function()
		if activeStorageItem == nil then return end;
		local skinPermItemLib = modItemsLibrary:Find(skinPermItem.ItemId);

		if skinPermItemLib.PatPerm == true and not modItemsLibrary:HasTag(activeStorageItem.ItemId, "Skinnable") then
			return;
		elseif skinPermItemLib.PatPerm ~= true and activeStorageItem.ItemId ~= skinPermItemLib.TargetItemId then
			return;
		end

		if debounce then return end;
		debounce = true;
		interface:PlayButtonClick();
		
		applyButton.Text = "Applying Skin Permanent";
		local returnPacket = remoteUseStorageItem:InvokeServer(skinPermStorageId, skinPermItem.ID, {
			TargetStorageItem = activeStorageItem;
		})
		if returnPacket.Success then
			applyButton.Text = "Successfully Applied!"
			task.wait(0.5);
            window:Close();
			
		else
			applyButton.Text = "Failed to apply"..(returnPacket.FailMsg and ": "..returnPacket.FailMsg or "");
			task.wait(2);
			applyButton.Text = "Apply Skin Permanent";
			
		end
		
		debounce = false;
	end)
	

	--MARK: OnToggle
	window.OnToggle:Connect(function(visible, storageItem)
		if visible then
			if storageItem == nil then
                window:Close();
				return;
			end
			
            interface:ToggleWindow("Workbench", true, {DontCloseInventory=true;});
            interface:ToggleWindow("Inventory", true);
			skinPermItem = storageItem;

			selectImgButton.Visible = false;
			
			local skinPermStorage = modData.GetStorageOfItem(skinPermItem.ID);
			skinPermStorageId = skinPermStorage.Id;
			
			local skinPermItemLib = modItemsLibrary:Find(skinPermItem.ItemId);
			
			for a=1, #interface.StorageInterfaces do
				local storageInterface: StorageInterface = interface.StorageInterfaces[a];
				if storageInterface.StorageId ~= "Inventory" and storageInterface.StorageId ~= "Clothing" then
					continue;
				end
				storageInterface.OnItemButton1Click = binds.onItemSelect;

                if skinPermItemLib.PatPerm then
                    titleLabel.Text = "Apply ".. skinPermItemLib.Name .." Permanent";

                    for id, buttonTable in pairs(storageInterface.Buttons) do
                        if modItemsLibrary:HasTag(buttonTable.Item.ItemId, "Skinnable") then continue end;
                        buttonTable.ItemButtonObject.DimOut = true;
                        buttonTable.ItemButtonObject:Update(buttonTable.Item);
                    end

                else
                    titleLabel.Text = "Apply ".. skinPermItemLib.SkinPerm .." Skin Permanent";

                    for id, buttonTable in pairs(storageInterface.Buttons) do
                        if buttonTable.Item.ItemId == skinPermItemLib.TargetItemId then continue end;
                        buttonTable.ItemButtonObject.DimOut = true;
                        buttonTable.ItemButtonObject:Update(buttonTable.Item);
                    end
                    
                end
			end

		else
			activeStorageItem = nil;
			skinPermItem = nil;

			for a=#interface.StorageInterfaces, 1, -1 do
				local storageInterface: StorageInterface = interface.StorageInterfaces[a];
				if storageInterface == nil then continue end;
				if storageInterface.StorageId ~= "Inventory" and storageInterface.StorageId ~= "Clothing" then
					continue;
				end
				storageInterface.OnItemButton1Click = storageInterface.BeginDragItem;

                for id, buttonTable in pairs(storageInterface.Buttons) do
                    buttonTable.ItemButtonObject.DimOut = false;
                    buttonTable.ItemButtonObject:Update(buttonTable.Item);
                end
			end

            interface:ToggleWindow("Inventory", false);
			
		end
	end)

end

return interfacePackage;

