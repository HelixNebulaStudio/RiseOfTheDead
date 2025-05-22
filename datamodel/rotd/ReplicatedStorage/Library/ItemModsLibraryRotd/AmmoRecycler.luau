local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modHealthComp = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local modifierPackage = {
	Name = "Ammo Recycler";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	if modifier.EquipmentClass == nil then return end;

	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "C");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	if tweakVal then
		value = value + tweakVal;
	end

	modifier.Values.AmmoRecycler = value;
end

function modifierPackage.Binds.OnNewDamage(modifier: ItemModifierInstance, damageData: DamageData)
	if RunService:IsClient() then return end;
	if damageData.TargetModel == nil then return end;
	
	local characterClass: CharacterClass;
	if modifier.Player then
		characterClass = shared.modPlayers.get(modifier.Player);
	end
	
	local healthComp: HealthComp? = modHealthComp.getByModel(damageData.TargetModel);
	if healthComp == nil or healthComp.IsDead or not healthComp:CanTakeDamageFrom(characterClass) then return end;
	if damageData.Damage < (healthComp.MaxHealth + healthComp.MaxArmor) then return end;

	local roll = math.random(0, 1000)/1000;
	if roll > modifier.Values.AmmoRecycler then return end;

	local storageItem: StorageItem? = modifier.EquipmentStorageItem;
	if storageItem == nil then return end;

	local toolHandler: ToolHandlerInstance? = characterClass.WieldComp:GetToolHandler(
		storageItem.ID, 
		storageItem.ItemId, 
		storageItem
	);
	if toolHandler == nil then return end;

	local primaryPart = toolHandler.Prefabs[1] and toolHandler.Prefabs[1].PrimaryPart;
	if primaryPart then
		local sound: Sound = modAudio.Play("AmmoFeed", primaryPart);
		sound.Volume = 10;
		sound.PlaybackSpeed = 1.5;
	end

	local curAmmo = storageItem:GetValues("A");
	local newMaxAmmo = (storageItem:GetValues("MA") or toolHandler.EquipmentClass.Configurations.AmmoCapacity) +1;
	
	storageItem:SetValues("MA", newMaxAmmo);
	storageItem:Sync({"MA"});
end

return modifierPackage;