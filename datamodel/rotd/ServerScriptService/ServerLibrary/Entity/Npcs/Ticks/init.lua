local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local npcPackage = {
    Name = "Ticks";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 5;
        AttackSpeed = 2;

        MaxHealth = 50;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 40;
        LockOnExpireDuration = NumberRange.new(2, 3);

        Level = 1;
        ExperiencePool = 15;
        DropRewardId = "ticks";
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "RandomClothing";
    };
    AddBehaviorTrees = {};
};
--==

function npcPackage.LevelSet(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;
    local healthComp: HealthComp = npcClass.HealthComp;

    local level = math.max(properties.Level, 0);

    local lvlMoveSpeed = 35;
    configurations.BaseValues.WalkSpeed = lvlMoveSpeed;
    
    local lvlHealth = 50+math.max(50*level, 50)-1;
    configurations.BaseValues.MaxHealth = lvlHealth;

    local lvlAttackDamage = 35 + (1*level);
    configurations.BaseValues.AttackDamage = lvlAttackDamage;

    if healthComp.LastDamagedBy == nil then
        healthComp:Reset();
    end
end

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    properties.OnChanged:Connect(function(k, v)
        if npcClass.HealthComp.IsDead then return end;
        if k == "Level" then
            npcPackage.LevelSet(npcClass);
        end
    end)
    npcPackage.LevelSet(npcClass);


    local ticksModel = npcClass.Character:WaitForChild("ExplosiveTickBlobs");
    local tickBlobs = ticksModel:GetChildren();
    
    modTables.Shuffle(tickBlobs);
    for a=1, #tickBlobs do
        if a > 10 then
            game.Debris:AddItem(tickBlobs[a], 0);
            
        else
            tickBlobs[a].Transparency = 0;
            local newSize = math.random(50,350)/1000
            tickBlobs[a].Size = Vector3.new(newSize, newSize);
            
        end
    end
    
    for _, obj in pairs(npcClass.Head:GetChildren()) do
        if obj:IsA("BasePart") and obj.Name == "Blobs" then
            obj.Parent = ticksModel;
        end
    end

    npcClass:GetComponent("RandomClothing")();
end


return npcPackage;