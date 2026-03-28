local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modDropRateCalculator = shared.require(game.ReplicatedStorage.Library.DropRateCalculator);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local UsablePreset = shared.require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

local REQUEST_STATUS = {
	MissingStorage = 1;
	MissingStorageItem = 2;
	InvalidOfferings = 3;
	InvalidStorageItemOwner = 4;
	InsufficientGold = 5;
	InsufficientInventorySpace = 6;
};
UsablePreset.RequestStatus = REQUEST_STATUS;
--==

function UsablePreset:ClientUse(storageItem: StorageItem)
	local remoteShopService = modRemotesManager:Get("ShopService");

	local offeringsWindow = modClientGuis.getWindow("OfferingsWindow");
	if offeringsWindow.Visible then
		offeringsWindow:Close();
	end

	local rPacket = remoteShopService:InvokeServer("offeringsitemreq", storageItem.ID);
	if rPacket and rPacket.Success then
		if rPacket.Values then
			for key, value in pairs(rPacket.Values) do
				storageItem:SetValues(key, value);
			end
		end
	end

	offeringsWindow:Open(storageItem);
	
	return false; -- skip invoke ServerUse
end

if RunService:IsServer() then
	local modGlobalRandom = shared.require(game.ServerScriptService.ServerLibrary.GlobalRandom);
	local modShopSystem = shared.require(game.ServerScriptService.ServerLibrary.ShopSystem);
	local modMarketSystem = shared.require(game.ServerScriptService.ServerLibrary.MarketSystem);
	local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

	UsablePreset.RollRandom = nil;

    --MARK: offeringsitemreq
    modShopSystem.RegisterActionHandler("offeringsitemreq", function(player, ...)
        local siid = ...;
        local rPacket = {};

        local storageItem: StorageItem?, storage: Storage? = shared.modStorage.FindIdFromStorages(siid, player);
        if storage == nil then 
            Debugger:Warn("OfferingsItemReq>> Missing storage");
            rPacket.Fail = REQUEST_STATUS.MissingStorage;
            return rPacket;
        end;

        if storageItem == nil then 
            Debugger:Warn("OfferingsItemReq>> Missing storageItem");
            rPacket.Fail = REQUEST_STATUS.MissingStorageItem;
            return rPacket;
        end;

		if storageItem.Player ~= player then
			Debugger:Warn("OfferingsDeny>> Not owner of storageItem");
			rPacket.Fail = REQUEST_STATUS.InvalidStorageItemOwner;
			return rPacket;
		end;

		task.spawn(function()
			UsablePreset.RollRandom = modGlobalRandom:Get(storageItem.ItemId):Clone();
		end)

        if storageItem:GetValues("O") == nil then
            local roll = math.random(1, 10);
            if roll <= 1 then
                storageItem:SetValues("O", 6);
            elseif roll <= 5 then
                storageItem:SetValues("O", 4);
            else
                storageItem:SetValues("O", 5);
            end

            local expireLength = shared.Const.OneDaySecs * 3;
            local expireTime = workspace:GetServerTimeNow() + expireLength;
            storageItem:SetValues("Expire", expireTime);
            storageItem:SetValues("ExpireLength", expireLength);
            storageItem:SetValues("NonTradeable", true);

            storageItem:Sync({"O"; "Expire"; "ExpireLength"; "NonTradeable"});

            rPacket.Success = true;
            rPacket.Values = storageItem.Values;
        end
        --Debugger:StudioWarn("OfferingsItemReq>>", rPacket);

        return rPacket;
    end)



    --MARK: offeringsactivate
    modShopSystem.RegisterActionHandler("offeringsactivate", function(player, ...)
        local siid, offerIndex = ...;
        local rPacket = {};

        local storageItem: StorageItem?, storage: Storage? = shared.modStorage.FindIdFromStorages(siid, player);
        if storage == nil then 
            Debugger:Warn("OfferingsActivate>> Missing storage");
            rPacket.Fail = REQUEST_STATUS.MissingStorage;
            return rPacket;
        end;

        if storageItem == nil then 
            Debugger:Warn("OfferingsActivate>> Missing storageItem");
            rPacket.Fail = REQUEST_STATUS.MissingStorageItem;
            return rPacket;
        end;

		if storageItem.Player ~= player then
			Debugger:Warn("OfferingsDeny>> Not owner of storageItem");
			rPacket.Fail = REQUEST_STATUS.InvalidStorageItemOwner;
			return rPacket;
		end;

        local offeringCount = storageItem:GetValues("O");
        if offeringCount == nil then 
            Debugger:Warn("OfferingsActivate>> Missing offeringCount");
            rPacket.Fail = REQUEST_STATUS.InvalidOfferings;
            return rPacket;
        end;

        if offerIndex < 1 or offerIndex > offeringCount then 
            Debugger:Warn("OfferingsActivate>> Not enough offerings");
            rPacket.Fail = REQUEST_STATUS.InvalidOfferings;
            return rPacket;
        end;

        local offersLeft = storageItem:GetValues("OL");
        if offersLeft and offersLeft <= 0 then 
            Debugger:Warn("OfferingsActivate>> No offerings left");
            rPacket.Fail = REQUEST_STATUS.InvalidOfferings;
            return rPacket;
        end;

        if offersLeft == nil then
            offersLeft = offeringCount;
        end
        offersLeft = offersLeft - 1;
        storageItem:SetValues("OL", offersLeft);

        local offerOpened = storageItem:GetValues("OO") or {};
		if table.find(offerOpened, offerIndex) then
			Debugger:Warn("OfferingsActivate>> Offer already opened");
			rPacket.Fail = REQUEST_STATUS.InvalidOfferings;
			return rPacket;
		end

        table.insert(offerOpened, offerIndex);
        storageItem:SetValues("OO", offerOpened);
        
        local rewardsLib = modRewardsLibrary:Find(storageItem.ItemId);

        local rewardInfo = modDropRateCalculator.RollDrop(rewardsLib, UsablePreset.RollRandom)[1];
		task.spawn(function() 
			UsablePreset.RollRandom = modGlobalRandom:Get(storageItem.ItemId):Clone();
		end)

        if rewardInfo then
			local rInfo = {
                ItemId = rewardInfo.ItemId;
                Quantity = rewardInfo.DropQuantity;
                Values = rewardInfo.Values;
				WinChance = rewardInfo.WinChance;
				Tier = rewardInfo.Tier;
            };
       		Debugger:Warn(`OfferingsActivate>> rewardInfo`, rInfo);

            storageItem:SetValues("R", rInfo);
			task.spawn(function()
				local price = modMarketSystem:GetCalibrateOfferingPrice(rInfo.ItemId, {
					Rarity = rInfo.WinChance;
					Tier = rInfo.Tier;
				});
				if price then
					rInfo.Price = price;
					storageItem:SetValues("R", rInfo);
					storageItem:Sync({"R"});
				end
			end)
        else
            storageItem:DeleteValues("R");
			Debugger:Warn("OfferingsActivate>> No reward info");
        end

        rPacket.Success = true;
        rPacket.Values = storageItem.Values;

        return rPacket;
    end)

	--MARK: offeringsdeny
	modShopSystem.RegisterActionHandler("offeringsdeny", function(player, ...)
		local siid = ...;
		local rPacket = {};

		local storageItem: StorageItem?, storage: Storage? = shared.modStorage.FindIdFromStorages(siid, player);
		if storage == nil then 
			Debugger:Warn("OfferingsDeny>> Missing storage");
			rPacket.Fail = REQUEST_STATUS.MissingStorage;
			return rPacket;
		end;

		if storageItem == nil then 
			Debugger:Warn("OfferingsDeny>> Missing storageItem");
			rPacket.Fail = REQUEST_STATUS.MissingStorageItem;
			return rPacket;
		end;
		if storageItem.Player ~= player then
			Debugger:Warn("OfferingsDeny>> Not owner of storageItem");
			rPacket.Fail = REQUEST_STATUS.InvalidStorageItemOwner;
			return rPacket;
		end;

		local offersLeft = storageItem:GetValues("OL");
		if offersLeft == nil or offersLeft <= 0 then
			shared.Notify(player, `{storageItem.Library.Name} has shattered!`, "Inform");
			storage:Remove(siid);

		else
			storageItem:DeleteValues("R");
			rPacket.Values = storageItem.Values;
		end

        rPacket.Success = true;
		return rPacket;
	end)

	--MARK: offeringsaccept
	modShopSystem.RegisterActionHandler("offeringsaccept", function(player, ...)
		local siid = ...;
		local rPacket = {};

		local storageItem: StorageItem?, storage: Storage? = shared.modStorage.FindIdFromStorages(siid, player);
		if storage == nil then 
			Debugger:Warn("OfferingsAccept>> Missing storage");
			rPacket.Fail = REQUEST_STATUS.MissingStorage;
			return rPacket;
		end;

		if storageItem == nil then 
			Debugger:Warn("OfferingsAccept>> Missing storageItem");
			rPacket.Fail = REQUEST_STATUS.MissingStorageItem;
			return rPacket;
		end;

		if storageItem.Player ~= player then
			Debugger:Warn("OfferingsAccept>> Not owner of storageItem");
			rPacket.Fail = REQUEST_STATUS.InvalidStorageItemOwner;
			return rPacket;
		end;

        local offerRewardInfo = storageItem:GetValues("R");
		if offerRewardInfo == nil then
			Debugger:Warn("OfferingsAccept>> Missing offerRewardInfo");
			rPacket.Fail = REQUEST_STATUS.InvalidOfferings;
			return rPacket;
		end;

		local profile = shared.modProfile:Get(player);
        local traderProfile = profile and profile.Trader;

		local itemId = offerRewardInfo.ItemId;
		local quantity = offerRewardInfo.Quantity;
		local values = offerRewardInfo.Values;
		local price = offerRewardInfo.Price;
		local itemLib = modItemsLibrary:Find(itemId);

		if traderProfile == nil or traderProfile.Gold < price then
			shared.Notify(player, "Insufficient Gold!", "Negative");
			rPacket.Fail = REQUEST_STATUS.InsufficientGold;
			return rPacket;
		end;

		local inventory = profile.ActiveInventory;
		local hasInvSpace = inventory:SpaceCheck{{ItemId=itemId; Data={Quantity=quantity};}};
		if not hasInvSpace then 
			shared.Notify(player, "Not enough inventory space!", "Negative");
			rPacket.Fail = REQUEST_STATUS.InsufficientInventorySpace;
			return rPacket; 
		end

		task.spawn(function()
			modMarketSystem:GetCalibrateOfferingPrice(itemId, {
				Rarity = offerRewardInfo.WinChance;
				Purchased = true;
			});
		end)

		storage:Remove(siid);
		inventory:Add(itemId, {Quantity=quantity; Values=values;}, function(eventStatus, newStorageItem)
			shared.Notify(player, `Thank you for purchasing {itemLib.Name}.`, "Reward");
						
			if profile.PolicyData.IsPaidItemTradingAllowed == false then
				newStorageItem:SetNonTradeable(1);
				newStorageItem:Sync();
				
			else
				shared.modStorage.OnItemSourced:Fire(nil, newStorageItem, newStorageItem.Quantity);
				
			end
		end);

		traderProfile:AddGold(-price);
		profile:AddPlayPoints(price/50, "Sink:Gold");

		modAnalyticsService:Sink{
			Player = player;
			Currency = modAnalyticsService.Currency.Gold;
			Amount = price;
			EndBalance = traderProfile.Gold;
			ItemSKU = `Offerings:{itemId}`;
		};

		if profile.Purchases[itemId] == nil then
			profile.Purchases[itemId] = 0;
		end
		profile.Purchases[itemId] = profile.Purchases[itemId] +1;

        rPacket.Success = true;

		return rPacket;
	end)

end

return UsablePreset;