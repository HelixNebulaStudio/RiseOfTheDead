local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local presetPackage = {
    Id = "npcstorage";
    Configuration = {
        Persistent = true; 
        Size = 5; 
        MaxSize = 5;
        Virtual = true;
    };
};

function presetPackage.BindInit(storage: Storage)

    storage.OnChanged:Connect(function()
        local player = storage.Player;
        local npcName = storage.Properties.NpcName;

        Debugger:Warn(`{storage.Player} npc {npcName} storage OnChanged: {storage.Id}`);

        local npcClass: NpcClass? = shared.modNpcs.getPlayerNpc(player, npcName);
        if npcClass == nil then return end;

        shared.modEventService:ServerInvoke(
            "Survivor_BindInventoryChanged", 
            {ReplicateTo={player}}, 
            npcClass, 
            storage
        );
        
        local storageItemIndexList = storage:GetIndexDictionary();

        local activeWeapon = storageItemIndexList[1] or storageItemIndexList[2];
        if activeWeapon then
            npcClass.Properties.CutsceneEquip = activeWeapon.ItemId;
            
            npcClass.WieldComp:Equip{
                ItemId = activeWeapon.ItemId;
                ItemCustomizations = activeWeapon.Values["_Customs"];
            };
            npcClass.WieldComp:InvokeToolAction("ToggleIdle");

        else
            npcClass.WieldComp:Unequip();

        end
    end);
end

function presetPackage.BindStorageCheck(packet)
    local dragStorageItem = packet.DragStorageItem;
    local targetIndex: number = packet.TargetIndex;
    
    if targetIndex == 1 then -- primary weapon slot;
        if modItemsLibrary:HasTag(dragStorageItem.ItemId, "Primary Weapon") then
            packet.Allowed = true;
        else
            packet.FailMsg = "This slot is only for primary weapons.";
            packet.Allowed = false;

        end
        
    elseif targetIndex == 2 then -- secondary weapon slot;
        if modItemsLibrary:HasTag(dragStorageItem.ItemId, "Secondary Weapon") then
            packet.Allowed = true;
        else
            packet.FailMsg = "This slot is only for secondary weapons.";
            packet.Allowed = false;

        end

    elseif targetIndex == 3 then -- melee weapon slot;
        if modItemsLibrary:HasTag(dragStorageItem.ItemId, "Melee") then
            packet.Allowed = true;
        else
            packet.FailMsg = "This slot is only for melee weapons.";
            packet.Allowed = false;

        end
        
    elseif targetIndex == 4 then -- clothing slot;
        if modItemsLibrary:HasTag(dragStorageItem.ItemId, "Clothing") then
            packet.Allowed = true;
        else
            packet.FailMsg = "This slot is only for melee weapons.";
            packet.Allowed = false;

        end

    elseif targetIndex == 5 then -- misc slot;
        packet.Allowed = true;

    else
        packet.Allowed = false;
    end
    
    return packet;
end

return presetPackage;