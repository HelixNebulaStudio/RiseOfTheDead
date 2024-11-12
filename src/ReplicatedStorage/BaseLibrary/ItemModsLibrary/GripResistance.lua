local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("GR", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	module.AdditionalStamina = module.BaseAdditionalStamina + math.ceil(value);
end

return itemMod;