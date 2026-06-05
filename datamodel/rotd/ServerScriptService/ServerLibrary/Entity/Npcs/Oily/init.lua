local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);

local modOilyOil = shared.require(game.ReplicatedStorage.Library.Projectile.oilyoil);

local FIRE_COLOR = Color3.fromRGB(103, 0, 62);
local npcPackage = {
    Name = "Oily";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 5;
        AttackSpeed = 2;

        MaxHealth = 50;
    };
    
    Properties = {
        PositionOctrees = {"Zombie"};
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 50;

        Level = 1;
        BaseExperience = 20;
        DropRewardId = "zombie";
        ThornResist = 1;

        Immunity = 1;
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "RandomClothing";
        "BodyLayer";
        "ZombieBasicMeleeAttack";
        "DynamicLevel";
    };
    AddBehaviorTrees = {
        "ZombieDefaultTree";
    };
    
    DynamicLevelScaling = {
        WalkSpeed = 12;
        MaxHealth = function(lvl) return 99+(math.max(20*lvl, 100)); end;
        AttackDamage = function(lvl) return math.min(10+(lvl*3), 100); end;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<anydict> = npcClass.Properties;

    npcClass:GetComponent("BodyLayer"):AddLayer("Zombie");

    npcClass.OnThink:Connect(function()
        npcClass.BehaviorTree:RunTree("ZombieDefaultTree", true);
    end);

    npcClass:GetComponent("RandomClothing")();

    local oilGrid = {};
    local lastOilProj;
    local dripOilTick = tick();
    npcClass.Garbage:Tag(function() 
        table.clear(oilGrid);
        task.wait(0.1);
        if lastOilProj then
            lastOilProj = nil;
        end
    end);

    npcClass.OnThink:Connect(function()
        if tick() < dripOilTick then return end;
        dripOilTick = tick() + 1;

        local origin = npcClass.RootPart.CFrame;

        if properties.Ignited then 
            task.spawn(function()
                local ray = Ray.new(npcClass:GetCFrame().Position, -Vector3.yAxis*5);
                local rayParams = RaycastParams.new();
                rayParams.IncludeInstances = {workspace.Environment};
                
                local rayResult = workspace:Spherecast(ray.Origin, 2, ray.Direction, rayParams);
                local hitPart = rayResult and rayResult.Instance;
                
                if hitPart.Name == "oilyoil" then
                    local projectile = modOilyOil.GetProjectileFromPart(hitPart);
                    modOilyOil.Ignite(projectile);
                end
            end)    
        end;

        local gridKey = `{math.round(origin.X/4)*4};{math.round(origin.Y/8)*8};{math.round(origin.Z/4)*4}`;
        if oilGrid[gridKey] and tick()-oilGrid[gridKey] <= 10 then return end;
        oilGrid[gridKey] = tick();

        local projectileInstance: ProjectileInstance = modProjectile.fire("oilyoil", {
            CharacterClass = npcClass;
            OriginCFrame = origin;
            SpreadDirection = Vector3.new(0, -1, 0);
        });
        local projectilePart = projectileInstance.Part;

        projectilePart.Color = FIRE_COLOR;
        projectilePart.Transparency = 0;
        lastOilProj = projectileInstance;

        local spreadLookVec = modMath.CFrameSpread(-Vector3.yAxis, 90);
        modProjectile.serverSimulate(projectileInstance, {
            Velocity = spreadLookVec * 20;
            IgnoreEntities = true;
        });

        if #npcClass.StatusComp:ListStatusWithTags{"Fire"} > 0 or properties.Ignited then
            modOilyOil.Ignite(projectileInstance);
        end
    end);

    npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
        if not isDead then return end;

		if lastOilProj then
            modOilyOil.Ignite(lastOilProj);
		end
    end)


    local oilyModifier = npcClass.Configurations.newModifier("Oily");
    function oilyModifier.Binds.CharacterClassTakenDamage(modifier, damageData)
        if damageData.DamageType == "Fire" then return end;
        if properties.Ignited == true then return end;
        properties.Ignited = true;
        properties.Immunity = nil;

        for _, obj in pairs(npcClass.Character:GetChildren()) do
			if obj:GetAttribute("BodyLayer") ~= true then continue end;
			if obj:FindFirstChild("Fire") then continue end;
            if math.random(1, 3) == 1 then continue end;

			local newFire = Instance.new("Fire");
            newFire.Color = FIRE_COLOR;
			newFire.Parent = obj;
		end
    end
    npcClass.Configurations:AddModifier(oilyModifier, false);
    oilyModifier:SetEnabled(true);

end

return npcPackage;