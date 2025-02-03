local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="Toxic";
    Icon="rbxassetid://12517601747";
    Name="Toxic";
    Description="You are taking toxic damage.";
    Buff=false;
    Tags = {"DOT";};
    Cleansable=true;
};

return modStatusClass.new(statusPackage);