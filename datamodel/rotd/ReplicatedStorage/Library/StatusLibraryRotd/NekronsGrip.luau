local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

--==
local statusPackage = {
    Id = "NekronsGrip";
    Icon = "rbxassetid://110726481798370";
    Name = "Nekrons Grip";
    Description = "Deadly nekron's veins lifting you up.";
    Buff = false;
    ExpiresOnDeath = true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    local characterClass = statusClass.StatusOwner :: CharacterClass;
    if characterClass == nil then return end;

    local character = characterClass.Character;

    local groundPart, originPosition;
    if characterClass.ClassName == "PlayerClass" then
        local playerClass = characterClass :: PlayerClass;
        local player = playerClass:GetInstance();

        groundPart, originPosition = characterClass:CastGroundRay(64);
        if groundPart == nil then
            originPosition = characterClass.RootPart.Position;
        end

        modStatusEffects.AntiGravity(player, 1000);
    end

    local originAnchor = Debugger:PointPart(originPosition);
    originAnchor.Transparency = 1;
    originAnchor.Parent = character;
    statusClass.Garbage:Tag(originAnchor);

    local oAtt = Instance.new("Attachment");
    oAtt.Parent = originAnchor;

    local rope = Instance.new("RopeConstraint");
    rope.Attachment0 = characterClass.RootPart:FindFirstChild("RootRigAttachment");
    rope.Attachment1 = oAtt;
    rope.Visible = false;
    rope.Length = 16;
    rope:SetAttribute("FPIgnore", true);
    rope.Parent = originAnchor;

    statusClass.Garbage:Tag(rope);
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms500 == false then return end;

    local characterClass = statusClass.StatusOwner;
    local rootPart = characterClass.RootPart;

    local healthComp = characterClass.HealthComp;
    if healthComp == nil or healthComp.IsDead then return end;    

    rootPart.AssemblyLinearVelocity = Vector3.new(0, 10, 0);

    local damage = healthComp.MaxHealth * 0.05;

    healthComp:TakeDamage(DamageData.new{
        Damage = damage;
    });    
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;

    local characterClass = statusClass.StatusOwner :: CharacterClass;
    if characterClass.ClassName == "PlayerClass" then
        local playerClass = characterClass :: PlayerClass;
        local player = playerClass:GetInstance();

        modStatusEffects.AntiGravity(player, nil);
    end

    local oldSporeDestructConfig = statusClass.Values.SporeDestructConfig;
    local oldSporeDestructible: DestructibleInstance = oldSporeDestructConfig and modDestructibles.getOrNew(oldSporeDestructConfig) or nil;
    if oldSporeDestructible then
        oldSporeDestructible.HealthComp:SetIsDead(true);
    end
end

return modStatusClass.new(statusPackage);