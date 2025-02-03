local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="remres";
    Icon="rbxassetid://4651191717";
    Name="Skill: Remarkable Resilience Cooldown";
    Description="Skill on cooldown, regenerated to $Percent% of max health.";
    Buff=true;
};

return modStatusClass.new(statusPackage);