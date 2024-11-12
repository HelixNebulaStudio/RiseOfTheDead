local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;
	
	local layerInfo = itemMod.Library.GetLayer("AC", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

	if module.Configurations.BaseMaxAmmo == nil then
		module.Configurations.BaseMaxAmmo = module.Configurations.MaxAmmoLimit;
	end
	local baseMaxAmmo = module.Configurations.BaseMaxAmmo;

	module.Configurations.MaxAmmoLimit = module.Configurations.MaxAmmoLimit + math.ceil(baseMaxAmmo * value);
end

return itemMod;