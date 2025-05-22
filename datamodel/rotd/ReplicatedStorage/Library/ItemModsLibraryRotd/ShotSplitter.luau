local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modifierPackage = {
	Name = "Shot Splitter";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local dmgLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "D");
	local dmgValue, dmgTweak = dmgLayerInfo.Value, dmgLayerInfo.TweakValue;
	if dmgTweak then
		dmgValue = dmgValue + dmgTweak;
	end

	local frLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "FR");
	local frValue, frTweak = frLayerInfo.Value, frLayerInfo.TweakValue;
	if frTweak then
		frValue = frValue + frTweak;
	end

	modifier.SumValues.DamageScaler = dmgValue;
	modifier.SumValues.Rpm = frValue;
	
	modifier.SetValues.Multishot = 2;
end

return modifierPackage;