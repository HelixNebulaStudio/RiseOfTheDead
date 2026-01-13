local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Bow Ricochet";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	modItemModifierClass.AddTierDamage(modifier);
	
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "R");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	if tweakVal then
		value = value + math.ceil(tweakVal);
	end

	modifier.SetValues.ProjectileConfig = {
		MaxBounce = 1;
		LifeTime = 3;
		Velocity = 175;
		Modifiers = {
			Ricochet = true;
		}
	}
end

return modifierPackage;