local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local weekSec = 3600*24*30;

local HttpService = game:GetService("HttpService");
local RunService = game:GetService("RunService");

local modSerializer = require(game.ReplicatedStorage.Library.Serializer);

local serializer = modSerializer.new();
--==
local TradingMarket = {};

--
local ItemMarket = {};
ItemMarket.__index = ItemMarket;
ItemMarket.ClassType = "ItemMarket";

function ItemMarket.new()
	local self = { --List of listings;
		Key="";
		ItemId="";
		List={};
		
		Count=0;
		Average=0;
		Max=0;
		Min=0;
	};
	
	setmetatable(self, ItemMarket);
	return self;
end

function ItemMarket:Add(logTime, storageItem, gold, traderNames, avgGold)
	local listSize = self.Key == "market:all" and 250 or 10;
	
	while #self.List > 0 do
		if (#self.List > listSize and self.List[1].Time < (DateTime.now().UnixTimestamp-weekSec)) or self.List[1].ItemId == nil then
			table.remove(self.List, 1);
		else
			break;
		end
	end
	
	self.ItemId = storageItem.ItemId;
	
	local itemValues = {};
	if storageItem.Values then
		local importantKeys = {"SkinWearId"; "Tweak"; "ActiveSkin"; "Skins"; "Color"; "Seed";};
		
		for a=1, #importantKeys do
			local key = importantKeys[a];
			if storageItem.Values[key] ~= nil then
				itemValues[key] = storageItem.Values[key];
			end
		end
	end
	
	local newListing = {
		Time = logTime;
		Gold = gold;
		Traders = traderNames;

		ItemId = storageItem.ItemId;
		Quantity = storageItem.Quantity or 1;
		ItemValues = itemValues;
		
		AverageCost = (avgGold or self.Average or gold);
	}
	
	table.insert(self.List, newListing);
	
	local total = 0;
	local count = 0;
	local max, min = 0, math.huge;
	
	for a=1, #self.List do
		local q = self.List[a].Quantity;
		count = count + q;
		
		local g = self.List[a].Gold;
		total = total + g;
		
		g = g/q;
		
		if g > max then
			max = g;
		end
		if g < min then
			min = g;
		end
	end
	
	self.Count = count;
	self.Average = total/count;
	self.Max = max;
	self.Min = min;
end

--


function TradingMarket:GetMarket(key)
	local itemMarket = self.Database:Get(key);
	if itemMarket == nil then return nil end;
	
	return itemMarket;
end

function TradingMarket.Init(tradingServiceDatabase)
	TradingMarket.Database = tradingServiceDatabase;
	
	tradingServiceDatabase:OnUpdateRequest("logtrade", function(requestPacket)
		local itemMarket = requestPacket.Data or ItemMarket.new();
		itemMarket.Key = requestPacket.Key;
		
		local inputValues = requestPacket.Values; 
		
		local logTime = inputValues.Time;
		local gold = inputValues.Gold;
		local storageItem = inputValues.StorageItem;
		local names = inputValues.Names;
		local avgGold = inputValues.AvgGold or itemMarket.Average or gold;
		
		itemMarket:Add(logTime, storageItem, gold, names, avgGold);
		
		Debugger:Warn("logtrade ", logTime, "gold", gold, "itemId",storageItem.ItemId, "avgGold", avgGold);
		
		return itemMarket;
	end)
	
	--== serializer
	serializer:AddClass(ItemMarket.ClassType, ItemMarket.new);
	tradingServiceDatabase:BindSerializer(serializer);
	

	task.spawn(function()
		local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);

		Debugger.AwaitShared("modCommandsLibrary");
		shared.modCommandsLibrary:HookChatCommand("market", {
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
			Description = [[Market commands.
			/market itemid
			]];

			RequiredArgs = 0;
			UsageInfo = "/market itemid";
			Function = function(player, args)
				local itemid = args[1];
				
				local key = "market:"..itemid;
				
				local itemMarket = tradingServiceDatabase:Get(key);
				
				if itemMarket then
					shared.Notify(player, "Market For: ".. itemMarket.ItemId, "Inform");
					shared.Notify(player, "Quantity: ".. itemMarket.Count, "Inform");
					shared.Notify(player, "Average: ".. itemMarket.Average .." Gold", "Inform");
					shared.Notify(player, "Highest: ".. itemMarket.Max .." Gold", "Inform");
					shared.Notify(player, "Lowest: ".. itemMarket.Min .." Gold", "Inform");
					
					Debugger:Log(itemid.. "itemMarket:", itemMarket);
					
				else
					shared.Notify(player, "There are not market logs for ".. itemid, "Inform");
				end
				
				return true;
			end;
		});
	end)
end

function TradingMarket:LogTrade(tradeSessionObj)
	local partyNames = {};
	
	local isTradeWithNpc = false;
	for name, _ in pairs(tradeSessionObj.Players) do
		local playerObj = tradeSessionObj.Players[name];
		if playerObj.Npc then
			isTradeWithNpc = true;
		end;
		table.insert(partyNames, name);
	end
	if isTradeWithNpc then return end;
	
	for name, _ in pairs(tradeSessionObj.Players) do
		local playerObj = tradeSessionObj.Players[name];
		
		local gold = playerObj.Gold or 0;
		local items = {};
		
		if tradeSessionObj.Fee > 0 then
			for siid, storageItem in pairs(tradeSessionObj.Storages[name].Container) do
				table.insert(items, storageItem);
			end
		end
		
		if gold > 0 and #items == 1 then
			local storageItem = items[1];
			storageItem = HttpService:JSONDecode(HttpService:JSONEncode(storageItem));
			
			local tradeLog = {
				Time = DateTime.now().UnixTimestamp;
				Gold = gold;
				StorageItem = storageItem;
				Names = partyNames;
			};
			
			local key = "market:"..storageItem.ItemId;
			local itemMarket = TradingMarket.Database:Get(key);
			
			if itemMarket then
				local avgGold = itemMarket.Average or gold;
				local quantity = storageItem.Quantity or 1;
				local costDiff = ((gold/quantity)/avgGold)-1; -- diffMulti

				local submitListing = true;
				local rng = math.random(0, 10000)/10000;

				if math.abs(costDiff) <= 0.15 then
				elseif math.abs(costDiff) <= 0.3 then -- 0.16 to 0.3;
					if costDiff > 0 then
						submitListing = rng < 0.6;
					else
						submitListing = rng < 0.2;
					end

				elseif math.abs(costDiff) <= 0.6 then
					if costDiff > 0 then
						submitListing = rng < 0.4;
					else
						submitListing = rng < 0.1;
					end

				elseif math.abs(costDiff) <= 1 then
					if costDiff > 0 then
						submitListing = rng < 0.2;
					else
						submitListing = rng < 0.1;
					end

				elseif math.abs(costDiff) <= 2 then
					if costDiff > 0 then
						submitListing = rng < 0.1;
					else
						submitListing = rng < 0.05;
					end

				elseif math.abs(costDiff) <= 4 then
					if costDiff > 0 then
						submitListing = rng < 0.05;
					else
						submitListing = rng < 0.025;
					end
				else
					submitListing = rng < 0.0125;
				end
				
				if RunService:IsStudio() then
					Debugger:Warn("[Studio] costDiff",costDiff,"submitListing",submitListing,"rng",rng,"avgGold",avgGold);
				end

				if not submitListing then
					Debugger:Warn("ItemMarket:Add (","market:".. storageItem.ItemId,") declined CostDiff:", costDiff, " Rng:",rng);
					return;
				end
			end
			
			local returnPacket = self.Database:UpdateRequest("market:".. storageItem.ItemId, "logtrade", tradeLog);
			if returnPacket.Success then
				tradeLog.AvgGold = returnPacket.Data.Average or gold;
				self.Database:UpdateRequest("market:all", "logtrade", tradeLog);
				
			end
		end
	end
end

return TradingMarket;