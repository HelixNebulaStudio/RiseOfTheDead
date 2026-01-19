local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id="Ziphoning";
    Icon="rbxassetid://15936793820";
    Name="Ziphoning";
    Description="Nekrosis heal from this pool of health. +$Amount hp/s";
    QuantityLabel="Pool";
    Buff=true;
    Cleansable=true;
    PresistUntilExpire={"Duration";};
};

function statusPackage.init()
    if RunService:IsClient() then return end;

    shared.modEventService:OnInvoked("Npcs_BindDamaged", function(event: EventPacket, damageData: DamageData)
        local playerClass: CharacterClass? = damageData.DamageBy;
        if playerClass == nil or playerClass.ClassName ~= "PlayerClass" then return end;
        
        local statusId = statusPackage.Id;

        local statusComp: StatusComp? = playerClass.StatusComp;
        if statusComp == nil then return end;

        local statusClass: StatusClassInstance? = statusComp:GetOrDefault(statusId);
        if statusClass == nil then return end;

		local damageTo: CharacterClass? = damageData.DamageTo;
		if damageTo == nil then return end;

		local damage = damageData.Damage;
        if damage > 0 then return end;
        
        local healthComp: HealthComp? = playerClass.HealthComp;
        if healthComp == nil then return end;

		local maxHealth = healthComp.MaxHealth;

		local ratio = math.clamp(damage/maxHealth, 0.1, 1);
		statusClass.Values.Pool = math.clamp(math.round((statusClass.Values.Pool or 0) + ratio*5), 0, maxHealth);

        statusClass:Sync();
	end)

end

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    local statusComp: StatusComp = playerClass.StatusComp;
    
    for otherStatusId, otherStatusClass in pairs(statusComp.List) do
        if otherStatusClass.Buff == true then continue end;
		if otherStatusClass.Cleansable ~= true then continue end;

        otherStatusClass.Expires = workspace:GetServerTimeNow()+0.15;
        otherStatusClass:Sync();
    end
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms1000 ~= true then return end;
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil or playerClass.ClassName ~= "PlayerClass" then return end;

    local healthComp: HealthComp = playerClass.HealthComp;
    if healthComp == nil then return end;

    local hpPerTick = 1;

    local cNekrosisAmpMulti = playerClass.Configurations.NekrosisAmpMulti or 0;
    hpPerTick = hpPerTick + (hpPerTick * cNekrosisAmpMulti);
    statusClass.Values.Amount = hpPerTick;

    if (statusClass.Values.Pool or 0) >= hpPerTick then
        statusClass.Values.Pool = math.clamp(math.round((statusClass.Values.Pool or 0) - hpPerTick), 0, healthComp.MaxHealth);

        local dmgData = DamageData.new{
            Damage = -hpPerTick;
            TargetPart = playerClass.RootPart;
            DamageType = "Heal";
        };

        healthComp:TakeDamage(dmgData);
    end

    return;
end

return modStatusClass.new(statusPackage);