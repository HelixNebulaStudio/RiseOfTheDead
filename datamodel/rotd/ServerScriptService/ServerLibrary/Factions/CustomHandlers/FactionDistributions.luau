local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modFactionsLibrary = shared.require(game.ReplicatedStorage.Library.FactionsLibrary);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibraryRotd);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

local Handler = {};

local modFactions = nil;

function Handler.onRequire(factions)
    modFactions = factions;

    local factionsDatabase = modFactions.Database;

	factionsDatabase:OnUpdateRequest("toggledisflag", function(requestPacket)
		local factionGroup = requestPacket.Data;
		local actionPacket = requestPacket.Values;
		
        local userId = actionPacket.UserId;
        local disId = actionPacket.DisId;
        local setActive = actionPacket.SetActive;

		if not factionGroup:HasPermission(userId, "HandleDistributions") then
			requestPacket.FailMsg = "Insufficient permissions";
			return;
		end

        local disLibrary = modFactionsLibrary.DistributionsLibrary;
        local disLib = disLibrary:Find(disId);
        if disLib == nil then 
            requestPacket.FailMsg = `Distribution for {disId} no longer exist.`;
            return;
        end;

        local flagKey = `DistActive_{disId}`;

        local endOfDayTick = modSyncTime.TimeOfEndOfDay();

        local fundedFlag = `DistFunded_{disId}`;
        local fundedFlagVal = factionGroup.Flags[fundedFlag];

        if setActive == true then
            if fundedFlagVal == nil or endOfDayTick > fundedFlagVal then 
                if disLib.FundCost and factionGroup.Money < disLib.FundCost then
                    requestPacket.FailMsg = `Can not afford to enable distribution for {disId}.`;
                    return;
                end
            end

            factionGroup.Flags[flagKey] = true;
        else
            factionGroup.Flags[flagKey] = nil;
        end

		if requestPacket.Publish then
            factionGroup:Log("toggledisflag", {userId; disId; setActive and 1 or 0});
		end

		return factionGroup;
	end)

    factionsDatabase:OnUpdateRequest("claimdis", function(requestPacket)
		local factionGroup = requestPacket.Data;
		local actionPacket = requestPacket.Values;
		
        local userId = actionPacket.UserId;
        local disId = actionPacket.DisId;
        
        local disLibrary = modFactionsLibrary.DistributionsLibrary;
        local disLib = disLibrary:Find(disId);
        if disLib == nil then 
            requestPacket.FailMsg = `Distribution for {disId} no longer exist.`;
            return;
        end;

        local distActiveFlag = `DistActive_{disId}`;
        if factionGroup.Flags[distActiveFlag] ~= true then
            requestPacket.FailMsg = `Distribution for {disId} is not active.`;
            return;
        end


        local endOfDayTick = modSyncTime.TimeOfEndOfDay();
        
        if disLib.FundCost then
            local fundedFlag = `DistFunded_{disId}`;
            local fundedFlagVal = factionGroup.Flags[fundedFlag];
            if fundedFlagVal == nil or endOfDayTick > fundedFlagVal then
                if factionGroup.Money < disLib.FundCost then
                    requestPacket.FailMsg = `Can not afford to fund distribution for {disId}.`;
                    factionGroup.Flags[distActiveFlag] = nil;

                    return factionGroup;
                end

                factionGroup.Flags[fundedFlag] = endOfDayTick;
                factionGroup:AddMoney(-disLib.FundCost, `dist{disId}`);
                requestPacket.Values.FundCost = disLib.FundCost;
            end
        end

        return factionGroup;
    end)
        
    modFactions.BindInvokeHandler("toggledistributions", function(packet)
        local unixTime = packet.UnixTime;
        local player = packet.Player;

        local profile = packet.Profile;

        local factionUser = packet.FactionUser;
        local factionGroup = packet.FactionGroup;

        local args = packet.Args;
        local rPacket = packet.RPacket;

		if not factionGroup:HasPermission(player.UserId, "HandleDistributions") then
			rPacket.FailMsg = "Insufficient permissions";
			return rPacket;
		end
        
        local disId = args[1];
        if disId == nil then return end;

        if factionGroup == nil then Debugger:Warn(`Missing faction group`, packet); return end;
        local factionTag = factionGroup.Tag;

		local disLibrary = modFactionsLibrary.DistributionsLibrary;
        local disLib = disLibrary:Find(disId);
        if disLib == nil then return end;

        local flagKey = `DistActive_{disId}`;

        local isActive = factionGroup.Flags[flagKey];

        local returnPacket = factionsDatabase:UpdateRequest(factionTag, "toggledisflag", {
            UserId = player.UserId;
            DisId = disId;
            SetActive = isActive ~= true;
        });
        if returnPacket.Success then
            local factionObj = returnPacket.Data;

            rPacket.Success = true;
            rPacket.FactionObj = factionObj:Clean(player);

        else
            local failMsg = returnPacket.FailMsg;
            if failMsg then
                shared.Notify(player, `[Faction] Toggle distribution: {failMsg}`, "Negative");
            end

        end

        return rPacket;
    end)
    
    modFactions.BindInvokeHandler("claimdistribution", function(packet)
        local unixTime = packet.UnixTime;
        local player = packet.Player;

        local profile = packet.Profile;

        local factionUser = packet.FactionUser;
        local factionGroup = packet.FactionGroup;

        local args = packet.Args;
        local rPacket = packet.RPacket;

        local disId = args[1];
        if disId == nil then return end;
            
        if factionGroup == nil then Debugger:Warn(`Missing faction group`, packet); return end;
        local factionTag = factionGroup.Tag;

		local disLibrary = modFactionsLibrary.DistributionsLibrary;
        local disLib = disLibrary:Find(disId);
        if disLib == nil then return end;


        local claimDisFlag = profile.Flags:Get("FactionDisClaims");
        local claimFlagKey = `ClaimDis_{disId}`;

        local endOfDayTick = modSyncTime.TimeOfEndOfDay();
        local isAlreadyClaim = claimDisFlag[claimFlagKey] and claimDisFlag[claimFlagKey] >= endOfDayTick;

        local disName = disLib.Name;

        local itemId = disLib.ItemId;
        if itemId then
            local itemLib = modItemsLibrary:Find(itemId);
            disName = itemLib.Name;
        end

        if isAlreadyClaim then
            shared.Notify(player, `You already claim the {disName} distribution.`, "Negative");
            return;
        end

        local isDisActive = factionGroup.Flags[`DistActive_{disId}`] == true;
        if not isDisActive then
            return;
        end

        local fundedFlag = `DistFunded_{disId}`;
        local fundedFlagVal = factionGroup.Flags[fundedFlag];
        if fundedFlagVal == nil or endOfDayTick > fundedFlagVal then
            if disLib.FundCost and factionGroup.Money < disLib.FundCost then
                shared.Notify(player, `The faction can no longer afford the {disName} distribution.`, "Negative");
                return;
            end
        end

        if disLib.Type == "Item" and itemId then
            local playerSave = profile:GetActiveSave();
            local inventory = playerSave.Inventory;

            inventory:Add(itemId, {Quantity=1;}, function(queueEvent, storageItem)
                shared.modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
                shared.Notify(player, `You received {disName}.`, "Reward");
            end);
        end

        task.spawn(function()
            local rPacket = factionsDatabase:UpdateRequest(factionTag, "claimdis", {
                UserId = player.UserId;
                DisId = disId;
            });
            if rPacket.Success then
                local factionGroup = rPacket.Data;
                if rPacket.Values.FundCost then
                    modAnalyticsService:Sink{
                        Player = player;
                        Currency = modAnalyticsService.Currency.FactionMoney;
                        Amount = rPacket.Values.FundCost;
                        EndBalance = factionGroup.Money;
                        ItemSKU = `Claim:Faction_{disId}`;
                    };
                end
            end
        end)

        claimDisFlag[claimFlagKey] = endOfDayTick;
		profile.Flags:Sync("FactionDisClaims");

        rPacket.Success = true;

        return rPacket;
    end);

    -- modFactions.ConnectRefreshHandler(function(factionGroup)
    --     local endOfDayTick = modSyncTime.TimeOfEndOfDay();

    --     for k, fundedFlagVal in pairs(factionGroup) do
    --         if k:sub(1, 11) ~= "DistFunded_" then continue end;

    --         local disId = k:gsub("DistFunded_", "");
    --         local flagKey = `DistActive_{disId}`;
    --         local isActive = factionGroup.Flags[flagKey];
            
    --         if isActive and endOfDayTick > fundedFlagVal then

    --         end
    --     end
    -- end)
end

return Handler;