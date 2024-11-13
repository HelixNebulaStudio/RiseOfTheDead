
local modModsLibrary = require(script.Parent);

local ItemModProperties = {};
ItemModProperties.__index = ItemModProperties;
ItemModProperties.Library = modModsLibrary;

function ItemModProperties.new()
    local self = {ActivateMod=nil;};
    
    setmetatable(self, ItemModProperties);
    return self;
end

return ItemModProperties;