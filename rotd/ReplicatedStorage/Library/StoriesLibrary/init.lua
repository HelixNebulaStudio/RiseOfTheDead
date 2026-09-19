local modLibraryManager = shared.require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();

function library.onRequire()
    for _, msInst in pairs(script:GetChildren()) do
        if not msInst:IsA("ModuleScript") then continue end;
        
        library:AddLazy(msInst.Name, msInst);
    end
end

return library;