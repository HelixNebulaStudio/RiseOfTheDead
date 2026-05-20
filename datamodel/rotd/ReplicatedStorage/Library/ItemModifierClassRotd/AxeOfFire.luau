local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local STATUS_DURATION = 4;

local modifierPackage = {
	Name = "Axe of Fire";
	
	Tags = {};
	Binds = {};
};
--==

if RunService:IsServer() then
    function modifierPackage.Binds.MeleeDamageDataNew(modifier: ItemModifierInstance, damageData: DamageData)
        local damageTo: EntityClass? = damageData.DamageTo;
        if damageTo == nil then return end;

        if damageData.ToolHandler == nil or modifier.EquipmentClass ~= damageData.ToolHandler.EquipmentClass then
            return;
        end

		if modifier.WieldComp == nil or modifier.WieldComp.CompOwner == nil then return end;
		local characterClass: CharacterClass = modifier.WieldComp.CompOwner :: CharacterClass;

		local targetHealthComp: HealthComp? = damageTo.HealthComp;
		if targetHealthComp == nil then return end;
		if not targetHealthComp:CanTakeDamageFrom(characterClass) then return end;

		local targetClass: EntityClass = targetHealthComp.CompOwner;
		local statusComp: StatusComp? = targetClass.StatusComp;
		if statusComp == nil then return end;

        local equipmentClass = modifier.EquipmentClass;
        if equipmentClass == nil then return end;
		local configurations = equipmentClass.Configurations;

		local statusClass: StatusClassInstance = statusComp:GetOrDefault("LiquidFlame");
        if statusClass == nil then
            statusComp:Apply("LiquidFlame", {
                Expires = workspace:GetServerTimeNow() + STATUS_DURATION;
                Duration = STATUS_DURATION;
                ApplyBy = characterClass;
                Values = {
                    TargetPart = damageData.TargetPart;
                    Damage = configurations.PreModDamage;
                    Stacks = 1;
                };
            });

        else
            statusClass.Values.Stacks *= 2;
            
        end
	end
end

return modifierPackage;