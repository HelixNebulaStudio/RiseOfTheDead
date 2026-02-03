local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local modTeamsManager = shared.require(game.ReplicatedStorage.Library.TeamsManager);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local statusPackage = {
    Id = "reqback";
    Icon = "rbxassetid://4561090238";
    Name = "Skill: Requesting Backup Cooldown";
    Description = "Healing up to $Percent% health of a $TargetName's current health.";
    Buff = true;
};
--==

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
            local reqbackSkillData = profile.SkillTree:GetSkill(player, statusPackage.Id);
            if reqbackSkillData == nil then return end;

            local level, skillStats = profile.SkillTree:CalStats(reqbackSkillData.Library, reqbackSkillData.Points);
            if level <= 0 then return end;

            local healthComp: HealthComp? = characterClass.HealthComp;
            if healthComp == nil or healthComp.CurArmor > 0 then return end;
            local newHealth = healthComp.CurHealth - damageData.Damage;
            if newHealth > healthComp.MaxHealth*0.35 then return end;

            local teamType = characterClass.Properties.ActiveTeamType or "Party";
            local team: TeamClass = modTeamsManager.getTeamByMemberName(characterClass.Name, teamType);
            if team == nil then return end;

            local highestHealthValue = 0;
            local highestHealthName = nil;

            for name, member in pairs(team.Members) do
                if name == characterClass.Name then continue end;
                local memberCharClass: CharacterClass? = team:GetMemberCharacterClass(name);
                if memberCharClass == nil then continue end;

                local memberHealthComp: HealthComp? = memberCharClass.HealthComp;
                if memberHealthComp == nil then continue end;

                if memberHealthComp.CurHealth > highestHealthValue then
                    highestHealthValue = memberHealthComp.CurHealth;
                    highestHealthName = name;
                end
            end

            if highestHealthValue <= 5 then return end;

            local statusComp: StatusComp = characterClass.StatusComp;
            if statusComp:GetOrDefault(statusPackage.Id) then return end;

            local healPool = highestHealthValue * (skillStats.Percent.Value/100);
            if newHealth <= healthComp.KillHealth-healPool then
                return;
            elseif newHealth <= healthComp.KillHealth then
                damageData.Damage = healthComp.CurHealth-1;
            end

            statusComp:Apply(statusPackage.Id, {
                Expires = workspace:GetServerTimeNow() + 60;
                Duration = 60;
                Values = {
                    HealPool = healPool;
                    Percent = skillStats.Percent.Value;
                    TargetName = highestHealthName;
                }
            });
        end)
    end

    function statusPackage.BindApply(statusClass: StatusClassInstance)
        local characterClass: CharacterClass = statusClass.StatusOwner;
        if characterClass == nil then 
            statusClass.IsExpired = true;
            return
        end;

        local teamType = characterClass.Properties.ActiveTeamType or "Party";
        local team: TeamClass = modTeamsManager.getTeamByMemberName(characterClass.Name, teamType);
        if team == nil then 
            statusClass.IsExpired = true;
            return
        end;

    end

    function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
        if tickData.ms100 == false then return end;
        local healthComp: HealthComp = statusClass.StatusOwner.HealthComp;

        local healPool = statusClass.Values.HealPool;
        if healPool <= 0 then
            return
        end;

        local healAmount = math.min(healPool, 2);
        statusClass.Values.HealPool = healPool - healAmount;

        healthComp:TakeDamage(DamageData.new{
            Damage = -healAmount;
            DamageType = "Heal";
        });
    end
end

return modStatusClass.new(statusPackage);