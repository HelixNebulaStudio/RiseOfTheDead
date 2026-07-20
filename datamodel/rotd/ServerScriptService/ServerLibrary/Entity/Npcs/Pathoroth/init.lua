local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local npcPackage = {
    Name = "Pathoroth";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 50;
        AttackRange = 8;
        AttackSpeed = 4;

        MaxHealth = 100;
        WalkSpeed = 16;
    };
    
    Properties = {
        BasicEnemy = false;
        IsHostile = true;
        AllyTypes = {"Zombie"};

        TargetableDistance = 128;

        Level = 1;
        BaseExperience = 200;
        MoneyReward = {Min = 1500; Max = 1700};
        DropRewardId = "pathoroth";
        ThornResist = 0.95;
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "BodyDestructibles";
        "ZombieBasicMeleeAttack";
        "RandomClothing";
        "DynamicLevel";
        "ThrowTarget";
    };
    AddBehaviorTrees = {
        "HasEnemy";
        "ZombieDefaultTree";
    };

    ThinkCycle = 1;

    DynamicLevelScaling = {
        WalkSpeed = function(lvl) return math.clamp(18 + math.floor(lvl/10), 1, 35); end;
        MaxHealth = function(lvl) return 500+(math.max(2000*lvl, 500)); end;
        AttackDamage = function(lvl) return math.min(25+(lvl/2), 100); end;
    };
};
--==

function npcPackage.onRequire()
    HORROR_PARTICLE = script:WaitForChild("HorrorParticle");
end

function npcPackage.Spawning(npcClass: NpcClass)
    local character = npcClass.Character;
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<anydict> = npcClass.Properties;
    local healthComp: HealthComp = npcClass.HealthComp;

    character:SetAttribute("EntityHudHealth", true);

    local horrorParticle = HORROR_PARTICLE:Clone();
    horrorParticle.Parent = npcClass.RootPart;
    properties.HorrorParticle = horrorParticle;

    local face = npcClass.Head:FindFirstChild("face");
    properties.FaceDecal = face;

    properties.IsLargePathoroth = false;
    properties.MorphTimer = tick()-20;
    properties.MorphCooldown = 20;
    properties.MorphTarget = nil;
    properties.MorphAccessories = {};
    
    if properties.Seed == nil then 
        properties.Seed = math.random(1, 100000);
    end;

    npcClass:GetComponent("RandomClothing"){
        Name = "Stranger";
        AddHair = false;
        AddFace = false;
    };
end

function npcPackage.Spawned(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local healthComp = npcClass.HealthComp;

    local binds = npcClass.Binds;
    function binds.EquipSuccessFunc(toolHandler: ToolHandlerInstance)
        local equipmentClass: EquipmentClass? = toolHandler.EquipmentClass;
        if equipmentClass == nil then return end;

        if equipmentClass.Class == "Gun" then
            equipmentClass:AddBaseModifier("PathorothGun", {
                SetValues = {
                    Damage = 2;
                    PreModDamage = 2;
                    NpcDamageType = "Heal";
                    NpcPercentHealthDamage = 0.05;
                };
                Priority = 9;
            });

        elseif equipmentClass.Class == "Melee" then
            equipmentClass:AddBaseModifier("PathorothMelee", {
                SetValues = {
                    Damage = 10;
                    PreModDamage = 10;
                    NpcDamageType = "Heal";
                    NpcPercentHealthDamage = 0.1;
                };
                Priority = 9;
            });
        end
    end

    healthComp.OnHealthChanged:Connect(function(newHealth, oldHealth, damageData)
        local isHeal = newHealth > oldHealth;
        if isHeal then 
            healthComp:TakeDamage(DamageData.new{
                Damage = -healthComp.MaxHealth*0.1;
                DamageType = "Heal";
            });
            return
        end;

        local damageBy: CharacterClass? = damageData.DamageBy;
        if damageBy == nil or damageBy.ClassName ~= "PlayerClass" then return end;
        if healthComp:CanTakeDamageFrom(damageBy) == false then return end;

        local damageByCharacter = damageBy.Character;
        local morphTarget = properties.MorphTarget;
        if morphTarget ~= damageByCharacter then return end;

        local dmg = 3;
        if damageBy.HealthComp.CurHealth-dmg <= 10 then return end;

        local newDmgData = DamageData.new{
            Damage = dmg;
            DamageBy = npcClass;
            DamageType = "Thorn";
        }
        damageBy.HealthComp:TakeDamage(newDmgData);
    end)

    local lastEntityScan = tick();
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    npcClass.Garbage:Tag(npcClass.OnThink:Connect(function()
        if npcClass.Head then
            npcClass.Head.CanCollide = false;
        end
        local character = npcClass.Character;
        if character:FindFirstChild("UpperTorso") then
            character.UpperTorso.CanCollide = false;
        end

        if tick() < lastEntityScan then return end;
        lastEntityScan = tick() + math.random(2, 5);

        local scanEntities = shared.modNpcs.listInRange(npcClass:GetCFrame().Position, 25);
        
        for a=1, #scanEntities do
            local scanNpcClass: NpcClass = scanEntities[a];
            if scanNpcClass == nil or scanNpcClass == npcClass then continue end;
            if scanNpcClass.HumanoidType ~= "Zombie" then continue end;
            if scanNpcClass.HealthComp.IsDead then continue end;

            targetHandlerComp:AddTarget(scanNpcClass.Character, scanNpcClass.HealthComp);
        end
    end));
end

return npcPackage;