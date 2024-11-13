local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("SF", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + tweakVal;
	end
	
	local baseFocusTime = module.Configurations.BaseFocusDuration or 1;
	local focusTimeReduction = baseFocusTime * value;
	local newFocusTime = baseFocusTime-focusTimeReduction;
	
	if newFocusTime < module.Configurations.FocusDuration then
		module.Configurations.FocusDuration = newFocusTime;
	end
	
end

return itemMod;