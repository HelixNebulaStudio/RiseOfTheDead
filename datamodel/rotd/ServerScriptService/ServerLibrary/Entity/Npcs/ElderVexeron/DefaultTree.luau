local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local treePackage = {
    LogicString = {
        HuntTree = "HasEnemy & IsHunting & [Hunt]";
        AttackTree = "HasEnemy & IsAttacking & [Attack]";
        Default = "SnoozeState | HuntTree | AttackTree | Idle";
    };
};

--==
function treePackage.SnoozeState(npcClass: NpcClass)
    local properties = npcClass.Properties;

    if properties.SpitterKilled > 4 then
        properties.SpitterKilled = 0;

        properties.State = "Snooze";
        properties.StageChangedTick = tick();
        properties.SnoozeTimer = tick();

        properties.SpawnSpitterCooldown = tick() + 30;
        for _, model in ipairs(properties.ActiveVexSpitters) do
            game.Debris:AddItem(model, 0);
        end
        table.clear(properties.ActiveVexSpitters);

        modAudio.Play("VexeronGrowl", workspace).PlaybackSpeed = 0.3;
    end

    if properties.State == "EternalSlumber" then
        return true;
        
    elseif properties.State == "Snooze" then
        if properties.SnoozeTimer and tick()-properties.SnoozeTimer > 300 then
            modAudio.Play("VexeronGrowl", workspace).PlaybackSpeed = math.random(35, 40)/100;
            properties.State = "Hunt";
            properties.StageChangedTick = tick();
        end

        return true;
    end
    
    return false;
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local hasEnemy = npcClass.BehaviorTree:RunTree("HasEnemy", false);
    local enemyTargetData: NpcTargetData? = npcClass.Properties.EnemyTargetData;

    if enemyTargetData and enemyTargetData.HealthComp then
        local targetCharacterClass: CharacterClass = enemyTargetData.HealthComp.CompOwner :: CharacterClass;
        if targetCharacterClass.ClassName ~= "PlayerClass" then
            enemyTargetData = nil;
        end
    end

    if hasEnemy and properties.State == "Idle" then
        properties.State = "Hunt";
        properties.StageChangedTick = tick();
    end

    return enemyTargetData ~= nil;
end

function treePackage.Idle(npcClass: NpcClass)
    local properties = npcClass.Properties;
    properties.State = "Idle";
    return true;
end

function treePackage.IsAttacking(npcClass: NpcClass)
    return npcClass.Properties.State == "Attack";
end

function treePackage.Attack(npcClass: NpcClass)
    local properties = npcClass.Properties;

    if tick()-properties.StageChangedTick >= 10 then
        properties.State = "Idle";
        properties.StageChangedTick = tick();
    end

    return true;
end

function treePackage.IsHunting(npcClass: NpcClass)
    return npcClass.Properties.State == "Hunt";
end

function treePackage.Hunt(npcClass: NpcClass)
    local properties = npcClass.Properties;

    if tick()-properties.StageChangedTick >= 16 then
        properties.State = "Attack";
        properties.StageChangedTick = tick();
    end
end

return treePackage;