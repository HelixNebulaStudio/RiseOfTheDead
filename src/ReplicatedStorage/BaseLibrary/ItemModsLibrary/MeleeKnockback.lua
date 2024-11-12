local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("KB", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end
	
	local baseKnockback = module.Configurations.BaseKnockback or 0;
	local additional = baseKnockback * value;

	module.Configurations.Knockback = (module.Configurations.Knockback or baseKnockback) + additional;
end

return itemMod;