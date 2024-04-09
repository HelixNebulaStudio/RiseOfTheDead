local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);
local modWeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("F", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end
	
	if module.FlinchMod and value < module.FlinchMod then return end;
	module.FlinchMod = value;

	module.FlinchProtection = module.FlinchProtection + value;
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local level = math.clamp((values["F"] or 0), 0, info.Upgrades[1].MaxLevel);
	--local add = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, level, info.Upgrades[1].MaxLevel);
	
	--if module.FlinchMod and add < module.FlinchMod then return end;
	--module.FlinchMod = add;
	
	--module.FlinchProtection = module.FlinchProtection + add;
end

return Mod;