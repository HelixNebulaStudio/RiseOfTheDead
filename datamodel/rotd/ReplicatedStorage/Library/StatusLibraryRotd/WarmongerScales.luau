local RunService = game:GetService("RunService");
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
--==
local statusPackage = {
    Id="WarmongerScales";
    Icon="rbxassetid://16084490297";
    Name="Warmonger's Scales";
    Description="For every percent damaged, temporary increases max health.";
    Buff=true;
};

function statusPackage.init()
    if RunService:IsServer() then
        
        shared.modEventService:OnInvoked("Npcs_BindDamaged", function(event: EventPacket, damageData: DamageData)
            if modBranchConfigs.IsWorld("Slaughterfest") then return end;

            local playerClass: CharacterClass? = damageData.DamageBy;
            if playerClass == nil or playerClass.ClassName ~= "PlayerClass" then return end;
            if playerClass.Properties.PacifistsAmulet then return; end -- disable if pacifists present;
    
            local player: Player = (playerClass :: PlayerClass):GetInstance();
            if player == nil or playerClass == nil then return end;

            local statusComp: StatusComp = playerClass.StatusComp;
            if statusComp == nil then return end;

            local statusClass = statusComp:GetOrDefault("WarmongerScales");
            if statusClass == nil then return end;

            local healthComp: HealthComp? = playerClass.HealthComp;
            if healthComp == nil then return end;

            local damage = damageData.Damage;
            local maxHealth = healthComp.MaxHealth;

            local ratio = math.clamp(damage/maxHealth, 0.1, 1);
            local add = ratio * statusClass.Values.HealthPerKill;

            local oldPool = (statusClass.Values.Pool or 0);
            statusClass.Values.Pool = math.clamp(oldPool + add, 0, statusClass.Values.Max);
            statusClass.Values.LastDeduct = tick()+1;

            if statusClass.Values.Pool > oldPool then
                local dif = statusClass.Values.Pool-oldPool;

                statusClass.Values.Buffer = (statusClass.Values.Buffer or 0) + dif;
            end

            statusClass:Sync();
        end)

    end
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    local hoSrcs = playerClass.Properties.HealthOverchargeSources;
    hoSrcs[statusPackage.Id] = nil;
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms100 ~= true then return end;
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    local timeSinceDoingDmg = workspace:GetServerTimeNow()-playerClass.LastDamageDealt;

    if timeSinceDoingDmg >= 20 and (statusClass.Values.Pool and statusClass.Values.Pool > 0) then
        statusClass.Values.Pool = math.max(statusClass.Values.Pool - 0.1, 0);
    end
    if statusClass.Values.Buffer and statusClass.Values.Buffer > 0 and playerClass.Humanoid.Health < playerClass.Humanoid.MaxHealth then
        playerClass.Humanoid.Health = playerClass.Humanoid.Health + statusClass.Values.Buffer;
        statusClass.Values.Buffer = 0;
    end

    local hoSrcs = playerClass.Properties.HealthOverchargeSources;
    hoSrcs[statusPackage.Id] = statusClass.Values.Pool;

    return true;
end

return modStatusClass.new(statusPackage);