local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="LabCoat";
    Icon="rbxassetid://4978200934";
    Name="LabCoat";
    Description="Your Lab Coat adds 30% extra gas protection to gas damages.";
    Buff=true;
};

return modStatusClass.new(statusPackage);