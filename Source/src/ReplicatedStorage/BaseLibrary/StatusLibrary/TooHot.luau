local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="TooHot";
    Icon="rbxassetid://3479646912";
    Name="Too Hot";
    Description="It's too hot. (Above 40°C) \"Take off your jacket!\" If you take damage, you might ignite.";
    Buff=false;
};

return modStatusClass.new(statusPackage);