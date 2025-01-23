local RunService = game:GetService("RunService");
local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id="SetWalkspeed";
    Description="Set Walkspeed = $Amount.";
    ShowOnHud=false;
};

function statusPackage:OnApply()
    if RunService:IsServer() then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    local walkSpeed = self.Amount;

    playerClass.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, walkSpeed > 0);
    modCharacter.CharacterProperties.CanSprint = false;
    
    modCharacter.CharacterProperties.WalkSpeed:Set("forceWalkspeed", walkSpeed, 10);
    modCharacter.UpdateWalkSpeed();
end

function statusPackage:OnExpire()
    if RunService:IsServer() then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    playerClass.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true);
    modCharacter.CharacterProperties.CanSprint = true;

    modCharacter.CharacterProperties.WalkSpeed:Remove("forceWalkspeed");
    modCharacter.UpdateWalkSpeed();
end

return modStatusClass.new(statusPackage);