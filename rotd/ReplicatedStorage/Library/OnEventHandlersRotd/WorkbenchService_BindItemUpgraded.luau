local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModsLibrary = shared.require(game.ReplicatedStorage.Library.ItemModsLibrary);

return function(event: EventPacket, ...)
    local player = event.Player;
    if player == nil then return end;

    local storageItem: StorageItem = ...;

    task.spawn(function()
        local profile = shared.modProfile:Get(player) :: ProfileRotd;
        local gameSave = profile:GetActiveSave() :: GameSaveRotd;
        
        local modLib = modItemModsLibrary.Get(storageItem.ItemId);
        
        if modLib.Module.Name == "Damage"  then
            local maxLevel = 10;
            for a=1, #modLib.Upgrades do
                if modLib.Upgrades[a].DataTag == "D" then
                    maxLevel = modLib.Upgrades[a].MaxLevel;
                    break;
                end
            end
            if storageItem.Values and storageItem.Values.D == maxLevel then
                gameSave:AwardAchievement("dammas");
            end
        end
    end)
end