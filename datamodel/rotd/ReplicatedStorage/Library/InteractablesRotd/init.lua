local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

function modInteractables.onRequire()
    for _, obj in pairs(script:GetChildren()) do
        modInteractables.loadInteractableModule(obj);
    end
    script.ChildAdded:Connect(modInteractables.loadInteractableModule);
end

return modInteractables;
