local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local uiGradientSequence = {
	ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
	ColorSequenceKeypoint.new(0.001, Color3.fromRGB(50, 50, 50)),
	ColorSequenceKeypoint.new(0.002, Color3.fromRGB(20, 20, 20)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
}

--== Variables;
local Interface = {};

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule") :: ModuleScript);
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library.WorkbenchLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modClothingLibrary = require(game.ReplicatedStorage.Library.ClothingLibrary);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local modItemInterface = require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modStorageInterface = require(game.ReplicatedStorage.Library.UI.StorageInterface);
--== Script;

local syncTimeConn;
function Interface.init(modInterface)
	Interface = setmetatable(Interface, modInterface);
	local window;
	
	local interfaceScreenGui = localplayer.PlayerGui:WaitForChild("MainInterface");
	
	local storageFrame = modConfigurations.CompactInterface and script:WaitForChild("MobileStorage"):Clone() or script:WaitForChild("Storage"):Clone();
	storageFrame.Parent = interfaceScreenGui;
	
	local storageList = storageFrame:WaitForChild("MainList");
	local slotTemplate = script:WaitForChild("Slot");
	local buttonsFrame = storageFrame:WaitForChild("ButtonsFrame");
	local gridLayout = storageList:WaitForChild("UIGridLayout");

	local storageTitleTag;

	if modConfigurations.CompactInterface then
		--storageFrame = script.Parent.Parent.MobileStorage;
		storageTitleTag = storageFrame:WaitForChild("TitleFrame"):WaitForChild("Title");
		
		storageFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
			Interface:CloseWindow("ExternalStorage");
		end)
		
		gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right;

		local padding = Instance.new("UIPadding");
		padding.PaddingLeft = UDim.new(0, 15);
		padding.Parent = storageList;

		buttonsFrame.Size = UDim2.new(1, 0, 0, 40);

	else
		storageTitleTag = storageFrame:WaitForChild("Title");
	end


	local addSlotButton = script:WaitForChild("PurchaseSlot");
	local pageButton = script:WaitForChild("pageButton");

	local remotes = game.ReplicatedStorage.Remotes;
	local remoteStorageService = modRemotesManager:Get("StorageService");
	local remoteUpgradeStorage = modRemotesManager:Get("UpgradeStorage");
	local remoteItemActionHandler = modRemotesManager:Get("ItemActionHandler");
	local remoteOpenStorageRequest = remotes.Interactable.OpenStorageRequest;

	local camera = workspace.CurrentCamera;

	local defaultInterface, premiumInterface = Interface.modInventoryInterface.DefaultInterface, Interface.modInventoryInterface.PremiumInterface;
	local clothingInterface = Interface.modInventoryInterface.ClothingInterface;
	
	local activeStorageId, activeStorageInterface, baseStorageId;
	local addSlotDebounce = tick();
	local smallScreen = false;
	
	local function openStorage(storageId, page)
		local storage = remoteOpenStorageRequest:InvokeServer(Interface.Object, Interface.InteractScript, page);
		if storage and type(storage) == "table" then
			modData.SetStorage(storage);
		end
		return storage;
	end

	local firstload = true;
	local function refreshBoundarySize()
		if modConfigurations.CompactInterface then
			Interface.SelfWindow.OpenPosition = UDim2.new(0.5, 0, 0, 0);
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
		Interface.SelfWindow.OpenPosition = UDim2.new(0, newStorageX, 0.5, 0);

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
			uiGradientSequence[2] = ColorSequenceKeypoint.new(r-0.001, Color3.fromRGB(50, 50, 50));
			uiGradientSequence[3] = ColorSequenceKeypoint.new(r, Color3.fromRGB(20, 20, 20));
			storageFrame.UIGradient.Color = ColorSequence.new(uiGradientSequence);
		end
	end
	
	function Interface.Update(storageId, storage, wardrobeStorageItemId)
		if storageId == nil then return end;
		activeStorageId = storageId;
		storage = storage or modData.Storages[activeStorageId];
		Debugger:Log("Opening storage:",storageId,"(",storage and storage.Name,")");
		
		local storageName = storage.Name or activeStorageId or "nil";
		
		if storage.MaxPages and storage.MaxPages > 1 then
			storageName = storageName .. " [".. (storage.Page or "1") .."/".. storage.MaxPages .."]"
		end
		
		storageTitleTag.Text = storageName;
		
		if activeStorageInterface then activeStorageInterface:Destroy() end;
		for _, c in pairs(storageList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end; end;
		
		local slotFrames = {};
		local yieldTick = tick(); repeat until storage.Size or tick()-yieldTick >1 or not wait(1/60);
		if storage.Size then
			for a=1, 50 do --(storage.MaxSize or storage.Size)
				local slot = slotTemplate:Clone();
				slot:SetAttribute("Index", a);
				slot.LayoutOrder = a;
				slot.Parent = storageList;
				table.insert(slotFrames, slot);
			end
			
			local newAddSlotButton = addSlotButton:Clone();
			newAddSlotButton.LayoutOrder = storage.Size+1;
			newAddSlotButton.Parent = storageList;
			
			activeStorageInterface = modStorageInterface.new(activeStorageId, storageFrame, slotFrames);
			
			function activeStorageInterface:DecorateSlot(index, slotTable)
				local slotFrame = slotTable.Frame;

				if index > storage.PremiumStorage then
					slotFrame.ImageColor3 = Color3.fromRGB(75, 50, 50);
				else
					slotFrame.ImageColor3 = Color3.fromRGB(50, 50, 50);
				end
			end
			
			if storage.Expandable and storage.Size < storage.MaxSize then
				newAddSlotButton.Visible = true;
				
				local cost = modWorkbenchLibrary.StorageCost(storage.Id, storage.Size);
				newAddSlotButton.MouseButton1Click:Connect(function()
					if tick()-addSlotDebounce <= 0.1 then return end;
					addSlotDebounce = tick();
					
					local proccessed = false;
					cost = modWorkbenchLibrary.StorageCost(storage.Id, storage.Size);
					Interface:CloseWindow("ExternalStorage");
					
					local promptWindow = Interface:PromptQuestion("Purchase storage slot?",
						("Are you sure you want to purchase a storage slot for $Cost Perks?"):gsub("$Cost", cost), 
						"Purchase", "Cancel", "rbxassetid://3187395807");
					local YesClickedSignal, NoClickedSignal;
					
					YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
						if tick()-addSlotDebounce <= 0.2 then return end;
						addSlotDebounce = tick();
						
						Interface:PlayButtonClick();
						promptWindow.Frame.Yes.buttonText.Text = "Purchasing...";
						local r = remoteUpgradeStorage:InvokeServer(storage.Id);
						if type(r) == "table" and r.Id then
							modData.SetStorage(r);
							Interface.Update(r.Id, r);
							promptWindow.Frame.Yes.buttonText.Text = "Slot Purchased!";
							wait(0.5);
							
						elseif r == 1 then
							promptWindow.Frame.Yes.buttonText.Text = "Purchase Failed!";
							wait(2);
							
						elseif r == 2 then
							promptWindow.Frame.Yes.buttonText.Text = "Not enough Perks!";
							wait(2);
							promptWindow:Close();
							Interface:OpenWindow("GoldMenu", "PerksPage");
							return;
							
						end
						
						activeStorageInterface:Update();
						promptWindow:Close();
						proccessed = true;
						Interface:OpenWindow("ExternalStorage");
						
						YesClickedSignal:Disconnect();
						NoClickedSignal:Disconnect();
					end);
					
					NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
						Interface:PlayButtonClick();
						promptWindow:Close();
						proccessed = true;
						Interface:OpenWindow("ExternalStorage");
						YesClickedSignal:Disconnect();
						NoClickedSignal:Disconnect();
					end);
					
					delay(5, function()
						if not proccessed and promptWindow then
							promptWindow:Close();
						end;
					end)
				end)
			else
				newAddSlotButton.Visible = false;
			end

			buttonsFrame.Visible = false;
			for _, obj in pairs(buttonsFrame:GetChildren()) do
				if obj.Name == "pageButton" then
					obj:Destroy();
				end
			end
			
			if storage.MaxPages and storage.MaxPages >= 1 then
				buttonsFrame.Visible = true;
				
				local indA, indB = storageId:find("#p");
				baseStorageId = indA and storageId:sub(1, indA-1) or storageId;
				
				for a=1, storage.MaxPages do
					local newButton = pageButton:Clone();
					newButton.Text = a;
					
					newButton.LayoutOrder = a;
					newButton.Parent = buttonsFrame;
					if modConfigurations.CompactInterface then
						newButton.ZIndex = 4;
					end
					if a == (storage.Page or 1) then
						newButton.BackgroundColor3 = Color3.fromRGB(160, 160, 160);
					end
					newButton.MouseButton1Click:Connect(function()
						Interface:PlayButtonClick();
						local newStorageId = baseStorageId;
						
						if a ~= 1 then
							newStorageId = baseStorageId.."#p"..a;
							
							--if modData.Storages[newStorageId] == nil then
							openStorage(newStorageId, a);
							--end
						end
						Interface.Update(newStorageId, modData.Storages[newStorageId]);
					end)
				end
			end


			if syncTimeConn then
				syncTimeConn:Disconnect();
				syncTimeConn = nil;
			end
			if storage.Settings and storage.Settings.Rental > 0 then
				buttonsFrame.Visible = true;
				local rentalPrice = storage.Settings.Rental;
				
				local newButton = pageButton:Clone();
				newButton.Text = "Rent";
				
				newButton.LayoutOrder = 0;
				newButton.BackgroundColor3 = Color3.fromRGB(66, 46, 91);
				newButton.Parent = buttonsFrame;
				if modConfigurations.CompactInterface then
					newButton.ZIndex = 4;
				end
				
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
						newButton.Text = `Unlock [{storage.Page or "1"}/{storage.MaxPages}] (<b><font color='rgb(170, 120, 0)'>{rentCost}{goldSuffix}</font></b>)`

					else
						activeStorageInterface.ViewOnly = false;
						newButton.Text = `Cost (<b><font color='rgb(170, 120, 0)'>{rentCost}{goldSuffix}</font></b>)`;
						
					end
					
					for id, buttonTable in pairs(activeStorageInterface.Buttons) do
						buttonTable.ItemButtonObject.DimOut = timeLeft <= 0 and 0.392157 or false;
						buttonTable.ItemButtonObject:Update(buttonTable.Item);
					end
					
					return itemCount, timeLeft;
				end

				activeStorageInterface:ConnectOnUpdate(updateRental);
				updateRental();
				syncTimeConn = modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(updateRental)
				
				newButton.MouseButton1Click:Connect(function()
					Interface:PlayButtonClick();
					local newStorageId = baseStorageId;
					
					local itemCount, timeLeft = updateRental();
					local rentCost = itemCount * rentalPrice;
					
					if timeLeft > 0 then return end;
					
					local promptWindow = Interface:PromptQuestion("Rent Rat Storage for <b><font color='rgb(170, 120, 0)'>".. rentCost.." Gold</font></b>?",
						"Unlock rat storage for 24 hours, <b><font color='rgb(170, 120, 0)'>10 Gold per slot</font></b>.\n<b>Warning, your items will be inaccessible after 24 hours and it will cost gold to re-unlock.</b>", 
						"Rent", "Cancel");
					local YesClickedSignal, NoClickedSignal;

					YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
						Interface:PlayButtonClick();
						promptWindow.Frame.Yes.buttonText.Text = "Unlocking...";
						
						local returnPacket = remoteStorageService:InvokeServer({Action="Rental"; StorageId=storage.Id; Request=true;});
						if returnPacket.Success then
							if returnPacket.Storages then
								for storageId, _ in pairs(returnPacket.Storages) do
									modData.SetStorage(returnPacket.Storages[storageId]);
								end
							end
							
							task.wait(1);
							Interface.Update(newStorageId, modData.Storages[newStorageId]);
							
						else
							task.wait(2);
							promptWindow:Close();
							Interface:OpenWindow("GoldMenu", "GoldPage");
							return;
							
						end

						activeStorageInterface:Update();
						promptWindow:Close();
						Interface:OpenWindow("ExternalStorage");
						
						YesClickedSignal:Disconnect();
						NoClickedSignal:Disconnect();
					end);
					
					NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
						Interface:PlayButtonClick();
						promptWindow:Close();
						
						YesClickedSignal:Disconnect();
						NoClickedSignal:Disconnect();
					end);
				end)
				
			end
			
			refreshBoundarySize();
			if firstload then
				firstload = false;
				task.delay(0.31, refreshBoundarySize);
			end
			activeStorageInterface:Update();
			
			if wardrobeStorageItemId then
				storageTitleTag.Text = "Set Vanity Clothing";
				
				local storageItemA = modData.GetItemById(wardrobeStorageItemId)
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
					local storageItemB = modData.GetItemById(slotId)
					local clothingLibB = modClothingLibrary:Find(storageItemB.ItemId);
					
					if slot.ItemButtonObject.DimOut ~= true then
						remoteItemActionHandler:FireServer(storageId, slotId, "setvanity", wardrobeStorageItemId);
						window:Close();
					end
				end
				
			else
				modStorageInterface.SetQuickTarget(activeStorageInterface);

			end
			
			updateFrame();
			
			task.spawn(function()
				local rPacket = remoteStorageService:InvokeServer({
					Action="OpenStorage";
					StorageId=activeStorageId;
				});
			end)
		else
			Debugger:Warn("Failed to load external storage.");
			Interface:CloseWindow("ExternalStorage");
		end
	end

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
	local inputChange = storageFrame.InputChanged:Connect(function(inputObject, gameProcessedEvent)
		if inputObject.UserInputType == Enum.UserInputType.MouseWheel then
			if debounce then return end;
			debounce = true;
			
			if buttonsFrame.Visible then
				local dir = -inputObject.Position.Z;
				local storage = modData.Storages[activeStorageId];
				if storage then
					local page = storage.Page;
					local maxPages = storage.MaxPages;
					
					if maxPages == nil then return end;
					
					local newStorageId = baseStorageId;
					local a = page or 1;
					if dir < 0 then
						a = math.clamp(a -1, 1, maxPages);
					elseif dir > 0 then
						a = math.clamp(a +1, 1, maxPages);
					end
					
					if a ~= 1 then
						newStorageId = baseStorageId.."#p"..a;
						
						--if modData.Storages[newStorageId] == nil then
							openStorage(newStorageId, a);
						--end
					end
					Interface.Update(newStorageId, modData.Storages[newStorageId]);
						
				end
			end
			debounce = false;
		end
	end)
	
	
	window = Interface.NewWindow("ExternalStorage", storageFrame);
	Interface.SelfWindow = window;
	
	if camera.ViewportSize.X <= 1366 then
		smallScreen = true;
	else
		smallScreen = false;
	end
	refreshBoundarySize();
	window.OnWindowToggle:Connect(function(visible, storageId, storage, wardrobeStorageItemId)
		if visible then
			if wardrobeStorageItemId then
				local function cancelWardrobe()
					window:Close();
				end
				if defaultInterface then defaultInterface.OnItemButton1Click = cancelWardrobe; end
				if premiumInterface then premiumInterface.OnItemButton1Click = cancelWardrobe; end
				if clothingInterface then clothingInterface.OnItemButton1Click = cancelWardrobe; end
			end
			
			Interface:HideAll{[window.Name]=true; ["Inventory"]=true;};
			Interface:ToggleInteraction(false);
			Interface:OpenWindow("Inventory");
			Interface.Update(storageId, storage, wardrobeStorageItemId);
			refreshBoundarySize();
			spawn(function()
				if storageId == "Wardrobe" then
					if wardrobeStorageItemId and Interface.Object == nil then return end;
					return;
				end
				if storage and storage.Virtual then return end;
				repeat until not window.Visible
					or Interface.Object == nil 
					or localplayer:DistanceFromCharacter(Interface.Object.Position) >= 16
					or not wait(0.1);
				window:Close();
			end)
			
		else
			if defaultInterface then defaultInterface.OnItemButton1Click = Interface.modInventoryInterface.DefaultInterface.BeginDragItem; end
			if premiumInterface then premiumInterface.OnItemButton1Click = Interface.modInventoryInterface.PremiumInterface.BeginDragItem; end
			if clothingInterface then clothingInterface.OnItemButton1Click = Interface.modInventoryInterface.ClothingInterface.BeginDragItem; end
			
			task.delay(0.3, function()
				Interface:ToggleInteraction(true);
			end)
			modStorageInterface.SetQuickTarget();
			Interface:CloseWindow("Inventory");
			
			task.spawn(function()
				local rPacket = remoteStorageService:InvokeServer({
					Action="CloseStorage";
					StorageId=activeStorageId;
				});
			end)
		end
	end)
	
	window.OnWindowUpdate:Connect(function(visible, storageId, storage, wardrobeStorageItemId)
		if window.Visible then
			Interface.Update(storageId, storage, wardrobeStorageItemId);
		end
	end)

	if not modConfigurations.CompactInterface then
		window:AddCloseButton(storageFrame);
	end
	return Interface;
end;

return Interface;