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

return Melee;