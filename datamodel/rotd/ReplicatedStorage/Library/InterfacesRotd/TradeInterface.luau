local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modFormatNumber = shared.require(game.ReplicatedStorage.Library.FormatNumber);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables)

local modNpcProfileLibrary = shared.require(game.ReplicatedStorage.Library.NpcProfileLibrary);

local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modStorageInterface = shared.require(game.ReplicatedStorage.Library.UI.StorageInterface);
local modRichFormatter = shared.require(game.ReplicatedStorage.Library.UI.RichFormatter);

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));
    local remoteTradeRequest = modRemotesManager:Get("TradeRequest");

    local windowFrame = script:WaitForChild("TradeMenu"):Clone();
    windowFrame.Parent = interface.ScreenGui;

	local titleLabel = windowFrame:WaitForChild("Title");
	local cancelButton = windowFrame:WaitForChild("cancelButton");
	local cancelGradient = cancelButton:WaitForChild("UIGradient");
	
	local mainFrame = windowFrame:WaitForChild("Main");
	local tradeWarnLabel = mainFrame:WaitForChild("tradeWarnLabel");
	
	local confirmFrame = mainFrame:WaitForChild("ConfirmFrame");
	local confirmButton = confirmFrame:WaitForChild("confirmButton");
	local confirmGradient = confirmButton:WaitForChild("UIGradient");
	local feeLabel = confirmFrame:WaitForChild("feeLabel");
	
	local localTradeFrame = mainFrame:WaitForChild("LocalTradeFrame");
	local ltfObjects = {
		NameLabel = localTradeFrame:WaitForChild("playerName");
		StorageFrame = localTradeFrame:WaitForChild("storage");
		GoldLabel = localTradeFrame:WaitForChild("goldInput");
		StatusLabel = localTradeFrame:WaitForChild("statusLabel");
		AvatarLabel = localTradeFrame:WaitForChild("AvatarLabel");
	}

	local otherTraderFrame = mainFrame:WaitForChild("OtherTradeFrame");
	local otfObjects = {
		NameLabel = otherTraderFrame:WaitForChild("playerName");
		StorageFrame = otherTraderFrame:WaitForChild("storage");
		GoldLabel = otherTraderFrame:WaitForChild("goldLabel");
		StatusLabel = otherTraderFrame:WaitForChild("statusLabel");
		AvatarLabel = otherTraderFrame:WaitForChild("AvatarLabel");
	}
	
	local customPrompt = otherTraderFrame:WaitForChild("customPrompt");
	local customListContainer = customPrompt:WaitForChild("rightListContainer");
	local pageButtons = customPrompt:WaitForChild("pageButtons");
    

	if modConfigurations.CompactInterface then
		windowFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20);
		game.Debris:AddItem(windowFrame:FindFirstChild("UIGradient"), 0);
		
		titleLabel.BackgroundTransparency = 0.1;
		titleLabel.Size = UDim2.new(1, 0, 0, 30);
		
		cancelButton.Position = UDim2.new(1, 0, 0, 0);
		cancelButton.Size = UDim2.new(0.2, 0, 0, 30);
		
		mainFrame.Size = UDim2.new(1, 0, 1, -30);
		
		
		localTradeFrame.Size = UDim2.new(1, 0, 0, 260);
		otherTraderFrame.Size = UDim2.new(1, 0, 0, 260);
		
		local function updateObjs(objects, isLocal)
			for k, obj in pairs(objects) do
				if k == "NameLabel" then
					obj.AnchorPoint = Vector2.zero;
					obj.Position = UDim2.new(0, 0, 0, 0);
					obj.Size = UDim2.new(1, 0, 0, 16);
					obj.TextXAlignment = Enum.TextXAlignment.Center;
					
				elseif k == "StorageFrame" then
					obj.AnchorPoint = Vector2.new(0.5, 0);
					obj.Position = UDim2.new(0.5, 0, 0, 30);

				elseif k == "GoldLabel" then
					obj.AnchorPoint = Vector2.new(0.5, 0);
					obj.Position = UDim2.new(0.5, 0, 0, 170);
					obj.TextXAlignment = Enum.TextXAlignment.Center;
					
				elseif k == "StatusLabel" then
					obj.AnchorPoint = Vector2.zero;
					obj.Position = UDim2.new(0,0,0, isLocal and 220 or 200);
					obj.Size = UDim2.new(1, 0, 0, 0);
					obj.AutomaticSize = Enum.AutomaticSize.Y;
					
					obj:GetPropertyChangedSignal("Text"):Connect(function()
						task.wait();
						local newYSize = obj.Position.Y.Offset + obj.AbsoluteSize.Y + 20;
						customPrompt.Position = UDim2.new(0.5, 0, 0, newYSize);
						customPrompt.Size = UDim2.new(1, 0, 0, 50);
					end)
					
				elseif k == "AvatarLabel" then
					obj.AnchorPoint = Vector2.new(0.5, 0.5);
					obj.Position = UDim2.new(0.5, 0, 0.5, 0);
					obj.Size = UDim2.new(1.3, 0, 1.3, 0);
					
				end
			end
		end
		
		updateObjs(ltfObjects, true);
		updateObjs(otfObjects, false);
		
		otfObjects.GoldLabel.goldIcon.Size = UDim2.new(0, 16, 0, 16);
		otfObjects.GoldLabel.goldIcon.AnchorPoint = Vector2.new(0, 0.5);
		otfObjects.GoldLabel.goldIcon.Position = UDim2.new(1, 10, 0.5, 1);
	end


	local itemButtonList = {};
	local itemToolTip = modItemInterface.newItemTooltip();
	
	
	local window: InterfaceWindow = interface:NewWindow("Trade", windowFrame);
    
    local binds = window.Binds;
    binds.TradeSession = nil;
    
	if modConfigurations.CompactInterface then
		window:SetClosePosition(UDim2.new(1, 0, -1.5, 0), UDim2.new(1, 0, 0, 0));
		windowFrame.AnchorPoint = Vector2.new(1, 0);
		windowFrame.Size = UDim2.new(0.5, 0, 1, 0);
		
	else
		window:SetClosePosition(UDim2.new(0.5, 0, -1.5, 0), UDim2.new(0.5, 0, 0.5, -37));
		
	end


	local localPlayerSlots = {}; 
    for _, obj in pairs(ltfObjects.StorageFrame:GetChildren()) do 
        if obj.Name == "Slot" then table.insert(localPlayerSlots, obj) end 
    end;
	local otherPlayerSlots = {}; 
    for _, obj in pairs(otfObjects.StorageFrame:GetChildren()) do 
        if obj.Name == "Slot" then table.insert(otherPlayerSlots, obj) end 
    end;
	local localStorageInterface = modStorageInterface.new(`{localPlayer.Name}Trade`, localTradeFrame, localPlayerSlots);
	local otherStorageInterface = modStorageInterface.new("Empty-Trade", otherTraderFrame, otherPlayerSlots);
	

	localStorageInterface:ConnectDepositLimit(function(slotInterface, slotTable, slotTableB)
		local storageOfItem = modData.Storages[slotTable.ID];

		local function invalid(msg, notifyMsg)
			if not slotInterface.WarnLabel.Visible then
				slotInterface.WarnLabel.Text = msg
				slotInterface.WarnLabel.Visible = true;
				delay(1, function()
					slotInterface.WarnLabel.Visible = false;
				end)
			end
			if slotTable then slotTable.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true); end
			if slotTableB then slotTableB.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true); end
			-- if Interface.modNotificationInterface then
			-- 	Interface.modNotificationInterface.Notify(nil, {
			-- 		Imp=true;
			-- 		Message=notifyMsg;
			-- 		ExtraData={
			-- 			ChatColor=Color3.fromRGB(255, 69, 69);
			-- 		};
			-- 	})
			-- end
		end

		if slotTable.Item.NonTradeable == 1 then
			invalid("NonTradeable", "This item can not be traded due to Roblox's IsPaidItemTradingAllowed policy.");
			return false;
		end
		if slotTable.Item.NonTradeable == 1 then
			invalid("NonTradeable", "This item is an limited nontradeable.");
			return false;
		end

		if storageOfItem ~= nil then
			invalid("Remove Mods!", "Can not trade weapon with mods!");
			return false;
		end

		if slotTable.Library.Type == "Mod" then
			local hasValues = false;
			for k, v in pairs(slotTable.Item.Values) do
				hasValues = true;
				break;
			end
			if hasValues then
				invalid("Invalid Mod!", "Can not trade upgraded mod!");
				return false;
			end
		end
		return;
	end);


	modData:RequestData("Trader/Gold");
    window.DisableInteractables = true;

    --MARK: OnToggle
	window.OnToggle:Connect(function(visible)
		if visible then
			interface:HideAll{[window.Name]=true; ["Inventory"]=true;};
            interface:ToggleWindow("Inventory", true);
			window:Freeze(true);
			
			mainFrame.CanvasPosition = Vector2.zero;
			
			ltfObjects.GoldLabel.Text = 0;
			ltfObjects.NameLabel.Text = localPlayer.Name;
			
            window:Update();

			local function buttonHighlight(buttonTable)
				if binds.TradeSession == nil then return end;
				local button = buttonTable.Button;
				local itemLib = buttonTable.Library;
				local _isPremium = binds.TradeSession.PremiumTrade;
				
				local isComputerSession = binds.TradeSession.ComputerSession;
				
				if isComputerSession and itemLib then
					button.ImageColor3 = modItemsLibrary.TierColors[itemLib.Tier];
					buttonTable.ViewOnly = nil;
					
				elseif itemLib and (itemLib.Tradable == modItemsLibrary.Tradable.Tradable 
					or itemLib.Tradable == modItemsLibrary.Tradable.PremiumOnly) then
					button.ImageColor3 = modItemsLibrary.TierColors[itemLib.Tier];
					buttonTable.ViewOnly = nil;

				else
					button.ImageColor3 = Color3.fromRGB(65, 65, 65);
					buttonTable.ViewOnly = true;

				end
			end

			for a=1, #interface.StorageInterfaces do
				local storageInterface: StorageInterface = interface.StorageInterfaces[a];
				if storageInterface.StorageId ~= "Inventory" and storageInterface.StorageId ~= "Clothing" then
					continue;
				end
				storageInterface.CustomHighlight = buttonHighlight;
                storageInterface:Update();
			end

			localStorageInterface:Update();
			otherStorageInterface:Update();
			modStorageInterface.SetQuickTarget();

		else
			window:Freeze(false);
			remoteTradeRequest:FireServer("cancel");
            
			for a=#interface.StorageInterfaces, 1, -1 do
				local storageInterface: StorageInterface = interface.StorageInterfaces[a];
				if storageInterface == nil then continue end;
				if storageInterface.StorageId ~= "Inventory" and storageInterface.StorageId ~= "Clothing" then
					continue;
				end

				storageInterface.CustomHighlight = nil;
                storageInterface.ViewOnly = nil;
                storageInterface:Update();
			end

			modStorageInterface.SetQuickTarget();
			
		end
	end)

	local function setSlotColors(color)
		for a=1, #localStorageInterface.Slots do
			if localStorageInterface.Slots[a] and localStorageInterface.Slots[a].Frame then
				localStorageInterface.Slots[a].Frame.ImageColor3 = color;
			end
		end
		for a=1, #otherStorageInterface.Slots do
			if otherStorageInterface.Slots[a] and otherStorageInterface.Slots[a].Frame then
				otherStorageInterface.Slots[a].Frame.ImageColor3 = color;
			end
		end
	end
	
	function binds.SyncLocalGold(gold)
		ltfObjects.GoldLabel.Text = gold;
	end

	local itemButtonCaches;
	local colorA, colorB, colorC = Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200), Color3.fromRGB(100, 100, 100);
	
    --MARK: OnUpdate
    window.OnUpdate:Connect(function()
        if binds.TradeSession == nil then return end;
		local state = binds.TradeSession.State;
		
		local _storage = modData.Storages.TradingStorage;
		itemButtonCaches = {};

		local localData, otherData;
		for name, _ in pairs(binds.TradeSession.Players) do
			if name == localPlayer.Name then
				localData = binds.TradeSession.Players[localPlayer.Name];
			else
				otherData = binds.TradeSession.Players[name];
			end
		end

		if localData == nil then Debugger:Log("Missing localData."); return end;
		if otherData == nil then Debugger:Log("Missing otherData"); return end;
		
		feeLabel.Text = "Tax:    $".. modFormatNumber.Beautify(binds.TradeSession.Fee) .." + "
			.. modRichFormatter.GoldText(modFormatNumber.Beautify(localData.GoldTax));
		

		local npcLib = otherData.IsNpc and modNpcProfileLibrary:Find(otherData.Name) or nil;

		ltfObjects.NameLabel.Text = localData.Premium and modRichFormatter.GoldText(localPlayer.Name) or localPlayer.Name;
		otfObjects.NameLabel.Text = (otherData.Premium and modRichFormatter.GoldText(otherData.Name) or otherData.Name)..
			(npcLib and " (" ..npcLib.Class..")" or "");
		
		ltfObjects.AvatarLabel.Image = shared.modPlayers.getAvatar(localPlayer.UserId);

		if binds.TradeSession.ComputerSession ~= true then
			feeLabel.Visible = true;
			
			local otherPlayer = game.Players:FindFirstChild(otherData.Name);
			if otherPlayer then
				task.spawn(function()
					otfObjects.AvatarLabel.Image = shared.modPlayers.getAvatar(otherPlayer.UserId);
				end)
			end

			if modConfigurations.CompactInterface then
				otherTraderFrame.Size = UDim2.new(1, 0, 0, 240);

			else
				otherTraderFrame.Size = UDim2.new(1, 0, 0, 140);

			end
			otfObjects.GoldLabel.Visible = true;
			tradeWarnLabel.Visible = true;
			customPrompt.Visible = false;
			
			
		else
			feeLabel.Visible = false;
			if npcLib then
				tradeWarnLabel.Visible = false;

				if modConfigurations.CompactInterface then
					--otfObjects.GoldLabel.AnchorPoint = Vector2.new(0.5, 0);
					--otfObjects.GoldLabel.Position = UDim2.new(0.5, -20, 0, 165);
					--otfObjects.GoldLabel.TextXAlignment = Enum.TextXAlignment.Center;
					
					--otfObjects.StatusLabel.AnchorPoint = Vector2.zero;
					--otfObjects.StatusLabel.Position = UDim2.new(0, 0, 0, 190);
					--otfObjects.StatusLabel.Size = UDim2.new(1, 0, 0, 0);
					--otfObjects.StatusLabel.AutomaticSize = Enum.AutomaticSize.Y;
					
				else
					otfObjects.GoldLabel.goldIcon.Size = UDim2.new(0, 16, 0, 16);
					otfObjects.GoldLabel.goldIcon.AnchorPoint = Vector2.new(0, 0.5);
					otfObjects.GoldLabel.goldIcon.Position = UDim2.new(1, 10, 0.5, 1);

					otfObjects.GoldLabel.AnchorPoint = Vector2.new(1, 0);
					otfObjects.GoldLabel.Position = UDim2.new(0.5, -20, 0, 0);
					otfObjects.GoldLabel.Size = UDim2.new(0, 120, 0, 16);
					otfObjects.GoldLabel.TextXAlignment = Enum.TextXAlignment.Right;

					otfObjects.StatusLabel.Position = UDim2.new(0, 0, 0, 25);
					otfObjects.StatusLabel.Size = UDim2.new(1, -265,  0, 100);
				end

				if npcLib.Avatar then
					otfObjects.AvatarLabel.Image = npcLib.Avatar;
				else
					otfObjects.AvatarLabel.Image = "";
				end
				
				if otherData.HideStorage then
					otfObjects.StorageFrame.Visible = false;
					otfObjects.StatusLabel.Size = UDim2.new(1, 0,  0, 100);
					
				else
					otfObjects.StorageFrame.Visible = true;
					
				end
				if otherData.HideGold then
					otfObjects.GoldLabel.Visible = false;
					
				else
					otfObjects.GoldLabel.Visible = true;
					
				end
				
				if otherData.Demands and #otherData.Demands > 0 then
					customListContainer.Visible = true;
					
					for a=1, #otherData.Demands do
						local demandInfo = otherData.Demands[a];

						local itemId = demandInfo.ItemId;

						local itemButtonObject = itemButtonList[itemId] or modItemInterface.newItemButton(itemId, true);
						local newItemButton = itemButtonObject.ImageButton;

						if itemButtonList[itemId] == nil then
							itemToolTip:BindHoverOver(newItemButton, function()
								itemToolTip.Frame.Parent = windowFrame;
								itemToolTip:Update(itemId);
								itemToolTip:SetPosition(newItemButton);
							end);
						end

						itemButtonList[itemId] = itemButtonObject;
						itemButtonCaches[itemId] = itemButtonObject;

						newItemButton.Name = itemId;
						newItemButton.BackgroundTransparency = 0.75;

						itemButtonObject:Update();

						newItemButton.LayoutOrder = a;

						local quantityLabel = newItemButton:WaitForChild("QuantityLabel");
						
						if demandInfo.Quantity then
							quantityLabel.Font = Enum.Font.Arial;
							quantityLabel.TextSize = 14;
							quantityLabel.Visible = true
							quantityLabel.Text = demandInfo.Quantity;
							
						elseif demandInfo.Price then
							quantityLabel.Font = Enum.Font.Arial;
							quantityLabel.TextSize = 14;
							quantityLabel.Visible = true

							quantityLabel.Text = demandInfo.Price.."G";
							quantityLabel.TextColor3 = Color3.fromRGB(255, 205, 79);
						end

						newItemButton.Parent = customListContainer;
					end
				end
				
				if otherData.AddPageButtons == true and state ~= 3 and binds.TradeSession.MaxPage ~= nil then
					pageButtons.Visible = true;
					
					if binds.TradeSession.Page and binds.TradeSession.MaxPage then
						pageButtons.backButton.Visible = binds.TradeSession.Page > 1;
						pageButtons.nextButton.Visible = binds.TradeSession.Page < binds.TradeSession.MaxPage;
						
						pageButtons.pageInput.PlaceholderText = binds.TradeSession.Page.."/"..binds.TradeSession.MaxPage;
						
					else
						pageButtons.backButton.Visible = true;
						pageButtons.nextButton.Visible = true;
						
					end
					
				else
					pageButtons.Visible = false;
					
				end
				
				if customListContainer.Visible or pageButtons.Visible then
					customPrompt.Visible = true;
					

					if modConfigurations.CompactInterface then
						otherTraderFrame.Size = UDim2.new(1, 0, 0, 330);
						
					else
						otherTraderFrame.Size = UDim2.new(1, 0, 0, 200);
						
					end
					
				else
					customPrompt.Visible = false;

					if modConfigurations.CompactInterface then
						otherTraderFrame.Size = UDim2.new(1, 0, 0, 260);
						
					else
						otherTraderFrame.Size = UDim2.new(1, 0, 0, 140);
						
					end
					
				end
			end
		end
		
		otfObjects.GoldLabel.Text = otherData.Gold;

		confirmButton.buttonText.Text = localData.Confirm and "Unconfirm" or "Confirm";
		
		local color = {
			ColorSequenceKeypoint.new(0, colorA),
			ColorSequenceKeypoint.new(0.001, colorA),
			ColorSequenceKeypoint.new(0.002, colorB),
			ColorSequenceKeypoint.new(1, colorB)
		};
		if localData.Confirm then
			color[2] = ColorSequenceKeypoint.new(0.001, colorA);
			color[3] = ColorSequenceKeypoint.new(0.002, colorC);
			color[4] = ColorSequenceKeypoint.new(1, colorC);
		end
		confirmGradient.Color = ColorSequence.new(color);
		
		modStorageInterface.SetQuickTarget(localStorageInterface);

		otherStorageInterface.StorageId = otherData.Name.."Trade";
		otherStorageInterface.ViewOnly = true;

		local commenceTime = binds.TradeSession.CommenceTime;

		local playerGold = modData.Profile and modData.Profile.Trader and modData.Profile.Trader.Gold or 0;
		
		if binds.TradeSession.Ended and state ~= 3 then
			localStorageInterface.ViewOnly = nil;
			confirmButton.Visible = false;
			cancelButton.buttonText.Text = "Close";
			
			ltfObjects.GoldLabel.TextEditable = false;

			ltfObjects.StatusLabel.Text = "Trade Cancelled!";
			ltfObjects.StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
			
			otfObjects.StatusLabel.Text = "Trade Cancelled!";
			otfObjects.StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255);

			setSlotColors(Color3.fromRGB(60, 40, 40));

		elseif state == 1 then
			localStorageInterface.ViewOnly = nil;
			confirmButton.Visible = true;
			cancelButton.buttonText.Text = "Cancel";
			
			ltfObjects.GoldLabel.TextEditable = playerGold > 0;
			
			if localData.HasRewardCrates then
				ltfObjects.StatusLabel.Text = "Restricted Items";
				ltfObjects.StatusLabel.TextColor3 = Color3.fromRGB(255, 76, 76);

			elseif localData.CantAffordTax then
				ltfObjects.StatusLabel.Text = "Cant Afford Gold Tax";
				ltfObjects.StatusLabel.TextColor3 = Color3.fromRGB(255, 76, 76);

			elseif localData.NoSpace and (otherData.Demands == nil or localData.Confirm) then
				ltfObjects.StatusLabel.Text = "No Inventory Space";
				ltfObjects.StatusLabel.TextColor3 = Color3.fromRGB(255, 76, 76);

			elseif localData.Confirm then
				ltfObjects.StatusLabel.Text = "Confirmed";
				ltfObjects.StatusLabel.TextColor3 = Color3.fromRGB(93, 182, 87);

			elseif localData.Money < binds.TradeSession.Fee then
				ltfObjects.StatusLabel.Text = "Not Enough Money";
				ltfObjects.StatusLabel.TextColor3 = Color3.fromRGB(255, 76, 76);

			else
				ltfObjects.StatusLabel.Text = "Waiting For You";
				ltfObjects.StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255);

			end

			setSlotColors(Color3.fromRGB(50, 50, 50));

		elseif state == 2 and commenceTime then
			localStorageInterface.ViewOnly = true;
			
			local countDown = math.clamp(commenceTime-modSyncTime.GetTime(), 0, 20);
			confirmButton.buttonText.Text = "Trading.. (".. math.floor(countDown) ..")";
			confirmButton.Visible = true;
			
			ltfObjects.GoldLabel.TextEditable = false;

			ltfObjects.StatusLabel.Text = "Confirmed";
			ltfObjects.StatusLabel.TextColor3 = Color3.fromRGB(93, 182, 87);
			
			setSlotColors(Color3.fromRGB(40, 40, 60));

		elseif state == 3 then
			localStorageInterface.ViewOnly = nil;
			confirmButton.Visible = false;
			cancelButton.buttonText.Text = "Close";
			
			ltfObjects.GoldLabel.TextEditable = false;
			ltfObjects.StatusLabel.Text = "Trade Complete!";
			ltfObjects.StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255);

			otfObjects.StatusLabel.Text = "Trade Complete!";
			otfObjects.StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255);

			setSlotColors(Color3.fromRGB(40, 60, 40));
		end

		if state <= 2 then
			if otherData.HasRewardCrates then
				otfObjects.StatusLabel.Text = "Restricted Items";
				otfObjects.StatusLabel.TextColor3 = Color3.fromRGB(255, 76, 76);

			elseif otherData.CantAffordTax then
				otfObjects.StatusLabel.Text = "Cant Afford Gold Tax";
				otfObjects.StatusLabel.TextColor3 = Color3.fromRGB(255, 76, 76);

			elseif otherData.NoSpace then
				otfObjects.StatusLabel.Text = "No Inventory Space";
				otfObjects.StatusLabel.TextColor3 = Color3.fromRGB(255, 76, 76);

			elseif otherData.Confirm then
				otfObjects.StatusLabel.Text = "Confirmed";
				otfObjects.StatusLabel.TextColor3 = Color3.fromRGB(93, 182, 87);

			elseif otherData.Money < binds.TradeSession.Fee then
				otfObjects.StatusLabel.Text = "Not Enough Money";
				otfObjects.StatusLabel.TextColor3 = Color3.fromRGB(255, 76, 76);

			else
				otfObjects.StatusLabel.Text = "Waiting For "..otherData.Name;
				otfObjects.StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255);

			end

		end
		
		if otherData.Message then
			otfObjects.StatusLabel.Text = otherData.Message;
			otfObjects.StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255);

		end

		for _, obj in pairs(itemButtonList) do
			local itemId = obj.ImageButton.Name;
			if itemButtonCaches[itemId] == nil then
				itemButtonList[itemId] = nil;
				obj:Destroy();
			end
		end
    end)

local confirmButtonDown = false;
	confirmButton.InputEnded:Connect(function(inputObject)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
			confirmButtonDown = false;
		end
	end)
	confirmButton.InputBegan:Connect(function(inputObject)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
			confirmButtonDown = true;
			if binds.TradeSession == nil then return end;
			local localData;
			for name, _ in pairs(binds.TradeSession.Players) do
				if name == localPlayer.Name then
					localData = binds.TradeSession.Players[localPlayer.Name];
					break;
				end
			end
			local isConfirmed = localData and localData.Confirm or false;

			local colorA, colorB, colorC = Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200), Color3.fromRGB(100, 100, 100);
			local color = {
				ColorSequenceKeypoint.new(0, colorA),
				ColorSequenceKeypoint.new(0.001, colorA),
				ColorSequenceKeypoint.new(0.002, colorB),
				ColorSequenceKeypoint.new(1, colorB)
			};
			confirmGradient.Color = ColorSequence.new(color);

			if isConfirmed then
				interface:PlayButtonClick();
				confirmButton.buttonText.Text = "Confirm";
				localData.Confirm = false;
				remoteTradeRequest:FireServer("unconfirm");

			elseif localData.Money < binds.TradeSession.Fee then
				confirmButton.buttonText.Text = "Not Enough Money";
				delay(1, function()
					confirmButton.buttonText.Text = "Confirm";
				end)

			elseif localData.CantAffordTax then
				confirmButton.buttonText.Text = "Cant Afford Gold Tax";
				delay(1, function()
					confirmButton.buttonText.Text = "Confirm";
				end)

			elseif localData.NoSpace then
				confirmButton.buttonText.Text = "No Inventory Space";
				delay(1, function()
					confirmButton.buttonText.Text = "Confirm";
				end)

			elseif localData.HasRewardCrates then
				confirmButton.buttonText.Text = "Restricted Items";
				delay(1, function()
					confirmButton.buttonText.Text = "Confirm";
				end)

			else

				local confirmTick = tick();
				local confirmTime = 0.5;
				local confirmDebounce = false;
				RunService:BindToRenderStep("ConfirmTrade", Enum.RenderPriority.Input.Value+1, function(delta)
					if not windowFrame.Visible then RunService:UnbindFromRenderStep("ConfirmTrade"); return end;
					local confirmPercent = math.clamp((tick()-confirmTick)/confirmTime, 0.001, 0.997);
					color[2] = ColorSequenceKeypoint.new(confirmPercent, colorA);
					color[3] = ColorSequenceKeypoint.new(confirmPercent+0.002, colorB);
					confirmGradient.Color = ColorSequence.new(color);
					if confirmPercent >= 0.997 and not confirmDebounce then
						confirmDebounce = true;
						interface:PlayButtonClick();
						RunService:UnbindFromRenderStep("ConfirmTrade");
						confirmButton.buttonText.Text = "Unconfirm";
						localData.Confirm = true;
						remoteTradeRequest:FireServer("confirm");
						color[2] = ColorSequenceKeypoint.new(0.001, colorA);
						color[3] = ColorSequenceKeypoint.new(0.002, colorC);
						color[4] = ColorSequenceKeypoint.new(1, colorC);
						confirmGradient.Color = ColorSequence.new(color);

					else
						confirmButton.buttonText.Text = "Hold To Confirm";
					end
					if not confirmButtonDown then
						color[2] = ColorSequenceKeypoint.new(0.001, colorA);
						color[3] = ColorSequenceKeypoint.new(0.002, colorB);
						confirmGradient.Color = ColorSequence.new(color);
						RunService:UnbindFromRenderStep("ConfirmTrade");
						delay(0.5, function()
							confirmButton.buttonText.Text = "Confirm";
						end)
					end
				end)
			end
		end
	end)

local function holdButton(button, label, onClick)
		local isButtonDown = false;
		
		button.buttonText.Text = label;
		
		local buttonGradiant = button:WaitForChild("UIGradient");
		
		button.InputEnded:Connect(function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
				isButtonDown = false;
			end
		end)
		button.InputBegan:Connect(function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
				isButtonDown = true;
				local _state = binds.TradeSession and binds.TradeSession.State;

				local colorA, colorB = Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200);
				local color = {
					ColorSequenceKeypoint.new(0, colorA),
					ColorSequenceKeypoint.new(0.001, colorA),
					ColorSequenceKeypoint.new(0.002, colorB),
					ColorSequenceKeypoint.new(1, colorB)
				};
				buttonGradiant.Color = ColorSequence.new(color);
				

				local clickTick = tick();
				local holdTime = 0.3;
				local debounce = false;
				RunService:BindToRenderStep(button.Name, Enum.RenderPriority.Input.Value+1, function(delta)
					if not windowFrame.Visible then RunService:UnbindFromRenderStep(button.Name); return end;
					local percent = math.clamp((tick()-clickTick)/holdTime, 0.001, 0.997);
					color[2] = ColorSequenceKeypoint.new(percent, colorA);
					color[3] = ColorSequenceKeypoint.new(percent+0.002, colorB);
					buttonGradiant.Color = ColorSequence.new(color);
					if percent >= 0.997 and not debounce then
						debounce = true;
						
						interface:PlayButtonClick();
						
						RunService:UnbindFromRenderStep(button.Name);
						button.buttonText.Text = label;
						
						onClick();
						
						color[2] = ColorSequenceKeypoint.new(0.001, colorA);
						color[3] = ColorSequenceKeypoint.new(0.002, colorC);
						color[4] = ColorSequenceKeypoint.new(1, colorC);
						buttonGradiant.Color = ColorSequence.new(color);
						
						debounce = false;
						
					else
						button.buttonText.Text = "Hold To "..label;
						
					end
					
					if not isButtonDown then
						color[2] = ColorSequenceKeypoint.new(0.001, colorA);
						color[3] = ColorSequenceKeypoint.new(0.002, colorB);
						buttonGradiant.Color = ColorSequence.new(color);
						RunService:UnbindFromRenderStep(button.Name);
						
						delay(0.5, function()
							button.buttonText.Text = label;
						end)
						
					end
				end)
			end
		end)
		
	end
	
	holdButton(pageButtons.nextButton, "Next", function()
		remoteTradeRequest:FireServer("inputevent", "dialognext");
	end);
	holdButton(pageButtons.backButton, "Back", function()
		remoteTradeRequest:FireServer("inputevent", "dialogback");
	end);
	
	pageButtons.pageInput.Focused:Connect(function()
		remoteTradeRequest:FireServer("inputevent", "pageInputFocused");
	end)
	pageButtons.pageInput.FocusLost:Connect(function()
		remoteTradeRequest:FireServer("inputevent", "pageInputFocusLost", pageButtons.pageInput.Text);
		pageButtons.pageInput.Text = "";
	end)
	
	
	local cancelButtonDown = false;
	cancelButton.InputEnded:Connect(function(inputObject)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
			cancelButtonDown = false;
		end
	end)
	cancelButton.InputBegan:Connect(function(inputObject)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
			cancelButtonDown = true;
			local state = binds.TradeSession and binds.TradeSession.State;

			local colorA, colorB = Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200);
			local color = {
				ColorSequenceKeypoint.new(0, colorA),
				ColorSequenceKeypoint.new(0.001, colorA),
				ColorSequenceKeypoint.new(0.002, colorB),
				ColorSequenceKeypoint.new(1, colorB)
			};
			cancelGradient.Color = ColorSequence.new(color);

			local tradeStorage = modData.Storages[localPlayer.Name.."Trade"];
			local hasItems = false;

			local function storageCheck()
				localStorageInterface:Update();
				otherStorageInterface:Update();
				if tradeStorage then
					for id, storageItem in pairs(tradeStorage.Container) do
						Debugger:Log("StorageItem in trade: ",storageItem);
						hasItems = true;
					end
				end
			end
			storageCheck();

			local function close()
				storageCheck();
				interface:PlayButtonClick();
				if not hasItems then
					window:Freeze(false);
                    interface:ToggleWindow("Trade", false);
					RunService:UnbindFromRenderStep("CancelTrade");
				else
					cancelButton.buttonText.Text = "Remove items!";
				end
			end

			if binds.TradeSession and binds.TradeSession.Ended then
				close();

			elseif state and state <= 2 then
				if not hasItems then
					local cancelTick = tick();
					local cancelTime = 0.5;
					local cancelDebounce = false;
					RunService:BindToRenderStep("CancelTrade", Enum.RenderPriority.Input.Value+1, function(delta)
						if not windowFrame.Visible then RunService:UnbindFromRenderStep("CancelTrade"); return end;
						local cancelPercent = math.clamp((tick()-cancelTick)/cancelTime, 0.001, 0.997);
						color[2] = ColorSequenceKeypoint.new(cancelPercent, colorA);
						color[3] = ColorSequenceKeypoint.new(cancelPercent+0.002, colorB);
						cancelGradient.Color = ColorSequence.new(color);
						if cancelPercent >= 0.997 and not cancelDebounce then
							cancelDebounce = true;
							close();
						else
							cancelButton.buttonText.Text = "Hold To Cancel";
						end
						if not cancelButtonDown then
							color[2] = ColorSequenceKeypoint.new(0.001, colorA);
							color[3] = ColorSequenceKeypoint.new(0.002, colorB);
							cancelGradient.Color = ColorSequence.new(color);
							RunService:UnbindFromRenderStep("CancelTrade");
							delay(0.5, function()
								cancelButton.buttonText.Text = "Cancel";
							end)
						end
					end)
				else
					cancelButton.buttonText.Text = "Remove items!";
				end
			else
				close();
			end
		end
	end)

	local prevGoldInput = nil;
	local function checkGoldInput()
		if binds.TradeSession == nil then
			ltfObjects.GoldLabel.Text = 0;
			return;
		end
		local playerGold = modData.Profile and modData.Profile.Trader and modData.Profile.Trader.Gold or 0;
		local inputNum = tonumber(ltfObjects.GoldLabel.Text) or 0;
		
		if binds.TradeSession and binds.TradeSession.IgnorePlayerGoldLimit == true then
			inputNum = math.clamp(inputNum, 0, math.huge);
			
		else
			inputNum = math.clamp(inputNum, 0, playerGold);
			
		end
		
		local state = binds.TradeSession.State;
		if state > 1 then
			local gold = binds.TradeSession.Players[localPlayer.Name].Gold; 
			ltfObjects.GoldLabel.Text = tostring(gold);
			return;
		end;
		
		ltfObjects.GoldLabel.Text = inputNum;

		if prevGoldInput ~= inputNum then
			prevGoldInput = inputNum;
			remoteTradeRequest:FireServer("setgold", ltfObjects.GoldLabel.Text);
		end
	end

	ltfObjects.GoldLabel:GetPropertyChangedSignal("Text"):Connect(function()
		checkGoldInput();
	end)

	ltfObjects.GoldLabel.FocusLost:Connect(checkGoldInput);

    interface.Garbage:Tag(modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
		if not windowFrame.Visible then return end;
        window:Update();
	end));
	
	interface.Garbage:Tag(function()
		table.clear(itemButtonList);
		itemButtonCaches = nil;
		itemToolTip:Destroy();
	end)
	
    function binds.updateTradeSessionData(data)
        if data == nil then
            binds.TradeSession = nil;
            return;
        end
        
        if binds.TradeSession == nil then
            binds.TradeSession = {};
        end
        modTables.ReplaceValues(binds.TradeSession, data);
    end

	interface.Garbage:Tag(remoteTradeRequest.OnClientEvent:Connect(function(requestType, ...)
		if requestType == "request" then
			local playerName = ...;
			modData.TradeRequests[playerName] = tick();
			
			interface:FireEvent("UpdateSocialMenu");
			
		elseif requestType == "tradesession" then
			local tradeSessionData = ...;

            binds.updateTradeSessionData(tradeSessionData);
            window:Update();
			
		elseif requestType == "syncgold" then
			local tradeSessionData = ...;
            
            local gold = tradeSessionData.Players[game.Players.LocalPlayer.Name].Gold;
            binds.SyncLocalGold(gold);
			
		elseif requestType == "init" then
			local tradeSessionData = ...;
        
            binds.updateTradeSessionData(tradeSessionData);
            interface:ToggleWindow("Trade", true);
            window:Update();
			
		elseif requestType == "end" then
			local tradeSessionData = ...;
            binds.updateTradeSessionData(tradeSessionData);
            window:Update();
			
		end
	end))


    task.spawn(function() 
		local tradeStorage = modData.Storages[localPlayer.Name.."Trade"];
		if tradeStorage and next(tradeStorage.Container) ~= nil then
			cancelButton.buttonText.Text = "Remove items!";
            interface:ToggleWindow("Trade", true);

			localStorageInterface:Update();
		end
	end)
end

return interfacePackage;

