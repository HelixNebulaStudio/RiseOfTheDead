local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBattlePassLibrary = shared.require(game.ReplicatedStorage.Library.BattlePassLibrary);

return function(event: EventPacket, profile: ProfileRotd, points: number?, reason: string?)
    local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
    local player: Player = profile.Player;


    local reasonStr;
    if reason == "Gameplay:Minigame:Fotl" then
        reasonStr = "playing Fall of the Living";

    elseif reason == "Sink:Gold" then
        reasonStr = "spending Gold";

    elseif reason == "Source:Reward" then
        reasonStr = "obtaining loot";

    elseif reason == "Gameplay:Mission" then
        reasonStr = "completing a mission";

    elseif reason == "Gameplay:Unlock" then
        reasonStr = "unlocking something new";

    elseif reason == "Gameplay:Kill:Zombie" then
        reasonStr = "killing zombies";

    elseif reason == "Gameplay:Kill:Enemies" then
        reasonStr = "killing enemies";

    elseif reason == "Gameplay:Kill" then
        reasonStr = "killing";

    elseif reason == "Gameplay:Use" then
        reasonStr = "using something";
        
    elseif reason == "Gameplay:Use:Instrument" then
        reasonStr = "playing a instrument";
        
    elseif reason == "Source:Money" then
        reasonStr = "earning money";
        
    elseif reason == "Sink:Money" then
        reasonStr = "spending Money";

    elseif reason == "Sink:Robux" then
        reasonStr = "spending Robux";

    elseif reason == "Source:Perks" then
        reasonStr = "earning Perks";

    elseif reason == "Gameplay:Workbench" then
        reasonStr = "using the workbench";

    elseif reason == "Gameplay:Dialogue" then
        reasonStr = "talking to someone";

    elseif reason == "Sink:Perks" then
        reasonStr = "spending Perks";
    else
        reasonStr = "some reason";
    end

    --MARK: StrangeCardReward
    local strangeCardFlag = profile.Flags:Get("StrangeCardPoints", {
        Id="StrangeCardPoints";
        Points=0;
        LastDrop=0;
    });
    strangeCardFlag.Points = (strangeCardFlag.Points or 0) + (points or 0);

    if profile.Cache.StrangeCardPending ~= true then
        profile.Cache.StrangeCardPending = true;
        task.spawn(function()
            local thresholdPercent = profile:GetPlayerConfig("PlaySessionThreshold") or 0.4;
            local globalAvg = shared.modProfile.getConfigAsync("GlobalSessionPlayPointsAverage") or 2000;
            local threshold = globalAvg * thresholdPercent;

            local flag = profile.Flags:Get("StrangeCardPoints");
            if flag == nil then
                profile.Cache.StrangeCardPending = false;
                return;
            end

            local oneHour = shared.Const.Hour;
            if (flag.Points or 0) < threshold or os.time() - (flag.LastDrop or 0) < oneHour then
                profile.Cache.StrangeCardPending = false;
                return;
            end

            local activeId = modBattlePassLibrary.Active;
            if activeId == nil then
                profile.Cache.StrangeCardPending = false;
                return;
            end

            local unixTime = DateTime.now().UnixTimestamp;
            local bpLib = modBattlePassLibrary:Find(activeId);
            if bpLib == nil or bpLib.EndUnixTime == nil or unixTime > bpLib.EndUnixTime then
                profile.Cache.StrangeCardPending = false;
                return;
            end

            local battlePassSave = profile.BattlePassSave;
            local passData = battlePassSave:GetPassData(activeId);
            if passData == nil then
                profile.Cache.StrangeCardPending = false;
                return;
            end

            profile.Cache.StrangeCardPending = false;

            local droppedPoints = flag.Points;
            flag.Points = 0;
            flag.LastDrop = os.time();
            profile.Flags:Sync("StrangeCardPoints");

            passData.Cards = passData.Cards or {};
            passData.Cards["strange"] = (passData.Cards["strange"] or 0) + 1;
            battlePassSave:Sync();

			task.spawn(function()
				profile:GuiAction("cardsreceived", {"strange"});
			end)

            Debugger:Warn(`Dropped strange card for {player}, points: {droppedPoints} threshold: {threshold}`);
            
            shared.Notify(
                player, 
                `You received a Strange event card for {reasonStr}!`,
                "Reward", 
                nil, 
                {SndId="Collectible"}
            );
        end);
    end

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
        
        if bpLib == nil or bpLib.EndUnixTime == nil or unixTime > bpLib.EndUnixTime then return end
       
		local activeInventory = profile.ActiveInventory;
        if activeInventory == nil then return end;

        local eventId = `pointstats_{activeId}`;
        local dropPacket = modEvents:GetEvent(player, eventId) or {
            Id = eventId;
            ActiveBp = activeId;
            LastDrop = os.time();
            NextDrop = os.time()+180;
            Drops = 0;
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
                    shared.Notify(
                        player, 
                        `You recieved a {itemLib.Name} for {reasonStr}!`, 
                        "Reward", 
                        nil, 
                        {SndId="Collectible"}
                    );
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


            dropTrigger(reasonStr);

            dropPacket.Drops = dropPacket.Drops +1;
            dropPacket.LastDrop = os.time();
        end

        modEvents:NewEvent(player, dropPacket);

    end
end;