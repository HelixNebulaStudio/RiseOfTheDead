local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local baseCritMulti = module.Configurations.BaseCritMulti;
	if baseCritMulti == nil then return; end
	
	local layerInfo = itemMod.Library.GetLayer("M", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end
	
	local muti = baseCritMulti + value;

	if module.Configurations.CritMulti == nil or module.Configurations.CritMulti < muti then
		module.Configurations.CritMulti = muti;
	end
end

return itemMod;