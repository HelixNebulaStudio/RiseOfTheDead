local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local treePackage = {
    LogicString = {
        Default = "PreLogic | HasEnemy & (AlertTree | AggroTree) | Idle";
        AlertTree = "FaceEnemy & InGrappleRange & GrappleEnemy";
        AggroTree = "InMeleeRange & CanAttack & [Attack]";
        Idle = "[Idle]";
    };
};

--==

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

function treePackage.FaceEnemy(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    local relativeCframe = npcClass.RootPart.CFrame:ToObjectSpace(enemyNpcClass.RootPart.CFrame);
    local dirRad = math.atan2(relativeCframe.X, -relativeCframe.Z);

    local ltJoint = npcClass.Character:WaitForChild("LowerTorso"):WaitForChild("Root");
    TweenService:Create(ltJoint, TweenInfo.new(0.13), {
        C1 = CFrame.Angles(0, dirRad, 0);
    }):Play();
    
    return true;
end

function treePackage.InGrappleRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData.Distance <= npcClass.Configurations.GrappleRange;
end

function treePackage.GrappleEnemy(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyHealthComp: HealthComp = enemyTargetData.HealthComp;

    local properties = npcClass.Properties;
    if properties.LastGrappleTick and properties.LastGrappleTick > tick() then
        return false;
    end
    properties.LastGrappleTick = tick() + npcClass.Configurations.GrappleCooldown;

    local grappleComp = npcClass:GetComponent("TendrilsGrapple");
    if grappleComp then
        grappleComp(enemyHealthComp.CompOwner);
    end

    return true;
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
    
    properties.AttackCooldown = tick() + (configurations.AttackSpeed * math.random(90, 110)/100);
    
    local attackComp = npcClass:GetComponent("ZombieBasicMeleeAttack");
    if attackComp then
        attackComp();
    end
    
    return true;
end

function treePackage.Idle(npcClass: NpcClass)
    return false;
end

return treePackage;