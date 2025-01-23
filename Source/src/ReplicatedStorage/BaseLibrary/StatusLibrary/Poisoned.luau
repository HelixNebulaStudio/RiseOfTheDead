local RunService = game:GetService("RunService");

local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

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
};

function statusPackage:OnApply()
    if RunService:IsServer() then return end;

    local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    modCharacter.MouseProperties.MovementNoise = true;

    modCharacter.CameraShakeAndZoom(5, 0, 0.5, 0, true);
end

function statusPackage:OnExpire()
    if RunService:IsServer() then return end;

    local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    modCharacter.MouseProperties.MovementNoise = false;
end

function statusPackage:OnTick(tickPack)
    if RunService:IsClient() then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end

    if tickPack.ms500 == false then return end;

    local damagable = modDamagable.NewDamagable(playerClass.Character);
    if damagable then
        damagable:TakeDamagePackage(modDamagable.NewDamageSource{
            Damage=2;
        });
    end
end

return modStatusClass.new(statusPackage);