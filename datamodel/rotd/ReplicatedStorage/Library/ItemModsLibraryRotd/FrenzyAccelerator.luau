local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Frenzy Accelerator";
	
	Tags = {
		GunModifier = true;
	};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "R");
	local value = layerInfo.Value;

	modifier.MaxValues.FrenzyRate = value;
end

return modifierPackage;