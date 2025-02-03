local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="Chained";
    Icon="rbxassetid://16716699240";
    Name="Chained";
    Description="You are chained to something. Maybe destroy it to break free?";
    Buff=false;
};

return modStatusClass.new(statusPackage);