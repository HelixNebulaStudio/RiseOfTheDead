local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("FR", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + math.ceil(tweakVal);
	end

	if module.Configurations.Rocketman ~= true then
		module.Properties.Rpm = module.Properties.Rpm + value;
		module.Configurations.Rocketman = true;
	end
	
end

return itemMod;