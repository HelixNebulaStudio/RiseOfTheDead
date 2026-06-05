local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id = "XpConfidence";
    Icon = "rbxassetid://2938848546";
    Name = "Exp Confidence";
    Description = "Gaining bonus experience for completing a mission.";
    Buff = true;
    PresistUntilExpire = {};
};

return modStatusClass.new(statusPackage);