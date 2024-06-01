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
end

return Mod;