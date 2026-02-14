local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local npcPackage = {
    Name = "Bloater";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 7;
        AttackSpeed = 2;

        MaxHealth = 50;

        BurpCooldown = 7;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 100;
        LockOnExpireDuration = NumberRange.new(1, 3);

        Level = 1;
        ExperiencePool = 35;
        DropRewardId = "bloater";
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "ZombieBasicMeleeAttack";
        "RandomClothing";
        "BodyDestructibles";
        "DizzyCloud";
    };
    AddBehaviorTrees = {
        "ZombieDefaultTree";
    };
};
--==

function npcPackage.LevelSet(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;
    local healthComp: HealthComp = npcClass.HealthComp;

    local level = math.max(properties.Level, 0);

    local lvlMoveSpeed = 10;
    configurations.BaseValues.WalkSpeed = lvlMoveSpeed;
    
    local lvlHealth = 50+math.max(0 + 100*level, 100);
    configurations.BaseValues.MaxHealth = lvlHealth;

    local lvlAttackDamage = 30 + 2*level;
    configurations.BaseValues.AttackDamage = lvlAttackDamage;

    if healthComp.LastDamagedBy == nil then
        healthComp:Reset();
    end
end

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    npcPackage.LevelSet(npcClass);
		

    local sporesModel = npcClass.Character:WaitForChild("Spores");
    local sporesParts = sporesModel:GetChildren();
    
    modTables.Shuffle(sporesParts);
    local pickCount = math.random(8, 12);
    for a=1, #sporesParts do
        if a > pickCount then
            game.Debris:AddItem(sporesParts[a], 0);
            
        else
            local sporePart = sporesParts[a];
            sporePart.Transparency = 0;
            
            if math.random(1, 3) == 1 then
                local newDrip = game.ReplicatedStorage.Particles:WaitForChild("SporeDripEmitter"):Clone();
                newDrip.Rate = math.random(3, 8);
                newDrip.Speed = NumberRange.new(3, 6);
                newDrip.Parent = sporePart.SporeEmitter;
            end
        end
    end


    npcClass.HealthComp.OnIsDeadChanged:Connect(function()
        if not npcClass.HealthComp.IsDead then return end;

        npcClass:GetComponent("DizzyCloud")(math.clamp(properties.Level, 10, 30));
    end)

    npcClass:GetComponent("RandomClothing"){
        Name = npcPackage.Name;
        AddHair = false;
    };
end

function npcPackage.Spawned(npcClass: NpcClass)
    local sporesModel = npcClass.Character:WaitForChild("Spores");

    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");
    local destructible: DestructibleInstance = bodyDestructiblesComp:Create("Spores", sporesModel);
    destructible.HealthComp:SetMaxHealth(math.max(npcClass.HealthComp.MaxHealth*0.1, 50));
    destructible.HealthComp:Reset();

    destructible.OnDestroy:Connect(function()
        local hurtSound = modAudio.Play(`ZombieHurt2`, npcClass.RootPart);
        hurtSound.PlaybackSpeed = math.random(60, 70)/100;
    end)
end

return npcPackage;