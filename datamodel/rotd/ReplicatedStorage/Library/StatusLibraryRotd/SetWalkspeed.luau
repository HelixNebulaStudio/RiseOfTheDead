local RunService = game:GetService("RunService");
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id="SetWalkspeed";
    Description="Set Walkspeed = $Amount.";
    ShowOnHud=false;
};

function statusPackage.OnApply(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;
    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass == nil then return end;

    local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    local walkSpeed = statusClass.Values.Amount;

    characterClass.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, walkSpeed > 0);
    modCharacter.CharacterProperties.CanSprint = false;

    modCharacter.CharacterProperties.WalkSpeed:Set("forceWalkspeed", walkSpeed, 10);
    modCharacter.UpdateWalkSpeed();
end

function statusPackage.OnExpire(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;
    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass == nil then return end;

    local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    characterClass.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true);
    modCharacter.CharacterProperties.CanSprint = true;

    modCharacter.CharacterProperties.WalkSpeed:Remove("forceWalkspeed");
    modCharacter.UpdateWalkSpeed();
end

return modStatusClass.new(statusPackage);