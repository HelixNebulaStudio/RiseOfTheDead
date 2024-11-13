
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local wLayerInfo = itemMod.Library.GetLayer("W", packet);
	local wValue, wTweakVal = wLayerInfo.Value, wLayerInfo.TweakValue;
	
	if wTweakVal then
		wValue = wValue + math.ceil(wTweakVal);
	end
	
	module.ArcTracerConfig.Velocity = 100;
	module.ArcTracerConfig.MaxBounce = wValue;
	module.ArcTracerConfig.KeepAcceleration = true;

	local dlayerInfo = itemMod.Library.GetLayer("D", packet);
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

end

return itemMod;