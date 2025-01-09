local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--=
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;
	local storageItem = packet.ModStorageItem;

	local layerInfo = itemMod.Library.GetLayer("HP", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end
	
	local info = itemMod.Library.Get(storageItem.ItemId);
	if module:RegisterTypes(info, storageItem) then return end;
	
	module.ModHealthPoints = (module.BaseHealthPoints or 0) + value;
end

return itemMod;