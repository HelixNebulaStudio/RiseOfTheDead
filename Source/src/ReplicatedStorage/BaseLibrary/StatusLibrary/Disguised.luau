local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="Disguised";
    Icon="rbxassetid://5783987908";
    Name="Disguised";
    Description="You are disguised as $Name.";
    Buff=true;
};

return modStatusClass.new(statusPackage);