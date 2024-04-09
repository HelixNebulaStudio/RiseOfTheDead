local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TraderProfile = {};
TraderProfile.__index = TraderProfile;
--==
local HttpService = game:GetService("HttpService");
local DataStoreService = game:GetService("DataStoreService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local remoteGoldStatSync = modRemotesManager:Get("GoldStatSync");

local tradesDatabase = DataStoreService:GetDataStore("TradesHistory");
local goldDatabase = DataStoreService:GetOrderedDataStore("GoldBase");
--print(game:GetService("DataStoreService"):GetDataStore("TradesHistory"):GetAsync("userId/page")); page = trades/50;

TraderProfile.GoldCapacity = 1000000;
--== Script;
function TraderProfile:Load(rawData)
	rawData = rawData or {};
	for key, value in pairs(self) do
		local data = rawData[key] or self[key];
		self[key] = data;
	end
	
	task.spawn(function()
		goldDatabase:SetAsync(tostring(self.Player.UserId), self.Gold);
	end)
	
	self:LoadTrades();
end

function TraderProfile.new(player)
	local meta = {
		Player = player;
		SaveCache = {};
		TradeOpponentCache = {};
	};
	meta.__index=meta;
	
	local self = {
		Gold=0;
		ReserveGold=0;
		
		Good=0;
		Bad=0;
		Trades=0;
	};
	
	setmetatable(self, meta);
	setmetatable(meta, TraderProfile);
	return self;
end

function TraderProfile:CalRep()
	if self.Trades <= 0 then return 0; end
	return (math.floor(self.Good/5) - math.floor(self.Bad/10))/(self.Trades/5);
end

function TraderProfile:SyncGold()
	remoteGoldStatSync:FireClient(self.Player, self.Gold);
end

function TraderProfile:AddGold(amt)
	self.Gold = math.ceil(self.Gold + amt);
	
	if self.Gold > self.GoldCapacity then
		local excess = self.Gold-self.GoldCapacity;
		
		self.Gold = self.GoldCapacity;
		self.ReserveGold = math.ceil(self.ReserveGold + excess);
	end
	
	self:SyncGold();
	
	task.spawn(function()
		local profile = shared.modProfile:Get(self.Player);
		profile.Analytics:Log("Gold", amt);
		
		local activeSave = profile:GetActiveSave();
		activeSave:AwardAchievement("thetra");
		
		goldDatabase:SetAsync(tostring(self.Player.UserId), self.Gold);
	end)
	if self.Gold < 0 then
		modAnalytics:ReportError("Trading", self.Player.Name.." ("..self.Player.UserId..") drop to negative gold. Trace: ".. debug.traceback(), "critical");
		shared.modGameLogService:Log(self.Player.Name.." ("..self.Player.UserId..") drop to negative gold. Trace: ".. debug.traceback().."\n", "Logs");
	end
end

function TraderProfile:AddTraderRep(targetName, repType)
	if self.TradeOpponentCache[targetName] then return end;
	
	if repType == "Good" then
		self.Good = self.Good +1;
	elseif repType == "Bad" then
		self.Bad = self.Bad +1;
	else
		Debugger:Warn("Unknown trader rep type:",repType);
	end
end

function TraderProfile:CacheTrade(tradeSessionObj)
	self.Trades = self.Trades +1;
	
	if self.Trades >= 100 then
		task.spawn(function()
			local profile = shared.modProfile:Get(self.Player);

			local activeSave = profile:GetActiveSave();
			activeSave:AwardAchievement("merchant");
		end)
	end
	
	local tradeId = self.Trades;
	local tradeSave = {};
	tradeSave.Players = {};
	tradeSave.Time = DateTime.now().UnixTimestamp;
	
	
	local playerNames = {};
	for name, _ in pairs(tradeSessionObj.Players) do
		table.insert(playerNames, name);
	end
	local otherParty = {};
	otherParty[playerNames[1]] = playerNames[2];
	otherParty[playerNames[2]] = playerNames[1];
	
	for name, _ in pairs(tradeSessionObj.Players) do
		local playerObj = tradeSessionObj.Players[name];
		
		local container = {};
		if tradeSessionObj.Fee > 0 then
			for Id, _ in pairs(tradeSessionObj.Storages[name].Container) do
				container[Id] = tradeSessionObj.Storages[name].Container[Id];
			end
		end
		
		local otherPlayerObj = tradeSessionObj.Players[otherParty[name]];
		local otherGold = otherPlayerObj.Gold;
		
		local storeName = name
		if playerObj.Npc then
			storeName = name.." [NPC]";
		end
		
		tradeSave.Players[name] = {
			Name = storeName;
			Gold = otherGold;
			Container = container;
		};
	end

	Debugger:Log("CacheTrade:", tradeSave);
	table.insert(self.SaveCache, tradeSave);
end

function TraderProfile:LoadTrades()
	spawn(function()
		local listIndex = math.floor(self.Trades/50);
		local listKey = self.Player.UserId.."/"..listIndex;
		
		local encoded = tradesDatabase:GetAsync(listKey)
		local rawTable = encoded and HttpService:JSONDecode(encoded) or {};
		for a=1, #rawTable do
			local tradeData = rawTable[a];
			for name, data in pairs(tradeData) do
				self.TradeOpponentCache[name] = true;
			end
		end
	end)
end

function TraderProfile:SaveTrades()
	spawn(function()
		local listIndex = math.floor(self.Trades/50);
		local listKey = self.Player.UserId.."/"..listIndex;
		
		tradesDatabase:UpdateAsync(listKey, function(oldValue)
			local rawTable = oldValue and HttpService:JSONDecode(oldValue) or {};
			for a=1, #self.SaveCache do
				table.insert(rawTable, self.SaveCache[a]);
			end
			self.SaveCache = {};
			local encode = HttpService:JSONEncode(rawTable);
			return encode;
		end)
	end)
end

return TraderProfile;
