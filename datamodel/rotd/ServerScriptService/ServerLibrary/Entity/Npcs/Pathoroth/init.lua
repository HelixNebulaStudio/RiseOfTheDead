local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local npcPackage = {
    Name = "Pathoroth";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 50;
        AttackRange = 14;
        AttackSpeed = 4;

        MaxHealth = 100;
        WalkSpeed = 16;
    };
    
    Properties = {
        BasicEnemy = false;
        IsHostile = true;

        TargetableDistance = 128;

        Level = 1;
        ExperiencePool = 200;
        MoneyReward = {Min = 1500; Max = 1700};
        DropRewardId = "pathoroth";
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "BodyDestructibles";
        "ZombieBasicMeleeAttack";
    };
    AddBehaviorTrees = {
        "HasEnemy";
        "ZombieDefaultTree";
    };

    ThinkCycle = 1;
};
--==

function npcPackage.onRequire()
    HORROR_PARTICLE = script:WaitForChild("HorrorParticle");
end

function npcPackage.Spawning(npcClass: NpcClass)
    local character = npcClass.Character;
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;
    local healthComp: HealthComp = npcClass.HealthComp;

    character:SetAttribute("EntityHudHealth", true);

    local isHard = properties.HardMode;
    local level = math.max(properties.Level, 0);

    if isHard then
        configurations.BaseValues.MaxHealth = math.max(10000 + 500*level, 10000);
    else
        configurations.BaseValues.MaxHealth = math.max(10000 + 500*level, 10000);
    end

    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");

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
end

function npcPackage.Spawned(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local healthComp = npcClass.HealthComp;

    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");

    npcClass.WieldComp.TargetableTags = {
        Zombie = true;
    }

    local binds = npcClass.Binds;
    function binds.EquipSuccessFunc(toolHandler: ToolHandlerInstance)
        local equipmentClass: EquipmentClass? = toolHandler.EquipmentClass;
        if equipmentClass == nil then return end;

        if equipmentClass.Class == "Gun" then
            local modifier = equipmentClass.Configurations.newModifier("PathorothGun");
            modifier.SetValues.NpcPercentHealthDamage = 0.05;
            modifier.SetValues.DamageType = "Heal";
            equipmentClass.Configurations:AddModifier(modifier, true);

        elseif equipmentClass.Class == "Melee" then
            local modifier = equipmentClass.Configurations.newModifier("PathorothMelee");
            modifier.SetValues.NpcPercentHealthDamage = 0.1;
            modifier.SetValues.DamageType = "Heal";
            equipmentClass.Configurations:AddModifier(modifier, true);
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

    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    npcClass.Garbage:Tag(npcClass.OnThink:Connect(function()
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