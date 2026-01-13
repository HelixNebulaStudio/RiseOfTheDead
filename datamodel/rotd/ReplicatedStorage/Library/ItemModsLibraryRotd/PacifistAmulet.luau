local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Pacifist Amulet";
	
	Tags = {};
	Binds = {};
};
--==
if RunService:IsServer() then
	function modifierPackage.Binds.WieldCompEquipStateChanged(modifier: ItemModifierInstance)
		local wieldComp: WieldComp? = modifier.WieldComp;
		local characterClass: CharacterClass? = wieldComp and wieldComp.CompOwner or nil;
		local statusComp: StatusComp? = characterClass and characterClass.StatusComp or nil;
		if characterClass == nil or wieldComp == nil or statusComp == nil then return end;
		
		local equippedItemId = wieldComp.ItemId;
		if equippedItemId == nil then return end;

		local isPacifist = (equippedItemId 
							and (modItemsLibrary:HasTag(equippedItemId, "Heal") 
							or modItemsLibrary:HasTag(equippedItemId, "Food")))
		if not isPacifist then return; end;

		local statusClass: StatusClassInstance = statusComp:GetOrDefault("PacifistsAmulet");
		if statusClass then return end; 

		statusClass = statusComp:Apply("PacifistsAmulet", {
			Values = {
				Siid = modifier.ItemModStorageItem and modifier.ItemModStorageItem.ID or nil;
			};
		});
	end
end

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