local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Nekrosis Amplifier";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)

	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "A");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

	modifier.SetValues.NekrosisAmpMulti = value;
	
	if modifier.EquipmentClass == nil
	or modifier.EquipmentClass.BaseModifiers == nil
	or modifier.EquipmentClass.BaseModifiers.Nekrosis == nil then return end;

	local baseVal = modifier.EquipmentClass.BaseModifiers.Nekrosis.SetValues.NekrosisHeal;
	modifier.MaxValues.NekrosisHeal = (baseVal+value);
end

return modifierPackage;