local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

--==
local statusPackage = {
    Id = "MothWhirlwind";
    Icon = "rbxassetid://99249222251358";
    Name = "Moth's Whirlwind";
    Description = "You were caught by the whirlwind lifting you up.";
    Tags = {"Mobility"; "Displace"};
    Buff = false;
    ExpiresOnDeath = true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    local characterClass = statusClass.StatusOwner :: CharacterClass;
    if characterClass == nil then return end;

    local character = characterClass.Character;
    if characterClass.ClassName ~= "PlayerClass" then return end;

    local playerClass = characterClass :: PlayerClass;
    local player = playerClass:GetInstance();

    modStatusEffects.AntiGravity(player, 1000);

    local healthComp = characterClass.HealthComp;
    if healthComp == nil or healthComp.IsDead then return end;    
    healthComp:TakeDamage(DamageData.new{
        Damage = 25;
    });

end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms100 == false then return end;

    local whirlwindModel = statusClass.Values.WhirlWind;
    if not workspace:IsAncestorOf(whirlwindModel) then
        statusClass.IsExpired = true;
        return;
    end

    local characterClass = statusClass.StatusOwner;
    local rootPart = characterClass.RootPart;

    local healthComp = characterClass.HealthComp;
    if healthComp == nil or healthComp.IsDead then return end;    

    local wwCFrame = whirlwindModel:GetPivot();
    local wwDis = (wwCFrame.Position - rootPart.Position);
    local wwDir = wwDis.Unit;
    local wwMag = wwDis.Magnitude;
    wwMag = math.min(wwMag, 12);

    rootPart.AssemblyLinearVelocity = (wwDir * wwMag) * 1.8;
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;

    local characterClass = statusClass.StatusOwner :: CharacterClass;
    if characterClass.ClassName == "PlayerClass" then
        local playerClass = characterClass :: PlayerClass;
        local player = playerClass:GetInstance();

        modStatusEffects.AntiGravity(player, nil);
    end
end

return modStatusClass.new(statusPackage);