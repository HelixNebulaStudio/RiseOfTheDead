local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);


local presetPackage = {
    Id = "portableautoturret";
    StaticStorageId = "portableautoturret";
    Configuration = {
        Persistent = true;
        Expandable = true;
        Size = 2;
        MaxSize = 2;
        Virtual = true;
    };
};


function presetPackage.BindStorageCheck(packet)
	local dragStorageItem = packet.DragStorageItem;
	local targetIndex = packet.TargetIndex;

	if dragStorageItem.ItemId == "dualp250" then
		packet.FailMsg = "The P.A.T. only has one arm and cannot equip dual weapons.";
		packet.Allowed = false;
		return packet;
	end;
	
	if targetIndex == 1 then
		if modItemsLibrary:HasTag(dragStorageItem.ItemId, "Gun") then
			packet.Allowed = true;
			return packet;
		else
			packet.FailMsg = "P.A.T. weapon slot is only for guns.";
		end
		
	elseif targetIndex == 2 then
		if dragStorageItem.ItemId == "battery" and dragStorageItem.Quantity == 1 then
			packet.Allowed = true;
			return packet;
		elseif dragStorageItem.ItemId == "battery" and dragStorageItem.Quantity > 1 then
			packet.FailMsg = "Only put one battery in the P.A.T. battery slot.";
			
		else
			packet.FailMsg = "P.A.T. battery slot is only for batteries.";
			
		end
	end
	
	packet.Allowed = false;
	return packet;
end


function presetPackage.BindInit(storage: Storage)
    local function setWeaponSiid()
        local weaponStorageItem: StorageItem = storage:FindByIndex(1);
        if weaponStorageItem == nil then return end;
        
        storage.Values.WeaponSiid = weaponStorageItem.ID;
        storage:SyncValues();
        
        Debugger:StudioLog(`SetWeaponSiid for portableautoturret storage.`);
    end

    storage.OnChanged:Connect(setWeaponSiid);
    setWeaponSiid();

    Debugger:StudioLog(`Init storage {script.Name}.`);
end

return presetPackage;