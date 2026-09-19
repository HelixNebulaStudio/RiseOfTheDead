local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modGoldShopLibrary = shared.require(game.ReplicatedStorage.Library.GoldShopLibrary);
local modContributorShareService = shared.require(game.ServerScriptService.ServerLibrary.ContributorShareService);


local CommunityItemPackages = {
    ProductIds = {};
};


function CommunityItemPackages.onRequire()
    local productList = modGoldShopLibrary.Products:ListByMatchFunc(function(productLib)
        if productLib.Product == nil then return end;
        if productLib.Product.ShopHandler ~= "CommunityItemPackages" then return end;

        return true;
    end)

    for _, productLib in pairs(productList) do
        local productId = productLib.Product.Id;
        table.insert(CommunityItemPackages.ProductIds, productId);

        modContributorShareService.addProductId(productId);
    end
end


function CommunityItemPackages.ProcessReceipt(player: Player, receiptInfo: {
	PurchaseId: number;
	PlayerId: number;
	ProductId: number;
	PlaceIdWherePurchased: number;
	CurrencySpent: number;
	CurrencyType: Enum.CurrencyType;
	ProductPurchaseChannel: Enum.ProductPurchaseChannel;
})
    local productId = receiptInfo.ProductId;
	local productLib = modGoldShopLibrary.Products:GetProductByProductId(productId);

    if productLib == nil then
        Debugger:WarnClient(player, `ProcessReceipt: Unknown product: {productId}`);
        return;
    end
    
	local profile = shared.modProfile:Get(player);
	local inventory = profile and profile.ActiveInventory;

    if inventory == nil then
        Debugger:WarnClient(player, `ProcessReceipt: Missing inventory: {productId}`);
        return;
    end

    local quantity = (productLib.Amount or 1);
    local productInfo = productLib.Product;
    local itemId = productInfo.ItemId;

    if itemId == nil then
        Debugger:WarnClient(player, `ProcessReceipt: Invalid handler: {productId}`);
        return;
    end

    local itemLib = modItemsLibrary:Find(itemId);

    local hasInvSpace = inventory:SpaceCheck{{ItemId=itemId; Data={Quantity=quantity};}};
    if not hasInvSpace then
        shared.Notify(player, `No inventory space!`, "Negative");
        return;
    end

    inventory:Add(itemId, {Quantity=quantity;}, function(eventStatus, newStorageItem)
        shared.Notify(player, `You have purchased a {itemLib.Name}!`, "Reward");
        shared.modStorage.OnItemSourced:Fire(nil, newStorageItem, newStorageItem.Quantity);
    end);

    modContributorShareService:RecordPurchase(player, receiptInfo);

    return Enum.ProductPurchaseDecision.PurchaseGranted;
end

return CommunityItemPackages;