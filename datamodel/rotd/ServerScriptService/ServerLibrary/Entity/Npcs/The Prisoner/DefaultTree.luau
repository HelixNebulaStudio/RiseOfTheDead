local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local treePackage = {
    LogicString = {
        Default = "PreLogic | AggroTree | IdleTree";
        AggroTree = "HasEnemy & FollowEnemy & MeleeTree";
        MeleeTree = "InMeleeRange & [SwingMelee] | [SprintToEnemy]";
        IdleTree = "[Idle]";
    };
}

function treePackage.PreLogic(npcClass: NpcClass)
    if npcClass.HealthComp.CurHealth <= npcClass.HealthComp.MaxHealth*0.5 then
        if npcClass.WieldComp.EquipmentClass == nil then
            npcClass.WieldComp:Equip{
                ItemId = "survivalknife";
                OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
                    if toolHandler.EquipmentClass == nil then return end;
                    local equipmentClass: EquipmentClass = toolHandler.EquipmentClass;

                    local modifier: ConfigModifier = equipmentClass.Configurations.newModifier("npcDmg");
                    modifier.SetValues.Damage = 25;
                    modifier.Priority = 999;
                    equipmentClass.Configurations:AddModifier(modifier, true);
                end;
            };
        end
    else
        if npcClass.WieldComp.EquipmentClass then
            npcClass.WieldComp:Unequip();
        end
    end

    return false;
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    if targetHandlerComp == nil then return false; end;

    local enemyTargetData = targetHandlerComp:MatchFirstTarget(function(targetData)
        if targetData.HealthComp == nil then return end;
        local targetCharacterClass: CharacterClass = targetData.HealthComp.CompOwner;

        local isAlive = targetCharacterClass.HealthComp.IsDead ~= true;
        local isInVision = npcClass:IsInVision(targetCharacterClass.RootPart);

        local isNetworkOwner = true;
        if npcClass.NetworkOwners and targetCharacterClass.ClassName == "PlayerClass" then
            local player: Player = (targetCharacterClass :: PlayerClass):GetInstance();
            isNetworkOwner = table.find(npcClass.NetworkOwners, player) ~= nil;
        end

        return isAlive and isInVision and isNetworkOwner;
    end);
    npcClass.Properties.EnemyTargetData = enemyTargetData;
    
    if enemyTargetData == nil then
        npcClass.Move:Follow();
    end

    return enemyTargetData ~= nil;
end

function treePackage.InMeleeRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData.Distance <= npcClass.Configurations.AttackRange;
end

function treePackage.SwingMelee(npcClass: NpcClass)
    if npcClass.Properties.AttackCooldownTick and npcClass.Properties.AttackCooldownTick > tick() then
        return false;
    end
    npcClass.Properties.AttackCooldownTick = tick() + npcClass.Configurations.AttackSpeed;

    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:HeadTrack(enemyNpcClass.RootPart, 2);
    npcClass.Move:Face(enemyNpcClass.RootPart.Position);

    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass and wieldComp.EquipmentClass.Class == "Melee" then
        wieldComp:InvokeToolAction("PrimarySwingRequest");
    else
        local meleeAttackComp = npcClass:GetComponent("MeleeAttack");
        if meleeAttackComp then
            meleeAttackComp(enemyNpcClass);
        end
    end

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

    return true;
end

function treePackage.FollowEnemy(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:Follow(enemyNpcClass.RootPart, 2);
    return true;
end

function treePackage.SprintToEnemy(npcClass: NpcClass)
    if npcClass.Properties.SprintCooldownTick and npcClass.Properties.SprintCooldownTick > tick() then
        return false;
    end
    npcClass.Properties.SprintCooldownTick = tick() + 6;

    npcClass.Move:SetMoveSpeed(
        "set", 
        "sprint", 
        npcClass.Properties.HardMode and 26 or 22, 
        2, 
        npcClass.Properties.HardMode and 3 or 1.5
    );

    return true;
end

function treePackage.Idle(npcClass: NpcClass)
    return false;
end

return treePackage;