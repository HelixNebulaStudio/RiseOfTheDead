local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local statusPackage = {
    Id = "GasLeak";
    Icon = "rbxassetid://12517601747";
    Name = "Toxic Gas Leak";
    Description = "Toxic Gas Leak";
    Buff = false;
    ExpiresOnDeath = true;
};

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms1000 ~= true then return end;

    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
   
    characterClass.HealthComp:TakeDamage(DamageData.new{
        Damage = 5;
        DamageType = "IgnoreArmor";
        DamageCate = "GasLeak";
    });
end

return modStatusClass.new(statusPackage);