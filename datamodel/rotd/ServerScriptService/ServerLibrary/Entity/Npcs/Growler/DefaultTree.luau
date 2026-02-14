local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local treePackage = {
    LogicString = {
        Default = "BlockIfExposed | ZombieDefaultTree";
    };
};

--==
function treePackage.BlockIfExposed(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    if enemyTargetData == nil then return false; end;
    if enemyTargetData.Distance > 50 then return false; end;

    local enemyHealthComp: HealthComp = enemyTargetData.HealthComp;
    local targetEntityClass: EntityClass = enemyHealthComp.CompOwner;
    if targetEntityClass.ClassName == "Destructible" then return false; end;

    local targetCharacterClass: CharacterClass = targetEntityClass :: CharacterClass;
    local targetCFrame = targetCharacterClass:GetCFrame();

    local targetDir = (npcClass:GetCFrame().Position - targetCFrame.Position).Unit;

    local angle = targetDir:Angle(targetCFrame.CFrame.LookVector);
    if math.abs(angle) < 1.5 then
        npcClass.Move:SetMoveSpeed("set", "walk", 4, npcClass.Move.MoveSpeedPriority.Action);
        npcClass.PlayAnimation("Block");
        
    else
        npcClass.Move:SetMoveSpeed("remove", "walk");
        npcClass.StopAnimation("Block");
        
    end;

    return false;
end

function treePackage.ZombieDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ZombieDefaultTree", false);
end

return treePackage;