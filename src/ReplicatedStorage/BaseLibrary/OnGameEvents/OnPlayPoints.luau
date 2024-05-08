local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBattlePassLibrary = require(game.ReplicatedStorage.Library.BattlePassLibrary);

local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

return function(profile, points: number?, reason: string?)
    local player: Player = profile.Player;

    local playPointsStats = profile.Cache.PlayPoints;
    if playPointsStats and points > 1 then
        Debugger:StudioWarn("playPointsStats", points, reason);

        local activeId = modBattlePassLibrary.Active;
        if activeId == nil then return end;
        
		local activeInventory = profile.ActiveInventory;
        if activeInventory == nil then return end;

        local hasSpace = activeInventory:SpaceCheck{
            {ItemId="mpbook"; Data={Quantity=1};}
        };
        if not hasSpace then
            return;
        end

        local dropPacket = modEvents:GetEvent(player, "mpBookDrop") or {
            Id="mpBookDrop";
            LastDrop=os.time();
            NextDrop=os.time()+180;
            Drops=0;
            SessionDrops=0;
        };

        if os.time() > dropPacket.NextDrop then
            local timeSinceLastDrop = os.time()-dropPacket.LastDrop;

            if timeSinceLastDrop >= (3600 * 8) then
                dropPacket.SessionDrops = 0;
            end

            local dropDifficulty = dropPacket.SessionDrops
            if dropDifficulty <= 3 then
                dropPacket.NextDrop=os.time()+180;

            elseif dropDifficulty <= 6 then
                dropPacket.NextDrop=os.time()+math.random(300-60, 300+60);

            elseif dropDifficulty <= 10 then
                dropPacket.NextDrop=os.time()+math.random(600-120, 600+120);

            else
                dropPacket.NextDrop=os.time()+math.random(1200-240, 1200+240);

            end

            Debugger:Warn(`Drop mpbook for {player} total {dropPacket.Drops}`);

            local itemLib = modItemsLibrary:Find("mpbook");
            activeInventory:Add(itemLib.Id, nil, function(queueEvent, storageItem)
				shared.Notify(player, `You recieved a {itemLib.Name}!`, "Reward", nil, {SndId="Collectible"});
				shared.modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
			end);

            dropPacket.Drops = dropPacket.Drops +1;
            dropPacket.SessionDrops = dropPacket.SessionDrops +1;
            dropPacket.LastDrop = os.time();
        end

        modEvents:NewEvent(player, dropPacket);

    end
end;