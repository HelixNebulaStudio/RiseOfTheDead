local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;
	
	local layerInfo = itemMod.Library.GetLayer("F", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + math.ceil(tweakVal);
	end

	if module.Configurations.Flameburst == nil then
		module.Configurations.Flameburst = true;

		module.Configurations.ModInaccuracy = 16;
		module.Configurations.ProjectileId = "gasFlame";
		module.Configurations.KnockbackForce = value or 5;
	end
end

return itemMod;