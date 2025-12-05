local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService")

local treePackage = {
    LogicString = {
        LeapTree = "HasEnemy & CanLeap & [Leap]";
        Default = "LeapTree | ZombieBossDefaultTree";
    };
};
--==
function treePackage.ZombieBossDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ZombieBossDefaultTree", false);
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData ~= nil;
end


--MARK: Leap
function treePackage.CanLeap(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if properties.LastLeap and tick()-properties.LastLeap <= 3 then return false; end;
    return true;
end

function treePackage.Leap(npcClass: NpcClass)
    local properties = npcClass.Properties;
    properties.LastLeap = tick();

    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyRootPart = enemyTargetData.Model.PrimaryPart;

    local leapPower = 100;

    local tarPos = enemyRootPart.CFrame.Position;
    npcClass.RootPart.AssemblyLinearVelocity = Vector3.new();
    task.wait();

    local leapDir = (tarPos-npcClass.RootPart.Position).Unit
    npcClass.RootPart.AssemblyLinearVelocity = leapDir * Vector3.new(leapPower, 0, leapPower);
    npcClass.Humanoid.Jump = true;
end

return treePackage;