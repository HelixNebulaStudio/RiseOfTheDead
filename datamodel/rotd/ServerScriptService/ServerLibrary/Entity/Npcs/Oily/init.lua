local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);

local modFlammable = shared.require(game.ServerScriptService.ServerLibrary.Flammable);

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
        ExperiencePool = 20;
        DropRewardId = "zombie";
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "RandomClothing";
        "BodyLayer";
        "ZombieBasicMeleeAttack";
    };
    AddBehaviorTrees = {
        "ZombieDefaultTree";
    };
};

function npcPackage.LevelSet(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;
    local healthComp: HealthComp = npcClass.HealthComp;

    local level = math.max(properties.Level, 0);

    configurations.BaseValues.WalkSpeed = 12;
    
    local lvlHealth = math.clamp(100 + 20*level, 100, 102400);
    configurations.BaseValues.MaxHealth = lvlHealth;

    local lvlAttackDamage = 10 + 3*level;
    configurations.BaseValues.AttackDamage = lvlAttackDamage;

    if healthComp.LastDamagedBy == nil then
        healthComp:SetMaxHealth(configurations.MaxHealth);
        healthComp:Reset();
    end
end

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    npcPackage.LevelSet(npcClass);
    npcClass:GetComponent("BodyLayer"):AddLayer("Zombie");

    npcClass.OnThink:Connect(function()
        npcClass.BehaviorTree:RunTree("ZombieDefaultTree", true);
    end);

    npcClass:GetComponent("RandomClothing")();

    local oilGrid = {};
    local lastOilProjObj;
    local dripOilTick = tick();
    npcClass.Garbage:Tag(function() 
        table.clear(oilGrid);
        if lastOilProjObj then
            lastOilProjObj:Destroy();
            lastOilProjObj = nil;
        end
    end);

    npcClass.OnThink:Connect(function()
        if tick() < dripOilTick then return end;
        dripOilTick = tick() + 1;

        local origin = npcClass.RootPart.CFrame;

        local gridKey = `{math.round(origin.X/4)*4};{math.round(origin.Y/8)*8};{math.round(origin.Z/4)*4}`;
        if oilGrid[gridKey] and tick()-oilGrid[gridKey] <= 10 then return end;
        oilGrid[gridKey] = tick();


        local projectileInstance: ProjectileInstance = modProjectile.fire("gasoline", {
            CharacterClass = npcClass;
            OriginCFrame = origin;
            SpreadDirection = Vector3.new(0, -1, 0);
        });
        projectileInstance.Part.Color = Color3.fromRGB(103, 0, 62);
        projectileInstance.Part.Transparency = 0;
        lastOilProjObj = projectileInstance.Part;

        local spreadLookVec = modMath.CFrameSpread(-Vector3.yAxis, 90);
        modProjectile.serverSimulate(projectileInstance, {
            Velocity = spreadLookVec * 20;
            RayWhitelist = {workspace.Environment; workspace.Terrain};
            IgnoreEntities = true;
        });

        if properties.Ignited then
            modFlammable:Ignite(projectileInstance.Part);
        end
    end);

    npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
        if not isDead then return end;

		if lastOilProjObj then
			if lastOilProjObj:HasTag("Flammable") then
				modFlammable:Ignite(lastOilProjObj);
			end
		end
    end)


    local oilyModifier = npcClass.Configurations.newModifier("Oily");
    function oilyModifier.Binds.CharacterClassTakenDamage(modifier, damageData)
        if damageData.DamageType == "Fire" then return end;
        if properties.Ignited == true then return end;
        properties.Ignited = true;

        for _, obj in pairs(npcClass.Character:GetChildren()) do
			if obj:GetAttribute("BodyLayer") ~= true then continue end;
			if obj:FindFirstChild("Fire") then continue end;

			local newFire = Instance.new("Fire");
			newFire.Parent = obj;
		end
    end
    npcClass.Configurations:AddModifier(oilyModifier, false);
    oilyModifier:SetEnabled(true);

end

return npcPackage;