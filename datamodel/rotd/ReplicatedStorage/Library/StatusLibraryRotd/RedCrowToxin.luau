local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local RunService = game:GetService("RunService");

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
--==
local statusPackage = {
    Id = "RedCrowToxin";
    Icon = "";
    Name = "Red Crow Toxin";
    Description = ".";
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

    local duration = statusClass.Duration;

    modCameraGraphics.TintColor:Set("redcrow", Color3.fromRGB(92, 31, 10), 1);
    modCameraGraphics:SetAtmosphere(
        script:WaitForChild("RedCrowAtmosphere"), 
        "redcrow", 
        modCameraGraphics.EffectsPriority.Environment, 
        duration+0.5
    );
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms100 == false then return end;

    local characterClass: CharacterClass = statusClass.StatusOwner;
    
    local cf = characterClass:GetCFrame();
    if cf.Position.Y > -2 then return end;

    local healthComp: HealthComp? = statusClass.StatusOwner.HealthComp;
    if healthComp == nil then return end;
    
    local dmgData = DamageData.new{
        Damage = 4;
        DamageType = "IgnoreArmor";
    };
    healthComp:TakeDamage(dmgData);
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    modCameraGraphics.TintColor:Remove("redcrow");
end

return modStatusClass.new(statusPackage);