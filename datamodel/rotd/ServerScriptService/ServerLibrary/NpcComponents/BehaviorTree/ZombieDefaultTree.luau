local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local treePackage = {
    Logic = {
        Root = {"Or"; "PreLogic"; "AggroSequence"; "ZombieIdleTree"};
        AggroSequence = {"And"; "HasEnemyTarget"; "AggroSelect";};
        AggroSelect = {"Or"; "AttackSequence"; "FollowTarget"};
        AttackSequence = {"And"; "CanAttackTarget"; "Attack"};
    };
};

function treePackage.PreLogic(tree, npcClass: NpcClass)
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");

    local enemyTargetData = targetHandlerComp:MatchFirstTarget(function(targetData)
        if targetData.HealthComp == nil then return end;
        local targetNpcClass: NpcClass = targetData.HealthComp.CompOwner;

        local isAlive = targetNpcClass.HealthComp.IsDead ~= true;
        local isInVision = npcClass:IsInVision(targetNpcClass.RootPart);

        return isAlive and isInVision;
    end);
    npcClass.Properties.EnemyTargetData = enemyTargetData;

    local properties = npcClass.Properties;
    if properties.AttackCooldown == nil then
        properties.AttackCooldown = tick();
    end

    return tree.Pass;
end

function treePackage.HasEnemyTarget(tree, npcClass: NpcClass)
    return npcClass.Properties.EnemyTargetData ~= nil and tree.Success or tree.Failure;
end

function treePackage.CanAttackTarget(tree, npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;

    local properties = npcClass.Properties;
    local targetModel = enemyTargetData.Model;

    local isInRange = modVector.InCenter(
        npcClass.RootPart.Position, 
        targetModel:GetPivot().Position, 
        npcClass.Properties.AttackRange
    );
    
    if isInRange and (tick() > properties.AttackCooldown) then
        return tree.Success;
    end

	return tree.Failure;
end

function treePackage.Attack(tree, npcClass: NpcClass)
    local configurations = npcClass.Configurations;
    local properties = npcClass.Properties;

    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyHealthComp: HealthComp = enemyTargetData.HealthComp;
    local enemyNpcClass: NpcClass = enemyHealthComp.CompOwner;

    local targetPosition = enemyNpcClass.RootPart.Position;
    local relativeCframe = npcClass.RootPart.CFrame:ToObjectSpace(CFrame.new(targetPosition));

    local dirAngle = math.deg(math.atan2(relativeCframe.X, -relativeCframe.Z));
    if math.abs(dirAngle) > 50 then
        properties.AttackCooldown = tick() + math.random(10, 20)/100;
        return tree.Success;
    end;
    
    properties.AttackCooldown = tick() + (configurations.AttackSpeed * math.random(90, 110)/100);
    
    local attackComp = npcClass:GetComponent("ZombieBasicMeleeAttack");
    if attackComp then
        attackComp();
    end
    
    return tree.Success;
end

function treePackage.FollowTarget(tree, npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;

    local enemyHealthComp: HealthComp = enemyTargetData.HealthComp;
    local enemyNpcClass: NpcClass = enemyHealthComp.CompOwner;

    npcClass.Move:Follow(enemyNpcClass.RootPart);

    return tree.Success;
end

return treePackage;

---@tree a