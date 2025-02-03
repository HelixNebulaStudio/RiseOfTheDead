local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="ArmorBreak";
    Icon="rbxassetid://6561711943";
    Name="Armor Break";
    Description="Your armor broke after you took $Damage damage. Armor regeneration is delay by $Duration seconds.";
    Buff=false;
    Tags = {"Weaken";};
    Cleansable=true;
};

function statusPackage.init()
end

function statusPackage:OnApply()
end

function statusPackage:OnExpire()
end

function statusPackage:OnTick()
end

function statusPackage:OnRelay()
end

return modStatusClass.new(statusPackage);