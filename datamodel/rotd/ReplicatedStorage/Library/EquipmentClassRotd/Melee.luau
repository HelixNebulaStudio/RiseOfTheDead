local Melee = {};
Melee.__index = Melee;

function Melee.new(equipmentClass)
    local self = {};

    setmetatable(self, Melee);
    return self;
end

function Melee:Init(equipmentClass)
end

return Melee;