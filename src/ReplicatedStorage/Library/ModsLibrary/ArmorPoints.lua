local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local storageItem = packet.ModStorageItem;
	local module = packet.WeaponModule;
	
	local info = modModsLibrary.Get(storageItem.ItemId);
	if module:RegisterTypes(info, storageItem) then return end;
	
	local layerInfo = modModsLibrary.GetLayer("AP", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	module.ModArmorPoints = module.BaseArmorPoints + value;
	
	--local storageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = modModsLibrary.Get(storageItem.ItemId);
	--if module:RegisterTypes(info, storageItem) then return end;
	
	--local values = storageItem.Values;
	--local add = modModsLibrary.Linear(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["AP"], info.Upgrades[1].MaxLevel);
	
	--module.ModArmorPoints = module.BaseArmorPoints + add;
end

return Mod;
