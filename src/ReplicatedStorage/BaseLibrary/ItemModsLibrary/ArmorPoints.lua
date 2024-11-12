local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

function itemMod.Activate(packet)
	local storageItem = packet.ModStorageItem;
	local module = packet.WeaponModule;
	
	local info = itemMod.Library.Get(storageItem.ItemId);
	if module:RegisterTypes(info, storageItem) then return end;
	
	local layerInfo = itemMod.Library.GetLayer("AP", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	module.ModArmorPoints = module.BaseArmorPoints + value;
end

return itemMod;