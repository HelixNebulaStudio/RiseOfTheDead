local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;
	local storageItem = packet.ModStorageItem;

	local info = itemMod.Library.Get(storageItem.ItemId);
	if module:RegisterTypes(info, storageItem) then return end;

	local hpkLayerInfo = itemMod.Library.GetLayer("HPK", packet);
	local hpkValue, hpkTweakVal = hpkLayerInfo.Value, hpkLayerInfo.TweakValue;

	if hpkTweakVal then
		hpkValue = hpkValue + hpkTweakVal;
	end

	local hpLayerInfo = itemMod.Library.GetLayer("HP", packet);
	local hpValue, hpTweakVal = hpLayerInfo.Value, hpLayerInfo.TweakValue;

	if hpTweakVal then
		hpValue = hpValue + hpTweakVal;
	end
	
	module:RegisterPlayerProperty("WarmongerScales", {
		HealthPerKill=hpkValue;
		Max=hpValue;
	}, true);
end

return itemMod;