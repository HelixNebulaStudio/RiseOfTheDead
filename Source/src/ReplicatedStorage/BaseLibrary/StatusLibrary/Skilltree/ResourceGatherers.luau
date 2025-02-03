local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="resgat";
    Icon="rbxassetid://16380816785";
    Name="Resource Gatherers Cooldown";
    Description="A squadmate helped you pick up some items.";
    Buff=true;
};

return modStatusClass.new(statusPackage);