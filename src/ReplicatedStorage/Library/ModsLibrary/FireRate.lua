local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("FR", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	local baseFireRate = module.Properties.BaseFireRate;

	local baseRpm = 60/baseFireRate;
	local newFirerate = 60/(baseRpm * (1+value));

	module.Properties.FireRate = newFirerate;
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local muti = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["FR"], info.Upgrades[1].MaxLevel);
	--local baseFireRate = module.Properties.BaseFireRate;
	
	--local baseRpm = 60/baseFireRate;
	--local newFirerate = 60/(baseRpm * (1+muti));

	--module.Properties.FireRate = newFirerate;

end

return Mod;