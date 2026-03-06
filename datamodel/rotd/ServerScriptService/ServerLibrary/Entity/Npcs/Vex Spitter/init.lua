local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
local TweenService = game:GetService("TweenService");

local modRaycastUtil = shared.require(game.ReplicatedStorage.Library.Util.RaycastUtil);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);

local npcPackage = {
    Name = "Vex Spitter";
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

        TargetableDistance = 128;

        Level = 1;
        ExperiencePool = 30;
        MoneyReward = NumberRange.new(100, 200);

        KnockbackResistant = 1;
        SkipMoveInit = true;
        SkipNpcAnimatorInit = true;
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
	rayParam = RaycastParams.new();
	rayParam.FilterType = Enum.RaycastFilterType.Include;
	rayParam.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};
	rayParam.IgnoreWater = true;
end

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);
    configurations.BaseValues.MaxHealth = math.clamp(1024 + 1024*(level-1), 1024, 10200);

    local targetObj = npcClass.Character:WaitForChild("TargetPart");
    properties.TargetObj = targetObj;

    properties.ShotCooldown = tick() + 5;

    npcClass.Humanoid.PlatformStand = true;
    npcClass.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false);
    npcClass.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true);
    npcClass.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true);
end

function npcPackage.Spawned(npcClass: NpcClass)
    local properties = npcClass.Properties;

    if properties.SpawnPointSet ~= true then
        npcClass.RootPart.Anchored = true;
        --MARK: Pick Spawn
        local scanDist = 64;
        local scanPoints = 4;

        for a=1, 10 do
            local dirCf = CFrame.lookAt(Vector3.zero, Vector3.yAxis, Vector3.yAxis);
            dirCf = dirCf*CFrame.Angles(0, 0, math.rad(math.random(0, 360))); -- roll cframe
            local gr = modMath.GaussianRandom()/2.5;
            dirCf = dirCf*CFrame.Angles(math.rad(95*gr), 0, 0); --pitch cframe;

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
                    Origin = origin;
                    Dir = -normal;
                    Points = scanPoints;
                    Radius = 4;
                    RayParam = rayParam;
                    OnEachRay = function(origin, dir, rayResult: RaycastResult)
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
                    npcClass.Character:PivotTo(pointCf);
                    break;

                else
                    Debugger:Warn("Search spawnpoint failed", #rayResultList);

                end

            else
                Debugger:Warn("Search spawnpoint failed", rayResult);

            end
            task.wait(0.33);
        end
    end

    for _, motor in ipairs(npcClass.RootPart:GetChildren()) do
        if not motor:IsA("Motor6D") then continue end;

        local dfCf = motor.C0;
        motor:SetAttribute("DefaultC0", dfCf);
        motor.C0 = dfCf * CFrame.new(0, -4, 0);
        TweenService:Create(motor, TweenInfo.new(1), {
            C0 = dfCf;
        }):Play();
    end
    for _, obj in ipairs(npcClass.Character:GetChildren()) do
        if not obj:IsA("BasePart") then continue end;
        if obj.Name == "HumanoidRootPart" then continue end;
        obj.CollisionGroup = "CollisionOff";
        obj.CanQuery = true;
        obj.Transparency = 0;
    end
end

return npcPackage;