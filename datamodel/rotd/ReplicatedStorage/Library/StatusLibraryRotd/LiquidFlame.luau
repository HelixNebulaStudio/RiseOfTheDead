local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local statusPackage = {
    Id="LiquidFlame";
    Icon="";
    Name="Liquid Flame";
    Description="Burning from liquid flame.";
    Buff = true;
    ExpiresOnDeath = true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    local fireParticle = game.ReplicatedStorage.Particles.Fire2;

    if statusClass.Values.TargetPart then 
        local new = fireParticle:Clone();
        new.Name = "FlameModFire";
        new.Parent = statusClass.Values.TargetPart;
        statusClass.Garbage:Tag(new);
        statusClass.Values.TargetPart = nil;
    end
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if not tickData.ms500 then return end;

    local healthComp: HealthComp? = statusClass.StatusOwner.HealthComp;
    if healthComp == nil then return end;

    local damage = statusClass.Values.Damage or 1;
    damage = damage + (damage*math.clamp(statusClass.Values.Stacks or 0, 0, 100));
    
    local dmgData = DamageData.new{
        Damage = damage;
        DamageType = "Fire";
    };
    healthComp:TakeDamage(dmgData);
end

return modStatusClass.new(statusPackage);