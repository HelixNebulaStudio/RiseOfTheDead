local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("GR", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	module.AdditionalStamina = module.BaseAdditionalStamina + math.ceil(value);
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;

	--local muti = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["GR"], info.Upgrades[1].MaxLevel);
	
	--module.AdditionalStamina = module.BaseAdditionalStamina + math.ceil(muti);
end

return Mod;
