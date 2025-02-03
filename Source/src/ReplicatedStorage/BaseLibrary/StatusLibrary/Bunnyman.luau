local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="Bunnyman";
    Icon="rbxassetid://4845612402";
    Name="Bunny Man's Head";
    Description="You are ignored by normal zombies.";
    Buff=true;
};

return modStatusClass.new(statusPackage);