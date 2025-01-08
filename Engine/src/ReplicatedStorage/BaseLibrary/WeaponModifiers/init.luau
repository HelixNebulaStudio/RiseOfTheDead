local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local WeaponModifiers = {};
WeaponModifiers.__index = WeaponModifiers;
--== Script;
function WeaponModifiers:Init(src)
    for _, ms in pairs(script:GetChildren()) do
        if not ms:IsA("ModuleScript") then continue end;
        ms.Parent = src;
    end
end

return WeaponModifiers;