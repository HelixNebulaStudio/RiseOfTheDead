local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("AC", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if layerInfo.UpgradeInfo.Scaling == 0 then
		if tweakVal then
			value = value + math.floor(tweakVal);
		end
		
		module.Configurations.MaxAmmoLimit = module.Configurations.MaxAmmoLimit + value;
		
	elseif layerInfo.UpgradeInfo.Scaling == 1 then
		if tweakVal then
			value = value + tweakVal;
		end

		local ammoLimit = module.Configurations.AmmoLimit;
		module.Configurations.MaxAmmoLimit = module.Configurations.MaxAmmoLimit + math.ceil(ammoLimit * value);
		
	end
end

return itemMod;