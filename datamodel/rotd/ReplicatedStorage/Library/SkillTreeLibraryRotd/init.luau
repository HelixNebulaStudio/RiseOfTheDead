local modSkillTreeLibrary = shared.require(game.ReplicatedStorage.Library.SkillTreeLibrary);

function modSkillTreeLibrary.onRequire()
    for _, ms in pairs(script:GetChildren()) do
        if not ms:IsA("ModuleScript") then continue end;
        if ms.Name == "Template" then continue end;
        
        local treeLibrary = shared.require(ms);
        treeLibrary:Sort(function(A, B) return A.Level < B.Level end);
        modSkillTreeLibrary[ms.Name] = treeLibrary;
    end

    if game:GetService("RunService"):IsServer() then
        shared.require(game.ServerScriptService.ServerLibrary.SkillTree):Init();
    end
end

return modSkillTreeLibrary;