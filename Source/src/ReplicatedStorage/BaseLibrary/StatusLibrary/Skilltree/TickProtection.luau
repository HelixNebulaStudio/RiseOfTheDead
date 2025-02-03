local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="tickre";
    Icon="rbxassetid://4978159755";
    Name="Tick Protection";
    Description="You recently got damaged by a tick, thus will not take damage from another one until this expires.";
    Buff=true;
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