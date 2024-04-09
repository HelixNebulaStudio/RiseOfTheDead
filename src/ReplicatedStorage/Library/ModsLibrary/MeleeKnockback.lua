local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("KB", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end
	
	local baseKnockback = module.Configurations.BaseKnockback or 0;
	local additional = baseKnockback * value;

	module.Configurations.Knockback = (module.Configurations.Knockback or baseKnockback) + additional;
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local muti = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["KB"], info.Upgrades[1].MaxLevel);
	--local baseKnockback = module.Configurations.BaseKnockback or 0;
	--local additional = baseKnockback*muti;
	
	--module.Configurations.Knockback = (module.Configurations.Knockback or baseKnockback) + additional;
end

return Mod;