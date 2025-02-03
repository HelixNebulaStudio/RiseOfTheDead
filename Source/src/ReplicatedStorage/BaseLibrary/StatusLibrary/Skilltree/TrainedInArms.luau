local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="trinar";
    Icon="rbxassetid://4483748413";
    Name="Skill: Trained In Arms";
    Description="Weapon accuracy increased by $Percent%.";
    Buff=true;
};

return modStatusClass.new(statusPackage);