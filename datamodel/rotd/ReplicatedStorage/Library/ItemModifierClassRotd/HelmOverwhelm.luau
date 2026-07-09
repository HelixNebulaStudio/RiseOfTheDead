local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local modifierPackage = {
	Name = "HelmOverwhelm";
	
	Tags = {};
	Binds = {};
	Priority = 5;
};
--==

function modifierPackage.onRequire()
	if RunService:IsClient() then return end;

	function modifierPackage.Binds.CharacterClassTakenDamage(modifier: ItemModifierInstance, damageData: DamageData)
		local characterClass: CharacterClass? = modifier.WieldComp and modifier.WieldComp.CompOwner :: CharacterClass;
		if characterClass == nil then return end;

		local statusComp: StatusComp? = characterClass.StatusComp;
		local healthComp: HealthComp? = characterClass.HealthComp;
		if healthComp == nil or statusComp == nil then return end;

		local woundedStatus: StatusClassInstance = statusComp:GetOrDefault("Wounded");
		if woundedStatus then return end;

		if damageData.DamageType == "IgnoreArmor" or healthComp.CurArmor <= 0 then return end;
		if damageData.DamageType == "Heal" or damageData.Damage <= 0 then return end;

		local damage = damageData.Damage;

		local heal = math.ceil(damage * 0.1);
		task.defer(function()
			healthComp:TakeDamage(DamageData.new{
				Damage = -heal;
				DamageBy = characterClass;
				StorageItem = modifier.EquipmentClass and modifier.EquipmentClass.StorageItem;
				DamageType = "Heal";
			});
		end)
	end
end

return modifierPackage;