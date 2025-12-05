local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modNekronSpore = shared.require(script.Parent:WaitForChild("NekronSpore"));
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local treePackage = {
    LogicString = {
        PlantSporeTree = "HasEnemy & CanPlantSpore & [PlantSpore]";
        Default = "PlantSporeTree";
    };
};
--==

function treePackage.onRequire()
    rayParam = RaycastParams.new();
    rayParam.FilterType = Enum.RaycastFilterType.Include;
    rayParam.IgnoreWater = true;
    rayParam.CollisionGroup = "Raycast";
    rayParam.FilterDescendantsInstances = {workspace.Environment:FindFirstChild("Scene");};
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local hasEnemy = npcClass.BehaviorTree:RunTree("HasEnemy", false);
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;

    return enemyTargetData ~= nil;
end

function treePackage.CanPlantSpore(npcClass: NpcClass)
    local properties = npcClass.Properties;

    if properties.PlantCooldown and tick() < properties.PlantCooldown then return false; end;
    return true;    
end

function treePackage.PlantSpore(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    local isHard = properties.HardMode;

    properties.PlantCooldown = tick() + math.random(2, 4);

    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");

    local targetPart = enemyNpcClass.RootPart;
    local targetPoint = enemyNpcClass:GetCFrame().Position;

    local raycastResult;
    
    local attackDirection = (tick()-properties.LastVeinSpawn) < 5 and -1 or 1;
    
    for a=1, 16 do
        local aimPoint = CFrame.new(targetPoint) 
            * CFrame.Angles(0, math.rad(math.random(1, 360)), 0)
            * CFrame.Angles(math.rad(attackDirection * math.random(30, 50)), 0, 0) 
            * CFrame.new(0, 0, 1024);
        
        local aimDir = (aimPoint.p-targetPoint).Unit;
        raycastResult = workspace:Raycast(targetPoint, aimDir*256, rayParam);
        
        task.wait();
        if raycastResult then
            break;
        end
    end
    
    local incubateTime = math.clamp(5 - (tick()-npcClass.SpawnTime)/60, isHard and 2 or 3, 5);
    
    if raycastResult then
        local hitPart = raycastResult.Instance;
        local attackOrigin = raycastResult.Position;
        
        properties.LastVeinSpawn = tick();
        properties.Spread(hitPart);
        properties.SporeCount = properties.SporeCount +1;

        local sporeCount = properties.SporeCount;

        local sporeModel = Instance.new("Model");
        sporeModel.Name = `NekrosSpore{sporeCount}`;
        sporeModel.Parent = properties.VeinModel;
        Debugger.Expire(sporeModel, 30);

        local sporeDestructible: DestructibleInstance = bodyDestructiblesComp:Create(sporeModel.Name, sporeModel);
        sporeDestructible.Properties.DestroyModel = false;
        
        local nekronSporeObject = modNekronSpore.spawn(attackOrigin, targetPart, {
            SporeDestructible = sporeDestructible;
            IncubationTime = incubateTime;
            NekronSpreadFunc = properties.Spread;
            HostNpcClass = npcClass;
        })
        table.insert(properties.SporeObjects, nekronSporeObject);
        
        local sporePart = sporeModel.PrimaryPart;
        
        local sporeMaxHealth = npcClass.Configurations.BaseValues.BaseHealth *0.1;
        sporeDestructible.HealthComp:SetMaxHealth(sporeMaxHealth);
        sporeDestructible.HealthComp:Reset();

        sporeDestructible:SetupHealthbar{
            Size = UDim2.new(1.2, 0, 0.25, 0);
            Distance = 128;
            OffsetWorldSpace = Vector3.new(0, 1, 0);
            ShowLabel = false;
        };
        sporeDestructible:SetHealthbarEnabled(true);
        
        sporeDestructible.OnDestroy:Connect(function(damageData)
            nekronSporeObject.Cancelled = true;
            nekronSporeObject:Destroy();

            game.Debris:AddItem(sporeModel, 2);
            sporePart.Color = Color3.fromRGB(48, 30, 30);
            modAudio.Play("TicksZombieExplode", sporePart).PlaybackSpeed = math.random(50, 60)/100;

            if damageData == nil then return end;
            npcClass.HealthComp:TakeDamage(DamageData.new{
                Damage = sporeMaxHealth * 2;
                TargetPart = sporePart;
            });
        end)
    end
end

return treePackage;