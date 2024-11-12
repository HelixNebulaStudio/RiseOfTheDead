local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("HSM", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + tweakVal;
	end
	
	local baseHeadshotMultiplier = module.Configurations.BaseHeadshotMultiplier or 0;

	module.Configurations.HeadshotMultiplier = baseHeadshotMultiplier + value;
	
end

return itemMod;