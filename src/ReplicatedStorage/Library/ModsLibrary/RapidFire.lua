local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("RFR", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + tweakVal;
	end
	
	local newRapidFire = ((module.Configurations.AmmoLimit * module.Properties.FireRate)/1.2) * (1-value);
	if module.Configurations.RapidFire == nil or newRapidFire < module.Configurations.RapidFire then
		module.Configurations.RapidFire = newRapidFire;
	end
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;

	--local muti = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["RFR"], info.Upgrades[1].MaxLevel);
	
	--local newRapidFire = ((module.Configurations.AmmoLimit * module.Properties.FireRate)/1.2) * (1-muti);
	--if module.Configurations.RapidFire == nil or newRapidFire < module.Configurations.RapidFire then
	--	module.Configurations.RapidFire = newRapidFire;
	--end
end

return Mod;