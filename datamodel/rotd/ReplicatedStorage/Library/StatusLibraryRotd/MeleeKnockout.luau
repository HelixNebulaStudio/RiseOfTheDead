local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==

local statusPackage = {
    Id = "MeleeKnockout";
    Icon = "";
    Name = "Melee Knockout";
    Description = "";
    Buff = false;
    ExpiresOnDeath = true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    statusClass.Values.Ragdoll = true;
end

return modStatusClass.new(statusPackage);