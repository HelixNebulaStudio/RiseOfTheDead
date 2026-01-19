local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Toughening Up";

	Tags = {};
	Binds = {};
};

--==
function modifierPackage.onRequire()
	if RunService:IsClient() then return end;

	function modifierPackage.Binds.CharacterClassDoneDamage(modifier: ItemModifierInstance, npcClass: NpcClass, cloneDmgData: DamageData)
		if modifier.WieldComp == nil then return end;

		local characterClass: CharacterClass = modifier.WieldComp.CompOwner;
		if characterClass == nil then return end;

        local healthComp: HealthComp? = characterClass.HealthComp;
        if healthComp == nil then return end;
        if healthComp.CurArmor <= 0 or healthComp.MaxArmor <= 0 then return end;

        local targetHealthComp = npcClass.HealthComp;
        if targetHealthComp == nil then return end;

        local damage = cloneDmgData.Damage;
        if damage == nil then return end;

        local targetMaxHealth = targetHealthComp.MaxHealth;
        if targetMaxHealth == nil then return end;
        
        local percentageDamage = math.clamp(damage/targetMaxHealth, 0, 1);
        
        local skillData = modifier.Values.SkillData;
        if skillData == nil then return end;

        local amt = skillData.Stats.Amount;
        local armorGain = percentageDamage * amt.Value*100;
        
        healthComp:SetArmor(healthComp.CurArmor + armorGain);
	end
end

return modifierPackage;