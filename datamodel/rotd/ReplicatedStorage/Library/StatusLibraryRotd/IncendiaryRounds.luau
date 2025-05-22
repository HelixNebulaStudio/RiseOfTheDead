local RunService = game:GetService("RunService");

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="IncendiaryRounds";
    Icon="";
    Name="Incendiary Rounds Hit";
    Description="Hit by incendiary rounds and taking fire damage over time.";
    Buff=true;
};


function statusPackage.OnApply(statusClass: StatusClassInstance)
    local fireParticle = game.ReplicatedStorage.Particles.Fire2;

    local new: ParticleEmitter = fireParticle:Clone();
    new.Name = "FlameModFire";
    new.Parent = statusClass.Values.TargetPart;
    
    statusClass.Garbage:Tag(new);
end


function statusPackage.OnTick(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms500 == false then return end;
   
    local damage = statusClass.Values.Damage;
    local stacks = statusClass.Values.Stacks;
    local targetPart = statusClass.Values.TargetPart;
    local useCurrentHpDmg = statusClass.Values.UseCurrHpDmg;

    local stackedDamage = damage + damage * (stacks or 0);

    local npcClass: NpcClass = statusClass.StatusOwner :: NpcClass;
    local healthComp: HealthComp? = npcClass:GetHealthComp(targetPart);
    if healthComp == nil or healthComp.IsDead then return end;
    
    if useCurrentHpDmg ~= false then
        stackedDamage = stackedDamage + useCurrentHpDmg;
    end
    if stackedDamage <= 0 then return; end
    
    local dmgData: DamageData = DamageData.new{
        DamageBy = statusClass.Values.ApplyBy;

        Damage = stackedDamage;
        DamageType = "Fire";
    };
    healthComp:TakeDamage(dmgData);

    modAudio.Play("BurnTick"..math.random(1, 3), targetPart).PlaybackSpeed = math.random(90,110)/100;
end


return modStatusClass.new(statusPackage);