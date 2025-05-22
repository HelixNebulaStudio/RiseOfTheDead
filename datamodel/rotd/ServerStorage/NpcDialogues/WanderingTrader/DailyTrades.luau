local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGoldShopLibrary = shared.require(game.ReplicatedStorage.Library.GoldShopLibrary);
local modDropRateCalculator = shared.require(game.ReplicatedStorage.Library.DropRateCalculator);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local modDatabaseService = shared.require(game.ServerScriptService.ServerLibrary.DatabaseService);
local modTradingService = shared.require(game.ServerScriptService.ServerLibrary.TradingService);


--==
local sellPrices = {0.15, 0.2, 0.25, 0.35}; --{0.25, 0.3, 0.35, 0.45};

local buyPriceRollGroups = modDropRateCalculator.Calculate{
	Rewards={
		{Value=0.8; Chance=1;};
		{Value=0.75; Chance=1/(2*4);};
		{Value=0.7; Chance=1/(5*4);};
		{Value=0.65; Chance=1/(15*4);};
		{Value=0.6; Chance=1/(30*4);};
	};
};


local buyList = {};
local sellList = {};
local goldItemList = modGoldShopLibrary.Products:GetIndexList();
for a=1, #goldItemList do
	local shopItemLib = goldItemList[a];
	if shopItemLib.Trader then
		if shopItemLib.Trader.Buy == true then
			table.insert(buyList, shopItemLib);
		end
		if shopItemLib.Trader.Sell == true then
			table.insert(sellList, shopItemLib);
		end
	end
end


local tradeCooldown = modBranchConfigs.CurrentBranch.Name == "Dev" and 10 or 3600;
return function(player, dialog, data)
	local profile = shared.modProfile:Get(player);
	local playerSave = profile:GetActiveSave();
	local traderProfile = profile and profile.Trader;
	local inventory = playerSave.Inventory;
	local playerLevel = playerSave and playerSave:GetStat("Level") or 1;
	
	local npcName = dialog.Name;
	local traderMem = modDatabaseService:GetDatabase(npcName);
	
	
	local weekOfYear = modBranchConfigs.CurrentBranch.Name == "Dev" and os.date("%M") or os.date("%W");
	local dayOfYear = workspace:GetAttribute("DayOfYear");
	
	local buyIndex, sellIndex = {}, {};
	local supplyList, demandList = {}, {};

	local daySeed = dayOfYear + (tonumber(os.date("%Y")) or 0)/1000;
	local hourOfDay = tonumber(os.date("%H"));
	
	if hourOfDay > Random.new(daySeed):NextInteger(0, 23) then
	else
		dayOfYear = dayOfYear -1;
	end
	daySeed = dayOfYear + (tonumber(os.date("%Y")) or 0)/1000;

	local randomOfTheDay = Random.new(daySeed);
	local offers = randomOfTheDay:NextInteger(2, 4);
	
	
	local luckOfTheDay = Random.new(player.UserId + (dayOfYear * os.date("%H")));
	local luckTable = {
		HasGold = luckOfTheDay:NextNumber();
	}
	

	repeat
		local test = randomOfTheDay:NextInteger(1, #buyList);
		if table.find(buyIndex, test) == nil then
			table.insert(buyIndex, test);
		end
	until #buyIndex >= offers;

	local function roll()
		local groups = buyPriceRollGroups;
		for a=1, #groups do
			local random = randomOfTheDay;

			local rolls = random:NextNumber(0, groups[a].TotalChance);

			for b=1, #groups[a] do
				local rewardInfo = groups[a][b];
				if rewardInfo.Min < rolls and rolls <= rewardInfo.Max then
					return rewardInfo and rewardInfo.Value;
				end
			end
		end

		return;
	end

	for a=1, #buyIndex do
		local shopItemLib = buyList[buyIndex[a]];
		local itemLib = modItemsLibrary:Find(shopItemLib.Product.ItemId);

		local goldPrice = shopItemLib.Product.Price;
		local rollDiscount = roll();

		goldPrice = math.floor((goldPrice * rollDiscount)/10 +a)*10; --buyPrices[ math.fmod(#buyIndex, #buyPrices)+1 ]

		table.insert(supplyList, {
			Type="Supply";
			ItemId = shopItemLib.Product.ItemId;
			Price = goldPrice;
		});
	end

	local traderGold = traderMem:Get("Gold") or 0;

	repeat
		local test = randomOfTheDay:NextInteger(1, #sellList);

		local shopItemLib = sellList[test];
		local itemId = shopItemLib.Product.ItemId;

		local exist = false;
		for a=1, #supplyList do
			if supplyList[a].ItemId == itemId then
				exist = true;
				break;
			end
		end

		if table.find(sellIndex, test) == nil and not exist then
			table.insert(sellIndex, test);

			local shopItemLib = sellList[test];
			local itemLib = modItemsLibrary:Find(shopItemLib.Product.ItemId);

			local goldPrice = shopItemLib.Product.Price;
			goldPrice = math.floor(goldPrice * sellPrices[ math.fmod(#sellIndex, #sellPrices)+1 ]/10)*10;

			if traderGold >= goldPrice then
				
				--Rigged to support the poor;
				if traderProfile.Gold >= 15000 and modBranchConfigs.CurrentBranch.Name ~= "Dev" then
					local mappedChance = modMath.MapNum(traderProfile.Gold, 19000, 50000, 1, 0.1);
					Debugger:Warn("Roll dice", luckTable.HasGold, "mappedChance", mappedChance);
					if luckTable.HasGold > mappedChance then
						continue;
					end
				end
				
				table.insert(demandList, {
					Type="Demand";
					ItemId = shopItemLib.Product.ItemId;
					Price = goldPrice;
				});
			end
		end
	until #sellIndex >= offers;

	local flag = profile.Flags:Get("traderTrade");
	local dialogData = flag and {ChoiceUnlockTime=flag.Time} or nil;

	local sellDisabled = nil;
	if playerLevel <= 100 then
		sellDisabled = "Hmmm.. You seem new around here, come back when you know what you are doing. Mastery Level 100 required.";

	elseif profile.TrustLevel <= 15 then
		sellDisabled = "Sorry, I just don't trust you enough yet to buy your stuff, maybe someday.";

	end

	dialog:AddDialog({
		Face="Skeptical";
		Say="Let's trade";
		Reply="Sure";
		ToggleWindow="Trade";

	}, function(dialog)
		if flag and flag.Time > os.time() then
			Debugger:Warn("Wandering Trader still on cooldown for", player.Name);
			task.spawn(function()
				shared.modGameLogService:Log(player.Name.." attempting to abuse wandering trader..", "Trades");
			end)
			return 
		end;

		local tradingSession = modTradingService:NewComputerSession(player, npcName);
		if tradingSession == nil then return end;

		local npcTradeStorage = tradingSession.Storages[npcName];
		npcTradeStorage.Values.HideSeeds = true;
		
		tradingSession:SetData(npcName, "Demands", demandList);

		tradingSession:BindStateUpdate(function()
			if tradingSession.State == 3 then
				profile.Flags:Add{Id="traderTrade"; Time=(os.time()+tradeCooldown)};
			end
		end)

		local validTrade = false;
		tradingSession:BindConfirmSet(function(self, playerObj)

			if playerObj.Confirm then
				if playerObj.NoSpace == true then
					tradingSession:SetData(npcName, "Message", "Your inventory is full");
					
				elseif validTrade then
					tradingSession:SetData(npcName, "Message", "It's nice doing business with you..");
					tradingSession:SetConfirm(npcName, true);
					
				else
					local msgs = {
						"??";
						"That's not part of the agreement.";
						"Are you trying to scam me?";
						"What are you doing?"
					}
					tradingSession:SetData(npcName, "Message", msgs[math.random(1, #msgs)]);
				end

				tradingSession:Sync("tradesession");
			else
				tradingSession:SetConfirm(npcName, false);
				if tradingSession.State == 2 then
					tradingSession:SetData(npcName, "Message", "What's wrong?");
					tradingSession:Sync("tradesession");
				end
			end
		end)

		local priceMatrixTable = {};
		for a=1, #supplyList do
			local supplyInfo = supplyList[a];
			priceMatrixTable[supplyInfo.Price] = supplyInfo;
		end

		local function processTrade(self, playerObj)
			validTrade = false;
			tradingSession:SetData(npcName, "Gold", 0);
			npcTradeStorage:Wipe();

			local buyValid, sellValid = nil, nil;

			-- Sell Section
			local matchingItem;
			local storage = tradingSession.Storages[player.Name];
			local totalItemCount = 0;
			local itemCount = storage:Loop(function(storageItem)
				for a=1, #demandList do
					local demandInfo = demandList[a];
					if storageItem.ItemId == demandInfo.ItemId then
						matchingItem = demandInfo;
					end
				end
				
				if storageItem.Quantity > 1 then
					totalItemCount = totalItemCount + storageItem.Quantity-1;
				end
			end);
			totalItemCount = totalItemCount + itemCount;

			if totalItemCount <= 0 then
				sellValid = true;

			elseif totalItemCount == 1 then
				if matchingItem then
					tradingSession:SetData(npcName, "Gold", matchingItem.Price);
					sellValid = matchingItem;

					if sellDisabled then
						sellValid = 3;
					end
				else
					sellValid = 2;
				end

			elseif totalItemCount >= 2 then
				sellValid = 1;
			end

			-- Buy Section
			if playerObj.Gold == 0 then
				buyValid = true;

			elseif priceMatrixTable[playerObj.Gold] then
				npcTradeStorage:Wipe();
				local supplyInfo = priceMatrixTable[playerObj.Gold];

				npcTradeStorage:Insert{ItemId=supplyInfo.ItemId; Data={Values={GoldPrice=supplyInfo.Price;}}};
				
				buyValid = supplyInfo;
			else
				buyValid = 1;
			end

			-- Evaluate;
			local goldHeaderTag = '<font color="rgb(255, 205, 79)">';
			if buyValid == 1 then
				tradingSession:SetData(npcName, "Message", "I don't think I'm trading anything with that price.");

			elseif sellValid == 1 then
				tradingSession:SetData(npcName, "Message", "Woah there, I only want to buy <b>1</b> of the "..#demandList.." items.");

			elseif sellValid == 2 then
				tradingSession:SetData(npcName, "Message", "What is this trash you are trying to sell me?");

			elseif sellValid == 3 then
				tradingSession:SetData(npcName, "Message", sellDisabled);

			elseif buyValid == true and sellValid == true then
				if #demandList > 0 then
					tradingSession:SetData(npcName, "Message", "I'm selling these items, but I am looking to buy the items below.");
				else
					tradingSession:SetData(npcName, "Message", "I'm selling these items, but I don't have enough gold to buy anything.");
				end

			elseif buyValid ~= nil and sellValid == true then
				local itemLib = modItemsLibrary:Find(buyValid.ItemId);
				tradingSession:SetData(npcName, "Message", "So you want the <b>"..itemLib.Name.."</b> eh?");
				validTrade = true;

			elseif buyValid == true and sellValid ~= nil then
				local itemLib = modItemsLibrary:Find(sellValid.ItemId);
				tradingSession:SetData(npcName, "Message", "Arr, yes, here's <b>"..goldHeaderTag..sellValid.Price.." Gold</font></b> for it.");
				validTrade = true;

			elseif buyValid ~= nil and sellValid ~= nil then
				local buyItemLib = modItemsLibrary:Find(buyValid.ItemId);
				local sellItemLib = modItemsLibrary:Find(sellValid.ItemId);

				tradingSession:SetData(npcName, "Message", 
					"Sure, you want the <b>"..buyItemLib.Name.."</b>, and I want the <b>".. sellItemLib.Name.."</b>.");
				validTrade = true;

			else
				tradingSession:SetData(npcName, "Message", "What's going on...");

			end

			if not validTrade then
				for a=1, #supplyList do
					local supplyInfo = supplyList[a];
					npcTradeStorage:Insert{ItemId=supplyInfo.ItemId; Data={Values={GoldPrice=supplyInfo.Price;}}};
					
				end
			end

			tradingSession:Sync("tradesession");
		end


		tradingSession:BindGoldUpdate(processTrade);
		tradingSession:BindStorageUpdate(processTrade);

		tradingSession:Sync("tradesession", true);
	end, dialogData);
end
