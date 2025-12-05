local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id="Poisoned";
    Icon="rbxassetid://6361544022";
    Name="Poisoned";
    Description="Poisoned for $Amount seconds.";
    Buff=false;
    Tags = {"DOT";};
    Cleansable=true;
    ExpiresOnDeath=true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    modCharacter.MouseProperties.MovementNoise = true;

    modCharacter.CameraShakeAndZoom(5, 0, 0.5, 0, true);
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    modCharacter.MouseProperties.MovementNoise = false;
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms500 == false then return end;

    local healthComp: HealthComp? = statusClass.StatusOwner.HealthComp;
    if healthComp == nil then return end;
    
    local dmgData = DamageData.new{
        Damage=2;
        DamageBy = statusClass.ApplyBy;
    };
    healthComp:TakeDamage(dmgData);
end

return modStatusClass.new(statusPackage);