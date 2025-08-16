local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id = "Dizzy";
    Icon = "rbxassetid://4881193285";
    Name = "Dizzy";
    Description = "Dizzy for $Amount seconds.";
    Buff = false;
    Tags = {"Confusion";};
    Cleansable = true;
    ExpiresOnDeath = true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();
	local modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);

    local gasProtection = false;
    if playerClass then
        gasProtection = playerClass.Configurations.GasProtection ~= nil;
    end

    if modCharacter.StatusBlur == nil then
        modCharacter.StatusBlur = Instance.new("BlurEffect");
        modCharacter.StatusBlur.Name = "StatusBlur";
        modCharacter.StatusBlur.Parent = workspace.CurrentCamera;
    end

    modCharacter.StatusBlur.Size = 30;
    if not gasProtection then
        modCharacter.MouseProperties.MovementNoise = true;
    end
    modCharacter.DizzyZAim = true;

    if statusClass.Values.DizzyType == "bloater" then
        modCameraGraphics.TintColor:Set("bloater", Color3.fromRGB(221, 178, 117), 1);
    end

    local duration = statusClass.Duration;
    if modCharacter.CameraShakeAndZoom then
        modCharacter.CameraShakeAndZoom(5, 0, duration*2, 0, true);
    end

    TweenService:Create(modCharacter.StatusBlur,
        TweenInfo.new(tonumber(duration+0.5), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = 0;}
    ):Play();
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
    local modCharacter = modData:GetModCharacter();
	local modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);

    if statusClass.Values.DizzyType == "bloater" then
        modCameraGraphics.TintColor:Remove("bloater");
    end

    if modCharacter then
        if modCharacter.StatusBlur then
            TweenService:Create(modCharacter.StatusBlur,
                TweenInfo.new(tonumber(0.1), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = 0;}
            ):Play();
        end
        modCharacter.MouseProperties.MovementNoise = false;
        modCharacter.DizzyZAim = false;

        if modCharacter.CameraShakeAndZoom then
            modCharacter.CameraShakeAndZoom(0, 0, 0);
        end
    end
end

return modStatusClass.new(statusPackage);