local Melee = shared.require(game.ReplicatedStorage.Library.EquipmentClass.Melee);
local ConfigOperators = Melee.ConfigOperator;
--==

ConfigOperators["DamageBlock"] = function(configModifier: ConfigModifier, value)
    configModifier.SumValues.DamageBlock = value;
end;

function Melee.new(equipmentClass)
    local self = {};

    setmetatable(self, Melee);
    return self;
end

function Melee:Init(equipmentClass)
end

function Melee.Update(meleeClass, equipmentClass: EquipmentClass)
    local storageItem: StorageItem = equipmentClass.StorageItem;
    meleeClass:UpdatePotential(equipmentClass);
end


function Melee.UpdatePotential(meleeClass, equipmentClass: EquipmentClass, weaponLevel: number)
    local configurations = equipmentClass.Configurations;
    local properties = equipmentClass.Properties;

    local baseDamage = configurations:GetBase("Damage");

    local potentialModifier: ItemModifierInstance = configurations:GetModifier("Potential");
    if potentialModifier == nil then
        potentialModifier = configurations.newModifier("Potential", 0);
        configurations:AddModifier(potentialModifier, false);
    end

    potentialModifier.EquipmentClass = equipmentClass;
    potentialModifier.SetValues.PreModDamage = baseDamage;
    potentialModifier.SetValues.Damage = baseDamage;
    potentialModifier.Tags.Base = true;
    potentialModifier.Enabled = true;

    configurations:Calculate();
end

return Melee;