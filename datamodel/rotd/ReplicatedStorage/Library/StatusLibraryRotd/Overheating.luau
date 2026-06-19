local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local localPlayer = game.Players.LocalPlayer;

local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

--==
local statusPackage = {
    Id = "Overheating";
    Icon = "rbxassetid://135144625609559";
    Name = "Overheating";
    Description = "You are overheating, moving too fast will blur your vision and affect your aim.";
    Buff = false;
    Tags = {};
    Cleansable = true;
    ExpiresOnDeath = true;
};

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    modCharacter.DizzyZAim = false;
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsServer() then return end;
    if tickData.ms100 == false then return end;

    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    local rootPart = characterClass.RootPart;
    local rpALV = rootPart.AssemblyLinearVelocity;

    local moveMagSqrd = modVector.MagnitudeSqrd(Vector3.new(rpALV.X, 0, rpALV.Z));
    local rollingMovementMag = statusClass.Values.RMM or 0;
    if moveMagSqrd >= 4096 then
        rollingMovementMag += 64;
    elseif moveMagSqrd >= 1024 then
        rollingMovementMag += 32;
    elseif moveMagSqrd >= 256 then
        rollingMovementMag += 16;
    end
    rollingMovementMag /= 2;
    statusClass.Values.RMM = rollingMovementMag;

    local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();

    if modCharacter.StatusBlur == nil then
        modCharacter.StatusBlur = Instance.new("BlurEffect");
        modCharacter.StatusBlur.Name = "StatusBlur";
        modCharacter.StatusBlur.Parent = workspace.CurrentCamera;
        statusClass.Garbage:Tag(function()
            modCharacter.StatusBlur:Destroy();
            modCharacter.StatusBlur = nil
        end)
    end

    if rollingMovementMag >= 50 then
        TweenService:Create(modCharacter.StatusBlur,
            TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = 40;}
        ):Play();
        modCharacter.DizzyZAim = true; 
        if modCharacter.CameraShakeAndZoom then
            modCharacter.CameraShakeAndZoom(5, 0, 4, 0, true);
        end

    elseif rollingMovementMag >= 30 then
        TweenService:Create(modCharacter.StatusBlur,
            TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = 20;}
        ):Play();
        modCharacter.DizzyZAim = true;
        if modCharacter.CameraShakeAndZoom then
            modCharacter.CameraShakeAndZoom(5, 0, 3, 0, true);
        end

    elseif rollingMovementMag >= 16 then
        TweenService:Create(modCharacter.StatusBlur,
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = 10;}
        ):Play();
        modCharacter.DizzyZAim = true;
        if modCharacter.CameraShakeAndZoom then
            modCharacter.CameraShakeAndZoom(5, 0, 1, 0, true);
        end

    else
        TweenService:Create(modCharacter.StatusBlur,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = 2;}
        ):Play();
        modCharacter.DizzyZAim = false;

    end
end

return modStatusClass.new(statusPackage);