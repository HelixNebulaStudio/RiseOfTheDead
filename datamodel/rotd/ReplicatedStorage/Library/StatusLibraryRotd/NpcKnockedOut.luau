local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local statusPackage = {
    Id = "NpcKnockedOut";
    Icon = shared.Const.PlaceholderIcon;
    Name = "NpcKnockedOut";
    Description = "";
    Buff = false;
};

return modStatusClass.new(statusPackage);