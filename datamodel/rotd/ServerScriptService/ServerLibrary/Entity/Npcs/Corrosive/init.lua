local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);

local npcPackage = {
    Name = "Corrosive";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 30;
        AttackRange = 8;
        AttackSpeed = 2.3;

        MaxHealth = 100;
        WalkSpeed = 8;
    };
    Properties = {
        IsHostile = true;

        TargetableDistance = 75;

        Level = 1;
        ExperiencePool = 40;
        MoneyReward = NumberRange.new(15, 20);

        KnockbackResistant = 1;
    };

    AddComponents = {
        "TargetHandler";
        "ZombieBasicMeleeAttack";
        "ThrowTarget";
    };
    AddBehaviorTrees = {
        "ZombieBossDefaultTree";
    };

    TouchHandler = nil;
};

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);

    if properties.HardMode then
        configurations.BaseValues.MaxHealth = math.max(500000 + 10000*level, 100);
        configurations.BaseValues.AttackDamage = 80;
        configurations.BaseValues.WalkSpeed = 12;
    else
        configurations.BaseValues.MaxHealth = math.max(16000 + 3000*level, 100);
        configurations.BaseValues.AttackDamage = 40;
        configurations.BaseValues.WalkSpeed = 8;
    end
end

function npcPackage.Spawned(npcClass: NpcClass)
    local npcChar = npcClass.Character;
    local toxicNormalAtt: Attachment = npcChar.CorrosiveGear.ToxicGoo.ToxicNormal;

    local toxicPuddle = Instance.new("Model");
    toxicPuddle.Name = "ToxicPuddle";
    toxicPuddle.Parent = npcChar;

    local toxicSplashDebounce = tick();
    npcClass.OnThink:Connect(function()
        if tick() < toxicSplashDebounce then return end;
        toxicSplashDebounce = tick() + 0.2;

        local normalDot = Vector3.yAxis:Dot(toxicNormalAtt.WorldCFrame.UpVector);
        if normalDot > 0.99 then return end;

        local dir = toxicNormalAtt.WorldCFrame.UpVector;
        local origin = CFrame.new(toxicNormalAtt.WorldCFrame.Position);
        
        local projectileInstance: ProjectileInstance = modProjectile.fire("toxicpuddle", {
            OriginCFrame = origin;
            SpreadDirection = Vector3.new(0, 1, 0);
        });

        local dirCf = CFrame.lookAlong(origin.Position, dir+Vector3.new(
            math.random(-100, 100)/100, 0, 
            math.random(-100, 100)/100)
        ).LookVector * math.random(0, 1.4);
        
        modProjectile.serverSimulate(projectileInstance, {
            Velocity = dirCf * 40;
            RayWhitelist = {workspace.Environment; workspace.Terrain};
            IgnoreEntities = true;
        });

        local projectilePart = projectileInstance.Part;
        projectilePart.Parent = toxicPuddle;

        local projectilePackage = projectileInstance;
        projectilePackage.TouchHandler:AddObject(projectilePart);
    end)
end

return npcPackage;