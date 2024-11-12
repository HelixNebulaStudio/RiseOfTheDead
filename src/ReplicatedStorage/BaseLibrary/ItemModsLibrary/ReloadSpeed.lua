local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("RT", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + tweakVal;
	end
	
	local baseReloadTime = module.Properties.BaseReloadSpeed;
	local reloadtimeReduction = baseReloadTime * value;
	local newReloadSpeed = math.clamp(baseReloadTime-reloadtimeReduction, 0.0333, 100);

	if newReloadSpeed < module.Properties.ReloadSpeed then
		module.Properties.ReloadSpeed = newReloadSpeed;
	end
	
end

return itemMod;