local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("RFR", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + tweakVal;
	end
	
	local newRapidFire = ((module.Configurations.AmmoLimit * module.Properties.FireRate)/1.2) * (1-value);
	if module.Configurations.RapidFire == nil or newRapidFire < module.Configurations.RapidFire then
		module.Configurations.RapidFire = newRapidFire;
	end
	
end

return itemMod;