local Food = {};
Food.__index = Food;

function Food.new(equipmentClass)
    local self = {};

    setmetatable(self, Food);
    return self;
end

function Food:Init(equipmentClass)

end

return Food;