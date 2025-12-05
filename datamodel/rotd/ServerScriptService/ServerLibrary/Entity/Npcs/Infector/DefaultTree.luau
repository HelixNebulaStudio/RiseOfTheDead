local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local treePackage = {
    LogicString = {
        Default = "PreLogic | HasEnemy & (AlertTree | AggroTree) | [Idle]";
        AlertTree = "LookAtEnemy";
        AggroTree = "InMeleeRange & CanAttack & [Attack] | [FollowEnemy]";
    };
}

function treePackage.PreLogic(npcClass: NpcClass)
    return false;
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");

    local enemyTargetData = targetHandlerComp:MatchFirstTarget(function(targetData)
        if targetData.HealthComp == nil then return end;
        local targetCharacterClass: CharacterClass = targetData.HealthComp.CompOwner;

        if targetCharacterClass.ClassName == "PlayerClass" then
            local player: Player = (targetCharacterClass :: PlayerClass):GetInstance();

            if npcClass.NetworkOwners then
                local isNetOwner = table.find(npcClass.NetworkOwners, player) ~= nil;
                if not isNetOwner then
                    return false;
                end
            end
        end

        local isAlive = targetCharacterClass.HealthComp.IsDead ~= true;
        if not isAlive then return false end;

        local isTargettable = targetCharacterClass.HealthComp:CanTakeDamageFrom(npcClass);
        if not isTargettable then return false end;

        local isInRange = (targetData.Distance <= properties.TargetableDistance);
        if not isInRange then return false end;

        return true;
    end);

    properties.EnemyTargetData = enemyTargetData;

    return enemyTargetData ~= nil;
end

function treePackage.LookAtEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    local curTick = tick();
    if properties.LookAtEnemyTick == nil then
        properties.LookAtEnemyTick = curTick + math.random(200, 300)/1000;
		npcClass.PlayAnimation("Aggro");
        return true;

    elseif properties.LookAtEnemyTick > curTick then
        npcClass.Move:Face(enemyNpcClass.RootPart);
        return true;

    end

    return false;
end

function treePackage.FollowEnemy(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    local properties = npcClass.Properties;

    if properties.SprintCooldown == nil or tick() > properties.SprintCooldown then
        properties.SprintCooldown = tick() +math.random(50, 60)/10;
        npcClass.Move:SetMoveSpeed("set", "sprint", 100, 2, 2);
    end

    npcClass.Move:Follow(enemyNpcClass.RootPart);    
end

function treePackage.Idle(npcClass: NpcClass)
    return false;
end

function treePackage.InMeleeRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData.Distance <= npcClass.Configurations.AttackRange;
end

function treePackage.CanAttack(npcClass: NpcClass)
    local properties = npcClass.Properties;
    return properties.AttackCooldown == nil or tick() > properties.AttackCooldown;
end

function treePackage.Attack(npcClass: NpcClass)
    local configurations = npcClass.Configurations;
    local properties = npcClass.Properties;

    local enemyTargetData = npcClass.Properties.EnemyTargetData;

    local enemyHealthComp: HealthComp = enemyTargetData.HealthComp;
    local enemyCharacterClass: CharacterClass = enemyHealthComp.CompOwner;

    local targetPosition = enemyCharacterClass.RootPart.Position;
    local relativeCframe = npcClass.RootPart.CFrame:ToObjectSpace(CFrame.new(targetPosition));
    
    local dirAngle = math.deg(math.atan2(relativeCframe.X, -relativeCframe.Z));
    if math.abs(dirAngle) > 50 then
        properties.AttackCooldown = tick() + math.random(10, 20)/100;
        return false;
    end;
    
    properties.AttackCooldown = tick() + (configurations.AttackSpeed * math.random(90, 110)/100);
    
    npcClass.PlayAnimation("Attack",0.05, nil, 2);


    local dmgData: DamageData = DamageData.new{
        Damage = 10;
        DamageBy = npcClass;
        DamageTo = enemyCharacterClass;
        DamageCate = DamageData.DamageCategory.Melee;
    };

    if enemyCharacterClass.ClassName == "PlayerClass" then
        local enemyPlayer = (enemyCharacterClass :: PlayerClass):GetInstance();
        
        shared.modPlayers.cameraShakeAndZoom(enemyPlayer, 10, 5, 4, 0.01, true);

        local dir = npcClass.RootPart.CFrame.LookVector;
        modAudio.Play("Punch", npcClass.RootPart);
        modStatusEffects.Launch(enemyPlayer, (dir+Vector3.new(0, 1, 0))*100);
       
    else
        dmgData.Damage = enemyCharacterClass.HealthComp.MaxHealth * 0.1;

    end

    enemyHealthComp:TakeDamage(dmgData);
    
    return true;
end

return treePackage;