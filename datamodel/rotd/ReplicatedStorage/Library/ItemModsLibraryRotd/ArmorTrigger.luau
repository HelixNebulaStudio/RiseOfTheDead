local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Armor Trigger";
	
	Tags = {
		ClothingModifier = true;
	};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	modifier.SumValues.ArmorPoints = 1000;
end

return modifierPackage;