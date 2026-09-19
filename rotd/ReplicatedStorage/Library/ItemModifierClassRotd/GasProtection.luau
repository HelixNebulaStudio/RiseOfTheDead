local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modifierPackage = {
	Name = "GasProtection";
	
	Tags = {};
	Binds = {};
};
--==

if RunService:IsServer() then
	function modifierPackage.Binds.CharacterClassTakenDamage(modifier: ItemModifierInstance, damageData: DamageData)
		if damageData.DamageType == "Heal" or damageData.Damage <= 0  then return end;

		local dmgCategory = damageData.DamageCate;
		if dmgCategory == nil then return end;

		if dmgCategory ~= "FumesGas"
		and dmgCategory ~= "TickCombustion"
		and dmgCategory ~= "GasLeak" then return end;

		local damage = damageData.Damage;


		local wieldComp: WieldComp? = modifier.WieldComp;
		if wieldComp == nil then return end;

		local characterClass: CharacterClass = wieldComp.CompOwner :: CharacterClass;
		if characterClass == nil then return end;

		local conGasProtection = characterClass.Configurations.GasProtection;
		if conGasProtection == nil then return end;

		damage = damage * (1-conGasProtection);

		damageData.Damage = damage;
	end
end

return modifierPackage;