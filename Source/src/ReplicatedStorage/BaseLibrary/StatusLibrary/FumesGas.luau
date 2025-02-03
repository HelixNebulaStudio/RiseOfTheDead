local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="FumesGas";
    Icon="rbxassetid://17203237389";
    Name="Fumes Gas";
    Description="Taking health damage from Fumes bypassing your gas protection.";
    Buff=false;
};

return modStatusClass.new(statusPackage);