local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local dLayerInfo = itemMod.Library.GetLayer("D", packet);
	local dValue, dTweakVal = dLayerInfo.Value, dLayerInfo.TweakValue;
	
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end

	local aLayerInfo = itemMod.Library.GetLayer("A", packet);
	local aValue, aTweakVal = aLayerInfo.Value, aLayerInfo.TweakValue;
	
	if aTweakVal then
		aValue = aValue + aTweakVal;
	end
	
	
	local preModDamage = module.Configurations.PreModDamage;
	local additionalDmg = preModDamage * dValue;
	module.Configurations.Damage = module.Configurations.Damage + additionalDmg;

	if module.Configurations.Deadeye == nil or aValue > module.Configurations.Deadeye then
		module.Configurations.Deadeye = aValue;
		
	end
	
end

return itemMod;