local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBattlePassLibrary = require(game.ReplicatedStorage.Library.BattlePassLibrary);

return function(event: EventPacket, profile: Profile, points: number?, reason: string?)
    local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
    local player: Player = profile.Player;

    local cooldowns = profile.Cache.MpBookPointsCooldown;
    if cooldowns == nil then
        profile.Cache.MpBookPointsCooldown = {};
        cooldowns = profile.Cache.MpBookPointsCooldown;
    end
    
    reason = reason or "Generic";
    local isCooldown = cooldowns[reason];
    if isCooldown and isCooldown > tick() then
        return;
    end
    cooldowns[reason] = tick() + math.random(300, 900);


    local playPointsStats = profile.Cache.PlayPoints;
    if playPointsStats and points > 1 and math.random(1, 2) == 1 then
        local activeId = modBattlePassLibrary.Active;
        if activeId == nil then return end;

        local unixTime = DateTime.now().UnixTimestamp;
        local bpLib = modBattlePassLibrary:Find(activeId);
        
        if bpLib.EndUnixTime == nil or unixTime > bpLib.EndUnixTime then return end
       
		local activeInventory = profile.ActiveInventory;
        if activeInventory == nil then return end;

        local eventId = `pointstats_{activeId}`;
        local dropPacket = modEvents:GetEvent(player, eventId) or {
            Id=eventId;
            ActiveBp=activeId;
            LastDrop=os.time();
            NextDrop=os.time()+180;
            Drops=0;
        };

        local function dropTrigger(reasonStr)

            if bpLib.EventBooksActive then
                local hasSpace = activeInventory:SpaceCheck{
                    {ItemId="mpbook"; Data={Quantity=1};}
                };
                if not hasSpace then return; end

                Debugger:Warn(`Drop mpbook for {player} total {dropPacket.Drops}`);
    
                local itemLib = modItemsLibrary:Find("mpbook");
                activeInventory:Add(itemLib.Id, nil, function(queueEvent, storageItem)
                    shared.Notify(player, `You recieved a {itemLib.Name}{reasonStr or ""}!`, "Reward", nil, {SndId="Collectible"});
                    shared.modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
                end);

            end
        end

        if os.time() > dropPacket.NextDrop then
            local oneHour = 3600;
            local dropCount = dropPacket.Drops;
            if dropCount <= 3 then
                dropPacket.NextDrop=os.time()+180;

            elseif dropCount <= 6 then
                dropPacket.NextDrop=os.time()+math.random(300-60, 300+60);

            elseif dropCount <= 10 then
                dropPacket.NextDrop=os.time()+math.random(600-120, 600+120);

            elseif dropCount <= 20 then
                dropPacket.NextDrop=os.time()+math.random(900-240, 900+240);

            elseif dropCount <= 200 then
                dropPacket.NextDrop=os.time()+math.random(1200-480, 1200+480);

            else
                dropPacket.NextDrop=os.time()+math.random(1200+960, (oneHour*4)+4800);

            end

            local reasonStr;
            if reason == "Gameplay:Minigame:Fotl" then
                reasonStr = " from playing Fall of the Living";

            elseif reason == "Sink:Gold" then
                reasonStr = " from spending Gold";

            elseif reason == "Source:Reward" then
                reasonStr = " from obtaining loot";

            elseif reason == "Gameplay:Mission" then
                reasonStr = " from completing a mission";

            elseif reason == "Gameplay:Unlock" then
                reasonStr = " from unlocking something new";

            elseif reason == "Gameplay:Kill:Zombie" then
                reasonStr = " from killing zombies";

            elseif reason == "Gameplay:Kill:Enemies" then
                reasonStr = " from killing enemies";

            elseif reason == "Gameplay:Kill" then
                reasonStr = " from killing";

            elseif reason == "Gameplay:Use" then
                reasonStr = " from using something";
                
            elseif reason == "Gameplay:Use:Instrument" then
                reasonStr = " from playing a instrument";
                
            elseif reason == "Source:Money" then
                reasonStr = " from earning money";
                
            elseif reason == "Sink:Money" then
                reasonStr = " from spending Money";

            elseif reason == "Sink:Robux" then
                reasonStr = " from spending Robux";
    
            elseif reason == "Source:Perks" then
                reasonStr = " from earning Perks";
    
            elseif reason == "Gameplay:Workbench" then
                reasonStr = " from using the workbench";
    
            elseif reason == "Gameplay:Dialogue" then
                reasonStr = " from talking to someone";
    
            elseif reason == "Sink:Perks" then
                reasonStr = " from spending Perks";
            else
                reasonStr = " for some reason";
            end

            dropTrigger(reasonStr);

            dropPacket.Drops = dropPacket.Drops +1;
            dropPacket.LastDrop = os.time();
        end

        modEvents:NewEvent(player, dropPacket);

    end
end;