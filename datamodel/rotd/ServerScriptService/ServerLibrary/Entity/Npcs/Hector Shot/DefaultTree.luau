local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modAoeHighlight = shared.require(game.ReplicatedStorage.Particles.AoeHighlight);

local treePackage = {
    LogicString = {
        SearchTree = "HasEnemy & IsSearchState & [Search]";
        HuntTree = "HasEnemy & IsHuntState & [Hunt]";
        LassoTree = "HasEnemy & IsLassoState & [Lasso]";
        KillTree = "HasEnemy & IsKillState & [Kill]";
        Default = "SearchTree | HuntTree | LassoTree | KillTree";
    };
};

function treePackage.HasEnemy(npcClass: NpcClass)
    local hasEnemy = npcClass.BehaviorTree:RunTree("HasEnemy", false);

    local properties = npcClass.Properties;
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;

    if enemyTargetData then
        local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

        local visionTarget = enemyNpcClass.Head;
        if enemyNpcClass.Properties.IsCrouching then
            visionTarget = enemyNpcClass.RootPart;
        end

        local huntTarget = false;
        
        if npcClass.HealthComp.LastDamagedBy and npcClass.HealthComp.LastDamageTaken+3 > workspace:GetServerTimeNow() then
            huntTarget = true;
        else
            local isInVision, opacity = npcClass:IsInVision(visionTarget, 89);
            if isInVision and opacity > 0.3 then
                huntTarget = true;
            end
        end

        if huntTarget == true then
            npcClass.Move:Face(visionTarget);

            if properties.State == "Search" then
                properties.State = "Hunt";
                properties.StateChangedTick = tick();

                npcClass.Chat(nil, npcClass.NpcPackage.HuntInitSpeech[math.random(1, #npcClass.NpcPackage.HuntInitSpeech)]);
            end
        end
    end

    if properties.State == "Search" then
        npcClass.Move:SetMoveSpeed("set", "walk", 8, npcClass.Move.MoveSpeedPriority.Movement);
    else
        npcClass.Move:SetMoveSpeed("remove", "walk");
    end

    return enemyTargetData ~= nil;
end


--MARK: SearchTree
function treePackage.IsSearchState(npcClass: NpcClass)
    return npcClass.Properties.State == "Search";
end

function treePackage.Search(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    if properties.SearchPoint == nil or tick() > properties.SearchResetTick then
        properties.SearchResetTick = tick()+6;

        properties.SearchPoint = enemyNpcClass:GetCFrame().Position;
        npcClass.Move:MoveTo(properties.SearchPoint);
    end

    if npcClass.Move:IsAtPosition(properties.SearchPoint) then
        npcClass.PlayAnimation("Idle");
    end

    if npcClass.WieldComp.ItemId ~= "lasso" then
        npcClass.WieldComp:Equip({
            ItemId = "lasso";
        });
    else
        npcClass.WieldComp:InvokeToolAction("ActionEvent", {IsActive = false;});
    end

    return true;
end


--MARK: HuntTree
function treePackage.IsHuntState(npcClass: NpcClass)
    return npcClass.Properties.State == "Hunt";
end

function treePackage.Hunt(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:Follow(enemyNpcClass.RootPart);

    if npcClass.WieldComp.ItemId == "lasso" then
        npcClass.WieldComp:InvokeToolAction("ActionEvent", {IsActive = true;});
    end

    if enemyTargetData.Distance <= 8 or tick()-properties.StateChangedTick >= 6 then
        if properties.State == "Hunt" then
            properties.State = "Lasso";
            properties.StateChangedTick = tick();

            npcClass.Chat(nil, npcClass.NpcPackage.LassoInitSpeech[math.random(1, #npcClass.NpcPackage.LassoInitSpeech)]);
        end
    end
end


--MARK: LassoTree
function treePackage.IsLassoState(npcClass: NpcClass)
    return npcClass.Properties.State == "Lasso";
end

function treePackage.Lasso(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if properties.LassoingTick and tick() <= properties.LassoingTick then return; end;

    properties.LassoingTick = tick()+10;

    local isHard = properties.HardMode;
    local lassoGracePeriod = isHard and 1 or 2.2;
    local lassoRadius = isHard and 50 or 45;

    npcClass.Move:SetMoveSpeed("set", "lassostop", 0, 9, lassoGracePeriod);
    npcClass.Move:Stop();

    local rangeIndicator = modAoeHighlight.newSphere(lassoGracePeriod);
    rangeIndicator.Parent = workspace.Debris;
    task.spawn(function()
        while workspace.Debris:IsAncestorOf(rangeIndicator) do
            rangeIndicator.Position = npcClass.RootPart.Position;
            task.wait();
        end
    end)

    TweenService:Create(
        rangeIndicator,  
        TweenInfo.new(lassoGracePeriod), 
        {
            Size=(Vector3.one * lassoRadius*2)
        }
    ):Play();

    task.wait(lassoGracePeriod);
    if npcClass.HealthComp.IsDead then return end;

    local targetsList = npcClass:GetComponent("TargetHandler"):MatchTargets(function(targetData: NpcTargetData)
        if targetData.HealthComp == nil or targetData.HealthComp.IsDead then return end;
        local characterClass: CharacterClass = targetData.HealthComp.CompOwner;

        if characterClass.ClassName == "NpcClass" then return false end;

        if characterClass.ClassName == "PlayerClass" then
            local player: Player = (characterClass :: PlayerClass):GetInstance();

            if npcClass.NetworkOwners then
                local isNetOwner = table.find(npcClass.NetworkOwners, player) ~= nil;
                if not isNetOwner then return false; end
            end
        end

        if targetData.Distance > lassoRadius-4 then return false end;
        return true;
    end)

    local tiedUpPlayers = {};
    for a=1, #targetsList do
        local targetData: NpcTargetData = targetsList[a];
        local characterClass: CharacterClass = targetData.HealthComp.CompOwner;

        if characterClass.ClassName == "PlayerClass" then
            local player: Player = (characterClass :: PlayerClass):GetInstance();
            modStatusEffects.TiedUp(player, 5);

            table.insert(tiedUpPlayers, characterClass);
        end
    end
    properties.TiedUpPlayers = tiedUpPlayers;

    if #tiedUpPlayers > 0 and npcClass.Properties.State == "Lasso" then
        npcClass.Properties.State = "Kill";
        properties.StateChangedTick = tick();

        npcClass.WieldComp:Equip({
            ItemId = "revolver454";
            OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
                local equipmentClass: EquipmentClass? = toolHandler.EquipmentClass;
                if equipmentClass == nil then return end;

                equipmentClass.Properties.InfiniteAmmo = 1;

                local modifier = equipmentClass.Configurations.newModifier("BanditGun");
                modifier.SetValues.Damage = isHard and 95 or 65;
                modifier.SetValues.Rpm = 999;
                modifier.SetValues.NpcPercentHealthDamage = 0.6;
                equipmentClass.Configurations:AddModifier(modifier, true);
            end
        });
        npcClass.Chat(nil, npcClass.NpcPackage.LassoedSpeech[math.random(1, #npcClass.NpcPackage.LassoedSpeech)]);

    else
        task.wait(1);

        if npcClass.HealthComp.IsDead then return end;
        npcClass.Properties.State = "Search";
        properties.StateChangedTick = tick();
    end
end

--MARK: KillTree
function treePackage.IsKillState(npcClass: NpcClass)
    return npcClass.Properties.State == "Kill";
end

function treePackage.Kill(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local tiedUpPlayers: {CharacterClass} = properties.TiedUpPlayers;
    local equipmentClass: EquipmentClass? = npcClass.WieldComp.EquipmentClass;

    if tick()-properties.StateChangedTick <= 0.5 then return end;
    if properties.KillTick and tick() <= properties.KillTick then return; end;
    properties.KillTick = tick() + 1 + (0.2*#tiedUpPlayers);

    if equipmentClass and tiedUpPlayers and #tiedUpPlayers > 0 and equipmentClass.Properties.Ammo > 0 then
        for a=#tiedUpPlayers, 1, -1 do
            local characterClass: CharacterClass? = table.remove(tiedUpPlayers, a);
            if characterClass == nil then continue end;

            local statusComp: StatusComp = characterClass.StatusComp;

            if equipmentClass.Properties.Ammo <= 0 then continue end;
            if characterClass.HealthComp.IsDead then continue; end

            local tiedUpStatus: StatusClassInstance = statusComp:GetOrDefault("TiedUp");
            if tiedUpStatus == nil then continue; end

            if equipmentClass.Class == "Gun" then
                npcClass.WieldComp:InvokeToolAction("PrimaryFireRequest", nil, characterClass.Humanoid);

            elseif equipmentClass.Class == "Melee" then
                npcClass.WieldComp:InvokeToolAction("PrimarySwingRequest");
                
            end

            task.wait(0.2);
        end

    else
        table.clear(properties.TiedUpPlayers);

        npcClass.Properties.State = "Search";
        properties.StateChangedTick = tick();

    end
end

return treePackage;