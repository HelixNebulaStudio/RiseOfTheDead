local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="MeleeFury";
    Icon="rbxassetid://6557976555";
    Name="Melee Fury";
    Description="Buff increases attack speed by $Amount stacks. (Max Stacks: 0.5 seconds)";
    QuantityLabel="Amount";
    Buff=true;
    Cleansable=true;
};

return modStatusClass.new(statusPackage);