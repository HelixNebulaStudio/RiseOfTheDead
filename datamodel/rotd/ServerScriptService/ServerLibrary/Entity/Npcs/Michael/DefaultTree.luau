local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

local treePackage = {
    LogicString = {
        Default = "(HasEnemy & MissionCheck & [Skip]) | SurvivorCombatTree | [Idle]";
    };
};

function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = properties.EnemyTargetData;

    return enemyTargetData ~= nil;
end

function treePackage.Skip()
end

function treePackage.MissionCheck(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = properties.EnemyTargetData;

    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;
    local enemyStatusComp: StatusComp = enemyNpcClass.StatusComp;

    local entityLeashStatus: StatusClassInstance = enemyStatusComp:GetOrDefault("EntityLeash");

    if entityLeashStatus and not enemyNpcClass.HealthComp.IsDead then
        local applyBy: PlayerClass = entityLeashStatus.ApplyBy :: PlayerClass;
        local player = applyBy and applyBy:GetInstance();
        if player and player.Parent ~= nil then
            local mission = modMission:Progress(player, 53);
            if (mission == nil or mission.ProgressionPoint < 8) and enemyNpcClass.Properties.LeashedIgnore ~= true then
                if properties.LeashQuestion == nil or tick() > properties.LeashQuestion then
                    properties.LeashQuestion = tick() + 5;

                    modMission:Progress(player, 53, function(mission)
                        if mission.ProgressionPoint == 6 then
                            mission.ProgressionPoint = 7;
                        end
                    end)		
                    npcClass.Chat(game.Players:GetPlayers(), "Hey! What are you trying to do?!");   	
                end

                npcClass.Move:SetMoveSpeed("set", "talk", 0, npcClass.Move.MoveSpeedPriority.Action, 1);

                local wieldComp = npcClass.WieldComp;
                local ammo = wieldComp.EquipmentClass.Properties.Ammo;
                if ammo and ammo <= 0 then 
                    wieldComp:InvokeToolAction("ReloadRequest");

                else
                    npcClass.Move:HeadTrack(enemyNpcClass.RootPart, 2);
                    npcClass.Move:Face(enemyNpcClass.RootPart.Position);

                    local shootDirection = (enemyNpcClass:GetCFrame().Position - npcClass:GetCFrame().Position).Unit;

                    local targetHumanoid = nil;
                    if enemyNpcClass.ClassName == "NpcClass" or enemyNpcClass.ClassName == "PlayerClass" then
                        targetHumanoid = (enemyNpcClass :: CharacterClass).Humanoid;
                    end

                    wieldComp:InvokeToolAction(
                        "PrimaryFireRequest", 
                        shootDirection, 
                        targetHumanoid
                    );
                end;
            else
                enemyNpcClass.Properties.LeashedIgnore = true;
                if properties.LeashWarn == nil or tick() > properties.LeashWarn then
                    properties.LeashWarn = tick() + 10;
                    npcClass.Chat(game.Players:GetPlayers(), "Becareful with that thing..");
                end
            end
        end

        return true;
    end

    if enemyNpcClass.HealthComp.IsDead then
        npcClass.WieldComp.Controls.Mouse1Down = false;
    end

    return false;
end

function treePackage.SurvivorCombatTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("SurvivorCombatTree", false);
end

function treePackage.Idle(npcClass: NpcClass)
    local spawnPos = npcClass.SpawnCFrame.Position;
    if not npcClass.Move:IsAtPosition(spawnPos) then
        npcClass.Move:MoveTo(spawnPos);
    end
end

return treePackage;