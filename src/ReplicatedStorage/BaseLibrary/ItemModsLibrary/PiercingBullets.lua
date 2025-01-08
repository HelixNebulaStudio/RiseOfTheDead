local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("PB", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end
	
	local basePiercing = module.Configurations.BasePiercing;

	local newPiercing = basePiercing + math.ceil(value);
	if module.Properties.Piercing == nil or newPiercing > module.Properties.Piercing then
		module.Properties.Piercing = newPiercing;
	end
	
end

return itemMod;