local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local treePackage = {
    LogicString = {
        FumesCloudTree = "HasEnemy & FumesCloud";
        Default = "FumesCloudTree | ZombieBossDefaultTree";
    };
};

function treePackage.ZombieBossDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ZombieBossDefaultTree", false);
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData ~= nil;
end



--MARK: FumesCloudTree
function treePackage.FumesCloud(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData: NpcTargetData = properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    local fumesCloud = game.ServerStorage.Prefabs.Objects:WaitForChild("fumesCloud");
    local isHard = properties.HardMode;

    if properties.CloudState == 0 then
        if enemyTargetData.Distance > 100 then return false; end;
        properties.CloudState = 1;

        properties.Immunity = 0;

        npcClass.Move:Stop();
        npcClass.Move:Face(enemyNpcClass.RootPart);

        local newFumeCloud: MeshPart = fumesCloud:Clone();
        local offsetCFrame = CFrame.new(math.random(-16, 16), 0, math.random(-16, 16));
        newFumeCloud.CFrame = CFrame.new(npcClass.RootPart.CFrame.Position) * offsetCFrame;
        properties.FumesCloudPoint = newFumeCloud.CFrame.Position;

        local fumesCloudSize = properties.FumesCloudSize;

        if isHard then
            newFumeCloud.Size = Vector3.new(fumesCloudSize, fumesCloudSize, fumesCloudSize);
            newFumeCloud:SetAttribute("GasDamage", 40);

            task.spawn(function()
                task.wait(3);
                while npcClass.HealthComp.IsDead ~= true do
                    local delta = game:GetService("RunService").Heartbeat:Wait();
                    if not workspace:IsAncestorOf(newFumeCloud) then break end;

                    local tarPos = enemyNpcClass.RootPart.Position;
                    local directionBias = (tarPos-npcClass:GetCFrame().Position).Unit or Vector3.zero;
                    properties.FumesCloudPoint = properties.FumesCloudPoint + directionBias * 2 * delta;
                    newFumeCloud.Position = newFumeCloud.Position:Lerp(properties.FumesCloudPoint, 0.1);
                end
            end)

        else
            newFumeCloud.Size = Vector3.new(fumesCloudSize, fumesCloudSize, fumesCloudSize);
            newFumeCloud:SetAttribute("GasDamage", 6);

        end

        newFumeCloud.Parent = workspace.Entities;
        npcClass.Garbage:Tag(newFumeCloud);

        npcClass.PlayAnimation("ChannelFumes");

    elseif properties.CloudState == 1 then
        local cancelChanneling = false;
        if enemyTargetData.Distance > 180 then
            cancelChanneling = true;
        end

        if cancelChanneling == true then
            properties.CloudState = 0;

            npcClass.Garbage:Loop(function(a, trash)
                if typeof(trash) == "Instance" and trash.Name == "fumesCloud" then
                    game.Debris:AddItem(trash, 0);
                end
            end)

            npcClass.StopAnimation("ChannelFumes");
            properties.Immunity = 2;
        end

        if isHard then
            local distFromCloud = npcClass:DistanceFromCharacter(properties.FumesCloudPoint);

            if tick() > properties.WanderTick or distFromCloud > 45 then
                properties.WanderTick = tick()+math.random(50,100)/10;

                npcClass.StopAnimation("ChannelFumes");
                npcClass.Move:MoveTo(properties.FumesCloudPoint + Vector3.new(math.random(-35, 35), 0, math.random(-35, 35)));

                return false;
            end
        end

        if npcClass.Move.IsMoving == false then
            npcClass.PlayAnimation("ChannelFumes", 0.5);
            npcClass.Move:Face(enemyNpcClass.RootPart);
        end
    end

    return true;
end


return treePackage;