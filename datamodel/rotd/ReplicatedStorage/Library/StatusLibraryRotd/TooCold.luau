local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="TooCold";
    Icon="rbxassetid://3564119613";
    Name="Too Cold";
    Description="It's too cold. (Below 10°C) Put on more clothes! If you take damage, you might freeze.";
    Buff=false;
};

return modStatusClass.new(statusPackage);