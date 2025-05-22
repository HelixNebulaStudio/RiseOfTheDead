local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="morbir";
    Icon="rbxassetid://4488388895";
    Name="Skill: Morning Bird";
    Description="+$Amount Health regen per second for $Duration seconds.";
    DescProcess={["Amount"]=function(v) return v*10; end};
    Buff=true;
    Cleansable=true;
};

return modStatusClass.new(statusPackage);