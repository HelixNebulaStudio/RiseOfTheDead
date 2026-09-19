local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

function modInteractables.onRequire()


    modInteractables.TypeIcons["BossDoor_"] = {
        Icon = "rbxassetid://6328469902"; 
        Color = Color3.fromRGB(255, 255, 255)
    };
	modInteractables.TypeIcons["RogueDoor_"] = {
        Icon="rbxassetid://6328466558"; 
        Color=Color3.fromRGB(255, 255, 255)
    };
	modInteractables.TypeIcons["ExtremeDoor_"] = {
        Icon="rbxassetid://6328526813"; 
        Color=Color3.fromRGB(152, 45, 45)
    };
	modInteractables.TypeIcons["Travel_"] = {
        Icon="rbxassetid://3694599252"; 
        Color=Color3.fromRGB(255, 255, 255)
    };
	modInteractables.TypeIcons["TravelLock_"] = {
        Icon="rbxassetid://3694599252"; 
        Color=Color3.fromRGB(255, 255, 255)
    };
	modInteractables.TypeIcons["Shop_"] = {
        Icon="rbxassetid://4629984614"; 
        Color=Color3.fromRGB(255, 255, 255)
    };
	modInteractables.TypeIcons["RaidSolo_"] = {
        Icon="rbxassetid://6328469902";  
        Color=Color3.fromRGB(255, 255, 255)
    };
	modInteractables.TypeIcons["Raid_"] = {
        Icon="rbxassetid://6328528439"; 
        Color=Color3.fromRGB(255, 255, 255)
    };
	modInteractables.TypeIcons["RaidBandit_"] = {
        Icon="rbxassetid://6361537388"; 
        Color=Color3.fromRGB(255, 255, 255)
    };
	modInteractables.TypeIcons["Survival_"] = {
        Icon="rbxassetid://6328528439"; 
        Color=Color3.fromRGB(152, 45, 45)
    };
	modInteractables.TypeIcons["Coop_"] = {
        Icon="rbxassetid://13336462553"; 
        Color=Color3.fromRGB(255, 255, 255)
    };

    
    for _, obj in pairs(script:GetChildren()) do
        modInteractables.loadInteractablePackages(obj);
    end
    script.ChildAdded:Connect(modInteractables.loadInteractablePackages);
end

return modInteractables;
