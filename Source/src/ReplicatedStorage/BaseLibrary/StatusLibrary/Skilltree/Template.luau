local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="Template";
    Icon="rbxassetid://10368377851";
    Name="Template";
    Description="";
    Buff=true;
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