
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("M", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

	local baseAmmoMag = module.Configurations.BaseAmmoLimit;

	module.Configurations.AmmoLimit = module.Configurations.AmmoLimit + math.ceil(value);
end

return itemMod;