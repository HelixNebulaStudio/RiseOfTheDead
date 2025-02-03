local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="Freezing";
    Icon="rbxassetid://10371553364";
    Name="Freezing";
    Description="You are freezing, you will lose mobility and won't be able to perform actions.";
    Buff=false;
    Tags = {"Mobility"; "Slow";};
    Cleansable=true;
};

return modStatusClass.new(statusPackage);