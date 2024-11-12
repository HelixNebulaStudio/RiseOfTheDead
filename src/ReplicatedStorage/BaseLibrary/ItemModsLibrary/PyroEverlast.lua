local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("BD", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + math.ceil(tweakVal);
	end
	
	module.Configurations.EverlastDuration = (module.Configurations.EverlastDuration or 0) + value;
	module.Configurations.AmmoCost = 2;

end

return itemMod;