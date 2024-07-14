local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
repeat task.wait() until shared.MasterScriptInit == true;

--== Variables;
local MarketplaceService = game:GetService("MarketplaceService");
local PurchaseHistory = game:GetService("DataStoreService"):GetDataStore("PurchaseHistory");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modShopLibrary = require(game.ReplicatedStorage.Library.RatShopLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modBlueprintLibrary = require(game.ReplicatedStorage.Library.BlueprintLibrary);
local modGoldShopLibrary = require(game.ReplicatedStorage.Library.GoldShopLibrary);
local modBattlePassLibrary = require(game.ReplicatedStorage.Library.BattlePassLibrary);

local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modLimitedService = require(game.ServerScriptService.ServerLibrary.LimitedService);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modAnalyticsService = require(game.ServerScriptService.ServerLibrary.AnalyticsService);

local remoteShopService = modRemotesManager:Get("ShopService");
local remoteGoldShopPurchase = modRemotesManager:Get("GoldShopPurchase");

--== Script;

function IsInShopRange(player, storeObject)
	if game.ReplicatedStorage.Library:FindFirstChild("CustomShopLibrary") then
		modShopLibrary = require(game.ReplicatedStorage.Library.CustomShopLibrary) :: any;
	end
	if storeObject then
		if storeObject:IsDescendantOf(workspace) and player:DistanceFromCharacter(storeObject.Position) <= 17 then
			return nil;
		elseif not storeObject:IsDescendantOf(workspace) then
			return modShopLibrary.PurchaseReplies.ShopClosed;
		end
	end
	return modShopLibrary.PurchaseReplies.TooFar;
end

function remoteShopService.OnServerInvoke(player, action, ...)
	if remoteShopService:Debounce(player) then return modShopLibrary.PurchaseReplies.TooSoon; end;
	
	if action == "iteminfo" then
		local itemId = ...;
		
		local r = modItemDrops.Info(itemId);
		r.SourceText = nil;
		return r;
		
	elseif action == "sellitem" then -- MARK: sellitem
		local storeObject, id, amt = ...;

		amt = shared.IsNan(amt) and 1 or amt;
		local inRange = IsInShopRange(player, storeObject); if inRange ~= nil then return inRange end;

		local profile = modProfile:Get(player);
		local playerSave = profile:GetActiveSave();
		local inventory = profile.ActiveInventory;

		local storageItem = inventory ~= nil and inventory:Find(id) or nil;
		local itemLib = storageItem and modItemsLibrary:Find(storageItem.ItemId) or nil;
		local bpLib = itemLib and modBlueprintLibrary.Get(itemLib.Id) or nil;

		if itemLib then
			local price = modShopLibrary.SellPrice[itemLib.Id]
				or bpLib and (bpLib.SellPrice or (bpLib.Tier and modShopLibrary.SellPrice["Tier"..bpLib.Tier])) or nil;
			if price then
				local sellAmt = math.clamp(amt or 1, 1, storageItem.Quantity);
				local sellPrice = sellAmt * price;

				inventory:Remove(id, sellAmt, function()
					shared.Notify(player, ("Sold $Amt $Item for $$Price."):gsub("$Amt", sellAmt):gsub("$Item", itemLib.Name):gsub("$Price", sellPrice), "Reward");
					Debugger:Log("Player (",player.Name,") sold a",itemLib.Name,"for $"..sellPrice);

					if playerSave:AddStat("Money", sellPrice) > 0 then
						modAnalytics.RecordResource(player.UserId, sellPrice, "Source", "Money", "Sold", storageItem.ItemId);
						modAnalyticsService:Source{
							Player=player;
							Currency=modAnalyticsService.Currency.Money;
							Amount=sellPrice;
							EndBalance=playerSave:GetStat("Money");
							ItemSKU=`SellItem:{storageItem.ItemId}`;
						};
					end

				end);
				

				local bonus = 0;
				if modBranchConfigs.IsWorld("Safehome") then
					bonus = math.ceil(sellPrice*0.15);
					shared.Notify(player, ("You got $"..bonus.." bonus for selling in safehome.") , "Reward");
					
					if playerSave:AddStat("Money", bonus) > 0 then
						modAnalytics.RecordResource(player.UserId, bonus, "Source", "Money", "Sold", "SafehomeBonus");
						modAnalyticsService:Source{
							Player=player;
							Currency=modAnalyticsService.Currency.Money;
							Amount=bonus;
							EndBalance=playerSave:GetStat("Money");
							ItemSKU="SellItem:SafehomeBonus";
						};
					end
				end

				
				local finalPrice = sellPrice + bonus;
				if finalPrice > 0 then
					if not modMission:IsComplete(player, 67) then
						modMission:Progress(player, 67, function(mission)
							mission.SaveData.Money = mission.SaveData.Money +finalPrice;
							if mission.SaveData.Money >= mission.SaveData.MaxMoney then
								modMission:CompleteMission(player, 67);
							end
						end)
					end
				end

				profile:AddPlayPoints(sellPrice/1000, "Source:Money");
				return modShopLibrary.PurchaseReplies.Success;
			else
				return modShopLibrary.PurchaseReplies.InvalidItem;
			end
		else
			return modShopLibrary.PurchaseReplies.InvalidItem;
		end
		
	elseif action == "buyitem" then -- MARK: buyitem
		local storeObject, productId = ...;

		local inRange = IsInShopRange(player, storeObject); if inRange ~= nil then return inRange end;
		local productInfo = modShopLibrary.Products:Find(productId);
		if productInfo == nil then return modShopLibrary.PurchaseReplies.InvalidProduct end;

		local itemLib = modItemsLibrary:Find(productInfo.Id);

		local profile = modProfile:Get(player);

		local playerSave = profile:GetActiveSave();
		local inventory = profile.ActiveInventory;

		local currency = productInfo.Currency;
		local price = productInfo.Price;

		if inventory and playerSave.GetStat and playerSave:GetStat(currency) >= price then
			if inventory:SpaceCheck{{ItemId=itemLib.Id; Data={Quantity=(productInfo.Amount or 1)};}} then

				playerSave:AddStat(currency, -price);
				inventory:Add(itemLib.Id, {Quantity=(productInfo.Amount or 1);}, function(queueEvent, storageItem)
					shared.Notify(player, "You purchased ".. ((productInfo.Amount or 1) > 1 and productInfo.Amount or "a").." ".. itemLib.Name, "Reward");
					Debugger:Log("Player (",player.Name,") purchased a",itemLib.Name);

					if itemLib.Id == "gps" and modMission:Progress(player, 49) then
						modMission:Progress(player, 49, function(mission)
							if mission.ProgressionPoint == 1 then
								mission.ProgressionPoint = 2;
							end;
						end)
					end
					
					modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
				end);
			else
				return modShopLibrary.PurchaseReplies.InventoryFull;
			end
			
			modAnalytics.RecordResource(player.UserId, price, "Sink", currency, "Purchase", itemLib.Id);
			modAnalyticsService:Sink{
				Player=player;
				Currency=modAnalyticsService.Currency[currency];
				Amount=price;
				EndBalance=playerSave:GetStat(currency);
				ItemSKU=`BuyItem:{itemLib.Id}`;
			};

			profile:AddPlayPoints(price/1000, "Sink:Money");
			return modShopLibrary.PurchaseReplies.Success;
		else
			return modShopLibrary.PurchaseReplies.InsufficientCurrency;
		end
		
	elseif action == "buyammo" then -- MARK: buyammo
		local storeObject, id, storageId = ...;

		local inRange = IsInShopRange(player, storeObject); if inRange ~= nil then return inRange end;
		
		if shared.modAntiCheatService:GetLastTeleport(player) <= 3 then
			return modShopLibrary.PurchaseReplies.TooFar; 
		end;

		local profile = modProfile:Get(player);
		local playerSave = profile:GetActiveSave();
		local storage;
		
		if storageId == "portableautoturret" then
			storage = playerSave.Storages[storageId];
		else
			storage = profile.ActiveInventory;
		end
		if storage == nil then 
			Debugger:Warn("PurchaseAmmunition>> Missing storage");
			return modShopLibrary.PurchaseReplies.InvalidProduct;
		end;
		
		local storageItem = storage:Find(id);
		local weaponModule = profile:GetItemClass(id);
		
		local interactModule = storeObject:FindFirstChild("Interactable") or storeObject.Parent:FindFirstChild("Interactable");
		if interactModule == nil then
			Debugger:Warn("Missing interactable");
			return modShopLibrary.PurchaseReplies.InvalidProduct;
		end
		
		local interactData = shared.saferequire(player, interactModule);
		
		if interactData and interactData.UseLimit then
			local playerUses = (interactData.PlayerUses[player.Name] or 0);
			
			if playerUses >= interactData.UseLimit then
				return modShopLibrary.PurchaseReplies.ExhaustedUses;
			end
			
			interactData.PlayerUses[player.Name] = playerUses +1;
			interactData:Sync();
		end
		
		if storageItem == nil then
			Debugger:Warn("PurchaseAmmunition>> Missing storage item.");
			return modShopLibrary.PurchaseReplies.InvalidProduct;
		end
		
		
		local currency = modShopLibrary.AmmunitionCurrency or "Money";
		local playerCurrency = playerSave and playerSave.GetStat and playerSave:GetStat(currency)
		local price, mags = modShopLibrary.CalculateAmmoPrice(storageItem.ItemId, storageItem.Values, weaponModule.Configurations, playerCurrency, profile.Punishment == modGlobalVars.Punishments.AmmoCostPenalty);
		if playerCurrency < price then
			return modShopLibrary.PurchaseReplies.InsufficientCurrency;
		end
		
		playerSave:AddStat(currency, -price);
		local totalMags = (weaponModule.Configurations.MaxAmmoLimit + weaponModule.Configurations.AmmoLimit)/weaponModule.Configurations.AmmoLimit;
		if totalMags == mags then
			storageItem:SetValues("A", weaponModule.Configurations.AmmoLimit);
			storageItem:SetValues("MA", weaponModule.Configurations.MaxAmmoLimit);
		else
			local currentAmmo = storageItem.Values["A"] or weaponModule.Configurations.AmmoLimit;
			local currentMaxAmmo = storageItem.Values["MA"] or weaponModule.Configurations.MaxAmmoLimit;
			local remainingBullets = mags*weaponModule.Configurations.AmmoLimit;

			if weaponModule.Configurations.AmmoLimit > currentAmmo then
				remainingBullets = remainingBullets - (weaponModule.Configurations.AmmoLimit - currentAmmo);
				storageItem:SetValues("A", weaponModule.Configurations.AmmoLimit);
			end
			if weaponModule.Configurations.MaxAmmoLimit > currentMaxAmmo then
				if currentMaxAmmo+remainingBullets >= weaponModule.Configurations.MaxAmmoLimit then
					storageItem:SetValues("MA", weaponModule.Configurations.MaxAmmoLimit);
				else
					storageItem:SetValues("MA", currentMaxAmmo+remainingBullets);
				end
			end
		end
		
		storageItem:Sync({"A", "MA"});

		if price > 0 then
			modAnalytics.RecordResource(player.UserId, price, "Sink", currency, "Gameplay", "Ammo");
			modAnalyticsService:Sink{
				Player=player;
				Currency=modAnalyticsService.Currency[currency];
				Amount=price;
				EndBalance=playerSave:GetStat(currency);
				ItemSKU=`BuyAmmo:{storageItem.ItemId}`;
			};
			
		end
 
		modOnGameEvents:Fire("OnRatShopAction", player, {
			Action="BuyAmmo";
			StorageItem=storageItem;
			Cost=price;
		});

		profile:AddPlayPoints(price/1000, "Sink:Money");
		
		local itemLib = modItemsLibrary:Find(storageItem.ItemId);
		shared.Notify(player, itemLib.Name.." ammunition refilled.", "Info");
		
		return modShopLibrary.PurchaseReplies.Success;
		
	elseif action == "buyrepair" then -- MARK: buyrepair
		local storeObject, storageItemID = ...;

		local inRange = IsInShopRange(player, storeObject); if inRange ~= nil then return inRange end;
		
		if shared.modAntiCheatService:GetLastTeleport(player) <= 3 then
			return modShopLibrary.PurchaseReplies.TooFar; 
		end;

		local profile = modProfile:Get(player);
		local activeSave = profile:GetActiveSave();

		local storageItem, storage = modStorage.FindIdFromStorages(storageItemID, player);
		if storage == nil then 
			Debugger:Warn("BuyRepair>> Missing storage");
			return modShopLibrary.PurchaseReplies.InvalidProduct;
		end;
		if storageItem == nil then 
			Debugger:Warn("BuyRepair>> Missing storage");
			return modShopLibrary.PurchaseReplies.InvalidProduct;
		end;

		local playerCurrency = activeSave and activeSave.GetStat and activeSave:GetStat("Money")
		local repairPrice = modShopLibrary.RepairPrice[storageItem.ItemId];
		if playerCurrency < repairPrice then
			return modShopLibrary.PurchaseReplies.InsufficientCurrency;
		end

		activeSave:AddStat("Money", -repairPrice);
		storageItem:DeleteValues("Health");
		storageItem:Sync({"Health"});

		local playerSave = profile:GetActiveSave();
		playerSave.AppearanceData:Update(playerSave.Clothing);

		if repairPrice > 0 then
			modAnalytics.RecordResource(player.UserId, repairPrice, "Sink", "Money", "Gameplay", "Repair");
			modAnalyticsService:Sink{
				Player=player;
				Currency=modAnalyticsService.Currency.Money;
				Amount=repairPrice;
				EndBalance=playerSave:GetStat("Money");
				ItemSKU=`Repair:{storageItem.ItemId}`;
			};
		end

		local itemLib = modItemsLibrary:Find(storageItem.ItemId);
		shared.Notify(player, itemLib.Name.." repaired.", "Info");
		
		return modShopLibrary.PurchaseReplies.Success;

	elseif action == "exchangefortoken" then -- MARK: exchangefortoken
		local storeObject, storageItemID, amt = ...;
		amt = shared.IsNan(amt) and 1 or amt;

		local inRange = IsInShopRange(player, storeObject); if inRange ~= nil then return inRange end;
		
		if shared.modAntiCheatService:GetLastTeleport(player) <= 3 then
			return modShopLibrary.PurchaseReplies.TooFar; 
		end;

		local profile = modProfile:Get(player);
		local inventory = profile.ActiveInventory;

		local storageItem, storage = modStorage.FindIdFromStorages(storageItemID, player);
		if storage == nil then 
			Debugger:Warn("ExchangeForTokens>> Missing storage");
			return modShopLibrary.PurchaseReplies.InvalidProduct;
		end;
		if storageItem == nil then 
			Debugger:Warn("ExchangeForTokens>> Missing storage");
			return modShopLibrary.PurchaseReplies.InvalidProduct;
		end;

		local itemId = storageItem.ItemId;
		local isExchangable = modItemsLibrary:HasTag(itemId, "Skin Perm") or modItemsLibrary:HasTag(itemId, "Color Pack") or modItemsLibrary:HasTag(itemId, "Skin Pack");
		if not isExchangable then
			Debugger:Warn("ExchangeForTokens>> Missing storage");
			return modShopLibrary.PurchaseReplies.InvalidProduct;
		end

		local battlePassSave = profile.BattlePassSave;
		local activeId = modBattlePassLibrary.Active;

		local passData = battlePassSave:GetPassData(activeId);
		if passData == nil then
			shared.Notify(player, `No available event pass.`, "Negative");
			return modShopLibrary.PurchaseReplies.ShopClosed;
		end

		local tokenValue = 1;
		local exchangeAmt = math.clamp(amt or 1, 1, storageItem.Quantity);
		local totalTokens = exchangeAmt * tokenValue;

		inventory:Remove(storageItem.ID, exchangeAmt, function()
			shared.Notify(player, `Exchanged {exchangeAmt} {storageItem.Library.Name} for {totalTokens} Gift Shop Tokens!`, "Reward");
		end);

		battlePassSave:AddTokens(activeId, totalTokens);
		profile:AddPlayPoints(totalTokens/10, "Source:Reward");
		
		return modShopLibrary.PurchaseReplies.Success;

	end
	return;
end

function remoteGoldShopPurchase.OnServerInvoke(player, key)
	if remoteGoldShopPurchase:Debounce(player) then return 2 end;

	local profile = modProfile:Get(player);
	local traderProfile = profile and profile.Trader;
	local inventory = profile and profile.ActiveInventory;
	
	local productInfo = modGoldShopLibrary.Products:Find(key);
	if productInfo and traderProfile and inventory then
		local productType = productInfo.Product.Type;
		
		if productType == "ThirdParty" then
			--Debugger:Log("productInfo", productInfo);
			local assetId = productInfo.Product.Id;
			local itemId = productInfo.Product.ItemId;
			
			if assetId == nil or itemId == nil then return end;

			local itemLib = modItemsLibrary:Find(itemId);
			
			local userOwnGamePass;
			pcall(function()
				userOwnGamePass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, productInfo.Product.Id);
			end)
			if userOwnGamePass == nil then
				shared.Notify(player, "Failed to check if player already has ".. itemLib.Name , "Negative");
				return;
			end
			
			local marketInfo;
			pcall(function()
				marketInfo = MarketplaceService:GetProductInfo(productInfo.Product.Id, productInfo.Product.ProductInfoType);
			end)
			if marketInfo == nil then return end;
			if marketInfo.IsForSale == false then
				shared.Notify(player, itemLib.Name .." is currently not for sale." , "Negative");
				return;
			end
			if marketInfo.CanBeSoldInThisGame == false then
				shared.Notify(player, itemLib.Name .." currently can't be sold in this environment." , "Negative");
				return;
			end

			local productKey = tostring(assetId);
			if userOwnGamePass == true then
				if profile.Purchases[productKey] ~= 1 then
					shared.Notify(player, "Thank you for purchasing " ..itemLib.Name.. ". It can now be claimed from the gold shop at anytime", "Reward");
					profile:AddPlayPoints(marketInfo.PriceInRobux/100, "Sink:Robux");
					
					profile.Purchases[productKey] = 1;
				end
				
				local storageItem, itemStorage = modStorage.FindItemIdFromStorages(itemId, player);
				if storageItem then
					shared.Notify(player, "You already have a ".. itemLib.Name .." in storage: " ..itemStorage.Name , "Negative");
					return 4;
					
				else
					local hasInvSpace = inventory:SpaceCheck{{ItemId=itemId; Data={Quantity=1};}};
					if not hasInvSpace then return 3; end

					inventory:Add(itemId, {Quantity=1;}, function(eventStatus, newStorageItem)
						shared.Notify(player, "You have claimed your " ..itemLib.Name.. ", enjoy!", "Reward");
						
						modStorage.OnItemSourced:Fire(nil, newStorageItem, newStorageItem.Quantity);
					end);
					return 1;
				end
				
			else
				return 0;
			end
			
		elseif productType == "Battlepass" then
			
			local bpId = productInfo.Id;
			if modBattlePassLibrary.Active ~= bpId then
				Debugger:Warn("This battlepass is not active.");
				return 4;
			end
			local bpLib = modBattlePassLibrary:Find(bpId);
			
			
			return 0;
			
		else
			if productInfo.NotForSale then
				return 5;
			end
			
			local price = productInfo.Product.Price;
			local playerGold = traderProfile.Gold;

			if playerGold >= price then
				if productInfo.Product.ItemId then
					local itemId = productInfo.Product.ItemId;
					local quantity = (productInfo.Amount or 1);

					local itemLib = modItemsLibrary:Find(itemId);

					local hasInvSpace = inventory:SpaceCheck{{ItemId=itemId; Data={Quantity=quantity};}};
					if not hasInvSpace then 
						shared.Notify(player, "Not enough inventory space!", "Negative");
						return 3; 
					end
					
					if productInfo.LimitedId ~= nil then
						local success = modLimitedService:SubtractStock(productInfo.LimitedId);
						if not success then
							shared.Notify(player, itemLib.Name .." is out of stock!", "Negative");
							return 5;
						end
					end
					
					inventory:Add(itemId, {Quantity=quantity;}, function(eventStatus, newStorageItem)
						shared.Notify(player, string.gsub("Thank you for purchasing $Item.", "$Item", productInfo.TitleText or itemLib.Name), "Reward");
						
						if profile.PolicyData.IsPaidItemTradingAllowed == false then
							newStorageItem:SetNonTradeable(1);
							newStorageItem:Sync();
							
						else
							modStorage.OnItemSourced:Fire(nil, newStorageItem, newStorageItem.Quantity);
							
						end
					end);

					traderProfile:AddGold(-price);
					profile:AddPlayPoints(price/100, "Sink:Gold");
					modAnalytics.RecordResource(player.UserId, price, "Sink", "Gold", "Purchase", itemId);

					modAnalyticsService:Sink{
						Player=player;
						Currency=modAnalyticsService.Currency.Gold;
						Amount=price;
						EndBalance=traderProfile.Gold;
						ItemSKU=`Purchase:{itemId}`;
					};

					if profile.Purchases[itemId] == nil then
						profile.Purchases[itemId] = 0;
					end
					profile.Purchases[itemId] = profile.Purchases[itemId] +1;

				end

				return 0;
			else
				shared.Notify(player, "Insufficient Gold!", "Negative");
				return 1;
			end
		end
	else
		return 4;
	end
end

local ProductCache = {}
function MarketplaceService.ProcessReceipt(receiptInfo)
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId);
	local ProductInfo = ProductCache[receiptInfo.ProductId];
	
	if not ProductInfo then
		ProductInfo = MarketplaceService:GetProductInfo(receiptInfo.ProductId, Enum.InfoType.Product);
		ProductCache[receiptInfo.ProductId] = ProductInfo;
	end
	
	local purchaseKey = receiptInfo.PlayerId..":"..receiptInfo.PurchaseId;
	
	local purchaseStatus = false;
	local getStatusSuccess = pcall(function() purchaseStatus = PurchaseHistory:GetAsync(purchaseKey); end)
	if getStatusSuccess and purchaseStatus then return Enum.ProductPurchaseDecision.PurchaseGranted; end;
	
	local productId = receiptInfo.ProductId;
	local productInfo = modGoldShopLibrary.Products:GetProduct(productId);
	
	if productInfo == nil then warn("MarketplaceService>> ProcessReceipt: Invalid product."); return Enum.ProductPurchaseDecision.NotProcessedYet; end;
	if player == nil then warn("MarketplaceService>> ProcessReceipt: Player unavailable."); return Enum.ProductPurchaseDecision.NotProcessedYet; end;
	
	local profile = modProfile:Get(player);
	local productData = productInfo.Product;
	
	if productData.Perks then
		local playerSave = profile:GetActiveSave();
		playerSave:AddStat("Perks", productData.Perks, true);
		shared.Notify(player, ("Thank you for purchasing $Amount Perks."):gsub("$Amount", productData.Perks), "Reward");
	
		modAnalyticsService:Source{
			Player=player;
			Currency=modAnalyticsService.Currency.Perks;
			Amount=productData.Perks;
			EndBalance=playerSave:GetStat("Perks");
			TransactionType=Enum.AnalyticsEconomyTransactionType.IAP;
			ItemSKU=`BuyPerks:{productData.Perks}`;
		};
		
	elseif productData.Gold then
		local traderProfile = profile.Trader;
		traderProfile:AddGold(productData.Gold);
		shared.Notify(player, ("Thank you for purchasing $Amount Gold."):gsub("$Amount", productData.Gold), "Reward");
		modAnalytics.RecordResource(player.UserId, productData.Gold, "Source", "Gold", "Purchase", tostring(productData.Gold));
		
		modAnalyticsService:Source{
			Player=player;
			Currency=modAnalyticsService.Currency.Gold;
			Amount=productData.Gold;
			EndBalance=traderProfile.Gold;
			TransactionType=Enum.AnalyticsEconomyTransactionType.IAP;
			ItemSKU=`BuyGold:{productData.Gold}`;
		};

	end
	
	local productKey = tostring(productId);
	if profile.Purchases[productKey] == nil then profile.Purchases[productKey] = 0; end;
	profile.Purchases[productKey] = profile.Purchases[productKey] +1;
	
	Debugger:Log("ProcessReceipt Successful",receiptInfo);
	profile:AddPlayPoints(receiptInfo.CurrencySpent, `Source:{productData.Perks and "Perks" or "Gold"}`);
	profile:Save();
	
	PurchaseHistory:SetAsync(purchaseKey, true);
	
	return Enum.ProductPurchaseDecision.PurchaseGranted;
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, ID, Purchased)
	if not Purchased then return end
	Debugger:Log("PromptGamePassPurchaseFinished", player, ID, Purchased);
	
	local GamepassInfo = ProductCache[ID]
	
	if not GamepassInfo then
		GamepassInfo = MarketplaceService:GetProductInfo(ID, Enum.InfoType.GamePass)
		ProductCache[ID] = GamepassInfo
	end
	
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	
	local productKey = tostring(ID);
	profile.Purchases[productKey] = 1;
	
	if ID == 2517190 then
		activeSave:AwardAchievement("theeng");
	end;
	
	shared.Notify(player, ("Thank you for purchasing $Name."):gsub("$Name", GamepassInfo.Name), "Reward");
	--modAnalytics:RecordTransaction(player, "Gamepass:"..GamepassInfo.Name, GamepassInfo.PriceInRobux);
end)

workspace.AllowThirdPartySales = true;