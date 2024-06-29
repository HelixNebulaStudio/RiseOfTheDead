local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TradingService = {};
TradingService.__index = TradingService;
--==
local RunService = game:GetService("RunService");
local DataStoreService = game:GetService("DataStoreService");

local traderNetStore = DataStoreService:GetOrderedDataStore("WanderingTrader");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modGameSave = require(game.ServerScriptService.ServerLibrary.GameSave); modGameSave.TradingService = TradingService;
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modDatabaseService = require(game.ServerScriptService.ServerLibrary.DatabaseService);
local modGoldShopLibrary = require(game.ReplicatedStorage.Library.GoldShopLibrary);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);

local modTradingMarket = require(script.TradingMarket);

local remoteTradeRequest = modRemotesManager:Get("TradeRequest");
local remoteStorageSync = modRemotesManager:Get("StorageSync");

local enumRequestTypes = {-- do
	SessionSync = "tradesession";
	Initiate = "init";
	End = "end"; 
};

local storageConfig = {Size=8; MaxSize=8;};
local tradingFee = 100;

local tradingServiceDatabase = modDatabaseService:GetDatabase("TradingService");

tradingServiceDatabase:OnUpdateRequest("lock", function(requestPacket)
	local oldKey = requestPacket.RawData;
	local newKey = requestPacket.Values;

	return newKey;
end)

TradingService.CommenceDuration = 3;
TradingService.TradeSessions = {};
TradingService.PlayerRequests = {}; 

modTradingMarket.Init(tradingServiceDatabase);
--== Script;

--== Trade Session Object
local TradeSessionObject = {};
TradeSessionObject.ClassType = "TradeSessionObject";
TradeSessionObject.__index = TradeSessionObject;

function TradeSessionObject.new()
	local meta = {};
	meta.__index = meta;
	local self = {
		State=1;
		Processing=false;
		IgnorePlayerInventoryFull=false;
	};
	
	setmetatable(meta, TradeSessionObject)
	setmetatable(self, meta);
	return self;
end

function TradeSessionObject:Sync(requestType, triggerUpdate)
	if requestType == nil then Debugger:Warn("Sync missing requestType."); return end;
	
	task.spawn(function()
		if triggerUpdate then
			for name, _ in pairs(self.Players) do
				local playerObj = self.Players[name];
				if playerObj.Player and self.OnGoldUpdate then
					self:OnGoldUpdate(playerObj);
					break;
				end
			end
		end

		for name, _ in pairs(self.Players) do
			local playerObj = self.Players[name];
			local player = playerObj.Player;
			if player then
				local profile = shared.modProfile:Get(player);
				local activeSave = profile and profile:GetActiveSave();
				local tradingProfile = profile and profile.Trader;

				if activeSave then
					playerObj.Money = activeSave:GetStat("Money");
					playerObj.Rep = tradingProfile:CalRep();
					playerObj.Premium = profile.Premium;
				end

				remoteTradeRequest:FireClient(player, requestType, self);
				for storageName, _ in pairs(self.Storages) do
					remoteStorageSync:FireClient(player, "sync", self.Storages[storageName]:Shrink());
				end
			end
		end
	end)
end

function TradeSessionObject:SetData(name, key, value)
	local playerObj = self.Players[name];
	if playerObj then
		playerObj[key] = value;
		
		if playerObj.Player and key == "Gold" then
			self:Sync("syncgold");
		end
	end
end

function TradeSessionObject:GetData(name, key)
	local playerObj = self.Players[name];
	if playerObj then
		return playerObj[key];
	end
end


function TradeSessionObject:BindGoldUpdate(func)
	local sessionMeta = getmetatable(self);
	
	sessionMeta.OnGoldUpdate = func
end

function TradeSessionObject:SetGold(playerName, input)
	if self.State >= 2 then return end;
	if self.Processing then return end;
	
	input = math.floor(tonumber(input) or 0);
	if shared.IsNan(input) then
		input = 0;
	end
	
	local playerObj = self.Players[playerName];
	if playerObj then
		local actualGold = tonumber(input) or 0;
		if self.IgnorePlayerGoldLimit == true then
			playerObj.Gold = math.clamp(actualGold, 0, math.huge);
			
		elseif playerObj.Player then
			local profile = shared.modProfile:Get(playerObj.Player);
			local cacheStorages = profile:GetCacheStorages();
			local tradingProfile = profile.Trader;
			
			actualGold = math.clamp(actualGold, 0, tradingProfile.Gold);
			playerObj.Gold = actualGold;
			
		elseif playerObj.MaxGold then
			actualGold = math.clamp(actualGold, 0, playerObj.MaxGold);
			playerObj.Gold = actualGold;
			
		end
		
		if playerObj.Player and self.OnGoldUpdate then
			self:OnGoldUpdate(playerObj);
		end
		for name, _ in pairs(self.Players) do
			self:SetConfirm(name, false);
		end
	end
end

function TradeSessionObject:BindStateUpdate(func)
	local sessionMeta = getmetatable(self);
	
	sessionMeta.OnStateUpdate = func
end

function TradeSessionObject:SetState(v)
	self.State = v;
	
	if self.OnStateUpdate then
		self:OnStateUpdate();
	end
end

function TradeSessionObject:BindOnSwapContainers(func)
	local sessionMeta = getmetatable(self);

	sessionMeta.OnSwapContainers = func
end

function TradeSessionObject:BindOnExchange(func)
	local sessionMeta = getmetatable(self);

	sessionMeta.OnExchange = func
end

function TradeSessionObject:BindInputEvents(func)
	local sessionMeta = getmetatable(self);

	sessionMeta.OnInputEvent = func
end

function TradeSessionObject:CheckConfirm()
	local allConfirmed = next(self.Players) ~= nil;
	local function isAllConfirm()
		for name, _ in pairs(self.Players) do
			local playerObj = self.Players[name];
			if playerObj.Player then
				if playerObj.Money < self.Fee then
					self:SetConfirm(name, false, true);
				end
			end
			
			if playerObj.NoSpace then
				self:SetConfirm(name, false, true);
			end
			if playerObj.HasRewardCrates then
				self:SetConfirm(name, false, true);
			end
			
			if not playerObj.Confirm then
				allConfirmed = false;
			end
		end
	end
	isAllConfirm();
	
	local validTrade = true;
	
	for storageId, _ in pairs(self.Storages) do
		self.Storages[storageId]:Loop(function(storageItem)
			local player = self.Storages[storageId].Player;
			if player then
				if self.ComputerSession then
					-- valid
				elseif storageItem.Library.Tradable == modItemsLibrary.Tradable.Tradable then
					-- valid
				elseif storageItem.Library.Tradable == modItemsLibrary.Tradable.PremiumOnly then -- and self.PremiumTrade
					-- valid
				else
					validTrade = false;
					shared.Notify(self.Storages[storageId].Player, "[Trade] Attempting to trade contraband.", "Negative");
					Debugger:Warn("Player (",player.Name,") Attempting to trade contraband.");
					
					return false;
				end
				
				if storageItem.Library.Type == "Mod" then
					local hasValues = false;
					if storageItem.Values then
						for k, v in pairs(storageItem.Values) do
							hasValues = true;
							break;
						end
					end
					if hasValues then
						shared.Notify(self.Storages[storageId].Player, "[Trade] Attempting to trade contraband.", "Negative");
						Debugger:Warn("Player (",player.Name,") Attempting to trade contraband.");
						
						return false;
					end
				end
				
			end
		end)
	end
	
	local traderA, traderB;
	for name, _ in pairs(self.Players) do
		local playerObj = self.Players[name];
		if playerObj.Player then
			if traderA == nil then
				traderA = playerObj;
			else
				traderB = playerObj;
			end
		end
	end
	
	if traderA and traderB then
		if traderA.GoldTax > 0 then
			local traderAProfile = traderA.TraderProfile;
			
			if traderAProfile.Gold-traderA.Gold >= traderA.GoldTax or traderB.Gold >= traderA.GoldTax then -- or traderA.Gold >= traderA.GoldTax
				traderA.CantAffordTax = false;
			else
				validTrade = false;
				shared.Notify(traderA.Player, "[Trade] Insufficient gold to pay gold tax.", "Negative");
				traderA.CantAffordTax = true;
				self:SetConfirm(traderA.Name, false, true);
			end
		end
		if traderB.GoldTax > 0 then
			local traderBProfile = traderB.TraderProfile;

			if traderBProfile.Gold-traderB.Gold >= traderB.GoldTax or traderA.Gold >= traderB.GoldTax then -- or traderB.Gold >= traderB.GoldTax
				traderB.CantAffordTax = false;
			else
				validTrade = false;
				shared.Notify(traderB.Player, "[Trade] Insufficient gold to pay gold tax.", "Negative");
				traderB.CantAffordTax = true;
				self:SetConfirm(traderB.Name, false, true);
			end
		end
	end
	
	for name, _ in pairs(self.Players) do
		local playerObj = self.Players[name];
		if playerObj.Player then
			local profile = playerObj.Profile;
			local activeSave = playerObj.ActiveSave;
			local traderProfile = playerObj.TraderProfile;
			
			if self.IgnorePlayerGoldLimit ~= true and playerObj.Gold > traderProfile.Gold then -- larger than self's gold
				validTrade = false;
				shared.Notify(playerObj.Player, "[Trade] Insufficient gold.", "Negative");
				Debugger:Warn("Player (",playerObj.Player.Name,") Insufficient gold.");
				break;
			end
			if self.Fee > activeSave:GetStat("Money") then
				validTrade = false;
				shared.Notify(playerObj.Player, "[Trade] Insufficient money.", "Negative");
				Debugger:Warn("Player (",playerObj.Player.Name,") Insufficient money.");
				break;
			end
			
		elseif playerObj.Npc then
			local npcTradeObj = playerObj;
			
			local traderMem = modDatabaseService:GetDatabase(name);
			local traderGold = traderMem:Get("Gold") or 0;
			
			if npcTradeObj.Gold > 0 and npcTradeObj.Gold > traderGold then
				validTrade = false;
				
				npcTradeObj.Gold = 0;
				
				local demands = self:GetData(name, "Demands") or {};
				
				for a=#demands, 1, -1 do
					if demands[a].Price > traderGold then
						table.remove(demands, a);
					end
				end
				
				self:SetData(name, "Demands", demands);
				self:SetData(name, "Message", "Okay, apparently I don't have enough gold for that.");
				break;
			end
		end
	end
	
	local function playersStillInTrade()
		for name, _ in pairs(self.Players) do
			local playerObj = self.Players[name];
			if playerObj.Player and not playerObj.Player:IsDescendantOf(game.Players) then
				Debugger:Warn("Player (",playerObj.Player.Name,") left during trade.");
				
				self:SetState(1);
				self.Ended = true;
				self:Sync(enumRequestTypes.End);
				return;
			end
		end
	end
	
	if allConfirmed and validTrade then
		if self.State == 1 then
			self:SetState(2);
			task.spawn(function()
				self.CommenceTime = modSyncTime.GetTime() + TradingService.CommenceDuration;
				self:Sync(enumRequestTypes.SessionSync);
				repeat
					isAllConfirm();
					playersStillInTrade();
					for name, _ in pairs(self.Players) do
						local playerObj = self.Players[name];
						if playerObj.Player then
							local profile = playerObj.Profile;
							profile.SessionLock = os.time();
						end
					end
					task.wait(0.1);
				until self.State ~= 2 or not allConfirmed or modSyncTime.GetTime() >= self.CommenceTime;
				
				if self.State == 2 and allConfirmed and modSyncTime.GetTime() >= self.CommenceTime then
					self:SetState(3);
					self:Sync(enumRequestTypes.SessionSync);
					
					local playersCount = 0;
					
					local npcName;
					for name, _ in pairs(self.Players) do
						if self.Players[name].IsNpc then
							npcName = name;
						end
						playersCount = playersCount +1;
					end
					
					if playersCount > 2 then
						self:SetState(1);
						self:Sync(enumRequestTypes.SessionSync);
						Debugger:Warn("Exchange had more than 2 players.");
						return;
					end

					local nameList = {};
					local exchange = {};
					if npcName == nil then
						for name, _ in pairs(self.Players) do
							table.insert(nameList, name);
						end

					else
						for name, _ in pairs(self.Players) do
							if name == npcName then
								nameList[2] = name;
							else
								nameList[1] = name;
							end
						end
					end
					
					playersStillInTrade();
					if self.Ended then return end;
					
					if self.Processing then return end;
					self.Processing = true;
					
					--Trade lock
					for name, _ in pairs(self.Players) do
						local playerObj = self.Players[name];
						if playerObj.Player then
							local profile = playerObj.Profile;
							profile.SessionLock = os.time();
						end
					end
					
					for storageId, _ in pairs(self.Storages) do
						self.Storages[storageId].Locked = true;
					end
					
					exchange[nameList[1]] = nameList[2];
					exchange[nameList[2]] = nameList[1];
					
					
					---== Exchange return;
					if self.OnExchange then
						self.OnExchange();
						
						if self.Cancelled == true then
							for storageId, _ in pairs(self.Storages) do
								self.Storages[storageId].Locked = false;
							end
							
							for name, _ in pairs(self.Players) do
								local playerObj = self.Players[name];

								if playerObj.Player then
									local profile = playerObj.Profile;
									local traderProfile = playerObj.TraderProfile;

									profile:Save();
									profile.SessionLock = 0;
									
									shared.Notify(playerObj.Player, "The trade has been cancelled.", "Negative");
								end

								TradingService.TradeSessions[name] = nil;
							end
							
							self.State = 1;
							self.Ended = true;
							self:Sync(enumRequestTypes.SessionSync);
							return;
						end
					end
					
					
					for name, _ in pairs(self.Players) do
						local playerObj = self.Players[name];
						if playerObj.Player then
							local profile = playerObj.Profile;
							local traderProfile = playerObj.TraderProfile;
							local activeSave = playerObj.ActiveSave;

							profile.SessionLock = os.time();
							
							profile.SaveIndex = profile.SaveIndex +2;
							activeSave:AddStat("Money", -self.Fee);
							
							local targetName = exchange[name];
							local targetData = self.Players[targetName];
							local targetGold = targetData.Gold;
							
							if playerObj.Gold > 0 and traderProfile.Gold >= playerObj.Gold then
								traderProfile:AddGold(-playerObj.Gold);
								shared.Notify(playerObj.Player,
									("You gave $Gold Gold to $Name."):gsub("$Name", targetName):gsub("$Gold", playerObj.Gold), "Positive");
								
								task.spawn(function()
									if targetData.Npc then return end;
									
									modAnalytics.RecordResource(playerObj.Player.UserId, playerObj.Gold, "Sink", "Gold", "Trade", "Exchange");
									
									if playerObj.Gold >= 10000 then
										local goldTradeDatastore = game:GetService("DataStoreService"):GetOrderedDataStore("GoldTradeHigh");
										goldTradeDatastore:UpdateAsync(profile.UserId, function(oldGold)
											if playerObj.Gold > (oldGold or 0) then
												return playerObj.Gold 
											end
											return nil;
										end)

										modAnalytics:ReportError("Trading", playerObj.Player.Name.." traded ".. playerObj.Gold .. " Gold to " ..targetName, playerObj.Gold >= 50000 and "critical" or "info");
										shared.modGameLogService:Log(playerObj.Player.Name.." traded <b>".. (playerObj.Gold) .. "</b> Gold to " ..targetName , "Trades");
									end
								end)
							end
							if targetGold > 0 then
								traderProfile:AddGold(targetGold);
								
								shared.Notify(playerObj.Player,
									("You recieved $Gold Gold from $Name."):gsub("$Name", targetName):gsub("$Gold", targetGold), "Positive");
								
								task.spawn(function()
									if targetData.Npc then return end;
									
									modAnalytics.RecordResource(playerObj.Player.UserId, targetGold, "Source", "Gold", "Trade", "Exchange");
								end)
							end

							if playerObj.GoldTax > 0 then
								traderProfile:AddGold(-playerObj.GoldTax);

								shared.Notify(playerObj.Player,
									("$Gold Gold was taxed from your trade."):gsub("$Name", targetName):gsub("$Gold", playerObj.GoldTax), "Inform");

								task.spawn(function()
									modAnalytics.RecordResource(playerObj.Player.UserId, playerObj.GoldTax, "Sink", "Gold", "Trade", "Tax");
								end)
							end
							
							if self.Fee > 0 then
								traderProfile:AddTraderRep(name, "Good");
							end
							
						elseif playerObj.Npc then
							
							task.spawn(function()
								local traderMem = modDatabaseService:GetDatabase(name);
								local traderGold = traderMem:Get("Gold") or 0;
								
								local playerName = exchange[name];
								local playerData = self.Players[playerName];
								local playerGold = playerData.Gold;
								
								traderMem:OnUpdateRequest("addgold", function(requestPacket)
									local oldGold = requestPacket.RawData;
									local targetGold = requestPacket.Values;
									
									return (oldGold or 0) + targetGold;
								end)
								
								if playerGold > 0 or playerObj.Gold > 0 then
									local netGold = 0;
									
									if playerGold > 0 then --Player sinks gold;
										local returnPacket = traderMem:UpdateRequest("Gold", "addgold", playerGold);
										Debugger:Log("Player sinks gold addgold(".. name ..":/Gold)", returnPacket);
										
										netGold = -playerGold;
										task.spawn(function()
											modAnalytics.RecordResource(playerData.Player.UserId, playerGold, "Sink", "Gold", "Npc", name);
										end)
									end
									
									if playerObj.Gold > 0 then --Player gain gold;
										local returnPacket = traderMem:UpdateRequest("Gold", "addgold", -playerObj.Gold);
										Debugger:Log("Player sinks gold addgold(".. name ..":/Gold)", returnPacket);
										
										netGold = netGold + playerObj.Gold;
										task.spawn(function()
											modAnalytics.RecordResource(playerData.Player.UserId, playerObj.Gold, "Source", "Gold", "Npc", name);
										end)
									end
									
									task.spawn(function()
										traderNetStore:UpdateAsync(tostring(playerData.Player.UserId), function(oldValue)
											return (oldValue or 0)+netGold;
										end)
									end)
								end
							end)
						end
					end
					
					if self.Fee > 0 then
						local playerStorage = self.Storages[nameList[1]];
						local targetStorage = self.Storages[nameList[2]];
						
						local playerData = self.Players[nameList[1]];
						local playerProfile = playerData.Profile; 
						
						local targetData = self.Players[nameList[2]];
						local targetProfile = targetData.Profile; 
						
						if self.OnSwapContainers then
							self.OnSwapContainers(playerStorage, targetStorage);
						end
						playerStorage:SwapContainer(targetStorage);
						self:Sync(enumRequestTypes.SessionSync);
						
						local codexItemIdsList = {};
						for storageId, _ in pairs(self.Storages) do
							self.Storages[storageId]:Loop(function(storageItem)
								storageItem:DeleteValues("GoldPrice"); --NPC traders

								storageItem:DeleteValues("Vanity"); --Vanity cache;
								storageItem:DeleteValues("VanityMeta");
								storageItem:DeleteValues("VanityItemId");
								
								table.insert(codexItemIdsList, storageItem.ItemId);
							end)
							self.Storages[storageId].Locked = false;
						end
						
						task.spawn(function()
							for a=1, #codexItemIdsList do
								if playerProfile then
									playerProfile:UnlockItemCodex(codexItemIdsList[a], false);
								end
								if targetProfile then 
									targetProfile:UnlockItemCodex(codexItemIdsList[a], false);
								end
							end
							if playerProfile then
								playerProfile:UnlockItemCodex(nil, true);
							end
							if targetProfile then 
								targetProfile:UnlockItemCodex(nil, true);
							end
						end)
					end

					self:Sync(enumRequestTypes.SessionSync);
					
					for name, _ in pairs(self.Players) do
						local playerObj = self.Players[name];
						
						if playerObj.Player then
							local profile = playerObj.Profile;
							local traderProfile = playerObj.TraderProfile;
							
							profile:Save();
							profile.SessionLock = 0;
							task.spawn(function()
								traderProfile:CacheTrade(self);
							end)
						end
						
						TradingService.TradeSessions[name] = nil;
					end
					task.spawn(function()
						modTradingMarket:LogTrade(self);
					end)
					
					self.Ended = true;
					self:Sync(enumRequestTypes.SessionSync);
					
				else
					self:SetState(1);
					self:Sync(enumRequestTypes.SessionSync);
					
				end
			end);
		end
	else
		if self.State == 2 then
			self:SetState(1);
		end
	end
end

function TradeSessionObject:BindConfirmSet(func)
	local sessionMeta = getmetatable(self);
	
	sessionMeta.OnConfirmSet = func
end

function TradeSessionObject:SetConfirm(playerName, value, cancelCheck)
	local playerObj = self.Players[playerName];
	if playerObj then
		playerObj.Confirm = value;
		
		self:Sync(enumRequestTypes.SessionSync);
		
		if playerObj.Player and self.OnConfirmSet then
			self:OnConfirmSet(playerObj);
		end
	end
	
	if value == true and cancelCheck ~= true then
		self:CheckConfirm();
	end
end

function TradeSessionObject:BindStorageUpdate(func)
	local sessionMeta = getmetatable(self);
	
	sessionMeta.OnStorageUpdate = func
end

function TradeSessionObject:Cancel(playerName)
	local bothPlayers = true;
	if self.Players[playerName] then
		
		for name, _ in pairs(self.Players) do
			if self.Players[name].Npc then
				bothPlayers = false;
			end
		end
		
		for name, _ in pairs(self.Players) do
			local player = self.Players[name].Player;
			if player then
				
				if self.State <= 2 then
					local profile = self.Players[name].Profile;
					local traderProfile = self.Players[name].TraderProfile;
					
					if bothPlayers then
						traderProfile:AddTraderRep(name, "Bad");
					end
					
					shared.Notify(player, ("The trade has been cancelled."), "Negative");
					if TradingService.TradeSessions[name] then
						TradingService.TradeSessions[name].Ended = true;
						TradingService.TradeSessions[name]:Sync(enumRequestTypes.End);
					end
					TradingService.TradeSessions[name] = nil;
				end
			end
		end
	end
end


function TradingService:StartTrade(personAObj, personBObj)
	local sessionObj = TradeSessionObject.new();
	local sessionMeta = getmetatable(sessionObj);
	sessionMeta.Storages = {};
	
	local personAName = personAObj.Name;
	TradingService.TradeSessions[personAName] = sessionObj;
	
	local personBName = personBObj.Name;
	local bIsHuman = personBObj.Type == "Player";
	
	if bIsHuman then
		TradingService.TradeSessions[personBName] = sessionObj;
	end
	
	sessionObj.Players = {};
	sessionObj.Fee = 0;
	sessionObj.PremiumTrade = true;
	
	local mainPlayerObj;
	local playersList = {personAName, personBName};
	for _, playerName in pairs(playersList) do
		local playerMeta = {};
		playerMeta.__index = playerMeta;
		
		local playerObj = setmetatable({}, playerMeta);
		
		playerObj.Name = playerName;
		
		if playerName == personAName then
			mainPlayerObj = playerObj;
		end
		
		playerObj.Player = game.Players:FindFirstChild(playerName);
		playerObj.Npc = workspace.Entity:FindFirstChild(playerName);
		
		playerObj.Rep = 0;
		playerObj.Gold = 0;
		playerObj.GoldTax = 0;
		playerObj.Confirm = false;
		playerObj.Premium = false;
		
		if playerObj.Player then
			local profile = shared.modProfile:Get(playerObj.Player);
			local activeSave = profile:GetActiveSave();
			local traderProfile = profile.Trader;
			playerMeta.Profile = profile;
			playerMeta.ActiveSave = activeSave;
			playerMeta.TraderProfile = traderProfile;
			
			playerObj.Rep = traderProfile:CalRep();
			playerObj.Premium = profile.Premium;
			playerObj.Money = activeSave:GetStat("Money");
		
			local storageId = playerName.."Trade";
			
			if activeSave.Storages[storageId] == nil then
				activeSave.Storages[storageId] = modStorage.new(storageId, storageId, storageConfig.Size, playerObj.Player);
				
			end
			
			activeSave.Storages[storageId].Locked = false;
			activeSave.Storages[storageId]:ConnectCheck(function(packet)
				local dragStorageItem = packet.DragStorageItem;
				if dragStorageItem == nil then
					packet.Allowed = false;
					packet.FailMsg = "Missing dragging item.";
					return packet;
				end;
				
				if sessionObj.ComputerSession then
					local storageOfItem = modStorage.Get(dragStorageItem.ID, playerObj.Player);
					if storageOfItem and storageOfItem:Loop() > 0 then
						packet.FailMsg = "Item "..dragStorageItem.ItemId.." can not have any mods attached to it."
						packet.Allowed = false;
						return packet;
					end
					packet.Allowed = true;
					return packet;
				end
				
				if dragStorageItem.NonTradeable then 
					packet.FailMsg = "Item "..dragStorageItem.ItemId.." is trade locked."
					packet.Allowed = false;
					return packet;
				end;
				if dragStorageItem.Library.Tradable == modItemsLibrary.Tradable.Nontradable then
					packet.FailMsg = "Item "..dragStorageItem.ItemId.." is not tradable."
					packet.Allowed = false;
					return packet;
					
				elseif dragStorageItem.Library.Tradable == modItemsLibrary.Tradable.Tradable 
					or dragStorageItem.Library.Tradable == modItemsLibrary.Tradable.PremiumOnly then
					
					local storageOfItem = modStorage.Get(dragStorageItem.ID, playerObj.Player);
					if storageOfItem and storageOfItem:Loop() > 0 then
						packet.FailMsg = "Item "..dragStorageItem.ItemId.." can not have any mods attached to it.";
						packet.Allowed = false;
						return packet;
					end
					packet.Allowed = true;
					return packet;
				end
				
				packet.Allowed = false;
				return packet;
			end)
			
			activeSave.Storages[storageId].OnChanged:Destroy();
			activeSave.Storages[storageId].OnChanged:Connect(function()
				if sessionObj.Ended then 
					return;
				end;
				
				if sessionObj.OnStorageUpdate then
					sessionObj:OnStorageUpdate(playerObj, activeSave.Storages[storageId]);
				end
				
				Debugger:Warn("sessionObj.PremiumTrade", sessionObj.PremiumTrade);
				local tradingWithNpc = false;
				for pName, _ in pairs(sessionObj.Players) do
					-- This player
					local newTax = 0;
					sessionMeta.Storages[pName]:Loop(function(storageItem)
						local itemTax = storageItem.Library.TradingTax or 0;
						
						if storageItem.Library.Tradable == modItemsLibrary.Tradable.PremiumOnly and sessionObj.PremiumTrade ~= true then
							itemTax = itemTax + (storageItem.Library.NonPremiumTax or 50);
						end
						
						if itemTax > 0 then
							newTax = newTax + (itemTax * storageItem.Quantity);
						end
						
						Debugger:Warn("Taxed item", storageItem.ItemId, itemTax);

						storageItem:SetVanity(nil);
						storageItem:DeleteValues("Vanity");
					end)

					local playerObj = sessionObj.Players[pName];
					playerObj.GoldTax = newTax;
					
					-- Check other player
					local otherPlayerName = pName == playersList[1] and playersList[2] or playersList[1];
					local otherPlayer = sessionObj.Players[otherPlayerName];
					
					if otherPlayer and otherPlayer.Player then
						local otherProfile = otherPlayer.Profile;
						local otherActiveSave = otherPlayer.ActiveSave;
						local otherInventory = otherActiveSave and otherActiveSave.Inventory;
						
						if otherProfile.PolicyData.ArePaidRandomItemsRestricted then
							local items = {};
							sessionMeta.Storages[pName]:Loop(function(storageItem) 
								table.insert(items, storageItem.ItemId);
							end)
							
							local hasRewardTable = false;
							for a=1, #items do
								local rewardsList = modRewardsLibrary:Find(items[a]);
								if rewardsList then
									hasRewardTable = true;
									break;
								end
							end
							
							if hasRewardTable then
								sessionObj.Players[otherPlayerName].HasRewardCrates = true;
							else
								sessionObj.Players[otherPlayerName].HasRewardCrates = nil;
							end
						end
						
						
						if otherInventory then
							local items = {};
							sessionMeta.Storages[pName]:Loop(function(storageItem) 
								table.insert(items, {ItemId=storageItem.ItemId; Data={Quantity=storageItem.Quantity or 1};});
							end)
							if otherInventory:SpaceCheck(items) then
								sessionObj.Players[otherPlayerName].NoSpace = nil;
							else
								sessionObj.Players[otherPlayerName].NoSpace = true;
							end
						else
							sessionObj.Players[otherPlayerName].NoSpace = true;
						end
						
					else -- otherplayer is npc;
						playerObj.GoldTax = 0;
						tradingWithNpc = true;
						
					end
				
				end
				
				
				if sessionObj.State <= 2 then
					local totalItems = 0;
					for storageName, _ in pairs(sessionMeta.Storages) do
						local c = sessionMeta.Storages[storageName]:Loop();
						totalItems = totalItems + c;
					end
					sessionObj.Fee = totalItems*tradingFee;
					
					playerObj.Money = activeSave:GetStat("Money");
					
					for name, _ in pairs(sessionObj.Players) do
						sessionObj:SetConfirm(name, false);
					end
				end
				
				sessionObj:Sync(enumRequestTypes.SessionSync);
			end)
			
			sessionMeta.Storages[playerName] = activeSave.Storages[storageId];
			traderProfile:SyncGold();
			
		elseif playerObj.Npc then
			
			playerObj.IsNpc = true;
			playerObj.Rep = 1;
			playerObj.Premium = true;
			playerObj.Money = 1000000;
			
			playerObj.Message = "What do you want to trade?";
			
			local storageId = playerName.."Trade";
			
			local newStorage = modStorage.new(storageId, storageId, storageConfig.Size);
			newStorage.ViewOnly = true;
			
			newStorage.OnChanged:Connect(function()
				if sessionObj.Ended then 
					return;
				end;
				
				local otherPlayerName = mainPlayerObj.Name;
				local otherActiveSave = sessionObj.Players[otherPlayerName] and sessionObj.Players[otherPlayerName].ActiveSave;
				local otherInventory = otherActiveSave and otherActiveSave.Inventory;
				
				if otherInventory then -- player's inv when trading with npc
					local mpcTradeStorageItems = {};
					
					newStorage:Loop(function(storageItem) 
						table.insert(mpcTradeStorageItems, {ItemId=storageItem.ItemId; Data={Quantity=storageItem.Quantity or 1};});
					end)
					if otherInventory:SpaceCheck(mpcTradeStorageItems) then
						sessionObj.Players[otherPlayerName].NoSpace = nil;
						
					else
						if sessionObj.IgnorePlayerInventoryFull ~= true then
							sessionObj.Players[otherPlayerName].NoSpace = true;
						else
							sessionObj.Players[otherPlayerName].NoSpace = nil;
						end
					end
					
				else
					if sessionObj.IgnorePlayerInventoryFull ~= true then
						sessionObj.Players[otherPlayerName].NoSpace = true;
					else
						sessionObj.Players[otherPlayerName].NoSpace = nil;
					end
					
				end
				
				if sessionObj.State <= 2 then
					local totalItems = 0;
					for storageName, _ in pairs(sessionMeta.Storages) do
						local c = sessionMeta.Storages[storageName]:Loop();
						totalItems = totalItems + c;
					end
					sessionObj.Fee = totalItems*tradingFee;
					
					for name, _ in pairs(sessionObj.Players) do
						sessionObj:SetConfirm(name, false);
					end
				end
				
				sessionObj:Sync(enumRequestTypes.SessionSync);
			end)
			
			sessionMeta.Storages[playerName] = newStorage;
		end
		
		sessionObj.Players[playerName] = playerObj;
	end
	
	for name, _ in pairs(sessionObj.Players) do
		if not RunService:IsStudio() and modGlobalVars.IsCreator(sessionObj.Players[name].Player) then
			sessionObj.PremiumTrade = true;
			Debugger:Warn("Forced premium trade.");
			break;
			
		elseif not sessionObj.Players[name].Premium then
			sessionObj.PremiumTrade = false;
			break;
		end
	end
	
	sessionObj:Sync(enumRequestTypes.Initiate);
end

function TradingService:SendTradeRequest(player, targetPlayer)
	if TradingService.PlayerRequests[targetPlayer.Name] == nil then
		TradingService.PlayerRequests[targetPlayer.Name] = {};
	end
	local requestsList = TradingService.PlayerRequests[targetPlayer.Name];
	if requestsList[player.Name] == nil or tick()-requestsList[player.Name] >= 10 then
		requestsList[player.Name] = tick();
		remoteTradeRequest:FireClient(targetPlayer, "request", player.Name);
		shared.Notify(targetPlayer, player.Name.." is inviting you to a trade..", "Inform");
		
		local function clearRequest()
			delay(30, function()
				if requestsList[player.Name] == nil or tick()-requestsList[player.Name] > 30 then
					requestsList[player.Name] = nil;
				else
					clearRequest();
				end
			end)
		end
		clearRequest();
	end
end

function TradingService:RefreshSessions(playerName)
	local sessionObj = TradingService.TradeSessions[playerName];
	if sessionObj then
		sessionObj:Sync(enumRequestTypes.SessionSync);
	end
end

function TradingService:NewComputerSession(player, npcName)
	if TradingService.TradeSessions[player.Name] == nil or TradingService.TradeSessions[player.Name].Ended == true then
		TradingService.PlayerRequests[player.Name] = nil;
		
		TradingService:StartTrade({Type="Player", Name=player.Name}, {Type="Npc", Name=npcName});
		
		shared.Notify(player, "You are now trading with "..npcName..".", "Inform");
		
		local sessionObj = TradingService.TradeSessions[player.Name];
		sessionObj.ComputerSession = true;
		return sessionObj;
		
	else
		local sessionObj = TradingService.TradeSessions[player.Name];
		if sessionObj then
			shared.Notify(player, "You are in a trade session!", "Negative");
			sessionObj.ComputerSession = true;
			return sessionObj;
		end
	end
end

remoteTradeRequest.OnServerEvent:Connect(function(player, requestType, ...)
	local profile = shared.modProfile:Get(player);
	
	if requestType == "request" then
		local tradingEnabled = tradingServiceDatabase:Get("TradeEnabled") == true;
		
		if tradingEnabled ~= true then
			shared.Notify(player, "Trading is temporarily disabled.", "Inform");
			
			if not RunService:IsStudio() then
				return;
			end
		end
		
		if profile.TradeBan >= 1 then
			if profile.TradeBan == 2 then
				shared.Notify(player, "You are trade locked. Please contact developers as you are under investigation.", "Negative");
			else
				shared.Notify(player, "You are trade banned.", "Negative");
			end
			return;
		end
		
		local targetName = ...;
		local targetPlayer = game.Players:FindFirstChild(targetName);
		if targetPlayer == nil then
			shared.Notify(player, targetName.." is no longer in the game.", "Negative");
			return 
		end;
			
		local requestsList = TradingService.PlayerRequests[targetPlayer.Name];
		if requestsList == nil then requestsList = {}; end
		
		local selfRequestList = TradingService.PlayerRequests[player.Name];
		if selfRequestList == nil then selfRequestList = {} end;
		
		local function acceptTrade()
			if TradingService.TradeSessions[player.Name] == nil and TradingService.TradeSessions[targetPlayer.Name] == nil then
				TradingService.PlayerRequests[player.Name] = nil;
				TradingService.PlayerRequests[targetPlayer.Name] = nil;
				
				TradingService:StartTrade({Type="Player", Name=player.Name}, {Type="Player", Name=targetPlayer.Name});
				
				shared.Notify(player, "You are now trading with "..targetPlayer.Name..".", "Inform");
				shared.Notify(targetPlayer, "You are now trading with "..player.Name..".", "Inform");
				
			else
				if TradingService.TradeSessions[player.Name] then
					shared.Notify(player, "You are in a trade session!", "Negative");
					TradingService.TradeSessions[player.Name]:Sync(enumRequestTypes.Initiate);
					
					
				elseif TradingService.TradeSessions[targetPlayer.Name] then
					shared.Notify(player, targetPlayer.Name.." is in a trade session!", "Negative");
				end
			end
		end
		
		
		local targetProfile = shared.modProfile:Get(targetPlayer);
		if targetProfile and targetProfile.Settings and targetProfile.Settings.TradeFriendsOnly == 1 and not player:IsFriendsWith(targetProfile.UserId) then
			shared.Notify(player, targetPlayer.Name.." can only receive invites from friends.", "Negative");
			return;
		end

		if targetProfile.TradeBan >= 1 then
			shared.Notify(player, "The person you want to trade with is unable to trade.", "Negative");
			return;
		end
		
		if selfRequestList[targetPlayer.Name] and tick()-selfRequestList[targetPlayer.Name] < 30 then
			acceptTrade();
			
		elseif requestsList[player.Name] == nil or tick()-requestsList[player.Name] >= 10 then
			TradingService:SendTradeRequest(player, targetPlayer);
			shared.Notify(player, "Inviting "..targetPlayer.Name.." to trade, expires in 30 seconds..", "Inform");
			
		end
		
	elseif requestType == "setgold" then
		if TradingService.TradeSessions[player.Name] == nil then return end;
		local goldInput = ...;
		local sessionObj = TradingService.TradeSessions[player.Name];
		sessionObj:SetGold(player.Name, goldInput);
		
	elseif requestType == "confirm" then
		if TradingService.TradeSessions[player.Name] == nil then return end;
		local sessionObj = TradingService.TradeSessions[player.Name];
		sessionObj:SetConfirm(player.Name, true);
		
	elseif requestType == "unconfirm" then
		if TradingService.TradeSessions[player.Name] == nil then return end;
		local sessionObj = TradingService.TradeSessions[player.Name];
		sessionObj:SetConfirm(player.Name, false);
		
	elseif requestType == "cancel" then
		if TradingService.TradeSessions[player.Name] == nil then Debugger:Warn("Not in trade session."); return end;
		local sessionObj = TradingService.TradeSessions[player.Name];
		sessionObj:Cancel(player.Name);
		
	elseif requestType == "inputevent" then
		if TradingService.TradeSessions[player.Name] == nil then Debugger:Warn("Not in trade session."); return end;
		local sessionObj = TradingService.TradeSessions[player.Name];
		
		if sessionObj.OnInputEvent then
			sessionObj.OnInputEvent(...);
		end
		

	elseif requestType == "marketrequest" then
		if profile.Cache.LastMarketRequest and tick()-profile.Cache.LastMarketRequest <= 5 then return end;
		profile.Cache.LastMarketRequest = tick();

		local storageItemId = ...;
		local storageItem, storage = modStorage.FindIdFromStorages(storageItemId, player);
		
		if storageItem == nil or storageItem.ItemId ~= "newspaper" then
			Debugger:Warn("Player newspaper does not exist.");
			return
		end;
		
		local itemMarket = modTradingMarket:GetMarket("market:all");
		if itemMarket then
			for a=1, #itemMarket.List do
				itemMarket.List[a].Traders = nil;
			end
			
			remoteTradeRequest:FireClient(player, "marketrequest", itemMarket.List);
		end
		
		
		-- Wanderers information;
		remoteTradeRequest:FireClient(player, "wandererrequest", modBranchConfigs.Wanderer);
		
		
		task.spawn(function()
			local dataTable = modLeaderboardService:GetTable("WeeklyGoldDonor");

			local topOne = dataTable[1];
			if topOne and topOne.Value > 0 then
				local topDonor = {
					Name=topOne.Title;
					Value=topOne.Value;
				};

				remoteTradeRequest:FireClient(player, "topdonorrequest", topDonor);
			end
		end)
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	if TradingService.PlayerRequests[player.Name] then
		TradingService.PlayerRequests[player.Name] = nil;
	end
end)

return TradingService;
