
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local statusPackage = {
    Id = "Vex Bile";
    Icon = "rbxassetid://7109208351";
    Name = "Vex Bile";
    Description = "Your vision is blurred by the atmosphere of the bile. You are taking bile damage. Can be nullified by wearing a Gas Mask.";
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

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms1000 ~= true then return end;

    local entityClass: EntityClass = statusClass.StatusOwner;
    local healthComp: HealthComp? = entityClass.HealthComp;
    if healthComp == nil or healthComp.IsDead then return end;

    local damageRatio = (statusClass.Values.DamageRatio or 0.1)/2;

    local configurations = (entityClass :: CharacterClass).Configurations;
    if configurations then
        local conGasMask = configurations.GasMask;
        if conGasMask then
            damageRatio = 0;
        end
    end

    local damage = healthComp.MaxHealth * damageRatio;
    if damage <= 0 then return end;
    
    local dmgData = DamageData.new{
        Damage = damage;
        DamageType = "IgnoreArmor";
    };
    healthComp:TakeDamage(dmgData);

    modAudio.Play("BurnTick"..math.random(1, 3), entityClass.RootPart).PlaybackSpeed = math.random(50,70)/100;
end

return modStatusClass.new(statusPackage);