local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="ItemHealth";
    Icon="rbxasset://textures/ui/GuiImagePlaceholder.png";
    Name="Item Health Hud";
    Description="$Desc";
    Buff=false;
};


return modStatusClass.new(statusPackage);