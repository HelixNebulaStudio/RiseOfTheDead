local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UsablePreset = shared.require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

UsablePreset.PortableStoragePresetId = "portableautoturret";

function UsablePreset:ClientUse(storageItem)
	local player = game.Players.LocalPlayer;
	local modData = shared.require(player:WaitForChild("DataModule") :: ModuleScript);
	
	local storage = modData.RequestStorage{Action="GetStorage"; StorageIds={storageItem.ID}};
	if storage and type(storage) == "table" then
		modAudio.Preload("TorqueWrench", 5);
		modAudio.Play("TorqueWrench");
		
		storage.Name = "AutoTurret";
		
		modData.SetStorage(storage);
		
		modClientGuis.toggleWindow("AutoTurretWindow", true, storageItem);
	else
		Debugger:Warn("Storage does not exist.");
	end
end

function UsablePreset.StorageCheck(packet)
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

local function setWeaponId(storage)
	local player = storage.Player;
	local profile = shared.modProfile:Find(player.Name);
	if profile == nil then return end;
	
	local playerSave = profile:GetActiveSave();
	
	local storageSiid = storage.Values.Siid;
	if storageSiid == nil then return end;
	local clothingStorage = playerSave.Clothing;
	local patStorageItem = clothingStorage:Find(storageSiid);
	
	local weaponStorageItem = storage:FindByIndex(1); -- StorageIndexEnums
	
	local accessories = playerSave.AppearanceData:GetAccessories(storageSiid);
	for a=1, #accessories do
		accessories[a]:SetAttribute("WeaponStorageItemID", weaponStorageItem and weaponStorageItem.ID or nil);
	end
	
	if patStorageItem == nil then return end;
	patStorageItem:SetValues("EquippedWeapon", weaponStorageItem and weaponStorageItem.ID or nil):Sync{"EquippedWeapon"};
end
function UsablePreset.InitStorage(storage)
	setWeaponId(storage);
end

function UsablePreset.ConnectChanged(storage)
	setWeaponId(storage);
end


return UsablePreset;