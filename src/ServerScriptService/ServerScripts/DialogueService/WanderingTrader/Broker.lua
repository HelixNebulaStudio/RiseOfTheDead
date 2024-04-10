local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local ListingStates = {
	Idle=0;
	Purchased=1;
	Expired=2;
}
local ListingActions = {
	Unlist=0;
	ClaimSales=1;
}

local BrokerLimit = {
	MinGold=500;
	MaxGold=100000;
}

local markUpPercent = 0.1;

local brokeringIncludeList = {
	["cannedbeans"] = true;
	["chocobar"] = true;
	
	["metalpackage"] = true;
	["glasspackage"] = true;
	["woodpackage"] = true;
	["clothpackage"] = true;
	
	["metalpipes"] = true;
	["igniter"] = true;
	["gastank"] = true;
	 
	["steelfragments"] = true;
	["gears"] = true;
	
	["advmedkit"] = true;
}
---==
local HttpService = game:GetService("HttpService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGoldShopLibrary = require(game.ReplicatedStorage.Library.GoldShopLibrary);
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modSerializer = require(game.ReplicatedStorage.Library.Serializer);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);

local modRichFormatter = require(game.ReplicatedStorage.Library.UI.RichFormatter);

local modDatabaseService = Debugger:Require(game.ServerScriptService.ServerLibrary.DatabaseService);
local modTradingService = Debugger:Require(game.ServerScriptService.ServerLibrary.TradingService);
local modAnalytics = Debugger:Require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modEvents = Debugger:Require(game.ServerScriptService.ServerLibrary.Events);
local modServerManager = Debugger:Require(game.ServerScriptService.ServerLibrary.ServerManager);

--local brokerReceiptDatastore = game:GetService("DataStoreService"):GetDataStore("BrokerReceipt");


--===
local serializer = modSerializer.new();
local tradersMarketDatabase = modDatabaseService:GetDatabase("TradersMarket");
local brokerLogsDatabase = modDatabaseService:GetDatabase("BrokerLogs");

local TradersMarket = {};
TradersMarket.ClassType = "TradersMarket";

function TradersMarket.new()
	local self = {
		UserId=0;
		UserName="~";
		IsPremium=false;
		
		TradeNumber=0;
		Listing={};
	};
	
	setmetatable(self, TradersMarket);
	return self;
end


--== serializer
serializer:AddClass(TradersMarket.ClassType, TradersMarket.new);
tradersMarketDatabase:BindSerializer(serializer);

tradersMarketDatabase:OnUpdateRequest("load", function(requestPacket)
	local tradersMarket = requestPacket.Data or TradersMarket.new();
	local inputValues = requestPacket.Values; 
	
	tradersMarket.UserId = inputValues.UserId;
	tradersMarket.UserName = inputValues.UserName;
	tradersMarket.IsPremium = inputValues.IsPremium == true;

	return tradersMarket;
end)

tradersMarketDatabase:OnUpdateRequest("newlisting", function(requestPacket)
	local tradersMarket = requestPacket.Data;
	local inputValues = requestPacket.Values; 
	
	if tradersMarket == nil then
		requestPacket.FailMsg = "Trader's data unavailable.";
		return nil;
	end
	
	tradersMarket.TradeNumber = tradersMarket.TradeNumber +1;

	local goldAdd = math.ceil(inputValues.Gold * (markUpPercent)/100) * 100;
	
	local tradeKey = tradersMarket.UserId.."#"..tradersMarket.TradeNumber;
	local tradePacket = {
		Tick=DateTime.now().UnixTimestampMillis;
		TradeKey = tradeKey;
		
		GoldPrice=inputValues.Gold;
		Items=inputValues.Items;
		
		WandererPrice = inputValues.Gold + goldAdd;
		
		State=ListingStates.Idle;
	};
	
	table.insert(tradersMarket.Listing, tradePacket);
	requestPacket.TradePacket = tradePacket;
	
	return tradersMarket;
end)

tradersMarketDatabase:OnUpdateRequest("removelisting", function(requestPacket)
	local tradersMarket = requestPacket.Data;
	local inputValues = requestPacket.Values; 
	local actionId = inputValues.Action;

	if tradersMarket == nil then
		requestPacket.FailMsg = "Trader's data unavailable.";
		return nil;
	end
	
	local exist = false;
	local tradeKey = inputValues.TradeKey;
	
	for a=#tradersMarket.Listing, 1, -1 do
		local tradePacket = tradersMarket.Listing[a]
		if tradePacket.TradeKey == tradeKey then
			
			if actionId == ListingActions.Unlist and tradePacket.State == ListingStates.Purchased then
				requestPacket.FailMsg = "Listing has been purchased.";
				return nil;
			end
			if actionId == ListingActions.ClaimSales and tradePacket.State ~= ListingStates.Purchased then
				requestPacket.FailMsg = "Listing sales is not claimable.";
				return nil;
			end
			
			table.remove(tradersMarket.Listing, a);
			exist = true;
		end
	end
	
	if exist == false then
		requestPacket.FailMsg = "Listing does not exist anymore.";
		return nil;
	end
	
	return tradersMarket;
end)

tradersMarketDatabase:OnUpdateRequest("updatelisting", function(requestPacket)
	local tradersMarket = requestPacket.Data;
	local inputValues = requestPacket.Values; 

	if tradersMarket == nil then
		requestPacket.FailMsg = "Trader's data unavailable.";
		return nil;
	end

	local tradeKey = inputValues.TradeKey;
	
	local exist = false;
	for a=#tradersMarket.Listing, 1, -1 do
		if tradersMarket.Listing[a].TradeKey == tradeKey then
			local listing = tradersMarket.Listing[a];
			
			listing.State = inputValues.State;
			
			if inputValues.State == ListingStates.Purchased and inputValues.GoldPaid >= tradersMarket.Listing[a].WandererPrice then
				listing.BuyerName = inputValues.BuyerName;
				listing.BuyerUserId = inputValues.BuyerUserId;
				listing.GoldPaid = inputValues.GoldPaid;
				
			end
			
			exist = true;
			break;
		end
	end

	if exist == false then
		requestPacket.FailMsg = "Listing does not exist anymore.";
		return nil;
	end

	return tradersMarket;
end)


-- globallist;
tradersMarketDatabase:OnUpdateRequest("addgloballisting", function(requestPacket)
	local tradersMarket = requestPacket.Data or TradersMarket.new(requestPacket.Key);
	local inputValues = requestPacket.Values; 


	local tradePacket = inputValues.TradePacket;
	tradePacket.UserId = inputValues.UserId;
	tradePacket.UserName = inputValues.UserName;
	
	for a=#tradersMarket.Listing, 1, -1 do
		if tradersMarket.Listing[a].TradeKey == tradePacket.TradeKey then
			table.remove(tradersMarket.Listing, a);
		end
	end
	table.insert(tradersMarket.Listing, tradePacket);
	
	return tradersMarket;
end)

tradersMarketDatabase:OnUpdateRequest("removegloballisting", function(requestPacket)
	local tradersMarket = requestPacket.Data or TradersMarket.new(requestPacket.Key);
	local inputValues = requestPacket.Values; 

	local tradeKey = inputValues.TradeKey;
	for a=#tradersMarket.Listing, 1, -1 do
		if tradersMarket.Listing[a].TradeKey == tradeKey then
			table.remove(tradersMarket.Listing, a);
		end
	end

	return tradersMarket;
end)

tradersMarketDatabase:OnUpdateRequest("purchasegloballisting", function(requestPacket)
	local tradersMarket = requestPacket.Data or TradersMarket.new(requestPacket.Key);
	local inputValues = requestPacket.Values; 

	local tradeKey = inputValues.TradeKey;
	local goldPaid = inputValues.GoldPaid;
	local exist = false;
	
	for a=#tradersMarket.Listing, 1, -1 do
		if tradersMarket.Listing[a].TradeKey == tradeKey and goldPaid >= tradersMarket.Listing[a].GoldPrice then
			table.remove(tradersMarket.Listing, a);
			exist = true;
			
			break;
		end
	end
	
	if exist == false then
		requestPacket.FailMsg = "Listing no longer exist on global";
	end
	
	return tradersMarket;
end)


brokerLogsDatabase:OnUpdateRequest("log", function(requestPacket)
	local logs = requestPacket.RawData or {}; -- No Data because this is not using a serializable class;
	local inputValues = requestPacket.Values;
	
	table.insert(logs, inputValues);
	Debugger:Warn("New broker log ", #logs);
	
	return logs;
end)

local function debugLogBroker(logPacket)
	task.spawn(function()
		local returnPacket = brokerLogsDatabase:UpdateRequest("logs", "log", logPacket);
		if returnPacket.Success ~= true then
			Debugger:Warn("Failed to broker log.");
		end
	end)
end

--==
local oneWeekSecs = 86400*7;
return function(player, dialog, data)
	if modServerManager.ShadowBanned then return end;

	local profile = shared.modProfile:Get(player);
	local playerSave = profile:GetActiveSave();
	local traderProfile = profile and profile.Trader;
	local inventory = playerSave.Inventory;
	local playerLevel = playerSave and playerSave:GetStat("Level") or 1;

	local npcName = dialog.Name;
	local traderMem = modDatabaseService:GetDatabase(npcName);
	
	local sellDisabled = nil;
	local brokerEnabled = traderMem:Get("BrokerEnabled");
	Debugger:Warn("brokerEnabled", brokerEnabled);
	if player.UserId == 16170943 then
		sellDisabled = nil;
		Debugger:Warn("Owner brokerEnabled bypass");
		
	elseif brokerEnabled ~= true then
		sellDisabled = "Sorry, I'm off work from brokering at the moment. (Brokering Disabled)";
		
	elseif profile.Premium ~= true then
		sellDisabled = "Sorry, you're not qualified to do this. (Requires Premium)"; --Nonpremium tax can be ignore since premium only feature.
		
	elseif playerLevel <= 350 then
		sellDisabled = "If we were to do business, I'll have to know you for longer. (Requires Mastery Level 350)";

	elseif profile.TrustLevel <= 30 then
		sellDisabled = "Sorry, I just don't trust you enough yet to sell your stuff, maybe someday. (Requires Playtime)";
		
	end
	
	local function existInBrokerEventLog(tradeKey, state)
		local brokerLog = modEvents:GetEvent(player, "BrokerLog");
		
		if brokerLog == nil or #brokerLog.Logs <= 0 then
			return false;
		end
		
		local exist = false;
		for a=1, #brokerLog.Logs do
			if brokerLog.Logs[a].TradeKey == tradeKey and brokerLog.Logs[a].State == state then
				exist = true;
				break;
			end
		end
		
		return exist;
	end
	
	local function addToBrokerEventLog(state, tradePacket)
		local brokerLog = modEvents:GetEvent(player, "BrokerLog") or {Id="BrokerLog"; Logs={}};
		
		local unixTime = DateTime.now().UnixTimestampMillis;
		
		for a=#brokerLog.Logs, 1, -1 do
			if (unixTime-brokerLog.Logs[a].UnixTime) > oneWeekSecs then
				table.remove(brokerLog.Logs, a);
			end
		end
		
		local tradeKey = tradePacket.TradeKey;
		local logPacket = {
			UnixTime=unixTime;
			TradeKey=tradeKey;
			State=state;
			TradePacket=tradePacket;
		}
		table.insert(brokerLog.Logs, logPacket);
		
		modEvents:NewEvent(player, brokerLog);
		-- logPacket
	end
	
	
	local function enterBrokerFunc(dialog)
		local userKey = tostring(profile.UserId);
		local returnPacket = tradersMarketDatabase:UpdateRequest(userKey, "load", {
			UserId=profile.UserId;
			UserName=player.Name;
			IsPremium=profile.Premium;
		});
		
		if returnPacket.Success ~= true then
			dialog:AddDialog({
				Face="Skeptical";
				Dialogue="Well?";
				Reply="Hold on, I'm still looking for my ledger, come back later..";
			});
			
			return;
		end
		
		local tradersMarket = returnPacket.Data;
		local maxListing = tradersMarket.IsPremium and 5 or 2;
		
		--if #tradersMarket.Listing < maxListing then
			
		--	local function listSaleDialog(dialog)
		--		local tradingSession = modTradingService:NewComputerSession(player, npcName);
		--		if tradingSession == nil then return end;

		--		tradingSession.IgnorePlayerGoldLimit = true;
		--		tradingSession.IgnorePlayerInventoryFull = true;
				
		--		local npcTradeStorage = tradingSession.Storages[npcName];

		--		local validTrade = false;
		--		local state = 0;

		--		tradingSession:SetData(npcName, "HideStorage", true);
		--		tradingSession:SetData(npcName, "HideGold", true);

		--		tradingSession:BindConfirmSet(function(self, playerObj)
		--			if playerObj.Confirm then
		--				if validTrade then
		--					tradingSession:SetData(npcName, "Message", "Alright, let's see what we have here..");
		--					tradingSession:SetConfirm(npcName, true);

		--				else
		--					if state == 0 then
		--						tradingSession:SetData(npcName, "Message", "??");

		--					elseif state == 1 then
		--						tradingSession:SetData(npcName, "Message", "You need to tell me how much you want to sell those for..");

		--					elseif state == 2 then
		--						tradingSession:SetData(npcName, "Message", "You can't sell nothing for gold silly.");

		--					elseif state == 4 then
		--						tradingSession:SetData(npcName, "Message", "I'm not helping you sell your cheap junk.");

		--					end

		--				end

		--				tradingSession:Sync("tradesession");

		--			else
		--				tradingSession:SetConfirm(npcName, false);
		--				if tradingSession.State == 2 then
		--					tradingSession:SetData(npcName, "Message", "What's wrong?");
		--					tradingSession:Sync("tradesession");
		--				end

		--			end
		--		end)

		--		local function onTradeUpdate(self, playerObj)
		--			validTrade = false;
		--			state = 0;
					
		--			tradingSession:SetData(npcName, "Gold", 0);
		--			npcTradeStorage:Wipe();

		--			local playerStorage = tradingSession.Storages[player.Name]; -- player trade-storage
		--			local playerGoldInput = playerObj.Gold;

		--			local hasContraBand = nil;
		--			local notIncludedList = false;

		--			local totalQuantity = 0;
		--			local itemCount = playerStorage:Loop(function(storageItem)
		--				totalQuantity = totalQuantity + storageItem.Quantity;

		--				if modItemsLibrary:HasTag(storageItem.ItemId, "Unobtainable") then
		--					local itemLib = modItemsLibrary:Find(storageItem.ItemId);
		--					hasContraBand = itemLib.Name;
		--				end
						
		--				if brokeringIncludeList[storageItem.ItemId] == nil then
		--					notIncludedList = true;
		--				end
		--			end);
					
		--			if itemCount > 0 then
		--				state = 1;

		--			end
					
		--			if playerGoldInput > 0 then
		--				state = (state == 1) and 3 or 2;

		--				if playerGoldInput < BrokerLimit.MinGold then
		--					state = 4;
							
		--				elseif playerGoldInput > BrokerLimit.MaxGold then
		--					state = 6;
							
		--				end
		--			end

		--			if hasContraBand ~= nil then
		--				state = 5;
		--			end

		--			if notIncludedList == true then
		--				state = 9;
		--			end


		--			if state == 0 then
		--				tradingSession:SetData(npcName, "Message", "Put the items you want to list for sale on the table and for what price.");

		--			elseif state == 1 then
		--				tradingSession:SetData(npcName, "Message", "Okay, ".. totalQuantity
		--					.. (totalQuantity == 1 and " item" or " items")..".. How much "..modRichFormatter.GoldText("Gold").." do you want to sell it for?");

		--			elseif state == 2 then
		--				tradingSession:SetData(npcName, "Message", "What are you listing to be sold for "..modRichFormatter.GoldText( modFormatNumber.Beautify(playerGoldInput) .." Gold").."?");

		--			elseif state == 3 then
		--				local wandererPrice = playerGoldInput + math.ceil(playerGoldInput * (markUpPercent)/100)*100;
		--				local wandererMarkup = "I'll try to sell it for ~"..modRichFormatter.GoldText( modFormatNumber.Beautify(wandererPrice) .." Gold").." excluding tax.";
		--				tradingSession:SetData(npcName, "Message", "So, you want to list <b>"..totalQuantity.. " ".. (totalQuantity == 1 and "item" or "items") 
		--					.."</b> for <b>"..modRichFormatter.GoldText( modFormatNumber.Beautify(playerGoldInput) .." Gold").."</b>?"
		--					.."\n"..wandererMarkup);
		--				validTrade = true;

		--			elseif state == 4 then
		--				tradingSession:SetData(npcName, "Message", "Sorry, bud, I'm not helping you sell that for less than "..modRichFormatter.GoldText(modFormatNumber.Beautify(BrokerLimit.MinGold) .." Gold"));

		--			elseif state == 5 then
		--				tradingSession:SetData(npcName, "Message", "Is that a <b>contraband</b> I see? I can't help you sell the <b>".. hasContraBand .."</b>.");

		--			elseif state == 6 then
		--				tradingSession:SetData(npcName, "Message", "That's way too overpriced, I can't sell that for you.");

		--			elseif state == 9 then
		--				tradingSession:SetData(npcName, "Message", "I'm only brokering basic resources at the moment, I'll need a permit from the Rats before I can start brokering other items.");

		--			end

		--			tradingSession:Sync("tradesession");
		--			tradingSession:BindOnExchange(function()
		--				local listingPrice = playerObj.Gold;
		--				local listingItems = {};

		--				local nIndex = 0;
		--				local taxCost = 0;
		--				playerStorage:Loop(function(storageItem)
		--					nIndex = nIndex +1;
		--					storageItem.Index = nIndex;
		--					table.insert(listingItems, storageItem);

		--					local itemLib = modItemsLibrary:Find(storageItem.ItemId);
		--					local itemTax = itemLib.TradingTax or 0;
		--					if itemTax > 0 then
		--						taxCost = taxCost + (itemTax * storageItem.Quantity);
		--					end
		--				end)

		--				local returnPacket = tradersMarketDatabase:UpdateRequest(userKey, "newlisting", {
		--					Gold=listingPrice;
		--					Items=listingItems;
		--				});

		--				if returnPacket.Success then
		--					playerObj.Gold = 0;
		--					tradingSession.Fee = 0;
		--					playerStorage:Wipe();

		--					local tradePacket = returnPacket.TradePacket;
							
		--					tradingSession:SetData(npcName, "Message", "Listed <b>"..totalQuantity.. " ".. (totalQuantity == 1 and "item" or "items") 
		--						.."</b> for <b>"..modRichFormatter.GoldText(modFormatNumber.Beautify(tradePacket.WandererPrice + taxCost) .." Gold")
		--						..(taxCost > 0 and " + Tax" or "").."</b>.\n\nCome back later to see if anyone bought your items.");

		--					-- after submitting to save;
		--					task.spawn(function()
		--						local globalReturnPacket = tradersMarketDatabase:UpdateRequest("all", "addgloballisting", {
		--							UserId=player.UserId;
		--							UserName=player.Name;
		--							TradePacket=tradePacket;
		--						});
								
		--						--if globalReturnPacket.Success then
		--						--	Debugger:Warn("removegloballisting Success tradePacket", tradePacket);
		--						--	debugLogBroker({
		--						--		Type="ListTrade";
		--						--		UserId=profile.UserId;
		--						--		Name=profile.Name;
		--						--		TradePacket=tradePacket;
		--						--	});
									
		--						--else
		--						--	Debugger:Warn("removegloballisting failed tradePacket", tradePacket, " failMsg", globalReturnPacket.FailMsg);
		--						--end
		--					end)

		--				else
		--					tradingSession:SetData(npcName, "Message", "Hmmm, my inventory seems to be full at the moment.. (Error: ".. tostring(returnPacket.FailMsg) ..")");
		--					tradingSession.Cancelled = true;
		--					Debugger:WarnClient(player, "Error: ", returnPacket);
							
		--				end

		--				tradingSession:Sync("tradesession");
		--			end);
		--		end


		--		tradingSession:BindGoldUpdate(onTradeUpdate);
		--		tradingSession:BindStorageUpdate(onTradeUpdate);

		--		tradingSession:Sync("tradesession", true);
		--	end
			
		--	-- -- Listing sales;
		--	dialog:AddDialog({
		--		Face="Skeptical";
		--		Dialogue="I got some items to list for sale.";
		--		Reply="Let me see them.";
		--		ToggleWindow="Trade";

		--	}, listSaleDialog)
		--	-- -- Listing sales;
			
		--else
		--	dialog:AddDialog({
		--		Face="Skeptical";
		--		Dialogue="I got some items to list for sale.";
		--		Reply=(
		--			tradersMarket.IsPremium 
		--			and "You already have ".. #tradersMarket.Listing .. "/5 listed."
		--			or "You already have ".. #tradersMarket.Listing .. "/2 listed. (Acquire Premium to increase limit to 5)"
		--		);
		--	});
			
		--end
		
		
		--== checkSaleDialog
		if #tradersMarket.Listing > 0 then
			
			local function checkSaleDialog(dialog)
				local tradingSession = modTradingService:NewComputerSession(player, npcName);
				if tradingSession == nil then return end;

				local playerTradeStorage = tradingSession.Storages[player.Name];
				playerTradeStorage.Locked = true;
				
				local npcTradeStorage = tradingSession.Storages[npcName];

				local validTrade = false;
				local state = 0;

				tradingSession:SetData(npcName, "HideGold", true);
				tradingSession:SetData(npcName, "AddPageButtons", true);

				tradingSession.Page = 1;
				tradingSession.MaxPage = #tradersMarket.Listing;

				local function updatePost()
					local tradePacket = tradersMarket.Listing[tradingSession.Page];
					
					tradingSession:SetData(npcName, "Gold", 0);
					npcTradeStorage:Wipe();
					
					if tradePacket == nil then
						tradingSession:SetData(npcName, "Message", "You've got nothing listed.");
						tradingSession:Sync("tradesession");
						return;
					end
					
					Debugger:Warn(tradingSession.Page, "tradePacket", tradePacket);
					
					local taxCost = 0;
					for a=1, #tradePacket.Items do
						local storageItem = tradePacket.Items[a];
						
						local itemLib = modItemsLibrary:Find(storageItem.ItemId);
						local itemTax = itemLib.TradingTax or 0;
						if itemTax > 0 then
							taxCost = taxCost + (itemTax * storageItem.Quantity);
						end
						
						npcTradeStorage:Insert{ItemId=storageItem.ItemId; Data={Values=storageItem.Values; Quantity=storageItem.Quantity;}};
					end
					

					if tradePacket.State == ListingStates.Purchased then
						local pageText = "\n\n<font size='14'>"
							.."\n<b>[Confirm]</b> Collect Gold</font>";
						
						tradingSession:SetData(npcName, "Message", "<b>"..tradePacket.BuyerName.."</b> has bought your items for "
							..modRichFormatter.GoldText(tradePacket.GoldPrice.." Gold").."."..pageText);
						
						
					elseif tradePacket.State == ListingStates.Expired then
						local pageText = "\n\n<font size='14'>"
							.."\n<b>[Confirm]</b> Unlist Trade</font>";
						tradingSession:SetData(npcName, "Message", "This listing has expired."..pageText);
						
						
					else
						local pageText = "\n\n<font size='14'>"
							.."\n<b>[Confirm]</b> Unlist Trade</font>";
						if #tradePacket.Items == 1 then
							local storageItem = tradePacket.Items[1];
							local itemLib = modItemsLibrary:Find(storageItem.ItemId);

							tradingSession:SetData(npcName, "Message", 
								(storageItem.Quantity > 1 and storageItem.Quantity or "A")
									.." <b>".. itemLib.Name .. "</b> for "..modRichFormatter.GoldText(modFormatNumber.Beautify(tradePacket.GoldPrice).." Gold")
									..(taxCost > 0 and " + Tax" or "")
									.."."..pageText);

						else
							tradingSession:SetData(npcName, "Message", "This bundle of items for "..modRichFormatter.GoldText(modFormatNumber.Beautify(tradePacket.GoldPrice).." Gold")
								..(taxCost > 0 and " + Tax" or "")
								.."."..pageText);

						end
						
					end


					tradingSession:Sync("tradesession");
				end

				tradingSession:BindConfirmSet(function(self, playerObj)

					if playerObj.Confirm then
						local tradePacket = tradersMarket.Listing[tradingSession.Page];
						local tradeKey = tradePacket.TradeKey;
						if tradeKey == nil then
							tradingSession:SetData(npcName, "Message", "Hmmm?");
							return
						end;

						if tradePacket.State == ListingStates.Purchased then -- claim sales gold;
							local returnPacket = tradersMarketDatabase:UpdateRequest(userKey, "removelisting", {
								TradeKey=tradeKey;
								Action=ListingActions.ClaimSales;
							});

							if returnPacket.Success then -- claim sales gold;
								Debugger:Warn("Removelisting  (",userKey,") success, TradeKey:", tradeKey);
								
								if modGlobalVars.IsCreator(player) == false then
									if existInBrokerEventLog(tradeKey, "removelisting") == true then
										tradingSession:SetData(npcName, "Message", "Hmmm, something went wrong.. (Error: Action Already Done)");
										tradingSession.Cancelled = true;
										tradingSession:Sync("tradesession");
										return;
									end
									addToBrokerEventLog("removelisting", tradePacket);
								else
									Debugger:Warn("Skipping local check");
								end
								
								traderProfile:AddGold(tradePacket.GoldPrice);
								shared.Notify(player, "You recieved ".. tradePacket.GoldPrice .. " Gold from "..npcName, "Positive");

								task.spawn(function()
									modAnalytics.RecordResource(player.UserId, tradePacket.GoldPrice, "Source", "Gold", "Trade", "Broker");
								end)

								tradersMarket = returnPacket.Data;

								if #tradersMarket.Listing > 0 then
									tradingSession.MaxPage = #tradersMarket.Listing;
									tradingSession.Page = math.clamp(tradingSession.Page, 1, tradingSession.MaxPage);

								end
								
								updatePost();
							else
								tradingSession:SetData(npcName, "Message", "Hmmm, something went wrong.. (Error:".. tostring(returnPacket.FailMsg) ..")");
								Debugger:WarnClient(player, "Error: ",returnPacket);
							end

						else  -- unlist items from listing;

							local hasSpace = inventory:SpaceCheck(tradePacket.Items);
							if hasSpace then
								if tradePacket.State == ListingStates.Expired then
									tradingSession:SetData(npcName, "Message", "Alright, returning your items..");
									tradingSession:SetConfirm(npcName, true);

								else
									tradingSession:SetData(npcName, "Message", "Alright, taking this off the market..");
									tradingSession:SetConfirm(npcName, true);
								end
							else
								tradingSession:SetData(npcName, "Message", "Your inventory is pretty full to collect this..");
								tradingSession:SetConfirm(npcName, false);
								
							end
							
						end
						tradingSession:Sync("tradesession");

					else
						tradingSession:SetConfirm(npcName, false);
						if tradingSession.State == 2 then
							tradingSession:SetData(npcName, "Message", "Changed your mind ey?");
							tradingSession:Sync("tradesession");
						end

					end
				end)

				tradingSession:BindInputEvents(function(action)
					local oldPage = tradingSession.Page;
					if action == "dialognext" then
						tradingSession.Page = math.clamp(tradingSession.Page +1, 1, tradingSession.MaxPage);

					elseif action == "dialogback" then
						tradingSession.Page = math.clamp(tradingSession.Page -1, 1, tradingSession.MaxPage);

					end

					updatePost();
				end)


				tradingSession:BindOnExchange(function()
					local tradePacket = tradersMarket.Listing[tradingSession.Page];
					local tradeKey = tradePacket.TradeKey;

					if modGlobalVars.IsCreator(player) == false then
						if existInBrokerEventLog(tradeKey, "removelisting") == true then
							tradingSession:SetData(npcName, "Message", "Hmmm, something went wrong.. (Error: Action Already Done)");
							tradingSession.Cancelled = true;
							tradingSession:Sync("tradesession");
							return;
						end
						addToBrokerEventLog("removelisting", tradePacket);
					else
						Debugger:Warn("Skipping local check");
					end
					
					local returnPacket = tradersMarketDatabase:UpdateRequest(userKey, "removelisting", {
						TradeKey=tradeKey;
						Action=ListingActions.Unlist;
					});
					Debugger:Warn("remove listing", tradeKey);
					
					if tradePacket.State == ListingStates.Purchased then
						
					else
						if returnPacket.Success then
							Debugger:Warn("Removelisting (",userKey,") success, TradeKey:", tradeKey, " TradePacket State:", tradePacket.State);
							
							tradingSession:SetData(npcName, "Message", "Here are your items.");

							-- after submitting to save;
							Debugger:Warn("TradePacket, Success: ", returnPacket.Success, " FailMsg: ", returnPacket.FailMsg);
							task.spawn(function()
								local globalReturnPacket = tradersMarketDatabase:UpdateRequest("all", "removegloballisting", {
									UserId=player.UserId;
									UserName=player.Name;
									TradeKey=tradeKey;
								});
							end)
							
						else
							tradingSession:SetData(npcName, "Message", "Hmmm, something went wrong.. (Error: ".. tostring(returnPacket.FailMsg) ..")");
							tradingSession.Cancelled = true;
							Debugger:WarnClient(player, "Error: ",returnPacket);

						end
						
					end
					
					tradingSession:Sync("tradesession");
				end)


				tradingSession:Sync("tradesession", true);
				updatePost();
			end

			--== checkSaleDialog
			dialog:AddDialog({
				Face="Skeptical";
				Dialogue="Can I have my stuff back?";
				Reply="Sure";
			}, checkSaleDialog);
			--== checkSaleDialog

		else
			dialog:AddDialog({
				Face="Skeptical";
				Dialogue="Can I have my stuff back?";
				Reply="I don't seem to have any of your stuff.";
			});

		end
		
		--== GlobalList
		--local allGlobalMarket = tradersMarketDatabase:Get("all");
		--Debugger:Warn("allGlobalMarket #", allGlobalMarket and #allGlobalMarket.Listing or 0);
		
		--if allGlobalMarket and #allGlobalMarket.Listing > 0 then
		--	local maxListGold = math.ceil(traderProfile.Gold * 1.1);
		--	local tailoredMarketList = {};
		--	local tooExpensiveList = {};

		--	for a=1, #allGlobalMarket.Listing do
		--		local listing = allGlobalMarket.Listing[a];
				
		--		local skipMarketItem = false;
		--		for _, storageItem in pairs(listing.Items) do
		--			if brokeringIncludeList[storageItem.ItemId] == nil then
		--				skipMarketItem = true;
		--				break;
		--			end
		--		end
		--		if skipMarketItem then continue end;
				
		--		if listing.WandererPrice <= maxListGold then
		--			table.insert(tailoredMarketList, listing);
		--		else
		--			table.insert(tooExpensiveList, listing);
		--		end
		--	end

		--	table.sort(tailoredMarketList, function(a, b) return a.WandererPrice > b.WandererPrice; end);

		--	for a=1, #tooExpensiveList do
		--		table.insert(tailoredMarketList, tooExpensiveList[a]);
		--	end

		--	local function loadSalesDialog(dialog)
		--		local tradingSession = modTradingService:NewComputerSession(player, npcName);
		--		if tradingSession == nil then return end;

		--		local playerTradeStorage = tradingSession.Storages[player.Name];
		--		playerTradeStorage.Locked = true;
				
		--		local npcTradeStorage = tradingSession.Storages[npcName];

		--		tradingSession:SetData(npcName, "HideGold", true);
		--		tradingSession:SetData(npcName, "AddPageButtons", true);
				
		--		local activeBook = tailoredMarketList;
		--		tradingSession.Page = 1;
		--		tradingSession.MaxPage = #tailoredMarketList;
				
		--		local msgStrCache;
		--		local function updatePage()
		--			local tradePacket = activeBook[tradingSession.Page];

		--			---Debugger:Warn(tradingSession.Page, "tradePacket", tradePacket);

		--			tradingSession:SetData(npcName, "Gold", 0);
		--			npcTradeStorage:Wipe();
					
		--			local taxCost = 0;
		--			for a=1, #tradePacket.Items do
		--				local storageItem = tradePacket.Items[a];

		--				local itemLib = modItemsLibrary:Find(storageItem.ItemId);
		--				local itemTax = itemLib.TradingTax or 0;
		--				if itemTax > 0 then
		--					taxCost = taxCost + (itemTax * storageItem.Quantity);
		--				end

		--				npcTradeStorage:Insert{ItemId=storageItem.ItemId; Data={Values=storageItem.Values; Quantity=storageItem.Quantity;}};
		--			end
					
		--			local soldByTxt = "\n\n<font size='14'>".."\nSeller: ".. tradePacket.UserName .."</font>";
		--			local messageStr = "";
					
		--			local goldCost = tradePacket.WandererPrice + taxCost;
					
		--			if #tradePacket.Items == 1 then
		--				local storageItem = tradePacket.Items[1];
		--				local itemLib = modItemsLibrary:Find(storageItem.ItemId);

		--				messageStr = (storageItem.Quantity > 1 and storageItem.Quantity or "A")
		--					.." <b>".. itemLib.Name .. "</b> for "
		--					..modRichFormatter.GoldText(modFormatNumber.Beautify(goldCost).." Gold").."."..soldByTxt;

		--			else
		--				messageStr = "This bundle of items for "..modRichFormatter.GoldText(modFormatNumber.Beautify(goldCost).." Gold").."."..soldByTxt;

		--			end
		--			msgStrCache = messageStr;
		--			tradingSession:SetData(npcName, "Message", messageStr);
					
		--			tradingSession:Sync("tradesession");
		--		end

		--		local function updateFilter()
		--			local filterString = tradingSession.PageFilter;

		--			if filterString == nil then
		--				activeBook = tailoredMarketList;
		--				tradingSession.Page = 1;
		--				tradingSession.MaxPage = #tailoredMarketList;

		--				updatePage();
		--				return;
		--			end

		--			local keys = string.split(filterString, ",");
					
		--			if #keys == 1 and tonumber(keys[1]) ~= nil then
		--				tradingSession.Page = math.clamp(tonumber(keys[1]), 1, tradingSession.MaxPage);

		--				updatePage();
		--				return;
		--			end

		--			activeBook = {};
		--			for a=1, #tailoredMarketList do
		--				local listing = tailoredMarketList[a];
						
		--				local keyMatched;
		--				for b=1, #keys do
		--					if string.lower(keys[b]) == string.lower(listing.UserName) then
		--						keyMatched = b;
		--						break;
		--					end
		--				end
						
		--				if keyMatched ~= nil then
		--					table.insert(activeBook, listing);

		--				else
		--					local strForKeyMatch = string.lower(HttpService:JSONEncode(listing.Items));
		--					for b=1, #keys do
		--						if string.match(strForKeyMatch, keys[b]) then
		--							table.insert(activeBook, listing);
		--							break;
		--						end
		--					end
		--				end
		--			end
					
		--			local noResult = false;
		--			if #activeBook <= 0 then
		--				tradingSession.PageFilter = nil;

		--				activeBook = tailoredMarketList;
		--				noResult = true;
		--			end

		--			tradingSession.Page = 1;
		--			tradingSession.MaxPage = #activeBook;
		--			updatePage();
					
		--			if noResult then
		--				tradingSession:SetData(npcName, "Message", "I can't seem to find what you're looking for..\n\nNo results for: "..tostring(filterString));
		--				tradingSession:Sync("tradesession");
		--			end
		--		end

		--		tradingSession:BindConfirmSet(function(self, playerObj)
		--			local playerGoldInput = playerObj.Gold;

		--			if playerObj.Confirm then
		--				local tradePacket = activeBook[tradingSession.Page];

		--				local taxCost = 0;
		--				for a=1, #tradePacket.Items do
		--					local storageItem = tradePacket.Items[a];

		--					local itemLib = modItemsLibrary:Find(storageItem.ItemId);
		--					local itemTax = itemLib.TradingTax or 0;
		--					if itemTax > 0 then
		--						taxCost = taxCost + (itemTax * storageItem.Quantity);
		--					end
		--				end

		--				local goldCost = tradePacket.WandererPrice + taxCost;
						
		--				if playerGoldInput == goldCost then

		--					local hasSpace = inventory:SpaceCheck(tradePacket.Items);
		--					if hasSpace then
		--						tradingSession:SetData(npcName, "Message", "Alright, let me check if I still have the items..");
		--						tradingSession:SetConfirm(npcName, true);
								
		--					else
		--						tradingSession:SetData(npcName, "Message", "You're gonna need more space to hold these items..");
		--						tradingSession:SetConfirm(npcName, false);
								
		--					end

		--				elseif playerGoldInput <= 0 then
		--					tradingSession:SetData(npcName, "Message", "This is not a charity buddy, hand over the gold.");

		--				elseif playerGoldInput ~= goldCost then
		--					tradingSession:SetData(npcName, "Message", "That's not the right amount of gold I'm offering.. It's "
		--						..modRichFormatter.GoldText(modFormatNumber.Beautify(goldCost).." Gold").." or nothing.");

		--				end

		--				tradingSession:Sync("tradesession");

		--			else
		--				tradingSession:SetConfirm(npcName, false);
		--				tradingSession:SetData(npcName, "Message", msgStrCache);
		--				tradingSession:Sync("tradesession");

		--			end
		--		end)
				
		--		tradingSession:BindInputEvents(function(action, ...)
		--			local oldPage = tradingSession.Page;
		--			if action == "dialognext" then
		--				tradingSession.Page = math.clamp(tradingSession.Page +1, 1, tradingSession.MaxPage);
		--				updatePage();

		--			elseif action == "dialogback" then
		--				tradingSession.Page = math.clamp(tradingSession.Page -1, 1, tradingSession.MaxPage);
		--				updatePage();
						
		--			elseif action == "pageInputFocused" then
		--				tradingSession.PageFilter = nil;
						
		--				tradingSession:SetData(npcName, "Message", "Looking for something specific? Let me know what or whos trade you're looking for.");
		--				tradingSession:Sync("tradesession");

		--			elseif action == "pageInputFocusLost" then
		--				local searchInput = ...;
		--				Debugger:Warn("SearchInput:", searchInput);
		--				searchInput = searchInput or "";
						
		--				local splitList = string.split(searchInput);
		--				if #splitList == 1 then
		--					local cmdKey = tostring(splitList[1]);
		--					if player.UserId == 16170943 and cmdKey:sub(1,1) == "/" then
		--						Debugger:Warn("Command input:", cmdKey);
		--						local tradePacket = activeBook[tradingSession.Page];
								
		--						if cmdKey == "/unlist" then
		--							task.spawn(function()
		--								local returnPacket = tradersMarketDatabase:UpdateRequest("all", "removegloballisting", {
		--									TradeKey=tradePacket.TradeKey;
		--								});
										
		--								local returnPacket = tradersMarketDatabase:UpdateRequest(tostring(tradePacket.UserId), "updatelisting", {
		--									State=ListingStates.Expired;
		--									TradeKey=tradePacket.TradeKey;
		--								});
		--							end)
									
		--							return;
		--						end
		--					end
		--				end
						
		--				if #searchInput > 0 then
		--					tradingSession.PageFilter = searchInput;
		--					updateFilter();
							
		--				else
		--					tradingSession.PageFilter = nil;
		--					updateFilter();
		--				end
		--			end

		--		end)


		--		tradingSession:BindOnExchange(function()
		--			local tradePacket = activeBook[tradingSession.Page];
		--			local tradeKey = tradePacket.TradeKey;

		--			local playerGoldInput = tradingSession:GetData(player.Name, "Gold");
					
		--			if playerGoldInput < tradePacket.WandererPrice then
		--				tradingSession:SetData(npcName, "Message", "Hmmm, something went wrong.. (Error: Insufficient Gold)");
		--				tradingSession.Cancelled = true;
		--				tradingSession:Sync("tradesession");
		--				return;
		--			end

		--			if modGlobalVars.IsCreator(player) == false then
		--				if existInBrokerEventLog(tradeKey, "purchasegloballisting") == true then
		--					tradingSession:SetData(npcName, "Message", "Hmmm, something went wrong.. (Error: Action Already Done)");
		--					tradingSession.Cancelled = true;
		--					tradingSession:Sync("tradesession");
		--					return;
		--				end
		--				addToBrokerEventLog("purchasegloballisting", tradePacket);
		--			else
		--				Debugger:Warn("Skipping local check");
		--			end
					
		--			local globalReturnPacket = tradersMarketDatabase:UpdateRequest("all", "purchasegloballisting", {
		--				TradeKey=tradeKey;
		--				GoldPaid=playerGoldInput;
		--			});

		--			tradingSession:SetData(npcName, "Gold", 0);
		--			tradingSession:SetData(player.Name, "Gold", 0);

		--			traderProfile:AddGold(-playerGoldInput);
		--			shared.Notify(player, "You gave ".. playerGoldInput .. " Gold to "..npcName, "Positive");
					
		--			task.spawn(function()
		--				modAnalytics.RecordResource(player.UserId, tradePacket.WandererPrice-tradePacket.GoldPrice, "Sink", "Gold", "Trade", "Broker");
		--			end)
					
		--			if globalReturnPacket.Success then
		--				Debugger:Warn("purchasegloballisting Success", tradeKey);
						
		--				tradingSession:SetData(npcName, "Message", "Here you go, <b>".. tradePacket.UserName .."</b> thanks you for your purchase!");
						
		--				task.spawn(function()
		--					tradersMarketDatabase:UpdateRequest(tostring(tradePacket.UserId), "updatelisting", {
		--						State=ListingStates.Purchased;
								
		--						TradeKey=tradeKey;
		--						GoldPaid=playerGoldInput;
		--						BuyerName=player.Name;
		--						BuyerUserId=player.UserId;
		--					});
		--				end)

		--				--debugLogBroker{
		--				--	Type="PurchaseTrade";
		--				--	UserId=profile.UserId;
		--				--	Name=profile.Name;
		--				--	TradePacket=tradePacket;
		--				--}
						
		--			else
		--				Debugger:Warn("purchasegloballisting failed ", tradeKey, " failMsg", globalReturnPacket.FailMsg);
		--				tradingSession:SetData(npcName, "Message", "Hmmm, something went wrong.. (Error: ".. tostring(returnPacket.FailMsg) ..")");
		--				tradingSession.Cancelled = true;
		--				Debugger:WarnClient(player, "Error: ",returnPacket);
						
		--			end

		--			tradingSession:Sync("tradesession");
		--		end)

		--		updatePage()
		--		tradingSession:Sync("tradesession", true);
		--	end
			
		--	--== GlobalList
		--	dialog:AddDialog({
		--		Face="Skeptical";
		--		Dialogue="What's on sale?";
		--		Reply="Here, have a look..";
		--	}, loadSalesDialog);
		--	--== GlobalList
			
		--else
		--	dialog:AddDialog({
		--		Face="Skeptical";
		--		Dialogue="What's on sale?";
		--		Reply="Nothing is on sale at the moment.";
		--	});
			
		--end
		
	end
	

	if sellDisabled == nil then
		--dialog:AddDialog({
		--	Face="Skeptical";
		--	Dialogue="Let's broker";
		--	Reply="I'm the right guy for the job.";
		--}, enterBrokerFunc);
		dialog:AddDialog({
			Face="Skeptical";
			Dialogue="Let's broker";
			Reply="I'm afraid I'm retiring from brokering. It's just too much for me to handle.";
		}, enterBrokerFunc);
		
	else
		dialog:AddDialog({
			Face="Skeptical";
			Dialogue="Let's broker";
			Reply=sellDisabled;
		});
		
	end
end
