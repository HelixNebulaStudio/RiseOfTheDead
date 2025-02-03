local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="fiaitr";
    Icon="rbxassetid://4493354290";
    Name="Skill: First Aid Training";
    Description="Medkits use speed increased by $Percent%.";
    Buff=true;
};

return modStatusClass.new(statusPackage);