local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local treePackage = {
    LogicString = {
        SprintTree = "HasEnemy & !InMeleeRange & [Sprint]";
        ShackleTree = "HasEnemy & InMeleeRange & CanShackle & [Shackle]";
        Default = "ShackleTree | SprintTree | ZombieBossDefaultTree";
    };
};

function treePackage.ZombieBossDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ZombieBossDefaultTree", false);
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData ~= nil;
end

function treePackage.InMeleeRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData.Distance <= npcClass.Configurations.AttackRange;
end


--MARK: SprintTree
function treePackage.Sprint(npcClass: NpcClass)
    if npcClass.Properties.SprintCooldownTick and npcClass.Properties.SprintCooldownTick > tick() then
        return false;
    end

    if npcClass.WieldComp.EquipmentClass == nil then
        npcClass.Properties.SprintCooldownTick = tick() + 7;
    else
        npcClass.Properties.SprintCooldownTick = tick() + 5;
    end

    npcClass.Move:SetMoveSpeed(
        "set", 
        "sprint", 
        npcClass.Properties.HardMode and 26 or 22, 
        2, 
        npcClass.Properties.HardMode and 3 or 1.5
    );

    return true;
end


--MARK: ShackleTree
function treePackage.CanShackle(npcClass: NpcClass)
    if npcClass.Properties.ShackleCooldownTick and npcClass.Properties.ShackleCooldownTick > tick() then
        return false;
    end
    npcClass.Properties.ShackleCooldownTick = tick() + 2;

    return true;
end

function treePackage.Shackle(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;
    local enemyStatusComp: StatusComp = enemyNpcClass.StatusComp;

    local duration = 10;
    local statusClass: StatusClassInstance = enemyStatusComp:GetOrDefault("Chained");
	if statusClass == nil then
        statusClass = enemyStatusComp:Apply("Chained", {
			Expires = workspace:GetServerTimeNow() + duration;
			Duration = duration;
        })
	end

    local position = enemyNpcClass.RootPart.Position - Vector3.new(0, 1, 0);
    local anchorHealth = npcClass.Properties.HardMode and 2000 or 100;
    local anchorPrefab = statusClass:Func("Chain", duration, position, anchorHealth, npcClass.Properties.HardMode);
    npcClass.Garbage:Tag(anchorPrefab);
end

return treePackage;