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
	
	local baseKnockoutDuration = module.Configurations.BaseKnockoutDuration or 0;
	local new = baseKnockoutDuration + value;

	if module.Configurations.KnockoutDuration == nil or module.Configurations.KnockoutDuration < new then
		module.Configurations.KnockoutDuration = new;
	end
end

return itemMod;