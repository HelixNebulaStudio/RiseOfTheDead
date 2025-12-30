local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);
local modArcParticles = shared.require(game.ReplicatedStorage.Particles.ArcParticles);
local modHealthComp = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

--
local statusPackage = {
    Id = "ElectricCharge";
    Icon = "";
    Name = "Electric Charge";
    Description = "Shock and strike nearby targets.";
    Buff = false;
};

local Arc = {
    Color = Color3.fromRGB(255, 179, 0);
    Color2 = Color3.new(1, 1, 1);
    Amount = 1;
    Thickness = 0.2;
};


function statusPackage.StrikeTarget(applyBy: CharacterClass, statusValues: anydict, character: Model)
    local healthComp: HealthComp? = modHealthComp.getByModel(character);
    if healthComp == nil or healthComp.IsDead or not healthComp:CanTakeDamageFrom(applyBy) then return end;

    local ownerClass: ComponentOwner = healthComp.CompOwner;
    local statusComp: StatusComp? = ownerClass.StatusComp;
    if statusComp == nil then return end;

    if ownerClass.ClassName == "NpcClass" then
        local targetImmunity = (ownerClass :: NpcClass):GetImmunity("Electric"); 
        if targetImmunity >= 1 then return end;
    end        

    local existingStatusClass: StatusClassInstance? = statusComp:GetOrDefault(statusPackage.Id);				
    if existingStatusClass then return end;
    
    statusComp:Apply(statusPackage.Id, {
        Expires = workspace:GetServerTimeNow()+1; 
        Values = statusValues;
    });
end

local overlapParams = OverlapParams.new();
overlapParams.FilterType = Enum.RaycastFilterType.Include;
overlapParams.MaxParts = 10;

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    
    local applyTo: ComponentOwner = statusClass.StatusOwner;
    local applyBy: CharacterClass? = statusClass.ApplyBy;
    if applyBy and applyBy.Character and applyTo.Character then
        modDamageTag.Tag(applyTo.Character, applyBy.Character, {
            WeaponItemId = statusClass.Values.WeaponSiid;
        });
    end

    local originAtt = statusClass.Values.OriginAtt;
    local hitPart = statusClass.Values.HitPart;
    local hitPosition = hitPart.Position;

    if originAtt then
        local hitAtt = Instance.new("Attachment");
        hitAtt.Parent = hitPart;
        hitAtt.Name = `ElectricCharge_{hitPart.Name}`;
        Debugger.Expire(hitAtt, 1);

        Debugger.Expire(modArcParticles.broadcast(originAtt, hitAtt, {
            Color = Arc.Color;
            Color2 = Arc.Color2;
            Amount = Arc.Amount or 4;
            Thickness = Arc.Thickness;
        }), originAtt.Name == "BulletOrigin" and 0.2 or 1);
    end

    
    local healthComp: HealthComp? = applyTo.HealthComp;
    if healthComp then
        local damage = statusClass.Values.Damage;
        local damagePercent = statusClass.Values.DamagePercent;
        local targetsHit = statusClass.Values.TargetsHit;

        local dmgRatio = math.clamp(damagePercent - 0.02*targetsHit, 0.05, 1);
        
        local dmgData: DamageData = DamageData.new();
        dmgData.Damage = math.max(damage*dmgRatio, 1);
        
        local damageType: DAMAGE_TYPE<DAMAGE_TYPE_ROTD> = "Electric";
        dmgData.DamageType = damageType;

        healthComp:TakeDamage(dmgData);
    end 

    statusClass.Values.TargetsHit = statusClass.Values.TargetsHit +1;
    
    if applyBy == nil then return end;

    overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("HealthCompRootParts");
    local radius = statusClass.Values.Radius or 16;

    local rootParts = workspace:GetPartBoundsInRadius(hitPosition, radius, overlapParams);
    for a=1, #rootParts do
        local rootPart = rootParts[a];
        local character = rootPart.Parent;
        if character == applyTo.Character then continue end;
        task.wait(0.1);

        local hitAtt = Instance.new("Attachment");
        hitAtt.Name = `ElectricCharge_{hitPart.Name}`;
        hitAtt.Parent = hitPart;
        Debugger.Expire(hitAtt, 1);
        statusClass.Values.OriginAtt = hitAtt;
        statusClass.Values.HitPart = rootPart;

        statusPackage.StrikeTarget(applyBy, statusClass.Values, character);

        if statusClass.Values.TargetsHit >= statusClass.Values.MaxTargets then break; end;
    end
end

return modStatusClass.new(statusPackage);