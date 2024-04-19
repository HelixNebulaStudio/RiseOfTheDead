local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local StorageInterface = {};
StorageInterface.__index = StorageInterface;

local TweenService = game:GetService("TweenService");
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");

local player = game.Players.LocalPlayer;
local playerGui = player:WaitForChild("PlayerGui");
local camera = workspace.CurrentCamera;
local modData = require(player:WaitForChild("DataModule"));

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modItem = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library.WorkbenchLibrary);
local modShopLibrary = require(game.ReplicatedStorage.Library.RatShopLibrary);
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modUsableItems = require(game.ReplicatedStorage.Library.UsableItems);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modBranchConfigurations = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modStorageItem = require(game.ReplicatedStorage.Library.StorageItem);

local modItemInterface = require(game.ReplicatedStorage.Library.UI:WaitForChild("ItemInterface"));
local modComponents = require(game.ReplicatedStorage.Library.UI.Components);

local quantityFrame = script:WaitForChild("QuantityFrame");
local optionFrame = script:WaitForChild("OptionsFrame");
local attachmentIcon = script:WaitForChild("AttachmentIcon");
local favIcon = script:WaitForChild("FavIcon");
local templateItemBar = script:WaitForChild("itemBar");
local templateContextOption = script:WaitForChild("TemplateOption");


local remoteCombine = modRemotesManager:Get("StorageCombine");
local remoteRemoveItem = modRemotesManager:Get("StorageRemoveItem");
local remoteSetSlot = modRemotesManager:Get("StorageSetSlot");
local remoteSplit = modRemotesManager:Get("StorageSplit");
local remoteSwapSlot = modRemotesManager:Get("StorageSwapSlot");
local remoteStorageItemSync = modRemotesManager:Get("StorageItemSync");

local currentOptionFrame = nil;
local currentQuanFrame = nil;
local mouseInOptionFrame = tick()-1;

local optionsListeners = {};

local CurrentDragging = nil;
local lastDraged = nil;
local lastDraggingTick = tick()-1;

local itemActionDebounce = false;

local CurrentSlot = nil;

StorageInterface.Button1Down = false;
StorageInterface.PrimaryInputDown = false;
StorageInterface.LeftShiftDown = false;

StorageInterface.IsPremium = false;
local dropDraggingHook;

local quickTargetInterface = nil;
local itemViewportObject

local templateHighlighGradient = script:WaitForChild("UIGradient");
local color = {
	ColorSequenceKeypoint.new(0, modBranchConfigurations.CurrentBranch.Color),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40))
};
templateHighlighGradient.Color = ColorSequence.new(color);

local clickDebounce;
--== Script;

local function getPromptPosition(targetParPos, targetPos, frameSize)
	local padding = 5;
	local vpSize = camera.ViewportSize;
	local posX = targetPos.X+frameSize.X+(padding*2) > vpSize.X-10 and targetPos.X-frameSize.X-padding or targetPos.X;
	local posY = targetPos.Y+frameSize.Y+(padding*2) > vpSize.Y-10 and targetPos.Y-frameSize.Y+padding or targetPos.Y;

	return Vector2.new(posX - targetParPos.X, posY - targetParPos.Y-36);
end

function RefreshPremium()
	StorageInterface.IsPremium = modData.Profile ~= nil and modData.Profile.Premium or false;
	return StorageInterface.IsPremium;
end


--- Reset these
StorageInterface.ItemBarsCache = {};
StorageInterface.GlobalSyncLock = false;
StorageInterface.ActiveSlotItem = nil;

---
function StorageInterface.init()
	StorageInterface.ActiveSlotItem = nil;
	StorageInterface.GlobalSyncLock = false;

	table.clear(StorageInterface.ItemBarsCache);
	modItemInterface.init();

	if currentOptionFrame then Debugger.Expire(currentOptionFrame, 0) end;

	StorageInterface.GlobalItemToolTipObject = modItemInterface.newItemTooltip();
	StorageInterface.GlobalDescFrame = StorageInterface.GlobalItemToolTipObject.Frame;
	StorageInterface.GlobalDescFrame.Size = UDim2.new(0, 340, 0, 300);
end

function StorageInterface.SetQuickTarget(interface)
	if not UserInputService.KeyboardEnabled then return end;
	quickTargetInterface = interface;
end

function StorageInterface.GetEmptyInventorySlotData(TableB)
	local inventoryInterface = StorageInterface.GetInterfaceWithStorageId("Inventory");
	if inventoryInterface then
		local slotData = inventoryInterface:GetEmptySlotData(TableB);
		if slotData then
			return slotData;
		end
	end
	return;
end

function StorageInterface.GetInterfaceWithStorageId(storageId)
	local modInterface = modData:GetInterfaceModule();
	
	for index, interface in pairs(modInterface.StorageInterfaces) do
		if interface.StorageId == storageId then
			return interface;
		end
	end
	return;
end
--== DescriptionFrame;

function StorageInterface.ToggleDesc(visible)
	if StorageInterface.GlobalDescFrame == nil then return end;
	StorageInterface.GlobalDescFrame.Visible = visible;
	if not visible then
		StorageInterface.ActiveSlotItem = nil;
	end
end


function StorageInterface.RefreshItemBar(button, storageItem, itemLib)
end

function StorageInterface.SetDescription(itemId, storageItem)
	local itemLib = modItem:Find(itemId);
	local itemDescription = "Unknown item ("..(itemId or "nil")..")";
	local frameHeight = 0;
	
	if StorageInterface.GlobalItemToolTipObject then
		StorageInterface.GlobalItemToolTipObject:Update(itemId, storageItem);
	end
end

function StorageInterface:UpdateSlotFrames(slotFrames)
	for i, buttonTable in pairs(self.Slots) do
		if self.Slots[i] and self.Slots[i].Table and self.Slots[i].Table.Destroy then
			self.Slots[i].Table:Destroy();
		end
	end

	for _,child in pairs(slotFrames) do
		local index = child:GetAttribute("Index") or child.LayoutOrder;
		child.Name = index;
		local slotData = {InterfaceIndex=self.Index; Frame=child; Index=index};
		self.Slots[index] = slotData;
		self.StartIndex = index < self.StartIndex and index or self.StartIndex;
		self.EndIndex = index > self.EndIndex and index or self.EndIndex;
		child.MouseMoved:Connect(function()
			if self.ViewOnly == true then return end;
			CurrentSlot = slotData;
		end)
	end
end

function StorageInterface:GetEmptySlotData(bSelf)
	if bSelf ~= nil and bSelf.Properties.Stackable then
		for a=self.StartIndex, self.EndIndex do
			local aSelf = self.Slots[a].Table;
			if aSelf ~= nil
				and aSelf.Properties and aSelf.Properties.Stackable
				and aSelf.Item.ItemId == bSelf.Item.ItemId
				and (aSelf.Item.Quantity+bSelf.Item.Quantity) <= aSelf.Properties.Stackable then
				
				return self.Slots[a];
			end
		end
	end
	
	for a=self.StartIndex, self.EndIndex do
		if self.Slots[a].Table == nil and self.Slots[a].Frame and self.Slots[a].Frame.Visible then
			return self.Slots[a];
		end
	end
end

function StorageInterface:ToggleDescriptionFrame(visible, fadeIn, fadeOut)
	if self.DescriptionFrame then
		self.DescriptionFrame.Visible = visible;
		StorageInterface.ToggleDesc(false);
	else
		StorageInterface.ToggleDesc(visible);
	end
end

function StorageInterface:BeginDragItem(slotItem)
	if StorageInterface.GlobalSyncLock then return end;
	if self.ViewOnly == true then return end;
	if slotItem.Locked then return end;
	
	local storageId = self.StorageId;
	local storage = modData.Storages[self.StorageId];
	
	if storage == nil then return end;
	
	if storage.Settings.DepositOnly then
		if not self.WarnLabel.Visible then
			self.WarnLabel.Text = "Deposit Only!"
			self.WarnLabel.Visible = true;
			task.delay(1, function()
				self.WarnLabel.Visible = false;
			end)
		end
		return;
	end
	
	self:ToggleDescriptionFrame(false);
	StorageInterface.CloseOptionMenus();

	local isTargetInterfaceVisible = quickTargetInterface and quickTargetInterface.MainFrame and modComponents.IsTrulyVisible(quickTargetInterface.MainFrame);
	if StorageInterface.LeftShiftDown and isTargetInterfaceVisible then
		if storageId == "Inventory" then -- Shift Click from inventory
			local emptySlotData = quickTargetInterface:GetEmptySlotData(slotItem);
			CurrentSlot = emptySlotData;
			self:StopDragItem(slotItem);

		else -- Shift Click from external storage
			local inventoryInterface = StorageInterface.GetInterfaceWithStorageId("Inventory");
			local isInvInterfaceVisible = inventoryInterface and inventoryInterface.MainFrame and modComponents.IsTrulyVisible(inventoryInterface.MainFrame);
			
			if isInvInterfaceVisible then
				local emptySlotData = StorageInterface.GetEmptyInventorySlotData(slotItem);
	
				if emptySlotData == nil then
					local storage = modData.Storages.Inventory;
					if storage and storage.LinkedStorages then
						for a=1, #storage.LinkedStorages do
							local storageId = storage.LinkedStorages[a].StorageId;
	
							local linkedInterface = StorageInterface.GetInterfaceWithStorageId(storageId);
							if linkedInterface then
								emptySlotData = linkedInterface:GetEmptySlotData(slotItem);
								if emptySlotData then break; end;
							end
						end
					end
				end
	
				CurrentSlot = emptySlotData;
				self:StopDragItem(slotItem);
			end
		end
		
	elseif CurrentDragging == nil then
		CurrentDragging = slotItem;
		lastDraged = slotItem;
		slotItem.Button.ZIndex = 4;
		
		for _,child in pairs(slotItem.Button:GetDescendants()) do
			if child:IsA("GuiObject") then
				child.ZIndex = 4;
			end
		end
		
		delay(0, function()
			dropDraggingHook = UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
				if inputObject.UserInputType == Enum.UserInputType.MouseButton1 
					or inputObject.UserInputType == Enum.UserInputType.MouseButton2 then

					if CurrentDragging then
						self:StopDragItem(CurrentDragging);
					end
					dropDraggingHook:Disconnect();
				end
			end);
		end);
		
		if slotItem.Properties.Type == modItem.Types.Resource then
			if slotItem.Properties.Name == "Metal Scraps" then
				modAudio.Play("StorageMetalPickup");
			elseif slotItem.Properties.Name == "Glass Shards" then
				modAudio.Play("StorageGlassPickup");
			elseif slotItem.Properties.Name == "Wooden Parts" then
				modAudio.Play("StorageWoodPickup");
			elseif slotItem.Properties.Name == "Cloth" then
				modAudio.Play("StorageClothPickup");
			end
		elseif slotItem.Properties.Type == modItem.Types.Blueprint then
			modAudio.Play("StorageBlueprintPickup");
		elseif slotItem.Properties.Type == modItem.Types.Tool then
			modAudio.Play("StorageWeaponPickup");
		elseif slotItem.Properties.Type == modItem.Types.Clothing then
			modAudio.Play("StorageClothPickup");
		else
			modAudio.Play("StorageItemPickup");
		end
		
		RunService:BindToRenderStep("DraggingItem", Enum.RenderPriority.Input.Value-1, function(delta)
			if slotItem.Button == nil or slotItem.Button.Parent == nil then RunService:UnbindFromRenderStep("DraggingItem"); return; end;
			local s, e = pcall(function()
				local mousePosition = UserInputService:GetMouseLocation();
				slotItem.Button.Position = UDim2.new(0, 
					mousePosition.X-slotItem.Button.Parent.AbsolutePosition.X-(slotItem.Button.AbsoluteSize.X/2),
					0, 
					mousePosition.Y-slotItem.Button.Parent.AbsolutePosition.Y-(slotItem.Button.AbsoluteSize.Y/2)-36
				);

				if currentQuanFrame then currentQuanFrame:Destroy(); currentQuanFrame=nil; end
				if currentOptionFrame then currentOptionFrame:Destroy(); currentOptionFrame=nil; end;
			end);
			if not s then Debugger:Warn(e) end;
		end)
		
	end
end


function StorageInterface:StopDragItem(slotItem)
	slotItem = slotItem or CurrentDragging;
	if slotItem == nil or slotItem.Locked then return end;
	
	lastDraged = slotItem;
	CurrentDragging = nil;
	lastDraggingTick = tick();
	if dropDraggingHook then dropDraggingHook:Disconnect(); end
	
	RunService:UnbindFromRenderStep("DraggingItem");
	if slotItem.Button and slotItem.Button.Parent ~= nil then
		slotItem.Button.ZIndex = 3;
		for _,child in pairs(slotItem.Button:GetDescendants()) do
			if child:IsA("GuiObject") then
				child.ZIndex = 3;
			end
		end

		slotItem:SetSlot(CurrentSlot);
		if not UserInputService.MouseEnabled then CurrentSlot = nil; end

		if slotItem.Properties.Type == modItem.Types.Resource then
			if slotItem.Properties.Name == "Metal Scraps" then
				modAudio.Play("StorageMetalDrop");
			elseif slotItem.Properties.Name == "Glass Shards" then
				modAudio.Play("StorageGlassDrop");
			elseif slotItem.Properties.Name == "Wooden Parts" then
				modAudio.Play("StorageWoodDrop");
			elseif slotItem.Properties.Name == "Cloth" then
				modAudio.Play("StorageClothDrop");
			end
		elseif slotItem.Properties.Type == modItem.Types.Blueprint then
			modAudio.Play("StorageBlueprintDrop");
		elseif slotItem.Properties.Type == modItem.Types.Tool then
			modAudio.Play("StorageWeaponDrop");
		elseif slotItem.Properties.Type == modItem.Types.Clothing then
			modAudio.Play("StorageClothDrop");
		else
			modAudio.Play("StorageItemDrop");
		end
	end
end


function StorageInterface:UseItem(Table)
	if Table == nil then Debugger:Warn("Attempt to equip nothing."); return; end;
	local modInterface = modData:GetInterfaceModule();
	
	local usableItemLib = modUsableItems:Find(Table.Item.ItemId);
	if usableItemLib then
		usableItemLib:Use(Table.Item);
		if currentOptionFrame ~= nil then currentOptionFrame.Visible = false; end

	elseif Table.Properties and Table.Properties.Equippable then
		if Table.Item.Values.IsEquipped == nil then
			modInterface:CloseWindow("Inventory");
		end
		modData.HandleTool("equip", {Id=Table.ID;});
		if currentOptionFrame ~= nil then currentOptionFrame.Visible = false; end

	else
		modInterface:HintWarning("Cannot Equip "..Table.Properties.Name.."!");
		
	end
end


function StorageInterface:UpdateDescriptionFrame(slotItem)
	if slotItem and slotItem.Locked or CurrentDragging ~= nil then return end;

	StorageInterface.SetDescription(slotItem.Item.ItemId, slotItem.Item);
	StorageInterface.ActiveSlotItem = slotItem;

	if StorageInterface.GlobalItemToolTipObject then
		StorageInterface.GlobalItemToolTipObject:SetPosition(slotItem.Slot.Frame);
	end
end


function StorageInterface:OnItemMouseMoved(Table)
	if not UserInputService.MouseEnabled then return end

	if CurrentDragging == nil and tick()-lastDraggingTick > 1 then
		self:UpdateDescriptionFrame(Table);
		self:ToggleDescriptionFrame(true);
	else
		self:ToggleDescriptionFrame(false);
	end
end;


function StorageInterface:OnItemMouseLeave(Table)
	if not UserInputService.MouseEnabled then return end
	self:ToggleDescriptionFrame(false);
	
end;


function StorageInterface:AddContextOption(packet)
	table.insert(self.ContextOptions, packet);
	table.sort(self.ContextOptions, function(a, b)
		return (a.Order or 99) < (b.Order or 99);
	end)
end


function StorageInterface:GetSlotWithID(storageItemID)
	for a=self.StartIndex, self.EndIndex do
		if self.Slots[a].Table and self.Slots[a].Table.ID == storageItemID then
			return self.Slots[a];
		end
	end
	return;
end

function StorageInterface.WithdrawalOnlyCheck(interface, slotItemA, slotItemB)
	local Storage = modData.Storages[interface.StorageId];
	if Storage and Storage.Settings.WithdrawalOnly then
		if not interface.WarnLabel.Visible then
			interface.WarnLabel.Text = "Withdrawal Only!"
			interface.WarnLabel.Visible = true;
			delay(1, function()
				interface.WarnLabel.Visible = false;
			end)
		end
		if slotItemA then slotItemA.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true); end
		if slotItemB then slotItemB.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true); end
		return true;
	end
	return false;
end

function StorageInterface.DepositOnlyCheck(interface, slotItemA, slotItemB)
	local storage = modData.Storages[interface.StorageId];
	if storage and storage.Settings.DepositOnly then
		if not interface.WarnLabel.Visible then
			interface.WarnLabel.Text = "Deposit Only!"
			interface.WarnLabel.Visible = true;
			delay(1, function()
				interface.WarnLabel.Visible = false;
			end)
		end
		if slotItemA then slotItemA.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true); end
		if slotItemB then slotItemB.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true); end
		return true;
	end
	return false;
end

--== SlotItem
local SlotItem = {};
SlotItem.__index = SlotItem;


function SlotItem.new(storageInterface)
	local self = {
		Locked = false;
		
	};
	
	self.Interface = storageInterface;
	
	setmetatable(self, SlotItem);
	return self;
end

function SlotItem:ActivateDelete(mousePosition)
	mousePosition = mousePosition or UserInputService:GetMouseLocation();
	
	local modInterface = modData:GetInterfaceModule();
	
	local interface = self.Interface;
	
	local promptPos = getPromptPosition(interface.MainFrame.AbsolutePosition, lastMousePos or mousePosition, currentQuanFrame.AbsoluteSize);
	currentQuanFrame.Position = UDim2.new(0, promptPos.X, 0, promptPos.Y);

	currentQuanFrame.Visible = true;
	currentQuanFrame.DeleteConfirm.Visible = true;
	currentQuanFrame.Title.Text = "Delete "..self.Properties.Name;

	if self.Properties.Stackable then
		currentQuanFrame.QuantityInput.Text = 1;
		currentQuanFrame.QuantityInput.Visible = true;
		currentQuanFrame.LockedQuantityInput.Visible = false;
		currentQuanFrame.BarButton.BackgroundTransparency = 0.8;
		
		currentQuanFrame.SliderBar.Position = UDim2.new(0, 13, 0, 28);
		currentQuanFrame.SliderBar.AutoButtonColor = true;

		currentQuanFrame.SliderBar.BackgroundColor3 = modBranchConfigurations.BranchColor;

		local minQuantity = 1; local maxQuantity = self.Item.Quantity;
		local powerRatio = maxQuantity > 10 and 1.4 or maxQuantity > 50 and 1.5 or maxQuantity > 100 and 1.75 or 1.15;

		local function StartQuantitySlider()
			local mouseXOrigin = UserInputService:GetMouseLocation().X;
			local xOffset = mouseXOrigin-currentQuanFrame.BarButton.AbsolutePosition.X;
			RunService:BindToRenderStep("QuantitySlider", Enum.RenderPriority.Input.Value+1, function(delta)
				if currentQuanFrame == nil or not playerGui:IsAncestorOf(currentQuanFrame) then RunService:UnbindFromRenderStep("QuantitySlider"); return end;
				local mousePosition = UserInputService:GetMouseLocation();
				local sliderPercent = math.clamp(mousePosition.X-mouseXOrigin+xOffset, 0, 254)/254;
				local inputQuantity = math.floor(math.clamp(maxQuantity*sliderPercent^powerRatio , minQuantity, maxQuantity));
				if currentQuanFrame then
					currentQuanFrame.SliderBar.Position = UDim2.new(0, math.clamp(256*sliderPercent+13, 13, 267), 0, 28);
					currentQuanFrame.QuantityInput.Text = inputQuantity;
					if not StorageInterface.PrimaryInputDown or not currentQuanFrame.Visible then
						RunService:UnbindFromRenderStep("QuantitySlider");
					end
				else
					RunService:UnbindFromRenderStep("QuantitySlider");
				end
			end)
		end


		table.insert(optionsListeners, currentQuanFrame.QuantityInput.FocusLost:Connect(function(enterPassed)
			local inputQuantity = math.floor(math.clamp(tonumber(currentQuanFrame.QuantityInput.Text) or 1, 1, maxQuantity));
			currentQuanFrame.QuantityInput.Text = inputQuantity;
			currentQuanFrame.SliderBar.Position = UDim2.new(0, math.clamp((inputQuantity/maxQuantity)^(1/powerRatio)*256+13, 13, 267), 0, 30);
			mouseInOptionFrame = tick();
		end))

		table.insert(optionsListeners, currentQuanFrame.SliderBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				StartQuantitySlider();
			end
		end));

		table.insert(optionsListeners, currentQuanFrame.BarButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				StartQuantitySlider();
			end
		end))
	else
		currentQuanFrame.QuantityInput.PlaceholderText = 1;
		currentQuanFrame.QuantityInput.Visible = false;
		currentQuanFrame.SliderBar.AutoButtonColor = false;
		currentQuanFrame.LockedQuantityInput.Visible = true;
		currentQuanFrame.BarButton.BackgroundTransparency = 0.9;
		currentQuanFrame.SliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50);
		currentQuanFrame.SliderBar.BorderColor3 = Color3.fromRGB(75, 75, 75);
		currentQuanFrame.SliderBar.Position = UDim2.new(0, 10, 0, 30);
	end

	table.insert(optionsListeners, currentQuanFrame.DeleteConfirm.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			itemActionDebounce = false;
			if modData.Storages[self.ID] then
				Debugger:Warn("Item (",self.ID,") has a existing storage.");
				modInterface:PromptWarning("Please remove attached mods before deleting.");
				itemActionDebounce = true;
				return;
			end
			local deleteTick = tick();
			local deleteTime = 0.35;
			RunService:BindToRenderStep("DeleteConfirm", Enum.RenderPriority.Input.Value+1, function(delta)
				if not playerGui:IsAncestorOf(currentQuanFrame) then RunService:UnbindFromRenderStep("DeleteConfirm"); return end;
				local deleteBar = currentQuanFrame.DeleteConfirm.Bar;
				local deletePercent = math.clamp((tick()-deleteTick)/deleteTime, 0, 1);
				deleteBar.Size = UDim2.new(deletePercent, 0, 1, 0);
				if deletePercent >= 1 and not itemActionDebounce then
					currentQuanFrame.DeleteConfirm.Text = "Deleting...";
					itemActionDebounce = true;
					local removeQuantity = math.floor(tonumber(currentQuanFrame.QuantityInput.Text) or 1);
					self.Locked = true;
					StorageInterface.GlobalSyncLock = true;

					interface.SyncLabel.Visible = true;
					RunService:UnbindFromRenderStep("DeleteConfirm");

					modData.HandleTool("local", {Unequip={Id=self.ID;}});

					local replyedStorages = remoteRemoveItem:InvokeServer(interface.StorageId, self.ID, removeQuantity);
					interface.SyncLabel.Visible = false;
					StorageInterface.UpdateStorages(replyedStorages);

					itemActionDebounce = false;
					self.Locked = false;
					StorageInterface.GlobalSyncLock = false;
				else
					currentQuanFrame.DeleteConfirm.Text = "Hold To Delete";
				end
				if not StorageInterface.PrimaryInputDown then
					RunService:UnbindFromRenderStep("DeleteConfirm");
					deleteBar.Size = UDim2.new(0, 0, 1, 0);
					delay(0.5, function()
						if currentQuanFrame then currentQuanFrame.DeleteConfirm.Text = "Delete"; end
					end)
				end
			end)
		end
	end))
end

function SlotItem:SwapSlot(slotTableB)
	local aSelf = self;
	local bSelf = slotTableB.Table;
	
	local aSlot = self.Slot.Frame;
	local bSlot = slotTableB.Frame;
	
	local interface = self.Interface;
	local interfaceB = interface.InterfacesList[slotTableB.InterfaceIndex];

	for a=1, #interfaceB.DepositLimitCheck do
		if interfaceB.DepositLimitCheck[a](interface, self, bSelf) == false then
			return;
		end
	end

	for a=1, #interface.DepositLimitCheck do
		if interface.DepositLimitCheck[a](interfaceB, bSelf, self) == false then
			return;
		end
	end
	
	if StorageInterface.DepositOnlyCheck(interface, aSelf, bSelf) or StorageInterface.WithdrawalOnlyCheck(interfaceB, aSelf, bSelf) then return end;
	if modStorageItem.IsStackable(aSelf.Item, bSelf.Item) then
		--Combine;
		if (aSelf.Item.Quantity+bSelf.Item.Quantity) > aSelf.Properties.Stackable then
			-- Combine into B
			aSelf.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);
			bSelf.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);

			local remainder = aSelf.Properties.Stackable-bSelf.Item.Quantity;
			bSelf.QuantityLabel.Text = aSelf.Properties.Stackable;
			aSelf.QuantityLabel.Text = aSelf.Item.Quantity-remainder;
		else
			-- Combine with B
			aSelf.Button.Position = UDim2.new(0, self.Button.AbsolutePosition.X-bSlot.AbsolutePosition.X, 0, self.Button.AbsolutePosition.Y-bSlot.AbsolutePosition.Y);
			aSelf.Button.Parent = bSlot;
			aSelf.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);
			bSelf.QuantityLabel.Text = (aSelf.Item.Quantity+bSelf.Item.Quantity);
			delay(0.099, function() if aSelf.Button ~= nil then aSelf.Button.Visible = false; end; end);
		end
		interface.SyncLabel.Visible, interface.InterfacesList[slotTableB.InterfaceIndex].SyncLabel.Visible = true, true;
		aSelf.Locked, bSelf.Locked = true, true;
		StorageInterface.GlobalSyncLock = true;

		local replyedStorages = remoteCombine:InvokeServer(interface.StorageId, {ID=aSelf.ID;},{ID=bSelf.ID; Id=interfaceB.StorageId;});
		interface.SyncLabel.Visible, interface.InterfacesList[slotTableB.InterfaceIndex].SyncLabel.Visible = false, false;
		StorageInterface.UpdateStorages(replyedStorages);

		aSelf.Locked, bSelf.Locked = false, false;
		StorageInterface.GlobalSyncLock = false;
		
	else
		if StorageInterface.WithdrawalOnlyCheck(interface, aSelf, bSelf) or StorageInterface.DepositOnlyCheck(interfaceB, aSelf, bSelf) then return end;
		--Swap;

		aSelf.Button.Position = UDim2.new(0, self.Button.AbsolutePosition.X-bSlot.AbsolutePosition.X, 0, self.Button.AbsolutePosition.Y-bSlot.AbsolutePosition.Y);
		aSelf.Button.Parent = bSlot;
		aSelf.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);

		bSelf.Button.Position = UDim2.new(0, self.Button.AbsolutePosition.X-aSlot.AbsolutePosition.X, 0, self.Button.AbsolutePosition.Y-aSlot.AbsolutePosition.Y);
		bSelf.Button.Parent = aSlot;
		bSelf.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);

		aSelf.Locked, bSelf.Locked = true, true;
		StorageInterface.GlobalSyncLock = true;
		interface.SyncLabel.Visible, interfaceB.SyncLabel.Visible = true, true;

		--Index=self.Index--Index=slotTableB.Index
		local replyedStorages = remoteSwapSlot:InvokeServer(interface.StorageId, {ID=aSelf.ID;},{ID=bSelf.ID; Id=interfaceB.StorageId;});
		interface.SyncLabel.Visible, interfaceB.SyncLabel.Visible = false, false;
		StorageInterface.UpdateStorages(replyedStorages);

		aSelf.Locked, bSelf.Locked = false, false;
		StorageInterface.GlobalSyncLock = false;
	end
end


function SlotItem:SetSlot(slotTable)
	if slotTable == nil then
		self.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);
		return;
	end
	
	local interface = self.Interface;
	
	local targetInterface = interface.InterfacesList[slotTable.InterfaceIndex];
	local targetSlot = slotTable.Frame;

	if targetInterface == nil then
		self.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);
		return;
	end

	if targetInterface.PremiumOnly and not StorageInterface.IsPremium then
		self.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);
		Debugger:Print("Not Premium");
		--modInterface:PromptWarning("Premium Member Only");

		local MarketplaceService = game:GetService("MarketplaceService");
		MarketplaceService:PromptGamePassPurchase(player, 2649294);
		--2649294
		return;
	end
	
	if slotTable.Table ~= nil and slotTable.Table.ID == self.ID then
		self.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);
	else
		if slotTable.Table == nil then
			for a=1, #targetInterface.DepositLimitCheck do
				if targetInterface.DepositLimitCheck[a](interface, self) == false then
					return;
				end
			end

			if StorageInterface.WithdrawalOnlyCheck(targetInterface, self) or StorageInterface.DepositOnlyCheck(interface, self) then return end;
			self.Locked = true;
			StorageInterface.GlobalSyncLock = true;
			
			self.Button.Position = UDim2.new(0, self.Button.AbsolutePosition.X-targetSlot.AbsolutePosition.X, 0, self.Button.AbsolutePosition.Y-targetSlot.AbsolutePosition.Y);
			self.Button.Parent = targetSlot;
			self.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);

			interface.SyncLabel.Visible, targetInterface.SyncLabel.Visible = true, true;
			local replyedStorages = remoteSetSlot:InvokeServer(interface.StorageId, self.ID, {Id=targetInterface.StorageId; Index=slotTable.Index;});
			interface.SyncLabel.Visible, targetInterface.SyncLabel.Visible = false, false;
			StorageInterface.UpdateStorages(replyedStorages);

			self.Locked = false;
			StorageInterface.GlobalSyncLock = false;
		else
			self:SwapSlot(slotTable);
		end
	end
end

function SlotItem:Update(storageItemId)
	local interface = self.Interface;
	
	self.Item = modData.Storages[interface.StorageId].Container[self.ID];
	self.Properties = modItem:Find(self.Item.ItemId);
	--self.Item.Properties = self.Properties;
	
	self.Index = self.Item.Index;
	self.Slot = interface.Slots[self.Index];
	self.Button.Position = UDim2.new(0, self.Button.AbsolutePosition.X-self.Slot.Frame.AbsolutePosition.X, 0, self.Button.AbsolutePosition.Y-self.Slot.Frame.AbsolutePosition.Y);
	self.Button.Active = true;

	if self.Button.Parent == nil then Debugger:Warn("Attempt to assign deleted button,", self.Index,"=>",self.Slot.Frame); return end;
	self.Button.Parent = self.Slot.Frame;
	
	if CurrentDragging == self then --lastDraged==self and tick()-lastDraggingTick <= 0.22
		
	elseif self.Button:IsDescendantOf(playerGui) then
		self.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);
		
	else
		self.Button.Size = UDim2.new();
		
	end
	
	self.Button.Visible = true;

	if self.Itembar == nil or storageItemId == self.ID then
		self.Itembar = true;
		self.ItemButtonObject.Itembar = true;
	end
	task.spawn(function()
		self.ItemButtonObject:Update(self.Item); -- Update item button;
	end)

	if interface.CustomHighlight then
		interface.CustomHighlight(self);
	else
		self.ViewOnly = nil;
		--self.Button.ImageColor3 = modItem.TierColors[self.Properties and self.Properties.Tier or 0];
	end

	return self;
end

function SlotItem:Destroy()
	Debugger.Expire(self.Button, 0);
	self.Button = nil;
	
	self.Interface.Buttons[self.ID] = nil;
end
--


function StorageInterface:NewButton(id)
	local slotItem = SlotItem.new(self);
	
	slotItem.ID = id;
	slotItem.Item = modData.Storages[slotItem.Interface.StorageId].Container[slotItem.ID];
	slotItem.Index = slotItem.Item.Index;
	
	slotItem.Properties = modItem:Find(slotItem.Item.ItemId);
	slotItem.Item.Properties = slotItem.Properties;

	slotItem.ItemButtonObject = modItemInterface.newItemButton(slotItem.Item.ItemId);
	slotItem.ItemButtonObject:Update(slotItem.Item);
	slotItem.ItemButtonObject.ImageButton:SetAttribute("StorageItemId", id);
	slotItem.ItemButtonObject.ImageButton:SetAttribute("StroageInterfaceIndex", self.Index);

	slotItem.Button = slotItem.ItemButtonObject.ImageButton;
	slotItem.Button.Parent = script;

	slotItem.QuantityLabel = slotItem.Button:WaitForChild("QuantityLabel");
	
	slotItem.Slot = self.Slots[slotItem.Index];

	for _, c in pairs(slotItem.Slot.Frame:GetChildren()) do
		if c.Name == "Button" then 
			local found = false;
			for k, _ in pairs(self.InterfacesList) do
				for id, bt in pairs(self.InterfacesList[k].Buttons or {}) do
					if bt.Button == c then
						if bt.Slot then
							local button = bt.Button;
							button.Position = UDim2.new(0, button.AbsolutePosition.X-bt.Slot.Frame.AbsolutePosition.X, 0, button.AbsolutePosition.Y-bt.Slot.Frame.AbsolutePosition.Y);
							button.Parent = bt.Slot.Frame;
							button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);
						else
							bt.Button.Parent = script;
						end
						found = true;
						break;
					end
				end
			end

			if not found then
				c:Destroy();
			end
		end
	end;

	slotItem.Button.Parent = slotItem.Slot.Frame;
	
	slotItem:Update();
	self.Buttons[slotItem.ID] = slotItem;

	slotItem.Button.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			self:OnItemMouseMoved(slotItem);
		end
	end)
	slotItem.Button.InputChanged:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			self:OnItemMouseMoved(slotItem);
		end
	end)

	slotItem.Button.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			self:OnItemMouseLeave(slotItem);
		end
	end)

	local function OpenOptionMenu(generateOnly)
		if CurrentDragging then return end;
		slotItem.Item = modData.Storages[slotItem.Interface.StorageId].Container[slotItem.ID];
		RunService:UnbindFromRenderStep("DeleteConfirm");

		if currentQuanFrame then currentQuanFrame:Destroy(); currentQuanFrame=nil; end
		currentQuanFrame = quantityFrame:Clone();
		currentQuanFrame.Parent = self.MainFrame;
		currentQuanFrame.MouseMoved:Connect(function() mouseInOptionFrame = tick(); end)

		if currentOptionFrame then currentOptionFrame:Destroy(); currentOptionFrame=nil; end;
		currentOptionFrame = optionFrame:Clone();
		currentOptionFrame.Parent = self.MainFrame;
		currentOptionFrame.MouseMoved:Connect(function() mouseInOptionFrame = tick(); end)

		currentOptionFrame.EquipOption.Visible = false; 
		currentOptionFrame.UnequipOption.Visible = false;
		currentOptionFrame.SplitOption.Visible = false;
		
		currentQuanFrame.DeleteConfirm.Visible = false;
		currentQuanFrame.SplitConfirm.Visible = false;

		for a=1, #optionsListeners do optionsListeners[a]:Disconnect(); end;
		optionsListeners = {};

		mouseInOptionFrame = tick();
		if generateOnly then return end;

		local contextOptionFirstPass = true;
		for a=1, #self.ContextOptions do
			local option = self.ContextOptions[a];

			local isViewOnly = self.ViewOnly == true or slotItem.ViewOnly == true;
			if option.AllowViewOnly ~= true and isViewOnly then continue end;
			if option.Check and option.Check(slotItem) == false then continue end;

			local button = option.Button and option.Button:Clone() or templateContextOption:Clone();
			button.LayoutOrder = option.Order or a;
			if option.Text then
				local buttonText = tostring(typeof(option.Text) == "function" and option.Text(slotItem) or option.Text);

				if UserInputService.KeyboardEnabled and contextOptionFirstPass then
					buttonText = buttonText.." [E]";
					contextOptionFirstPass = false;
				end

				button.Text = buttonText;
			end
			button.Parent = currentOptionFrame;

			table.insert(optionsListeners, button.MouseButton1Click:Connect(function()
				currentQuanFrame.Visible = false;
				currentOptionFrame.Visible = false;
				option.Click(slotItem);
			end))
		end

		if slotItem.Properties.Stackable and slotItem.Item.Quantity > 1 then
			currentOptionFrame.SplitOption.Visible = true;

		else

		end

		local Storage = modData.Storages[self.StorageId];
		if Storage then
			if Storage.Settings.DepositOnly then
				--currentOptionFrame.DeleteOption.Visible = false;
				currentOptionFrame.SplitOption.Visible = false;
			end
		end

		if currentOptionFrame.SplitOption.Visible then
			table.insert(optionsListeners, currentOptionFrame.SplitOption.MouseButton1Click:Connect(function()
				itemActionDebounce = false;

				local promptPos = getPromptPosition(self.MainFrame.AbsolutePosition, lastMousePos, currentQuanFrame.AbsoluteSize);
				currentQuanFrame.Position = UDim2.new(0, promptPos.X, 0, promptPos.Y);

				currentQuanFrame.Visible = true;
				currentQuanFrame.SplitConfirm.Visible = true;
				currentQuanFrame.Title.Text = "Split Stack";
				currentQuanFrame.QuantityInput.Text = 1;
				currentQuanFrame.QuantityInput.Visible = true;
				currentQuanFrame.LockedQuantityInput.Visible = false;
				currentQuanFrame.BarButton.BackgroundTransparency = 0.8;
				--currentQuanFrame.SliderBar.BackgroundColor3 = Color3.fromRGB(150, 150, 150);
				--currentQuanFrame.SliderBar.BorderColor3 = Color3.fromRGB(200, 200, 200);
				currentQuanFrame.SliderBar.Position = UDim2.new(0, 13, 0, 28);
				currentQuanFrame.SliderBar.AutoButtonColor = true;

				currentQuanFrame.SliderBar.BackgroundColor3 = modBranchConfigurations.BranchColor;

				local minQuantity = 1; local maxQuantity = (slotItem.Item.Quantity-1);
				local powerRatio = maxQuantity > 10 and 1.4 or maxQuantity > 50 and 1.5 or maxQuantity > 100 and 1.75 or 1.3;

				--local mousePosition = UserInputService:GetMouseLocation();
				local function StartQuantitySlider()
					local mouseXOrigin = UserInputService:GetMouseLocation().X;
					local xOffset = mouseXOrigin-currentQuanFrame.BarButton.AbsolutePosition.X;
					
					RunService:BindToRenderStep("QuantitySlider", Enum.RenderPriority.Input.Value+1, function(delta)
						if not playerGui:IsAncestorOf(currentQuanFrame) then RunService:UnbindFromRenderStep("QuantitySlider"); return end;
						
						local mousePosition = UserInputService:GetMouseLocation();
						local sliderPercent = math.clamp(mousePosition.X-mouseXOrigin+xOffset, 0, 254)/254;
						local inputQuantity = math.floor(math.clamp(maxQuantity*sliderPercent^powerRatio , minQuantity, maxQuantity));
						currentQuanFrame.SliderBar.Position = UDim2.new(0, math.clamp(256*sliderPercent+13, 13, 267), 0, 28);
						currentQuanFrame.QuantityInput.Text = inputQuantity;
						if not StorageInterface.PrimaryInputDown or not currentQuanFrame.Visible then
							RunService:UnbindFromRenderStep("QuantitySlider");
						end
					end)
				end

				table.insert(optionsListeners, currentQuanFrame.QuantityInput.FocusLost:Connect(function(enterPassed)
					local inputQuantity = math.floor(math.clamp(tonumber(currentQuanFrame.QuantityInput.Text) or 1, 1, maxQuantity));
					currentQuanFrame.QuantityInput.Text = inputQuantity;
					currentQuanFrame.SliderBar.Position = UDim2.new(0, math.clamp((inputQuantity/maxQuantity)^(1/powerRatio)*256+13, 13, 267), 0, 30);
					mouseInOptionFrame = tick();
				end))

				table.insert(optionsListeners, currentQuanFrame.SliderBar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
						StartQuantitySlider();
					end
				end));

				table.insert(optionsListeners, currentQuanFrame.BarButton.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
						StartQuantitySlider();
					end	
				end))

				table.insert(optionsListeners, currentQuanFrame.SplitConfirm.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
						local splitQuantity = math.floor(tonumber(currentQuanFrame.QuantityInput.Text) or 1);
						local fakeButton = slotItem.Button:Clone();
						fakeButton.Name = "FakeButton";
						fakeButton.ZIndex = 4;
						local hint = currentQuanFrame.Hint:Clone();
						hint.Parent = fakeButton;
						hint.Position = UDim2.new(1, -20, 1, -10);
						hint.ZIndex = 4;
						hint.Visible = true;
						for _,child in pairs(fakeButton:GetDescendants()) do
							if child:IsA("GuiObject") then
								child.ZIndex = 4;
							end
						end

						delay(0.2, function()
							fakeButton.MouseButton1Click:Connect(function()
								if itemActionDebounce then return end;
								itemActionDebounce = true;
								local dropTable = CurrentSlot;
								local dropInterface = dropTable and self.InterfacesList[dropTable.InterfaceIndex] or nil;
								local dropSlot = dropInterface and dropInterface.Slots[dropTable.Index] or nil;
								RunService:UnbindFromRenderStep("Splitting");
								hint:Destroy();

								if CurrentSlot ~= nil then
									if dropSlot == nil or dropSlot.Table == nil or (dropSlot.Table.ID ~= slotItem.ID 
										and modStorageItem.IsStackable(dropSlot.Table.Item, slotItem.Item)
										and dropSlot.Table.Item.Quantity+splitQuantity <= slotItem.Properties.Stackable) then

										fakeButton.Position = UDim2.new(0, fakeButton.AbsolutePosition.X-dropSlot.Frame.AbsolutePosition.X, 0, fakeButton.AbsolutePosition.Y-dropSlot.Frame.AbsolutePosition.Y);
										fakeButton.Parent = dropSlot.Frame;
										fakeButton:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);
										spawn(function() while wait(1/60) do if dropSlot.Frame:FindFirstChild("Button") then fakeButton:Destroy(); break; end end end);

										slotItem.Locked = true;
										StorageInterface.GlobalSyncLock = true;
										self.SyncLabel.Visible, dropInterface.SyncLabel.Visible = true, true;

										local replyedStorages = remoteSplit:InvokeServer(self.StorageId, slotItem.ID, splitQuantity, {Id=dropInterface.StorageId; Index=dropTable.Index; ID=dropSlot.Table ~= nil and dropSlot.Table.ID or nil; });
										self.SyncLabel.Visible, dropInterface.SyncLabel.Visible = false, false;
										StorageInterface.UpdateStorages(replyedStorages);
										Debugger.Expire(fakeButton, 0);

										if slotItem.Properties.Type == modItem.Types.Resource then
											if slotItem.Properties.Name == "Metal Scraps" then
												modAudio.Play("StorageMetalDrop", nil, nil, false);
											elseif slotItem.Properties.Name == "Glass Shards" then
												modAudio.Play("StorageGlassDrop", nil, nil, false);
											elseif slotItem.Properties.Name == "Wooden Parts" then
												modAudio.Play("StorageWoodDrop", nil, nil, false);
											elseif slotItem.Properties.Name == "Cloth" then
												modAudio.Play("StorageClothDrop", nil, nil, false);
											end
										elseif slotItem.Properties.Type == modItem.Types.Blueprint then
											modAudio.Play("StorageBlueprintDrop", nil, nil, false);
										elseif slotItem.Properties.Type == modItem.Types.Tool then
											modAudio.Play("StorageWeaponDrop", nil, nil, false);
										elseif slotItem.Properties.Type == modItem.Types.Clothing then
											modAudio.Play("StorageClothDrop", nil, nil, false);
										else
											modAudio.Play("StorageItemDrop", nil, nil, false);
										end

										slotItem.Locked = false;
										StorageInterface.GlobalSyncLock = false;
									else
										fakeButton:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);
										slotItem.QuantityLabel.Text = slotItem.Item.Quantity;
										delay(0.08, function() fakeButton:Destroy(); end);
									end
								else
									fakeButton:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);
									slotItem.QuantityLabel.Text = slotItem.Item.Quantity;
									delay(0.08, function() fakeButton:Destroy(); end);
								end
								itemActionDebounce = false;
							end)
						end)

						RunService:BindToRenderStep("Splitting", Enum.RenderPriority.Input.Value+1, function(delta)
							local mousePosition = UserInputService:GetMouseLocation();

							slotItem.QuantityLabel.Text = (slotItem.Item.Quantity-splitQuantity);
							fakeButton.QuantityLabel.Text = splitQuantity;
							fakeButton.QuantityLabel.Visible = splitQuantity > 1 and true or false;
							fakeButton.Position = UDim2.new(0, mousePosition.X-slotItem.Slot.Frame.AbsolutePosition.X-(fakeButton.AbsoluteSize.X/2), 0, mousePosition.Y-slotItem.Slot.Frame.AbsolutePosition.Y-(fakeButton.AbsoluteSize.Y/2)-36);

							if not self.MainFrame.Visible then
								RunService:UnbindFromRenderStep("Splitting");
								fakeButton:Destroy();
							end
						end)
						fakeButton.Parent = slotItem.Slot.Frame;
						currentQuanFrame.Visible = false;
					end
				end))
				currentOptionFrame.Visible = false;
			end))
		end
		
		lastMousePos = UserInputService:GetMouseLocation();
		local promptPos = getPromptPosition(self.MainFrame.AbsolutePosition, lastMousePos, currentOptionFrame.AbsoluteSize);
		currentOptionFrame.Position = UDim2.new(0, promptPos.X, 0, promptPos.Y);
	end


	if UserInputService.TouchEnabled then
		slotItem.Button.TouchLongPress:Connect(function()
			if self.DisableContextMenu == true then return end;
			OpenOptionMenu();
		end)
	end

	local itemButtonClickBeganTick = tick();
	slotItem.Button.InputBegan:Connect(function(input, gameProcessed)
		local isViewOnly = self.ViewOnly == true or slotItem.ViewOnly == true;

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if isViewOnly then return end;
			if clickDebounce ~= nil and tick()-clickDebounce < 0.1 then return end;
			clickDebounce = tick(); delay(0.1, function() clickDebounce = nil; end);

			itemButtonClickBeganTick = tick();
			if self.OnItemButton1Click then self:OnItemButton1Click(slotItem); end

		elseif input.UserInputType == Enum.UserInputType.MouseButton2 and self.DisableContextMenu ~= true then
			OpenOptionMenu();

		elseif input.UserInputType == Enum.UserInputType.Keyboard then
			if isViewOnly then return end;
			if input.KeyCode == Enum.KeyCode.Delete then
				if slotItem.Item.Fav ~= true and slotItem.Properties.CanDelete == 0 then
					OpenOptionMenu(true);
					slotItem:ActivateDelete();
					
				end
			end
		end
	end)

	slotItem.Button.InputEnded:Connect(function(input)
		if slotItem.ViewOnly == true then return end;

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local clickLapse = tick()-itemButtonClickBeganTick;

			if UserInputService.TouchEnabled then
				if clickLapse <= 0.13 then

					if self.OnItemButton1Click ~= self.BeginDragItem then return end;

					StorageInterface.SetDescription(slotItem.Item.ItemId, slotItem.Item);

					if slotItem.Button.AbsolutePosition.X <= workspace.CurrentCamera.ViewportSize.X/2 then
						StorageInterface.GlobalDescFrame.Position = UDim2.new(0.5, 0, 0, 0);
					else
						StorageInterface.GlobalDescFrame.Position = UDim2.new(0, 0, 0, 0);
					end
					StorageInterface.GlobalDescFrame.Size = UDim2.new(0.5, 0, 1, 0);

					self:ToggleDescriptionFrame(true);

				end
			end
		end
	end)

	return slotItem;
end


function StorageInterface:GetItemButton(storageItemId)
	if self == nil then
		local modInterface = modData:GetInterfaceModule();
		
		for index, interface in pairs(modInterface.StorageInterfaces) do
			if interface.Buttons[storageItemId] then
				return interface.Buttons[storageItemId]; --StorageId
			end
		end
	end
	return self.Buttons[storageItemId];
end

function StorageInterface:ConnectOnUpdate(func)
	table.insert(self.OnUpdateEvent, func);
end

function StorageInterface:ConnectDepositLimit(func)
	table.insert(self.DepositLimitCheck, func);
end

function StorageInterface:DisconnectDepositLimit(func)
	for a=#self.DepositLimitCheck, 1, -1  do
		if self.DepositLimitCheck[a] == func then
			table.remove(self.DepositLimitCheck, a);
		end
	end
end

function StorageInterface:Destroy()
	for id, bt in pairs(self.Buttons) do bt:Destroy(); end
	self.InterfacesList[self.Index] = nil;
end

function StorageInterface:ClearPrompts()
	RunService:UnbindFromRenderStep("DeleteConfirm");
	if currentQuanFrame then currentQuanFrame:Destroy(); currentQuanFrame=nil; end;
	if currentOptionFrame then currentOptionFrame:Destroy(); currentOptionFrame=nil; end;
end

function StorageInterface:Update(storage, storageItemId)
	storage = storage or modData.Storages[self.StorageId];
	if storage == nil then Debugger:Warn("StorageInterface:Update Storage Id (",self.StorageId,") not found."); return end;
	
	if self.MainFrame:FindFirstChild("storageMode") then
		local storageModeLabel = self.MainFrame:FindFirstChild("storageMode");
		if storage.Settings then
			storageModeLabel.Image = storage.Settings.WithdrawalOnly and "rbxassetid://3227351059"
				or storage.Settings.DepositOnly and "rbxassetid://3227350852"
				or "rbxassetid://3227350675";
		end
	end
	
	RefreshPremium();
	

	for id, bt in pairs(self.Buttons) do
		local storageItem = storage.Container[id];
		local oldStorageItem = bt.Item;

		if storageItem == nil or self.Slots[storageItem.Index] == nil then
			bt:Destroy();

		end
	end
	
	for index, _ in pairs(self.Slots) do
		local slotTable = self.Slots[index];
		local slotFrame = slotTable.Frame;

		if (slotFrame:GetAttribute("Index") or slotFrame.LayoutOrder) > storage.Size then
			slotFrame.Visible = false;
		else
			slotFrame.Visible = true;
		end

		if storage.PremiumStorage == nil then
			Debugger:Warn("Missing PremiumStorage:",storage.Id);
			storage.PremiumStorage = 100;
		end

		if slotFrame.ClassName == "Frame" then
			slotFrame.BackgroundTransparency = 0.75;
			slotFrame.BorderSizePixel = 0;

		elseif slotFrame.ClassName == "ImageLabel" then

			if slotFrame:GetAttribute("DefaultColor") == nil then
				slotFrame:SetAttribute("DefaultColor", slotFrame.ImageColor3);
			end

			slotFrame.ImageColor3 = slotFrame:GetAttribute("DefaultColor");

			for _, obj in pairs(slotFrame:GetChildren()) do
				if obj.Name == "UIGradient" then
					obj:Destroy();
				end
			end	
		end
		
		if storageItemId and slotTable.ID ~= storageItemId then continue end;
		self.Slots[index].Table = nil;
	end

	for id, storageItem in pairs(storage.Container) do
		if self.Slots[storageItem.Index] == nil then continue end;
		if storageItemId and id ~= storageItemId then continue end;
		
		if self.Buttons[id] == nil or self.Buttons[id].Button.Parent == nil then
			self:NewButton(storageItem.ID);
			
		else
			self.Buttons[id]:Update(storageItemId);
			
		end
		self.Slots[storageItem.Index].Table = self.Buttons[id];

		if storageItem.Values.IsEquipped then
			local slotFrame = self.Slots[storageItem.Index].Frame
			if slotFrame.ClassName == "Frame" then
				slotFrame.BackgroundTransparency = 0.25;
				slotFrame.BorderSizePixel = 2;

			elseif slotFrame.ClassName == "ImageLabel" then
				local new = templateHighlighGradient:Clone();
				new.Parent = slotFrame;
				slotFrame.ImageColor3 = Color3.fromRGB(255, 255, 255);

			end
		end
		
	end

	for index, _ in pairs(self.Slots) do
		local slotTable = self.Slots[index];
		if self.DecorateSlot then
			self:DecorateSlot(index, slotTable);
		end
	end
	
	for a=1, #self.OnUpdateEvent do
		if self.OnUpdateEvent[a] and typeof(self.OnUpdateEvent[a]) == "function" then
			local s, e = pcall(function()
				self.OnUpdateEvent[a](self);
			end)
			if not s then
				Debugger:Warn(e);
			end
		end
	end
end


local lastMousePos;
function StorageInterface.new(storageId, mainFrame, slotFrames)
	local modInterface = modData:GetInterfaceModule();
	
	local self = {
		StorageId = storageId;
		
		PremiumOnly = false;
		
		StartIndex = 999;
		EndIndex = 0;
	};
	
	self.Slots = {};
	self.Buttons = {};
	self.DepositLimitCheck = {};
	self.OnUpdateEvent = {};
	
	self.InterfacesList = modInterface.StorageInterfaces;
	self.Index = modInterface.StorageInterfaceIndex;

	self.InterfacesList[self.Index] = self;
	modInterface.StorageInterfaceIndex = modInterface.StorageInterfaceIndex +1;
	
	setmetatable(self, StorageInterface);
	
	self:UpdateSlotFrames(slotFrames);
	
	self.MainFrame = mainFrame;
	self.DescriptionFrame = self.MainFrame:FindFirstChild("DescriptionFrame") or nil;
	
	self.SyncLabel = self.MainFrame:FindFirstChild("SyncLabel") or {Visible=false;};
	self.WarnLabel = self.MainFrame:FindFirstChild("WarnLabel") or {Visible=false;};
	
	--==
	self.OnItemButton1Click = self.BeginDragItem;
	--self.OnItemMouseMoved = self.OnItemMouseMoved;
	--self.OnItemMouseLeave = self.OnItemMouseLeave;
	
	--== ContextOptions
	self.ContextOptions = {};
	
	self:AddContextOption({
		Text="Inspect";
		AllowViewOnly=true;
		Click=function(Table)
			itemViewportObject = itemViewportObject or modInterface.ItemViewport.new();
			itemViewportObject:SetZIndex(4);
			local frame = itemViewportObject.Frame;

			local inspectFrame = modInterface.MainInterface.InspectFrame;
			inspectFrame.Visible = true;

			frame.Parent = inspectFrame;
			frame.Size = UDim2.new(1, 0, 1, 0);
			frame.Visible = true;

			local closeConn;
			closeConn = inspectFrame:GetPropertyChangedSignal("Visible"):Connect(function()
				if not inspectFrame.Visible then
					if itemViewportObject then itemViewportObject:Destroy(); end
				end
			end)
			itemViewportObject.Garbage:Tag(function()
				itemViewportObject = nil;
				if closeConn then
					closeConn:Disconnect();
					closeConn = nil;
				end
				inspectFrame.Visible = false;
			end)

			itemViewportObject:SetDisplay(Table.Item);

			if currentOptionFrame ~= nil then currentOptionFrame.Visible = false; end
		end;
		Order=9;
	})
	
	self:AddContextOption({
		Button=script.DeleteOption;
		Check=function(slotItem)
			if self.DeleteEnabled == false then
				return false;
			end
			
			local visible = slotItem.Properties.CanDelete == 0;
			if slotItem.Properties.CanDelete > 0 then
				local c = modData.CountItemIdFromStorages(slotItem.Item.ItemId);
				visible = c > slotItem.Properties.CanDelete;
			end

			if slotItem.Item.Fav then
				visible = false;
			end

			local storage = modData.Storages[self.StorageId];
			if storage then
				if storage.Settings.DepositOnly then
					visible = false;
				end
			end

			return visible;
		end;
		Click=function(slotItem)
			slotItem:ActivateDelete();
			if currentOptionFrame ~= nil then currentOptionFrame.Visible = false; end
		end;
		Order=20;
	})
	
	if modBranchConfigurations.CurrentBranch.Name ~= "Live" or player.UserId == 16170943 then
		self:AddContextOption({
			Text="Print Tags";
			Click=function(slotItem)
				local itemLib = modItem:Find(slotItem.Item.ItemId);
				if itemLib then
					Debugger:Warn("Print Tags  Item"..slotItem.ID..">>", game:GetService("HttpService"):JSONEncode(itemLib.Tags));
				end
			end;
			Order=998;
		});
		self:AddContextOption({
			Text="Debug";
			Click=function(slotItem)
				Debugger:StudioWarn("DebugClicked  Storage>>", modData.Storages[slotItem.Interface.StorageId]);
				Debugger:Warn("DebugClicked ("..storageId..") Item"..slotItem.ID..">>", game:GetService("HttpService"):JSONEncode(slotItem.Item));
			end;
			Order=999;
		});
	end
	
	return self;
end

function StorageInterface.UpdateStorages(storages, storageItemId)
	local modInterface = modData:GetInterfaceModule(true);
	if modInterface == nil then return end;
	
	storages = storages or {};
	if #storages <= 0 then Debugger:Warn(script.Name..">>  No storages to update."); end;
	
	local updateInterfaces = {};
	local updatedStorageIds = {};
	
	for a=1, #storages do
		modData.SetStorage(storages[a]);
		updatedStorageIds[storages[a].Id] = storages[a];

	end
	
	for storageId, _ in pairs(updatedStorageIds) do
		for index, interface in pairs(modInterface.StorageInterfaces) do
			if interface.StorageId == storageId then
				interface:Update(nil, storageItemId);

				table.insert(updateInterfaces, interface.MainFrame.Name);
			end
		end
	end

	--Debugger:StudioWarn("UpdateStorages", updateInterfaces);
end

function StorageInterface.RefreshStorageItemId(storageItemId)
	local modInterface = modData:GetInterfaceModule(true);
	if modInterface == nil then return end;
	
	for index, interface in pairs(modInterface.StorageInterfaces) do
		local slotItem = interface.Buttons[storageItemId];
		if slotItem == nil then continue end;
		slotItem:Update();
	end
end

if UserInputService.TouchEnabled then
	UserInputService.InputEnded:Connect(function (input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.Touch and CurrentDragging then
			local inteface = CurrentDragging.Interface;
			if inteface then
				inteface:StopDragItem(CurrentDragging);
			end
		end
	end)
end

function StorageInterface.CloseOptionMenus()
	if (tick() - mouseInOptionFrame) > 0.05 then
		if currentOptionFrame then currentOptionFrame:Destroy() end;
		if currentQuanFrame then currentQuanFrame:Destroy() end;
	end
end

function StorageInterface.CloseInspectFrame()
	local modInterface = modData:GetInterfaceModule();
	local inspectFrame = modInterface.MainInterface.InspectFrame;
	inspectFrame.Visible = false;
end

UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
	if inputObject.KeyCode == Enum.KeyCode.E then
		local slotItem = StorageInterface.ActiveSlotItem;
		if slotItem then
			local interface = slotItem.Interface;
			
			for a=1, #interface.ContextOptions do
				local option = interface.ContextOptions[a];

				if option.Check and option.Check(slotItem) == false then continue end;

				Debugger:Log("ContextOptions", option);
				option.Click(slotItem);
				break;
			end
		end
		
	end
end)

return StorageInterface;