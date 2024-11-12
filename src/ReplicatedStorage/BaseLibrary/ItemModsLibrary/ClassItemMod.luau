
local modModsLibrary = require(game.ReplicatedStorage.BaseLibrary.ItemModsLibrary);

local ClassItemMod = {};
ClassItemMod.__index = ClassItemMod;
ClassItemMod.Library = modModsLibrary;

function ClassItemMod.new()
    local self = {ActivateMod=nil;};
    
    setmetatable(self, ClassItemMod);
    return self;
end

return ClassItemMod;