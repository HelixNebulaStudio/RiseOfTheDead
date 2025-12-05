local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modRaycastUtil = shared.require(game.ReplicatedStorage.Library.Util.RaycastUtil);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);

local npcPackage = {
    Name = "Witherer";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 32;
        AttackSpeed = 0.5;

        MaxHealth = 100;
        WalkSpeed = 0;
    };
    Properties = {
        IsHostile = true;
        BasicEnemy = true;

        TargetableDistance = 75;
        Detectable = false;

        Level = 1;
        ExperiencePool = 30;
        MoneyReward = NumberRange.new(100, 200);

        KnockbackResistant = 1;
        SkipMoveInit = true;
    };

    AddComponents = {
        "TargetHandler";
        "BodyDestructibles";
    };
    AddBehaviorTrees = {
        "ZombieBossDefaultTree";
    };
    
    ThinkCycle = 1;
};

function npcPackage.onRequire()
    WITHERERS_EYE_PREFAB = script:WaitForChild("withererEye");

	rayParam = RaycastParams.new();
	rayParam.FilterType = Enum.RaycastFilterType.Include;
	rayParam.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};
	rayParam.IgnoreWater = true;
end

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);
    configurations.BaseValues.MaxHealth = math.clamp(1024 + 1024*(level-1), 1024, 102400);

    npcClass.Move:SetMoveSpeed("set", "default", 0);

    properties.EyePrefab = WITHERERS_EYE_PREFAB:Clone();
    npcClass.Garbage:Tag(properties.EyePrefab);
end

function npcPackage.Spawned(npcClass: NpcClass)
    local properties = npcClass.Properties;


    local eye = properties.EyePrefab;
    local eyeBase = eye:WaitForChild("base");
    local eyeBall = eye:WaitForChild("eyeball");
    local eyeAtt = eyeBase:WaitForChild("eyeAttachment");
    local defaultEyeCf = eyeAtt.CFrame;

    local eyeVisible = true;

    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");
    local destructible: DestructibleInstance = bodyDestructiblesComp:Create("Eye", eye);

    destructible:SetupHealthbar{
        Size = UDim2.new(1.2, 0, 0.25, 0);
        Distance = 64;
        ShowLabel = false;
    };

    destructible.HealthComp.OnHealthChanged:Connect(function(newHealth, oldHealth, damageData)
        if newHealth > oldHealth then return end;
        if not eyeVisible then return; end
        
        local damageBy: PlayerClass? = damageData.DamageBy;
        if damageBy == nil or damageBy.ClassName ~= "PlayerClass" then return end;
        if damageBy:DistanceFromCharacter(eyeBase.Position) > 64 then return end;

        destructible:SetEnabled(false);
        destructible:SetHealthbarEnabled(false);

        eyeVisible = false;
        eyeAtt.CFrame = CFrame.identity;
        task.delay(math.random(70, 110)/10, function()
            eyeAtt.CFrame = defaultEyeCf;
            eyeVisible = true;

            destructible:SetEnabled(true);
            destructible:SetHealthbarEnabled(true);
        end)
        
        npcClass.HealthComp:TakeDamage(damageData);
    end)

    --Pick Spawn
    local scanDist = 64;
    local scanPoints = 3;
    local spawnSuccess = false;
    
    for a=1, 10 do
        local dirCf = CFrame.lookAt(Vector3.zero, Vector3.yAxis, Vector3.yAxis);
        dirCf = dirCf*CFrame.Angles(0, 0, math.rad(math.random(0, 360))); -- roll cframe
        local gr = modMath.GaussianRandom()/2.5;
        dirCf = dirCf*CFrame.Angles(math.rad(80*gr), 0, 0); --pitch cframe;

        local dir = dirCf.LookVector;
        local orign = npcClass.RootPart.Position;

        local scanDir = dir*scanDist;
        local rayResult = workspace:Raycast(orign, scanDir, rayParam);

        if rayResult then
            local normal = rayResult.Normal;
            local point = rayResult.Position;

            local pointCf = CFrame.lookAt(point, point + normal) * CFrame.Angles(math.rad(-90), 0, 0);
            local origin = point + (normal*0.1);

            local rayResultList = modRaycastUtil.ConeCast{
                Origin=origin;
                Dir=-normal;
                Points=scanPoints;
                Radius=4;
                RayParam=rayParam;
                OnEachRay=function(origin, dir, rayResult: RaycastResult)
                    if rayResult == nil then
                        return true;
                    end;

                    if rayResult.Instance then
                        local lobbyPrefabs = CollectionService:GetTagged("LobbyPrefab");
                        for a=1, #lobbyPrefabs do
                            if lobbyPrefabs[a]:IsAncestorOf(rayResult.Instance) then
                                return true;
                            end
                        end
                    end

                    local expectedPos = origin + dir;
                    local pos = rayResult.Position;
                    
                    local maxDif = modMath.MaxDiff({pos.X, expectedPos.X}, {pos.Y, expectedPos.Y}, {pos.Z, expectedPos.Z});
                    if maxDif > 1 then
                        return true;
                    end

                    return;
                end;
            };


            if #rayResultList >= scanPoints then
                eye:PivotTo(pointCf);
                eye.Parent = npcClass.Character;
                spawnSuccess = true;
                break;

            else
                Debugger:Warn("Search spawnpoint failed", #rayResultList);

            end

        else
            Debugger:Warn("Search spawnpoint failed", rayResult);

        end
        task.wait(0.33);
    end
    
    if spawnSuccess then
        eyeBall:AddTag("Witherer");
        npcClass.Garbage:Tag(function()
            eyeBall:RemoveTag("Witherer");
        end)
    end

    npcClass.OnThink:Connect(function()
		if not workspace.Entity:IsAncestorOf(properties.EyePrefab) then return end;
        local origin = properties.EyePrefab:GetPivot();
        
        local overlapParam = OverlapParams.new();
        overlapParam.MaxParts = 8;
        overlapParam.FilterType = Enum.RaycastFilterType.Include;
        overlapParam.FilterDescendantsInstances = CollectionService:GetTagged("PlayerRootParts");

        local playerRootParts = workspace:GetPartBoundsInRadius(origin.Position, 64, overlapParam);
        for a=1, #playerRootParts do
            local player = game.Players:FindFirstChild(playerRootParts[a].Parent.Name);
            if player == nil then continue end
            
            modStatusEffects.Withering(player, 30);
        end
    end)
end

return npcPackage;