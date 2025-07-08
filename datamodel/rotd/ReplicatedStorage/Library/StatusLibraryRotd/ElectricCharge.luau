local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

local modHealthComp = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local remoteArcParticles = modRemotesManager:Get("GenerateArcParticles");
--
local statusPackage = {
    Id="ElectricCharge";
    Icon="";
    Name="Electric Charge";
    Description="Shock and strike nearby targets.";
    Buff=true;
};

local Arc = {
    Color = Color3.fromRGB(255, 179, 0);
    Color2 = Color3.new(1, 1, 1);
    Amount = 1;
    Thickness = 0.2;
};


function statusPackage.StrikeTarget(statusValues: anydict, character: Model)
    local applyBy: CharacterClass = statusValues.ApplyBy;

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
    
    statusValues.ArcOrigin = statusValues.ArcPoint;
    statusValues.ArcPoint = character:GetPivot().Position;

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
    
    local arcOrigin: Vector3 = statusClass.Values.ArcOrigin;
    local arcPoint: Vector3 = statusClass.Values.ArcPoint;
    if arcOrigin then
        for _, player: Player in pairs(game.Players:GetPlayers()) do
            if player:DistanceFromCharacter(arcOrigin) > 64 then return end
            remoteArcParticles:FireClient(player, 0.2, arcOrigin, arcPoint, Arc.Color, Arc.Color2, Arc.Amount, Arc.Thickness);
        end
    end

    local applyTo: ComponentOwner = statusClass.StatusOwner;
    local applyBy: CharacterClass = statusClass.Values.ApplyBy;
    if applyBy.Character and applyTo.Character then
        modDamageTag.Tag(applyTo.Character, applyBy.Character, {
            WeaponItemId = statusClass.Values.WeaponSiid;
        });
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
    
    overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("HealthCompRootParts");
    local radius = statusClass.Values.Radius or 10;
    local rootParts = workspace:GetPartBoundsInRadius(arcPoint, radius, overlapParams);
    for a=1, #rootParts do
        local rootPart = rootParts[a];
        local character = rootPart.Parent;
        if character == applyTo.Character then continue end;

        statusPackage.StrikeTarget(statusClass.Values, character);

        if statusClass.Values.TargetsHit >= statusClass.Values.MaxTargets then break; end;
    end
    
end

return modStatusClass.new(statusPackage);