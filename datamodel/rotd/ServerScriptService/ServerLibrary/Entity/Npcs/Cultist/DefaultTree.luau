local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local treePackage = {
    LogicString = {
        AggroTree = "HasEnemy & MeleeTree";
        MeleeTree = "InMeleeRange & [SwingMelee] | [RunToMeleeRange]";
        Default = "PreLogic | !InCutscene & AggroTree | Idle";
    };
};

function treePackage.HasEnemy(npcClass: NpcClass)
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    if targetHandlerComp == nil then return false; end;

    local enemyTargetData: NpcTargetData? = targetHandlerComp:MatchFirstTarget(function(targetData: NpcTargetData)
        if targetData.HealthComp == nil then return end;
        local targetEntityClass: EntityClass = targetData.HealthComp.CompOwner :: EntityClass;
        if targetEntityClass.ClassName == "Destructible" then return false; end;

        local targetCharacterClass: CharacterClass = targetData.HealthComp.CompOwner :: CharacterClass;

        local isAlive = targetCharacterClass.HealthComp.IsDead ~= true;
        if not isAlive then return false; end;

        if npcClass.Player and targetCharacterClass.ClassName == "PlayerClass" then
            return false;
        end

		local canDamage = targetCharacterClass.HealthComp:CanTakeDamageFrom(npcClass);
		if not canDamage then return false; end;

        return true;
    end)
    npcClass.Properties.EnemyTargetData = enemyTargetData;
    
    return enemyTargetData ~= nil;
end

function treePackage.InMeleeRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData.Distance <= 6;
end

function treePackage.RunToMeleeRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", 18, npcClass.Move.MoveSpeedPriority.Action, 5);
    npcClass.Move:Follow(enemyNpcClass.RootPart, 2);
end

function treePackage.SwingMelee(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;

    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:HeadTrack(enemyNpcClass.RootPart, 2);
    npcClass.Move:LookAt(enemyNpcClass.RootPart.Position);

    wieldComp:InvokeToolAction("PrimarySwingRequest");
end

function treePackage.PreLogic(npcClass: NpcClass)
    local processStatusesComp = npcClass:GetComponent("ProcessStatuses");
    if processStatusesComp then
        return processStatusesComp();
    end
    
    return false;
end

function treePackage.InCutscene(npcClass: NpcClass)
    return npcClass.Properties.CutsceneActive == true;
end

function treePackage.Idle(npcClass: NpcClass)
    return false;
end

return treePackage;