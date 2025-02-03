local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="reqback";
    Icon="rbxassetid://4561090238";
    Name="Skill: Requesting Backup Cooldown";
    Description="Skill on cooldown, when you drop below 35% health, you will heal up to $Percent% health of a squadmate with the highest health.";
    Buff=true;
};

return modStatusClass.new(statusPackage);