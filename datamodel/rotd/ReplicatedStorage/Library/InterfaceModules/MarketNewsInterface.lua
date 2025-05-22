local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;
local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modNpcProfileLibrary = shared.require(game.ReplicatedStorage.Library.NpcProfileLibrary);

local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);
local modFormatNumber = shared.require(game.ReplicatedStorage.Library.FormatNumber);
local modGoldShopLibrary = shared.require(game.ReplicatedStorage.Library.GoldShopLibrary);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);

local remotes = game.ReplicatedStorage.Remotes;
local remoteTradeRequest = modRemotesManager:Get("TradeRequest");
local remoteLimitedService = modRemotesManager:Get("LimitedService");
	
local windowFrameTemplate = script:WaitForChild("MarketNews");
local itemListingFrame = script:WaitForChild("itemListingFrame");

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	local windowFrame = windowFrameTemplate:Clone();
	windowFrame.Parent = modInterface.MainInterface;
	
	local contentList = windowFrame:WaitForChild("ScrollingFrame");
	local scrollingTextFrame = windowFrame:WaitForChild("ScrollingTextFrame");
	local scrollingTextLabel = scrollingTextFrame:WaitForChild("label");
	local uiPadding = scrollingTextLabel:WaitForChild("UIPadding");
	
	scrollingTextLabel:GetPropertyChangedSignal("Text"):Connect(function()
		task.wait(5);
		scrollingTextLabel.Active = true;
	end)
	
	local window = Interface.NewWindow("MarketNewspaper", windowFrame);
	if modConfigurations.CompactInterface then
		windowFrame.Size = UDim2.new(1, 0, 1, 0);
		
		windowFrame:WaitForChild("touchCloseButton").Visible = true;
		windowFrame:WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
			window:Close();
		end)
	end
	window.CompactFullscreen = true;
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1, 0));
	window:AddCloseButton(windowFrame);
	
	local itemMarketList;
	local cache = {
		TopDonor = nil;
	};
	
	window.OnWindowToggle:Connect(function(visible, toolHandler)
		if visible then
			Interface:HideAll{[window.Name]=true;};
			
			local storageItem = toolHandler and toolHandler.StorageItem and toolHandler.StorageItem.ID and modData.GetItemById(toolHandler.StorageItem.ID) or nil;

			if storageItem == nil then
				window:Close();
				return;
			end;

			remoteTradeRequest:FireServer("marketrequest", storageItem.ID);
			
			task.spawn(function()
				cache.LimitedCache = remoteLimitedService:InvokeServer("fetch");
			end)
			task.spawn(function()
				local secTimer = tick();
				while window.Visible do
					local delta = task.wait();
					
					if scrollingTextLabel.Active then
						if scrollingTextFrame.AbsoluteCanvasSize.X > scrollingTextFrame.AbsoluteWindowSize.X then
							scrollingTextFrame.CanvasPosition = scrollingTextFrame.CanvasPosition + Vector2.new(3 * delta, 0);
						end
					end;
					
					if tick()-secTimer >= 20 then
						secTimer = tick();
						remoteTradeRequest:FireServer("marketrequest", storageItem.ID);
					end
				end
			end)
		end
	end)
	
	function Interface.Update()
		for _, obj in pairs(contentList:GetChildren()) do
			if obj:IsA("GuiObject") then
				game.Debris:AddItem(obj, 0);
			end
		end
		
		if itemMarketList then
			for a=#itemMarketList, 1, -1 do
				local itemInfo = itemMarketList[a];

				local new = itemListingFrame:Clone();
				local slot = new:WaitForChild("Slot");
				local label = new:WaitForChild("label");
				new.Parent = contentList;
				
				local quantity = itemInfo.Quantity or 1;
				local priceEach = math.round(itemInfo.Gold/quantity *10)/10;
				label.Text = "traded for <b><font color='rgb(255, 214, 112)'>".. modFormatNumber.Beautify(priceEach) .." Gold".. (quantity > 1 and " each" or "") .."</font></b>"
				
				local costDiff = math.round(((itemInfo.Gold/(quantity))-itemInfo.AverageCost)/itemInfo.AverageCost * 100)/100;
				if math.abs(costDiff) > 0.01 then
					local greenHex = "#8bff8f";
					local redHex = "#d6595b";
					label.Text = label.Text.." <b><font size='12' color='"..(costDiff >= 0 and greenHex or redHex).."'>(".. math.round(costDiff*1000)/10 .."%)</font></b>";
				end
				
				local itemId = itemInfo.ItemId or "t1key";

				local itemButtonObj = modItemInterface.newItemButton(itemId);
				itemButtonObj.ImageButton.Parent = slot;

				local storageItem = {
					ItemId = itemId;
					Values = itemInfo.ItemValues;
					Quantity = itemInfo.Quantity;
				}

				itemButtonObj:Update(storageItem);
			end
		end
		
		
		--== headlines
		local headlineList = {};
		
		if modBranchConfigs.Wanderer ~= nil then
			local npcProfileLib = modNpcProfileLibrary:Find(modBranchConfigs.Wanderer.Name);
			
			local str = "Wanderer ".. npcProfileLib.Class 
				..", <b><font color='#".. modNpcProfileLibrary.ClassColors[npcProfileLib.Class]:ToHex()
				.."'>".. modBranchConfigs.Wanderer.Name 
				.."</font></b>, was recently spotted in <b>".. modBranchConfigs.GetWorldDisplayName(modBranchConfigs.Wanderer.WorldId)
				.."</b>."
			table.insert(headlineList, str);
		end
		
		if cache.TopDonor then
			local str = "The top donor this week is <b>".. cache.TopDonor.Name
				.."</b> by donating up to <font color='rgb(170, 120, 0)'>"..cache.TopDonor.Value.."</font> Gold!."
			table.insert(headlineList, str);
		end
		
		if cache.LimitedCache then
			local strList = {};
			
			local sortedList = {};
			for limitedId, stock in pairs(cache.LimitedCache) do
				table.insert(sortedList, {Id=limitedId; Stock=stock;});
			end
			
			if #sortedList > 0 then
				table.sort(sortedList, function(a, b) return a.Stock > b.Stock; end);

				for a=1, #sortedList do
					local limitedLib = sortedList[a];
					local productLib = modGoldShopLibrary.Products:FindByKeyValue("LimitedId", limitedLib.Id);
					local itemLib = productLib and modItemsLibrary:Find(productLib.Product.ItemId);
					
					if productLib and itemLib then
						if limitedLib.Stock > 50 then
							table.insert(strList, limitedLib.Stock.." <b>".. itemLib.Name.."</b> limiteds on sale.");
							
						elseif limitedLib.Stock > 10 then
							table.insert(strList, "<b>"..itemLib.Name.."</b> only has <font color='#ff7631'>".. limitedLib.Stock .."</font> left in stock!");
							
						elseif limitedLib.Stock <= 0 then
							table.insert(strList, "<b>"..itemLib.Name.."</b> is now sold out.");
							
						end
					end
				end


				table.insert(headlineList, table.concat(strList, ", "));
			end
		end
		
		
		if #headlineList > 0 then
			scrollingTextFrame.CanvasPosition = Vector2.zero;
			scrollingTextLabel.Active = false;
			scrollingTextLabel.Text = "<b><font size='18'>Headline:</font></b>  ".. headlineList[math.random(1, #headlineList)];
		end
	end
	
	Interface.Garbage:Tag(remoteTradeRequest.OnClientEvent:Connect(function(requestType, ...)
		if requestType == "marketrequest" then
			local iML = ...;
			if iML ~= nil then
				itemMarketList = iML;
			end
			
		elseif requestType == "wandererrequest" then
			local wanderer = ...;
			if wanderer ~= nil then
				modBranchConfigs.Wanderer = wanderer;
			end
			
		elseif requestType == "topdonorrequest" then
			local topDonor = ...;
			if topDonor ~= nil then
				cache.TopDonor = topDonor;
			end
			
		end
		
		
		Interface.Update();
	end));
	
	return Interface;
end;

return Interface;