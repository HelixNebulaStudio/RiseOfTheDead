local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modifierPackage = {
	Name = "Warmonger Scales";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local hpkLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "HPK");
	local hpkValue, hpkTweakVal = hpkLayerInfo.Value, hpkLayerInfo.TweakValue;
	if hpkTweakVal then
		hpkValue = hpkValue + hpkTweakVal;
	end

	local hpLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "HP");
	local hpValue, hpTweakVal = hpLayerInfo.Value, hpLayerInfo.TweakValue;
	if hpTweakVal then
		hpValue = hpValue + hpTweakVal;
	end

	modifier.Values.HealthPerKill = hpkValue;
	modifier.Values.Max = hpValue;
end

return modifierPackage;