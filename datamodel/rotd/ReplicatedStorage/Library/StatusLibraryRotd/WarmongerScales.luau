local RunService = game:GetService("RunService");
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

--==
local statusPackage = {
    Id = "WarmongerScales";
    Icon = "rbxassetid://16084490297";
    Name = "Warmonger's Scales";
    Description = "For every percent damaged, temporary increases max health.";
    Buff = true;
};

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms100 ~= true then return end;

    local playerClass = statusClass.StatusOwner :: PlayerClass;
    local healthComp: HealthComp? = playerClass and playerClass.HealthComp or nil;
    if healthComp == nil then return end;

    local timeSinceDoingDmg = workspace:GetServerTimeNow()-(statusClass.Values.LastDamageDealt or 0);

    local doSync = false;
    if timeSinceDoingDmg >= 5 and (statusClass.Values.Pool and statusClass.Values.Pool > 0) then
        statusClass.Values.Pool = math.max(statusClass.Values.Pool - 0.1, 0);
        doSync = true;
    end
    if statusClass.Values.Buffer and statusClass.Values.Buffer > 0 and healthComp.CurHealth < healthComp.MaxHealth then
        healthComp:TakeDamage(DamageData.new{
            Damage = -statusClass.Values.Buffer;
            DamageType = "Heal";
        });
        statusClass.Values.Buffer = 0;
        doSync = true;
    end

    statusClass.Values.MaxHealthOverCharge = statusClass.Values.Pool;
    statusClass.Text = `+{math.ceil(statusClass.Values.Pool)} mhp`;

    if doSync then
        if timeSinceDoingDmg >= 5 and statusClass.Values.Pool <= 0 then
            statusClass.IsExpired = true;
        else
            statusClass:Sync();
        end
    end

    return true;
end

return modStatusClass.new(statusPackage);