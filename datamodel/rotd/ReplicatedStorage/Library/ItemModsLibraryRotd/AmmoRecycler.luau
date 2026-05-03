local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modHealthComp = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local modifierPackage = {
	Name = "Ammo Recycler";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	if modifier.EquipmentClass == nil then return end;
	modItemModifierClass.AddTierDamage(modifier);
	
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "C");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	if tweakVal then
		value = value + tweakVal;
	end

	modifier.Properties.AmmoRecycler = value;
end

function modifierPackage.Binds.WeaponShotDamageDataNew(modifier: ItemModifierInstance, damageData: DamageData)
	if RunService:IsClient() then return end;
	if damageData.TargetModel == nil then return end;
	
	local characterClass: CharacterClass;
	if modifier.WieldComp == nil then return end;
	if modifier.WieldComp and modifier.WieldComp.CompOwner then
		characterClass = modifier.WieldComp.CompOwner :: CharacterClass;
	end
	
	local healthComp: HealthComp? = modHealthComp.getByModel(damageData.TargetModel);
	if healthComp == nil or healthComp.IsDead or not healthComp:CanTakeDamageFrom(characterClass) then return end;
	if healthComp.CompOwner.ClassName ~= "NpcClass" then return end;
	if damageData.Damage < (healthComp.MaxHealth + healthComp.MaxArmor) then return end;

	local roll = math.random(0, 1000)/1000;
	if not RunService:IsStudio() and roll > modifier.Properties.AmmoRecycler then return end;

	local equipmentClass: EquipmentClass? = modifier.EquipmentClass;
	if equipmentClass == nil then return end;

	local storageItem: StorageItem? = equipmentClass.StorageItem;
	if storageItem == nil then return end;

	if modifier.Properties.CooldownTick and workspace:GetServerTimeNow() <= modifier.Properties.CooldownTick then
		return;
	end
	modifier.Properties.CooldownTick = workspace:GetServerTimeNow()+1;

	local toolHandler: ToolHandlerInstance? = characterClass.WieldComp:GetToolHandler(
		storageItem.ID, 
		storageItem.ItemId, 
		storageItem
	);
	if toolHandler == nil then return end;
	if damageData.Projectile then
		damageData.Projectile.Properties.AmmoRecovered = true;
	end

	local primaryPart = toolHandler.MainToolModel and toolHandler.MainToolModel.PrimaryPart;
	if primaryPart then
		local sound: Sound = modAudio.Play("AmmoFeed", primaryPart);
		sound.Volume = 10;
		sound.PlaybackSpeed = 1.5;
	end

	local curAmmo = storageItem:GetValues("A");
	
	local maxAmmoLimit = toolHandler.EquipmentClass.Configurations.MaxAmmoLimit;

	local newMaxAmmo = (storageItem:GetValues("MA") or maxAmmoLimit) +1;
	if newMaxAmmo > maxAmmoLimit then
		newMaxAmmo = maxAmmoLimit;
	end

	equipmentClass.Properties.MaxAmmo = newMaxAmmo;
	storageItem:SetValues("MA", newMaxAmmo);

	modifier.WieldComp:SyncEquipmentProperties(storageItem.ID, {"MaxAmmo"});
end

return modifierPackage;