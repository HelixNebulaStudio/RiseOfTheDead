local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local RunService = game:GetService("RunService");
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
--==
local statusPackage = {
    Id="ovehea";
    Icon="rbxassetid://4752500248";
    Name="Skill: Over Heal";
    Description="Heal over max health by $MaxHealthOverCharge health with medkits.";
    Buff=true;
    ExpiresOnDeath = true;
};

if RunService:IsServer() then
    local statusId = statusPackage.Id;
    
    function statusPackage.onRequire()
        shared.modEventService:OnInvoked("Players_OnHeal", function(event: EventPacket, ...)
            local playerClass: PlayerClass, healData: DamageData = ...;
            
            local player: Player = playerClass:GetInstance();
            local healthComp: HealthComp = playerClass.HealthComp;
            local statusComp: StatusComp = playerClass.StatusComp;

            local healAmount: number = math.abs(healData.Damage);

            local profile: ProfileRotd = shared.modProfile:Get(player) :: ProfileRotd;
            local oveheaSkillData = profile.SkillTree:GetSkill(player, statusId);

            if oveheaSkillData then
                local level, values = profile.SkillTree:CalStats(oveheaSkillData.Library, oveheaSkillData.Points);
                local skillMaxOverHeal: number = values.Amount.Default + (level > 0 and values.Amount.Value or 0);
                
                local newHealth = healthComp.CurHealth + healAmount;
                if newHealth > healthComp.MaxHealth and skillMaxOverHeal > 0 then
                    
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

                end
            end
        end);
    end

    function statusPackage.OnUpdate(statusClass: StatusClassInstance)
        if statusClass.StatusOwner.ClassName == "PlayerClass" then
            statusClass.StatusOwner:UpdateHealthStats();
        end
    end

    statusPackage.OnApply = statusPackage.OnUpdate;
end

return modStatusClass.new(statusPackage);