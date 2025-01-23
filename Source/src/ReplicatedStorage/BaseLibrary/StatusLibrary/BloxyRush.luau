local RunService = game:GetService("RunService");

local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id="BloxyRush";
    Icon="rbxassetid://5094119246";
    Name="Bloxy Rush";
    Description="Speed and Melee Stamina bonus for a temporary duration.";
    Buff=true;
    Cleansable=true;
};

function statusPackage:OnApply()
    if RunService:IsServer() then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();
    
    modCharacter.CharacterProperties.SprintSpeed = 26.4;
end

function statusPackage:OnExpire()
    if RunService:IsServer() then return end;
    
    local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    modCharacter.CharacterProperties.SprintSpeed = 22;
    modCharacter.UpdateWalkSpeed();
end

return modStatusClass.new(statusPackage);