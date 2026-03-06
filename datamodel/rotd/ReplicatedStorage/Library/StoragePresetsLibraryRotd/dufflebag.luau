local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local presetPackage = {
    Id = "dufflebag";
    StaticStorageId = "dufflebag";
    LinkInventory = true;
    Configuration = {
        Persistent = true;
        Expandable = true;
        Size = 5;
        MaxSize = 15;
        Virtual = true;
    };
};

function presetPackage.BindInit(storage: Storage)
    storage:ConnectCheck(function(packet)
        local psItemLib = modItemsLibrary:Find(packet.DragStorageItem.ItemId);
        if psItemLib and psItemLib.StoragePresetId then
            packet.Allowed = false;
            packet.FailMsg = `You can't put storage({packet.DragStorageItem.ItemId}) into another storage.`;
            
            return packet;
        end

        packet.Allowed = true;
        return packet;
    end)
end

return presetPackage;