local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibraryRotd);

function modItemDrops.InfoRotd(itemId, sourceStrs, sourceList, stepName, ...)

    local modShopLibrary = shared.require(game.ReplicatedStorage.Library.GeneralShopLibrary);
    local shopIndexedList = modShopLibrary.Products:GetIndexList();
    for a=1, #shopIndexedList do
        if shopIndexedList[a].Id == itemId then
            sourceList.RatShop = {
                Price=shopIndexedList[a].Price;
                Currency=shopIndexedList[a].Currency;
                PremiumOnly=shopIndexedList[a].PremiumOnly == true;
            }
            
            table.insert(sourceStrs, `Shop - {
                shopIndexedList[a].Price
            } {
                shopIndexedList[a].Currency
            } {
                shopIndexedList[a].PremiumOnly == true and "(Premium)" or ""
            }`);
        end
    end


    local modBlueprintLibrary = shared.require(game.ReplicatedStorage.Library.BlueprintLibraryRotd);
    modBlueprintLibrary:Loop(function(key, lib)
        if lib.Product ~= itemId then return end;
        sourceList.Blueprint = lib.Id;

        table.insert(sourceStrs, `Blueprint - {lib.Name} ({lib.Id})` );
        
        local dropTableScrList, dropTableStrList = modItemDrops.searchDropTables(lib.Id, lib.Name);
        for a=1, #dropTableScrList do
            table.insert(sourceList.RewardSrcs, dropTableScrList[a]);
        end
        for a=1, #dropTableStrList do
            table.insert(sourceStrs, dropTableStrList[a]);
        end
    end)

    
    local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);

    -- Gamemode drops
    for gm, _ in pairs(modGameModeLibrary.GameModes) do
        for sn, _ in pairs(modGameModeLibrary.GameModes[gm].Stages) do
            local stageLib = modGameModeLibrary.GameModes[gm].Stages[sn];

            local rewardIds = stageLib.RewardsIds or {};
            if stageLib.RewardsId and table.find(rewardIds, stageLib.RewardsId) then
                table.insert(rewardIds, stageLib.RewardsId);
            end

            for a=1, #rewardIds do
                if rewardIds[a] == itemId then
                    table.insert(sourceList.RewardSrcs, {GameMode=gm; StageName=sn;})
                    break;
                end
            end
        end
    end

    
    local modFactionsLibrary = shared.require(game.ReplicatedStorage.Library.FactionsLibrary);
    if modFactionsLibrary.DistributionsLibrary then
        local disLibrary = modFactionsLibrary.DistributionsLibrary;
        local disLib = disLibrary:Find(itemId);
        if disLib and disLib.ItemId == itemId then
            table.insert(sourceStrs, `Faction Distributions`); 
        end
    end
        
end

return modItemDrops;