local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local RunService = game:GetService("RunService");

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
--==
return function(event: EventPacket, action: string, toolHandler: ToolHandlerInstance, toCharacterClass: CharacterClass)
    local equipmentClass: EquipmentClass = toolHandler.EquipmentClass;
    local configurations = equipmentClass.Configurations;
    local properties = equipmentClass.Properties;
    
    local byCharacterClass: CharacterClass = toolHandler.CharacterClass;
    if byCharacterClass.ClassName ~= "PlayerClass" then return end;
    local player = (byCharacterClass :: PlayerClass):GetInstance();

    local byHealthComp: HealthComp = byCharacterClass.HealthComp;
    local statusComp: StatusComp = byCharacterClass.StatusComp;

    if action == "UseStart" then
        local fiaitrStatusClass: StatusClassInstance = statusComp:GetOrDefault("fiaitr");
        if fiaitrStatusClass then
            properties.UseDuration = configurations.UseDuration * (100-fiaitrStatusClass.Values.Percent)/100;
        end

    elseif action == "UseComplete" then
        local profile = shared.modProfile:Get(player);
        
        -- Skill: Meet the Medic;
        local skillData = profile.SkillTree:GetSkill(player, "methme");

        if skillData and toCharacterClass and toCharacterClass ~= byCharacterClass then
            local level, stats = profile.SkillTree:CalStats(skillData.Library, skillData.Points);
            local medicMulti = (level > 0 and stats.Percent.Value or 0)/100;
            
            local healAmount = properties.HealAmount * medicMulti;

            if medicMulti > 0 then
                byHealthComp:TakeDamage(DamageData.new{
                    Damage = -healAmount;
                    DamageBy = byCharacterClass;
                    ToolStorageItem = toolHandler.StorageItem;
                    DamageType = "Heal";
                });
                
            end
        end
    
    end
end;