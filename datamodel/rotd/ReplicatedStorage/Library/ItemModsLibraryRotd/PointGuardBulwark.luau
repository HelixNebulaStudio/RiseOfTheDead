local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Point-Guard Bulwark";
	
	Tags = {
		ClothingModifier = true;
	};
	Binds = {};
};
--==

function modifierPackage.onRequire()
	if RunService:IsClient() then return end;

	function modifierPackage.Binds.CharacterClassIsFocusedChanged(modifier: ItemModifierInstance, isFocused: boolean)
		if isFocused == false then return; end;
		if modifier.WieldComp == nil then return end;

		local characterClass: CharacterClass = modifier.WieldComp.CompOwner;
		if characterClass == nil then return end;

		local statusClass: StatusClassInstance? = characterClass.StatusComp:GetOrDefault("PointGuardBulwark");
		if statusClass then return; end

		characterClass.StatusComp:Apply("PointGuardBulwark", {
			Values = {
				ModifierId = modifier.Id;
			}
		});
	end
end

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "AP");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

	modifier.SumValues.PGBArmor = value;
	modifier.ProductValues.FocusWalkSpeedReduction = 0.5;
	modifier.ArrayValues.PassiveModifiers = "PointGuardBulwark";
end

return modifierPackage;