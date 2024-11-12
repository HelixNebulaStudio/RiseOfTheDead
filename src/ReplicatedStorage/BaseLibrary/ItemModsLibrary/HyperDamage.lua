local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local dLayerInfo = itemMod.Library.GetLayer("D", packet);
	local dValue, dTweakVal = dLayerInfo.Value, dLayerInfo.TweakValue;
	
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end

	local frLayerInfo = itemMod.Library.GetLayer("FR", packet);
	local frValue, frTweakVal = frLayerInfo.Value, frLayerInfo.TweakValue;

	if frTweakVal then
		frValue = frValue + frTweakVal;
	end
	
	local preModDmg = module.Configurations.PreModDamage;
	local additionalDmg = preModDmg * dValue;
	module.Configurations.Damage = module.Configurations.Damage + additionalDmg;
	module.Properties.Rpm = module.Properties.Rpm + frValue;

end

return itemMod;