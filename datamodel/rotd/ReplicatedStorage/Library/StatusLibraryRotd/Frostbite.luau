local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService"); 

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local modTDParticles = shared.require(game.ReplicatedStorage.Particles.TDParticles);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modParticleSprinkler = shared.require(game.ReplicatedStorage.Particles.ParticleSprinkler);
local modHealthComp = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
--
local statusPackage = {
    Id = "Frostbite";
    Icon = "";
    Name = "Hit by Frostbite bullet.";
    Description = "Frostbite causing stun and lethal damage.";
    Buff = false;
    Tags = {"DOT"; "Frost"};
};

function statusPackage.onRequire()
    frostParticle = game.ReplicatedStorage.Particles:WaitForChild("Frost");
    iceDecor = game.ReplicatedStorage.Prefabs.Objects:WaitForChild("IceDecor");
    frostTexture = game.ReplicatedStorage.Prefabs.Textures:WaitForChild("FrostTexture");
end

function statusPackage.IceBlast(applyBy: CharacterClass?, packet: anydict)
    local targetCharacterClass: CharacterClass = packet.ApplyTo;
    if targetCharacterClass.Character == nil then
        Debugger:Warn("Target character is nil.", targetCharacterClass == nil or targetCharacterClass.ClassName);
        return;
    end

    local maxTargets: number = packet.Targets;
    local maxRadius: number = packet.Radius;
    local totalSplashDamage: number = packet.TotalSplashDamage;
    local storageItemBy: StorageItem? = packet.StorageItem;
    
    local blastOrigin = targetCharacterClass.Character:GetPivot().Position;

    local overlapParams = OverlapParams.new();
    overlapParams.FilterType = Enum.RaycastFilterType.Include;
    overlapParams.MaxParts = maxTargets+2;
    
    task.spawn(function()
        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Cubic);
        
        local shockWavePacket = {
            Type="Shockwave";
            
            TweenInfo = tweenInfo;
            Origin = CFrame.new(blastOrigin - Vector3.new(0, 1, 0));
            EndSize = Vector3.new(maxRadius*2, 0.2, maxRadius*2);
            
            WaveColor = Color3.fromRGB(175, 221, 255);
            WaveMaterial = Enum.Material.Ice;
            WaveTextureID = "rbxassetid://16279339455";
        };
        
        local newIceBall = Instance.new("Part");
        newIceBall.Anchored = true;
        newIceBall.Material = Enum.Material.Ice;
        newIceBall.Shape = Enum.PartType.Ball;
        newIceBall.CanCollide = false;
        newIceBall.CanQuery = false;
        newIceBall.Size = Vector3.new(2,2,2);
        newIceBall.CFrame = CFrame.new(blastOrigin);
        newIceBall.Color = Color3.fromRGB(175, 221, 255);
        newIceBall.Transparency = 0.3;
        newIceBall.Parent = workspace.Debris;

        modTDParticles:Emit(shockWavePacket);
        TweenService:Create(newIceBall, tweenInfo, {
            Size=Vector3.new(maxRadius*1.8, maxRadius*1.8, maxRadius*1.8);
            Transparency=1;
        }):Play();

    end)

    overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("HealthCompRootParts");

    local hitHealthComps: {HealthComp} = {};

    local rootParts = workspace:GetPartBoundsInRadius(blastOrigin, maxRadius, overlapParams);
    local hitCount = 0;
    for a=1, #rootParts do
        local rootPart = rootParts[a];
        local targetModel = rootPart.Parent;
        if targetModel == targetCharacterClass.Character then continue end;

        local healthComp: HealthComp? = modHealthComp.getByModel(targetModel);
        if healthComp == nil or healthComp.IsDead or not healthComp:CanTakeDamageFrom(applyBy) then continue end;

        if healthComp.CompOwner.StatusComp == nil then continue end;
        local statusComp: StatusComp = healthComp.CompOwner.StatusComp;

        local frostStatusClass: StatusClassInstance = statusComp:GetOrDefault(statusPackage.Id);
        if frostStatusClass then
            frostStatusClass.Expires = workspace:GetServerTimeNow() + 8;
            continue; 
        end;

        statusComp:Apply(statusPackage.Id, {
            Expires = workspace:GetServerTimeNow() + 8;
            Duration = 8;
			ApplyBy = applyBy;
            Values = {
                DoIceBlast = false;
                Damage = packet.Damage;
                StorageItemBy = storageItemBy;
            };
        });
        table.insert(hitHealthComps, healthComp);
        
        hitCount = hitCount +1;
        if hitCount > maxTargets then break; end;
    end
  
    for a=1, #hitHealthComps do
        local healthComp: HealthComp = hitHealthComps[a];

        healthComp:TakeDamage(DamageData.new{ 
            DamageBy = applyBy;
            StorageItem = storageItemBy;
            
            Damage = totalSplashDamage/#hitHealthComps;
            DamageType = "Frost";
        });
    end
end

local faces = {Enum.NormalId.Back; Enum.NormalId.Bottom; Enum.NormalId.Front; Enum.NormalId.Left; Enum.NormalId.Right; Enum.NormalId.Top;};
function statusPackage.IceEffect(targetModel: Model, garbageHandler: GarbageHandler)
    local bodyParts = targetModel:GetDescendants();

    local function applyIceShader(bodyPart: BasePart)
        for b=1, #faces do
            local new = frostTexture:Clone();
            new.Face = faces[b];
            new.Parent = bodyPart;
            garbageHandler:Tag(new);
        end
        if bodyPart.Name == "Head" then
            local newFrostParticle = frostParticle:Clone();
            newFrostParticle.Parent = bodyPart;
            garbageHandler:Tag(newFrostParticle);
        end
        if bodyPart.Name:find("Foot") then
            local newIceRock = iceDecor:Clone();

            local newVal = Instance.new("ObjectValue");
            newVal.Name = "TargetFoot";
            newVal.Value = bodyPart;
            newVal.Parent = newIceRock;

            Debugger.Expire(newIceRock, 10);
            garbageHandler:Tag(newIceRock);
        end
    end

    for a=1, #bodyParts do
        local bodyPart: BasePart = bodyParts[a];
        if not bodyPart:IsA("BasePart") then 
            if bodyPart:IsA("Accessory") and bodyPart:FindFirstChild("Handle") then
                applyIceShader(bodyPart.Handle);
            end
            continue
        end;
        if bodyPart.Name == "HumanoidRootPart" then continue end;
        if bodyPart.Transparency > 0.88 then continue end;

        applyIceShader(bodyPart);
    end
end

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    
    statusClass.ExpiresOnDeath = true;
    statusClass.Values.WeakStun = true;

    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    local healthComp: HealthComp? = characterClass.HealthComp;
    if healthComp == nil or healthComp.IsDead then return end;
    
    if characterClass.ClassName == "NpcClass" and characterClass.Character then
        local targetImmunity = (characterClass :: NpcClass):GetImmunity("Frost");

        if targetImmunity < 1 then
            statusClass.Values.KillHealth = healthComp.MaxHealth * 0.1; 
            statusPackage.IceEffect(characterClass.Character, statusClass.Garbage);
        end
    end
    
    if statusClass.Values.DoIceBlast ~= true then return end;
    statusPackage.IceBlast(statusClass.ApplyBy, {
        ApplyTo = statusClass.StatusOwner;
        Targets = statusClass.Values.Targets;
        Radius = statusClass.Values.Radius;
        TotalSplashDamage = statusClass.Values.Damage;
        Damage = statusClass.Values.Damage;
    });
end

-- When character dies due to reaching health's shatter threshold, status expires.
function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;

    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    if characterClass.Character == nil or not characterClass.HealthComp.IsDead then return end;
   
    local rootPart: BasePart = characterClass.RootPart;
    if rootPart == nil then return end;

    -- Shatter effects
    modAudio.Play("IceShatter", rootPart.Position);

    local rootPartSize = rootPart.Size.Magnitude*0.1;
    local particlePacket = {
        Type = 1;
        Origin = CFrame.new(rootPart.Position);
        Velocity = Vector3.new(0, 1, 0);
        SizeRange = {Min=rootPartSize; Max=rootPartSize};
        Color = Color3.fromRGB(255,255,255);
        Material = Enum.Material.Ice;
        DespawnTime = 3;
        Speed = 30;
        MinSpawnCount = 4;
        MaxSpawnCount = 6;
    };
    modParticleSprinkler:Emit(particlePacket);

end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms1000 == false then return end;

    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    local healthComp: HealthComp? = characterClass.HealthComp;
    if healthComp == nil then return end;

    local storageItemBy: StorageItem? = statusClass.Values.StorageItemBy;
    local toolHandler: ToolHandlerInstance? = statusClass.Values._ToolHandler;

    local damage = statusClass.Values.Damage or 1;
    healthComp:TakeDamage(DamageData.new{
        DamageBy = statusClass.ApplyBy;
        StorageItem = storageItemBy;
        Damage = damage;
        DamageType = "Frost";

        TargetPart = statusClass.Values.TargetPart;
        ToolHandler = toolHandler;
    });
end


return modStatusClass.new(statusPackage);