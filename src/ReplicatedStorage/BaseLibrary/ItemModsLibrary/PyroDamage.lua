local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("D", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + tweakVal;
	end

	module.Configurations.Damage = module.Configurations.Damage + value;
	
end

return itemMod;