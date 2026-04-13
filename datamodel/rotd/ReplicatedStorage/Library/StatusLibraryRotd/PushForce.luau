local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id = "PushForce";
    Description = "Push force.";
    ShowOnHud = false;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    local velocity = statusClass.Values.Velocity or Vector3.zero;
    local dir = velocity.Unit;
    local speed = velocity.Magnitude;
    statusClass.Values.Dir = dir;
    statusClass.Values.Speed = speed;

    if RunService:IsClient() then
        local modData = shared.require(localPlayer:WaitForChild("DataModule"));
        local modCharacter = modData:GetModCharacter();
        local characterProperties = modCharacter.CharacterProperties;

        local newVel = {
            Velocity = velocity;
            MaxForce = statusClass.Values.MaxForce or Vector3.one*math.huge;
        };
        characterProperties.BodyVelocity:Set(statusClass.Uid, newVel, 5);
        characterProperties.BodyLockToCam = true;

        return 
    end;

    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
	if characterClass == nil or characterClass.ClassName ~= "NpcClass" then return end;

    local bodyVelocity: BodyVelocity = statusClass.Values.BodyVelocity;
    if bodyVelocity == nil then
        bodyVelocity = Instance.new("BodyVelocity");
        bodyVelocity.Name = "PushForce";

        bodyVelocity.Velocity = velocity;
        bodyVelocity.MaxForce = statusClass.Values.MaxForce or Vector3.one*math.huge;

        statusClass.Garbage:Tag(bodyVelocity);
        statusClass.Values.BodyVelocity = bodyVelocity;
    end

    bodyVelocity.Parent = characterClass.RootPart;
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;

    local characterClass: EntityClass = statusClass.StatusOwner :: EntityClass;
    if characterClass == nil or characterClass.ClassName == "Destructible" then return end;

    local rootPart = characterClass.RootPart;

    local dir = statusClass.Values.Dir;
    local speed = statusClass.Values.Speed;

    local rayParams = RaycastParams.new();
    rayParams.IncludeInstances = {workspace.Environment; workspace.Clips; workspace.Terrain;};
    rayParams.IgnoreWater = true;
    rayParams.RespectCanCollide = true;

    local origin = rootPart.Position;
    dir = dir *4;

    local rayResult: RaycastResult = workspace:Spherecast(origin, 1, dir, rayParams);
    if rayResult then
        -- local rPt = Debugger:Ray(Ray.new(origin, dir), rayResult.Instance, rayResult.Position, rayResult.Normal);
        -- game.Debris:AddItem(rPt, 10);
        statusClass.IsExpired = true;
    end
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsClient() then
        local modData = shared.require(localPlayer:WaitForChild("DataModule"));
        local modCharacter = modData:GetModCharacter();
        local characterProperties = modCharacter.CharacterProperties;

        characterProperties.BodyVelocity:Remove(statusClass.Uid);
        characterProperties.BodyLockToCam = false;
        return 
    end;
end

return modStatusClass.new(statusPackage);