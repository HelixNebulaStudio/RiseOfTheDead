
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modShopLibrary = shared.require(game.ReplicatedStorage.Library.RatShopLibrary);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBattlePassLibrary = shared.require(game.ReplicatedStorage.Library.BattlePassLibrary);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modBlueprintLibrary = shared.require(game.ReplicatedStorage.Library.BlueprintLibraryRotd);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);
local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

local ShopService = {};
--==

function IsInShopRange(player, storeObject)
	if storeObject == nil then return modShopLibrary.PurchaseReplies.TooFar; end;
    if not workspace:IsAncestorOf(storeObject) then return modShopLibrary.PurchaseReplies.ShopClosed; end;

    if player:DistanceFromCharacter(storeObject.Position) > 17 then
        return modShopLibrary.PurchaseReplies.TooFar;
    end
        
    return nil;
end


function ShopService.onRequire()
    local remoteShopService = modRemotesManager:Get("ShopService");

    function remoteShopService.OnServerInvoke(player, action, ...)
        if remoteShopService:Debounce(player) then return modShopLibrary.PurchaseReplies.TooSoon; end;
        
        local playerClass: PlayerClass = shared.modPlayers.get(player);

        local profile: ProfileRotd = shared.modProfile:Get(player) :: ProfileRotd;
        local gameSave: GameSaveRotd = profile:GetActiveSave() :: GameSaveRotd;
        local inventory: Storage = gameSave.Inventory;

        Debugger:Warn(`OnServerInvoke>>`, player, action, ...);

        if action == "iteminfo" then
            local itemId = ...;
            
            local r = modItemDrops.Info(itemId);
            r.SourceText = nil;
            return r;
            
            
--=====================================================================================
        elseif action == "sellitem" then -- MARK: sellitem
            local storeObject, id, amt = ...;

            amt = shared.IsNan(amt) and 1 or amt;
            local inRange = IsInShopRange(player, storeObject); if inRange ~= nil then return inRange end;

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

                        if gameSave:AddStat("Money", sellPrice) > 0 then
                            modAnalyticsService:Source{
                                Player=player;
                                Currency=modAnalyticsService.Currency.Money;
                                Amount=sellPrice;
                                EndBalance=gameSave:GetStat("Money");
                                ItemSKU=`SellItem:{storageItem.ItemId}`;
                            };
                        end

                    end);
                    

                    local bonus = 0;
                    if modBranchConfigs.IsWorld("Safehome") then
                        bonus = math.ceil(sellPrice*0.15);
                        shared.Notify(player, ("You got $"..bonus.." bonus for selling in safehome.") , "Reward");
                        
                        if gameSave:AddStat("Money", bonus) > 0 then
                            modAnalyticsService:Source{
                                Player=player;
                                Currency=modAnalyticsService.Currency.Money;
                                Amount=bonus;
                                EndBalance=gameSave:GetStat("Money");
                                ItemSKU="SellItem:SafehomeBonus";
                            };
                        end
                    end

                    
                    local finalPrice = sellPrice + bonus;
                    if finalPrice > 0 then
                        shared.modEventService:ServerInvoke("Generic_BindTrigger", {ReplicateTo={player}}, "ShopService_Sell", {
                            Player = player;
                            FinalPrice = finalPrice;
                            StorageItem = storageItem;
                        });
                    end

                    profile:AddPlayPoints(sellPrice/1000, "Source:Money");
                    modAudio.Play("MoneyPickup", playerClass.Head);
                    
                    return modShopLibrary.PurchaseReplies.Success;
                else
                    return modShopLibrary.PurchaseReplies.InvalidItem;
                end
            else
                return modShopLibrary.PurchaseReplies.InvalidItem;
            end
            

--=====================================================================================
        elseif action == "buyitem" then -- MARK: buyitem
            local storeObject, productId = ...;

            local inRange = IsInShopRange(player, storeObject); if inRange ~= nil then return inRange end;
            local productInfo = modShopLibrary.Products:Find(productId);
            if productInfo == nil then return modShopLibrary.PurchaseReplies.InvalidProduct end;

            local itemLib = modItemsLibrary:Find(productInfo.Id);

            local currency = productInfo.Currency;
            local price = productInfo.Price;

            if inventory and gameSave.GetStat and gameSave:GetStat(currency) >= price then
                if inventory:SpaceCheck{{ItemId=itemLib.Id; Data={Quantity=(productInfo.Amount or 1)};}} then

                    gameSave:AddStat(currency, -price);
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
                
                modAnalyticsService:Sink{
                    Player=player;
                    Currency=modAnalyticsService.Currency[currency];
                    Amount=price;
                    EndBalance=gameSave:GetStat(currency);
                    ItemSKU=`BuyItem:{itemLib.Id}`;
                };

                profile:AddPlayPoints(price/1000, "Sink:Money");
                modAudio.Play("Purchase", playerClass.Head);

                return modShopLibrary.PurchaseReplies.Success;
            else
                return modShopLibrary.PurchaseReplies.InsufficientCurrency;
            end
            

--=====================================================================================
        elseif action == "buyammo" then -- MARK: buyammo
            local packet = ...;

            local interactConfig = packet.InteractConfig;
            local ammoPouchSiid = packet.AmmoPouchSiid;

            local siid = packet.Siid;
            local storageId = packet.StorageId;

            local ammoPouchData;
            local interactable: InteractableInstance;

            if ammoPouchSiid then
                local ammoPouchStorageItem = modStorage.FindIdFromStorages(ammoPouchSiid, player);
                if ammoPouchStorageItem == nil then return modShopLibrary.PurchaseReplies.InvalidProduct; end;

                ammoPouchData = modEvents:GetEvent(player, "AmmoPouchData") or {
                    Id="AmmoPouchData";
                    Charges=3;
                };

                if ammoPouchData.Charges <= 0 then
                    return modShopLibrary.PurchaseReplies.ExhaustedUses;
                end

            else
		        interactable = modInteractables.getOrNew(interactConfig);
                if interactable == nil then return modShopLibrary.PurchaseReplies.InvalidProduct; end;

                local interactPart = interactable.Part;
                local inRange = IsInShopRange(player, interactPart);
                if inRange ~= nil then return inRange end;

                if shared.modAntiCheatService:GetLastTeleport(player) <= 3 then
                    return modShopLibrary.PurchaseReplies.TooFar; 
                end;
            end

            local storage;
            
            if storageId == "portableautoturret" then
                storage = gameSave.Storages[storageId];
            else
                storage = inventory;
            end
            if storage == nil then 
                Debugger:Warn("PurchaseAmmunition>> Missing storage");
                return modShopLibrary.PurchaseReplies.InvalidProduct;
            end;
            
            local storageItem = storage:Find(siid);
            if storageItem == nil then
                Debugger:Warn("PurchaseAmmunition>> Missing storage item.");
                return modShopLibrary.PurchaseReplies.InvalidProduct;
            end
            
            local equipmentClass: EquipmentClass = playerClass.WieldComp:GetEquipmentClass(siid, storageItem.ItemId, storageItem);
            if equipmentClass == nil or equipmentClass.Class ~= "Gun" then
                Debugger:Warn("PurchaseAmmunition>> Missing equipment class.");
                return modShopLibrary.PurchaseReplies.InvalidProduct;
            end

            local ammoCurrency = modShopLibrary.AmmunitionCurrency or "Money";
            local playerCurrency = gameSave and gameSave.GetStat and gameSave:GetStat(ammoCurrency);
            local price, mags = modShopLibrary.CalculateAmmoPrice(
                storageItem.ItemId, 
                storageItem.Values, 
                equipmentClass.Configurations, 
                playerCurrency, 
                (profile :: any).Punishment == modGlobalVars.Punishments.AmmoCostPenalty
            );

            if playerCurrency < price then
                return modShopLibrary.PurchaseReplies.InsufficientCurrency;
            end
            
            if interactable then
                if interactable.Values.UseLimit then
                    local playerUses = (interactable.Values.PlayerUses[player.Name] or 0);
                    
                    if playerUses >= interactable.Values.UseLimit then
                        return modShopLibrary.PurchaseReplies.ExhaustedUses;
                    end
                    
                    interactable.Values.PlayerUses[player.Name] = playerUses +1;
                    interactable:Sync({player});
                end
            end

            gameSave:AddStat(ammoCurrency, -price);

            equipmentClass.ClassSelf:RefillAmmo(equipmentClass, storageItem);

            if ammoPouchData then
                local ammoPouchEquipmentClass: EquipmentClass = playerClass.WieldComp:GetEquipmentClass(ammoPouchSiid);
                local maxCharges = ammoPouchEquipmentClass.Configurations.BaseRefillCharge;
                
                ammoPouchData.Charges = math.clamp(ammoPouchData.Charges -1, 0, maxCharges);
                modEvents:NewEvent(player, ammoPouchData, true);
            end

            if price > 0 then
                modAnalyticsService:Sink{
                    Player=player;
                    Currency=modAnalyticsService.Currency[ammoCurrency];
                    Amount=price;
                    EndBalance=gameSave:GetStat(ammoCurrency);
                    ItemSKU=`BuyAmmo:{storageItem.ItemId}`;
                };
                
            end
    
            shared.modEventService:ServerInvoke("Shop_BindActionEvent", {ReplicateTo={player}}, "BuyAmmo", {
                StorageItem = storageItem;
                Cost = price;
            });

            profile:AddPlayPoints(price/1000, "Sink:Money");
            modAudio.Play("Purchase", playerClass.Head);
            
            shared.Notify(player, `{storageItem.Library.Name} ammunition refilled.`, "Inform");
            
            return modShopLibrary.PurchaseReplies.Success;
            

--=====================================================================================
        elseif action == "buyrepair" then -- MARK: buyrepair
            local storeObject, storageItemID = ...;

            local inRange = IsInShopRange(player, storeObject); if inRange ~= nil then return inRange end;
            
            if shared.modAntiCheatService:GetLastTeleport(player) <= 3 then
                return modShopLibrary.PurchaseReplies.TooFar; 
            end;

            local storageItem, storage = modStorage.FindIdFromStorages(storageItemID, player);
            if storage == nil then 
                Debugger:Warn("BuyRepair>> Missing storage");
                return modShopLibrary.PurchaseReplies.InvalidProduct;
            end;
            if storageItem == nil then 
                Debugger:Warn("BuyRepair>> Missing storage");
                return modShopLibrary.PurchaseReplies.InvalidProduct;
            end;

            local playerCurrency = gameSave and gameSave.GetStat and gameSave:GetStat("Money")
            local repairPrice = modShopLibrary.RepairPrice[storageItem.ItemId];
            if playerCurrency < repairPrice then
                return modShopLibrary.PurchaseReplies.InsufficientCurrency;
            end

            gameSave:AddStat("Money", -repairPrice);
            storageItem:DeleteValues("Health");
            storageItem:Sync({"Health"});

            gameSave.AppearanceData:Update(gameSave.Clothing);

            if repairPrice > 0 then
                modAnalyticsService:Sink{
                    Player=player;
                    Currency=modAnalyticsService.Currency.Money;
                    Amount=repairPrice;
                    EndBalance=gameSave:GetStat("Money");
                    ItemSKU=`Repair:{storageItem.ItemId}`;
                };
            end

            local itemLib = modItemsLibrary:Find(storageItem.ItemId);
            shared.Notify(player, itemLib.Name.." repaired.", "Inform");

            profile:AddPlayPoints(repairPrice/1000, "Sink:Money");
            modAudio.Play("Crafting1", playerClass.Head);
            
            return modShopLibrary.PurchaseReplies.Success;

            
--=====================================================================================
        elseif action == "refillcharges" then -- MARK: refillcharges
            local storeObject, storageItemID = ...;

            local inRange = IsInShopRange(player, storeObject); if inRange ~= nil then return inRange end;
            
            if shared.modAntiCheatService:GetLastTeleport(player) <= 3 then
                return modShopLibrary.PurchaseReplies.TooFar; 
            end;
            
            local storageItem, storage = modStorage.FindIdFromStorages(storageItemID, player);
            if storage == nil then 
                Debugger:Warn("BuyRepair>> Missing storage");
                return modShopLibrary.PurchaseReplies.InvalidProduct;
            end;
            if storageItem == nil then 
                Debugger:Warn("BuyRepair>> Missing storage");
                return modShopLibrary.PurchaseReplies.InvalidProduct;
            end;

            local itemId = storageItem.ItemId;

            if itemId == "ammopouch" then
                local ammoPouchData = modEvents:GetEvent(player, "AmmoPouchData") or {
                    Id="AmmoPouchData";
                    Charges=3;
                };
                
                ammoPouchData.Charges = 3;
                modEvents:NewEvent(player, ammoPouchData, true);

                storageItem:DeleteValues("C");

                shared.Notify(player, "Ammo pouch refilled.", "Inform");
                
                return modShopLibrary.PurchaseReplies.Success;
            end


--=====================================================================================
        elseif action == "exchangefortoken" then -- MARK: exchangefortoken
            local storeObject, storageItemID, amt = ...;
            amt = shared.IsNan(amt) and 1 or amt;

            local inRange = IsInShopRange(player, storeObject); if inRange ~= nil then return inRange end;
            
            if shared.modAntiCheatService:GetLastTeleport(player) <= 3 then
                return modShopLibrary.PurchaseReplies.TooFar; 
            end;

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
            modAudio.Play("Purchase", playerClass.Head);
            
            return modShopLibrary.PurchaseReplies.Success;


--=====================================================================================
        end
        return;
    end

end

return ShopService;