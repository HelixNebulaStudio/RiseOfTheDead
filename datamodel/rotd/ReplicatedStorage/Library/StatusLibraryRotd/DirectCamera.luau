local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id = "DirectCamera";
    Description = "Set DirectCameraPosition = $Position.";
    ShowOnHud = false;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    if characterClass == nil then return end;

    local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    local duration = statusClass.Duration;

    modCharacter.CharacterProperties.DirectCameraPosition = statusClass.Values.Position;
    modCharacter.CharacterProperties.DirectCameraTick = tick() + duration;
end

function statusPackage.BindUpdate(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;
    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    if characterClass == nil then return end;

    local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();
    
    local duration = statusClass.Duration;

    modCharacter.CharacterProperties.DirectCameraPosition = statusClass.Values.Position;
    modCharacter.CharacterProperties.DirectCameraTick = tick() + duration;
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;
    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    if characterClass == nil then return end;

    local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    modCharacter.CharacterProperties.DirectCameraPosition = nil;
    modCharacter.CharacterProperties.DirectCameraTick = nil;
end

return modStatusClass.new(statusPackage);