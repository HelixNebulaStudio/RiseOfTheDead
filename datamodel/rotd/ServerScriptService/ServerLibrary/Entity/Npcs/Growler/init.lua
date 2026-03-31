local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local npcPackage = {
    Name = "Growler";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 8;
        AttackSpeed = 0.5;

        MaxHealth = 50;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 70;
        LockOnExpireDuration = NumberRange.new(5, 8);

        Level = 1;
        ExperiencePool = 30;
        DropRewardId = "growler";
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "RandomClothing";
        "ZombieBasicMeleeAttack";
        "BodyDestructibles";
        "DynamicLevel";
    };
    AddBehaviorTrees = {
        "ZombieDefaultTree";
    };

    DynamicLevelScaling = {
        WalkSpeed = function(lvl) return math.clamp(15 + math.floor(lvl/10), 1, 30); end;
        MaxHealth = function(lvl) return 49+(math.max(100*lvl, 200)); end;
        AttackDamage = function(lvl) return math.min(10+(lvl/3), 100); end;
    };
};
--==

function npcPackage.Spawning(npcClass: NpcClass)
    local driedFleshModel = npcClass.Character:WaitForChild("DriedNekronFlesh");
    local fleshParts = driedFleshModel:GetChildren();
    
    modTables.Shuffle(fleshParts);
    for a=1, #fleshParts do
        if a > 3 then
            Debugger.Expire(fleshParts[a], 0);
        else
            local part = fleshParts[a];
            part.Transparency = 0;
        end
    end

    npcClass:GetComponent("RandomClothing"){
        AddHair = false;
    };
end

function npcPackage.Respawn(npcClass: NpcClass)
    local character = npcClass.Character;
    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");

    local clawsPrefab = script:WaitForChild("Claws"):GetChildren();
    for _, model in pairs(clawsPrefab) do
        local armPart;
        if model.Name:sub(1,4) == "Left" then
            armPart = character:FindFirstChild("LeftLowerArm");
        else
            armPart = character:FindFirstChild("RightLowerArm");
        end
        if armPart == nil then continue end;

        local shieldAccessory = model:Clone();
        local name = shieldAccessory.Name;
        shieldAccessory.Parent = npcClass.Character;

        local weld = shieldAccessory:WaitForChild("PrimaryPart"):WaitForChild("AccessoryWeld");
        weld.Part1 = armPart;
        weld.Enabled = true;

        local destructible: DestructibleInstance = bodyDestructiblesComp:Create(name, shieldAccessory);
        destructible.DebrisName = name;
        destructible.HealthComp:SetMaxHealth(math.max(npcClass.HealthComp.MaxHealth*0.1, 50));
        destructible.HealthComp:Reset();

        destructible:SetupHealthbar{
            Size = UDim2.new(1.2, 0, 0.25, 0);
            Distance = 32;
            OffsetWorldSpace = Vector3.new(0, 1, 0);
            ShowLabel = false;
        };
        destructible:SetHealthbarEnabled(true);

        destructible.OnDestroy:Connect(function()
            local hurtSound = modAudio.Play(`ZombieHurt2`, npcClass.RootPart);
            hurtSound.PlaybackSpeed = math.random(90, 100)/100;
        end)
    end
end

return npcPackage;