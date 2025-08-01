local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local treePackage = {
    Logic = {
        Root = {"And"; "NoEnemyTarget"; "Idle"};
    };
}

function treePackage.NoEnemyTarget(tree, npcClass: NpcClass)
    return npcClass.Properties.EnemyTargetData == nil and tree.Success or tree.Failure;
end

function treePackage.Idle(tree, npcClass: NpcClass)
    local properties = npcClass.Properties;
    local spawnPoint = npcClass.SpawnPoint.Position;

    if properties.FakeSpawnPoint then
        spawnPoint = properties.FakeSpawnPoint.Position;
    end
    
    if (npcClass.RootPart.Position-spawnPoint).Magnitude >= 24 then
        npcClass.Move:MoveTo(spawnPoint);
        
    else
        properties.TriggerHostileTick = nil;
        
    end
    
    if npcClass.Move.IsMoving == false then
        if math.random(1, 20) == 1 then
            npcClass.PlayAnimation("Idle");
            modAudio.Play("ZombieIdle"..math.random(1,4), npcClass.RootPart).PlaybackSpeed = math.random(80, 120)/100;
            
        elseif math.random(1, 40) == 1 then
            npcClass.Move:MoveTo(spawnPoint + Vector3.new(
                (math.random(1, 2) == 1 and 1 or -1) * math.random(4, 16),
                0,
                (math.random(1, 2) == 1 and 1 or -1) * math.random(4, 16)
                )
            );
            
        end
        
    end

    return tree.Success;
end

return treePackage;