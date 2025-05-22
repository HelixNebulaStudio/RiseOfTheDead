local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="nigowl";
    Icon="rbxassetid://4492141104";
    Name="Skill: Night Owl";
    Description="-$Percent% enemy detection for $Duration seconds.";
    Buff=true;
};

return modStatusClass.new(statusPackage);