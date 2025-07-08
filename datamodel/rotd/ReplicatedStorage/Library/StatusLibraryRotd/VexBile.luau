local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local RunService = game:GetService("RunService");
--==
local statusPackage = {
    Id = "Vex Bile";
    Icon = "rbxassetid://10368377851";
    Name = "Vex Bile";
    Description = "Your vision is blurred by the atmosphere of the bile.";
    Buff = false;
    ExpiresOnDeath = true;
};

function statusPackage.onRequire()
    if RunService:IsClient() then
	    modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);
    end
end

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;
    
    local modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule")); 
    local modCharacter = modData:GetModCharacter();

    if modCharacter.StatusBlur == nil then
        modCharacter.StatusBlur = Instance.new("BlurEffect");
        modCharacter.StatusBlur.Name = "StatusBlur";
        modCharacter.StatusBlur.Parent = workspace.CurrentCamera;
    end

    modCharacter.StatusBlur.Size = 10;

    local duration = statusClass.Duration;

    modCameraGraphics.TintColor:Set("vexbile", Color3.fromRGB(255, 136, 96), 1);
    modCameraGraphics:SetAtmosphere(
        script.VexBileAtmosphere, 
        "vexbile", 
        modCameraGraphics.EffectsPriority.Environment, 
        duration+0.5
    );
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    modCameraGraphics.TintColor:Remove("vexbile");

    local modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule")); 
    local modCharacter = modData:GetModCharacter();
    if modCharacter then
        if modCharacter.StatusBlur then
            modCharacter.StatusBlur.Size = 0;
        end
        modCharacter.MouseProperties.MovementNoise = false;
        modCharacter.DizzyZAim = false;
    end
end

return modStatusClass.new(statusPackage);