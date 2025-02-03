local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="ovehea";
    Icon="rbxassetid://4752500248";
    Name="Skill: Over Heal";
    Description="Heal over max health by $Amount health with medkits.";
    Buff=true;
    Cleansable=true;
};

return modStatusClass.new(statusPackage);