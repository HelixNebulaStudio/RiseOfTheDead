local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local modifierPackage = {
	Name = "MeleeDampening";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.onRequire()
	if RunService:IsClient() then return end;

	function modifierPackage.Binds.CharacterClassTakenDamage(modifier: ItemModifierInstance, damageData: DamageData)
		local characterClass: CharacterClass? = modifier.WieldComp and modifier.WieldComp.CompOwner or nil;
		if characterClass == nil then return end;

		local wieldComp: WieldComp? = characterClass.WieldComp;
		if wieldComp == nil or wieldComp.ItemId == nil then return end;

		if not modItemsLibrary:HasTag(wieldComp.ItemId, "Melee") then return end;

		local configurations = characterClass.Configurations;
		local cBlockChance = configurations and configurations.BlockChance or nil;
		local cDamageBlock = configurations and configurations.DamageBlock or nil;
		if cBlockChance == nil or cDamageBlock == nil then return end;

		if damageData.DamageCate ~= damageData.DamageCategory.Melee then return end;
		if math.random(1, 100) > cBlockChance*100 then return end;

		damageData.Damage = math.max(1, damageData.Damage - cDamageBlock);
		if damageData.Damage <= 0 then damageData.Damage = 1 end;
		
		modAudio.Play("TireArmorBlock", characterClass.RootPart);
	end
end

return modifierPackage;