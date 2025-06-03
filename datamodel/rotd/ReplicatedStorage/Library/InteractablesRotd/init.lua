local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

function modInteractables.onRequire()
    for _, obj in pairs(script:GetChildren()) do
        modInteractables.loadInteractablePackages(obj);
    end
    script.ChildAdded:Connect(modInteractables.loadInteractablePackages);
end

return modInteractables;
