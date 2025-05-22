local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modifierPackage = {
	Name = "Pacifist Amulet";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local apLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "AP");
	local apValue, apTweakVal = apLayerInfo.Value, apLayerInfo.TweakValue;
	if apTweakVal then
		apValue = apValue + apTweakVal;
	end
	
	local arLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "AR");
	local arValue, arTweakVal = arLayerInfo.Value, arLayerInfo.TweakValue;
	if arTweakVal then
		arValue = arValue + arTweakVal;
	end

	modifier.Values.AddAp = apValue;
	modifier.Values.AddAr = arValue;
end

return modifierPackage;