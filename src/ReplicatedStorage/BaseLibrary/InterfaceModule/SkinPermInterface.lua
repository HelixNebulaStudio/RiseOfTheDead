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
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRemotesManager = Debugger:Require(game.ReplicatedStorage.Library.RemotesManager);

local modItemInterface = require(game.ReplicatedStorage.Library.UI.ItemInterface);

local remoteUseStorageItem = modRemotesManager:Get("UseStorageItem");

local windowFrameTemplate = script:WaitForChild("SkinPerm");

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	local windowFrame = windowFrameTemplate:Clone();
	local slotFrame = windowFrame:WaitForChild("Slot");
	windowFrame.Parent = modInterface.MainInterface;
	
	local titleLabel = windowFrame:WaitForChild("TitleFrame"):WaitForChild("Title");
	local applyButton = windowFrame:WaitForChild("applyButton");
	
	windowFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		Interface:CloseWindow("SkinPerm");
	end)
	
	local selectItemButton = modItemInterface.newItemButton();
	local selectImgButton = selectItemButton.ImageButton;
	selectImgButton.Visible = false;
	selectImgButton.Parent = slotFrame;
	
	local defaultInterface, premiumInterface = Interface.modInventoryInterface.DefaultInterface, Interface.modInventoryInterface.PremiumInterface;
	local clothingInterface = Interface.modInventoryInterface.ClothingInterface;
	
	local skinPermItem, skinPermStorageId;
	local selectedItem;
	
	local function onItemSelect(interface, slot)
		if skinPermItem == nil then 
			selectImgButton.Visible = false;
			return 
		end;
		
		if selectedItem == nil or selectedItem.ID ~= (slot and slot.ID or 0) then
			Interface:PlayButtonClick();

			selectedItem = slot.Item;

			local skinPermItemLib = modItemsLibrary:Find(skinPermItem.ItemId);
			if skinPermItemLib.PatPerm == true and not modItemsLibrary:HasTag(selectedItem.ItemId, "Skinnable") then
				selectItemButton.DimOut = true;
				applyButton.BackgroundColor3 = Color3.fromRGB(81, 107, 79);
				
			elseif skinPermItemLib.PatPerm ~= true and selectedItem.ItemId ~= skinPermItemLib.TargetItemId then
				selectItemButton.DimOut = true;
				applyButton.BackgroundColor3 = Color3.fromRGB(81, 107, 79);
				
			else
				applyButton.BackgroundColor3 = Color3.fromRGB(54, 107, 51);
				selectItemButton.DimOut = false;
			end;

			selectItemButton:Update(selectedItem);
			selectImgButton.Visible = true;
			
		else
			selectedItem = nil;
			selectImgButton.Visible = false;
			
		end
	end
	
	local debounce = false;
	applyButton.MouseButton1Click:Connect(function()
		local skinPermItemLib = modItemsLibrary:Find(skinPermItem.ItemId);

		if skinPermItemLib.PatPerm == true and not modItemsLibrary:HasTag(selectedItem.ItemId, "Skinnable") then
			return;
		elseif skinPermItemLib.PatPerm ~= true and selectedItem.ItemId ~= skinPermItemLib.TargetItemId then
			return;
		end

		if debounce then return end;
		debounce = true;
		Interface:PlayButtonClick();
		
		applyButton.Text = "Applying Skin Permanent";
		local returnPacket = remoteUseStorageItem:InvokeServer(skinPermStorageId, skinPermItem.ID, {
			TargetStorageItem = selectedItem;
		})
		if returnPacket.Success then
			applyButton.Text = "Successfully Applied!"
			task.wait(0.5);
			Interface:CloseWindow("SkinPerm");
			
		else
			applyButton.Text = "Failed to apply"..(returnPacket.FailMsg and ": "..returnPacket.FailMsg or "");
			task.wait(2);
			applyButton.Text = "Apply Skin Permanent";
			
		end
		
		debounce = false;
	end)
	
	
	local window = Interface.NewWindow("SkinPerm", windowFrame);
	if modConfigurations.CompactInterface then
		windowFrame.AnchorPoint = Vector2.new(0, 0.5);
	end
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1, 0));
	window.OnWindowToggle:Connect(function(visible, storageItem)
		if visible then
			if storageItem == nil then
				Interface:CloseWindow("SkinPerm");
				return;
			end
			
			Interface:CloseWindow("Workbench", {DontCloseInventory=true;});
			skinPermItem = storageItem;
			Interface:OpenWindow("Inventory");

			local skinPermStorage = modData.GetStorageOfItem(skinPermItem.ID);
			skinPermStorageId = skinPermStorage.Id;
			
			local skinPermItemLib = modItemsLibrary:Find(skinPermItem.ItemId);
			
			if skinPermItemLib.PatPerm then
				titleLabel.Text = "Apply ".. skinPermItemLib.Name .." Permanent";

				for id, buttonTable in pairs(defaultInterface.Buttons) do
					if modItemsLibrary:HasTag(buttonTable.Item.ItemId, "Skinnable") then continue end;
					buttonTable.ItemButtonObject.DimOut = true;
					buttonTable.ItemButtonObject:Update(buttonTable.Item);
				end
				for id, buttonTable in pairs(premiumInterface.Buttons) do
					if modItemsLibrary:HasTag(buttonTable.Item.ItemId, "Skinnable") then continue end;
					buttonTable.ItemButtonObject.DimOut = true;
					buttonTable.ItemButtonObject:Update(buttonTable.Item);
				end

			else
				titleLabel.Text = "Apply ".. skinPermItemLib.SkinPerm .." Skin Permanent";

				for id, buttonTable in pairs(defaultInterface.Buttons) do
					if buttonTable.Item.ItemId == skinPermItemLib.TargetItemId then continue end;
					buttonTable.ItemButtonObject.DimOut = true;
					buttonTable.ItemButtonObject:Update(buttonTable.Item);
				end
				for id, buttonTable in pairs(premiumInterface.Buttons) do
					if buttonTable.Item.ItemId == skinPermItemLib.TargetItemId then continue end;
					buttonTable.ItemButtonObject.DimOut = true;
					buttonTable.ItemButtonObject:Update(buttonTable.Item);
				end
				
			end

			task.spawn(function()
				for a=0, 0.5, 0.1 do
					defaultInterface.OnItemButton1Click = onItemSelect;
					premiumInterface.OnItemButton1Click = onItemSelect;
					clothingInterface.OnItemButton1Click = onItemSelect;
					task.wait(0.1);
					if not window.Visible then break; end;
				end
			end)
			
		else
			selectedItem = nil;
			skinPermItem = nil;

			for id, buttonTable in pairs(defaultInterface.Buttons) do
				buttonTable.ItemButtonObject.DimOut = false;
				buttonTable.ItemButtonObject:Update(buttonTable.Item);
			end
			for id, buttonTable in pairs(premiumInterface.Buttons) do
				buttonTable.ItemButtonObject.DimOut = false;
				buttonTable.ItemButtonObject:Update(buttonTable.Item);
			end
			
			defaultInterface.OnItemButton1Click = Interface.modInventoryInterface.DefaultInterface.BeginDragItem;
			premiumInterface.OnItemButton1Click = Interface.modInventoryInterface.PremiumInterface.BeginDragItem;
			clothingInterface.OnItemButton1Click = Interface.modInventoryInterface.ClothingInterface.BeginDragItem;
			Interface:CloseWindow("Inventory");
			
		end
	end)

	window:AddCloseButton(windowFrame);
	--Interface.Garbage:Tag();
	
	return Interface;
end;

return Interface;