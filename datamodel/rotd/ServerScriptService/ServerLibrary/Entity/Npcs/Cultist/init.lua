local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Cultist";
    HumanoidType = "Cultist";
    
	Configurations = {
        AttackDamage = 20;
        AttackRange = 6;
        AttackSpeed = 1;
    };
    
    Properties = {
        BasicEnemy = false;
        IsHostile = true;

        TargetableDistance = 256;

        Level = 1;
        ExperiencePool = 40;
        DropRewardId = "bandit";
    };

    AddComponents = {
        "TargetHandler";
        "Chat";
        "RandomClothing";
        "FollowPlayer";
    };

    Voice = {
        VoiceId = 3;
        Pitch = 1;
        Speed = 1;
        PlaybackSpeed = 1;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local configurations: ConfigVariable = npcClass.Configurations;
    local healthComp: HealthComp = npcClass.HealthComp;

    local level = math.max(properties.Level, 0);

    local lvlMoveSpeed = 15;
    configurations.BaseValues.WalkSpeed = lvlMoveSpeed;

    local lvlHealth = math.max(400 + 200*level, 400)-1;
    configurations.BaseValues.MaxHealth = lvlHealth;

    local lvlAttackDamage = 25 + 2*level;
    configurations.BaseValues.AttackDamage = lvlAttackDamage;
    
    if healthComp.LastDamagedBy == nil then
        healthComp:Reset();
    end
end

function npcPackage.Spawned(npcClass: NpcClass)
    npcClass:GetComponent("RandomClothing"){
        Name = npcPackage.Name; 
        AddHair = false;
    };

    npcClass.WieldComp:Equip{
        ItemId = "survivalknife";
        OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
            local equipmentClass: EquipmentClass? = toolHandler.EquipmentClass;
            if equipmentClass == nil then return end;

            equipmentClass:AddBaseModifier("CultistMelee", {
                SetValues = {
                    Damage = math.random(5, 10);
                    NpcPercentHealthDamage = 0.15;
                };
            });
        end
    };
end

return npcPackage;