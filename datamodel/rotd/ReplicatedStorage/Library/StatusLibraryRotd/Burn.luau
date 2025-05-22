local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

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

function statusPackage.OnApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;

    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass == nil or characterClass.Character == nil then return end;

    local setFireOnParts = {};
    for _, obj in pairs(characterClass.Character:GetChildren()) do
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

function statusPackage.OnExpire(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;

    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass == nil or characterClass.Character == nil then return end;

    for _, obj in pairs(characterClass.Character:GetChildren()) do
        if obj:IsA("BasePart") then
            local fire = obj:FindFirstChild("burnFire");
            if fire then
                fire:Destroy();
            end
        end
    end
end

function statusPackage.OnTick(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms500 == false then return end;

    local healthComp: HealthComp? = statusClass.StatusOwner.HealthComp;
    if healthComp == nil then return end;

    local dmgData = DamageData.new{
        Damage = statusClass.Values.Amount;
        DamageType = "Fire";
    };

    healthComp:TakeDamage(dmgData);
end

return modStatusClass.new(statusPackage);