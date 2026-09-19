local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService")

local treePackage = {
    LogicString = {
        BlinkTree = "HasEnemy & CanBlink & [Blink]";
        StrangleTree = "HasEnemy & CanStrangle & [Strangle]";
        Default = "StrangleTree | BlinkTree | ZombieBossDefaultTree";
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


--MARK: BlinkTree
function treePackage.CanBlink(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if properties.IsStrangling then return false; end;
    if properties.LastBlink and tick()-properties.LastBlink <= 4 then return false; end;

    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyCharacterClass: CharacterClass = enemyTargetData.HealthComp.CompOwner :: CharacterClass;
    if enemyCharacterClass:DistanceFrom(npcClass:GetCFrame().Position) >= 24 then return true; end;

    return true;
end

function treePackage.Blink(npcClass: NpcClass)
    npcClass.Properties.LastBlink = tick();

    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;

    local bc = npcClass.Character:GetAttribute("BlinkCount") or 0;
    npcClass.Character:SetAttribute("BlinkCount", bc +1);
    
    local blinkComp = npcClass:GetComponent("BlinkTeleport");
    blinkComp(enemyTargetData.Model);
end


--MARK: StrangleTree
function treePackage.CanStrangle(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local lastTargetStrangleTick = properties.LastStrangle;
    if lastTargetStrangleTick and tick() <= lastTargetStrangleTick then 
        return false;
    end;

    local enemyTargetData: NpcTargetData = properties.EnemyTargetData;
    local enemyCharacterClass: CharacterClass = enemyTargetData.HealthComp.CompOwner :: CharacterClass;
    local enemyStatusComp: StatusComp = enemyCharacterClass.StatusComp;

    if enemyStatusComp:GetOrDefault("ShadowStrangle") then return false; end;

    return true;
end

function treePackage.Strangle(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if properties.IsStrangling then return; end;
    properties.IsStrangling = true;

    local isHard = properties.HardMode;
    local strangleDuration = isHard and 30 or 10;
    strangleDuration = math.random(strangleDuration-2, strangleDuration+2);
    properties.LastStrangle = tick() + strangleDuration + 4;

    local enemyTargetData: NpcTargetData = properties.EnemyTargetData;
    local enemyCharacterClass: CharacterClass = enemyTargetData.HealthComp.CompOwner :: CharacterClass;
    local enemyStatusComp: StatusComp = enemyCharacterClass.StatusComp;

    npcClass.PlayAnimation("Strangle");

    local statusClass: StatusClassInstance = enemyStatusComp:Apply("ShadowStrangle", {
        Expires = workspace:GetServerTimeNow() + strangleDuration;
        Duration = strangleDuration;
        Values = {
            ShadowHealth = npcClass.HealthComp.CurHealth;
            ShadowHumanoid = npcClass.Humanoid;
        };
    });
    statusClass.Garbage:Tag(function()
        Debugger:Warn(`{npcClass.Name} Strangle expired`);
        
        npcClass.StopAnimation("Strangle");
        properties.IsStrangling = false;
    end)
end

return treePackage;