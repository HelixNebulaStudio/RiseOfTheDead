local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="FoodHeal";
    Icon="rbxassetid://4466529123";
    Name="Healing From Food";
    Description="+$Amount Health regen per second.";
    DescProcess={
        ["Amount"]=function(v) 
            return v*10; 
        end
    };
    Buff=true;
    Cleansable=true;
};

return modStatusClass.new(statusPackage);