local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);
local modWeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local wLayerInfo = modModsLibrary.GetLayer("W", packet);
	local wValue, wTweakVal = wLayerInfo.Value, wLayerInfo.TweakValue;
	
	if wTweakVal then
		wValue = wValue + math.ceil(wTweakVal);
	end
	
	module.ArcTracerConfig.Velocity = 100;
	module.ArcTracerConfig.MaxBounce = wValue;
	module.ArcTracerConfig.KeepAcceleration = true;

	local dlayerInfo = modModsLibrary.GetLayer("D", packet);
	local dValue, dTweakVal = dlayerInfo.Value, dlayerInfo.TweakValue;
	
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end
	
	local baseDamage = module.Configurations.PreModDamage; -- BaseDamage

	local additionalDmg = baseDamage * dValue;
	if module.Configurations.Deadweight == nil then
		module.Configurations.Deadweight = true;

		module.Configurations.Damage = module.Configurations.Damage + additionalDmg;
	end
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;

	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;

	--local dmgMulti = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["D"], info.Upgrades[1].MaxLevel);
	--local weights = ModsLibrary.Linear(info.Upgrades[2].BaseValue, info.Upgrades[2].MaxValue, values["W"], info.Upgrades[2].MaxLevel);
	
	--module.ArcTracerConfig.Velocity = 100;
	--module.ArcTracerConfig.MaxBounce = weights;
	--module.ArcTracerConfig.KeepAcceleration = true;
	
	
	--local baseDamage = module.Configurations.PreModDamage; -- BaseDamage

	--local additionalDmg = baseDamage*dmgMulti;
	--if module.Configurations.Deadweight == nil then
	--	module.Configurations.Deadweight = true;
		
	--	module.Configurations.Damage = module.Configurations.Damage + additionalDmg;
	--end
end

return Mod;