local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="ForceField";
    Icon="rbxassetid://6121328871";
    Name="ForceField";
    Description="Temporarily negate any damage.";
    Buff=true;
    ExpiresOnDeath = true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    local rootPart = playerClass.RootPart;
    if rootPart then
        if playerClass.Character:FindFirstChild("ForcefieldStatus") then
            game.Debris:AddItem(playerClass.Character.ForcefieldStatus, 0);
        end
        local new = Instance.new("ForceField");
        new.Name = "ForcefieldStatus";
        new.Parent = playerClass.Character;
    end
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    if playerClass.Character:FindFirstChild("ForcefieldStatus") then
        game.Debris:AddItem(playerClass.Character.ForcefieldStatus, 0);
    end
end

return modStatusClass.new(statusPackage);