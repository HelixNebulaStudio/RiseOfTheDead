local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== 

local ItemModifierClass = {};
ItemModifierClass.__index = ItemModifierClass;
--== 

function ItemModifierClass:Init(super)
    for _, ms in pairs(script:GetChildren()) do
        if not ms:IsA("ModuleScript") then continue end;
        ms.Parent = super.Script;
    end
end

return ItemModifierClass;