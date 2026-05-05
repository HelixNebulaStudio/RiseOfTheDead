local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local RunService = game:GetService("RunService");

--==
local statusPackage = {
    Id="ovehea";
    Icon="rbxassetid://4752500248";
    Name="Skill: Over Heal";
    Description="Skill: Over Heal max health by $MaxHealthOverCharge health.";
    Buff=true;
    ExpiresOnDeath = true;
};

if RunService:IsServer() then
    local statusId = statusPackage.Id;
    
    function statusPackage.onRequire()
        shared.modEventService:OnInvoked("Players_BindPreTakeDamage", function(event: EventPacket, ...)
            local player: Player? = event.Player;
            if player == nil then return end;
            
            local healData: DamageData = ...;
            if healData == nil or healData.DamageTo == nil then return end;

            local playerClass: PlayerClass = healData.DamageTo :: PlayerClass;

            task.spawn(function()
                if healData.DamageType ~= "Heal" then return end;
                
                local healthComp: HealthComp = playerClass.HealthComp;
                local statusComp: StatusComp = playerClass.StatusComp;

                local healAmount: number = math.abs(healData.Damage);

                local profile: ProfileRotd = shared.modProfile:Get(player) :: ProfileRotd;

                local oveheaSkillData = profile.SkillTree:GetSkill(player, statusId);
                if oveheaSkillData == nil then return end;
                
                local level, values = profile.SkillTree:CalStats(oveheaSkillData.Library, oveheaSkillData.Points);
                local skillMaxOverHeal: number = values.Amount.Default + (level > 0 and values.Amount.Value or 0);
                if skillMaxOverHeal <= 0 then return end;

                local newHealth = healthComp.CurHealth + healAmount;
                if newHealth < healthComp.MaxHealth then return end;
                   
                local overhealDuration = 60;
                local healthChange = newHealth-healthComp.MaxHealth;
                
                local newMaxHealthOverCharge = math.min(healthChange, skillMaxOverHeal);

                local oveheaStatus = statusComp:GetOrDefault(statusId);
                if oveheaStatus == nil then
                    local cMaxHealth = playerClass.Configurations.MaxHealth;
                    local cHealthPoints = (playerClass.Configurations.HealthPoints or 0);

                    local healthSurplus = healthComp.MaxHealth - (cMaxHealth + cHealthPoints);
                    newMaxHealthOverCharge = math.min(healthSurplus + healthChange, skillMaxOverHeal);
                else
                    newMaxHealthOverCharge = math.min(oveheaStatus.Values.MaxHealthOverCharge + healthChange, skillMaxOverHeal);
                end
    
                local statusApplyParam: StatusCompApplyParam = {
                    Expires = workspace:GetServerTimeNow() + overhealDuration;
                    Duration = overhealDuration;
                    Values = {
                        MaxHealthOverCharge = newMaxHealthOverCharge;
                    };
                };
                statusComp:Apply(statusId, statusApplyParam);
            end)
        end)
    end

    function statusPackage.BindUpdate(statusClass: StatusClassInstance)
        if statusClass.StatusOwner.ClassName == "PlayerClass" then
            statusClass.StatusOwner:UpdateHealthStats();
        end
    end

    statusPackage.BindApply = statusPackage.BindUpdate;
end

return modStatusClass.new(statusPackage);