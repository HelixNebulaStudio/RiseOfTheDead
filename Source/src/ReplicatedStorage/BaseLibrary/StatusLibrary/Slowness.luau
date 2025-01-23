local RunService = game:GetService("RunService");

local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id="Slowness";
    Icon="rbxassetid://4467439574";
    Name="Slowness";
    Description="Slowed by $Amount walk speed.";
    Buff=false;
    Tags = {"Mobility"; "Slow";};
    Cleansable=true;
};

function statusPackage:OnApply()
    if RunService:IsServer() then return end;

    local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    local amount = self.Amount or 10;
    local newWalkSpeed = modCharacter.CharacterProperties.DefaultWalkSpeed-amount;

    modCharacter.CharacterProperties.WalkSpeed:Set("slowness", newWalkSpeed, 5);
    modCharacter.CharacterProperties.CanSprint = false;
end

function statusPackage:OnExpire()
    if RunService:IsServer() then return end;

    local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    modCharacter.CharacterProperties.WalkSpeed:Remove("slowness");
    modCharacter.CharacterProperties.CanSprint = true;
end

return modStatusClass.new(statusPackage);