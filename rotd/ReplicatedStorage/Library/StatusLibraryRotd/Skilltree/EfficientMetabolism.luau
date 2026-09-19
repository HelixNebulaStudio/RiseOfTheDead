local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id = "effmet";
    Icon = "rbxassetid://4561093556";
    Name = "Skill: Efficient Metabolism";
    Description = "Increases the duration of food by $Percent%.";
    Buff = true;
};

return modStatusClass.new(statusPackage);