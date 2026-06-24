local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		LifeTime = 10;
        Delta = 1/3;
		Velocity = 25;
		Bounce = 0;
		IgnoreEntities = true;
        Acceleration = Vector3.zero;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
    local part = Instance.new("Part");
    part.Anchored = true;
    part.CanCollide = false;
    if RunService:IsStudio() then
        part.Size = Vector3.one;
        part.Material = Enum.Material.Neon;
        part.Color = Color3.fromRGB(255, 0, 0);
        part.Transparency = 0;

    else
        part.Size = Vector3.new(0, 0, 0);
        part.Transparency = 1;

    end
    
	projectile.Part = part:Clone();

    projectile.ArcTracer.IncludeInstances = {};
end

function projectilePackage.BindFire(projectile: ProjectileInstance)
    local projectilePart = projectile.Part;

    projectile.Properties.StartY = projectilePart.CFrame.Y;

    local whirlwindModel = game.ServerStorage.Prefabs.Objects:WaitForChild("MothWhirlwind"):Clone();
    projectile.Properties.WhirlwindModel = whirlwindModel;

    local whirlwindCFrameTag = Instance.new("CFrameValue");
    whirlwindCFrameTag.Parent = whirlwindModel;
    projectile.Properties.CFrameTag = whirlwindCFrameTag;

    whirlwindCFrameTag:GetPropertyChangedSignal("Value"):Connect(function()
        whirlwindModel:PivotTo(whirlwindCFrameTag.Value);
    end)

    local primaryPart = whirlwindModel:WaitForChild("PrimaryPart");
    modAudio.Play("Whirlwind", primaryPart);

    for _, obj in pairs(whirlwindModel:GetChildren()) do
        if obj.Name ~= "Hitbox" then
            continue;
        end

        obj.Touched:Connect(function(hitPart)
            local playerChars = CollectionService:GetTagged("PlayerCharacters");
            local playerChar = nil;
            for _, char in ipairs(playerChars) do
                if not char:IsAncestorOf(hitPart) then continue end;
                playerChar = char;
                break;
            end
            if playerChar == nil then return end;

            local player: Player = game.Players:GetPlayerFromCharacter(playerChar);
            local playerClass: PlayerClass = player and shared.modPlayers.get(player);

            if playerClass == nil then return end;

            local whirlWindStatus: StatusClassInstance = playerClass.StatusComp:GetOrDefault("MothWhirlwind");
            if whirlWindStatus then return end;

            playerClass.StatusComp:Apply("MothWhirlwind", {
                Expires = workspace:GetServerTimeNow() + 4;
                Duration = 4;

                Values = {
                    WhirlWind = whirlwindModel;
                };
            });
        end)
    end

    projectile.Garbage:Tag(whirlwindModel);
end

function projectilePackage.BindArcStepped(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local projectilePart = projectile.Part;
    if projectilePart == nil then return end;
    
    local whirlwindModel = projectile.Properties.WhirlwindModel;
    local whirlwindCFrameTag = projectile.Properties.CFrameTag;

    local curCFrame = projectilePart.CFrame;
    local startY = projectile.Properties.StartY;

    local rayOrigin = Vector3.new(curCFrame.X, startY, curCFrame.Z);
    local rayDir = -Vector3.yAxis * 64;

    local rayParams = RaycastParams.new();
    rayParams.IncludeInstances = {workspace.Environment; workspace.Terrain};
    
    local rayResult: RaycastResult? = workspace:Spherecast(rayOrigin, 3, rayDir, rayParams);

    -- local dbRay = Debugger:Ray(Ray.new(rayOrigin, rayDir), rayResult and rayResult.Instance, rayResult and rayResult.Position, rayResult and rayResult.Normal);
    -- Debugger.Expire(dbRay, 10);

    local groundPoint = rayResult and rayResult.Position;
    if groundPoint == nil then
        groundPoint = rayOrigin + rayDir;
    end
    groundPoint += Vector3.yAxis * 10;

    local prevGroundPoint = projectile.Properties.GroundPoint;
    if prevGroundPoint == nil then
        whirlwindModel.Parent = workspace.Entities;
        whirlwindCFrameTag.Value = CFrame.new(groundPoint);
    end
    projectile.Properties.GroundPoint = groundPoint;

    TweenService:Create(
        whirlwindCFrameTag, 
        TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
            Value = CFrame.new(groundPoint);
        }
    ):Play();
end

return projectilePackage;