local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modSkillTreeLibrary = shared.require(game.ReplicatedStorage.Library.SkillTreeLibrary);

function modSkillTreeLibrary.onRequire()
    for _, ms in pairs(script:GetChildren()) do
        if not ms:IsA("ModuleScript") then continue end;
        if ms.Name == "Template" then continue end;
        
        local treeLibrary = shared.require(ms);
        treeLibrary:Sort(function(A, B) return A.Level < B.Level end);

        for _, skillLib in pairs(treeLibrary:GetIndexList()) do
            table.insert(modSkillTreeLibrary.SkillsIndexList, skillLib);
        end

        modSkillTreeLibrary[ms.Name] = treeLibrary;
    end
    
    table.sort(modSkillTreeLibrary.SkillsIndexList, function(a, b)
        return a.Level < b.Level;
    end)

    if game:GetService("RunService"):IsServer() then
        shared.require(game.ServerScriptService.ServerLibrary.SkillTree):Init();
    end
end

return modSkillTreeLibrary;