local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local statusPackage = {
    Id = "remres";
    Icon = "rbxassetid://4651191717";
    Name = "Skill: Remarkable Resilience Cooldown";
    Description = "Skill on cooldown, regenerated to $Percent% of max health.";
    Buff = true;
};


if RunService:IsServer() then
    function statusPackage.onRequire()
        shared.modEventService:OnInvoked("Players_BindPreTakeDamage", function(event: EventPacket, ...)
            local damageData: DamageData = ...;
            if damageData.Damage == nil or damageData.Damage <= 0 then return end;
            if damageData.DamageType == "Heal" then return end;

            local characterClass: CharacterClass? = damageData.DamageTo;
            if characterClass == nil or characterClass.ClassName ~= "PlayerClass" then return end;

            local player = (characterClass :: PlayerClass):GetInstance();
            
            local profile = shared.modProfile:Get(player);
            local remresSkillData = profile.SkillTree:GetSkill(player, statusPackage.Id);
            if remresSkillData == nil then return end;

            local level, skillStats = profile.SkillTree:CalStats(remresSkillData.Library, remresSkillData.Points);
            if level <= 0 then return end;

            local healthComp: HealthComp? = characterClass.HealthComp;
            if healthComp == nil or healthComp.CurArmor > 0 then return end;
            local newHealth = healthComp.CurHealth - damageData.Damage;
            if newHealth > healthComp.MaxHealth*0.15 then return end;

            local statusComp: StatusComp = characterClass.StatusComp;
            if statusComp:GetOrDefault(statusPackage.Id) then return end;

            local healPool = healthComp.MaxHealth * (skillStats.Percent.Value/100);
            if newHealth <= healthComp.KillHealth-healPool then
                return;
            elseif newHealth <= healthComp.KillHealth then
                damageData.Damage = healthComp.CurHealth-1;
            end

            statusComp:Apply(statusPackage.Id, {
                Expires = workspace:GetServerTimeNow() + 120;
                Duration = 120;
                Values = {
                    HealPool = healPool;
                    Percent = skillStats.Percent.Value;
                }
            });
        end)
    end

    function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
        if tickData.ms1000 == false then return end;
        local healthComp: HealthComp = statusClass.StatusOwner.HealthComp;

        local healPool = statusClass.Values.HealPool;
        if healPool <= 0 then
            return
        end;

        local healAmount = math.min(healPool, 3);
        statusClass.Values.HealPool = healPool - healAmount;

        healthComp:TakeDamage(DamageData.new{
            Damage = -healAmount;
            DamageType = "Heal";
        });
    end
end

return modStatusClass.new(statusPackage);