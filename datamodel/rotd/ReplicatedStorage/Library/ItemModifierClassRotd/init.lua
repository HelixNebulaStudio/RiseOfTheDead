local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== 
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);
--== 

function modItemModifierClass.onRequire()
    for _, ms in pairs(script:GetChildren()) do
        if not ms:IsA("ModuleScript") then continue end;
        ms.Parent = modItemModifierClass.Script;
    end
end

return modItemModifierClass;