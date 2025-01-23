local RunService = game:GetService("RunService");

local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

--==
local statusPackage = {
    Id="Burn";
    Icon="rbxassetid://5105787895";
    Name="Burning";
    Description="You are on fire, you will lose $Amount Health per second.";
    Buff=false;
    Tags = {"DOT";};
    Cleansable=true;
};

function statusPackage:OnApply()
    if RunService:IsClient() then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    local setFireOnParts = {};
    for _, obj in pairs(playerClass.Character:GetChildren()) do
        if obj:IsA("BasePart") then
            local fire = obj:FindFirstChild("burnFire");
            if fire then
                fire:Destroy();
            end
            if #setFireOnParts == 0 or math.random(1, 4) == 1 then
                table.insert(setFireOnParts, obj);
            end
        end
    end
    for a=1, #setFireOnParts do
        local fire = Instance.new("Fire");
        fire.Name = "burnFire";
        fire.Heat = 3;
        fire.Size = 2;
        fire.Parent = setFireOnParts[a];
    end
end

function statusPackage:OnExpire()
    if RunService:IsClient() then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    for _, obj in pairs(playerClass.Character:GetChildren()) do
        if obj:IsA("BasePart") then
            local fire = obj:FindFirstChild("burnFire");
            if fire then
                fire:Destroy();
            end
        end
    end
end

function statusPackage:OnTick(tickPack)
    if RunService:IsClient() then return end;
    if tickPack.ms500 == false then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    playerClass:TakeDamagePackage(modDamagable.NewDamageSource{
        Damage = self.Amount;
        TargetPart = playerClass.RootPart;
        DamageType = "FireDamage";
    });
end

return modStatusClass.new(statusPackage);