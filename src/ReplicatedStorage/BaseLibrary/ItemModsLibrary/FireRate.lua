local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("FR", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	local baseFireRate = module.Properties.BaseFireRate;

	local baseRpm = 60/baseFireRate;
	local newFirerate = 60/(baseRpm * (1+value));

	module.Properties.FireRate = newFirerate;

end

return itemMod;