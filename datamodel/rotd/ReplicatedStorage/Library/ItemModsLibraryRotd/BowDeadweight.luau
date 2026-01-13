local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Bow Deadweight";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local wLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "W");
	local wValue, wTweakVal = wLayerInfo.Value, wLayerInfo.TweakValue;
	if wTweakVal then
		wValue = wValue + wTweakVal;
	end


	local dLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "D");
	local dValue, dTweakVal = dLayerInfo.Value, dLayerInfo.TweakValue;
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end
	
	assert(modifier.EquipmentClass, `Missing equipment class: {modifier}`);
	modItemModifierClass.AddTierDamage(modifier);

	modifier.SetValues.ProjectileConfig = {
		Velocity = 100;
		MaxBounce = wValue;
		KeepAcceleration = true;
	};
end

return modifierPackage;