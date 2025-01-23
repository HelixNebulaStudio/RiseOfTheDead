local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="XpBoost";
    Icon="rbxassetid://5627435285";
    Name="Exp Boost";
    Description="Experience gain is doubled.";
    Buff=true;
};

return modStatusClass.new(statusPackage);