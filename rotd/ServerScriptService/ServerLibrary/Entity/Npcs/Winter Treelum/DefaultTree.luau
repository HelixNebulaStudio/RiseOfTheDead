local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);

local treePackage = {
    LogicString = {
        SpikeRootsTree = "HasEnemy & CanSpikeRoots & [SpikeRoots]";
        Default = "SpikeRootsTree | ZombieBossDefaultTree";
    };
};

function treePackage.ZombieBossDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ZombieBossDefaultTree", false);
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData ~= nil;
end

--MARK: Spike Roots
function treePackage.CanSpikeRoots(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local configurations = npcClass.Configurations;

    if tick() - properties.LastSpikeRootsTick <= 10 then
        return false;
    end

    return true;
end

function treePackage.SpikeRoots(npcClass: NpcClass)

    local traceTime = 5;

    local validPlayerClasses: {PlayerClass} = {};

    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    targetHandlerComp:MatchTargets(function(targetData: NpcTargetData)
        local healthComp = targetData.HealthComp;
        if healthComp == nil or healthComp.IsDead then return end;

        local playerClass: PlayerClass = healthComp.CompOwner :: PlayerClass;
        if playerClass.ClassName ~= "PlayerClass" then return end;

        table.insert(validPlayerClasses, playerClass);
    end)

    local spikeGrid = {};
    for a=1, #validPlayerClasses do
        local playerClass: PlayerClass = validPlayerClasses[a];
        local playerHumanoid = playerClass.Humanoid;

        task.spawn(function()
            local traceTimer = tick();
            local lastPosition = npcClass.RootPart.Position;

            repeat
                if playerHumanoid.FloorMaterial ~= Enum.Material.Air 
                and playerHumanoid.FloorMaterial ~= Enum.Material.Water then
                    local playerRootPart = playerClass.RootPart;
                    local distChange = (lastPosition - playerRootPart.Position).Magnitude;
                    
                    if distChange >= 6 then
                        local dropRayHit, dropRayPos = workspace:FindPartOnRayWithWhitelist(
                            Ray.new(playerRootPart.Position, Vector3.new(0, -64, 0)), 
                            {workspace.Environment; workspace.Terrain}, true);

                        lastPosition = playerRootPart.Position;
                        
                        local gridKey = `{math.round(dropRayPos.X/4)*4};{math.round(dropRayPos.Y/8)*8};{math.round(dropRayPos.Z/4)*4}`;
                        spikeGrid[gridKey] = dropRayPos;
                    end
                end
                task.wait(0.5);
                if npcClass.HealthComp.IsDead then break end;
            until tick()-traceTimer >= traceTime;
        end)
    end

    task.wait(traceTime);
    if npcClass.HealthComp.IsDead then return end;

    npcClass.Move:SetMoveSpeed("set", "spike", 0, npcClass.Move.MoveSpeedPriority.Action, 10);
    npcClass.PlayAnimation("Shake");

    task.wait(1);
    if npcClass.HealthComp.IsDead then return end;

    local npcPackageScr = npcClass.NpcPackage.Script;
    for _, spawnPosition in pairs(spikeGrid) do
        local newRoot = npcPackageScr.SpikeRoots:Clone();

        newRoot.CFrame = CFrame.new(spawnPosition) * CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
        task.spawn(function()
            for a=1, 3 do
                task.wait(0.05);
                newRoot.CFrame = CFrame.new(spawnPosition) * CFrame.new(0, 0.5*a, 0) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
            end
        end)
        newRoot.Parent = workspace.Debris;
        game.Debris:AddItem(newRoot, 30);

        modAudio.Play("ShovelDig", newRoot).PlaybackSpeed = 6;

        local touchHandler = modTouchHandler.get("BarbClips")
        if touchHandler then
            touchHandler:AddObject(newRoot);
        end
        
        task.wait(0.25);
    end
    
    npcClass.StopAnimation("Shake");
    task.wait(1);
    if npcClass.HealthComp.IsDead then return end;

    npcClass.Move:SetMoveSpeed("remove", "spike");
end

return treePackage;