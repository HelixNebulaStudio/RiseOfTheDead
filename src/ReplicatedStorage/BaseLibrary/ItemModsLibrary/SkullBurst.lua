local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("F", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + tweakVal;
	end
	
	--local baseRpm = module.Properties.BaseRpm;
	--local skullBurstRpm = baseRpm * value;

	if module.Configurations.SkullBurst == nil or value > module.Configurations.SkullBurst then
		module.Configurations.SkullBurst = value;
	end
end

return itemMod;