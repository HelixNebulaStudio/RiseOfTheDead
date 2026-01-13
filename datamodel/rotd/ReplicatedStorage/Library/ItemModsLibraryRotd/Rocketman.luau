local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Rocketman";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	modItemModifierClass.AddTierDamage(modifier);
	
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "FR");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	if tweakVal then
		value = value + math.ceil(tweakVal);
	end

	modifier.SumValues.Rpm = value;
	modifier.SetValues.Rocketman = true;
end

function modifierPackage.Binds.PreProcessShot(modifier: ItemModifierInstance, packet)
	if modifier.EquipmentClass == nil then return end;

	local equipmentClass = modifier.EquipmentClass;

	local configurations = equipmentClass.Configurations;
	if configurations.Rocketman ~= true then return end;

	local shotPacket = packet.ShotPacket;
	if shotPacket.Rocketman ~= true then return end;

	local storageItem = equipmentClass.StorageItem;
	local maxAmmo = storageItem:GetValues("MA") or configurations.AmmoCapacity;
	if maxAmmo <= 0 then return end;

	local overrideTable = packet.OverrideTable;

	local ammo = storageItem:GetValues("A") or configurations.MagazineSize;
	local ammoCost = math.min(configurations.AmmoCost or 1, ammo);
	
	local shotBy = shotPacket.ShotBy;
	if shotBy == nil or shotBy.IsSwimming == true then return end;

	overrideTable.AmmoCost = 0;
	overrideTable.MaxAmmoCost = 1;
end

return modifierPackage;