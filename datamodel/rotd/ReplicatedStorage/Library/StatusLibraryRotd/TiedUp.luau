local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="TiedUp";
    Icon="rbxassetid://4983245856";
    Name="Tied Up";
    Description="You are tied up and cannot move or do anything while being tied up.";
    Buff=false;
    Tags = {"Mobility"; "Stun";};
    Cleansable=true;
    ExpiresOnDeath=true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
end

return modStatusClass.new(statusPackage);