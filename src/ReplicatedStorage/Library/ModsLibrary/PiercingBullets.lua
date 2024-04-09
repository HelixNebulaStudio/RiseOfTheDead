local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("PB", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end
	
	local basePiercing = module.Configurations.BasePiercing;

	local newPiercing = basePiercing + math.ceil(value);
	if module.Properties.Piercing == nil or newPiercing > module.Properties.Piercing then
		module.Properties.Piercing = newPiercing;
	end
	
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local add = ModsLibrary.Linear(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["PB"], info.Upgrades[1].MaxLevel);
	--local basePiercing = module.Configurations.BasePiercing;
	
	--local newPiercing = basePiercing + math.ceil(add);
	--if module.Properties.Piercing == nil or newPiercing > module.Properties.Piercing then
	--	module.Properties.Piercing = newPiercing;
	--end
end

return Mod;