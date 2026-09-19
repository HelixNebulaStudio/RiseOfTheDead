local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);
local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);

local modifierPackage = {
	Name = "Automatic Trigger";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	modItemModifierClass.AddTierDamage(modifier);
	modifier.SetValues.TriggerMode = modWeaponAttributes.TriggerModes.Automatic;
end

return modifierPackage;